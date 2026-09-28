extends Node3D
class_name GrayboxRegion
## Emberveil Reach — Phase 1 graybox with CD-locked landmark stubs.

const REGION_NAME := "Emberveil Reach"

func _ready() -> void:
	name = "EmberveilReach"
	_build()

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
	_label("Ashfen Gate", Vector3(0, 9, 0), ashfen)
	var waystone := Node3D.new()
	waystone.name = "GrayConcordWaystone"
	add_child(waystone)
	_add_cyl(0.6, 4.0, Vector3(0, 2, 0), waystone)
	_label("Gray Concord Waystone", Vector3(0, 5, 0), waystone)
	var wilds := Node3D.new()
	wilds.name = "EmberveilWilds"
	wilds.position = Vector3(20, 0, 0)
	add_child(wilds)
	_add_cyl(1.5, 7.0, Vector3(0, 3.5, 0), wilds)
	_label("Emberveil Wilds", Vector3(0, 9, 0), wilds)
	var coil := Node3D.new()
	coil.name = "CoilcryptMouth"
	coil.position = Vector3(0, 0, -24)
	add_child(coil)
	for i in range(8):
		var a := i * TAU / 8.0
		_add_box(Vector3(1.2, 2.5, 1.2), Vector3(cos(a) * 5.0, 1.25, sin(a) * 5.0), coil)
	_label("Coilcrypt", Vector3(0, 4, 0), coil)
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
