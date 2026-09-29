extends RefCounted
class_name ItemDB
## Equipable / consumable catalog — tiers Common→Rare (+ Epic boss) for Phase 3.

const TIER_ORDER := {"common": 0, "uncommon": 1, "rare": 2, "epic": 3, "legendary": 4}

const ITEMS := {
	"vein_mite_carapace": {
		"name": "Vein-mite Carapace",
		"slot": "",
		"tier": "common",
		"stats": {},
		"sell": 4,
		"desc": "Trash material",
	},
	"ember_fiber": {
		"name": "Ember Fiber",
		"slot": "",
		"tier": "uncommon",
		"stats": {},
		"sell": 3,
		"desc": "Wilds gather stub",
	},
	"wake_ore": {
		"name": "Wake Ore",
		"slot": "",
		"tier": "uncommon",
		"stats": {},
		"sell": 5,
		"desc": "Smith reagent",
	},
	"ashblade_shard": {
		"name": "Ashblade Shard",
		"slot": "weapon",
		"tier": "common",
		"stats": {"atk": 6, "mig": 1},
		"sell": 20,
		"desc": "Worn blade edge — equip to raise ATK",
	},
	"vein_leather_vest": {
		"name": "Vein Leather Vest",
		"slot": "armor",
		"tier": "common",
		"stats": {"def": 4, "vit": 1, "max_hp": 15},
		"sell": 18,
		"desc": "Light armor — equip to raise DEF/HP",
	},
	"ember_charm": {
		"name": "Ember Charm",
		"slot": "charm",
		"tier": "uncommon",
		"stats": {"foc": 2, "focus_regen": 1},
		"sell": 15,
		"desc": "Focus trinket",
	},
	"ash_etched_circlet_fragment": {
		"name": "Ash-etched Circlet Fragment",
		"slot": "charm",
		"tier": "epic",
		"stats": {"atk": 4, "def": 2, "foc": 2, "max_hp": 20},
		"sell": 80,
		"desc": "Coil Warden unique loot",
	},
	"brutefang_plate": {
		"name": "Brutefang Plate",
		"slot": "armor",
		"tier": "uncommon",
		"stats": {"def": 8, "mig": 1, "max_hp": 25},
		"sell": 28,
		"desc": "Heavy scrap from Vein Brute",
	},
	"spitter_bowstring": {
		"name": "Spitter Bowstring",
		"slot": "weapon",
		"tier": "uncommon",
		"stats": {"atk": 8, "swt": 1},
		"sell": 22,
		"desc": "Ranged-tuned weapon stub",
	},
	"health_draught": {
		"name": "Health Draught",
		"slot": "consumable",
		"tier": "common",
		"stats": {"heal": 40},
		"sell": 8,
		"desc": "Alchemy craft — heal on use",
	},
	"iron_nail_blade": {
		"name": "Iron Nail Blade",
		"slot": "weapon",
		"tier": "uncommon",
		"stats": {"atk": 10, "mig": 2},
		"sell": 35,
		"desc": "Smith craft weapon",
	},
	"scar_wake_saber": {
		"name": "Scar-Wake Saber",
		"slot": "weapon",
		"tier": "rare",
		"stats": {"atk": 16, "mig": 2, "foc": 1},
		"sell": 60,
		"desc": "Rare Wake-etched saber — clear ATK jump",
	},
	"concord_mail": {
		"name": "Concord Mail",
		"slot": "armor",
		"tier": "rare",
		"stats": {"def": 14, "vit": 2, "max_hp": 40},
		"sell": 55,
		"desc": "Rare Concord issue mail — clear DEF/HP jump",
	},
	"singing_root_charm": {
		"name": "Singing Root Charm",
		"slot": "charm",
		"tier": "rare",
		"stats": {"foc": 3, "bnd": 2, "atk": 2},
		"sell": 50,
		"desc": "Rare Binding trinket from Choir path",
	},
	"starter_blade": {
		"name": "Starter Blade",
		"slot": "weapon",
		"tier": "common",
		"stats": {"atk": 4},
		"sell": 5,
		"desc": "Kit default edge",
	},
	"starter_vest": {
		"name": "Starter Vest",
		"slot": "armor",
		"tier": "common",
		"stats": {"def": 2, "max_hp": 8},
		"sell": 5,
		"desc": "Kit default armor",
	},
}

static func get_item(id: String) -> Dictionary:
	if ITEMS.has(id):
		var d: Dictionary = ITEMS[id].duplicate(true)
		d["id"] = id
		return d
	return {"id": id, "name": id, "slot": "", "tier": "common", "stats": {}, "sell": 1, "desc": "Unknown"}

static func display_name(id: String) -> String:
	return str(get_item(id).get("name", id))

static func tier_of(id: String) -> String:
	return str(get_item(id).get("tier", "common"))

static func power_score(id: String) -> int:
	var st: Dictionary = get_item(id).get("stats", {})
	return int(st.get("atk", 0)) + int(st.get("def", 0)) + int(st.get("max_hp", 0)) / 5 \
		+ int(st.get("mig", 0)) + int(st.get("swt", 0)) + int(st.get("foc", 0)) \
		+ int(st.get("vit", 0)) + int(st.get("bnd", 0))

static func compare(new_id: String, old_id: String) -> Dictionary:
	## Returns delta stats and readable lines for equip UI.
	var n: Dictionary = get_item(new_id).get("stats", {})
	var o: Dictionary = {} if old_id == "" else get_item(old_id).get("stats", {})
	var keys := ["atk", "def", "max_hp", "mig", "swt", "foc", "vit", "bnd", "focus_regen"]
	var delta := {}
	var lines: PackedStringArray = []
	for k in keys:
		var dv: int = int(n.get(k, 0)) - int(o.get(k, 0))
		if dv != 0 or int(n.get(k, 0)) != 0 or int(o.get(k, 0)) != 0:
			delta[k] = dv
			var sign := "+" if dv > 0 else ""
			lines.append("%s: %s%d" % [k.to_upper(), sign, dv])
	var score_d := power_score(new_id) - (0 if old_id == "" else power_score(old_id))
	return {
		"delta": delta,
		"lines": lines,
		"score_delta": score_d,
		"new_tier": tier_of(new_id),
		"old_tier": "" if old_id == "" else tier_of(old_id),
		"new_name": display_name(new_id),
		"old_name": "" if old_id == "" else display_name(old_id),
	}

static func format_item_line(id: String) -> String:
	var d := get_item(id)
	var slot := str(d.get("slot", ""))
	var tier := str(d.get("tier", "common")).capitalize()
	if slot in ["weapon", "armor", "charm"]:
		var st: Dictionary = d.get("stats", {})
		return "[%s] %s (%s) ATK%d DEF%d" % [tier, d.get("name", id), slot, int(st.get("atk", 0)), int(st.get("def", 0))]
	return "[%s] %s" % [tier, d.get("name", id)]
