extends Node
const _Profiles = preload("res://AFK/AfkProfiles.gd")
const _ItemDB = preload("res://Inventory/ItemDB.gd")
const AfkOffline = preload("res://AFK/AfkOffline.gd")
const STOP_STRINGS := {
	"player_cancel": "You called me back.",
	"death": "I fell. Report sealed.",
	"inventory_full": "Pack at limit — no vendor path.",
	"level_gap": "Threat above charter — held position.",
	"manual_quest": "Choice needed — waiting on you.",
	"afk_blocked": "Coil Warden stays a waking fight.",
	"time_cap": "Session cap reached — fair rest.",
	"thermal": "Heat warning — switched to offline sim.",
	"retreat_unresolved": "Could not recover — stopped per rules.",
	"complete_ok": "Watch ended clean.",
	"boss_stub": "Boss watch is a stub — held short of the Coil.",
}
const AGENT_TICK_SEC := 0.55
const EMBER_CAMP_POS := Vector3(14, 0, 6)
const WILDS_POS := Vector3(22, 0, 0)
const GATHER_POS := Vector3(16, 0, 3)
const VENDOR_POS := Vector3(0, 0, 8)  # near Ashfen / Pyra
const INVENTORY_CAP := 40
const HARD_XP_PER_HOUR := 2400
const HARD_GOLD_PER_HOUR := 900
var active_profile: String = "Balanced"
var running: bool = false
var last_report: Dictionary = {}
var mode: String = "foreground"  # foreground | offline
var rules: Dictionary = {}
var _started_unix: float = 0.0
var _agent_timer: Timer
var _acc_kills: int = 0
var _acc_xp: int = 0
var _acc_gold: int = 0
var _acc_items: Array = []
var _acc_retreats: int = 0
var _acc_deaths: int = 0
var _acc_discoveries: Array = []
var _caps_hit: Array = []
var _goal: String = "idle_safe"
var _prev_combat_mode: int = 0
var _loot_queue: Array = []  # pending ground loot ids from kills this session
var _fog_cells: int = 0
var _player_was_alive: bool = true
var _sim_yield: bool = false
func _ready() -> void:
	rules = _Profiles.rules()
	_agent_timer = Timer.new()
	_agent_timer.wait_time = AGENT_TICK_SEC
	_agent_timer.timeout.connect(_on_agent_tick)
	add_child(_agent_timer)
	call_deferred("_check_offline_resume")
func profiles() -> Array:
	return _Profiles.selectable()
func set_profile(profile: String) -> void:
	var ok := _Profiles.selectable()
	active_profile = profile if profile in ok else "Balanced"
	if EventBus:
		EventBus.hud_toast.emit("Watch profile: %s" % active_profile)
func cycle_profile() -> String:
	var list: Array = profiles()
	var i := list.find(active_profile)
	i = (i + 1) % list.size()
	set_profile(str(list[i]))
	return active_profile
func start_afk(profile: String = "") -> void:
	if profile != "":
		set_profile(profile)
	if _is_afk_blocked():
		if EventBus:
			EventBus.hud_toast.emit(STOP_STRINGS["afk_blocked"])
		last_report = _build_report(0, "afk_blocked")
		if EventBus:
			EventBus.afk_stopped.emit(last_report)
		return
	running = true
	mode = "foreground"
	_started_unix = Time.get_unix_time_from_system()
	_reset_acc()
	rules = _Profiles.rules()
	var player := _player()
	if player:
		_prev_combat_mode = int(player.get("combat_mode") if player.get("combat_mode") != null else 0)
		if "combat_mode" in player:
			player.combat_mode = 2
		if "soft_lock_on" in player:
			player.soft_lock_on = true
		_player_was_alive = player.combat.alive if player.get("combat") else true
	_goal = _pick_goal()
	_agent_timer.start()
	if SaveManager:
		SaveManager.data["afk_running"] = true
		SaveManager.data["afk_profile"] = active_profile
		SaveManager.data["afk_started_unix"] = _started_unix
		SaveManager.save()
	if EventBus:
		EventBus.afk_started.emit()
		EventBus.hud_toast.emit("Agent watching — %s · %s" % [active_profile, _goal])
func stop_afk(reason: String = "player_cancel") -> Dictionary:
	if not running and last_report.get("stop_reason", "") == reason and not last_report.is_empty():
		return last_report
	_agent_timer.stop()
	running = false
	var player := _player()
	if player and player.has_method("set_touch_move"):
		player.set_touch_move(Vector2.ZERO)
		if "combat_mode" in player:
			player.combat_mode = _prev_combat_mode
	var dur := int(Time.get_unix_time_from_system() - _started_unix) if _started_unix > 0.0 else 0
	if _acc_kills == 0 and _acc_xp == 0 and dur >= 3:
		_sim_yield = true
		_simulate_offline_seconds(dur)
	_apply_hard_caps(dur)
	last_report = _build_report(maxi(dur, 0), reason)
	_grant_to_player()
	if SaveManager:
		SaveManager.data["afk_running"] = false
		SaveManager.data["last_afk_report"] = last_report.duplicate(true)
		SaveManager.save()
	if EventBus:
		EventBus.afk_stopped.emit(last_report)
	return last_report
func _reset_acc() -> void:
	_sim_yield = false
	_acc_kills = 0
	_acc_xp = 0
	_acc_gold = 0
	_acc_items.clear()
	_acc_retreats = 0
	_acc_deaths = 0
	_acc_discoveries.clear()
	_caps_hit.clear()
	_loot_queue.clear()
	_fog_cells = 0
func _is_afk_blocked() -> bool:
	if SaveManager and SaveManager.get_scene_id() == "coilcrypt":
		return true
	var bosses := get_tree().get_nodes_in_group("boss")
	return bosses.size() > 0
func _player() -> Node:
	var nodes := get_tree().get_nodes_in_group("player")
	return nodes[0] if not nodes.is_empty() else null
func _on_agent_tick() -> void:
	if not running or mode != "foreground":
		return
	var dur := int(Time.get_unix_time_from_system() - _started_unix)
	var stop := _check_stop_conditions(dur)
	if stop != "":
		stop_afk(stop)
		return
	var player := _player()
	if player == null:
		return
	if player.get("combat") and not player.combat.alive:
		_acc_deaths += 1
		stop_afk("death")
		return
	_goal = _pick_goal()
	_execute_goal(player, _goal)
	_loot_step(player)
	if _inventory_fill_pct(player) >= float(rules.get("inventory_stop_pct", 90.0)):
		if _goal != "vendor_trip":
			_goal = "vendor_trip"
			_execute_goal(player, "vendor_trip")
		if _inventory_fill_pct(player) >= float(rules.get("inventory_stop_pct", 90.0)):
			stop_afk("inventory_full")
			return
func _check_stop_conditions(dur: int) -> String:
	if _is_afk_blocked():
		return "afk_blocked"
	var cap := int(rules.get("session_time_cap_sec", 1800))
	if dur >= cap:
		_caps_hit.append("session_time_cap")
		return "time_cap"
	if active_profile == "Boss" and dur >= 45:
		return "boss_stub"
	return ""
func _pick_goal() -> String:
	var w := _Profiles.weights(active_profile)
	var player := _player()
	var hp := 1.0
	if player and player.get("combat"):
		hp = player.combat.hp_pct()
	var retreat_at := float(rules.get("retreat_hp_pct", 35.0)) / 100.0
	var potion_at := float(rules.get("potion_hp_pct", 50.0)) / 100.0
	if hp <= retreat_at:
		return "heal_recover"
	if hp <= potion_at and player and int(player.get("potions") if player.get("potions") != null else 0) > 0:
		return "heal_recover"
	if player and _inventory_fill_pct(player) >= 70.0 and float(w.get("gold", 0.0)) >= 0.5:
		return "vendor_trip"
	var scores := {
		"farm_pack": float(w.get("xp", 0.5)) * 0.9 + float(w.get("gold", 0.5)) * 0.5,
		"explore_chunk": float(w.get("explore", 0.3)),
		"gather": float(w.get("gather", 0.2)),
		"idle_safe": 0.05,
	}
	if active_profile == "Boss":
		scores["farm_pack"] = 0.2
		scores["idle_safe"] = 0.4
	var best := "farm_pack"
	var best_u := -1.0
	for k in scores.keys():
		var u: float = float(scores[k])
		if u > best_u:
			best_u = u
			best = str(k)
	return best
func _execute_goal(player: Node, goal: String) -> void:
	match goal:
		"heal_recover":
			_do_heal(player)
			_nav_toward(player, EMBER_CAMP_POS)
		"vendor_trip":
			_nav_toward(player, VENDOR_POS)
			if player.global_position.distance_to(VENDOR_POS) < 3.5:
				_vendor_sell_junk(player)
		"explore_chunk":
			_nav_toward(player, WILDS_POS + Vector3(randf_range(-6, 6), 0, randf_range(-6, 6)))
			_fog_cells += 1
			if _fog_cells % 8 == 0 and "Emberveil Wilds" not in _acc_discoveries:
				_acc_discoveries.append("Emberveil Wilds")
			_try_engage(player)
		"gather":
			_nav_toward(player, GATHER_POS)
			if player.global_position.distance_to(GATHER_POS) < 2.5:
				_gather_tick(player)
		"farm_pack":
			_try_engage(player)
			if player.get("soft_lock_target") == null or not is_instance_valid(player.soft_lock_target):
				_nav_toward(player, WILDS_POS)
		_:
			_nav_toward(player, EMBER_CAMP_POS)
func _nav_toward(player: Node, target: Vector3) -> void:
	if not player.has_method("set_touch_move"):
		return
	var to := target - player.global_position
	to.y = 0.0
	if to.length() < 1.2:
		player.set_touch_move(Vector2.ZERO)
		return
	var yaw := float(player.get("_yaw") if player.get("_yaw") != null else 0.0)
	var local := to.rotated(Vector3.UP, -yaw)
	var stick := Vector2(local.x, -local.z).normalized()
	player.set_touch_move(stick)
func _try_engage(player: Node) -> void:
	var gap_max := int(rules.get("max_level_gap", 3))
	var player_lv := 1
	if player.get("attr_sheet") != null:
		player_lv = int(player.attr_sheet.get("level", 1))
	var enemies := get_tree().get_nodes_in_group("wilds_enemy")
	var best: Node3D = null
	var best_d := 9999.0
	var gap_blocked := false
	for e in enemies:
		if e == null or not is_instance_valid(e):
			continue
		if e.get("combat") and e.combat and not e.combat.alive:
			continue
		var elv := _enemy_level(e)
		if elv - player_lv > gap_max:
			gap_blocked = true
			continue
		var d: float = player.global_position.distance_to(e.global_position)
		if d < best_d and d < 28.0:
			best_d = d
			best = e
	if best == null:
		if gap_blocked and enemies.size() > 0:
			if best_d > 9000.0:
				pass
		return
	if "soft_lock_target" in player:
		player.soft_lock_target = best
	if "soft_lock_on" in player:
		player.soft_lock_on = true
	if "combat_mode" in player:
		player.combat_mode = 2
	_nav_toward(player, best.global_position)
	if not EventBus.enemy_killed.is_connected(_on_kill):
		EventBus.enemy_killed.connect(_on_kill)
func _enemy_level(e: Node) -> int:
	if e.get("enemy_level") != null:
		return int(e.enemy_level)
	var xp := int(e.get("xp_reward") if e.get("xp_reward") != null else 12)
	return clampi(1 + xp / 10, 1, 20)
func _on_kill(_enemy: Node, drops: Dictionary) -> void:
	if not running:
		return
	_acc_kills += 1
	_acc_xp += int(drops.get("xp", 0))
	_acc_gold += int(drops.get("gold", 0))
	var item := str(drops.get("item", ""))
	if item != "":
		_loot_queue.append(item)
		_record_item(item, 1)
func _loot_step(player: Node) -> void:
	while not _loot_queue.is_empty():
		if _inventory_fill_pct(player) >= 100.0:
			break
		var id: String = str(_loot_queue.pop_front())
		if player.has_method("add_item"):
			player.add_item(id)
func _record_item(item_id: String, qty: int) -> void:
	var defn: Dictionary = _ItemDB.get_item(item_id)
	var rarity := str(defn.get("tier", "common"))
	for it in _acc_items:
		if str(it.get("id", "")) == item_id:
			it["qty"] = int(it.get("qty", 1)) + qty
			return
	_acc_items.append({
		"id": item_id,
		"name": str(defn.get("name", item_id)),
		"qty": qty,
		"rarity": rarity,
	})
func _do_heal(player: Node) -> void:
	if player == null or player.get("combat") == null:
		return
	var hp := player.combat.hp_pct()
	var potion_at := float(rules.get("potion_hp_pct", 50.0)) / 100.0
	if hp <= potion_at and int(player.potions) > 0:
		player.potions = maxi(player.potions - 1, 0)
		player.combat.heal(40.0)
		if player.has_method("consume_item"):
			player.consume_item("health_draught", 1)
	var retreat_at := float(rules.get("retreat_hp_pct", 35.0)) / 100.0
	if hp <= retreat_at:
		_acc_retreats += 1
		_nav_toward(player, EMBER_CAMP_POS)
func _gather_tick(player: Node) -> void:
	if randf() < 0.25:
		var id := "ember_fiber"
		if player.has_method("add_item"):
			player.add_item(id)
		_record_item(id, 1)
		_acc_xp += 2
		_acc_gold += 1
func _vendor_sell_junk(player: Node) -> void:
	if player == null or not ("inventory" in player):
		return
	var keep: Array = []
	var sold := 0
	for it in player.inventory:
		var id := str(it)
		var defn: Dictionary = _ItemDB.get_item(id)
		var tier := str(defn.get("tier", "common"))
		var slot := str(defn.get("slot", ""))
		if tier in ["rare", "epic", "legendary"] or slot in ["weapon", "armor", "charm", "consumable"]:
			keep.append(id)
		elif id.begins_with("starter_"):
			keep.append(id)
		else:
			sold += int(defn.get("sell", 2))
	player.inventory = keep
	if "gold" in player:
		player.gold += sold
	_acc_gold += sold
	if EventBus:
		EventBus.inventory_changed.emit()
		EventBus.hud_toast.emit("Vendor: sold junk +%dg" % sold)
func _inventory_fill_pct(player: Node) -> float:
	if player == null or not ("inventory" in player):
		return 0.0
	return clampf(100.0 * float(player.inventory.size()) / float(INVENTORY_CAP), 0.0, 100.0)
func _apply_hard_caps(dur: int) -> void:
	if dur <= 0:
		return
	var hours := maxf(dur / 3600.0, 1.0 / 60.0)
	var xp_cap := int(HARD_XP_PER_HOUR * hours)
	var gold_cap := int(HARD_GOLD_PER_HOUR * hours)
	if _acc_xp > xp_cap:
		_acc_xp = xp_cap
		if "hard_xp_per_hour" not in _caps_hit:
			_caps_hit.append("hard_xp_per_hour")
	if _acc_gold > gold_cap:
		_acc_gold = gold_cap
		if "hard_gold_per_hour" not in _caps_hit:
			_caps_hit.append("hard_gold_per_hour")
	var soft := int(rules.get("soft_diminish_sec", 7200))
	if dur > soft:
		if "soft_diminishing_120m" not in _caps_hit:
			_caps_hit.append("soft_diminishing_120m")
		_acc_xp = int(_acc_xp * 0.7)
		_acc_gold = int(_acc_gold * 0.7)
func _simulate_offline_seconds(sec: int) -> void:
	var r: Dictionary = AfkOffline.simulate(active_profile, sec, rules, {
		"caps_hit": _caps_hit, "discoveries": _acc_discoveries,
	})
	_acc_kills = int(r.get("kills", 0))
	_acc_xp = int(r.get("xp", 0))
	_acc_gold = int(r.get("gold", 0))
	_acc_items = r.get("items", [])
	_acc_retreats = int(r.get("retreats", 0))
	_acc_discoveries = r.get("discoveries", [])
	_caps_hit = r.get("caps_hit", [])
	_fog_cells += int(r.get("fog_cells", 0))
func _build_report(dur: int, reason: String) -> Dictionary:
	var stop_key := reason
	if not STOP_STRINGS.has(stop_key):
		stop_key = "complete_ok"
	return {
		"duration_sec": dur,
		"duration_human": _human_duration(dur),
		"kills": _acc_kills,
		"xp_gained": _acc_xp,
		"gold_gained": _acc_gold,
		"items_looted": _acc_items.duplicate(true),
		"retreats": _acc_retreats,
		"deaths": _acc_deaths,
		"discoveries": _acc_discoveries.duplicate(),
		"stop_reason": stop_key,
		"stop_reason_text": STOP_STRINGS[stop_key],
		"mode": mode,
		"profile": active_profile,
		"caps_hit": _caps_hit.duplicate(),
		"region": "Emberveil Reach",
		"goal": _goal,
		"companion_summary": "",
	}
func _human_duration(sec: int) -> String:
	if sec < 60:
		return "%d seconds" % sec
	var m := sec / 60
	var s := sec % 60
	if m < 60:
		return "%d minutes" % m if s < 15 else "%d min %ds" % [m, s]
	return "%dh %dm" % [m / 60, m % 60]
func format_report_text(report: Dictionary = {}) -> String:
	if report.is_empty():
		report = last_report
	if report.is_empty():
		return "No return yet — set a profile and rest the watch."
	var lines: PackedStringArray = []
	lines.append("AFK complete — %s · %s" % [report.get("profile", "?"), report.get("mode", "foreground")])
	lines.append("%s · %s" % [report.get("duration_human", "?"), report.get("region", "Emberveil Reach")])
	lines.append("")
	lines.append("Engagements closed: %s" % report.get("kills", 0))
	lines.append("Ash-light gained: %s XP" % report.get("xp_gained", 0))
	lines.append("Ledger: +%s gold" % report.get("gold_gained", 0))
	for it in report.get("items_looted", []):
		var rarity := str(it.get("rarity", "common"))
		var nm := str(it.get("name", it.get("id", "item")))
		var qty := int(it.get("qty", 1))
		if rarity in ["rare", "uncommon", "epic"]:
			lines.append("Kept: %s · %s ×%d" % [nm, rarity, qty])
		else:
			lines.append("Salvage: %s ×%d" % [nm, qty])
	for d in report.get("discoveries", []):
		lines.append("Marked: %s" % str(d))
	var retreats := int(report.get("retreats", 0))
	if retreats > 0:
		lines.append("Fell back %d× — rules held" % retreats)
	if int(report.get("deaths", 0)) > 0:
		lines.append("Stopped after fall — report sealed")
	for cap in report.get("caps_hit", []):
		lines.append("Cap applied: %s" % str(cap))
	var companion := str(report.get("companion_summary", ""))
	if companion != "":
		lines.append("Rook: %s" % companion)
	lines.append(str(report.get("stop_reason_text", STOP_STRINGS.get(str(report.get("stop_reason", "complete_ok")), "Watch ended clean."))))
	return "\n".join(lines)
func _grant_to_player() -> void:
	var p := _player()
	if p == null:
		return
	if mode != "offline" and not _sim_yield:
		return
	if p.has_method("add_xp"):
		p.add_xp(_acc_xp)
	elif "xp" in p:
		p.xp += _acc_xp
	if "gold" in p:
		p.gold += _acc_gold
	if p.has_method("add_item"):
		for it in _acc_items:
			for _i in range(int(it.get("qty", 1))):
				if _inventory_fill_pct(p) >= 100.0:
					break
				p.add_item(str(it.get("id", "")))
func _check_offline_resume() -> void:
	if SaveManager == null:
		return
	if not bool(SaveManager.data.get("afk_running", false)):
		return
	var started := float(SaveManager.data.get("afk_started_unix", 0.0))
	if started <= 0.0:
		return
	var elapsed := int(Time.get_unix_time_from_system() - started)
	if elapsed < 3:
		return
	active_profile = str(SaveManager.data.get("afk_profile", "Balanced"))
	mode = "offline"
	_started_unix = started
	_reset_acc()
	rules = _Profiles.rules()
	var reason := "complete_ok"
	var fill_before := _inventory_fill_pct(_player()) if _player() else 0.0
	_simulate_offline_seconds(elapsed)
	if fill_before >= float(rules.get("inventory_stop_pct", 90.0)) or _inventory_fill_pct(_player()) >= 95.0:
		reason = "inventory_full"
	var wall := int(rules.get("offline_hard_wall_sec", 14400))
	if elapsed >= wall:
		reason = "time_cap"
	running = false
	SaveManager.data["afk_running"] = false
	last_report = _build_report(mini(elapsed, wall), reason)
	_grant_to_player()
	SaveManager.data["last_afk_report"] = last_report.duplicate(true)
	SaveManager.save()
	await get_tree().create_timer(0.6).timeout
	if EventBus:
		EventBus.afk_stopped.emit(last_report)
		EventBus.hud_toast.emit("Offline watch returned")
func notification_paused() -> void:
	if running:
		_agent_timer.stop()
		mode = "offline"
		if SaveManager:
			SaveManager.data["afk_running"] = true
			SaveManager.data["afk_profile"] = active_profile
			SaveManager.data["afk_started_unix"] = _started_unix
			SaveManager.save()
func debug_sim_minutes(minutes: int, profile: String = "") -> String:
	if profile != "":
		set_profile(profile)
	mode = "offline"
	_started_unix = Time.get_unix_time_from_system() - minutes * 60
	_reset_acc()
	rules = _Profiles.rules()
	_simulate_offline_seconds(minutes * 60)
	last_report = _build_report(minutes * 60, "complete_ok")
	return format_report_text(last_report)
