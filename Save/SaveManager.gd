extends Node
const _Attributes = preload("res://Character/Attributes.gd")
const _SkillNodes = preload("res://Character/SkillNodes.gd")
## Corruption-safe autosave — position, combat, kit, quest, equip, companion, AFK, world sim, factions.

const SAVE_VERSION := 6
const SAVE_DIR := "user://saves"
const SAVE_NAME := "autosave.json"
const TEMP_NAME := "autosave.json.tmp"
const AUTOSAVE_INTERVAL_SEC := 30.0

var data: Dictionary = {
	"version": SAVE_VERSION,
	"player_position": {"x": 0.0, "y": 1.2, "z": 36.0},
	"hp": 120.0,
	"max_hp": 120.0,
	"stamina": 100.0,
	"focus": 100.0,
	"heat": 0.0,
	"kit_id": "Ashblade",
	"xp": 0,
	"gold": 0,
	"inventory": [],
	"equipment": {"weapon": "", "armor": "", "charm": ""},
	"companion_id": "",
	"potions": 3,
	"scene": "emberveil",
	"quest": {},
	"afk_running": false,
	"afk_profile": "Balanced",
	"afk_started_unix": 0.0,
	"last_afk_report": {},
	"control_layout": "default",
	"control_stick_side": "left",
	"level": 1,
	"attr_sheet": {},
	"skill_state": {},
	"factions": {},
	"world_sim": {},
	"faction_synced_quest": false,
}
var _player: Node3D
var _timer: Timer

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	_timer = Timer.new()
	_timer.wait_time = AUTOSAVE_INTERVAL_SEC
	_timer.autostart = true
	_timer.timeout.connect(_on_autosave)
	add_child(_timer)
	EventBus.request_save.connect(save)
	EventBus.request_load.connect(load_save)

func register_player(player: Node3D) -> void:
	_player = player

func _on_autosave() -> void:
	if _player and is_instance_valid(_player):
		capture_from_player(_player)
	save()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST \
			or what == NOTIFICATION_APPLICATION_PAUSED \
			or what == NOTIFICATION_EXIT_TREE:
		if _player and is_instance_valid(_player):
			capture_from_player(_player)
		var afk := get_node_or_null("/root/AfkManager")
		if afk and afk.running and afk.has_method("notification_paused"):
			afk.notification_paused()
		save()

func capture_player_transform(player: Node3D) -> void:
	var p := player.global_position
	data["player_position"] = {"x": p.x, "y": p.y, "z": p.z}

func capture_from_player(player: Node3D) -> void:
	capture_player_transform(player)
	data["version"] = SAVE_VERSION
	if player.has_method("get_kit_id"):
		data["kit_id"] = player.get_kit_id()
	if "xp" in player:
		data["xp"] = player.xp
	if "gold" in player:
		data["gold"] = player.gold
	if "inventory" in player:
		data["inventory"] = player.inventory.duplicate()
	if "equipment" in player:
		data["equipment"] = player.equipment.duplicate(true)
	if "companion_id" in player:
		data["companion_id"] = player.companion_id
	if "potions" in player:
		data["potions"] = player.potions
	if "attr_sheet" in player:
		data["attr_sheet"] = player.attr_sheet.duplicate(true)
		data["level"] = int(player.attr_sheet.get("level", 1))
	if "skill_state" in player:
		data["skill_state"] = player.skill_state.duplicate(true)
	var c = player.get("combat")
	if c:
		data["hp"] = c.hp
		data["max_hp"] = c.max_hp
		data["stamina"] = c.stamina
		data["focus"] = c.focus
		data["heat"] = c.heat
	var qm := get_node_or_null("/root/QuestManager")
	if qm and qm.has_method("snapshot"):
		data["quest"] = qm.snapshot()
	var ws := get_node_or_null("/root/WorldSim")
	if ws and ws.has_method("snapshot"):
		data["world_sim"] = ws.snapshot()
		data["factions"] = ws.factions.duplicate(true)

func apply_player_transform(player: Node3D) -> void:
	var p: Dictionary = data.get("player_position", {})
	player.global_position = Vector3(
		float(p.get("x", 0.0)),
		float(p.get("y", 1.2)),
		float(p.get("z", 36.0))
	)

func apply_to_player(player: Node3D) -> void:
	apply_player_transform(player)
	if player.has_method("set_kit_id"):
		player.set_kit_id(str(data.get("kit_id", "Ashblade")))
	if "xp" in player:
		player.xp = int(data.get("xp", 0))
	if "gold" in player:
		player.gold = int(data.get("gold", 0))
	if "inventory" in player:
		player.inventory = data.get("inventory", []).duplicate()
	if "equipment" in player:
		player.equipment = data.get("equipment", {"weapon": "", "armor": "", "charm": ""}).duplicate(true)
		if player.has_method("_recalc_equip"):
			player._recalc_equip()
	if "companion_id" in player:
		player.companion_id = str(data.get("companion_id", ""))
		if player.companion_id != "" and player.has_method("recruit_companion"):
			player.call_deferred("recruit_companion", player.companion_id)
	if "potions" in player:
		player.potions = int(data.get("potions", 3))
	if "attr_sheet" in player:
		var sheet = data.get("attr_sheet", {})
		if typeof(sheet) == TYPE_DICTIONARY and not sheet.is_empty():
			player.attr_sheet = sheet.duplicate(true)
		elif player.attr_sheet.is_empty():
			player.attr_sheet = _Attributes.make_sheet()
		# Sync xp field
		if "xp" in player:
			player.attr_sheet["xp"] = int(player.attr_sheet.get("xp", player.xp))
	if "skill_state" in player:
		var sk = data.get("skill_state", {})
		if typeof(sk) == TYPE_DICTIONARY and not sk.is_empty():
			player.skill_state = sk.duplicate(true)
		elif player.skill_state.is_empty():
			player.skill_state = _SkillNodes.make_state(str(data.get("kit_id", "Ashblade")))
	var c = player.get("combat")
	if c and c.has_method("apply_snapshot"):
		c.apply_snapshot({
			"hp": data.get("hp", 120.0),
			"max_hp": data.get("max_hp", 120.0),
			"stamina": data.get("stamina", 100.0),
			"focus": data.get("focus", 100.0),
			"heat": data.get("heat", 0.0),
		})
	var qm := get_node_or_null("/root/QuestManager")
	if qm and qm.has_method("apply_snapshot") and data.has("quest"):
		qm.apply_snapshot(data.get("quest", {}))
	var ws := get_node_or_null("/root/WorldSim")
	if ws and ws.has_method("apply_snapshot"):
		if data.has("world_sim") and typeof(data["world_sim"]) == TYPE_DICTIONARY:
			ws.apply_snapshot(data.get("world_sim", {}))
		if data.has("factions") and typeof(data["factions"]) == TYPE_DICTIONARY and not data["factions"].is_empty():
			ws.factions = data["factions"].duplicate(true)

func set_scene_id(id: String) -> void:
	data["scene"] = id

func get_scene_id() -> String:
	return str(data.get("scene", "emberveil"))

func save() -> bool:
	data["version"] = SAVE_VERSION
	data["saved_at_unix"] = Time.get_unix_time_from_system()
	var json := JSON.stringify(data, "\t")
	var temp_path := SAVE_DIR.path_join(TEMP_NAME)
	var final_path := SAVE_DIR.path_join(SAVE_NAME)
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		push_warning("SaveManager: cannot open temp (%s)" % FileAccess.get_open_error())
		return false
	file.store_string(json)
	file.flush()
	file.close()
	if FileAccess.file_exists(final_path):
		DirAccess.remove_absolute(final_path)
	var err := DirAccess.rename_absolute(temp_path, final_path)
	if err != OK:
		push_warning("SaveManager: rename failed (%s)" % err)
		return false
	return true

func load_save() -> bool:
	var path := SAVE_DIR.path_join(SAVE_NAME)
	if not FileAccess.file_exists(path):
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("SaveManager: corrupt JSON")
		return false
	var loaded: Dictionary = parsed
	var ver := int(loaded.get("version", 0))
	if ver < 1 or ver > SAVE_VERSION:
		push_warning("SaveManager: unsupported version")
		return false
	if not loaded.has("kit_id"):
		loaded["kit_id"] = "Ashblade"
	if not loaded.has("xp"):
		loaded["xp"] = 0
	if not loaded.has("gold"):
		loaded["gold"] = 0
	if not loaded.has("equipment"):
		loaded["equipment"] = {"weapon": "", "armor": "", "charm": ""}
	if not loaded.has("quest"):
		loaded["quest"] = {}
	if not loaded.has("control_layout"):
		loaded["control_layout"] = "default"
	if not loaded.has("control_stick_side"):
		loaded["control_stick_side"] = "left"
	if not loaded.has("attr_sheet"):
		loaded["attr_sheet"] = {}
	if not loaded.has("skill_state"):
		loaded["skill_state"] = {}
	if not loaded.has("level"):
		loaded["level"] = 1
	loaded["version"] = SAVE_VERSION
	data = loaded
	return true


func get_control_layout() -> String:
	return str(data.get("control_layout", "default"))

func get_control_stick_side() -> String:
	return str(data.get("control_stick_side", "left"))

func set_control_layout(layout_id: String, stick_side: String = "") -> void:
	data["control_layout"] = layout_id
	if stick_side != "":
		data["control_stick_side"] = stick_side
	elif layout_id == "left_hand":
		data["control_stick_side"] = "right"
	elif layout_id == "default":
		data["control_stick_side"] = "left"
	save()

func save_game() -> bool:
	if _player and is_instance_valid(_player):
		capture_from_player(_player)
	return save()

func load_game() -> bool:
	if not load_save():
		return false
	if _player and is_instance_valid(_player):
		apply_to_player(_player)
		return true
	return false

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_DIR.path_join(SAVE_NAME))
