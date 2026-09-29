extends Node
class_name CombatAPI
## Shared combat hooks for Manual / Assisted / AFK (COMBAT.md).

func light_attack(attacker: Node, target: Node) -> void:
	_deal(attacker, target, 12.0)

func heavy_attack(attacker: Node, target: Node) -> void:
	_deal(attacker, target, 22.0)

func charged_attack(attacker: Node, target: Node) -> void:
	_deal(attacker, target, 36.0)

func dodge(_body: Node, _dir: Vector3) -> void:
	pass

func should_heal(hp_pct: float, potion_hp: float) -> bool:
	return hp_pct <= potion_hp

func should_dodge(telegraph_kind: String) -> bool:
	return telegraph_kind in ["dodge", "unblockable", "aoe"]

func pick_target(threats: Array, _profile: String) -> Node:
	var best: Node = null
	for t in threats:
		if t == null or not is_instance_valid(t):
			continue
		best = t
		break
	return best

func _deal(attacker: Node, target: Node, amount: float) -> void:
	if target == null or not is_instance_valid(target):
		return
	if target.has_method("receive_hit"):
		target.receive_hit(amount, attacker)
