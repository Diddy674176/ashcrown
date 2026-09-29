extends Node
## Living-world sim LOD — L0 near player, L1 adjacent, L2 abstract when far/AFK/offline.
## Exit (Phase 5): world changes while player is elsewhere.
const _Faction = preload("res://Factions/FactionReputation.gd")
const _Biome = preload("res://World/BiomeZones.gd")
const _Events = preload("res://World/WorldEvents.gd")

signal lod_changed(lod: int)
signal event_changed(event_id: String)
signal town_state_changed(summary: Dictionary)

const L0_NEAR_M := 28.0
const L1_ADJ_M := 55.0
const ABSTRACT_TICK_SEC := 8.0
const EVENT_CHECK_SEC := 5.0

## Abstract town/region counters (L2) — cited when player returns.
var factions: Dictionary = _Faction.default_state()
var active_event: String = "idle"
var event_time_left: float = 120.0
var rotation_index: int = 0
var camp_threat: float = 10.0          # 0..100
var vendor_stock: float = 80.0         # 0..100
var ashfen_patrol_losses: int = 0
var marsh_wisp_pressure: float = 0.0
var scar_pressure: float = 20.0
var player_zone: String = "wake_pit"
var current_lod: int = 0               # 0/1/2
var player_elsewhere: bool = false     # dungeon / AFK offline
var last_return_summary: Dictionary = {}
var _abs_accum: float = 0.0
var _evt_accum: float = 0.0
var _player: Node3D = null
var _region_origin: Vector3 = Vector3.ZERO

func _ready() -> void:
	add_to_group("world_sim")
	call_deferred("_hydrate_from_save")

func _hydrate_from_save() -> void:
	if SaveManager == null:
		return
	var ws: Dictionary = SaveManager.data.get("world_sim", {})
	if typeof(ws) == TYPE_DICTIONARY and not ws.is_empty():
		apply_snapshot(ws)
	var fr: Dictionary = SaveManager.data.get("factions", {})
	if typeof(fr) == TYPE_DICTIONARY and not fr.is_empty():
		factions = fr.duplicate(true)
	# Sync quest consequence → rep once if still default-ish
	var qm := get_node_or_null("/root/QuestManager")
	if qm and "consequence_flag" in qm and str(qm.consequence_flag) != "":
		_maybe_sync_quest_rep(str(qm.consequence_flag))

func _maybe_sync_quest_rep(consequence: String) -> void:
	var already := bool(SaveManager.data.get("faction_synced_quest", false)) if SaveManager else false
	if already:
		return
	factions = _Faction.sync_from_quest(factions, consequence)
	if SaveManager:
		SaveManager.data["faction_synced_quest"] = true
		_persist()

func bind_player(player: Node3D) -> void:
	_player = player

func set_player_elsewhere(elsewhere: bool, reason: String = "") -> void:
	var was := player_elsewhere
	player_elsewhere = elsewhere
	if elsewhere:
		_set_lod(2)
		if EventBus and reason != "":
			EventBus.hud_toast.emit("World sim L2 — %s" % reason)
	elif was and not elsewhere:
		# Returning — surface what changed while away
		var summary := build_return_summary()
		last_return_summary = summary
		town_state_changed.emit(summary)
		if EventBus and not summary.is_empty():
			EventBus.hud_toast.emit(str(summary.get("toast", "Ashfen shifted while you were away.")))

func _process(delta: float) -> void:
	_update_zone_and_lod()
	_abs_accum += delta
	if _abs_accum >= ABSTRACT_TICK_SEC:
		var ticks := int(_abs_accum / ABSTRACT_TICK_SEC)
		_abs_accum = fmod(_abs_accum, ABSTRACT_TICK_SEC)
		_abstract_tick(ticks)
	_evt_accum += delta
	if _evt_accum >= EVENT_CHECK_SEC:
		_evt_accum = 0.0
		_tick_event(EVENT_CHECK_SEC)

func _update_zone_and_lod() -> void:
	if _player == null or not is_instance_valid(_player):
		var p := get_tree().get_first_node_in_group("player")
		if p is Node3D:
			_player = p
	if player_elsewhere:
		_set_lod(2)
		return
	if _player == null:
		return
	var pos: Vector3 = _player.global_position
	var z := _Biome.detect(pos)
	if z != player_zone:
		player_zone = z
		if EventBus:
			EventBus.hud_toast.emit("Entering %s" % _Biome.label(z))
	# LOD vs Ashfen Gate hub (town + market)
	var town := Vector3(0, 0, 22)
	var dist := pos.distance_to(town)
	# Also consider Ember Camp as L0 hub when nearby
	var camp_d := pos.distance_to(Vector3(14, 0, 6))
	var near := minf(dist, camp_d)
	if near <= L0_NEAR_M:
		_set_lod(0)
	elif near <= L1_ADJ_M:
		_set_lod(1)
	else:
		_set_lod(2)

func _set_lod(lod: int) -> void:
	if lod == current_lod:
		return
	current_lod = lod
	lod_changed.emit(lod)
	# Notify scheduled NPCs
	for n in get_tree().get_nodes_in_group("scheduled_npc"):
		if n.has_method("set_sim_lod"):
			n.set_sim_lod(lod)

func _abstract_tick(ticks: int = 1) -> void:
	# L2 (and light L1) advances regional counters even when player is in wilds/dungeon/AFK
	var rate := 1.0
	if current_lod == 0 and not player_elsewhere:
		rate = 0.35  # slow drip while present
	elif current_lod == 1:
		rate = 0.7
	else:
		rate = 1.25 if player_elsewhere else 1.0
	for _i in range(ticks):
		camp_threat = clampf(camp_threat + randf_range(-1.5, 2.2) * rate, 0.0, 100.0)
		vendor_stock = clampf(vendor_stock + randf_range(-2.0, 1.5) * rate, 10.0, 100.0)
		marsh_wisp_pressure = clampf(marsh_wisp_pressure + randf_range(-1.0, 2.5) * rate, 0.0, 100.0)
		scar_pressure = clampf(scar_pressure + randf_range(-0.8, 1.8) * rate, 0.0, 100.0)
		var rivalry := float(factions.get("rivalry_pressure", 0.0))
		rivalry = clampf(rivalry + randf_range(-0.5, 1.2) * rate, 0.0, 100.0)
		factions["rivalry_pressure"] = rivalry
		# Patrol losses when threat high and player elsewhere
		if player_elsewhere or current_lod >= 2:
			if camp_threat > 55.0 and randf() < 0.12 * rate:
				ashfen_patrol_losses += 1
				camp_threat = maxf(camp_threat - 8.0, 20.0)
		# Event-driven pressure
		if active_event == "scar_alarm":
			scar_pressure = minf(scar_pressure + 3.0 * rate, 100.0)
		elif active_event == "vein_storm":
			marsh_wisp_pressure = minf(marsh_wisp_pressure + 4.0 * rate, 100.0)
		elif active_event == "market_day":
			vendor_stock = minf(vendor_stock + 5.0 * rate, 100.0)
	_persist()

func _tick_event(dt: float) -> void:
	event_time_left -= dt
	if event_time_left > 0.0:
		return
	_advance_rotation()

func _advance_rotation() -> void:
	rotation_index = (rotation_index + 1) % _Events.ROTATION.size()
	var next_id: String = str(_Events.ROTATION[rotation_index])
	active_event = next_id
	if next_id == "idle":
		event_time_left = _Events.IDLE_DURATION
	else:
		var d: Dictionary = _Events.def(next_id)
		event_time_left = float(d.get("duration_sec", 120.0))
		if EventBus:
			EventBus.hud_toast.emit(str(d.get("bark", next_id)))
	event_changed.emit(active_event)
	_persist()

## Advance wall-clock while AFK offline / app paused (L3 statistical).
func advance_offline(sec: float) -> Dictionary:
	var ticks := maxi(1, int(sec / ABSTRACT_TICK_SEC))
	var was := player_elsewhere
	player_elsewhere = true
	_set_lod(2)
	# Fast-forward events roughly
	var left := sec
	while left > 0.0:
		var step: float = minf(left, maxf(event_time_left, 1.0))
		event_time_left -= step
		left -= step
		if event_time_left <= 0.0:
			_advance_rotation()
	_abstract_tick(ticks)
	player_elsewhere = was
	var summary := build_return_summary()
	last_return_summary = summary
	_persist()
	return summary

func build_return_summary() -> Dictionary:
	var lines: Array = []
	lines.append("Ashfen patrol losses: %d" % ashfen_patrol_losses)
	lines.append("Ember Camp threat: %d" % int(camp_threat))
	lines.append("Vendor stock: %d%%" % int(vendor_stock))
	lines.append("Scar pressure: %d" % int(scar_pressure))
	if active_event != "idle":
		var d := _Events.def(active_event)
		lines.append("Active: %s" % str(d.get("display", active_event)))
	var toast := "While away — patrol losses %d, camp threat %d." % [ashfen_patrol_losses, int(camp_threat)]
	return {
		"toast": toast,
		"lines": lines,
		"patrol_losses": ashfen_patrol_losses,
		"camp_threat": camp_threat,
		"vendor_stock": vendor_stock,
		"scar_pressure": scar_pressure,
		"marsh_wisp_pressure": marsh_wisp_pressure,
		"active_event": active_event,
		"lod": current_lod,
	}

func add_reputation(faction: String, delta: int) -> void:
	factions = _Faction.apply_delta(factions, faction, delta)
	if EventBus:
		EventBus.faction_rep_changed.emit(faction, int(factions.get(faction, 0)))
	_persist()

func on_quest_consequence(kind: String) -> void:
	factions = _Faction.sync_from_quest(factions, kind)
	if SaveManager:
		SaveManager.data["faction_synced_quest"] = true
	if kind == "helped_concord":
		camp_threat = maxf(camp_threat - 15.0, 0.0)
		scar_pressure = maxf(scar_pressure - 10.0, 0.0)
	elif kind == "ignored_scar":
		scar_pressure = minf(scar_pressure + 20.0, 100.0)
		ashfen_patrol_losses += 1
	_persist()

## Economy: final buy price (player pays).
func buy_price(base: int, vendor_faction: String = "gray_concord") -> int:
	var m := _Faction.buy_mult(factions, vendor_faction)
	m *= _Events.price_multiplier(active_event)
	# Low stock → markup
	if vendor_stock < 35.0:
		m *= 1.15
	return maxi(1, int(round(float(base) * m)))

## Economy: sell payout (player receives).
func sell_price(base: int, vendor_faction: String = "gray_concord") -> int:
	var m := _Faction.sell_mult(factions, vendor_faction)
	# Market day boosts sell slightly
	if active_event == "market_day":
		m *= 1.1
	if vendor_stock > 85.0:
		m *= 0.95  # saturated market
	return maxi(1, int(round(float(base) * m)))

func spawn_weight(zone_id: String, role: String) -> float:
	var info := _Biome.zone_info(zone_id)
	var bias: Dictionary = info.get("spawn_bias", {})
	var w := float(bias.get(role, 0.2))
	w *= _Events.spawn_multiplier(active_event, zone_id)
	# Abstract pressure
	if zone_id == "heat_sink_scar":
		w *= 1.0 + scar_pressure / 200.0
	if zone_id == "vein_marsh":
		w *= 1.0 + marsh_wisp_pressure / 180.0
	if zone_id == "aetherwood":
		w *= 1.0 + camp_threat / 250.0
	return w

func event_bark(npc_kind: String) -> String:
	return _Events.bark_for(active_event, npc_kind)

func faction_bark(npc_kind: String) -> String:
	return _Faction.bark_suffix(factions, npc_kind)

func zone_move_mult(zone_id: String = "") -> float:
	var z := zone_id if zone_id != "" else player_zone
	return float(_Biome.zone_info(z).get("move_mult", 1.0))

func snapshot() -> Dictionary:
	return {
		"factions": factions.duplicate(true),
		"active_event": active_event,
		"event_time_left": event_time_left,
		"rotation_index": rotation_index,
		"camp_threat": camp_threat,
		"vendor_stock": vendor_stock,
		"ashfen_patrol_losses": ashfen_patrol_losses,
		"marsh_wisp_pressure": marsh_wisp_pressure,
		"scar_pressure": scar_pressure,
		"player_zone": player_zone,
		"last_return_summary": last_return_summary.duplicate(true),
	}

func apply_snapshot(data: Dictionary) -> void:
	if data.has("factions") and typeof(data["factions"]) == TYPE_DICTIONARY:
		factions = data["factions"].duplicate(true)
	active_event = str(data.get("active_event", "idle"))
	event_time_left = float(data.get("event_time_left", 120.0))
	rotation_index = int(data.get("rotation_index", 0))
	camp_threat = float(data.get("camp_threat", 10.0))
	vendor_stock = float(data.get("vendor_stock", 80.0))
	ashfen_patrol_losses = int(data.get("ashfen_patrol_losses", 0))
	marsh_wisp_pressure = float(data.get("marsh_wisp_pressure", 0.0))
	scar_pressure = float(data.get("scar_pressure", 20.0))
	player_zone = str(data.get("player_zone", "wake_pit"))
	var lrs = data.get("last_return_summary", {})
	if typeof(lrs) == TYPE_DICTIONARY:
		last_return_summary = lrs.duplicate(true)

func _persist() -> void:
	if SaveManager == null:
		return
	SaveManager.data["world_sim"] = snapshot()
	SaveManager.data["factions"] = factions.duplicate(true)
