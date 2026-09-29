extends Node
const _DialogueDB = preload("res://NPC/DialogueDB.gd")
## Magistrate Len authored chain (3+ beats) + choice consequence flag (Phase 3).

const QUEST_ID := "len_scar_alarm"
const STEPS := [
	"talk_len",        # 0 accept
	"scout_wilds",     # 1 kill 3 wilds OR gather ember_fiber
	"report_choice",   # 2 turn-in with branched choice
	"aftermath",       # 3 optional Cald follow-up beat
	"done",            # 4 complete
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
			return "Quest: report to Len — choose Concord help or ignore"
		3:
			if consequence_flag == "helped_concord":
				return "Quest: optional — speak to Sister Cald (aftermath)"
			return "Quest: scar alarm ignored — Gate favor lost"
		_:
			if consequence_flag == "helped_concord":
				return "Quest complete — Concord favor gained"
			elif consequence_flag == "ignored_scar":
				return "Quest closed — scar alarm ignored"
			return "Quest complete"

func can_talk_len() -> bool:
	return stage == 0 or stage == 2 or stage >= 3

func dialogue_tree_for_len() -> String:
	return _DialogueDB.len_tree_for_stage(stage, consequence_flag)

## Legacy toast path kept for compatibility — prefer dialogue effects.
func interact_len() -> String:
	if stage == 0:
		accept_quest()
		return "accepted"
	if stage == 1:
		if EventBus:
			EventBus.hud_toast.emit("Len: Still waiting on that Wilds report.")
		return "waiting"
	if stage == 2:
		# Without dialogue UI, default to helped (dialogue should drive choice)
		apply_consequence("helped_concord")
		return "turned_in"
	if stage >= 3:
		if EventBus:
			EventBus.hud_toast.emit("Len: The Concord remembers — or doesn't.")
		return "done"
	return ""

func accept_quest() -> void:
	if stage != 0:
		return
	stage = 1
	kills_toward = 0
	set_flag("len_accepted", true)
	if EventBus:
		EventBus.hud_toast.emit("Len: Scout the Wilds. Kill 3 hostiles — or bring Ember Fiber.")

func apply_consequence(kind: String) -> void:
	if stage < 2:
		return
	if kind == "helped_concord":
		consequence_flag = "helped_concord"
		set_flag("helped_concord", true)
		set_flag("quest_len_done", true)
		stage = 3
		if EventBus:
			EventBus.hud_toast.emit("Len: Concord favor noted. Rook at the Inn will join you.")
			EventBus.quest_flag_set.emit(&"helped_concord", true)
		# Reward rare Concord Mail via player if available
		_reward_player("concord_mail")
		var ws := get_node_or_null("/root/WorldSim")
		if ws and ws.has_method("on_quest_consequence"):
			ws.on_quest_consequence("helped_concord")
	elif kind == "ignored_scar":
		consequence_flag = "ignored_scar"
		set_flag("ignored_scar_alarm", true)
		set_flag("quest_len_done", true)
		stage = 4
		if EventBus:
			EventBus.hud_toast.emit("Len: Scar alarm ignored. No Concord favor.")
			EventBus.quest_flag_set.emit(&"ignored_scar", true)
		var ws2 := get_node_or_null("/root/WorldSim")
		if ws2 and ws2.has_method("on_quest_consequence"):
			ws2.on_quest_consequence("ignored_scar")

func complete_aftermath() -> void:
	if stage == 3:
		stage = 4
		set_flag("cald_aftermath", true)
		if EventBus:
			EventBus.hud_toast.emit("Quest chain complete — Cald notes your path.")

func _reward_player(item_id: String) -> void:
	var nodes := get_tree().get_nodes_in_group("player")
	if nodes.is_empty():
		return
	var p = nodes[0]
	if p.has_method("add_item"):
		p.add_item(item_id)
	elif "inventory" in p:
		p.inventory.append(item_id)

func try_ignore_consequence() -> void:
	# Alternate path if player never finishes — set when entering Coilcrypt without quest
	if stage > 0 and stage < 3 and consequence_flag == "":
		consequence_flag = "ignored_scar"
		set_flag("ignored_scar_alarm", true)
		var ws3 := get_node_or_null("/root/WorldSim")
		if ws3 and ws3.has_method("on_quest_consequence"):
			ws3.on_quest_consequence("ignored_scar")

func _on_enemy_killed(enemy: Node, _drops: Dictionary) -> void:
	if stage != 1:
		return
	if enemy == null:
		return
	if enemy.is_in_group("boss"):
		return
	kills_toward += 1
	if EventBus:
		EventBus.hud_toast.emit("Wilds progress %d/3" % kills_toward)
	if kills_toward >= 3:
		stage = 2
		if EventBus:
			EventBus.hud_toast.emit("Report to Magistrate Len — a choice awaits")

func notify_item_gained(item_id: String) -> void:
	if stage == 1 and item_id == "ember_fiber":
		stage = 2
		if EventBus:
			EventBus.hud_toast.emit("Ember Fiber secured — report to Len (choose carefully)")

func recruit_unlocked() -> bool:
	return stage >= 3 and consequence_flag == "helped_concord"

func handle_dialogue_effect(effect: String) -> void:
	match effect:
		"accept_quest":
			accept_quest()
		"consequence_helped":
			apply_consequence("helped_concord")
		"consequence_ignored":
			apply_consequence("ignored_scar")
		"flag_cald_hint":
			set_flag("cald_hint", true)
			if stage == 3:
				complete_aftermath()
		"flag_sera_afk":
			set_flag("sera_afk_explained", true)
		"flag_met_cald":
			set_flag("met_cald", true)
			if stage == 3:
				complete_aftermath()
		"give_root_charm":
			set_flag("met_cald", true)
			_reward_player("singing_root_charm")
			if stage == 3:
				complete_aftermath()
		_:
			pass
