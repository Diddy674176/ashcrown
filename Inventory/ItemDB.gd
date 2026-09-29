extends RefCounted
class_name ItemDB
## Equipable / consumable stubs for First Playable.

const ITEMS := {
	"vein_mite_carapace": {
		"name": "Vein-mite Carapace",
		"slot": "",
		"stats": {},
		"sell": 4,
		"desc": "Trash material",
	},
	"ember_fiber": {
		"name": "Ember Fiber",
		"slot": "",
		"stats": {},
		"sell": 3,
		"desc": "Wilds gather stub",
	},
	"wake_ore": {
		"name": "Wake Ore",
		"slot": "",
		"stats": {},
		"sell": 5,
		"desc": "Smith reagent",
	},
	"ashblade_shard": {
		"name": "Ashblade Shard",
		"slot": "weapon",
		"stats": {"atk": 6, "mig": 1},
		"sell": 20,
		"desc": "Worn blade edge — equip to raise ATK",
	},
	"vein_leather_vest": {
		"name": "Vein Leather Vest",
		"slot": "armor",
		"stats": {"def": 4, "vit": 1, "max_hp": 15},
		"sell": 18,
		"desc": "Light armor — equip to raise DEF/HP",
	},
	"ember_charm": {
		"name": "Ember Charm",
		"slot": "charm",
		"stats": {"foc": 2, "focus_regen": 1},
		"sell": 15,
		"desc": "Focus trinket",
	},
	"ash_etched_circlet_fragment": {
		"name": "Ash-etched Circlet Fragment",
		"slot": "charm",
		"stats": {"atk": 4, "def": 2, "foc": 2, "max_hp": 20},
		"sell": 80,
		"desc": "Coil Warden unique loot",
	},
	"brutefang_plate": {
		"name": "Brutefang Plate",
		"slot": "armor",
		"stats": {"def": 8, "mig": 1, "max_hp": 25},
		"sell": 28,
		"desc": "Heavy scrap from Vein Brute",
	},
	"spitter_bowstring": {
		"name": "Spitter Bowstring",
		"slot": "weapon",
		"stats": {"atk": 8, "swt": 1},
		"sell": 22,
		"desc": "Ranged-tuned weapon stub",
	},
	"health_draught": {
		"name": "Health Draught",
		"slot": "consumable",
		"stats": {"heal": 40},
		"sell": 8,
		"desc": "Alchemy craft — heal on use",
	},
	"iron_nail_blade": {
		"name": "Iron Nail Blade",
		"slot": "weapon",
		"stats": {"atk": 10, "mig": 2},
		"sell": 35,
		"desc": "Smith craft weapon",
	},
}

static func get_item(id: String) -> Dictionary:
	if ITEMS.has(id):
		var d: Dictionary = ITEMS[id].duplicate(true)
		d["id"] = id
		return d
	return {"id": id, "name": id, "slot": "", "stats": {}, "sell": 1, "desc": "Unknown"}

static func display_name(id: String) -> String:
	return str(get_item(id).get("name", id))
