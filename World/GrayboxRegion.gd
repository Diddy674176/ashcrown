extends Node3D
class_name GrayboxRegion
## Emberveil Reach graybox - landmarks, Vein-mite trash, Coilcrypt mouth portal.

const REGION_NAME := "Emberveil Reach"

func _ready() -> void:
	name = "EmberveilReach"
	_build()
	_spawn_wilds_enemies()
	_spawn_coilcrypt_portal()
	if EventBus:
		EventBus.region_entered.emit(&"emberveil_reach")

func _build() -> void:
	_add_box(Vector3(80, 1, 80), Vector3(0, -0.5, 0))
	for i in range(8):
		var h := 2.0 + float(i % 3)
		var a := i * TAU / 8.0
		_add_box(Vector3(3, h, 3), Vector3(cos(a) * 22.0, h * 0.5, sin(a) * 22.0))
	var ashfen := Node3D.new()
	ashfen.name = "AshfenGate"
	ashfen.position = Vector3(0, 0, 22)
	add_child(ashfen)
	_add_box(Vector3(2, 8, 2), Vector3(0, 4, 0), ashfen)
	_add_box(Vector3(10, 3, 1), Vector3(0, 1.5, 2), ashfen)
	_add_box(Vector3(1, 3, 4), Vector3(-5, 1.5, 0), ashfen)
	_add_box(Vector3(1, 3, 4), Vector3(5, 1.5, 0), ashfen)
	_label("Ashfen Gate", Vector3(0, 9, 0), ashfen)
	var waystone := Node3D.new()
	waystone.name = "GrayConcordWaystone"
	waystone.position = Vector3(0, 0, 0)
	add_child(waystone)
	_add_cyl(0.6, 4.0, Vector3(0, 2, 0), waystone)
	_add_box(Vector3(2.5, 0.3, 2.5), Vector3(0, 0.15, 0), waystone)
	_label("Gray Concord Waystone", Vector3(0, 5, 0), waystone)
	var wilds := Node3D.new()
	wilds.name = "EmberveilWilds"
	wilds.position = Vector3(20, 0, 0)
	add_child(wilds)
	_add_cyl(1.5, 7.0, Vector3(0, 3.5, 0), wilds)
	_add_cyl(3.0, 1.0, Vector3(0, 7.2, 0), wilds)
	_add_box(Vector3(2, 1, 2), Vector3(-4, 0.5, 3), wilds)
	_label("Emberveil Wilds", Vector3(0, 9, 0), wilds)
	var coil := Node3D.new()
	coil.name = "CoilcryptMouth"
	coil.position = Vector3(0, 0, -24)
	add_child(coil)
	for i in range(8):
		var a := i * TAU / 8.0
		_add_box(Vector3(1.2, 2.5, 1.2), Vector3(cos(a) * 5.0, 1.25, sin(a) * 5.0), coil)
	_add_cyl(3.5, 0.4, Vector3(0, 0.2, 0), coil)
	_label("Coilcrypt - USE to enter", Vector3(0, 4, 0), coil)
	var ramp := CSGBox3D.new()
	ramp.size = Vector3(4, 0.4, 10)
	ramp.position = Vector3(-12, 1.0, 8)
	ramp.rotation_degrees = Vector3(12, 40, 0)
	ramp.use_collision = true
	ramp.collision_layer = 1
	add_child(ramp)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, 30, 0)
	sun.light_energy = 1.1
	sun.shadow_enabled = false
	add_child(sun)
	var env_node := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.35, 0.4, 0.55)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.55, 0.5, 0.55)
	e.ambient_light_energy = 0.75
	env_node.environment = e
	add_child(env_node)

func _spawn_wilds_enemies() -> void:
	var mite_script = preload("res://Combat/EnemyBase.gd")
	var m1 = mite_script.new()
	m1.display_name = "Vein-mite"
	m1.max_hp = 36.0
	m1.move_speed = 3.4
	m1.attack_damage = 7.0
	m1.xp_reward = 15
	m1.gold_reward = 6
	m1.loot_id = "vein_mite_carapace"
	m1.position = Vector3(18, 0.5, 2)
	add_child(m1)
	var m2 = mite_script.new()
	m2.display_name = "Vein-mite"
	m2.max_hp = 32.0
	m2.move_speed = 3.6
	m2.attack_damage = 6.0
	m2.xp_reward = 12
	m2.gold_reward = 4
	m2.loot_id = "vein_mite_carapace"
	m2.position = Vector3(22, 0.5, -3)
	add_child(m2)

func _spawn_coilcrypt_portal() -> void:
	var area := Area3D.new()
	area.name = "CoilcryptPortal"
	area.position = Vector3(0, 1.0, -24)
	area.collision_layer = 0
	area.collision_mask = 2
	area.monitoring = true
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 4.5
	shape.shape = sphere
	area.add_child(shape)
	area.set_meta("dungeon_id", "coilcrypt")
	area.set_meta("player_inside", false)
	area.body_entered.connect(func(body: Node):
		if body.is_in_group("player"):
			area.set_meta("player_inside", true)
			if EventBus:
				EventBus.hud_toast.emit("Coilcrypt mouth - press USE to enter")
	)
	area.body_exited.connect(func(body: Node):
		if body.is_in_group("player"):
			area.set_meta("player_inside", false)
	)
	add_child(area)

func is_player_at_coilcrypt(player: Node3D) -> bool:
	var portal := get_node_or_null("CoilcryptPortal")
	if portal and portal.get_meta("player_inside", false):
		return true
	if player == null:
		return false
	return player.global_position.distance_to(Vector3(0, 1.0, -24)) < 5.5

func _add_box(size: Vector3, pos: Vector3, parent: Node = null) -> CSGBox3D:
	var b := CSGBox3D.new()
	b.size = size
	b.position = pos
	b.use_collision = true
	b.collision_layer = 1
	(parent if parent else self).add_child(b)
	return b

func _add_cyl(radius: float, height: float, pos: Vector3, parent: Node = null) -> CSGCylinder3D:
	var c := CSGCylinder3D.new()
	c.radius = radius
	c.height = height
	c.position = pos
	c.use_collision = true
	c.collision_layer = 1
	(parent if parent else self).add_child(c)
	return c

func _label(text: String, pos: Vector3, parent: Node) -> void:
	var l := Label3D.new()
	l.text = text
	l.position = pos
	l.font_size = 48
	l.modulate = Color(0.9, 0.85, 0.6)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	parent.add_child(l)
