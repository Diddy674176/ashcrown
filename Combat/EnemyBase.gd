extends CharacterBody3D
class_name EnemyBase
## Distinct Emberveil roles — COMBAT.md §6 / BOSS_COIL_WARDEN.md ladder.
## Vein-mite (skirmisher) · Wake-warped stag (bruiser) · Conduit wisp (caster)

const _CombatActor = preload("res://Combat/CombatActor.gd")
const _Telegraph = preload("res://Combat/TelegraphDecal.gd")

enum Role { SKIRMISHER, BRUISER, CASTER }

signal looted(drops: Dictionary)

@export var display_name: String = "Enemy"
@export var role: int = Role.SKIRMISHER
@export var max_hp: float = 40.0
@export var move_speed: float = 3.2
@export var aggro_range: float = 12.0
@export var attack_range: float = 1.8
@export var attack_damage: float = 8.0
@export var attack_cooldown: float = 1.4
@export var xp_reward: int = 12
@export var gold_reward: int = 5
@export var loot_id: String = "vein_mite_carapace"
@export var poise_max: float = 30.0

var combat
var _player: Node3D
var _attack_cd: float = 0.0
var _dead: bool = false
var _mesh: MeshInstance3D
var _label: Label3D
var _poise: float = 30.0
var _stagger_until: float = 0.0
var _base_color: Color = Color(0.55, 0.22, 0.28)
var _pattern_i: int = 0

func _ready() -> void:
	add_to_group("enemy")
	add_to_group("wilds_enemy")
	collision_layer = 4
	collision_mask = 1 | 2
	_apply_role_defaults()
	combat = _CombatActor.new()
	combat.name = "Combat"
	combat.max_hp = max_hp
	combat.team = &"enemy"
	add_child(combat)
	combat.died.connect(_on_died)
	_poise = poise_max
	_build_visual()
	_find_player()

func _apply_role_defaults() -> void:
	match role:
		Role.SKIRMISHER:
			if display_name == "Enemy":
				display_name = "Vein-mite"
			_base_color = Color(0.55, 0.22, 0.28)
			if max_hp <= 40.0:
				max_hp = 36.0
			move_speed = 3.8
			attack_range = 1.7
			attack_damage = 7.0
			attack_cooldown = 1.15
			poise_max = 18.0
			loot_id = "vein_mite_carapace"
			xp_reward = 15
			gold_reward = 6
		Role.BRUISER:
			if display_name == "Enemy":
				display_name = "Wake-warped Stag"
			_base_color = Color(0.42, 0.38, 0.45)
			max_hp = 95.0
			move_speed = 2.4
			attack_range = 2.4
			attack_damage = 16.0
			attack_cooldown = 2.1
			aggro_range = 14.0
			poise_max = 70.0
			loot_id = "brutefang_plate"
			xp_reward = 35
			gold_reward = 14
		Role.CASTER:
			if display_name == "Enemy":
				display_name = "Conduit Wisp"
			_base_color = Color(0.35, 0.55, 0.75)
			max_hp = 48.0
			move_speed = 2.0
			attack_range = 9.0
			attack_damage = 11.0
			attack_cooldown = 2.4
			aggro_range = 16.0
			poise_max = 22.0
			loot_id = "spitter_bowstring"
			xp_reward = 22
			gold_reward = 9

static func make_skirmisher(pos: Vector3) -> EnemyBase:
	var e := EnemyBase.new()
	e.role = Role.SKIRMISHER
	e.display_name = "Vein-mite"
	e.position = pos
	return e

static func make_bruiser(pos: Vector3) -> EnemyBase:
	var e := EnemyBase.new()
	e.role = Role.BRUISER
	e.display_name = "Wake-warped Stag"
	e.position = pos
	return e

static func make_caster(pos: Vector3) -> EnemyBase:
	var e := EnemyBase.new()
	e.role = Role.CASTER
	e.display_name = "Conduit Wisp"
	e.position = pos
	return e

func _build_visual() -> void:
	var shape := CollisionShape3D.new()
	match role:
		Role.BRUISER:
			var box := BoxShape3D.new()
			box.size = Vector3(1.4, 2.2, 2.0)
			shape.shape = box
			shape.position = Vector3(0, 1.1, 0)
		Role.CASTER:
			var sph := SphereShape3D.new()
			sph.radius = 0.55
			shape.shape = sph
			shape.position = Vector3(0, 1.1, 0)
		_:
			var cap := CapsuleShape3D.new()
			cap.radius = 0.4
			cap.height = 1.0
			shape.shape = cap
			shape.position = Vector3(0, 0.5, 0)
	add_child(shape)
	_mesh = MeshInstance3D.new()
	match role:
		Role.BRUISER:
			var bm := BoxMesh.new()
			bm.size = Vector3(1.2, 2.0, 1.8)
			_mesh.mesh = bm
			_mesh.position = Vector3(0, 1.0, 0)
			var a1 := MeshInstance3D.new()
			var cyl := CylinderMesh.new()
			cyl.top_radius = 0.05
			cyl.bottom_radius = 0.08
			cyl.height = 0.9
			a1.mesh = cyl
			a1.position = Vector3(-0.35, 2.2, 0.2)
			a1.rotation_degrees = Vector3(20, 0, -25)
			var am := StandardMaterial3D.new()
			am.albedo_color = Color(0.55, 0.5, 0.58)
			a1.material_override = am
			add_child(a1)
		Role.CASTER:
			var sm := SphereMesh.new()
			sm.radius = 0.5
			sm.height = 1.0
			_mesh.mesh = sm
			_mesh.position = Vector3(0, 1.1, 0)
		_:
			var sphere := SphereMesh.new()
			sphere.radius = 0.45
			sphere.height = 0.9
			_mesh.mesh = sphere
			_mesh.position = Vector3(0, 0.45, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = _base_color
	if role == Role.CASTER:
		mat.emission_enabled = true
		mat.emission = Color(0.2, 0.45, 0.7)
		mat.emission_energy_multiplier = 0.6
	_mesh.material_override = mat
	add_child(_mesh)
	_label = Label3D.new()
	_label.text = display_name
	_label.position = Vector3(0, 2.4 if role == Role.BRUISER else 1.6, 0)
	_label.font_size = 28
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.modulate = Color(0.95, 0.75, 0.7)
	add_child(_label)

func _find_player() -> void:
	var nodes := get_tree().get_nodes_in_group("player")
	if nodes.size() > 0:
		_player = nodes[0] as Node3D

func _physics_process(delta: float) -> void:
	if _dead:
		return
	if _player == null or not is_instance_valid(_player):
		_find_player()
		return
	_attack_cd = maxf(_attack_cd - delta, 0.0)
	if Time.get_ticks_msec() * 0.001 < _stagger_until:
		velocity.x = move_toward(velocity.x, 0.0, move_speed)
		velocity.z = move_toward(velocity.z, 0.0, move_speed)
		if not is_on_floor():
			velocity.y -= 12.0 * delta
		move_and_slide()
		return
	if not is_on_floor():
		velocity.y -= 12.0 * delta
	var to_player := _player.global_position - global_position
	to_player.y = 0.0
	var dist := to_player.length()
	if dist > aggro_range:
		velocity.x = move_toward(velocity.x, 0.0, move_speed)
		velocity.z = move_toward(velocity.z, 0.0, move_speed)
		move_and_slide()
		return
	match role:
		Role.SKIRMISHER:
			_ai_skirmisher(delta, to_player, dist)
		Role.BRUISER:
			_ai_bruiser(delta, to_player, dist)
		Role.CASTER:
			_ai_caster(delta, to_player, dist)

func _ai_skirmisher(_delta: float, to_player: Vector3, dist: float) -> void:
	var desired := attack_range * 0.8
	if dist > desired + 0.4:
		var dir := to_player.normalized()
		var side := Vector3(-dir.z, 0, dir.x) * (0.35 if int(Time.get_ticks_msec() / 800) % 2 == 0 else -0.35)
		var move := (dir + side).normalized()
		velocity.x = move.x * move_speed
		velocity.z = move.z * move_speed
		look_at(global_position + dir, Vector3.UP)
	else:
		velocity.x = 0.0
		velocity.z = 0.0
		if _attack_cd <= 0.0:
			_attack_cd = attack_cooldown
			_do_leap_attack()
	move_and_slide()

func _ai_bruiser(_delta: float, to_player: Vector3, dist: float) -> void:
	if dist > attack_range * 0.9:
		var dir := to_player.normalized()
		velocity.x = dir.x * move_speed
		velocity.z = dir.z * move_speed
		look_at(global_position + dir, Vector3.UP)
	else:
		velocity.x = 0.0
		velocity.z = 0.0
		if _attack_cd <= 0.0:
			_attack_cd = attack_cooldown
			_pattern_i += 1
			if _pattern_i % 3 == 0:
				_do_unblockable_grab()
			else:
				_do_heavy_slam()
	move_and_slide()

func _ai_caster(_delta: float, to_player: Vector3, dist: float) -> void:
	var ideal := 7.5
	var dir := to_player.normalized() if to_player.length() > 0.1 else Vector3.FORWARD
	if dist < ideal - 1.5:
		velocity.x = -dir.x * move_speed
		velocity.z = -dir.z * move_speed
	elif dist > ideal + 1.5:
		velocity.x = dir.x * move_speed * 0.7
		velocity.z = dir.z * move_speed * 0.7
	else:
		velocity.x = 0.0
		velocity.z = 0.0
	if dir.length_squared() > 0.001:
		look_at(global_position + dir, Vector3.UP)
	if _attack_cd <= 0.0 and dist <= aggro_range:
		_attack_cd = attack_cooldown
		_pattern_i += 1
		if _pattern_i % 3 == 0:
			_do_aoe_seal()
		else:
			_do_ranged_orb()
	move_and_slide()

func _do_leap_attack() -> void:
	_Telegraph.spawn(get_parent(), global_position, _Telegraph.Kind.DODGE_AMBER, 0.5, 1.6)
	await get_tree().create_timer(0.5).timeout
	if _dead or _player == null or not is_instance_valid(_player):
		return
	var to := _player.global_position - global_position
	to.y = 0.0
	if to.length() > 0.1:
		global_position += to.normalized() * minf(to.length(), 2.2)
	if global_position.distance_to(_player.global_position) <= attack_range + 0.8:
		if _player.has_method("receive_hit"):
			_player.receive_hit(attack_damage, self)

func _do_heavy_slam() -> void:
	_Telegraph.spawn(get_parent(), global_position, _Telegraph.Kind.BLOCK_BLUE, 0.65, 2.4)
	await get_tree().create_timer(0.65).timeout
	if _dead or _player == null or not is_instance_valid(_player):
		return
	if global_position.distance_to(_player.global_position) <= attack_range + 0.7:
		var dmg := attack_damage
		if _player.has_method("is_blocking") and _player.is_blocking():
			dmg *= 0.35
		if _player.has_method("receive_hit"):
			_player.receive_hit(dmg, self)

func _do_unblockable_grab() -> void:
	_Telegraph.spawn(get_parent(), global_position, _Telegraph.Kind.UNBLOCKABLE_RED, 0.7, 2.6)
	if _label:
		_label.text = "%s — UNBLOCKABLE" % display_name
	await get_tree().create_timer(0.7).timeout
	if _label and not _dead:
		_label.text = display_name
	if _dead or _player == null or not is_instance_valid(_player):
		return
	if global_position.distance_to(_player.global_position) <= attack_range + 1.0:
		if _player.has_method("receive_hit"):
			_player.receive_hit(attack_damage * 1.45, self)

func _do_ranged_orb() -> void:
	if _player == null:
		return
	var pos := _player.global_position
	pos.y = global_position.y
	_Telegraph.spawn(get_parent(), pos, _Telegraph.Kind.DODGE_AMBER, 0.55, 1.4)
	await get_tree().create_timer(0.55).timeout
	if _dead or _player == null or not is_instance_valid(_player):
		return
	if _player.global_position.distance_to(pos) < 1.6:
		if _player.has_method("receive_hit"):
			_player.receive_hit(attack_damage, self)

func _do_aoe_seal() -> void:
	if _player == null:
		return
	var pos := _player.global_position
	pos.y = global_position.y
	_Telegraph.spawn(get_parent(), pos, _Telegraph.Kind.AOE_AMBER, 0.9, 2.6)
	await get_tree().create_timer(0.9).timeout
	if _dead or _player == null or not is_instance_valid(_player):
		return
	if _player.global_position.distance_to(pos) < 2.7:
		if _player.has_method("receive_hit"):
			_player.receive_hit(attack_damage * 1.2, self)

func receive_hit(amount: float, source: Node = null) -> void:
	if _dead:
		return
	combat.take_damage(amount, source)
	_poise = maxf(_poise - amount * 0.6, 0.0)
	if _poise <= 0.0:
		_poise = poise_max
		_stagger_until = Time.get_ticks_msec() * 0.001 + 0.9
		if _label:
			_label.text = "%s — STAGGER" % display_name
	if _mesh and _mesh.material_override:
		var mat := _mesh.material_override as StandardMaterial3D
		mat.albedo_color = Color(1, 0.85, 0.85)
		get_tree().create_timer(0.08).timeout.connect(func():
			if is_instance_valid(mat):
				mat.albedo_color = _base_color
		)

func _on_died() -> void:
	_dead = true
	velocity = Vector3.ZERO
	var drops := {
		"xp": xp_reward,
		"gold": gold_reward,
		"item": loot_id,
		"name": display_name,
		"role": role,
	}
	looted.emit(drops)
	if EventBus:
		EventBus.enemy_killed.emit(self, drops)
	if _label:
		_label.text = "Loot: +%s XP / %sg" % [xp_reward, gold_reward]
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector3.ONE * 0.05, 0.45)
	tw.tween_callback(queue_free)
