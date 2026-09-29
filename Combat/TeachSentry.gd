extends CharacterBody3D
class_name TeachSentry
## Outer-ring / wake-pit teach encounter — one telegraph color, soft damage.
## Amber = dodge · Blue-white = block · Red = unblockable (COMBAT.md §4).

const _Telegraph = preload("res://Combat/TelegraphDecal.gd")

enum Lesson { DODGE_AMBER, BLOCK_BLUE, UNBLOCKABLE_RED }

@export var lesson: int = Lesson.DODGE_AMBER
@export var display_name: String = "Conduit Sentry"
@export var attack_damage: float = 4.0
@export var attack_cooldown: float = 3.2
@export var aggro_range: float = 7.0

var _player: Node3D
var _attack_cd: float = 1.0
var _dead: bool = false
var _mesh: MeshInstance3D
var _label: Label3D
var _hp: float = 28.0
var _taught: bool = false

func _ready() -> void:
	add_to_group("enemy")
	add_to_group("teach_sentry")
	collision_layer = 4
	collision_mask = 1 | 2
	_build()
	_find_player()
	_attack_cd = 1.2 + randf() * 0.8

func _build() -> void:
	var shape := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.4
	cap.height = 1.2
	shape.shape = cap
	shape.position = Vector3(0, 0.8, 0)
	add_child(shape)
	_mesh = MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.35
	cyl.bottom_radius = 0.45
	cyl.height = 1.5
	_mesh.mesh = cyl
	_mesh.position = Vector3(0, 0.75, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = _lesson_color()
	mat.emission_enabled = true
	mat.emission = _lesson_color()
	mat.emission_energy_multiplier = 0.45
	_mesh.material_override = mat
	add_child(_mesh)
	_label = Label3D.new()
	_label.text = "%s\n%s" % [display_name, _lesson_hint()]
	_label.position = Vector3(0, 2.1, 0)
	_label.font_size = 26
	_label.modulate = _lesson_color()
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(_label)

func _lesson_color() -> Color:
	match lesson:
		Lesson.BLOCK_BLUE:
			return Color(0.55, 0.75, 1.0)
		Lesson.UNBLOCKABLE_RED:
			return Color(1.0, 0.25, 0.18)
		_:
			return Color(1.0, 0.72, 0.15)

func _lesson_hint() -> String:
	match lesson:
		Lesson.BLOCK_BLUE:
			return "HOLD BLOCK (blue-white)"
		Lesson.UNBLOCKABLE_RED:
			return "DODGE — UNBLOCKABLE (red)"
		_:
			return "DODGE (amber)"

static func make(lesson_kind: int, pos: Vector3, title: String = "") -> CharacterBody3D:
	var s = (load("res://Combat/TeachSentry.gd") as GDScript).new()
	s.lesson = lesson_kind
	s.position = pos
	if title != "":
		s.display_name = title
	else:
		match lesson_kind:
			Lesson.BLOCK_BLUE:
				s.display_name = "Block Trainer"
			Lesson.UNBLOCKABLE_RED:
				s.display_name = "Red-Tell Trainer"
			_:
				s.display_name = "Dodge Trainer"
	return s

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
	var to := _player.global_position - global_position
	to.y = 0.0
	var dist := to.length()
	velocity.x = 0.0
	velocity.z = 0.0
	if dist < aggro_range and dist > 0.2:
		look_at(global_position + to.normalized(), Vector3.UP)
	if dist <= aggro_range and _attack_cd <= 0.0:
		_attack_cd = attack_cooldown
		_fire_lesson()
	move_and_slide()

func _fire_lesson() -> void:
	match lesson:
		Lesson.BLOCK_BLUE:
			_Telegraph.spawn(get_parent(), global_position, _Telegraph.Kind.BLOCK_BLUE, 0.7, 2.2)
			if not _taught and EventBus:
				EventBus.hud_toast.emit("Blue-white tell — HOLD BLOCK")
				_taught = true
			await get_tree().create_timer(0.7).timeout
			_resolve_hit(true)
		Lesson.UNBLOCKABLE_RED:
			_Telegraph.spawn(get_parent(), global_position, _Telegraph.Kind.UNBLOCKABLE_RED, 0.75, 2.4)
			if _label:
				_label.text = "%s\nUNBLOCKABLE — DODGE" % display_name
			if not _taught and EventBus:
				EventBus.hud_toast.emit("Red tell — DODGE (block will NOT save you)")
				_taught = true
			await get_tree().create_timer(0.75).timeout
			if _label and not _dead:
				_label.text = "%s\n%s" % [display_name, _lesson_hint()]
			_resolve_hit(false)
		_:
			_Telegraph.spawn(get_parent(), global_position, _Telegraph.Kind.DODGE_AMBER, 0.55, 1.8)
			if not _taught and EventBus:
				EventBus.hud_toast.emit("Amber tell — press DODGE")
				_taught = true
			await get_tree().create_timer(0.55).timeout
			_resolve_hit(false)

func _resolve_hit(blockable: bool) -> void:
	if _dead or _player == null or not is_instance_valid(_player):
		return
	if global_position.distance_to(_player.global_position) > aggro_range + 0.5:
		return
	# Soft teach damage; respect dodge/block
	if _player.has_method("is_dodging") and _player.is_dodging():
		if EventBus:
			EventBus.hud_toast.emit("Dodged!")
		return
	var dmg := attack_damage
	if blockable and _player.has_method("is_blocking") and _player.is_blocking():
		dmg *= 0.15
		if EventBus:
			EventBus.hud_toast.emit("Blocked!")
	elif not blockable and _player.has_method("is_blocking") and _player.is_blocking():
		if EventBus:
			EventBus.hud_toast.emit("Block failed — red is unblockable")
	if _player.has_method("receive_hit"):
		_player.receive_hit(dmg, self)

func receive_hit(amount: float, _source: Node = null) -> void:
	if _dead:
		return
	_hp -= amount
	if _mesh and _mesh.material_override:
		var mat := _mesh.material_override as StandardMaterial3D
		var prev := mat.albedo_color
		mat.albedo_color = Color(1, 1, 1)
		get_tree().create_timer(0.07).timeout.connect(func():
			if is_instance_valid(mat):
				mat.albedo_color = prev
		)
	if _hp <= 0.0:
		_on_died()

func _on_died() -> void:
	_dead = true
	if EventBus:
		EventBus.enemy_killed.emit(self, {"xp": 8, "gold": 2, "item": "", "name": display_name, "role": -1})
		EventBus.hud_toast.emit("Lesson clear — %s" % display_name)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector3.ONE * 0.05, 0.4)
	tw.tween_callback(queue_free)
