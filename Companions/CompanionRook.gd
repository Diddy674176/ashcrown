extends CharacterBody3D
## Rook companion — follows player, light auto-attacks. Recruit after Len quest.

const _CombatActor = preload("res://Combat/CombatActor.gd")
const FOLLOW_DIST := 2.8
const ATTACK_RANGE := 2.2
const MOVE_SPEED := 5.0
const ATK_DAMAGE := 8.0

var combat
var _player: Node3D
var _atk_cd: float = 0.0
var _mesh: MeshInstance3D

func _ready() -> void:
	add_to_group("companion")
	collision_layer = 2
	collision_mask = 1
	combat = _CombatActor.new()
	combat.name = "Combat"
	combat.max_hp = 80.0
	combat.team = &"player"
	add_child(combat)
	_build()
	_find_player()

func _build() -> void:
	var shape := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.35
	cap.height = 1.2
	shape.shape = cap
	shape.position = Vector3(0, 0.8, 0)
	add_child(shape)
	_mesh = MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = 0.35
	cm.height = 1.2
	_mesh.mesh = cm
	_mesh.position = Vector3(0, 0.8, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.35, 0.45, 0.55)
	_mesh.material_override = mat
	add_child(_mesh)
	var lbl := Label3D.new()
	lbl.text = "Rook"
	lbl.position = Vector3(0, 1.9, 0)
	lbl.font_size = 26
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.modulate = Color(0.7, 0.85, 1.0)
	add_child(lbl)

func _find_player() -> void:
	var nodes := get_tree().get_nodes_in_group("player")
	if nodes.size() > 0:
		_player = nodes[0] as Node3D

func _physics_process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_find_player()
		return
	_atk_cd = maxf(_atk_cd - delta, 0.0)
	if not is_on_floor():
		velocity.y -= 12.0 * delta
	# Prefer nearby enemy, else follow
	var target: Node3D = _nearest_enemy()
	if target:
		var to := target.global_position - global_position
		to.y = 0.0
		var dist := to.length()
		if dist > ATTACK_RANGE:
			var dir := to.normalized()
			velocity.x = dir.x * MOVE_SPEED
			velocity.z = dir.z * MOVE_SPEED
		else:
			velocity.x = 0.0
			velocity.z = 0.0
			if _atk_cd <= 0.0 and target.has_method("receive_hit"):
				target.receive_hit(ATK_DAMAGE, self)
				_atk_cd = 1.1
	else:
		var to_p := _player.global_position - global_position
		to_p.y = 0.0
		if to_p.length() > FOLLOW_DIST:
			var dir := to_p.normalized()
			velocity.x = dir.x * MOVE_SPEED
			velocity.z = dir.z * MOVE_SPEED
		else:
			velocity.x = 0.0
			velocity.z = 0.0
	move_and_slide()

func _nearest_enemy() -> Node3D:
	var best: Node3D = null
	var best_d := 10.0
	for n in get_tree().get_nodes_in_group("enemy"):
		if n == null or not is_instance_valid(n):
			continue
		if n.is_in_group("boss"):
			continue  # don't solo Warden
		var d: float = global_position.distance_to((n as Node3D).global_position)
		if d < best_d:
			best_d = d
			best = n as Node3D
	return best
