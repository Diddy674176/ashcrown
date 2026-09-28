extends Node3D
class_name FollowCamera
## Third-person follow cam: touch swipe orbit + pinch zoom (mobile).

@export var target_path: NodePath
@export var follow_offset: Vector3 = Vector3(0, 1.6, 0)
@export var min_distance: float = 2.5
@export var max_distance: float = 10.0
@export var default_distance: float = 5.0
@export var min_pitch_deg: float = -55.0
@export var max_pitch_deg: float = 70.0
@export var orbit_sensitivity: float = 0.004
@export var pinch_zoom_sensitivity: float = 0.01
@export var mouse_sensitivity: float = 0.003

var _target: Node3D
var _yaw: float = 0.0
var _pitch: float = 0.25
var _distance: float = 5.0
var _pinch_active: bool = false
var _pinch_start_dist: float = 0.0
var _pinch_start_zoom: float = 5.0

@onready var _cam: Camera3D = $Camera3D

func _ready() -> void:
	_distance = default_distance
	if target_path != NodePath(""):
		_target = get_node_or_null(target_path)

func bind_target(t: Node3D) -> void:
	_target = t

func get_yaw() -> float:
	return _yaw

func add_orbit_delta(relative: Vector2) -> void:
	_yaw -= relative.x * orbit_sensitivity
	_pitch -= relative.y * orbit_sensitivity
	_pitch = clampf(_pitch, deg_to_rad(min_pitch_deg), deg_to_rad(max_pitch_deg))

func add_zoom(delta_dist: float) -> void:
	_distance = clampf(_distance + delta_dist, min_distance, max_distance)

func _process(_delta: float) -> void:
	if _target == null or not is_instance_valid(_target):
		return
	var pivot: Vector3 = _target.global_position + follow_offset
	var offset := Vector3(0, 0, _distance)
	offset = offset.rotated(Vector3.RIGHT, _pitch)
	offset = offset.rotated(Vector3.UP, _yaw)
	global_position = pivot + offset
	look_at(pivot, Vector3.UP)
	if _target.has_method("set_camera_yaw"):
		_target.set_camera_yaw(_yaw)

func _unhandled_input(event: InputEvent) -> void:
	# Desktop editor fallback
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		add_orbit_delta(event.relative)
	elif event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			add_zoom(-0.4)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			add_zoom(0.4)
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
