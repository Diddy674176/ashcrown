extends RefCounted
class_name StarterKits
## Creation picks a kit, not a class — CLASSLESS_STARTER.md.

const KITS := {
	"Ashblade": {
		"weapons": ["one_hand_blade", "focus_charm"],
		"skills": ["light_slash", "dash_strike"],
		"armor": "medium",
		"fantasy": "Frontline melee",
	},
	"Veilbow": {
		"weapons": ["wake_etched_bow", "knife"],
		"skills": ["piercing_shot", "nature_dot_seed"],
		"armor": "light",
		"fantasy": "Kite / ranged",
	},
	"Corebinder": {
		"weapons": ["staff", "wake_pistol_stub"],
		"skills": ["binding_bolt", "minor_ward"],
		"armor": "light_med",
		"fantasy": "Caster + pet prep",
	},
}

const STARTER_CONSUMABLES := {"potion": 5, "focus_tonic": 3}

static func kit_ids() -> Array:
	return KITS.keys()
