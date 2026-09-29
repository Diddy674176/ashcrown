extends Node
## Minimal AFK - one toggled profile; after N seconds sim, truthful stub return report.

const MVP_PROFILES := ["EXP", "Gold", "Explore", "Balanced"]
const SIM_INTERVAL_SEC := 8.0  # N seconds until first report tick feels playable

var active_profile: String = "Balanced"
var running: bool = false
var last_report: Dictionary = {}
var _started_unix: float = 0.0
var _timer: Timer
var _acc_kills: int = 0
var _acc_xp: int = 0
var _acc_gold: int = 0

func _ready() -> void:
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.wait_time = SIM_INTERVAL_SEC
	_timer.timeout.connect(_on_sim_tick)
	add_child(_timer)

func start_afk(profile: String = "Balanced") -> void:
	active_profile = profile if profile in MVP_PROFILES else "Balanced"
	running = true
	_started_unix = Time.get_unix_time_from_system()
	_acc_kills = 0
	_acc_xp = 0
	_acc_gold = 0
	_timer.start(SIM_INTERVAL_SEC)
	if EventBus:
		EventBus.afk_started.emit()

func stop_afk(reason: String = "player_cancel") -> Dictionary:
	_timer.stop()
	running = false
	var dur := int(Time.get_unix_time_from_system() - _started_unix)
	if _acc_kills == 0 and dur > 0:
		_simulate_for_seconds(dur)
	last_report = {
		"duration_sec": maxi(dur, 0),
		"kills": _acc_kills,
		"xp_gained": _acc_xp,
		"gold_gained": _acc_gold,
		"stop_reason": reason,
		"mode": "foreground",
		"profile": active_profile,
		"caps_hit": [],
	}
	_grant_to_player()
	if EventBus:
		EventBus.afk_stopped.emit(last_report)
	return last_report

func _on_sim_tick() -> void:
	if not running:
		return
	var dur := int(Time.get_unix_time_from_system() - _started_unix)
	_simulate_for_seconds(maxi(dur, int(SIM_INTERVAL_SEC)))
	stop_afk("sim_complete")

func _simulate_for_seconds(sec: int) -> void:
	var kills_pm := 2.0
	var xp_pm := 18.0
	var gold_pm := 8.0
	match active_profile:
		"EXP":
			kills_pm = 3.0
			xp_pm = 32.0
			gold_pm = 4.0
		"Gold":
			kills_pm = 2.0
			xp_pm = 10.0
			gold_pm = 22.0
		"Explore":
			kills_pm = 1.0
			xp_pm = 12.0
			gold_pm = 6.0
		_:
			kills_pm = 2.5
			xp_pm = 20.0
			gold_pm = 10.0
	var t := maxf(sec / 60.0, 0.05)
	_acc_kills = int(round(kills_pm * t))
	_acc_xp = int(round(xp_pm * t))
	_acc_gold = int(round(gold_pm * t))
	if sec >= 5:
		_acc_kills = maxi(_acc_kills, 1)
		_acc_xp = maxi(_acc_xp, 3)
		_acc_gold = maxi(_acc_gold, 2)

func _grant_to_player() -> void:
	var nodes := get_tree().get_nodes_in_group("player")
	if nodes.is_empty():
		return
	var p = nodes[0]
	if "xp" in p:
		p.xp += _acc_xp
	if "gold" in p:
		p.gold += _acc_gold
