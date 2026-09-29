extends RefCounted
class_name ItemDB
## Stub item table for First Playable loot/vendor.

const ITEMS := {
	"vein_mite_carapace": {"name": "Vein-mite Carapace", "rarity": "common", "sell": 4},
	"ash_etched_circlet_fragment": {"name": "Ash-etched Circlet Fragment", "rarity": "unique", "sell": 0},
	"ember_fiber": {"name": "Ember Fiber", "rarity": "uncommon", "sell": 8},
	"wake_ore": {"name": "Wake Ore", "rarity": "uncommon", "sell": 10},
}

static func display_name(id: String) -> String:
	var e = ITEMS.get(id, {})
	return str(e.get("name", id))
