extends Node3D
class_name ChunkStreamer
## Phase 1 stub: load/unload a neighboring empty chunk marker near the player.

@export var player_path: NodePath
@export var chunk_size: float = 64.0
@export var load_radius_chunks: int = 1

var _player: Node3D
var _loaded: Dictionary = {}  # Vector2i -> Node3D
var _origin_chunk: Vector2i = Vector2i(0, 0)

func _ready() -> void:
	if player_path != NodePath(""):
		_player = get_node_or_null(player_path)
	# Always keep origin graybox "loaded" as logical chunk (0,0)
	_loaded[Vector2i(0, 0)] = null
	_ensure_neighbor_markers()

func bind_player(p: Node3D) -> void:
	_player = p

func _physics_process(_delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	var c := _world_to_chunk(_player.global_position)
	if c != _origin_chunk:
		_origin_chunk = c
		_ensure_neighbor_markers()

func _world_to_chunk(pos: Vector3) -> Vector2i:
	return Vector2i(int(floor(pos.x / chunk_size)), int(floor(pos.z / chunk_size)))

func _ensure_neighbor_markers() -> void:
	var needed: Dictionary = {}
	for x in range(_origin_chunk.x - load_radius_chunks, _origin_chunk.x + load_radius_chunks + 1):
		for z in range(_origin_chunk.y - load_radius_chunks, _origin_chunk.y + load_radius_chunks + 1):
			needed[Vector2i(x, z)] = true
	# Unload
	for key in _loaded.keys():
		if key == Vector2i(0, 0):
			continue  # keep origin
		if not needed.has(key):
			var node: Node = _loaded[key]
			if node and is_instance_valid(node):
				node.queue_free()
			_loaded.erase(key)
			EventBus.chunk_unloaded.emit("%s_%s" % [key.x, key.y])
	# Load markers for empty neighbors
	for key in needed.keys():
		if _loaded.has(key):
			continue
		if key == Vector2i(0, 0):
			_loaded[key] = null
			continue
		var marker := _make_chunk_marker(key)
		add_child(marker)
		_loaded[key] = marker
		EventBus.chunk_loaded.emit("%s_%s" % [key.x, key.y])

func _make_chunk_marker(key: Vector2i) -> Node3D:
	var n := Node3D.new()
	n.name = "Chunk_%s_%s" % [key.x, key.y]
	n.position = Vector3((key.x + 0.5) * chunk_size, 0.05, (key.y + 0.5) * chunk_size)
	var mesh_inst := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(2, 0.1, 2)
	mesh_inst.mesh = box
	n.add_child(mesh_inst)
	return n
