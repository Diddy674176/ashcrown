extends CanvasLayer
class_name InventoryPanel
const _ItemDB = preload("res://Inventory/ItemDB.gd")
## Inventory UI — list, equip/unequip, compare stats before confirm.

signal closed

var _player: Node = null
var _list: ItemList
var _detail: Label
var _compare: Label
var _equip_btn: Button
var _unequip_btn: Button
var _close_btn: Button
var _slots_lbl: Label
var _selected_id: String = ""
var _entries: Array = []  # parallel to list indices: item ids (unique rows by stack)

func _ready() -> void:
	layer = 35
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
	panel.offset_left = -320
	panel.offset_top = -220
	panel.offset_right = 320
	panel.offset_bottom = 240
	root.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	panel.add_child(vb)
	var title := Label.new()
	title.text = "Inventory — Equip"
	title.add_theme_font_size_override("font_size", 18)
	vb.add_child(title)
	_slots_lbl = Label.new()
	_slots_lbl.add_theme_font_size_override("font_size", 13)
	vb.add_child(_slots_lbl)
	_list = ItemList.new()
	_list.custom_minimum_size = Vector2(600, 160)
	_list.item_selected.connect(_on_select)
	vb.add_child(_list)
	_detail = Label.new()
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.custom_minimum_size = Vector2(600, 40)
	vb.add_child(_detail)
	_compare = Label.new()
	_compare.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_compare.custom_minimum_size = Vector2(600, 50)
	_compare.add_theme_color_override("font_color", Color(0.75, 0.9, 0.7))
	vb.add_child(_compare)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	vb.add_child(hb)
	_equip_btn = Button.new()
	_equip_btn.text = "Equip"
	_equip_btn.custom_minimum_size = Vector2(120, 40)
	_equip_btn.pressed.connect(_on_equip)
	hb.add_child(_equip_btn)
	_unequip_btn = Button.new()
	_unequip_btn.text = "Unequip"
	_unequip_btn.custom_minimum_size = Vector2(120, 40)
	_unequip_btn.pressed.connect(_on_unequip)
	hb.add_child(_unequip_btn)
	_close_btn = Button.new()
	_close_btn.text = "Close"
	_close_btn.custom_minimum_size = Vector2(120, 40)
	_close_btn.pressed.connect(close_panel)
	hb.add_child(_close_btn)

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
	_list.clear()
	_entries.clear()
	_selected_id = ""
	_detail.text = ""
	_compare.text = ""
	if _player == null:
		return
	_refresh_slots()
	# Stack inventory for display
	var counts: Dictionary = {}
	var order: Array = []
	for it in _player.inventory:
		var id := str(it)
		if not counts.has(id):
			counts[id] = 0
			order.append(id)
		counts[id] = int(counts[id]) + 1
	for id in order:
		var line := _ItemDB.format_item_line(id)
		var qty: int = int(counts[id])
		var equipped_mark := ""
		if _player.get("equipment") != null:
			for slot in _player.equipment.keys():
				if str(_player.equipment[slot]) == id:
					equipped_mark = " ★EQ"
					break
		_list.add_item("%s ×%d%s" % [line, qty, equipped_mark])
		_entries.append(id)

func _refresh_slots() -> void:
	if _player == null or _player.get("equipment") == null:
		_slots_lbl.text = ""
		return
	var eq: Dictionary = _player.equipment
	var w := str(eq.get("weapon", ""))
	var a := str(eq.get("armor", ""))
	var c := str(eq.get("charm", ""))
	_slots_lbl.text = "Weapon: %s | Armor: %s | Charm: %s" % [
		_ItemDB.display_name(w) if w != "" else "—",
		_ItemDB.display_name(a) if a != "" else "—",
		_ItemDB.display_name(c) if c != "" else "—",
	]

func _on_select(idx: int) -> void:
	if idx < 0 or idx >= _entries.size():
		return
	_selected_id = str(_entries[idx])
	var d := _ItemDB.get_item(_selected_id)
	_detail.text = "%s — %s\n%s" % [d.get("name", _selected_id), str(d.get("tier", "")).capitalize(), d.get("desc", "")]
	var slot := str(d.get("slot", ""))
	_equip_btn.disabled = slot not in ["weapon", "armor", "charm"]
	_unequip_btn.disabled = true
	if _player and _player.get("equipment") != null and slot in _player.equipment:
		var cur := str(_player.equipment.get(slot, ""))
		_unequip_btn.disabled = cur != _selected_id
		if slot in ["weapon", "armor", "charm"]:
			var cmp: Dictionary = _ItemDB.compare(_selected_id, cur if cur != _selected_id else "")
			if cur == "" or cur == _selected_id:
				_compare.text = "Compare: equip to apply stats. Power score %d." % _ItemDB.power_score(_selected_id)
			else:
				var sign := "+" if int(cmp.get("score_delta", 0)) >= 0 else ""
				_compare.text = "Compare vs %s (%s→%s) power %s%d\n%s" % [
					cmp.get("old_name", cur),
					cmp.get("old_tier", ""),
					cmp.get("new_tier", ""),
					sign,
					int(cmp.get("score_delta", 0)),
					" · ".join(cmp.get("lines", [])),
				]

func _on_equip() -> void:
	if _player == null or _selected_id == "":
		return
	if _player.has_method("equip_item"):
		_player.equip_item(_selected_id)
	refresh()

func _on_unequip() -> void:
	if _player == null or _selected_id == "":
		return
	var d := _ItemDB.get_item(_selected_id)
	var slot := str(d.get("slot", ""))
	if _player.has_method("unequip_slot"):
		_player.unequip_slot(slot)
	refresh()
