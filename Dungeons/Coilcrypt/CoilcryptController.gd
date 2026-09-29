extends Node3D
## Coilcrypt dungeon — mouth, outer-ring teach rooms, Coil Warden arena.

signal exit_requested

const _Teach = preload("res://Combat/TeachSentry.gd")

var _boss: Node3D

func _ready() -> void:
	name = "CoilcryptRuntime"
	_build()
	_spawn_outer_ring_teach()
	_spawn_boss()
	if EventBus:
		EventBus.hud_toast.emit("Coilcrypt — outer ring teaches amber/blue/red · then Coil Warden")

func _build() -> void:
	# Floor
	var floor_b := CSGBox3D.new()
	floor_b.size = Vector3(48, 1, 64)
	floor_b.position = Vector3(0, -0.5, -8)
	floor_b.use_collision = true
	floor_b.collision_layer = 1
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.22, 0.18, 0.2)
	floor_b.material = floor_mat
	add_child(floor_b)
	# Walls stub
	var wall_mat := StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.18, 0.14, 0.16)
	for x in [-24, 24]:
		var w := CSGBox3D.new()
		w.size = Vector3(2, 6, 64)
		w.position = Vector3(x, 3, -8)
		w.use_collision = true
		w.collision_layer = 1
		w.material = wall_mat
		add_child(w)
	# Arena plate (north)
	var arena := CSGCylinder3D.new()
	arena.radius = 14.0
	arena.height = 0.4
	arena.position = Vector3(0, 0.2, -28)
	arena.use_collision = true
	arena.collision_layer = 1
	var am := StandardMaterial3D.new()
	am.albedo_color = Color(0.55, 0.28, 0.18)
	arena.material = am
	add_child(arena)
	var title := Label3D.new()
	title.text = "Coilcrypt - Coil Warden Arena"
	title.position = Vector3(0, 6, -28)
	title.font_size = 40
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(title)
	var mouth := Label3D.new()
	mouth.text = "Mouth - USE to return to Emberveil"
	mouth.position = Vector3(0, 3, 18)
	mouth.font_size = 28
	mouth.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(mouth)
	# Exit zone
	var exit_area := Area3D.new()
	exit_area.name = "ExitZone"
	exit_area.position = Vector3(0, 1, 18)
	exit_area.collision_mask = 2
	var sh := CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = 4.0
	sh.shape = sph
	exit_area.add_child(sh)
	exit_area.set_meta("player_inside", false)
	exit_area.body_entered.connect(func(b):
		if b.is_in_group("player"):
			exit_area.set_meta("player_inside", true)
			EventBus.hud_toast.emit("Exit zone - press USE to leave Coilcrypt")
	)
	exit_area.body_exited.connect(func(b):
		if b.is_in_group("player"):
			exit_area.set_meta("player_inside", false)
	)
	add_child(exit_area)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50, 20, 0)
	light.light_energy = 0.9
	light.shadow_enabled = false
	add_child(light)
	var env_node := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.12, 0.1, 0.14)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.4, 0.35, 0.4)
	e.ambient_light_energy = 0.7
	env_node.environment = e
	add_child(env_node)

func _spawn_outer_ring_teach() -> void:
	# Outer ring clockwise — teach telegraphs on conduit sentries before Warden
	var ring := Node3D.new()
	ring.name = "OuterRingTeach"
	add_child(ring)
	var floor_pad := CSGCylinder3D.new()
	floor_pad.radius = 8.0
	floor_pad.height = 0.25
	floor_pad.position = Vector3(0, 0.12, 2)
	floor_pad.use_collision = true
	floor_pad.collision_layer = 1
	var pm := StandardMaterial3D.new()
	pm.albedo_color = Color(0.3, 0.26, 0.28)
	floor_pad.material = pm
	ring.add_child(floor_pad)
	var title := Label3D.new()
	title.text = "Outer Ring — learn telegraphs before the Warden"
	title.position = Vector3(0, 4.5, 2)
	title.font_size = 32
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	title.modulate = Color(0.95, 0.8, 0.45)
	ring.add_child(title)
	# Three sentries around the ring
	ring.add_child(_Teach.make(_Teach.Lesson.DODGE_AMBER, Vector3(-5, 0.5, 4), "Amber Sentry"))
	ring.add_child(_Teach.make(_Teach.Lesson.BLOCK_BLUE, Vector3(0, 0.5, 0), "Blue Sentry"))
	ring.add_child(_Teach.make(_Teach.Lesson.UNBLOCKABLE_RED, Vector3(5, 0.5, 4), "Red Sentry"))
	# Soft lore tablet
	var tablet := Label3D.new()
	tablet.text = "Amber=DODGE · Blue-white=BLOCK · Red=UNBLOCKABLE"
	tablet.position = Vector3(0, 2.2, 6)
	tablet.font_size = 24
	tablet.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	ring.add_child(tablet)

func _spawn_boss() -> void:
	var script = preload("res://Combat/CoilWardenBoss.gd")
	_boss = script.new()
	_boss.position = Vector3(0, 0.5, -28)
	add_child(_boss)

func is_player_at_exit(player: Node3D) -> bool:
	var z := get_node_or_null("ExitZone")
	if z and z.get_meta("player_inside", false):
		return true
	if player == null:
		return false
	return player.global_position.distance_to(Vector3(0, 1, 18)) < 5.0

func get_player_entry() -> Vector3:
	return Vector3(0, 1.2, 10)  # mouth → outer ring teach → arena north
