extends CanvasLayer
## Mobile touch HUD — remappable stick/cluster, AFK report, profile/combat/gfx.

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

var _profile_btn: Button
var _auto_btn: Button
var _gfx_btn: Button
var _stats_lbl: Label
var _controls_btn: Button
var _layout_panel: PanelContainer
var _layout_id: String = "default"  # default | left_hand
var _stick_side: String = "left"    # left | right
var _right_cluster: Control
var _default_stick_offsets: Dictionary = {}
var _default_cluster_offsets: Dictionary = {}
var _inv_panel: Node = null
var _char_panel: Node = null
var _dlg_panel: Node = null
var _inv_btn: Button
var _char_btn: Button
var _quest_lbl: Label

func _ready() -> void:
	if player_path:
		_player = get_node_or_null(player_path)
	_apply_phone_scale()
	get_viewport().size_changed.connect(_apply_phone_scale)
	_stick_base.gui_input.connect(_on_stick_gui)
	_look_zone.gui_input.connect(_on_look_gui)
	var atk: BaseButton = $Root/RightCluster/Attack
	atk.button_down.connect(func():
		EventBus.attack_hold_started.emit()
	)
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
	_afk_btn.text = "Agent"
	$Root/ReturnReport/VBox/Close.pressed.connect(func():
		_report.visible = false
	)
	_ensure_extra_buttons()
	_right_cluster = $Root/RightCluster
	_cache_default_layout()
	_load_layout_from_save()
	_ensure_controls_panel()
	if EventBus:
		EventBus.hud_toast.connect(_show_toast)
		EventBus.afk_stopped.connect(_show_afk_report)
		EventBus.loot_gained.connect(func(d):
			var iname := str(d.get("item_name", d.get("item", "")))
			_show_toast("+%s XP · %sg · %s" % [d.get("xp", 0), d.get("gold", 0), iname])
		)
		EventBus.boss_phase_changed.connect(func(_id, banner):
			_show_toast(str(banner))
		)
	_report.visible = false
	_report_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func _ensure_extra_buttons() -> void:
	# Profile cycle — "Watch profile"
	_profile_btn = Button.new()
	_profile_btn.name = "ProfileBtn"
	_profile_btn.text = "Balanced"
	_profile_btn.position = Vector2(0, 0)
	_profile_btn.size = Vector2(120, 36)
	_root.add_child(_profile_btn)
	_profile_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_profile_btn.offset_left = -270
	_profile_btn.offset_top = 36
	_profile_btn.offset_right = -148
	_profile_btn.offset_bottom = 72
	_profile_btn.pressed.connect(func():
		var afk := get_node_or_null("/root/AfkManager")
		if afk and afk.has_method("cycle_profile"):
			_profile_btn.text = afk.cycle_profile()
		_show_toast("Watch profile: %s" % _profile_btn.text)
	)
	var afk0 := get_node_or_null("/root/AfkManager")
	if afk0:
		_profile_btn.text = str(afk0.active_profile)

	# Combat mode AUTO
	_auto_btn = Button.new()
	_auto_btn.name = "AutoBtn"
	_auto_btn.text = "Manual"
	_auto_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_auto_btn.offset_left = -270
	_auto_btn.offset_top = 78
	_auto_btn.offset_right = -148
	_auto_btn.offset_bottom = 114
	_root.add_child(_auto_btn)
	_auto_btn.pressed.connect(func():
		if _player and _player.has_method("cycle_combat_mode"):
			_player.cycle_combat_mode()
			_auto_btn.text = _player.get_combat_mode_name()
	)

	# Graphics preset
	_gfx_btn = Button.new()
	_gfx_btn.name = "GfxBtn"
	_gfx_btn.text = "Mid"
	_gfx_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_gfx_btn.offset_left = -270
	_gfx_btn.offset_top = 120
	_gfx_btn.offset_right = -148
	_gfx_btn.offset_bottom = 156
	_root.add_child(_gfx_btn)
	_gfx_btn.pressed.connect(func():
		var perf := get_node_or_null("/root/PerformanceSettings")
		if perf and perf.has_method("cycle"):
			_gfx_btn.text = perf.cycle()
	)

	# Soft-lock toggle (default ON)
	var lock_btn := Button.new()
	lock_btn.name = "LockBtn"
	lock_btn.text = "Lock ON"
	lock_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	lock_btn.offset_left = -270
	lock_btn.offset_top = 162
	lock_btn.offset_right = -148
	lock_btn.offset_bottom = 198
	_root.add_child(lock_btn)
	lock_btn.pressed.connect(func():
		if _player and _player.has_method("toggle_soft_lock"):
			_player.toggle_soft_lock()
			lock_btn.text = "Lock ON" if bool(_player.soft_lock_on) else "Lock OFF"
	)

	_stats_lbl = Label.new()
	_stats_lbl.name = "StatsLbl"
	_stats_lbl.position = Vector2(12, 150)
	_stats_lbl.size = Vector2(360, 80)
	_stats_lbl.add_theme_font_size_override("font_size", 13)
	_root.add_child(_stats_lbl)

	_inv_btn = Button.new()
	_inv_btn.name = "InvBtn"
	_inv_btn.text = "INV"
	_inv_btn.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_inv_btn.offset_left = 12
	_inv_btn.offset_top = 230
	_inv_btn.offset_right = 90
	_inv_btn.offset_bottom = 266
	_root.add_child(_inv_btn)
	_inv_btn.pressed.connect(func():
		if _inv_panel and _inv_panel.has_method("toggle"):
			if _char_panel and _char_panel.has_method("close_panel"):
				_char_panel.close_panel()
			_inv_panel.toggle()
	)

	_char_btn = Button.new()
	_char_btn.name = "CharBtn"
	_char_btn.text = "CHAR"
	_char_btn.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_char_btn.offset_left = 96
	_char_btn.offset_top = 230
	_char_btn.offset_right = 174
	_char_btn.offset_bottom = 266
	_root.add_child(_char_btn)
	_char_btn.pressed.connect(func():
		if _char_panel and _char_panel.has_method("toggle"):
			if _inv_panel and _inv_panel.has_method("close_panel"):
				_inv_panel.close_panel()
			_char_panel.toggle()
	)

	_quest_lbl = Label.new()
	_quest_lbl.name = "QuestLbl"
	_quest_lbl.position = Vector2(12, 270)
	_quest_lbl.size = Vector2(400, 40)
	_quest_lbl.add_theme_font_size_override("font_size", 12)
	_quest_lbl.add_theme_color_override("font_color", Color(0.85, 0.8, 0.55))
	_root.add_child(_quest_lbl)

func bind_player(p: Node) -> void:
	_player = p
	if p and p.get("combat"):
		var c = p.combat
		if c and c.has_signal("resources_changed"):
			c.resources_changed.connect(_refresh_bars)
	_refresh_bars()

func bind_rpg_panels(inv: Node, charp: Node, dlg: Node) -> void:
	_inv_panel = inv
	_char_panel = charp
	_dlg_panel = dlg
	if dlg:
		dlg.add_to_group("dialogue_panel")

func _apply_phone_scale() -> void:
	var sz := get_viewport().get_visible_rect().size
	var shortest := minf(sz.x, sz.y)
	_ui_scale = clampf(shortest / 720.0, 0.85, 1.35)
	if _hint:
		_hint.text = "Ashcrown 0.4.0 · AFK agent · INV/CHAR · hold ATK · Agent watch"

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
	if _stats_lbl:
		var atk_bonus := 0
		var def_bonus := 0
		if _player.has_method("get_equip_bonus"):
			var b: Dictionary = _player.get_equip_bonus()
			atk_bonus = int(b.get("atk", 0))
			def_bonus = int(b.get("def", 0))
		var lvl := 1
		if _player.has_method("get_level"):
			lvl = int(_player.get_level())
		elif _player.get("attr_sheet") != null:
			lvl = int(_player.attr_sheet.get("level", 1))
		_stats_lbl.text = "Lv%s · XP %s · Gold %s · ATK+%s DEF+%s\nHeat gates skills when overheated" % [
			lvl,
			_player.get("xp") if _player.get("xp") != null else 0,
			_player.get("gold") if _player.get("gold") != null else 0,
			atk_bonus, def_bonus
		]
	if _quest_lbl:
		var qm := get_node_or_null("/root/QuestManager")
		if qm and qm.has_method("status_text"):
			_quest_lbl.text = qm.status_text()

func _on_afk_toggled(on: bool) -> void:
	var afk := get_node_or_null("/root/AfkManager")
	if afk == null:
		_show_toast("AFK unavailable")
		_afk_btn.set_pressed_no_signal(false)
		return
	if on:
		var prof := active_profile_name()
		afk.start_afk(prof)
		_afk_btn.text = "Watching"
		_show_toast("Agent watching")
	else:
		var report: Dictionary = afk.stop_afk("player_cancel")
		_afk_btn.text = "Agent"
		_show_afk_report(report)
		_show_toast("You have the watch")

func active_profile_name() -> String:
	var afk := get_node_or_null("/root/AfkManager")
	if afk:
		return str(afk.active_profile)
	return "Balanced"

func _show_afk_report(report: Dictionary) -> void:
	_report.visible = true
	var afk := get_node_or_null("/root/AfkManager")
	if afk and afk.has_method("format_report_text"):
		_report_body.text = afk.format_report_text(report)
	else:
		_report_body.text = "AFK complete — %s · %s\nEngagements closed: %s\nAsh-light gained: %s XP\nLedger: +%s gold\n%s" % [
			report.get("profile", "?"),
			report.get("mode", "?"),
			report.get("kills", 0),
			report.get("xp_gained", 0),
			report.get("gold_gained", 0),
			report.get("stop_reason_text", report.get("stop_reason", "")),
		]
	_afk_btn.set_pressed_no_signal(false)
	_afk_btn.text = "Agent"
	# Enlarge report panel for voice lines
	_report.offset_left = -200
	_report.offset_top = -200
	_report.offset_right = 200
	_report.offset_bottom = 200

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


# --- Remappable mobile controls (0.2.1) ---------------------------------

func _cache_default_layout() -> void:
	_default_stick_offsets = {
		"preset": _stick_base.anchors_preset,
		"left": _stick_base.offset_left,
		"top": _stick_base.offset_top,
		"right": _stick_base.offset_right,
		"bottom": _stick_base.offset_bottom,
		"anchor_left": _stick_base.anchor_left,
		"anchor_top": _stick_base.anchor_top,
		"anchor_right": _stick_base.anchor_right,
		"anchor_bottom": _stick_base.anchor_bottom,
	}
	if _right_cluster:
		_default_cluster_offsets = {
			"left": _right_cluster.offset_left,
			"top": _right_cluster.offset_top,
			"right": _right_cluster.offset_right,
			"bottom": _right_cluster.offset_bottom,
			"anchor_left": _right_cluster.anchor_left,
			"anchor_top": _right_cluster.anchor_top,
			"anchor_right": _right_cluster.anchor_right,
			"anchor_bottom": _right_cluster.anchor_bottom,
		}

func _load_layout_from_save() -> void:
	var sm := get_node_or_null("/root/SaveManager")
	if sm and sm.has_method("get_control_layout"):
		_layout_id = sm.get_control_layout()
		_stick_side = sm.get_control_stick_side()
	_apply_layout(false)

func _ensure_controls_panel() -> void:
	_controls_btn = Button.new()
	_controls_btn.name = "ControlsBtn"
	_controls_btn.text = "Controls"
	_controls_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_controls_btn.offset_left = -270
	_controls_btn.offset_top = 204
	_controls_btn.offset_right = -148
	_controls_btn.offset_bottom = 240
	_root.add_child(_controls_btn)
	_controls_btn.pressed.connect(_toggle_layout_panel)

	_layout_panel = PanelContainer.new()
	_layout_panel.name = "LayoutPanel"
	_layout_panel.visible = false
	_layout_panel.set_anchors_preset(Control.PRESET_CENTER)
	_layout_panel.offset_left = -170
	_layout_panel.offset_top = -140
	_layout_panel.offset_right = 170
	_layout_panel.offset_bottom = 140
	_root.add_child(_layout_panel)
	var v := VBoxContainer.new()
	_layout_panel.add_child(v)
	var title := Label.new()
	title.text = "Mobile Controls"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var info := Label.new()
	info.name = "LayoutInfo"
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.text = _layout_help_text()
	v.add_child(info)
	var swap := Button.new()
	swap.text = "Swap stick side"
	swap.pressed.connect(func():
		_stick_side = "right" if _stick_side == "left" else "left"
		_layout_id = "left_hand" if _stick_side == "right" else "default"
		_apply_layout(true)
		info.text = _layout_help_text()
	)
	v.add_child(swap)
	var left_hand := Button.new()
	left_hand.text = "Left-hand layout"
	left_hand.pressed.connect(func():
		_layout_id = "left_hand"
		_stick_side = "right"
		_apply_layout(true)
		info.text = _layout_help_text()
	)
	v.add_child(left_hand)
	var reset := Button.new()
	reset.text = "Reset defaults"
	reset.pressed.connect(func():
		_layout_id = "default"
		_stick_side = "left"
		_apply_layout(true)
		info.text = _layout_help_text()
	)
	v.add_child(reset)
	# Hide unfinished per-button drag remap (P2+)
	var hidden := Label.new()
	hidden.visible = false
	hidden.text = "Per-button drag remap — coming later"
	v.add_child(hidden)
	var close := Button.new()
	close.text = "Close"
	close.pressed.connect(func(): _layout_panel.visible = false)
	v.add_child(close)

func _layout_help_text() -> String:
	var stick := "LEFT" if _stick_side == "left" else "RIGHT"
	var cluster := "RIGHT" if _stick_side == "left" else "LEFT"
	return "Default: stick LEFT, buttons RIGHT.\nNow: stick %s · buttons %s\nLayout: %s" % [stick, cluster, _layout_id]

func _toggle_layout_panel() -> void:
	_layout_panel.visible = not _layout_panel.visible
	if _layout_panel.visible:
		var info = _layout_panel.find_child("LayoutInfo", true, false)
		if info:
			info.text = _layout_help_text()

func _apply_layout(persist: bool) -> void:
	if _stick_side == "left":
		_place_stick_left()
		_place_cluster_right()
	else:
		_place_stick_right()
		_place_cluster_left()
	if persist:
		var sm := get_node_or_null("/root/SaveManager")
		if sm and sm.has_method("set_control_layout"):
			sm.set_control_layout(_layout_id, _stick_side)
		_show_toast("Controls: stick %s" % _stick_side)

func _place_stick_left() -> void:
	_stick_base.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_stick_base.anchor_left = 0.0
	_stick_base.anchor_right = 0.0
	_stick_base.anchor_top = 1.0
	_stick_base.anchor_bottom = 1.0
	_stick_base.offset_left = 24.0
	_stick_base.offset_top = -200.0
	_stick_base.offset_right = 200.0
	_stick_base.offset_bottom = -24.0
	_stick_base.grow_horizontal = Control.GROW_DIRECTION_END
	_stick_base.grow_vertical = Control.GROW_DIRECTION_BEGIN

func _place_stick_right() -> void:
	_stick_base.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_stick_base.anchor_left = 1.0
	_stick_base.anchor_right = 1.0
	_stick_base.anchor_top = 1.0
	_stick_base.anchor_bottom = 1.0
	_stick_base.offset_left = -200.0
	_stick_base.offset_top = -200.0
	_stick_base.offset_right = -24.0
	_stick_base.offset_bottom = -24.0
	_stick_base.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_stick_base.grow_vertical = Control.GROW_DIRECTION_BEGIN

func _place_cluster_right() -> void:
	if _right_cluster == null:
		return
	_right_cluster.anchor_left = 1.0
	_right_cluster.anchor_right = 1.0
	_right_cluster.anchor_top = 1.0
	_right_cluster.anchor_bottom = 1.0
	_right_cluster.offset_left = -280.0
	_right_cluster.offset_top = -280.0
	_right_cluster.offset_right = -12.0
	_right_cluster.offset_bottom = -12.0
	_right_cluster.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_right_cluster.grow_vertical = Control.GROW_DIRECTION_BEGIN

func _place_cluster_left() -> void:
	if _right_cluster == null:
		return
	_right_cluster.anchor_left = 0.0
	_right_cluster.anchor_right = 0.0
	_right_cluster.anchor_top = 1.0
	_right_cluster.anchor_bottom = 1.0
	_right_cluster.offset_left = 12.0
	_right_cluster.offset_top = -280.0
	_right_cluster.offset_right = 280.0
	_right_cluster.offset_bottom = -12.0
	_right_cluster.grow_horizontal = Control.GROW_DIRECTION_END
	_right_cluster.grow_vertical = Control.GROW_DIRECTION_BEGIN
