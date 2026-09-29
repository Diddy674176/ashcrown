extends RefCounted
class_name WorldEvents
## Lite rotating world events — scar alarm, market day, vein storm stub.

const EVENT_DEFS := {
	"scar_alarm": {
		"display": "Scar Alarm",
		"duration_sec": 180.0,
		"spawn_mod": {"heat_sink_scar": 1.6, "crossroads": 1.25, "aetherwood": 1.1},
		"price_mod": 1.05,
		"bark": "Scar alarm sings — Concord levy stirs.",
		"npc_barks": {
			"vos": "Vos: Scar alarm live — denser patrols north.",
			"cald": "Sister Cald: The wound breathes. Listen.",
			"len": "Len: Alarm raised — Gate watches the scar road.",
		},
	},
	"market_day": {
		"display": "Market Day",
		"duration_sec": 240.0,
		"spawn_mod": {"ashfen_gate": 0.7, "aetherwood": 0.9},
		"price_mod": 0.88,  # cheaper buys at Gate
		"bark": "Market Day — Ashfen stalls run warm.",
		"npc_barks": {
			"vendor": "Mara: Market Day rates — don't sleep on it.",
			"sera": "Sera: Ledgers fat today. Vendors smile.",
			"smith": "Brann: Market rush — blades queue faster.",
		},
	},
	"vein_storm": {
		"display": "Vein Storm",
		"duration_sec": 150.0,
		"spawn_mod": {"vein_marsh": 1.8, "aetherwood": 1.3},
		"price_mod": 1.12,
		"bark": "Vein storm — marsh wisps thicken.",
		"npc_barks": {
			"cald": "Sister Cald: Storm on the veins — Binding restless.",
			"sera": "Sera: Fog maps redraw themselves in a storm.",
			"vos": "Vos: Marsh road closed to soft boots.",
		},
	},
}

const ROTATION := ["scar_alarm", "market_day", "idle", "vein_storm", "idle"]
const IDLE_DURATION := 120.0

static func def(event_id: String) -> Dictionary:
	if EVENT_DEFS.has(event_id):
		return EVENT_DEFS[event_id]
	return {}

static func spawn_multiplier(active_id: String, zone_id: String) -> float:
	if active_id == "" or active_id == "idle":
		return 1.0
	var d := def(active_id)
	var mods: Dictionary = d.get("spawn_mod", {})
	return float(mods.get(zone_id, 1.0))

static func price_multiplier(active_id: String) -> float:
	if active_id == "" or active_id == "idle":
		return 1.0
	var d := def(active_id)
	return float(d.get("price_mod", 1.0))

static func bark_for(active_id: String, npc_kind: String) -> String:
	var d := def(active_id)
	var barks: Dictionary = d.get("npc_barks", {})
	return str(barks.get(npc_kind, ""))
