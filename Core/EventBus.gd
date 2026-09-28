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
