extends RefCounted
class_name Attributes
## Slice attribute keys - CLASSLESS_STARTER.md (MIG/SWT/FOC/VIT/BND).

const KEYS := ["MIG", "SWT", "FOC", "VIT", "BND"]
const DISPLAY := {
	"MIG": "Might",
	"SWT": "Swift",
	"FOC": "Focus",
	"VIT": "Vitality",
	"BND": "Binding",
}

## Level-1 base (Binding slightly lower).
const BASE := {"MIG": 8, "SWT": 8, "FOC": 8, "VIT": 8, "BND": 6}
const POINTS_PER_LEVEL := 2

## XP thresholds to reach next level (index = current level). Level 1→2 needs 100.
const XP_TO_NEXT := {
	1: 100, 2: 180, 3: 280, 4: 400, 5: 550, 6: 720, 7: 900, 8: 1100, 9: 1400, 10: 1800,
}

static func make_base() -> Dictionary:
	return BASE.duplicate()

static func make_sheet() -> Dictionary:
	return {
		"values": make_base(),
		"unspent": 0,
		"level": 1,
		"xp": 0,
		"total_spent": 0,
		"free_respec_available": true,
	}

static func xp_needed_for(level: int) -> int:
	return int(XP_TO_NEXT.get(level, 2000 + level * 200))

static func try_level_up(sheet: Dictionary) -> bool:
	var leveled := false
	while true:
		var lvl: int = int(sheet.get("level", 1))
		var need: int = xp_needed_for(lvl)
		var xp: int = int(sheet.get("xp", 0))
		if xp < need or lvl >= 20:
			break
		sheet["xp"] = xp - need
		sheet["level"] = lvl + 1
		sheet["unspent"] = int(sheet.get("unspent", 0)) + POINTS_PER_LEVEL
		leveled = true
	return leveled

static func spend(sheet: Dictionary, key: String) -> bool:
	if key not in KEYS:
		return false
	if int(sheet.get("unspent", 0)) <= 0:
		return false
	var vals: Dictionary = sheet.get("values", make_base())
	vals[key] = int(vals.get(key, BASE.get(key, 8))) + 1
	sheet["values"] = vals
	sheet["unspent"] = int(sheet["unspent"]) - 1
	sheet["total_spent"] = int(sheet.get("total_spent", 0)) + 1
	return true

static func respec(sheet: Dictionary) -> bool:
	if not bool(sheet.get("free_respec_available", false)):
		return false
	var spent: int = int(sheet.get("total_spent", 0))
	sheet["values"] = make_base()
	sheet["unspent"] = int(sheet.get("unspent", 0)) + spent
	sheet["total_spent"] = 0
	sheet["free_respec_available"] = false
	return true

static func get_val(sheet: Dictionary, key: String) -> int:
	var vals: Dictionary = sheet.get("values", BASE)
	return int(vals.get(key, BASE.get(key, 8)))

## Combat scaling derived from attributes (Phase 3 slice).
static func atk_from_attrs(sheet: Dictionary) -> float:
	return float(get_val(sheet, "MIG") - 8) * 1.5 + float(get_val(sheet, "SWT") - 8) * 0.5

static func skill_power_from_attrs(sheet: Dictionary) -> float:
	return float(get_val(sheet, "FOC") - 8) * 1.8

static func hp_from_attrs(sheet: Dictionary) -> float:
	return float(get_val(sheet, "VIT") - 8) * 8.0

static func focus_from_attrs(sheet: Dictionary) -> float:
	return float(get_val(sheet, "FOC") - 8) * 4.0

static func companion_bonus(sheet: Dictionary) -> float:
	return float(get_val(sheet, "BND") - 6) * 1.2

static func summary_line(sheet: Dictionary) -> String:
	var v: Dictionary = sheet.get("values", BASE)
	return "Lv%d  MIG%d SWT%d FOC%d VIT%d BND%d  (+%d pts)" % [
		int(sheet.get("level", 1)),
		int(v.get("MIG", 8)), int(v.get("SWT", 8)), int(v.get("FOC", 8)),
		int(v.get("VIT", 8)), int(v.get("BND", 6)),
		int(sheet.get("unspent", 0)),
	]
