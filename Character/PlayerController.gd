extends CharacterBody3D
## Playable mobile player

const _CombatActor = preload("res://Combat/CombatActor.gd")

const WALK_SPEED := 4.5
const SPRINT_SPEED := 7.0
const JUMP_VELOCITY := 4.5
const GRAVITY := 12.0
const MIN_CAM_DIST := 2.5
const MAX_CAM_DIST := 10.0
const LIGHT_DMG := 14.0
const HEAVY_DMG := 26.0
const CHARGED_DMG := 40.0
const SKILL1_DMG := 22.0
const SKILL2_DMG := 18.0
const ATTACK_RANGE := 2.6
const DODGE_COST := 22.0
const DODGE_IFRAMES := 0.35
const DODGE_SPEED := 11.0
const LIGHT_STAMINA := 8.0
const HEAVY_STAMINA := 18.0
const CHARGED_STAMINA := 28.0
const SKILL_FOCUS := 20.0
const HEAVY_HOLD_SEC := 0.35
const CHARGED_HOLD_SEC := 0.85

@export var mouse_sensitivity := 0.003
@export var touch_look_sensitivity := 0.0045

var _touch_move := Vector2.ZERO
var _camera_pitch := -15.0
var _yaw := 0.0
var _cam_distance := 4.5
var _jump_queued := false
var _dodge_queued := false
var _attack_down_msec := 0
var _blocking := false
var _dodge_timer := 0.0
var _attack_lock := 0.0
var _kit_id: String = "Ashblade"
var xp: int = 0
var gold: int = 0
var inventory: Array = []

var combat

@onready var _pivot: Node3D = $CameraPivot
@onready var _camera: Camera3D = $CameraPivot/Camera3D

func _ready() -> void:
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1 | 4
	combat = _CombatActor.new()
	combat.name = "Combat"
	combat.max_hp = 120.0
	combat.max_stamina = 100.0
	combat.max_focus = 100.0
	combat.team = &"player"
	add_child(combat)
	combat.died.connect(_on_player_died)
	if SaveManager:
		SaveManager.register_player(self)
		SaveManager.load_save()
		SaveManager.apply_to_player(self)
	_apply_cam_distance()
	if EventBus:
		EventBus.action_attack.connect(_on_attack_tap)
		EventBus.action_dodge.connect(request_dodge)
		EventBus.action_skill.connect(_on_skill)
		EventBus.action_jump.connect(request_jump)
		EventBus.action_interact.connect(_on_interact)
		EventBus.enemy_killed.connect(_on_enemy_killed)
		EventBus.attack_hold_started.connect(_on_attack_hold_start)
		EventBus.attack_hold_ended.connect(_on_attack_hold_end)

func set_touch_move(dir: Vector2) -> void:
	if dir.length() < 0.12:
		_touch_move = Vector2.ZERO
	else:
		_touch_move = dir.limit_length(1.0)

func add_touch_look(delta: Vector2) -> void:
	if delta.length() < 0.8:
		return
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

func request_dodge() -> void:
	_dodge_queued = true

func set_blocking(v: bool) -> void:
	_blocking = v

func is_blocking() -> bool:
	return _blocking

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
	_attack_lock = maxf(_attack_lock - delta, 0.0)
	_dodge_timer = maxf(_dodge_timer - delta, 0.0)
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
	if _dodge_queued and is_on_floor() and combat.try_spend_stamina(DODGE_COST):
		_dodge_queued = false
		_dodge_timer = 0.28
		combat.grant_iframe(DODGE_IFRAMES)
		var ddir := direction if direction.length() > 0.1 else -transform.basis.z
		velocity.x = ddir.x * DODGE_SPEED
		velocity.z = ddir.z * DODGE_SPEED
	else:
		_dodge_queued = false
		if _dodge_timer <= 0.0:
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

func _on_attack_hold_start() -> void:
	_attack_down_msec = Time.get_ticks_msec()

func _on_attack_hold_end() -> void:
	if _attack_down_msec <= 0:
		return
	var held := (Time.get_ticks_msec() - _attack_down_msec) / 1000.0
	_attack_down_msec = 0
	if held >= CHARGED_HOLD_SEC:
		_do_attack("charged")
	elif held >= HEAVY_HOLD_SEC:
		_do_attack("heavy")
	else:
		_do_attack("light")

func _on_attack_tap() -> void:
	if _attack_down_msec <= 0:
		_do_attack("light")

func _on_skill(slot: int) -> void:
	if _attack_lock > 0.0:
		return
	if not combat.try_spend_focus(SKILL_FOCUS):
		return
	combat.add_heat(18.0 if slot == 1 else 14.0)
	_attack_lock = 0.35
	var dmg := SKILL1_DMG if slot == 1 else SKILL2_DMG
	_strike_nearest(dmg)

func _do_attack(kind: String) -> void:
	if _attack_lock > 0.0 or not combat.alive:
		return
	match kind:
		"heavy":
			if not combat.try_spend_stamina(HEAVY_STAMINA):
				return
			_attack_lock = 0.45
			_strike_nearest(HEAVY_DMG)
		"charged":
			if not combat.try_spend_stamina(CHARGED_STAMINA):
				return
			combat.try_spend_focus(8.0)
			_attack_lock = 0.65
			_strike_nearest(CHARGED_DMG)
		_:
			if not combat.try_spend_stamina(LIGHT_STAMINA):
				return
			_attack_lock = 0.22
			_strike_nearest(LIGHT_DMG)

func _strike_nearest(damage: float) -> void:
	var best: Node3D = null
	var best_d := ATTACK_RANGE
	for n in get_tree().get_nodes_in_group("enemy"):
		if n == null or not is_instance_valid(n):
			continue
		var d: float = global_position.distance_to((n as Node3D).global_position)
		if d <= best_d:
			best_d = d
			best = n as Node3D
	if best and best.has_method("receive_hit"):
		best.receive_hit(damage, self)

func receive_hit(amount: float, source: Node = null) -> void:
	if not combat.alive:
		return
	var dmg := amount
	if _blocking:
		dmg *= 0.4
		combat.try_spend_stamina(10.0)
	combat.take_damage(dmg, source)

func _on_interact() -> void:
	if EventBus:
		EventBus.player_interact.emit(self)

func _on_enemy_killed(_enemy: Node, drops: Dictionary) -> void:
	xp += int(drops.get("xp", 0))
	gold += int(drops.get("gold", 0))
	var item: String = str(drops.get("item", ""))
	if item != "":
		inventory.append(item)
	if EventBus:
		EventBus.loot_gained.emit(drops)

func _on_player_died() -> void:
	await get_tree().create_timer(1.2).timeout
	if not is_instance_valid(self):
		return
	combat.hp = combat.max_hp * 0.6
	combat.alive = true
	combat.stamina = combat.max_stamina
	global_position = Vector3(0, 1.2, 16)
	combat.resources_changed.emit()

func capture_to_save() -> void:
	if SaveManager:
		SaveManager.capture_from_player(self)
		SaveManager.save()

func get_kit_id() -> String:
	return _kit_id

func set_kit_id(id: String) -> void:
	_kit_id = id
