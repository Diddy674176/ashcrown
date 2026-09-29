extends CharacterBody3D
class_name CoilWardenBoss

const _CombatActor = preload("res://Combat/CombatActor.gd")
const _Telegraph = preload("res://Combat/TelegraphDecal.gd")
## Multi-phase Coil Warden - COMBAT.md / BOSS_COIL_WARDEN.md stub AI with readable tells.

signal phase_changed(phase_id: String)
signal defeated(drop: Dictionary)

const UNIQUE_DROP := "Ash-etched Circlet Fragment"
const MAX_HP := 280.0

var combat
var _player: Node3D
var _phase: String = "coil_sentinel"
var _pattern_cd: float = 1.5
var _dead: bool = false
var _mesh: MeshInstance3D
var _label: Label3D
var _phase_banner: Label3D
var _enrage: bool = false

func _ready() -> void:
	add_to_group("enemy")
	add_to_group("boss")
	collision_layer = 4
	collision_mask = 1 | 2
	combat = _CombatActor.new()
	combat.name = "Combat"
	combat.max_hp = MAX_HP
	combat.team = &"enemy"
	add_child(combat)
	combat.died.connect(_on_died)
	_build_visual()
	_find_player()
	_announce_phase("coil_sentinel", "Phase 1 - Coil Sentinel")

func _build_visual() -> void:
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.2, 3.2, 2.2)
	shape.shape = box
	shape.position = Vector3(0, 1.6, 0)
	add_child(shape)
	_mesh = MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(2.0, 3.0, 2.0)
	_mesh.mesh = mesh
	_mesh.position = Vector3(0, 1.5, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.45, 0.42, 0.48)
	_mesh.material_override = mat
	add_child(_mesh)
	var spine := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.25
	cyl.bottom_radius = 0.35
	cyl.height = 3.4
	spine.mesh = cyl
	spine.position = Vector3(0, 1.7, -0.9)
	var spine_mat := StandardMaterial3D.new()
	spine_mat.albedo_color = Color(0.7, 0.35, 0.2)
	spine.material_override = spine_mat
	add_child(spine)
	_label = Label3D.new()
	_label.text = "The Coil Warden"
	_label.position = Vector3(0, 3.8, 0)
	_label.font_size = 36
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(_label)
	_phase_banner = Label3D.new()
	_phase_banner.position = Vector3(0, 4.6, 0)
	_phase_banner.font_size = 28
	_phase_banner.modulate = Color(1.0, 0.85, 0.4)
	_phase_banner.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(_phase_banner)

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
	_update_phase()
	_pattern_cd = maxf(_pattern_cd - delta, 0.0)
	if not is_on_floor():
		velocity.y -= 12.0 * delta
	var to_p := _player.global_position - global_position
	to_p.y = 0.0
	if to_p.length() > 0.1:
		var target := global_position + to_p.normalized()
		look_at(target, Vector3.UP)
	velocity.x = 0.0
	velocity.z = 0.0
	move_and_slide()
	if _pattern_cd <= 0.0:
		_fire_pattern()

func _update_phase() -> void:
	var pct := combat.hp_pct()
	var next := _phase
	if pct > 0.6:
		next = "coil_sentinel"
	elif pct > 0.3:
		next = "bleed_surge"
	else:
		next = "crown_echo"
	if next != _phase:
		_phase = next
		match _phase:
			"bleed_surge":
				_announce_phase(_phase, "Phase 2 - Bleed Surge")
				_pattern_cd = 1.2
				if _mesh and _mesh.material_override:
					(_mesh.material_override as StandardMaterial3D).albedo_color = Color(0.35, 0.45, 0.55)
			"crown_echo":
				_announce_phase(_phase, "Phase 3 - Crown Echo")
				_enrage = true
				_pattern_cd = 0.8
				if _mesh and _mesh.material_override:
					(_mesh.material_override as StandardMaterial3D).albedo_color = Color(0.55, 0.32, 0.22)
		phase_changed.emit(_phase)
		_pattern_cd = maxf(_pattern_cd, 1.0)

func _announce_phase(id: String, text: String) -> void:
	if _phase_banner:
		_phase_banner.text = text
	if EventBus:
		EventBus.boss_phase_changed.emit(id, text)

func _fire_pattern() -> void:
	match _phase:
		"coil_sentinel":
			_pattern_cd = 2.2 if not _enrage else 1.4
			await _pattern_sweep_or_slam()
		"bleed_surge":
			_pattern_cd = 2.0
			if randf() < 0.55:
				await _pattern_aether_vent()
			else:
				await _pattern_coil_overload()
		"crown_echo":
			_pattern_cd = 1.35
			if randf() < 0.4:
				await _pattern_coil_overload()
			else:
				await _pattern_sweep_or_slam()

func _pattern_sweep_or_slam() -> void:
	if randf() < 0.55:
		_Telegraph.spawn(get_parent(), global_position + -transform.basis.z * 2.0, _Telegraph.Kind.DODGE_AMBER, 0.55, 3.0)
		await get_tree().create_timer(0.55).timeout
		_hit_players_in_radius(3.2, 14.0, "Sweep Arc")
	else:
		_Telegraph.spawn(get_parent(), global_position, _Telegraph.Kind.BLOCK_BLUE, 0.6, 2.4)
		await get_tree().create_timer(0.6).timeout
		_hit_players_in_radius(2.6, 18.0, "Glyph Slam", true)

func _pattern_aether_vent() -> void:
	if _player == null:
		return
	var pos := _player.global_position
	pos.y = global_position.y
	_Telegraph.spawn(get_parent(), pos, _Telegraph.Kind.AOE_AMBER, 0.85, 2.8)
	await get_tree().create_timer(0.85).timeout
	if _player and is_instance_valid(_player) and _player.global_position.distance_to(pos) < 2.9:
		_apply_hit(_player, 16.0, "Aether Vent")

func _pattern_coil_overload() -> void:
	_Telegraph.spawn(get_parent(), global_position, _Telegraph.Kind.UNBLOCKABLE_RED, 0.7, 4.0)
	if _phase_banner:
		_phase_banner.text = "UNBLOCKABLE - DODGE!"
	await get_tree().create_timer(0.7).timeout
	_hit_players_in_radius(4.2, 28.0, "Coil Overload")
	if _phase_banner and not _dead:
		_phase_banner.text = "Phase 3 - Crown Echo" if _phase == "crown_echo" else "Phase 2 - Bleed Surge"

func _hit_players_in_radius(radius: float, damage: float, _pat: String, blockable: bool = false) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	if global_position.distance_to(_player.global_position) <= radius:
		var dmg := damage
		if blockable and _player.has_method("is_blocking") and _player.is_blocking():
			dmg *= 0.35
		_apply_hit(_player, dmg, _pat)

func _apply_hit(target: Node, damage: float, _pat: String) -> void:
	if target.has_method("receive_hit"):
		target.receive_hit(damage, self)

func receive_hit(amount: float, source: Node = null) -> void:
	if _dead or amount <= 0.0:
		return
	if source == null:
		return
	var mult := 1.15 if _enrage else 1.0
	combat.take_damage(amount * mult, source)
	if _label:
		_label.text = "Coil Warden  %d/%d" % [int(combat.hp), int(combat.max_hp)]

func _on_died() -> void:
	_dead = true
	var drop := {"xp": 120, "gold": 80, "item": UNIQUE_DROP, "name": "The Coil Warden", "unique": true}
	defeated.emit(drop)
	if EventBus:
		EventBus.enemy_killed.emit(self, drop)
		EventBus.boss_defeated.emit(drop)
	if _phase_banner:
		_phase_banner.text = "DEFEATED - %s" % UNIQUE_DROP
	if _label:
		_label.text = "Ash-etched Circlet Fragment"
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector3(1, 0.05, 1), 1.2)
	tw.tween_callback(queue_free)
