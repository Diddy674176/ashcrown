extends Node3D
## Coilcrypt dungeon - mouth rooms + Coil Warden arena. USE near exit to leave.

signal exit_requested

var _boss: Node3D

func _ready() -> void:
	name = "CoilcryptRuntime"
	_build()
	_spawn_boss()
	if EventBus:
		EventBus.hud_toast.emit("Coilcrypt - defeat the Coil Warden · USE at mouth to leave")

func _build() -> void:
	var floor_b := CSGBox3D.new()
	floor_b.size = Vector3(48, 1, 64)
	floor_b.position = Vector3(0, -0.5, -8)
	floor_b.use_collision = true
	floor_b.collision_layer = 1
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.22, 0.18, 0.2)
	floor_b.material = floor_mat
	add_child(floor_b)
	for x in [-24, 24]:
		var w := CSGBox3D.new()
		w.size = Vector3(2, 6, 64)
		w.position = Vector3(x, 3, -8)
		w.use_collision = true
		w.collision_layer = 1
		add_child(w)
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
	return Vector3(0, 1.2, 12)
