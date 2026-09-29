extends Node3D
## Bootstrap - Emberveil Reach playable slice + Coilcrypt load.

const _InventoryPanel = preload("res://UI/InventoryPanel.gd")
const _CharacterPanel = preload("res://UI/CharacterPanel.gd")
const _DialoguePanel = preload("res://UI/DialoguePanel.gd")

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
	_mount_rpg_ui()
	EventBus.player_spawned.emit(player)
	EventBus.player_interact.connect(_on_player_interact)
	EventBus.enter_dungeon_requested.connect(_on_enter_dungeon)
	EventBus.exit_dungeon_requested.connect(_exit_coilcrypt)
	if SaveManager and not SaveManager.has_save():
		player.global_position = Vector3(0, 1.2, 36)
	EventBus.hud_toast.emit("0.3.0 — Inventory/Attrs/Skills · Len choice · equip power")

func _mount_rpg_ui() -> void:
	var inv = _InventoryPanel.new()
	inv.name = "InventoryPanel"
	add_child(inv)
	inv.bind_player(player)
	var charp = _CharacterPanel.new()
	charp.name = "CharacterPanel"
	add_child(charp)
	charp.bind_player(player)
	var dlg = _DialoguePanel.new()
	dlg.name = "DialoguePanel"
	add_child(dlg)
	dlg.effect_requested.connect(_on_dialogue_effect)
	if touch and touch.has_method("bind_rpg_panels"):
		touch.bind_rpg_panels(inv, charp, dlg)

func _on_dialogue_effect(effect: String) -> void:
	var qm := get_node_or_null("/root/QuestManager")
	if qm and qm.has_method("handle_dialogue_effect"):
		qm.handle_dialogue_effect(effect)

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
	player.global_position = Vector3(0, 1.2, -20)
	if SaveManager:
		SaveManager.set_scene_id("emberveil")
		player.capture_to_save()
	EventBus.hud_toast.emit("Returned to Emberveil Reach")

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		if player and player.has_method("capture_to_save"):
			player.capture_to_save()
