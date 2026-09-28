extends CanvasLayer
## Mobile touch HUD — left stick, look/swipe zone, ATK/skills/dodge/jump/interact.
## Default layout (remappable later):
##   Left lower: virtual stick
##   Right lower cluster: ATK (large), DODGE, S1, S2, JUMP, USE
##   Right half swipe: camera orbit; two-finger pinch: zoom

signal attack_pressed
signal dodge_pressed
signal skill_pressed(slot: int)
signal jump_pressed
signal interact_pressed

@export var player_path: NodePath
@export var camera_path: NodePath

var _player: Node = null
var _stick_origin := Vector2.ZERO
var _stick_touch_index := -1
var _look_touch_index := -1
var _look_last := Vector2.ZERO
var _pinch_ids: Array[int] = []
var _pinch_start_dist := 0.0
var _touch_pos: Dictionary = {}

@onready var _stick_base: Control = $Root/LeftStick
@onready var _stick_knob: Control = $Root/LeftStick/Knob
@onready var _look_zone: Control = $Root/LookZone

func _ready() -> void:
	if player_path:
		_player = get_node_or_null(player_path)
	_stick_base.gui_input.connect(_on_stick_gui)
	_look_zone.gui_input.connect(_on_look_gui)
	$Root/RightCluster/Attack.pressed.connect(func():
		attack_pressed.emit()
		EventBus.action_attack.emit()
	)
	$Root/RightCluster/Dodge.pressed.connect(func():
		dodge_pressed.emit()
		EventBus.action_dodge.emit()
	)
	$Root/RightCluster/Skill1.pressed.connect(func():
		skill_pressed.emit(1)
		EventBus.action_skill.emit(1)
	)
	$Root/RightCluster/Skill2.pressed.connect(func():
		skill_pressed.emit(2)
		EventBus.action_skill.emit(2)
	)
	$Root/RightCluster/Jump.pressed.connect(func():
		jump_pressed.emit()
		EventBus.action_jump.emit()
		if _player and _player.has_method("request_jump"):
			_player.request_jump()
	)
	$Root/RightCluster/Interact.pressed.connect(func():
		interact_pressed.emit()
		EventBus.action_interact.emit()
	)

func bind_player(p: Node) -> void:
	_player = p

func _on_stick_gui(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_stick_touch_index = event.index
			_stick_origin = event.position
			_update_stick(event.position)
		elif event.index == _stick_touch_index:
			_stick_touch_index = -1
			_set_move(Vector2.ZERO)
			_stick_knob.position = (_stick_base.size - _stick_knob.size) * 0.5
	elif event is InputEventScreenDrag and event.index == _stick_touch_index:
		_update_stick(event.position)

func _update_stick(pos: Vector2) -> void:
	var center := _stick_base.size * 0.5
	var delta := pos - _stick_origin
	var max_r := minf(_stick_base.size.x, _stick_base.size.y) * 0.4
	var clamped := delta.limit_length(max_r)
	_stick_knob.position = center - _stick_knob.size * 0.5 + clamped
	_set_move(Vector2(clamped.x / max_r, clamped.y / max_r))

func _set_move(dir: Vector2) -> void:
	if _player and _player.has_method("set_touch_move"):
		_player.set_touch_move(Vector2(dir.x, dir.y))

func _on_look_gui(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_touch_pos[event.index] = event.position
			if event.index not in _pinch_ids and _pinch_ids.size() < 2:
				_pinch_ids.append(event.index)
			if _pinch_ids.size() == 1:
				_look_touch_index = event.index
				_look_last = event.position
			elif _pinch_ids.size() == 2:
				_look_touch_index = -1
				_pinch_start_dist = _pinch_distance()
		else:
			_touch_pos.erase(event.index)
			_pinch_ids.erase(event.index)
			if event.index == _look_touch_index:
				_look_touch_index = -1
			if _pinch_ids.size() < 2:
				_pinch_start_dist = 0.0
	elif event is InputEventScreenDrag:
		_touch_pos[event.index] = event.position
		if _pinch_ids.size() >= 2:
			var d := _pinch_distance()
			if _pinch_start_dist > 1.0 and _player and _player.has_method("add_pinch_zoom"):
				var delta := (_pinch_start_dist - d) * 0.01
				_player.add_pinch_zoom(delta)
				_pinch_start_dist = d
		elif event.index == _look_touch_index:
			var delta: Vector2 = event.position - _look_last
			_look_last = event.position
			if _player and _player.has_method("add_touch_look"):
				_player.add_touch_look(delta)

func _pinch_distance() -> float:
	if _pinch_ids.size() < 2:
		return 0.0
	var a: Vector2 = _touch_pos.get(_pinch_ids[0], Vector2.ZERO)
	var b: Vector2 = _touch_pos.get(_pinch_ids[1], Vector2.ZERO)
	return a.distance_to(b)
