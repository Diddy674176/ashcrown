extends Node3D
class_name TelegraphDecal
## Phone-readable attack tell - mesh/decal, not particle-only (COMBAT.md).

enum Kind { DODGE_AMBER, BLOCK_BLUE, UNBLOCKABLE_RED, AOE_AMBER }

const COLORS := {
	Kind.DODGE_AMBER: Color(1.0, 0.72, 0.15, 0.55),
	Kind.BLOCK_BLUE: Color(0.55, 0.75, 1.0, 0.55),
	Kind.UNBLOCKABLE_RED: Color(1.0, 0.2, 0.15, 0.6),
	Kind.AOE_AMBER: Color(1.0, 0.55, 0.1, 0.5),
}

var kind: Kind = Kind.DODGE_AMBER
var duration: float = 0.6
var radius: float = 2.5
var _age: float = 0.0
var _mesh: MeshInstance3D

func _ready() -> void:
	_mesh = MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = 0.08
	_mesh.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = COLORS.get(kind, Color.ORANGE)
	mat.no_depth_test = true
	_mesh.material_override = mat
	add_child(_mesh)

func _process(delta: float) -> void:
	_age += delta
	var t := clampf(_age / maxf(duration, 0.01), 0.0, 1.0)
	if _mesh and _mesh.material_override:
		var c: Color = COLORS.get(kind, Color.ORANGE)
		c.a = lerpf(0.25, 0.75, t)
		if kind == Kind.AOE_AMBER and t > 0.7:
			c = c.lerp(Color(1, 0.15, 0.1, 0.8), (t - 0.7) / 0.3)
		(_mesh.material_override as StandardMaterial3D).albedo_color = c
	if _age >= duration:
		queue_free()

static func spawn(parent: Node, pos: Vector3, p_kind: Kind, p_duration: float, p_radius: float = 2.5) -> TelegraphDecal:
	var t := TelegraphDecal.new()
	t.kind = p_kind
	t.duration = p_duration
	t.radius = p_radius
	parent.add_child(t)
	t.global_position = pos + Vector3(0, 0.05, 0)
	return t
