extends RefCounted
class_name SkillNodes
## Classless skill unlock stubs — CLASSLESS_STARTER.md (§5).
## Unlock cadence: one node at levels 2 / 4 / 6 / 8. Max equipped: 3 + ultimate.

const UNLOCK_LEVELS := [2, 4, 6, 8]
const MAX_EQUIPPED := 3

## Node catalog. heat = heat generated on cast; school gates overchannel.
const NODES := {
	"light_slash": {
		"name": "Light Slash", "school": "blade", "slot": "combat",
		"dmg": 22.0, "focus": 18.0, "heat": 14.0, "cd": 2.0,
		"desc": "Kit starter — short blade strike",
	},
	"dash_strike": {
		"name": "Dash Strike", "school": "blade", "slot": "combat",
		"dmg": 18.0, "focus": 16.0, "heat": 12.0, "cd": 1.8,
		"desc": "Kit starter — gap-close poke",
	},
	"piercing_shot": {
		"name": "Piercing Shot", "school": "nature", "slot": "combat",
		"dmg": 24.0, "focus": 20.0, "heat": 15.0, "cd": 2.2,
		"desc": "Kit starter — ranged pierce",
	},
	"nature_dot_seed": {
		"name": "Nature Seed", "school": "nature", "slot": "combat",
		"dmg": 16.0, "focus": 18.0, "heat": 10.0, "cd": 2.5,
		"desc": "Kit starter — DoT seed",
	},
	"binding_bolt": {
		"name": "Binding Bolt", "school": "binding", "slot": "combat",
		"dmg": 20.0, "focus": 22.0, "heat": 16.0, "cd": 2.0,
		"desc": "Kit starter — Wake bolt",
	},
	"minor_ward": {
		"name": "Minor Ward", "school": "binding", "slot": "combat",
		"dmg": 0.0, "focus": 24.0, "heat": 8.0, "cd": 3.0,
		"heal": 28.0,
		"desc": "Kit starter — brief ward / heal",
	},
	"ember_cleave": {
		"name": "Ember Cleave", "school": "elemental", "slot": "combat",
		"dmg": 30.0, "focus": 22.0, "heat": 22.0, "cd": 2.8,
		"desc": "Lv2 node — wide ember arc",
		"unlock_level": 2,
	},
	"veil_step": {
		"name": "Veil Step", "school": "wake", "slot": "combat",
		"dmg": 12.0, "focus": 14.0, "heat": 10.0, "cd": 2.4,
		"desc": "Lv2 node — short iframe dash strike",
		"unlock_level": 2,
	},
	"root_snare": {
		"name": "Root Snare", "school": "nature", "slot": "combat",
		"dmg": 14.0, "focus": 20.0, "heat": 12.0, "cd": 3.0,
		"desc": "Lv4 node — snare + chip",
		"unlock_level": 4,
	},
	"wake_lance": {
		"name": "Wake Lance", "school": "wake", "slot": "combat",
		"dmg": 34.0, "focus": 26.0, "heat": 24.0, "cd": 3.2,
		"desc": "Lv4 node — focused Wake pierce",
		"unlock_level": 4,
	},
	"ash_guard": {
		"name": "Ash Guard", "school": "binding", "slot": "combat",
		"dmg": 0.0, "focus": 20.0, "heat": 8.0, "cd": 4.0,
		"heal": 40.0,
		"desc": "Lv6 node — strong self ward",
		"unlock_level": 6,
	},
	"coil_breaker": {
		"name": "Coil Breaker", "school": "blade", "slot": "combat",
		"dmg": 38.0, "focus": 24.0, "heat": 20.0, "cd": 3.0,
		"desc": "Lv6 node — poise-break heavy",
		"unlock_level": 6,
	},
	"singing_brand": {
		"name": "Singing Brand", "school": "elemental", "slot": "combat",
		"dmg": 42.0, "focus": 28.0, "heat": 28.0, "cd": 3.5,
		"desc": "Lv8 node — high heat brand",
		"unlock_level": 8,
	},
	"crown_wake": {
		"name": "Crown Wake", "school": "wake", "slot": "ultimate",
		"dmg": 55.0, "focus": 40.0, "heat": 40.0, "cd": 12.0,
		"desc": "Ultimate — seals school briefly if overchannel",
		"unlock_level": 8,
	},
}

const KIT_STARTERS := {
	"Ashblade": ["light_slash", "dash_strike"],
	"Veilbow": ["piercing_shot", "nature_dot_seed"],
	"Corebinder": ["binding_bolt", "minor_ward"],
}

## Choices offered when a unlock-level is reached (player picks one).
const LEVEL_CHOICES := {
	2: ["ember_cleave", "veil_step"],
	4: ["root_snare", "wake_lance"],
	6: ["ash_guard", "coil_breaker"],
	8: ["singing_brand", "crown_wake"],
}

static func make_state(kit_id: String = "Ashblade") -> Dictionary:
	var starters: Array = KIT_STARTERS.get(kit_id, KIT_STARTERS["Ashblade"]).duplicate()
	return {
		"unlocked": starters.duplicate(),
		"equipped": starters.slice(0, mini(2, starters.size())),
		"ultimate": "",
		"pending_choice_level": 0,
		"pending_options": [],
		"claimed_levels": [],
	}

static func get_node(id: String) -> Dictionary:
	if NODES.has(id):
		var d: Dictionary = NODES[id].duplicate(true)
		d["id"] = id
		return d
	return {"id": id, "name": id, "school": "?", "slot": "combat", "dmg": 10.0, "focus": 15.0, "heat": 10.0, "cd": 2.0, "desc": "?"}

static func sync_unlocks(state: Dictionary, level: int) -> bool:
	## Returns true if a pending choice was opened.
	var claimed: Array = state.get("claimed_levels", [])
	for lv in UNLOCK_LEVELS:
		if level >= int(lv) and not (int(lv) in claimed) and int(state.get("pending_choice_level", 0)) == 0:
			state["pending_choice_level"] = int(lv)
			state["pending_options"] = LEVEL_CHOICES.get(int(lv), []).duplicate()
			return true
	return false

static func choose_node(state: Dictionary, node_id: String) -> bool:
	var opts: Array = state.get("pending_options", [])
	if node_id not in opts:
		return false
	var unlocked: Array = state.get("unlocked", [])
	if node_id not in unlocked:
		unlocked.append(node_id)
	state["unlocked"] = unlocked
	var lv: int = int(state.get("pending_choice_level", 0))
	var claimed: Array = state.get("claimed_levels", [])
	if lv > 0 and lv not in claimed:
		claimed.append(lv)
	state["claimed_levels"] = claimed
	state["pending_choice_level"] = 0
	state["pending_options"] = []
	var defn := get_node(node_id)
	if str(defn.get("slot", "")) == "ultimate":
		state["ultimate"] = node_id
	else:
		# Auto-equip if room
		var eq: Array = state.get("equipped", [])
		if eq.size() < MAX_EQUIPPED and node_id not in eq:
			eq.append(node_id)
			state["equipped"] = eq
	return true

static func equip(state: Dictionary, node_id: String) -> bool:
	var unlocked: Array = state.get("unlocked", [])
	if node_id not in unlocked:
		return false
	var defn := get_node(node_id)
	if str(defn.get("slot", "")) == "ultimate":
		state["ultimate"] = node_id
		return true
	var eq: Array = state.get("equipped", [])
	if node_id in eq:
		return true
	if eq.size() >= MAX_EQUIPPED:
		return false
	eq.append(node_id)
	state["equipped"] = eq
	return true

static func unequip(state: Dictionary, node_id: String) -> bool:
	if str(state.get("ultimate", "")) == node_id:
		state["ultimate"] = ""
		return true
	var eq: Array = state.get("equipped", [])
	eq.erase(node_id)
	state["equipped"] = eq
	return true

static func equipped_ids(state: Dictionary) -> Array:
	return state.get("equipped", []).duplicate()

static func skill_at_slot(state: Dictionary, slot: int) -> String:
	## slot 1..3 combat, 4 = ultimate
	if slot == 4:
		return str(state.get("ultimate", ""))
	var eq: Array = state.get("equipped", [])
	var idx := slot - 1
	if idx >= 0 and idx < eq.size():
		return str(eq[idx])
	return ""
