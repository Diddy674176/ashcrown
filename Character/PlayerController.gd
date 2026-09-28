extends CharacterBody3D
## Phase 1 player — keyboard + touch stick. Walk/run/jump; combat verbs stubbed.
## Default layout: left stick move | right swipe look | ATK/DODGE/S1/S2/JUMP/USE.

const WALK_SPEED := 4.5
const SPRINT_SPEED := 7.0
const JUMP_VELOCITY := 4.5
const GRAVITY := 12.0
const MIN_CAM_DIST := 2.5
const MAX_CAM_DIST := 10.0

@export var mouse_sensitivity := 0.003
@export var touch_look_sensitivity := 0.004

var _touch_move := Vector2.ZERO
var _camera_pitch := -15.0
var _yaw := 0.0
var _cam_distance := 4.5
var _jump_queued := false

@onready var _pivot: Node3D = $CameraPivot
@onready var _camera: Camera3D = $CameraPivot/Camera3D

func _ready() -> void:
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1
	if SaveManager:
		SaveManager.register_player(self)
		SaveManager.load_save()
		SaveManager.apply_player_transform(self)
	_apply_cam_distance()

func set_touch_move(dir: Vector2) -> void:
	_touch_move = dir.limit_length(1.0)

func add_touch_look(delta: Vector2) -> void:
	_yaw -= delta.x * touch_look_sensitivity
	_camera_pitch = clampf(_camera_pitch - delta.y * touch_look_sensitivity * 60.0, -60.0, 45.0)
	rotation.y = _yaw
	if _pivot:
		_pivot.rotation.x = deg_to_rad(_camera_pitch)

func add_pinch_zoom(delta_dist: float) -> void:
	_cam_distance = clampf(_cam_distance + delta_dist, MIN_CAM_DIST, MAX_CAM_DIST)
	_apply_cam_distance()

func request_jump() -> void:
	_jump_queued = true

func _apply_cam_distance() -> void:
	if _camera:
		_camera.position = Vector3(0, 0.4, _cam_distance)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_yaw -= event.relative.x * mouse_sensitivity
		_camera_pitch = clampf(_camera_pitch - event.relative.y * mouse_sensitivity * 60.0, -60.0, 45.0)
		rotation.y = _yaw
		if _pivot:
			_pivot.rotation.x = deg_to_rad(_camera_pitch)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			add_pinch_zoom(-0.35)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			add_pinch_zoom(0.35)
	elif event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	var input_dir := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_forward", "move_back")
	)
	if _touch_move.length_squared() > 0.01:
		input_dir = _touch_move

	var direction := (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	var speed := SPRINT_SPEED if Input.is_action_pressed("sprint") else WALK_SPEED
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed)
		velocity.z = move_toward(velocity.z, 0.0, speed)

	if (_jump_queued or Input.is_action_just_pressed("jump")) and is_on_floor():
		velocity.y = JUMP_VELOCITY
	_jump_queued = false

	move_and_slide()

func capture_to_save() -> void:
	if SaveManager:
		SaveManager.capture_player_transform(self)
		SaveManager.save()
