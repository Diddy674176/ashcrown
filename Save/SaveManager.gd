extends Node
## Corruption-safe autosave - position, HP, kit, xp/gold.

const SAVE_VERSION := 2
const SAVE_DIR := "user://saves"
const SAVE_NAME := "autosave.json"
const TEMP_NAME := "autosave.json.tmp"
const AUTOSAVE_INTERVAL_SEC := 30.0

var data: Dictionary = {
	"version": SAVE_VERSION,
	"player_position": {"x": 0.0, "y": 1.2, "z": 16.0},
	"hp": 120.0,
	"max_hp": 120.0,
	"stamina": 100.0,
	"focus": 100.0,
	"heat": 0.0,
	"kit_id": "Ashblade",
	"xp": 0,
	"gold": 0,
	"inventory": [],
	"scene": "emberveil",
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
	var c = player.get("combat")
	if c:
		data["hp"] = c.hp
		data["max_hp"] = c.max_hp
		data["stamina"] = c.stamina
		data["focus"] = c.focus
		data["heat"] = c.heat

func apply_player_transform(player: Node3D) -> void:
	var p: Dictionary = data.get("player_position", {})
	player.global_position = Vector3(
		float(p.get("x", 0.0)),
		float(p.get("y", 1.2)),
		float(p.get("z", 16.0))
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
	var c = player.get("combat")
	if c and c.has_method("apply_snapshot"):
		c.apply_snapshot({
			"hp": data.get("hp", 120.0),
			"max_hp": data.get("max_hp", 120.0),
			"stamina": data.get("stamina", 100.0),
			"focus": data.get("focus", 100.0),
			"heat": data.get("heat", 0.0),
		})

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
	loaded["version"] = SAVE_VERSION
	data = loaded
	return true

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
