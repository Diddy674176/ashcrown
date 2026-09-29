extends "res://AFK/AfkManagerCore.gd"
## Phase 5 overlay — world-sim offline advance + GDScript type fixes.

func _nav_toward(player: Node, target: Vector3) -> void:
	if not player.has_method("set_touch_move"):
		return
	var to: Vector3 = target - (player as Node3D).global_position
	to.y = 0.0
	if to.length() < 1.2:
		player.set_touch_move(Vector2.ZERO)
		return
	var yaw := float(player.get("_yaw") if player.get("_yaw") != null else 0.0)
	var local: Vector3 = to.rotated(Vector3.UP, -yaw)
	var stick := Vector2(local.x, -local.z).normalized()
	player.set_touch_move(stick)

func _do_heal(player: Node) -> void:
	if player == null or player.get("combat") == null:
		return
	var hp: float = float(player.combat.hp_pct())
	var potion_at := float(rules.get("potion_hp_pct", 50.0)) / 100.0
	if hp <= potion_at and int(player.potions) > 0:
		player.potions = maxi(player.potions - 1, 0)
		player.combat.heal(40.0)
		if player.has_method("consume_item"):
			player.consume_item("health_draught", 1)
	var retreat_at := float(rules.get("retreat_hp_pct", 35.0)) / 100.0
	if hp <= retreat_at:
		_acc_retreats += 1
		_nav_toward(player, EMBER_CAMP_POS)

func _simulate_offline_seconds(sec: int) -> void:
	super._simulate_offline_seconds(sec)
	var ws := get_node_or_null("/root/WorldSim")
	if ws and ws.has_method("advance_offline"):
		var summary: Dictionary = ws.advance_offline(float(sec))
		if summary.has("toast"):
			_acc_discoveries = _acc_discoveries.duplicate()
			var line := "World: %s" % summary.get("toast", "")
			if line not in _acc_discoveries:
				_acc_discoveries.append(line)

func format_report_text(report: Dictionary = {}) -> String:
	if report.is_empty():
		report = last_report
	if report.is_empty():
		return "No return yet — set a profile and rest the watch."
	var base := super.format_report_text(report)
	var ws2 := get_node_or_null("/root/WorldSim")
	if ws2 == null:
		return base
	var lrs: Dictionary = ws2.get("last_return_summary") if ws2.get("last_return_summary") != null else {}
	if typeof(lrs) != TYPE_DICTIONARY:
		return base
	var extra: PackedStringArray = []
	for ln in lrs.get("lines", []):
		extra.append(str(ln))
	if extra.is_empty():
		return base
	var needle := "Ledger: +%s gold" % report.get("gold_gained", 0)
	if needle in base:
		return base.replace(needle, needle + "\n" + "\n".join(extra))
	return base + "\n" + "\n".join(extra)
