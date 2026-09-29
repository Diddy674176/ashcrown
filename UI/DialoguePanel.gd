extends CanvasLayer
class_name DialoguePanel
const _DialogueDB = preload("res://NPC/DialogueDB.gd")
## Simple branched dialogue overlay — mobile-friendly buttons.

signal dialogue_finished(tree_id: String, last_effect: String)
signal effect_requested(effect: String)

var _panel: PanelContainer
var _title: Label
var _body: Label
var _opt_box: VBoxContainer
var _tree_id: String = ""
var _tree: Dictionary = {}
var _node_id: String = ""
var _last_effect: String = ""

func _ready() -> void:
	layer = 40
	add_to_group("dialogue_panel")
	_build()
	visible = false

func _build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.45)
	root.add_child(dim)
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.offset_left = -280
	_panel.offset_top = -160
	_panel.offset_right = 280
	_panel.offset_bottom = 200
	root.add_child(_panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	_panel.add_child(vb)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 18)
	vb.add_child(_title)
	_body = Label.new()
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.custom_minimum_size = Vector2(520, 80)
	_body.add_theme_font_size_override("font_size", 15)
	vb.add_child(_body)
	_opt_box = VBoxContainer.new()
	_opt_box.add_theme_constant_override("separation", 6)
	vb.add_child(_opt_box)

func is_open() -> bool:
	return visible

func open_tree(tree_id: String) -> void:
	var t: Dictionary = _DialogueDB.tree(tree_id)
	if t.is_empty():
		return
	_tree_id = tree_id
	_tree = t
	_last_effect = ""
	_title.text = str(t.get("title", tree_id))
	visible = true
	_show_node(str(t.get("start", "")))

func close_dialogue() -> void:
	visible = false
	dialogue_finished.emit(_tree_id, _last_effect)

func _show_node(node_id: String) -> void:
	_node_id = node_id
	var nodes: Dictionary = _tree.get("nodes", {})
	if not nodes.has(node_id):
		close_dialogue()
		return
	var node: Dictionary = nodes[node_id]
	_body.text = str(node.get("text", ""))
	for c in _opt_box.get_children():
		c.queue_free()
	var opts: Array = node.get("options", [])
	for opt in opts:
		var btn := Button.new()
		btn.text = str(opt.get("label", "…"))
		btn.custom_minimum_size = Vector2(0, 40)
		var next_id := str(opt.get("next", ""))
		var effect := str(opt.get("effect", ""))
		btn.pressed.connect(_on_option.bind(next_id, effect))
		_opt_box.add_child(btn)

func _on_option(next_id: String, effect: String) -> void:
	if effect != "":
		_last_effect = effect
		effect_requested.emit(effect)
	if next_id == "" or effect in [
		"accept_quest", "consequence_helped", "consequence_ignored",
		"end", "flag_cald_hint", "flag_sera_afk", "flag_met_cald", "give_root_charm",
	]:
		# Terminal-ish: if next empty, close after effect
		if next_id == "":
			close_dialogue()
			return
	_show_node(next_id)
