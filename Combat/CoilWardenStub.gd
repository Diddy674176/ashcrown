extends RefCounted
class_name CoilWardenStub
## Coil Warden phase hooks — COMBAT.md / BOSS_COIL_WARDEN.md. No combat logic yet.

const BOSS_ID := "coil_warden"
const BOSS_NAME := "The Coil Warden"
const DUNGEON := "Coilcrypt"
const REGION := "Emberveil Reach"
const UNIQUE_DROP := "Ash-etched Circlet Fragment"

## Phase id → stub sheet (HP band, fantasy, signature tells).
const PHASES := {
	"coil_sentinel": {
		"index": 1,
		"hp_band": [0.60, 1.00],
		"fantasy": "Still on duty, testing",
		"patterns": ["Sweep Arc", "Glyph Slam", "Conduit Spit"],
		"lesson": "Dodge vs Block vocabulary",
	},
	"bleed_surge": {
		"index": 2,
		"hp_band": [0.30, 0.60],
		"fantasy": "Coil cracks; vents open",
		"patterns": ["Aether Vent", "Coil Overload"],
		"lesson": "Space control; Focus/heat pressure",
	},
	"crown_echo": {
		"index": 3,
		"hp_band": [0.0, 0.30],
		"fantasy": "Ash-light on helm/circlet scar",
		"patterns": ["Faster sentinel", "Enrage", "Poise windows"],
		"lesson": "Commit skills on poise break",
	},
}

static func phase_order() -> Array:
	return ["coil_sentinel", "bleed_surge", "crown_echo"]
