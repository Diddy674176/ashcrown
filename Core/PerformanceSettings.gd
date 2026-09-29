extends Node
## Mid / Battery Saver quality toggles (PERFORMANCE_BUDGET.md).

const PRESETS := ["Mid", "Battery Saver", "Low"]
var preset: String = "Mid"
var _sun: DirectionalLight3D

func cycle() -> String:
	var i := PRESETS.find(preset)
	if i < 0:
		i = 0
	preset = PRESETS[(i + 1) % PRESETS.size()]
	apply_preset()
	if EventBus:
		EventBus.hud_toast.emit("Graphics: %s" % preset)
	return preset

func register_sun(sun: DirectionalLight3D) -> void:
	_sun = sun
	apply_preset()

func apply_preset() -> void:
	match preset:
		"Battery Saver":
			Engine.max_fps = 30
			if _sun:
				_sun.light_energy = 0.85
				_sun.shadow_enabled = false
		"Low":
			Engine.max_fps = 30
			if _sun:
				_sun.light_energy = 0.9
				_sun.shadow_enabled = false
		_:
			Engine.max_fps = 60
			if _sun:
				_sun.light_energy = 1.1
				_sun.shadow_enabled = false
