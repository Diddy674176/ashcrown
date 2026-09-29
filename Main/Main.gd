extends Node3D
## Bootstrap - Emberveil Reach playable slice + Coilcrypt load.

@onready var player: CharacterBody3D = $Player
@onready var touch: CanvasLayer = $TouchControls
@onready var streamer: Node3D = $ChunkStreamer
@onready var region: Node3D = $EmberveilReach

var _dungeon: Node3D = null
var _in_dungeon: bool = false

func _ready() -> void:
	if touch.has_method("bind_player"):
		touch.bind_player(player)
	if streamer and streamer.has_method("bind_player"):
		streamer.bind_player(player)
	EventBus.player_spawned.emit(player)
	EventBus.player_interact.connect(_on_player_interact)
	EventBus.enter_dungeon_requested.connect(_on_enter_dungeon)
	EventBus.exit_dungeon_requested.connect(_exit_coilcrypt)
	if SaveManager and not SaveManager.has_save():
		player.global_position = Vector3(0, 1.2, 16)
	# Kit default Ashblade already on player; toast intro
	EventBus.hud_toast.emit("Emberveil Reach — mites east · Coilcrypt north · MODE/AFK top-right")

func _on_player_interact(p: Node) -> void:
	if _in_dungeon:
		if _dungeon and _dungeon.has_method("is_player_at_exit") and _dungeon.is_player_at_exit(p):
			_exit_coilcrypt()
		return
	if region and region.has_method("is_player_at_coilcrypt") and region.is_player_at_coilcrypt(p):
		_enter_coilcrypt()

func _on_enter_dungeon(dungeon_id: String) -> void:
	if dungeon_id == "coilcrypt":
		_enter_coilcrypt()

func _enter_coilcrypt() -> void:
	if _in_dungeon:
		return
	var qm := get_node_or_null("/root/QuestManager")
	if qm and qm.has_method("try_ignore_consequence"):
		qm.try_ignore_consequence()
	_in_dungeon = true
	if region:
		region.visible = false
		# Disable region physics processing lightly
		region.process_mode = Node.PROCESS_MODE_DISABLED
	var ctrl_script: GDScript = load("res://Dungeons/Coilcrypt/CoilcryptController.gd") as GDScript
	_dungeon = ctrl_script.new()
	add_child(_dungeon)
	player.global_position = _dungeon.get_player_entry()
	if SaveManager:
		SaveManager.set_scene_id("coilcrypt")
		player.capture_to_save()
	EventBus.hud_toast.emit("Entered Coilcrypt")

func _exit_coilcrypt() -> void:
	if not _in_dungeon:
		return
	_in_dungeon = false
	if _dungeon and is_instance_valid(_dungeon):
		_dungeon.queue_free()
		_dungeon = null
	if region:
		region.visible = true
		region.process_mode = Node.PROCESS_MODE_INHERIT
	player.global_position = Vector3(0, 1.2, -20)  # just outside mouth
	if SaveManager:
		SaveManager.set_scene_id("emberveil")
		player.capture_to_save()
	EventBus.hud_toast.emit("Returned to Emberveil Reach")

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		if player and player.has_method("capture_to_save"):
			player.capture_to_save()
