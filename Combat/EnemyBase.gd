extends CharacterBody3D
class_name EnemyBase

const _CombatActor = preload("res://Combat/CombatActor.gd")
const _Telegraph = preload("res://Combat/TelegraphDecal.gd")
## Field trash / elite base - killable, drops stub loot.

signal looted(drops: Dictionary)

@export var display_name: String = "Enemy"
@export var max_hp: float = 40.0
@export var move_speed: float = 3.2
@export var aggro_range: float = 12.0
@export var attack_range: float = 1.8
@export var attack_damage: float = 8.0
@export var attack_cooldown: float = 1.4
@export var xp_reward: int = 12
@export var gold_reward: int = 5
@export var loot_id: String = "vein_mite_carapace"

var combat
var _player: Node3D
var _attack_cd: float = 0.0
var _dead: bool = false
var _mesh: MeshInstance3D
var _label: Label3D

func _ready() -> void:
	add_to_group("enemy")
	collision_layer = 4  # enemy
	collision_mask = 1 | 2  # world + player
	combat = _CombatActor.new()
	combat.name = "Combat"
	combat.max_hp = max_hp
	combat.team = &"enemy"
	add_child(combat)
	combat.died.connect(_on_died)
	_build_visual()
	_find_player()

func _build_visual() -> void:
	var shape := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.4
	cap.height = 1.0
	shape.shape = cap
	shape.position = Vector3(0, 0.5, 0)
	add_child(shape)
	_mesh = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.45
	sphere.height = 0.9
	_mesh.mesh = sphere
	_mesh.position = Vector3(0, 0.45, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.55, 0.22, 0.28)
	_mesh.material_override = mat
	add_child(_mesh)
	_label = Label3D.new()
	_label.text = display_name
	_label.position = Vector3(0, 1.4, 0)
	_label.font_size = 28
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.modulate = Color(0.95, 0.7, 0.7)
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
	if dist > attack_range * 0.85:
		var dir := to_player.normalized()
		velocity.x = dir.x * move_speed
		velocity.z = dir.z * move_speed
		if dir.length_squared() > 0.001:
			look_at(global_position + dir, Vector3.UP)
	else:
		velocity.x = 0.0
		velocity.z = 0.0
		if _attack_cd <= 0.0:
			_do_attack()
			_attack_cd = attack_cooldown
	move_and_slide()

func _do_attack() -> void:
	# Amber dodge leap telegraph then damage
	_Telegraph.spawn(get_parent(), global_position, _Telegraph.Kind.DODGE_AMBER, 0.5, 1.6)
	await get_tree().create_timer(0.5).timeout
	if _dead or _player == null or not is_instance_valid(_player):
		return
	if global_position.distance_to(_player.global_position) <= attack_range + 0.6:
		if _player.has_method("receive_hit"):
			_player.receive_hit(attack_damage, self)

func receive_hit(amount: float, source: Node = null) -> void:
	if _dead:
		return
	combat.take_damage(amount, source)
	# Flinch flash
	if _mesh and _mesh.material_override:
		var mat := _mesh.material_override as StandardMaterial3D
		mat.albedo_color = Color(1, 0.85, 0.85)
		get_tree().create_timer(0.08).timeout.connect(func():
			if is_instance_valid(mat):
				mat.albedo_color = Color(0.55, 0.22, 0.28)
		)

func _on_died() -> void:
	_dead = true
	velocity = Vector3.ZERO
	var drops := {
		"xp": xp_reward,
		"gold": gold_reward,
		"item": loot_id,
		"name": display_name,
	}
	looted.emit(drops)
	if EventBus:
		EventBus.enemy_killed.emit(self, drops)
	if _label:
		_label.text = "Loot: +%s XP / %sg" % [xp_reward, gold_reward]
	# Soft despawn
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector3.ONE * 0.05, 0.45)
	tw.tween_callback(queue_free)
