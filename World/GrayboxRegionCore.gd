extends Node3D

const REGION_NAME := "Emberveil Reach"
const _Enemy = preload("res://Combat/EnemyBase.gd")
const _ScheduledNpc = preload("res://NPC/ScheduledNpc.gd")
const _Teach = preload("res://Combat/TeachSentry.gd")
const _DayNight = preload("res://Core/DayNightCycle.gd")

var _interact_target: String = ""
var _sun: DirectionalLight3D
var _day_night: Node = null
var _env: Environment = null
var _scheduled: Dictionary = {}  # kind -> ScheduledNpc

func _ready() -> void:
	name = "EmberveilReach"
	_day_night = _DayNight.new()
	_day_night.name = "DayNightCycle"
	add_child(_day_night)
	_day_night.phase_changed.connect(_on_day_night)
	_build()
	_spawn_town_npcs()
	_spawn_wake_pit_teach()
	_spawn_wilds_enemies()
	_spawn_ember_camp()
	_spawn_coilcrypt_portal()
	_on_day_night(_day_night.is_night())
	if EventBus:
		EventBus.region_entered.emit(&"emberveil_reach")
		EventBus.player_interact.connect(_on_interact)

func _build() -> void:
	_add_box(Vector3(90, 1, 90), Vector3(0, -0.5, 0), null, Color(0.28, 0.32, 0.26))

	var ashfen := Node3D.new()
	ashfen.name = "AshfenGate"
	ashfen.position = Vector3(0, 0, 22)
	add_child(ashfen)
	_add_box(Vector3(2, 10, 2), Vector3(0, 5, 0), ashfen, Color(0.72, 0.58, 0.32))  # spire
	_add_box(Vector3(14, 3, 1.2), Vector3(0, 1.5, 3), ashfen, Color(0.55, 0.48, 0.38))  # wall ring front
	_add_box(Vector3(1.2, 3, 10), Vector3(-7, 1.5, -1), ashfen, Color(0.55, 0.48, 0.38))
	_add_box(Vector3(1.2, 3, 10), Vector3(7, 1.5, -1), ashfen, Color(0.55, 0.48, 0.38))
	_label("Ashfen Gate", Vector3(0, 11, 0), ashfen)
	_label("Gate Yard", Vector3(-4, 3.5, 4), ashfen)
	_label("Market Ring", Vector3(5, 3.2, 1), ashfen)
	_label("Concord Hall", Vector3(-5, 3.2, -2), ashfen)
	_label("Lower Quarters / Inn", Vector3(5, 3.2, -4), ashfen)

	var waystone := Node3D.new()
	waystone.name = "GrayConcordWaystone"
	waystone.position = Vector3(0, 0, 0)
	add_child(waystone)
	_add_cyl(0.6, 4.0, Vector3(0, 2, 0), waystone, Color(0.55, 0.58, 0.62))
	_add_box(Vector3(2.5, 0.3, 2.5), Vector3(0, 0.15, 0), waystone)
	_label("Gray Concord Waystone", Vector3(0, 5, 0), waystone)

	var wilds := Node3D.new()
	wilds.name = "EmberveilWilds"
	wilds.position = Vector3(22, 0, 0)
	add_child(wilds)
	_add_cyl(1.8, 8.0, Vector3(0, 4.0, 0), wilds, Color(0.22, 0.42, 0.28))  # Singing Root trunk
	_add_cyl(4.0, 1.2, Vector3(0, 8.4, 0), wilds, Color(0.75, 0.55, 0.22))  # canopy
	for i in range(4):
		var a := i * TAU / 4.0
		_add_box(Vector3(0.3, 3.5, 0.3), Vector3(cos(a) * 2.2, 2.0, sin(a) * 2.2), wilds, Color(0.35, 0.65, 0.85))
	_label("The Singing Root", Vector3(0, 10, 0), wilds)
	_label("Emberveil Wilds", Vector3(0, 9, 3), wilds)

	var coil := Node3D.new()
	coil.name = "CoilcryptMouth"
	coil.position = Vector3(0, 0, -24)
	add_child(coil)
	for i in range(8):
		var a := i * TAU / 8.0
		_add_box(Vector3(1.2, 2.5, 1.2), Vector3(cos(a) * 5.0, 1.25, sin(a) * 5.0), coil, Color(0.55, 0.28, 0.18))
	_add_cyl(3.5, 0.4, Vector3(0, 0.2, 0), coil, Color(0.85, 0.4, 0.15))
	_label("Coilcrypt — USE to enter", Vector3(0, 4, 0), coil)

	var ramp := CSGBox3D.new()
	ramp.size = Vector3(4, 0.4, 10)
	ramp.position = Vector3(-12, 1.0, 8)
	ramp.rotation_degrees = Vector3(12, 40, 0)
	ramp.use_collision = true
	ramp.collision_layer = 1
	add_child(ramp)

	_sun = DirectionalLight3D.new()
	_sun.rotation_degrees = Vector3(-45, 30, 0)
	_sun.light_energy = 1.1
	_sun.shadow_enabled = false
	_sun.add_to_group("world_light")
	add_child(_sun)
	var perf := get_node_or_null("/root/PerformanceSettings")
	if perf and perf.has_method("register_sun"):
		perf.register_sun(_sun)

	var env_node := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.42, 0.38, 0.48)  # dusk emberveil
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.62, 0.52, 0.48)
	e.ambient_light_energy = 0.75
	env_node.environment = e
	_env = e
	add_child(env_node)

func _on_day_night(is_night: bool) -> void:
	if _sun:
		_sun.light_energy = 0.4 if is_night else 1.15
		_sun.light_color = Color(0.55, 0.6, 0.85) if is_night else Color(1.0, 0.95, 0.88)
	if _env:
		_env.background_color = Color(0.14, 0.16, 0.28) if is_night else Color(0.42, 0.38, 0.48)
		_env.ambient_light_color = Color(0.35, 0.4, 0.55) if is_night else Color(0.62, 0.52, 0.48)
		_env.ambient_light_energy = 0.45 if is_night else 0.75

func _spawn_town_npcs() -> void:
	_add_scheduled("MagistrateLen", "Magistrate Len", "len",
		Vector3(-4, 0, 20), Vector3(-6, 0, 14), true, false,
		Color(0.55, 0.5, 0.45), "offline at house")
	_add_scheduled("ArchivistSera", "Archivist Sera", "sera",
		Vector3(-5.5, 0, 19), Vector3(-3.5, 0, 19.5), true, true,
		Color(0.45, 0.5, 0.65), "lamp-lit hall")
	_add_scheduled("SmithBrann", "Smith Brann", "smith",
		Vector3(6, 0, 19), Vector3(6, 0, 19), true, true,
		Color(0.55, 0.4, 0.35), "tired — forge still open")
	_add_scheduled("SisterCald", "Sister Cald", "cald",
		Vector3(9, 0, 18), Vector3(18, 0, 4), true, true,
		Color(0.7, 0.65, 0.85), "vigil toward Singing Root")
	_add_scheduled("RookSpot", "Rook", "inn",
		Vector3(5, 0, 16), Vector3(4.5, 0, 15.5), true, true,
		Color(0.5, 0.45, 0.55), "resting at Inn")
	_add_scheduled("GuardCaptainVos", "Guard Captain Vos", "vos",
		Vector3(-2, 0, 24), Vector3(0, 0, 28), true, true,
		Color(0.4, 0.42, 0.48), "wall patrol")
	_make_static_npc("VendorMara", "Vendor Mara", Vector3(4, 0, 23), "vendor", Color(0.45, 0.55, 0.4))
	_make_static_npc("AlchemistPyra", "Alchemist Pyra", Vector3(3, 0, 18), "alchemy", Color(0.4, 0.5, 0.6))

func _add_scheduled(node_name: String, label: String, kind: String,
		day_p: Vector3, night_p: Vector3, avail_day: bool, avail_night: bool,
		color: Color, night_sfx: String) -> void:
	var n = _ScheduledNpc.new()
	n.name = node_name
	n.npc_id = kind
	n.display_name = label
	n.kind = kind
	n.day_pos = day_p
	n.night_pos = night_p
	n.available_day = avail_day
	n.available_night = avail_night
	n.body_color = color
	n.night_dialog_suffix = night_sfx
	n.position = day_p
	add_child(n)
	_scheduled[kind] = n
	n.set_meta("kind", kind)

func _make_static_npc(node_name: String, label: String, pos: Vector3, kind: String, color: Color) -> void:
	var root := Node3D.new()
	root.name = node_name
	root.position = pos
	add_child(root)
	var body := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.35
	cap.height = 1.4
	body.mesh = cap
	body.position = Vector3(0, 0.9, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	body.material_override = mat
	root.add_child(body)
	_label(label, Vector3(0, 2.2, 0), root)
	var area := Area3D.new()
	area.name = "Interact"
	area.collision_layer = 0
	area.collision_mask = 2
	area.monitoring = true
	var sh := CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = 2.2
	sh.shape = sph
	area.add_child(sh)
	area.set_meta("npc_kind", kind)
	area.set_meta("player_inside", false)
	area.body_entered.connect(func(b):
		if b.is_in_group("player"):
			area.set_meta("player_inside", true)
			_interact_target = kind
			if EventBus:
				EventBus.hud_toast.emit("USE — %s" % label)
	)
	area.body_exited.connect(func(b):
		if b.is_in_group("player"):
			area.set_meta("player_inside", false)
			if _interact_target == kind:
				_interact_target = ""
	)
	root.add_child(area)

func _spawn_wake_pit_teach() -> void:
	var pit := Node3D.new()
	pit.name = "StarterWakePit"
	pit.position = Vector3(0, 0, 34)
	add_child(pit)
	_add_cyl(4.5, 0.5, Vector3(0, 0.1, 0), pit, Color(0.35, 0.28, 0.22))
	_add_box(Vector3(1.2, 2.0, 1.2), Vector3(-3, 1.0, -2), pit, Color(0.55, 0.35, 0.2))
	_add_box(Vector3(1.2, 2.0, 1.2), Vector3(3, 1.0, -2), pit, Color(0.55, 0.35, 0.2))
	_label("Starter Wake-Pit — teach telegraphs", Vector3(0, 3.5, 0), pit)
	add_child(_Teach.make(_Teach.Lesson.DODGE_AMBER, Vector3(-2.5, 0.5, 32), "Wake Spark (Dodge)"))
	add_child(_Teach.make(_Teach.Lesson.BLOCK_BLUE, Vector3(0, 0.5, 31), "Coil Plate (Block)"))
	add_child(_Teach.make(_Teach.Lesson.UNBLOCKABLE_RED, Vector3(2.5, 0.5, 32), "Rupture Echo (Red)"))

func _spawn_wilds_enemies() -> void:
	add_child(_Enemy.make_skirmisher(Vector3(18, 0.5, 2)))
	add_child(_Enemy.make_skirmisher(Vector3(24, 0.5, -2)))
	add_child(_Enemy.make_bruiser(Vector3(28, 0.5, 4)))
	add_child(_Enemy.make_caster(Vector3(20, 0.5, -8)))
	add_child(_Enemy.make_skirmisher(Vector3(12, 0.5, 8)))

func _spawn_ember_camp() -> void:
	var camp := Node3D.new()
	camp.name = "EmberCamp"
	camp.position = Vector3(14, 0, 6)
	camp.add_to_group("ember_camp")
	add_child(camp)
	_add_box(Vector3(3.5, 0.2, 3.5), Vector3(0, 0.1, 0), camp)
	var fire := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.35
	sm.height = 0.7
	fire.mesh = sm
	fire.position = Vector3(0, 0.5, 0)
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(1.0, 0.45, 0.15)
	fm.emission_enabled = true
	fm.emission = Color(1.0, 0.4, 0.1)
	fm.emission_energy_multiplier = 1.2
	fire.material_override = fm
	camp.add_child(fire)
	_add_box(Vector3(2.5, 0.15, 1.8), Vector3(1.2, 1.2, 0), camp)
	_label("Ember Camp — AFK radius", Vector3(0, 2.5, 0), camp)
	_add_gather_node("EmberFiberNode", "Ember Fiber", "ember_fiber", Vector3(16, 0, 3))
	_add_gather_node("WakeOreNode", "Wake Ore", "wake_ore", Vector3(26, 0, -1))

func _add_gather_node(node_name: String, label: String, item_id: String, pos: Vector3) -> void:
	var n := Node3D.new()
	n.name = node_name
	n.position = pos
	add_child(n)
	_add_cyl(0.4, 0.8, Vector3(0, 0.4, 0), n)
	_label(label + " — USE", Vector3(0, 1.6, 0), n)
	var area := Area3D.new()
	area.collision_mask = 2
	area.monitoring = true
	var sh := CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = 1.8
	sh.shape = sph
	area.add_child(sh)
	area.set_meta("gather_id", item_id)
	area.set_meta("player_inside", false)
	area.set_meta("gathered", false)
	area.body_entered.connect(func(b):
		if b.is_in_group("player"):
			area.set_meta("player_inside", true)
			_interact_target = "gather:%s" % item_id
			if EventBus:
				EventBus.hud_toast.emit("USE — gather %s" % label)
	)
	area.body_exited.connect(func(b):
		if b.is_in_group("player"):
			area.set_meta("player_inside", false)
	)
	n.add_child(area)

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
			_interact_target = "coilcrypt"
			if EventBus:
				EventBus.hud_toast.emit("Coilcrypt mouth — press USE to enter")
	)
	area.body_exited.connect(func(body: Node):
		if body.is_in_group("player"):
			area.set_meta("player_inside", false)
			if _interact_target == "coilcrypt":
				_interact_target = ""
	)
	add_child(area)

func is_player_at_coilcrypt(player: Node3D) -> bool:
	var portal := get_node_or_null("CoilcryptPortal")
	if portal and portal.get_meta("player_inside", false):
		return true
	if player == null:
		return false
	return player.global_position.distance_to(Vector3(0, 1.0, -24)) < 5.5

func get_interact_target() -> String:
	return _interact_target

func _process(_delta: float) -> void:
	for kind in _scheduled.keys():
		var n = _scheduled[kind]
		if n and n.has_method("is_player_near") and n.is_player_near():
			_interact_target = str(kind)
			return

func _on_interact(player: Node) -> void:
	if player == null:
		return
	var t := _interact_target
	if t == "" or t == "coilcrypt":
		return  # Main handles coilcrypt
	if t.begins_with("gather:"):
		var item_id := t.substr(7)
		_do_gather(player, item_id)
		return
	match t:
		"len":
			_do_len(player)
		"sera":
			_do_sera(player)
		"vendor":
			_do_vendor(player)
		"smith":
			_do_smith(player)
		"alchemy":
			_do_alchemy(player)
		"cald":
			_do_cald(player)
		"inn":
			_do_inn(player)
		"vos":
			_do_vos(player)

func _do_gather(player: Node, item_id: String) -> void:
	if player.has_method("add_item"):
		player.add_item(item_id)
	elif "inventory" in player:
		player.inventory.append(item_id)
	var qm := get_node_or_null("/root/QuestManager")
	if qm and qm.has_method("notify_item_gained"):
		qm.notify_item_gained(item_id)
	if EventBus:
		EventBus.hud_toast.emit("Gathered %s" % item_id)
		EventBus.loot_gained.emit({"xp": 2, "gold": 0, "item": item_id})

func _do_len(_player: Node) -> void:
	var n = _scheduled.get("len")
	if n and not n.visible:
		if EventBus:
			EventBus.hud_toast.emit("Len is offline at his house — return at dawn.")
		return
	var qm := get_node_or_null("/root/QuestManager")
	var tree_id := "len_intro"
	if qm and qm.has_method("dialogue_tree_for_len"):
		tree_id = qm.dialogue_tree_for_len()
	if _open_dialogue(tree_id):
		return
	if qm and qm.has_method("interact_len"):
		qm.interact_len()
	elif EventBus:
		EventBus.hud_toast.emit(_bark("len"))

func _do_sera(_player: Node) -> void:
	if _open_dialogue("sera_archive"):
		return
	if EventBus:
		EventBus.hud_toast.emit(_bark("sera"))

func _do_cald(_player: Node) -> void:
	if _open_dialogue("cald_shrine"):
		return
	if EventBus:
		EventBus.hud_toast.emit(_bark("cald"))
		EventBus.quest_flag_set.emit(&"met_cald", true)

func _open_dialogue(tree_id: String) -> bool:
	var dlg := get_tree().get_first_node_in_group("dialogue_panel")
	if dlg == null:
		var main := get_tree().current_scene
		if main:
			dlg = main.get_node_or_null("DialoguePanel")
	if dlg and dlg.has_method("open_tree"):
		dlg.open_tree(tree_id)
		return true
	return false

func _do_vos(_player: Node) -> void:
	if EventBus:
		EventBus.hud_toast.emit(_bark("vos"))

func _bark(kind: String) -> String:
	var n = _scheduled.get(kind)
	if n and n.has_method("bark_line"):
		return n.bark_line()
	return "…"

func _do_vendor(player: Node) -> void:
	var sold := 0
	if "inventory" in player:
		var keep: Array = []
		for it in player.inventory:
			if str(it) == "vein_mite_carapace":
				player.gold += 4
				sold += 1
			else:
				keep.append(it)
		player.inventory = keep
	if sold > 0:
		if EventBus:
			EventBus.hud_toast.emit("Mara bought %d carapace (+%dg)" % [sold, sold * 4])
	elif "gold" in player and player.gold >= 8:
		player.gold -= 8
		if player.has_method("add_item"):
			player.add_item("health_draught")
		else:
			player.inventory.append("health_draught")
		if EventBus:
			EventBus.hud_toast.emit("Bought Health Draught (−8g)")
	elif EventBus:
		EventBus.hud_toast.emit("Mara: Sell carapace or buy draught (8g)")

func _do_smith(player: Node) -> void:
	var cq := get_node_or_null("/root/CraftQueue")
	if cq:
		cq.bind_player(player)
		var r: String = cq.try_start("smith_scar_saber", "smith")
		if r == "ok":
			return
		r = cq.try_start("smith_iron_blade", "smith")
		if r != "ok" and EventBus:
			EventBus.hud_toast.emit("Brann: Wake Ore+gold for blade; +shard for Rare Scar-Wake Saber (%s)" % r)
	elif EventBus:
		EventBus.hud_toast.emit("Brann: Forge closed (stub)")

func _do_alchemy(player: Node) -> void:
	var cq := get_node_or_null("/root/CraftQueue")
	if cq:
		cq.bind_player(player)
		var r: String = cq.try_start("alchemy_draught", "alchemy")
		if r != "ok" and EventBus:
			EventBus.hud_toast.emit("Pyra: need Ember Fiber + 5g (%s)" % r)
	elif EventBus:
		EventBus.hud_toast.emit("Pyra: Alchemy closed (stub)")

func _do_inn(player: Node) -> void:
	var qm := get_node_or_null("/root/QuestManager")
	if qm and qm.has_method("recruit_unlocked") and qm.recruit_unlocked():
		if player.has_method("recruit_companion"):
			player.recruit_companion("Rook")
		elif EventBus:
			EventBus.hud_toast.emit("Rook joins your watch.")
			EventBus.quest_flag_set.emit(&"rook_recruited", true)
	elif EventBus:
		EventBus.hud_toast.emit("Inn: Rook waits — finish Len's request first.")

func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	return m

func _add_box(size: Vector3, pos: Vector3, parent: Node = null, col: Color = Color(0.32, 0.34, 0.3)) -> CSGBox3D:
	var b := CSGBox3D.new()
	b.size = size
	b.position = pos
	b.use_collision = true
	b.collision_layer = 1
	b.material = _mat(col)
	(parent if parent else self).add_child(b)
	return b

func _add_cyl(radius: float, height: float, pos: Vector3, parent: Node = null, col: Color = Color(0.4, 0.38, 0.36)) -> CSGCylinder3D:
	var c := CSGCylinder3D.new()
	c.radius = radius
	c.height = height
	c.position = pos
	c.use_collision = true
	c.collision_layer = 1
	c.material = _mat(col)
	(parent if parent else self).add_child(c)
	return c

func _label(text: String, pos: Vector3, parent: Node) -> void:
	var l := Label3D.new()
	l.text = text
	l.position = pos
	l.font_size = 40
	l.modulate = Color(0.9, 0.85, 0.6)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	parent.add_child(l)
