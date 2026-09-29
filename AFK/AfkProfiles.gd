extends RefCounted
class_name AfkProfiles
## AFK profiles + hard rules — AFK_AGENT.md Phase 4.

const MVP := ["EXP", "Gold", "Explore", "Balanced"]
## Selectable stubs (goal weights exist; full loops deferred).
const STUBS := ["Gathering", "Boss"]

const DEFERRED := [
	"Dungeon", "Quest", "Craft",
	"Reputation", "Gear", "Companion", "Kingdom", "Custom",
]

const DEFAULT_RULES := {
	"max_level_gap": 3,
	"retreat_hp_pct": 35.0,
	"potion_hp_pct": 50.0,
	"inventory_stop_pct": 90.0,
	"never_auto_premium": true,
	"session_time_cap_sec": 1800,  # 30 min foreground soft stop
	"offline_hard_wall_sec": 14400,  # 4h
	"soft_diminish_sec": 7200,  # 120 min
}

## Utility weights per profile (xp, gold, explore, gather, danger_avoid).
const PROFILE_WEIGHTS := {
	"EXP": {"xp": 1.0, "gold": 0.35, "explore": 0.2, "gather": 0.1, "danger_avoid": 0.7},
	"Gold": {"xp": 0.4, "gold": 1.0, "explore": 0.15, "gather": 0.25, "danger_avoid": 0.65},
	"Explore": {"xp": 0.35, "gold": 0.3, "explore": 1.0, "gather": 0.4, "danger_avoid": 0.8},
	"Balanced": {"xp": 0.7, "gold": 0.7, "explore": 0.45, "gather": 0.35, "danger_avoid": 0.7},
	"Gathering": {"xp": 0.25, "gold": 0.3, "explore": 0.4, "gather": 1.0, "danger_avoid": 0.85},
	"Boss": {"xp": 0.5, "gold": 0.4, "explore": 0.1, "gather": 0.0, "danger_avoid": 0.3},
}

## Offline yield multipliers (AFK_AGENT.md §6).
const OFFLINE_MULT := {
	"EXP": {"xp": 1.0, "gold": 0.5, "fog": 0.2, "risk": 0.55},
	"Gold": {"xp": 0.55, "gold": 1.0, "fog": 0.15, "risk": 0.55},
	"Explore": {"xp": 0.4, "gold": 0.35, "fog": 1.0, "risk": 0.4},
	"Balanced": {"xp": 0.7, "gold": 0.7, "fog": 0.45, "risk": 0.5},
	"Gathering": {"xp": 0.3, "gold": 0.4, "fog": 0.5, "risk": 0.35},
	"Boss": {"xp": 0.2, "gold": 0.2, "fog": 0.0, "risk": 0.9},  # stub — almost no yield; afk_blocked for Coil
}

static func selectable() -> Array:
	return MVP + STUBS

static func all_names() -> Array:
	return MVP + STUBS + DEFERRED

static func weights(profile: String) -> Dictionary:
	if PROFILE_WEIGHTS.has(profile):
		return PROFILE_WEIGHTS[profile].duplicate()
	return PROFILE_WEIGHTS["Balanced"].duplicate()

static func offline_mult(profile: String) -> Dictionary:
	if OFFLINE_MULT.has(profile):
		return OFFLINE_MULT[profile].duplicate()
	return OFFLINE_MULT["Balanced"].duplicate()

static func rules() -> Dictionary:
	return DEFAULT_RULES.duplicate()
