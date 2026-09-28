extends Node
## Phase 1 combat stub — verbs wired later. Shared hooks for Manual / Assisted / AFK.

func light_attack(_attacker: Node, _target: Node) -> void:
	pass

func heavy_attack(_attacker: Node, _target: Node) -> void:
	pass

func dodge(_body: Node, _dir: Vector3) -> void:
	pass

func should_heal(hp_pct: float, potion_hp: float) -> bool:
	return hp_pct <= potion_hp
