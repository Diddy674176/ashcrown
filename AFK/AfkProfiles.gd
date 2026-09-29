extends RefCounted
class_name AfkProfiles
## AFK profile stubs — AFK_AGENT.md. MVP locked for §82.

const MVP := ["EXP", "Gold", "Explore", "Balanced"]

const DEFERRED := [
	"Gathering", "Boss", "Dungeon", "Quest", "Craft",
	"Reputation", "Gear", "Companion", "Kingdom", "Custom",
]

const DEFAULT_RULES := {
	"max_level_gap": 3,
	"retreat_hp_pct": 35,
	"potion_hp_pct": 50,
	"inventory_stop_pct": 90,
	"never_auto_premium": true,
}

static func all_names() -> Array:
	return MVP + DEFERRED
