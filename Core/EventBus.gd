extends Node
## Global signal bus - prefer signals over hard node paths between modules.

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
signal attack_hold_started
signal attack_hold_ended
signal region_entered(region_id: StringName)
signal quest_flag_set(flag: StringName, value: Variant)
signal afk_started
signal afk_stopped(report: Dictionary)
signal damage_dealt(attacker: Node, target: Node, amount: float)
signal combat_ended
signal enemy_killed(enemy: Node, drops: Dictionary)
signal boss_phase_changed(phase_id: String, banner: String)
signal boss_defeated(drop: Dictionary)
signal loot_gained(drops: Dictionary)
signal player_interact(player: Node)
signal enter_dungeon_requested(dungeon_id: String)
signal exit_dungeon_requested
signal hud_toast(text: String)
signal player_leveled(level: int)
signal inventory_changed
signal attributes_changed
signal skills_changed
signal dialogue_opened(tree_id: String)
signal dialogue_closed(tree_id: String)
