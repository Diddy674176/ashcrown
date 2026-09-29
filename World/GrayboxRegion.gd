extends "res://World/GrayboxRegionCore.gd"
class_name GrayboxRegion
## Phase 5 overlay — biomes, economy, world events (Emberveil only).
const _Biome = preload("res://World/BiomeZones.gd")

func _ready() -> void:
	super._ready()
	_build_biome_pads()
	_spawn_phase5_enemies()
	var ws := get_node_or_null("/root/WorldSim")
	if ws and ws.has_signal("event_changed"):
		if not ws.event_changed.is_connected(_on_world_event):
			ws.event_changed.connect(_on_world_event)

func _spawn_phase5_enemies() -> void:
	add_child(_Enemy.make_caster(Vector3(-18, 0.5, 2)))
	add_child(_Enemy.make_caster(Vector3(-22, 0.5, -4)))
	add_child(_Enemy.make_skirmisher(Vector3(-14, 0.5, 6)))
	add_child(_Enemy.make_bruiser(Vector3(4, 0.5, -18)))
	add_child(_Enemy.make_caster(Vector3(-4, 0.5, -20)))
	add_child(_Enemy.make_skirmisher(Vector3(6, 0.5, -16)))
	var bandit = _Enemy.make_skirmisher(Vector3(-2, 0.5, 2))
	bandit.display_name = "Concord Deserter"
	bandit.loot_id = "vein_mite_carapace"
	add_child(bandit)

func _do_vendor(player: Node) -> void:
	var ws := get_node_or_null("/root/WorldSim")
	var sell_unit := 4
	var buy_cost := 8
	if ws and ws.has_method("sell_price"):
		sell_unit = ws.sell_price(4, "gray_concord")
		buy_cost = ws.buy_price(8, "gray_concord")
	var sold := 0
	var gained := 0
	if "inventory" in player:
		var keep: Array = []
		for it in player.inventory:
			if str(it) == "vein_mite_carapace":
				player.gold += sell_unit
				gained += sell_unit
				sold += 1
			else:
				keep.append(it)
		player.inventory = keep
	if sold > 0:
		if ws:
			ws.vendor_stock = minf(ws.vendor_stock + float(sold) * 2.0, 100.0)
		if EventBus:
			EventBus.hud_toast.emit("Mara bought %d carapace (+%dg, charter rates)" % [sold, gained])
	elif "gold" in player and player.gold >= buy_cost:
		player.gold -= buy_cost
		if player.has_method("add_item"):
			player.add_item("health_draught")
		else:
			player.inventory.append("health_draught")
		if ws:
			ws.vendor_stock = maxf(ws.vendor_stock - 5.0, 10.0)
		if EventBus:
			EventBus.hud_toast.emit("Bought Health Draught (−%dg)" % buy_cost)
	elif EventBus:
		EventBus.hud_toast.emit("Mara: Sell carapace or buy draught (%dg)" % buy_cost)

func _build_biome_pads() -> void:
	_biome_pad("AetherwoodPad", Vector3(22, -0.35, 0), Vector3(28, 0.3, 28), Color(0.22, 0.38, 0.26), "Aetherwood")
	_biome_pad("VeinMarshPad", Vector3(-20, -0.35, 2), Vector3(22, 0.3, 24), Color(0.18, 0.32, 0.38), "Vein Marsh — shock flora")
	_biome_pad("HeatSinkScarPad", Vector3(0, -0.35, -22), Vector3(26, 0.3, 22), Color(0.48, 0.28, 0.18), "Heat-sink Scar")
	_biome_pad("AshfenPad", Vector3(0, -0.35, 22), Vector3(20, 0.3, 16), Color(0.42, 0.38, 0.32), "Ashfen Gate")
	for i in range(3):
		var hx := -16.0 - float(i) * 3.0
		_add_cyl(0.35, 1.2, Vector3(hx, 0.6, -2 + i), self, Color(0.3, 0.7, 0.85))
	for i in range(4):
		_add_box(Vector3(0.5, 2.2, 0.5), Vector3(-6 + i * 4.0, 1.1, -26), self, Color(0.7, 0.35, 0.15))

func _biome_pad(node_name: String, pos: Vector3, size: Vector3, col: Color, label: String) -> void:
	var pad := _add_box(size, pos, self, col)
	pad.name = node_name
	_label(label, pos + Vector3(0, 2.5, 0), self)

func _on_world_event(event_id: String) -> void:
	if EventBus and event_id != "idle":
		EventBus.hud_toast.emit("World event: %s" % event_id)
