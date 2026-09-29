extends Node
## AFK agent — AFK_AGENT.md MVP profiles + AFK_REPORT_VOICE.md copy bind.

const MVP_PROFILES := ["EXP", "Gold", "Explore", "Balanced"]

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
	"sim_complete": "Watch ended clean.",
}

const SIM_INTERVAL_SEC := 10.0
const EMBER_CAMP_RADIUS := 8.0
const EMBER_CAMP_POS := Vector3(14, 0, 6)

var active_profile: String = "Balanced"
var running: bool = false
var last_report: Dictionary = {}
var mode: String = "foreground"
var _started_unix: float = 0.0
var _timer: Timer
var _acc_kills: int = 0
var _acc_xp: int = 0
var _acc_gold: int = 0
var _acc_items: Array = []
var _acc_retreats: int = 0
var _caps_hit: Array = []

func _ready() -> void:
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.wait_time = SIM_INTERVAL_SEC
	_timer.timeout.connect(_on_sim_tick)
	add_child(_timer)
	call_deferred("_check_offline_resume")

func profiles() -> Array:
	return MVP_PROFILES.duplicate()

func set_profile(profile: String) -> void:
	active_profile = profile if profile in MVP_PROFILES else "Balanced"
	if EventBus:
		EventBus.hud_toast.emit("Watch profile: %s" % active_profile)

func cycle_profile() -> String:
	var i := MVP_PROFILES.find(active_profile)
	i = (i + 1) % MVP_PROFILES.size()
	set_profile(MVP_PROFILES[i])
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
	_acc_kills = 0
	_acc_xp = 0
	_acc_gold = 0
	_acc_items.clear()
	_acc_retreats = 0
	_caps_hit.clear()
	_timer.start(SIM_INTERVAL_SEC)
	if SaveManager:
		SaveManager.data["afk_running"] = true
		SaveManager.data["afk_profile"] = active_profile
		SaveManager.data["afk_started_unix"] = _started_unix
		SaveManager.save()
	if EventBus:
		EventBus.afk_started.emit()
		EventBus.hud_toast.emit("Agent watching — %s" % active_profile)

func stop_afk(reason: String = "player_cancel") -> Dictionary:
	_timer.stop()
	running = false
	var dur := int(Time.get_unix_time_from_system() - _started_unix)
	if _acc_kills == 0 and dur > 0:
		_simulate_for_seconds(dur)
	last_report = _build_report(maxi(dur, 0), reason)
	_grant_to_player()
	if SaveManager:
		SaveManager.data["afk_running"] = false
		SaveManager.data["last_afk_report"] = last_report.duplicate(true)
		SaveManager.save()
	if EventBus:
		EventBus.afk_stopped.emit(last_report)
	return last_report

func _is_afk_blocked() -> bool:
	if SaveManager and SaveManager.get_scene_id() == "coilcrypt":
		return true
	var bosses := get_tree().get_nodes_in_group("boss")
	return bosses.size() > 0

func _on_sim_tick() -> void:
	if not running:
		return
	var dur := int(Time.get_unix_time_from_system() - _started_unix)
	_simulate_for_seconds(maxi(dur, int(SIM_INTERVAL_SEC)))
	stop_afk("complete_ok")

func _simulate_for_seconds(sec: int) -> void:
	var t := maxf(sec / 60.0, 0.05)
	var kills_pm := 2.5
	var xp_pm := 20.0
	var gold_pm := 10.0
	var item_chance := 0.35
	match active_profile:
		"EXP":
			kills_pm = 3.2
			xp_pm = 34.0
			gold_pm = 5.0
			item_chance = 0.25
		"Gold":
			kills_pm = 2.2
			xp_pm = 12.0
			gold_pm = 24.0
			item_chance = 0.4
		"Explore":
			kills_pm = 1.2
			xp_pm = 14.0
			gold_pm = 7.0
			item_chance = 0.3
		_:
			kills_pm = 2.5
			xp_pm = 22.0
			gold_pm = 12.0
			item_chance = 0.35
	if _near_ember_camp():
		kills_pm *= 1.15
		xp_pm *= 1.1
	_acc_kills = int(round(kills_pm * t))
	_acc_xp = int(round(xp_pm * t))
	_acc_gold = int(round(gold_pm * t))
	if sec >= 5:
		_acc_kills = maxi(_acc_kills, 1)
		_acc_xp = maxi(_acc_xp, 3)
		_acc_gold = maxi(_acc_gold, 2)
	if sec > 120 * 60:
		_caps_hit.append("soft_diminishing_120m")
		_acc_xp = int(_acc_xp * 0.7)
		_acc_gold = int(_acc_gold * 0.7)
	_acc_items.clear()
	if sec >= 5 and randf() < item_chance + t * 0.1:
		_acc_items.append({"id": "vein_mite_carapace", "name": "Vein-mite Carapace", "qty": maxi(1, int(t * 2)), "rarity": "common"})
	if sec >= 8 and active_profile == "Explore" and randf() < 0.4:
		_acc_items.append({"id": "ember_fiber", "name": "Ember Fiber", "qty": 1, "rarity": "uncommon"})
	if sec >= 10 and randf() < 0.12:
		_acc_items.append({"id": "wake_ore", "name": "Wake Ore", "qty": 1, "rarity": "uncommon"})
	if t >= 0.3 and randf() < 0.25:
		_acc_retreats = 1

func _near_ember_camp() -> bool:
	var nodes := get_tree().get_nodes_in_group("player")
	if nodes.is_empty():
		return false
	var p: Node3D = nodes[0] as Node3D
	if p == null:
		return false
	return p.global_position.distance_to(EMBER_CAMP_POS) <= EMBER_CAMP_RADIUS + 4.0

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
		"deaths": 0,
		"stop_reason": stop_key,
		"stop_reason_text": STOP_STRINGS[stop_key],
		"mode": mode,
		"profile": active_profile,
		"caps_hit": _caps_hit.duplicate(),
		"region": "Emberveil Reach",
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
	var items: Array = report.get("items_looted", [])
	for it in items:
		var rarity := str(it.get("rarity", "common"))
		var nm := str(it.get("name", it.get("id", "item")))
		var qty := int(it.get("qty", 1))
		if rarity == "rare" or rarity == "uncommon":
			lines.append("Kept: %s · %s ×%d" % [nm, rarity, qty])
		else:
			lines.append("Salvage: %s ×%d" % [nm, qty])
	var retreats := int(report.get("retreats", 0))
	if retreats > 0:
		lines.append("Fell back %d× — rules held" % retreats)
	for cap in report.get("caps_hit", []):
		lines.append("Cap applied: %s" % str(cap))
	var companion := str(report.get("companion_summary", ""))
	if companion != "":
		lines.append("Rook: %s" % companion)
	lines.append(str(report.get("stop_reason_text", STOP_STRINGS.get(str(report.get("stop_reason", "complete_ok")), "Watch ended clean."))))
	return "\n".join(lines)

func _grant_to_player() -> void:
	var nodes := get_tree().get_nodes_in_group("player")
	if nodes.is_empty():
		return
	var p = nodes[0]
	if "xp" in p:
		p.xp += _acc_xp
	if "gold" in p:
		p.gold += _acc_gold
	if p.has_method("add_item"):
		for it in _acc_items:
			for _i in range(int(it.get("qty", 1))):
				p.add_item(str(it.get("id", "")))
	elif "inventory" in p:
		for it in _acc_items:
			for _i in range(int(it.get("qty", 1))):
				p.inventory.append(str(it.get("id", "")))

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
	_simulate_for_seconds(mini(elapsed, 4 * 3600))
	running = false
	SaveManager.data["afk_running"] = false
	last_report = _build_report(mini(elapsed, 4 * 3600), "complete_ok")
	_grant_to_player()
	SaveManager.data["last_afk_report"] = last_report.duplicate(true)
	SaveManager.save()
	await get_tree().create_timer(0.6).timeout
	if EventBus:
		EventBus.afk_stopped.emit(last_report)
		EventBus.hud_toast.emit("Offline watch returned")

func notification_paused() -> void:
	if running:
		_timer.stop()
		mode = "offline"
