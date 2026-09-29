extends Node
## Magistrate Len small authored chain (2–3 steps) + consequence flag.

const QUEST_ID := "len_scar_alarm"
const STEPS := [
	"talk_len",       # 0 accept
	"scout_wilds",    # 1 kill 3 wilds enemies OR gather ember_fiber
	"report_len",     # 2 turn-in
	"done",           # 3 complete
]

var stage: int = 0
var kills_toward: int = 0
var consequence_flag: String = ""  # helped_concord | ignored_scar
var flags: Dictionary = {}

func _ready() -> void:
	if EventBus:
		EventBus.enemy_killed.connect(_on_enemy_killed)

func reset() -> void:
	stage = 0
	kills_toward = 0
	consequence_flag = ""
	flags.clear()

func snapshot() -> Dictionary:
	return {
		"stage": stage,
		"kills_toward": kills_toward,
		"consequence_flag": consequence_flag,
		"flags": flags.duplicate(true),
	}

func apply_snapshot(data: Dictionary) -> void:
	stage = int(data.get("stage", 0))
	kills_toward = int(data.get("kills_toward", 0))
	consequence_flag = str(data.get("consequence_flag", ""))
	flags = data.get("flags", {}).duplicate(true)

func set_flag(key: String, value: Variant = true) -> void:
	flags[key] = value
	if EventBus:
		EventBus.quest_flag_set.emit(StringName(key), value)

func get_flag(key: String, default: Variant = false) -> Variant:
	return flags.get(key, default)

func status_text() -> String:
	match stage:
		0:
			return "Quest: speak to Magistrate Len (Concord Hall)"
		1:
			return "Quest: clear Wilds threats (%d/3) or gather Ember Fiber" % kills_toward
		2:
			return "Quest: report back to Magistrate Len"
		_:
			if consequence_flag == "helped_concord":
				return "Quest complete — Concord favor gained"
			elif consequence_flag == "ignored_scar":
				return "Quest closed — scar alarm ignored"
			return "Quest complete"

func can_talk_len() -> bool:
	return stage == 0 or stage == 2

func interact_len() -> String:
	if stage == 0:
		stage = 1
		kills_toward = 0
		if EventBus:
			EventBus.hud_toast.emit("Len: Scout the Wilds. Kill 3 hostiles — or bring Ember Fiber.")
		return "accepted"
	if stage == 1:
		# Player can ignore and still talk — soft nudge
		if EventBus:
			EventBus.hud_toast.emit("Len: Still waiting on that Wilds report.")
		return "waiting"
	if stage == 2:
		stage = 3
		consequence_flag = "helped_concord"
		set_flag("helped_concord", true)
		set_flag("quest_len_done", true)
		if EventBus:
			EventBus.hud_toast.emit("Len: Concord favor noted. Rook at the Inn will join you.")
			EventBus.quest_flag_set.emit(&"helped_concord", true)
		return "turned_in"
	if stage >= 3:
		if EventBus:
			EventBus.hud_toast.emit("Len: The Concord remembers your work.")
		return "done"
	return ""

func try_ignore_consequence() -> void:
	# Alternate path if player never finishes — set when entering Coilcrypt without quest
	if stage > 0 and stage < 3 and consequence_flag == "":
		consequence_flag = "ignored_scar"
		set_flag("ignored_scar_alarm", true)

func _on_enemy_killed(enemy: Node, _drops: Dictionary) -> void:
	if stage != 1:
		return
	if enemy == null:
		return
	# Count wilds enemies (not boss)
	if enemy.is_in_group("boss"):
		return
	if enemy.is_in_group("wilds_enemy") or true:
		# Count any non-boss kill during stage 1
		kills_toward += 1
		if EventBus:
			EventBus.hud_toast.emit("Wilds progress %d/3" % kills_toward)
		if kills_toward >= 3:
			stage = 2
			if EventBus:
				EventBus.hud_toast.emit("Report to Magistrate Len")

func notify_item_gained(item_id: String) -> void:
	if stage == 1 and item_id == "ember_fiber":
		stage = 2
		if EventBus:
			EventBus.hud_toast.emit("Ember Fiber secured — report to Len")

func recruit_unlocked() -> bool:
	return stage >= 3 and consequence_flag == "helped_concord"
