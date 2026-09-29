extends Node
## Fast day-night clock for Ashfen Gate NPC schedules (WORLD_FIRST_PLAYABLE §3).
## Full cycle ~120s real time for the slice (day 60s / night 60s).

signal phase_changed(is_night: bool)

const CYCLE_SECONDS := 120.0
const DAY_FRACTION := 0.5  # first half = day

var time_of_day: float = 0.25  # 0..1, start mid-morning
var _was_night: bool = false
var paused: bool = false

func _ready() -> void:
	add_to_group("day_night")
	_was_night = is_night()

func _process(delta: float) -> void:
	if paused:
		return
	time_of_day = fmod(time_of_day + delta / CYCLE_SECONDS, 1.0)
	var night := is_night()
	if night != _was_night:
		_was_night = night
		phase_changed.emit(night)
		if EventBus:
			EventBus.hud_toast.emit("Night falls…" if night else "Dawn breaks…")

func is_night() -> bool:
	return time_of_day >= DAY_FRACTION

func is_day() -> bool:
	return not is_night()

func phase_label() -> String:
	return "Night" if is_night() else "Day"

func set_night(force_night: bool) -> void:
	time_of_day = 0.75 if force_night else 0.25
	var night := is_night()
	if night != _was_night:
		_was_night = night
		phase_changed.emit(night)

func sun_energy() -> float:
	return 0.45 if is_night() else 1.15

func ambient_tint() -> Color:
	if is_night():
		return Color(0.22, 0.24, 0.38)
	return Color(0.42, 0.38, 0.48)
