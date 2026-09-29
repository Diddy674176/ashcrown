extends RefCounted
class_name FactionReputation
## Gray Concord vs Choirbound (+ Wakewright lean) — prices/dialogue shift with rep.

const FACTIONS := ["gray_concord", "choirbound", "wakewrights"]
const DISPLAY := {
	"gray_concord": "Gray Concord",
	"choirbound": "Choirbound",
	"wakewrights": "Wakewrights",
}

## Base sell/buy multipliers before events. Higher Concord → Gate vendors friendlier.
static func default_state() -> Dictionary:
	return {
		"gray_concord": 0,
		"choirbound": 0,
		"wakewrights": 0,
		"rivalry_pressure": 0.0,  # 0..100 abstract L2
	}

static func clamp_rep(v: int) -> int:
	return clampi(v, -100, 100)

static func apply_delta(state: Dictionary, faction: String, delta: int) -> Dictionary:
	var s := state.duplicate(true)
	if not FACTIONS.has(faction):
		return s
	s[faction] = clamp_rep(int(s.get(faction, 0)) + delta)
	# Rivalry: Concord up cools Choirbound slightly and vice versa
	if faction == "gray_concord" and delta > 0:
		s["choirbound"] = clamp_rep(int(s.get("choirbound", 0)) - int(delta / 3))
	elif faction == "choirbound" and delta > 0:
		s["gray_concord"] = clamp_rep(int(s.get("gray_concord", 0)) - int(delta / 3))
	return s

static func sync_from_quest(state: Dictionary, consequence: String) -> Dictionary:
	var s := state.duplicate(true)
	if consequence == "helped_concord":
		s = apply_delta(s, "gray_concord", 25)
		s = apply_delta(s, "wakewrights", 5)
	elif consequence == "ignored_scar":
		s = apply_delta(s, "gray_concord", -20)
		s = apply_delta(s, "choirbound", 10)
	return s

## Buy price mult (player pays). Low = cheaper for player.
static func buy_mult(state: Dictionary, vendor_faction: String) -> float:
	var rep := int(state.get(vendor_faction, 0))
	# Friendly: up to 20% off; hostile: up to 25% markup
	return clampf(1.0 - float(rep) * 0.002, 0.75, 1.25)

## Sell price mult (player receives). High = better payout.
static func sell_mult(state: Dictionary, vendor_faction: String) -> float:
	var rep := int(state.get(vendor_faction, 0))
	return clampf(1.0 + float(rep) * 0.0025, 0.7, 1.35)

static func dialogue_lean(state: Dictionary) -> String:
	var c := int(state.get("gray_concord", 0))
	var ch := int(state.get("choirbound", 0))
	if c >= 20 and c > ch:
		return "concord"
	if ch >= 15 and ch > c:
		return "choir"
	if int(state.get("wakewrights", 0)) >= 15:
		return "wake"
	return "neutral"

static func bark_suffix(state: Dictionary, npc_kind: String) -> String:
	var lean := dialogue_lean(state)
	match npc_kind:
		"cald":
			if lean == "choir":
				return "The Root knows your listening."
			if lean == "concord":
				return "Concord favor does not seal wounds."
			if int(state.get("gray_concord", 0)) < -10:
				return "Silence on the scar still hangs."
			return ""
		"len":
			if lean == "concord":
				return "Concord ledger favors you."
			if lean == "choir":
				return "Choir whispers reach the Hall."
			return ""
		"smith":
			if lean == "wake" or int(state.get("wakewrights", 0)) >= 10:
				return "Wakewright rates — ore cuts deeper."
			if lean == "choir":
				return "Choirbound lean — forge tariffs up."
			return ""
		"vendor":
			if lean == "concord":
				return "Gate charter discount."
			if int(state.get("gray_concord", 0)) < -15:
				return "Prices cold — Gate remembers."
			return ""
		_:
			return ""
