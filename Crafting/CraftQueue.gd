extends Node
## Smith + alchemy craft queue with tick stub (usable from town).

signal craft_completed(recipe_id: String, item_id: String)
signal queue_changed

const RECIPES := {
	"smith_iron_blade": {
		"name": "Forge Iron Nail Blade",
		"station": "smith",
		"inputs": {"wake_ore": 2, "gold": 15},
		"output": "iron_nail_blade",
		"seconds": 8.0,
	},
	"alchemy_draught": {
		"name": "Brew Health Draught",
		"station": "alchemy",
		"inputs": {"ember_fiber": 1, "gold": 5},
		"output": "health_draught",
		"seconds": 6.0,
	},
}

var queue: Array = []  # {recipe_id, remaining, output}
var _player: Node = null

func bind_player(p: Node) -> void:
	_player = p

func _process(delta: float) -> void:
	if queue.is_empty():
		return
	var job: Dictionary = queue[0]
	job["remaining"] = float(job.get("remaining", 0.0)) - delta
	queue[0] = job
	if float(job["remaining"]) <= 0.0:
		_finish_job(job)
		queue.pop_front()
		queue_changed.emit()

func _finish_job(job: Dictionary) -> void:
	var out_id := str(job.get("output", ""))
	if _player and out_id != "" and _player.has_method("add_item"):
		_player.add_item(out_id)
	craft_completed.emit(str(job.get("recipe_id", "")), out_id)
	if EventBus:
		EventBus.hud_toast.emit("Craft ready: %s" % ItemDB.display_name(out_id))

func try_start(recipe_id: String, station: String) -> String:
	if not RECIPES.has(recipe_id):
		return "unknown"
	var r: Dictionary = RECIPES[recipe_id]
	if str(r.get("station", "")) != station:
		return "wrong_station"
	if queue.size() >= 2:
		return "queue_full"
	if _player == null:
		return "no_player"
	var inputs: Dictionary = r.get("inputs", {})
	# Check gold
	var gold_need := int(inputs.get("gold", 0))
	if "gold" in _player and int(_player.gold) < gold_need:
		return "need_gold"
	# Check items
	for k in inputs.keys():
		if k == "gold":
			continue
		var need := int(inputs[k])
		if not _player.has_method("count_item") or _player.count_item(k) < need:
			return "need_%s" % k
	# Spend
	if gold_need > 0:
		_player.gold -= gold_need
	for k in inputs.keys():
		if k == "gold":
			continue
		_player.consume_item(k, int(inputs[k]))
	queue.append({
		"recipe_id": recipe_id,
		"output": r["output"],
		"remaining": float(r["seconds"]),
		"name": r["name"],
	})
	queue_changed.emit()
	if EventBus:
		EventBus.hud_toast.emit("Crafting: %s (%.0fs)" % [r["name"], r["seconds"]])
	return "ok"

func snapshot() -> Array:
	return queue.duplicate(true)

func apply_snapshot(data: Array) -> void:
	queue = data.duplicate(true)
