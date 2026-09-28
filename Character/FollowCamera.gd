extends Node3D
class_name FollowCamera
## Optional third-person follow cam (Player.tscn embeds CameraPivot for Phase 1).

@export var target_path: NodePath
@export var follow_offset: Vector3 = Vector3(0, 1.6, 0)
@export var min_distance: float = 2.5
@export var max_distance: float = 10.0
@export var default_distance: float = 5.0
@export var orbit_sensitivity: float = 0.004

var _target: Node3D
var _yaw: float = 0.0
var _pitch: float = 0.25
var _distance: float = 5.0

func _ready() -> void:
	_distance = default_distance
	if target_path != NodePath(""):
		_target = get_node_or_null(target_path)

func bind_target(t: Node3D) -> void:
	_target = t

func add_orbit_delta(relative: Vector2) -> void:
	_yaw -= relative.x * orbit_sensitivity
	_pitch = clampf(_pitch - relative.y * orbit_sensitivity, deg_to_rad(-55.0), deg_to_rad(70.0))

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
