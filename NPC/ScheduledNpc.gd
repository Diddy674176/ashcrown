extends Node3D
class_name ScheduledNpc
## Ashfen Gate key NPC with day/night position + availability (WORLD_FIRST_PLAYABLE §3).

signal interacted(kind: String)

@export var npc_id: String = ""
@export var display_name: String = "NPC"
@export var kind: String = ""
@export var day_pos: Vector3 = Vector3.ZERO
@export var night_pos: Vector3 = Vector3.ZERO
@export var available_day: bool = true
@export var available_night: bool = true
@export var body_color: Color = Color(0.5, 0.48, 0.45)
@export var night_dialog_suffix: String = ""

var _label: Label3D
var _body: MeshInstance3D
var _area: Area3D
var _player_inside: bool = false
var _cycle: Node = null
var _sim_lod: int = 0  # 0 full, 1 simplified, 2 abstract (hidden mesh)

func _ready() -> void:
	add_to_group("scheduled_npc")
	_build()
	_cycle = get_tree().get_first_node_in_group("day_night")
	if _cycle and _cycle.has_signal("phase_changed"):
		_cycle.phase_changed.connect(_on_phase)
	_apply_schedule(false)

func _build() -> void:
	_body = MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.35
	cap.height = 1.4
	_body.mesh = cap
	_body.position = Vector3(0, 0.9, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = body_color
	_body.material_override = mat
	add_child(_body)
	_label = Label3D.new()
	_label.text = display_name
	_label.position = Vector3(0, 2.2, 0)
	_label.font_size = 36
	_label.modulate = Color(0.9, 0.85, 0.6)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(_label)
	_area = Area3D.new()
	_area.name = "Interact"
	_area.collision_layer = 0
	_area.collision_mask = 2
	_area.monitoring = true
	var sh := CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = 2.2
	sh.shape = sph
	_area.add_child(sh)
	_area.body_entered.connect(_on_enter)
	_area.body_exited.connect(_on_exit)
	add_child(_area)

func _on_phase(_is_night: bool) -> void:
	_apply_schedule(true)

func _apply_schedule(animate: bool) -> void:
	var night := false
	if _cycle and _cycle.has_method("is_night"):
		night = bool(_cycle.is_night())
	var avail := available_night if night else available_day
	var target := night_pos if night else day_pos
	visible = avail
	_area.monitoring = avail
	if not avail:
		_player_inside = false
		return
	if animate:
		var tw := create_tween()
		tw.tween_property(self, "position", target, 0.6).set_trans(Tween.TRANS_SINE)
	else:
		position = target
	_refresh_label(night)

func _refresh_label(night: bool) -> void:
	var phase := " (night)" if night else ""
	if night and night_dialog_suffix != "":
		_label.text = "%s%s" % [display_name, phase]
	else:
		_label.text = display_name + phase

func is_player_near() -> bool:
	return visible and _player_inside

func _on_enter(b: Node) -> void:
	if b.is_in_group("player"):
		_player_inside = true
		if EventBus:
			var tip := display_name
			if _cycle and _cycle.has_method("is_night") and _cycle.is_night() and night_dialog_suffix != "":
				tip = "%s — %s" % [display_name, night_dialog_suffix]
			EventBus.hud_toast.emit("USE — %s" % tip)

func _on_exit(b: Node) -> void:
	if b.is_in_group("player"):
		_player_inside = false


func set_sim_lod(lod: int) -> void:
	_sim_lod = lod
	# L2 abstract: keep node for schedule state but hide body when far / elsewhere
	if lod >= 2:
		if _body:
			_body.visible = false
		if _label:
			_label.modulate = Color(0.55, 0.55, 0.6, 0.55)
			_label.text = "%s [L2]" % display_name
	else:
		if _body:
			_body.visible = visible
		if _label:
			_label.modulate = Color(0.9, 0.85, 0.6)
			_refresh_label(_cycle != null and _cycle.has_method("is_night") and bool(_cycle.is_night()))

func bark_line() -> String:
	var night := _cycle != null and _cycle.has_method("is_night") and bool(_cycle.is_night())
	var base := ""
	match kind:
		"len":
			base = "Len (house, offline): Come back at dawn." if night else "Len: Scout the Wilds. Kill 3 hostiles."
		"sera":
			base = "Sera: Lamp-lit maps — AFK profiles live at Ember Camp." if night else "Sera: Archives open. Ask about Ember Camp AFK."
		"smith":
			base = "Brann (tired): Forge stays lit… barely." if night else "Brann: Bring Wake Ore. I'll queue a blade."
		"cald":
			base = "Sister Cald: Vigil on the Singing Root path. The scar hums louder." if night else "Sister Cald: Choirbound shrine — leave the Core alone."
		"inn":
			base = "Rook: Resting at the Inn. Ready when you are." if night else "Inn yard — Rook waits after Len's request."
		"vos":
			base = "Vos: Wall patrol — night bandits thick near the waystone." if night else "Vos: Gate Yard clear. Watch the scar road north."
		_:
			base = "%s greets you." % display_name
	var ws := get_node_or_null("/root/WorldSim")
	if ws:
		var eb := ""
		if ws.has_method("event_bark"):
			eb = str(ws.event_bark(kind))
		if eb != "":
			return eb
		var fb := ""
		if ws.has_method("faction_bark"):
			fb = str(ws.faction_bark(kind))
		if fb != "":
			return "%s — %s" % [base, fb]
	return base
