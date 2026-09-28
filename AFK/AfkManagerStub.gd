extends Node
## Phase 1 AFK manager stub — profiles + offline report schema only.

const MVP_PROFILES := ["EXP", "Gold", "Explore", "Balanced"]

var active_profile: String = "Balanced"
var running: bool = false
var last_report: Dictionary = {}

func start_afk(profile: String = "Balanced") -> void:
	active_profile = profile if profile in MVP_PROFILES else "Balanced"
	running = true
	if EventBus:
		EventBus.afk_started.emit()

func stop_afk(reason: String = "player_cancel") -> Dictionary:
	running = false
	last_report = {
		"duration_sec": 0,
		"kills": 0,
		"xp_gained": 0,
		"gold_gained": 0,
		"stop_reason": reason,
		"mode": "foreground",
		"profile": active_profile,
		"caps_hit": [],
	}
	if EventBus:
		EventBus.afk_stopped.emit(last_report)
	return last_report
