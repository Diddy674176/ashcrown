extends RefCounted
class_name AfkOffline
## Offline progression sim + caps — AFK_AGENT.md §6.
const _Profiles = preload("res://AFK/AfkProfiles.gd")
const _ItemDB = preload("res://Inventory/ItemDB.gd")
const INVENTORY_CAP := 40
const HARD_XP_PER_HOUR := 2400
const HARD_GOLD_PER_HOUR := 900

static func simulate(profile: String, sec: int, rules: Dictionary, acc: Dictionary) -> Dictionary:
	var wall := int(rules.get("offline_hard_wall_sec", 14400))
	sec = mini(sec, wall)
	var caps: Array = acc.get("caps_hit", [])
	if sec >= wall:
		caps.append("offline_hard_wall_4h")
	var t := maxf(sec / 60.0, 0.05)
	var mult := _Profiles.offline_mult(profile)
	var kills := 0
	var xp := 0
	var gold := 0
	var items: Array = []
	var retreats := 0
	var discoveries: Array = acc.get("discoveries", []).duplicate()
	var fog := 0
	if profile == "Boss":
		xp = maxi(int(5 * t * 0.2), 0)
		gold = maxi(int(3 * t * 0.2), 0)
		caps.append("boss_stub_no_coil_farm")
	else:
		var kills_pm := 2.4 * float(mult.get("risk", 0.5)) / 0.5
		var xp_pm := 28.0 * float(mult.get("xp", 0.7))
		var gold_pm := 14.0 * float(mult.get("gold", 0.7))
		if profile == "Gathering":
			kills_pm = 0.8
			xp_pm = 10.0 * float(mult.get("xp", 0.3))
			gold_pm = 8.0
		kills = int(round(kills_pm * t))
		xp = int(round(xp_pm * t))
		gold = int(round(gold_pm * t))
		if sec >= 60:
			kills = maxi(kills, 1)
			xp = maxi(xp, 8)
			gold = maxi(gold, 4)
		fog = int(round(3.0 * float(mult.get("fog", 0.3)) * t))
		if fog > 0 and "Emberveil Wilds" not in discoveries:
			discoveries.append("Emberveil Wilds")
		if sec >= 30:
			items.append({"id": "vein_mite_carapace", "name": "Vein-mite Carapace", "qty": maxi(1, int(t * 1.5)), "rarity": "common"})
		if profile in ["Gathering", "Explore", "Balanced"] and sec >= 60:
			items.append({"id": "ember_fiber", "name": "Ember Fiber", "qty": maxi(1, int(t * 0.8)), "rarity": "uncommon"})
		if sec >= 120:
			items.append({"id": "wake_ore", "name": "Wake Ore", "qty": 1, "rarity": "uncommon"})
		if float(mult.get("risk", 0.5)) > 0.45 and t >= 1.0:
			retreats = maxi(1, int(t * 0.15))
	# hard caps
	var hours := maxf(sec / 3600.0, 1.0 / 60.0)
	var xp_cap := int(HARD_XP_PER_HOUR * hours)
	var gold_cap := int(HARD_GOLD_PER_HOUR * hours)
	if xp > xp_cap:
		xp = xp_cap
		caps.append("hard_xp_per_hour")
	if gold > gold_cap:
		gold = gold_cap
		caps.append("hard_gold_per_hour")
	var soft := int(rules.get("soft_diminish_sec", 7200))
	if sec > soft:
		caps.append("soft_diminishing_120m")
		xp = int(xp * 0.7)
		gold = int(gold * 0.7)
	return {
		"kills": kills, "xp": xp, "gold": gold, "items": items,
		"retreats": retreats, "discoveries": discoveries, "caps_hit": caps, "fog_cells": fog,
	}
