extends Node3D
## Phase 1 bootstrap — Emberveil Reach graybox + player + touch HUD + streaming stub.

@onready var player: CharacterBody3D = $Player
@onready var touch: CanvasLayer = $TouchControls
@onready var streamer: Node3D = $ChunkStreamer
@onready var region: Node3D = $EmberveilReach

func _ready() -> void:
	if touch.has_method("bind_player"):
		touch.bind_player(player)
	if streamer and streamer.has_method("bind_player"):
		streamer.bind_player(player)
	EventBus.player_spawned.emit(player)
	# Ensure spawn near Ashfen Gate if no save
	if SaveManager and not SaveManager.has_save():
		player.global_position = Vector3(0, 1.2, 16)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		if player and player.has_method("capture_to_save"):
			player.capture_to_save()
