extends CharacterBody3D
## Playable mobile player — soft-lock ON, Manual/Assisted/Full Auto share CombatBrain.

const _CombatActor = preload("res://Combat/CombatActor.gd")
const _CombatBrain = preload("res://Combat/CombatBrain.gd")

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
const SOFT_LOCK_TURN := 6.0

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
var potions: int = 3

var combat
var combat_mode: int = _CombatBrain.Mode.MANUAL
var soft_lock_on: bool = true
var soft_lock_target: Node3D = null
var _skill1_cd: float = 0.0
var _skill2_cd: float = 0.0
var _auto_attack_cd: float = 0.0
var _auto_block_until: float = 0.0

@onready var _pivot: Node3D = $CameraPivot
@onready var _camera: Camera3D = $CameraPivot/Camera3D
@onready var _mesh: MeshInstance3D = $MeshInstance3D

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
	_tint_player()
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

func _tint_player() -> void:
	if _mesh:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.72, 0.55, 0.28)  # ash-gold cloak stub
		_mesh.material_override = mat

func cycle_combat_mode() -> int:
	combat_mode = (combat_mode + 1) % 3
	if EventBus:
		EventBus.hud_toast.emit("Combat: %s · soft-lock %s" % [
			_CombatBrain.mode_name(combat_mode),
			"ON" if soft_lock_on else "OFF"
		])
	return combat_mode

func toggle_soft_lock() -> void:
	soft_lock_on = not soft_lock_on
	if not soft_lock_on:
		soft_lock_target = null
	if EventBus:
		EventBus.hud_toast.emit("Soft-lock %s" % ("ON" if soft_lock_on else "OFF"))

func get_combat_mode_name() -> String:
	return _CombatBrain.mode_name(combat_mode)

func set_touch_move(dir: Vector2) -> void:
	if dir.length() < 0.12:
		_touch_move = Vector2.ZERO
	else:
		_touch_move = dir.limit_length(1.0)

func add_touch_look(delta: Vector2) -> void:
	if delta.length() < 0.8:
		return
	# Manual / Assisted: player owns look. Full Auto: ignore look (brain aims).
	if combat_mode == _CombatBrain.Mode.FULL_AUTO:
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
	return _blocking or Time.get_ticks_msec() * 0.001 < _auto_block_until

func is_dodging() -> bool:
	return _dodge_timer > 0.0 or (combat != null and combat.is_invincible())

func _apply_cam_distance() -> void:
	if _camera:
		_camera.position = Vector3(0, 0.4, _cam_distance)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if combat_mode != _CombatBrain.Mode.FULL_AUTO:
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
	_skill1_cd = maxf(_skill1_cd - delta, 0.0)
	_skill2_cd = maxf(_skill2_cd - delta, 0.0)
	_auto_attack_cd = maxf(_auto_attack_cd - delta, 0.0)

	if soft_lock_on:
		soft_lock_target = _CombatBrain.pick_target(global_position, get_tree(), soft_lock_target)
		if soft_lock_target and is_instance_valid(soft_lock_target):
			var to := soft_lock_target.global_position - global_position
			to.y = 0.0
			if to.length() > 0.2:
				var target_yaw := atan2(-to.x, -to.z)
				_yaw = lerp_angle(_yaw, target_yaw, clampf(SOFT_LOCK_TURN * delta, 0.0, 1.0))
				rotation.y = _yaw

	_run_auto_brain(delta)

	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	var input_dir := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_forward", "move_back")
	)
	if _touch_move.length_squared() > 0.01:
		input_dir = _touch_move

	# Full Auto: brain drives move toward / away from soft-lock target
	if combat_mode == _CombatBrain.Mode.FULL_AUTO:
		input_dir = _auto_move_dir()

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

func _auto_move_dir() -> Vector2:
	if soft_lock_target == null or not is_instance_valid(soft_lock_target):
		return Vector2.ZERO
	if _CombatBrain.should_retreat(combat.hp_pct()):
		# Back away in local space
		return Vector2(0, 1)
	var dist := global_position.distance_to(soft_lock_target.global_position)
	if dist > ATTACK_RANGE * 0.85:
		return Vector2(0, -1)  # forward
	if dist < ATTACK_RANGE * 0.45:
		return Vector2(0.4, 0.2)  # sidestep
	return Vector2.ZERO

func _run_auto_brain(_delta: float) -> void:
	if combat_mode == _CombatBrain.Mode.MANUAL or not combat.alive:
		return
	# Assisted + Full Auto: heal / dodge / block / skills / (Full: attack)
	if _CombatBrain.should_heal(combat.hp_pct(), potions):
		potions = maxi(potions - 1, 0)
		combat.heal(35.0)
		if EventBus:
			EventBus.hud_toast.emit("Auto-heal (potion left: %d)" % potions)
	if _CombatBrain.should_dodge(global_position, get_tree()):
		_dodge_queued = true
	elif _CombatBrain.should_block(global_position, get_tree()):
		_auto_block_until = Time.get_ticks_msec() * 0.001 + 0.55
		_blocking = true
	else:
		if Time.get_ticks_msec() * 0.001 >= _auto_block_until:
			_blocking = false
	var skill := _CombatBrain.pick_skill(combat.focus, combat.heat, combat.is_overheated(), _skill1_cd, _skill2_cd)
	if skill > 0:
		_on_skill(skill)
	if combat_mode == _CombatBrain.Mode.FULL_AUTO and soft_lock_target and is_instance_valid(soft_lock_target):
		var d := global_position.distance_to(soft_lock_target.global_position)
		if _CombatBrain.want_light_attack(d, _attack_lock) and _auto_attack_cd <= 0.0:
			_do_attack("light")
			_auto_attack_cd = 0.28

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
	if _attack_lock > 0.0 or not combat.alive:
		return
	if slot == 1 and _skill1_cd > 0.0:
		return
	if slot == 2 and _skill2_cd > 0.0:
		return
	if combat.is_overheated():
		if EventBus:
			EventBus.hud_toast.emit("Overheated — skills sealed")
		return
	if combat.heat >= 90.0:
		if EventBus:
			EventBus.hud_toast.emit("Heat high — skill blocked")
		return
	if not combat.try_spend_focus(SKILL_FOCUS):
		return
	combat.add_heat(18.0 if slot == 1 else 14.0)
	_attack_lock = 0.35
	if slot == 1:
		_skill1_cd = 2.2
	else:
		_skill2_cd = 1.8
	var dmg := SKILL1_DMG if slot == 1 else SKILL2_DMG
	_strike_locked(dmg)

func _do_attack(kind: String) -> void:
	if _attack_lock > 0.0 or not combat.alive:
		return
	match kind:
		"heavy":
			if not combat.try_spend_stamina(HEAVY_STAMINA):
				return
			_attack_lock = 0.45
			_strike_locked(HEAVY_DMG)
		"charged":
			if not combat.try_spend_stamina(CHARGED_STAMINA):
				return
			combat.try_spend_focus(8.0)
			_attack_lock = 0.65
			_strike_locked(CHARGED_DMG)
		_:
			if not combat.try_spend_stamina(LIGHT_STAMINA):
				return
			_attack_lock = 0.22
			_strike_locked(LIGHT_DMG)

func _strike_locked(damage: float) -> void:
	var best: Node3D = soft_lock_target if soft_lock_on and soft_lock_target and is_instance_valid(soft_lock_target) else null
	if best == null or global_position.distance_to(best.global_position) > ATTACK_RANGE + 0.4:
		best = null
		var best_d := ATTACK_RANGE
		for n in get_tree().get_nodes_in_group("enemy"):
				if n == null or not is_instance_valid(n):
				continue
			var d: float = global_position.distance_to((n as Node3D).global_position)
			if d <= best_d:
				best_d = d
				best = n as Node3D
	if best and best.has_method("receive_hit"):
		best.receive_hit(damage + _atk_bonus, self)

func receive_hit(amount: float, source: Node = null) -> void:
	if not combat.alive:
		return
	var dmg := maxf(amount - _def_bonus * 0.5, 1.0)
	if is_blocking():
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
		add_item(item)
	if EventBus:
		EventBus.loot_gained.emit(drops)

func _on_player_died() -> void:
	await get_tree().create_timer(1.2).timeout
	if not is_instance_valid(self):
		return
	combat.hp = combat.max_hp * 0.6
	combat.alive = true
	combat.stamina = combat.max_stamina
	potions = maxi(potions, 1)
	global_position = Vector3(0, 1.2, 16)
	combat.resources_changed.emit()
	if EventBus:
		EventBus.hud_toast.emit("Respawned at Ashfen Gate")


var equipment: Dictionary = {"weapon": "", "armor": "", "charm": ""}
var companion_id: String = ""
var _atk_bonus: float = 0.0
var _def_bonus: float = 0.0
var _equip_hp_bonus: float = 0.0

func add_item(item_id: String) -> void:
	if item_id == "":
		return
	inventory.append(item_id)
	var ItemDBScript = load("res://Inventory/ItemDB.gd")
	var defn: Dictionary = {}
	if ItemDBScript:
		defn = ItemDBScript.get_item(item_id)
	var slot := str(defn.get("slot", ""))
	if slot in ["weapon", "armor", "charm"]:
		_try_auto_equip(item_id, slot, defn)
	if item_id == "health_draught":
		potions += 1

func _try_auto_equip(item_id: String, slot: String, defn: Dictionary) -> void:
	var cur := str(equipment.get(slot, ""))
	var new_atk := int(defn.get("stats", {}).get("atk", 0)) + int(defn.get("stats", {}).get("def", 0))
	var cur_score := 0
	if cur != "":
		var ItemDBScript = load("res://Inventory/ItemDB.gd")
		var cold = ItemDBScript.get_item(cur)
		cur_score = int(cold.get("stats", {}).get("atk", 0)) + int(cold.get("stats", {}).get("def", 0))
	if new_atk >= cur_score or cur == "":
		equipment[slot] = item_id
		_recalc_equip()
		if EventBus:
			EventBus.hud_toast.emit("Equipped %s" % str(defn.get("name", item_id)))

func _recalc_equip() -> void:
	_atk_bonus = 0.0
	_def_bonus = 0.0
	var hp_add := 0.0
	var ItemDBScript = load("res://Inventory/ItemDB.gd")
	for slot in equipment.keys():
		var id := str(equipment[slot])
		if id == "" or ItemDBScript == null:
			continue
		var d = ItemDBScript.get_item(id)
		var st: Dictionary = d.get("stats", {})
		_atk_bonus += float(st.get("atk", 0))
		_def_bonus += float(st.get("def", 0))
		hp_add += float(st.get("max_hp", 0))
	if combat:
		var base_hp := 120.0
		combat.max_hp = base_hp + hp_add
		combat.hp = minf(combat.hp, combat.max_hp)
		combat.resources_changed.emit()

func get_equip_bonus() -> Dictionary:
	return {"atk": int(_atk_bonus), "def": int(_def_bonus)}

func count_item(item_id: String) -> int:
	var n := 0
	for it in inventory:
		if str(it) == item_id:
			n += 1
	return n

func consume_item(item_id: String, qty: int = 1) -> bool:
	var left := qty
	var keep: Array = []
	for it in inventory:
		if left > 0 and str(it) == item_id:
			left -= 1
		else:
			keep.append(it)
	inventory = keep
	return left == 0

func recruit_companion(id: String = "Rook") -> void:
	companion_id = id
	# Spawn follower if not present
	if get_tree().get_nodes_in_group("companion").is_empty():
		var Comp = load("res://Companions/CompanionRook.gd")
		if Comp:
			var c = Comp.new()
			c.name = "Rook"
			get_parent().add_child(c)
			c.global_position = global_position + Vector3(1.5, 0, 1.0)
	if EventBus:
		EventBus.hud_toast.emit("%s joins your watch." % id)
		EventBus.quest_flag_set.emit(&"rook_recruited", true)


func capture_to_save() -> void:
	if SaveManager:
		SaveManager.capture_from_player(self)
		SaveManager.save()

func get_kit_id() -> String:
	return _kit_id

func set_kit_id(id: String) -> void:
	_kit_id = id
