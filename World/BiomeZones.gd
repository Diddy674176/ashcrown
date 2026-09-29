extends RefCounted
class_name BiomeZones
## Emberveil Reach only — Aetherwood / Vein Marsh / Heat-sink Scar / Ashfen Gate.

enum Zone { ASHFEN_GATE, AETHERWOOD, VEIN_MARSH, HEAT_SINK_SCAR, WAKE_PIT, CROSSROADS }

const ZONE_IDS := {
	Zone.ASHFEN_GATE: "ashfen_gate",
	Zone.AETHERWOOD: "aetherwood",
	Zone.VEIN_MARSH: "vein_marsh",
	Zone.HEAT_SINK_SCAR: "heat_sink_scar",
	Zone.WAKE_PIT: "wake_pit",
	Zone.CROSSROADS: "crossroads",
}

const DISPLAY := {
	"ashfen_gate": "Ashfen Gate",
	"aetherwood": "Aetherwood",
	"vein_marsh": "Vein Marsh",
	"heat_sink_scar": "Heat-sink Scar",
	"wake_pit": "Starter Wake-Pit",
	"crossroads": "Concord Crossroads",
}

## Ground / hazard / spawn flavor per zone (materials are Color for graybox).
static func zone_info(zone_id: String) -> Dictionary:
	match zone_id:
		"ashfen_gate":
			return {
				"ground": Color(0.42, 0.38, 0.32),
				"hazard": "none",
				"move_mult": 1.0,
				"spawn_bias": {"skirmisher": 0.2, "bruiser": 0.0, "caster": 0.0, "bandit": 0.15},
				"gather": [],
			}
		"aetherwood":
			return {
				"ground": Color(0.22, 0.38, 0.26),
				"hazard": "none",
				"move_mult": 1.0,
				"spawn_bias": {"skirmisher": 0.7, "bruiser": 0.35, "caster": 0.15, "bandit": 0.05},
				"gather": ["ember_fiber", "wake_ore"],
			}
		"vein_marsh":
			return {
				"ground": Color(0.18, 0.32, 0.38),
				"hazard": "shock_flora",  # slower move
				"move_mult": 0.82,
				"spawn_bias": {"skirmisher": 0.35, "bruiser": 0.1, "caster": 0.75, "bandit": 0.0},
				"gather": ["ember_fiber"],
			}
		"heat_sink_scar":
			return {
				"ground": Color(0.48, 0.28, 0.18),
				"hazard": "heat_ribs",
				"move_mult": 0.92,
				"spawn_bias": {"skirmisher": 0.4, "bruiser": 0.55, "caster": 0.45, "bandit": 0.2},
				"gather": ["wake_ore"],
			}
		"wake_pit":
			return {
				"ground": Color(0.35, 0.28, 0.22),
				"hazard": "none",
				"move_mult": 1.0,
				"spawn_bias": {"skirmisher": 0.0, "bruiser": 0.0, "caster": 0.0, "bandit": 0.0},
				"gather": [],
			}
		_:
			return {
				"ground": Color(0.32, 0.34, 0.3),
				"hazard": "none",
				"move_mult": 1.0,
				"spawn_bias": {"skirmisher": 0.3, "bruiser": 0.2, "caster": 0.2, "bandit": 0.25},
				"gather": [],
			}

## Authored AABB-ish centers for Emberveil graybox layout.
static func detect(pos: Vector3) -> String:
	# Town south
	if pos.z > 14.0 and absf(pos.x) < 12.0:
		return "ashfen_gate"
	# Wake-pit far south
	if pos.z > 28.0:
		return "wake_pit"
	# Scar north toward Coilcrypt
	if pos.z < -12.0:
		return "heat_sink_scar"
	# Marsh west wet flats
	if pos.x < -8.0:
		return "vein_marsh"
	# Aetherwood east (Singing Root / Ember Camp)
	if pos.x > 8.0:
		return "aetherwood"
	return "crossroads"

static func label(zone_id: String) -> String:
	return str(DISPLAY.get(zone_id, zone_id))
