extends Node
## Global signal bus — prefer signals over hard node paths between modules.

signal player_spawned(player: Node3D)
signal request_save
signal request_load
signal chunk_loaded(chunk_id: String)
signal chunk_unloaded(chunk_id: String)
signal action_attack
signal action_skill(slot: int)
signal action_dodge
signal action_jump
signal action_interact
signal region_entered(region_id: StringName)
signal quest_flag_set(flag: StringName, value: Variant)
signal afk_started
signal afk_stopped(report: Dictionary)
signal damage_dealt(attacker: Node, target: Node, amount: float)
signal combat_ended
