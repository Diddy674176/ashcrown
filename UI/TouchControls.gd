extends CanvasLayer
## Mobile touch HUD - stick (deadzone), look swipe, ATK hold=heavy/charged, combat bars, AFK report.

signal attack_pressed
signal dodge_pressed
signal skill_pressed(slot: int)
signal jump_pressed
signal interact_pressed

@export var player_path: NodePath
@export var stick_deadzone: float = 0.15
@export var look_deadzone_px: float = 1.2

var _player: Node = null
var _stick_origin := Vector2.ZERO
var _stick_touch_index := -1
var _look_touch_index := -1
var _look_last := Vector2.ZERO
var _pinch_ids: Array[int] = []
var _pinch_start_dist := 0.0
var _touch_pos: Dictionary = {}
var _ui_scale: float = 1.0

@onready var _root: Control = $Root
@onready var _stick_base: Control = $Root/LeftStick
@onready var _stick_knob: Control = $Root/LeftStick/Knob
@onready var _look_zone: Control = $Root/LookZone
@onready var _hp_bar: ProgressBar = $Root/Hud/HpBar
@onready var _sta_bar: ProgressBar = $Root/Hud/StaBar
@onready var _foc_bar: ProgressBar = $Root/Hud/FocBar
@onready var _heat_bar: ProgressBar = $Root/Hud/HeatBar
@onready var _toast: Label = $Root/Toast
@onready var _afk_btn: Button = $Root/AfkBtn
@onready var _report: Control = $Root/ReturnReport
@onready var _report_body: Label = $Root/ReturnReport/VBox/Body
@onready var _hint: Label = $Root/Hint

func _ready() -> void:
	if player_path:
		_player = get_node_or_null(player_path)
	_apply_phone_scale()
	get_viewport().size_changed.connect(_apply_phone_scale)
	_stick_base.gui_input.connect(_on_stick_gui)
	_look_zone.gui_input.connect(_on_look_gui)
	var atk: BaseButton = $Root/RightCluster/Attack
	atk.button_down.connect(func(): EventBus.attack_hold_started.emit())
	atk.button_up.connect(func():
		EventBus.attack_hold_ended.emit()
		attack_pressed.emit()
	)
	$Root/RightCluster/Dodge.pressed.connect(func():
		dodge_pressed.emit()
		EventBus.action_dodge.emit()
	)
	$Root/RightCluster/Skill1.pressed.connect(func():
		skill_pressed.emit(1)
		EventBus.action_skill.emit(1)
	)
	$Root/RightCluster/Skill2.pressed.connect(func():
		skill_pressed.emit(2)
		EventBus.action_skill.emit(2)
	)
	$Root/RightCluster/Jump.pressed.connect(func():
		jump_pressed.emit()
		EventBus.action_jump.emit()
		if _player and _player.has_method("request_jump"):
			_player.request_jump()
	)
	$Root/RightCluster/Interact.pressed.connect(func():
		interact_pressed.emit()
		EventBus.action_interact.emit()
	)
	if $Root/RightCluster.has_node("Block"):
		var blk: BaseButton = $Root/RightCluster/Block
		blk.button_down.connect(func():
			if _player and _player.has_method("set_blocking"):
				_player.set_blocking(true)
		)
		blk.button_up.connect(func():
			if _player and _player.has_method("set_blocking"):
				_player.set_blocking(false)
		)
	_afk_btn.toggled.connect(_on_afk_toggled)
	$Root/ReturnReport/VBox/Close.pressed.connect(func(): _report.visible = false)
	if EventBus:
		EventBus.hud_toast.connect(_show_toast)
		EventBus.afk_stopped.connect(_show_afk_report)
		EventBus.loot_gained.connect(func(d):
			_show_toast("+%s XP · %sg · %s" % [d.get("xp", 0), d.get("gold", 0), d.get("item", "")])
		)
		EventBus.boss_phase_changed.connect(func(_id, banner): _show_toast(str(banner)))
	_report.visible = false

func bind_player(p: Node) -> void:
	_player = p
	if p and p.get("combat"):
		var c = p.combat
		if c and c.has_signal("resources_changed"):
			c.resources_changed.connect(_refresh_bars)
	_refresh_bars()

func _apply_phone_scale() -> void:
	var sz := get_viewport().get_visible_rect().size
	var shortest := minf(sz.x, sz.y)
	_ui_scale = clampf(shortest / 720.0, 0.85, 1.35)
	if _hint:
		_hint.text = "Ashcrown - stick · swipe look · hold ATK=heavy · DODGE i-frames · USE=Coilcrypt"

func _process(_delta: float) -> void:
	_refresh_bars()

func _refresh_bars() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	var c = _player.get("combat")
	if c == null:
		return
	_hp_bar.max_value = c.max_hp
	_hp_bar.value = c.hp
	_sta_bar.max_value = c.max_stamina
	_sta_bar.value = c.stamina
	_foc_bar.max_value = c.max_focus
	_foc_bar.value = c.focus
	_heat_bar.max_value = c.max_heat
	_heat_bar.value = c.heat

func _on_afk_toggled(on: bool) -> void:
	var afk := get_node_or_null("/root/AfkManager")
	if afk == null:
		_show_toast("AFK unavailable")
		_afk_btn.set_pressed_no_signal(false)
		return
	if on:
		afk.start_afk("Balanced")
		_show_toast("AFK Balanced - simulating...")
	else:
		var report: Dictionary = afk.stop_afk("player_cancel")
		_show_afk_report(report)

func _show_afk_report(report: Dictionary) -> void:
	_report.visible = true
	_report_body.text = "AFK Return Report\nprofile: %s\nduration: %ss\nkills: %s\nxp: %s\ngold: %s\nstop: %s" % [
		report.get("profile", "?"),
		report.get("duration_sec", 0),
		report.get("kills", 0),
		report.get("xp_gained", 0),
		report.get("gold_gained", 0),
		report.get("stop_reason", ""),
	]
	_afk_btn.set_pressed_no_signal(false)

func _show_toast(text: String) -> void:
	_toast.text = text
	_toast.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(2.2)
	tw.tween_property(_toast, "modulate:a", 0.0, 0.6)

func _on_stick_gui(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_stick_touch_index = event.index
			_stick_origin = event.position
			_update_stick(event.position)
		elif event.index == _stick_touch_index:
			_stick_touch_index = -1
			_set_move(Vector2.ZERO)
			_stick_knob.position = (_stick_base.size - _stick_knob.size) * 0.5
	elif event is InputEventScreenDrag and event.index == _stick_touch_index:
		_update_stick(event.position)

func _update_stick(pos: Vector2) -> void:
	var center := _stick_base.size * 0.5
	var delta := pos - _stick_origin
	var max_r := minf(_stick_base.size.x, _stick_base.size.y) * 0.4
	var clamped := delta.limit_length(max_r)
	_stick_knob.position = center - _stick_knob.size * 0.5 + clamped
	var raw := Vector2(clamped.x / max_r, clamped.y / max_r)
	if raw.length() < stick_deadzone:
		_set_move(Vector2.ZERO)
	else:
		var len := raw.length()
		var adj := (len - stick_deadzone) / (1.0 - stick_deadzone)
		_set_move(raw.normalized() * adj)

func _set_move(dir: Vector2) -> void:
	if _player and _player.has_method("set_touch_move"):
		_player.set_touch_move(Vector2(dir.x, dir.y))

func _on_look_gui(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_touch_pos[event.index] = event.position
			if event.index not in _pinch_ids and _pinch_ids.size() < 2:
				_pinch_ids.append(event.index)
			if _pinch_ids.size() == 1:
				_look_touch_index = event.index
				_look_last = event.position
			elif _pinch_ids.size() == 2:
				_look_touch_index = -1
				_pinch_start_dist = _pinch_distance()
		else:
			_touch_pos.erase(event.index)
			_pinch_ids.erase(event.index)
			if event.index == _look_touch_index:
				_look_touch_index = -1
			if _pinch_ids.size() < 2:
				_pinch_start_dist = 0.0
	elif event is InputEventScreenDrag:
		_touch_pos[event.index] = event.position
		if _pinch_ids.size() >= 2:
			var d := _pinch_distance()
			if _pinch_start_dist > 1.0 and _player and _player.has_method("add_pinch_zoom"):
				var zdelta := (_pinch_start_dist - d) * 0.01
				_player.add_pinch_zoom(zdelta)
				_pinch_start_dist = d
		elif event.index == _look_touch_index:
			var delta: Vector2 = event.position - _look_last
			_look_last = event.position
			if delta.length() >= look_deadzone_px and _player and _player.has_method("add_touch_look"):
				_player.add_touch_look(delta)

func _pinch_distance() -> float:
	if _pinch_ids.size() < 2:
		return 0.0
	var a: Vector2 = _touch_pos.get(_pinch_ids[0], Vector2.ZERO)
	var b: Vector2 = _touch_pos.get(_pinch_ids[1], Vector2.ZERO)
	return a.distance_to(b)
