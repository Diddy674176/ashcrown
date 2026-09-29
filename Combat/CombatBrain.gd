extends RefCounted
class_name CombatBrain
## Shared decision hooks for Manual / Assisted / Full Auto / AFK (COMBAT.md §2).
## Modes share this brain; only who drives move/aim changes.

enum Mode { MANUAL, ASSISTED, FULL_AUTO }

const SOFT_LOCK_RANGE := 14.0
const ATTACK_RANGE := 2.6
const RETREAT_HP := 0.35
const POTION_HP := 0.50
const HEAL_AMOUNT := 35.0

static func pick_target(origin: Vector3, tree: SceneTree, current: Node3D = null) -> Node3D:
	if tree == null:
		return null
	var best: Node3D = null
	var best_score := -INF
	for n in tree.get_nodes_in_group("enemy"):
		if n == null or not is_instance_valid(n):
			continue
		if n.get("_dead") == true:
			continue
		var e := n as Node3D
		if e == null:
			continue
		var d: float = origin.distance_to(e.global_position)
		if d > SOFT_LOCK_RANGE:
			continue
		# Utility: closer + boss bias + stickiness
		var score := (SOFT_LOCK_RANGE - d) * 2.0
		if e.is_in_group("boss"):
			score += 8.0
		if current != null and e == current:
			score += 4.0
		if score > best_score:
			best_score = score
			best = e
	return best

static func should_dodge(origin: Vector3, tree: SceneTree) -> bool:
	if tree == null:
		return false
	for n in tree.get_nodes_in_group("telegraph"):
		if n == null or not is_instance_valid(n):
			continue
		var kind = n.get("kind")
		var radius: float = float(n.get("radius") if n.get("radius") != null else 2.5)
		var dur: float = float(n.get("duration") if n.get("duration") != null else 0.6)
		var age: float = float(n.get("_age") if n.get("_age") != null else 0.0)
		# Dodge amber + unblockable red when near and tell is committing
		var needs_dodge := false
		if kind != null:
			# TelegraphDecal.Kind: DODGE_AMBER=0, UNBLOCKABLE_RED=2, AOE_AMBER=3
			var k := int(kind)
			needs_dodge = (k == 0 or k == 2 or k == 3)
		if not needs_dodge:
			continue
		var pos: Vector3 = (n as Node3D).global_position
		if origin.distance_to(pos) <= radius + 0.8 and age >= dur * 0.35:
			return true
	return false

static func should_block(origin: Vector3, tree: SceneTree) -> bool:
	if tree == null:
		return false
	for n in tree.get_nodes_in_group("telegraph"):
		if n == null or not is_instance_valid(n):
			continue
		var kind = n.get("kind")
		if kind == null or int(kind) != 1:  # BLOCK_BLUE
			continue
		var radius: float = float(n.get("radius") if n.get("radius") != null else 2.5)
		var pos: Vector3 = (n as Node3D).global_position
		if origin.distance_to(pos) <= radius + 0.6:
			return true
	return false

static func should_heal(hp_pct: float, potions: int = 99) -> bool:
	return potions > 0 and hp_pct <= POTION_HP and hp_pct > 0.0

static func should_retreat(hp_pct: float) -> bool:
	return hp_pct > 0.0 and hp_pct <= RETREAT_HP

static func pick_skill(focus: float, heat: float, overheated: bool, skill1_cd: float, skill2_cd: float) -> int:
	# Never infinite ultimate; skills gated by focus + heat + CD
	if overheated:
		return 0
	if heat >= 85.0:
		return 0
	if skill1_cd <= 0.0 and focus >= 20.0:
		return 1
	if skill2_cd <= 0.0 and focus >= 20.0:
		return 2
	return 0

static func want_light_attack(dist: float, attack_lock: float) -> bool:
	return attack_lock <= 0.0 and dist <= ATTACK_RANGE

static func mode_name(m: Mode) -> String:
	match m:
		Mode.ASSISTED:
			return "Assisted"
		Mode.FULL_AUTO:
			return "Full Auto"
		_:
			return "Manual"
