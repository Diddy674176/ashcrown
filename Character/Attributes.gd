extends RefCounted
class_name Attributes
## Slice attribute keys — CLASSLESS_STARTER.md (MIG/SWT/FOC/VIT/BND).

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

static func make_base() -> Dictionary:
	return BASE.duplicate()
