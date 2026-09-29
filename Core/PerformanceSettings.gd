extends Node
## Mid / Battery Saver presets — real resolution scale, shadows, FPS cap.

signal preset_changed(preset: String)

var current: String = "Mid"
var _sun: DirectionalLight3D = null

const PRESETS := {
	"High": {"scale": 1.0, "shadows": true, "fps": 60},
	"Mid": {"scale": 0.85, "shadows": false, "fps": 45},
	"Battery Saver": {"scale": 0.65, "shadows": false, "fps": 30},
}

func _ready() -> void:
	apply_preset("Mid")

func register_sun(light: DirectionalLight3D) -> void:
	_sun = light
	_apply_shadows()

func apply_preset(name: String) -> void:
	if not PRESETS.has(name):
		name = "Mid"
	current = name
	var p: Dictionary = PRESETS[name]
	var scale := float(p["scale"])
	get_tree().root.content_scale_factor = scale
	# Prefer 3D stretch scale via viewport
	var vp := get_viewport()
	if vp:
		vp.scaling_3d_scale = scale
	Engine.max_fps = int(p["fps"])
	_apply_shadows()
	preset_changed.emit(current)
	if EventBus:
		EventBus.hud_toast.emit("Graphics: %s (scale %.0f%% · %dfps)" % [
			current, scale * 100.0, int(p["fps"])
		])

func _apply_shadows() -> void:
	var on := bool(PRESETS.get(current, {}).get("shadows", false))
	if _sun and is_instance_valid(_sun):
		_sun.shadow_enabled = on
	# Also toggle any DirectionalLight3D in tree lightly
	for n in get_tree().get_nodes_in_group("world_light"):
		if n is DirectionalLight3D:
			(n as DirectionalLight3D).shadow_enabled = on

func cycle() -> String:
	var order := ["High", "Mid", "Battery Saver"]
	var i := order.find(current)
	i = (i + 1) % order.size()
	apply_preset(order[i])
	return current
