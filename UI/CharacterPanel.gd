extends CanvasLayer
class_name CharacterPanel
const _Attributes = preload("res://Character/Attributes.gd")
const _SkillNodes = preload("res://Character/SkillNodes.gd")
## Attributes spend + skill node unlock/equip UI.

signal closed

var _player: Node = null
var _attr_lbl: Label
var _pts_lbl: Label
var _skill_lbl: Label
var _pending_box: VBoxContainer
var _equip_box: VBoxContainer
var _attr_btns: Dictionary = {}

func _ready() -> void:
	layer = 36
	_build()
	visible = false

func _build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.5)
	root.add_child(dim)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -300
	panel.offset_top = -240
	panel.offset_right = 300
	panel.offset_bottom = 260
	root.add_child(panel)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(580, 480)
	panel.add_child(scroll)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	scroll.add_child(vb)
	var title := Label.new()
	title.text = "Character — Attributes & Skills"
	title.add_theme_font_size_override("font_size", 18)
	vb.add_child(title)
	_attr_lbl = Label.new()
	_attr_lbl.add_theme_font_size_override("font_size", 14)
	vb.add_child(_attr_lbl)
	_pts_lbl = Label.new()
	vb.add_child(_pts_lbl)
	var attr_row := HBoxContainer.new()
	attr_row.add_theme_constant_override("separation", 4)
	vb.add_child(attr_row)
	for k in _Attributes.KEYS:
		var b := Button.new()
		b.text = "+%s" % k
		b.custom_minimum_size = Vector2(64, 36)
		b.pressed.connect(_on_spend.bind(k))
		attr_row.add_child(b)
		_attr_btns[k] = b
	var respec := Button.new()
	respec.text = "Free Respec (town)"
	respec.pressed.connect(_on_respec)
	vb.add_child(respec)
	var sk_title := Label.new()
	sk_title.text = "Skill nodes (max 3 + ult) — heat respected in combat"
	sk_title.add_theme_font_size_override("font_size", 15)
	vb.add_child(sk_title)
	_skill_lbl = Label.new()
	_skill_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(_skill_lbl)
	var pend_title := Label.new()
	pend_title.text = "Pending unlock choice:"
	vb.add_child(pend_title)
	_pending_box = VBoxContainer.new()
	vb.add_child(_pending_box)
	var eq_title := Label.new()
	eq_title.text = "Unlocked — tap to equip/unequip:"
	vb.add_child(eq_title)
	_equip_box = VBoxContainer.new()
	vb.add_child(_equip_box)
	var close := Button.new()
	close.text = "Close"
	close.custom_minimum_size = Vector2(120, 40)
	close.pressed.connect(close_panel)
	vb.add_child(close)

func bind_player(p: Node) -> void:
	_player = p

func toggle() -> void:
	if visible:
		close_panel()
	else:
		open_panel()

func open_panel() -> void:
	visible = true
	refresh()

func close_panel() -> void:
	visible = false
	closed.emit()

func refresh() -> void:
	if _player == null:
		return
	var sheet: Dictionary = _player.get("attr_sheet") if _player.get("attr_sheet") != null else _Attributes.make_sheet()
	_attr_lbl.text = _Attributes.summary_line(sheet)
	_pts_lbl.text = "Unspent points: %d  |  XP %d / %d to next" % [
		int(sheet.get("unspent", 0)),
		int(sheet.get("xp", 0)),
		_Attributes.xp_needed_for(int(sheet.get("level", 1))),
	]
	var can_spend: bool = int(sheet.get("unspent", 0)) > 0
	for k in _attr_btns.keys():
		_attr_btns[k].disabled = not can_spend

	var skills: Dictionary = _player.get("skill_state") if _player.get("skill_state") != null else _SkillNodes.make_state()
	var eq: Array = skills.get("equipped", [])
	var ult := str(skills.get("ultimate", ""))
	_skill_lbl.text = "Equipped: %s\nUltimate: %s" % [
		", ".join(eq) if eq.size() > 0 else "(none)",
		ult if ult != "" else "(none)",
	]
	for c in _pending_box.get_children():
		c.queue_free()
	var pend_lv: int = int(skills.get("pending_choice_level", 0))
	if pend_lv > 0:
		var opts: Array = skills.get("pending_options", [])
		var hint := Label.new()
		hint.text = "Level %d — pick one:" % pend_lv
		_pending_box.add_child(hint)
		for oid in opts:
			var defn: Dictionary = _SkillNodes.get_node(str(oid))
			var b := Button.new()
			b.text = "%s — %s" % [defn.get("name", oid), defn.get("desc", "")]
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.pressed.connect(_on_choose_skill.bind(str(oid)))
			_pending_box.add_child(b)
	else:
		var none := Label.new()
		none.text = "(no pending — unlocks at Lv 2/4/6/8)"
		_pending_box.add_child(none)

	for c in _equip_box.get_children():
		c.queue_free()
	for uid in skills.get("unlocked", []):
		var defn: Dictionary = _SkillNodes.get_node(str(uid))
		var is_eq := str(uid) in eq or str(uid) == ult
		var b := Button.new()
		b.text = "%s%s [%s heat %s]" % [
			defn.get("name", uid),
			" ★" if is_eq else "",
			defn.get("school", "?"),
			str(defn.get("heat", 0)),
		]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.pressed.connect(_on_toggle_skill.bind(str(uid), is_eq))
		_equip_box.add_child(b)

func _on_spend(key: String) -> void:
	if _player and _player.has_method("spend_attribute"):
		_player.spend_attribute(key)
	refresh()

func _on_respec() -> void:
	if _player and _player.has_method("respec_attributes"):
		_player.respec_attributes()
	refresh()

func _on_choose_skill(node_id: String) -> void:
	if _player and _player.has_method("choose_skill_node"):
		_player.choose_skill_node(node_id)
	refresh()

func _on_toggle_skill(node_id: String, is_equipped: bool) -> void:
	if _player == null:
		return
	if is_equipped and _player.has_method("unequip_skill"):
		_player.unequip_skill(node_id)
	elif _player.has_method("equip_skill"):
		_player.equip_skill(node_id)
	refresh()
