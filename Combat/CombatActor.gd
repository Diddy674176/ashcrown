extends Node
class_name CombatActor
## Shared HP / stamina / focus / heat for player and enemies (COMBAT.md).

signal died
signal damaged(amount: float, source: Node)
signal healed(amount: float)
signal resources_changed

@export var max_hp: float = 100.0
@export var max_stamina: float = 100.0
@export var max_focus: float = 100.0
@export var max_heat: float = 100.0
@export var team: StringName = &"neutral"  # player | enemy

var hp: float
var stamina: float
var focus: float
var heat: float = 0.0
var alive: bool = true

var invincible_until: float = 0.0
var overheat_until: float = 0.0

const STAMINA_REGEN := 22.0
const FOCUS_REGEN := 8.0
const HEAT_COOL := 12.0
const OVERHEAT_THRESHOLD := 95.0
const OVERHEAT_DURATION := 2.5

func _ready() -> void:
	hp = max_hp
	stamina = max_stamina
	focus = max_focus
	heat = 0.0
	alive = true

func _process(delta: float) -> void:
	if not alive:
		return
	stamina = minf(stamina + STAMINA_REGEN * delta, max_stamina)
	focus = minf(focus + FOCUS_REGEN * delta, max_focus)
	heat = maxf(heat - HEAT_COOL * delta, 0.0)
	resources_changed.emit()

func hp_pct() -> float:
	return 0.0 if max_hp <= 0.0 else hp / max_hp

func is_invincible() -> bool:
	return Time.get_ticks_msec() * 0.001 < invincible_until

func is_overheated() -> bool:
	return Time.get_ticks_msec() * 0.001 < overheat_until

func grant_iframe(seconds: float) -> void:
	invincible_until = maxf(invincible_until, Time.get_ticks_msec() * 0.001 + seconds)

func try_spend_stamina(cost: float) -> bool:
	if stamina < cost:
		return false
	stamina -= cost
	resources_changed.emit()
	return true

func try_spend_focus(cost: float) -> bool:
	if is_overheated() or focus < cost:
		return false
	focus -= cost
	resources_changed.emit()
	return true

func add_heat(amount: float) -> void:
	heat = minf(heat + amount, max_heat)
	if heat >= OVERHEAT_THRESHOLD:
		overheat_until = Time.get_ticks_msec() * 0.001 + OVERHEAT_DURATION
		heat = max_heat * 0.6
	resources_changed.emit()

func take_damage(amount: float, source: Node = null) -> float:
	if not alive or is_invincible() or amount <= 0.0:
		return 0.0
	var dealt := amount
	hp = maxf(hp - dealt, 0.0)
	damaged.emit(dealt, source)
	resources_changed.emit()
	if EventBus:
		EventBus.damage_dealt.emit(source, get_parent(), dealt)
	if hp <= 0.0:
		alive = false
		died.emit()
	return dealt

func heal(amount: float) -> void:
	if not alive:
		return
	hp = minf(hp + amount, max_hp)
	healed.emit(amount)
	resources_changed.emit()

func snapshot() -> Dictionary:
	return {
		"hp": hp,
		"max_hp": max_hp,
		"stamina": stamina,
		"focus": focus,
		"heat": heat,
	}

func apply_snapshot(data: Dictionary) -> void:
	max_hp = float(data.get("max_hp", max_hp))
	hp = float(data.get("hp", max_hp))
	stamina = float(data.get("stamina", max_stamina))
	focus = float(data.get("focus", max_focus))
	heat = float(data.get("heat", 0.0))
	alive = hp > 0.0
	resources_changed.emit()
