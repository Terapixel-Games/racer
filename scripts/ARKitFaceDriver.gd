extends Node
class_name ARKitFaceDriver

const DEFAULT_PORT := 11111
const PREFERRED_FACE_MESH_NAME := "ARKitFaceProxy"
const ARKIT_BLEND_SHAPE_NAMES := [
	"EyeBlinkLeft",
	"EyeLookDownLeft",
	"EyeLookInLeft",
	"EyeLookOutLeft",
	"EyeLookUpLeft",
	"EyeSquintLeft",
	"EyeWideLeft",
	"EyeBlinkRight",
	"EyeLookDownRight",
	"EyeLookInRight",
	"EyeLookOutRight",
	"EyeLookUpRight",
	"EyeSquintRight",
	"EyeWideRight",
	"JawForward",
	"JawRight",
	"JawLeft",
	"JawOpen",
	"MouthClose",
	"MouthFunnel",
	"MouthPucker",
	"MouthRight",
	"MouthLeft",
	"MouthSmileLeft",
	"MouthSmileRight",
	"MouthFrownLeft",
	"MouthFrownRight",
	"MouthDimpleLeft",
	"MouthDimpleRight",
	"MouthStretchLeft",
	"MouthStretchRight",
	"MouthRollLower",
	"MouthRollUpper",
	"MouthShrugLower",
	"MouthShrugUpper",
	"MouthPressLeft",
	"MouthPressRight",
	"MouthLowerDownLeft",
	"MouthLowerDownRight",
	"MouthUpperUpLeft",
	"MouthUpperUpRight",
	"BrowDownLeft",
	"BrowDownRight",
	"BrowInnerUp",
	"BrowOuterUpLeft",
	"BrowOuterUpRight",
	"CheekPuff",
	"CheekSquintLeft",
	"CheekSquintRight",
	"NoseSneerLeft",
	"NoseSneerRight",
	"TongueOut",
]

@export var target_root: Node
@export var face_mesh_path: NodePath
@export var auto_start_server := false
@export_range(1, 65535, 1) var server_port := DEFAULT_PORT
@export_range(0.0, 60.0, 0.5) var smoothing_rate := 24.0

var _face_mesh: MeshInstance3D = null
var _blend_shape_indices: Dictionary = {}
var _smoothed_values: Dictionary = {}
var _server_start_attempted := false

func _ready() -> void:
	if target_root == null:
		target_root = get_parent()
	_rebind_face_mesh()

func bind_to_model(model_root: Node) -> bool:
	target_root = model_root
	_rebind_face_mesh()
	return _face_mesh != null

func has_face_mesh() -> bool:
	return _face_mesh != null and is_instance_valid(_face_mesh)

func get_mapped_blend_shape_count() -> int:
	return _blend_shape_indices.size()

func apply_blendshape_dictionary(values_by_name: Dictionary, delta: float = 0.0) -> int:
	if not has_face_mesh():
		return 0
	if _blend_shape_indices.is_empty():
		_cache_blend_shapes()

	var applied := 0
	for raw_name in values_by_name.keys():
		var index := _index_for_blend_shape_name(str(raw_name))
		if index < 0:
			continue
		_apply_value(index, float(values_by_name[raw_name]), delta)
		applied += 1
	return applied

func apply_blendshape_packet(blendshape_names: Array, blendshape_values: Array, delta: float = 0.0) -> int:
	var values_by_name := {}
	var count: int = mini(blendshape_names.size(), blendshape_values.size())
	for i in range(count):
		values_by_name[str(blendshape_names[i])] = float(blendshape_values[i])
	return apply_blendshape_dictionary(values_by_name, delta)

func _process(delta: float) -> void:
	if not has_face_mesh():
		return
	var server := _arkit_server()
	if server == null:
		return
	if auto_start_server:
		_start_server_once(server)
	var subject := _first_subject(server)
	if subject == null:
		return
	_apply_subject_packet(subject, delta)

func _rebind_face_mesh() -> void:
	_face_mesh = null
	_blend_shape_indices.clear()
	_smoothed_values.clear()
	if target_root == null:
		return
	if not face_mesh_path.is_empty() and target_root.has_node(face_mesh_path):
		var explicit := target_root.get_node(face_mesh_path)
		if explicit is MeshInstance3D:
			_face_mesh = explicit as MeshInstance3D
	if _face_mesh == null:
		_face_mesh = _find_named_blend_shape_mesh(target_root, PREFERRED_FACE_MESH_NAME)
	if _face_mesh == null:
		_face_mesh = _find_first_blend_shape_mesh(target_root)
	_cache_blend_shapes()
	set_process(_face_mesh != null)

func _cache_blend_shapes() -> void:
	_blend_shape_indices.clear()
	if _face_mesh == null or _face_mesh.mesh == null:
		return
	for i in range(_face_mesh.mesh.get_blend_shape_count()):
		var shape_name: String = _face_mesh.mesh.get_blend_shape_name(i)
		_blend_shape_indices[_blend_shape_key(shape_name)] = i

func _find_first_blend_shape_mesh(root: Node) -> MeshInstance3D:
	if root is MeshInstance3D and _mesh_has_blend_shapes((root as MeshInstance3D).mesh):
		return root as MeshInstance3D
	for child in root.get_children():
		if child is Node:
			var found: MeshInstance3D = _find_first_blend_shape_mesh(child)
			if found != null:
				return found
	return null

func _find_named_blend_shape_mesh(root: Node, mesh_name: String) -> MeshInstance3D:
	if root is MeshInstance3D and root.name == mesh_name and _mesh_has_blend_shapes((root as MeshInstance3D).mesh):
		return root as MeshInstance3D
	for child in root.get_children():
		if child is Node:
			var found: MeshInstance3D = _find_named_blend_shape_mesh(child, mesh_name)
			if found != null:
				return found
	return null

func _mesh_has_blend_shapes(mesh: Mesh) -> bool:
	return mesh != null and mesh.get_blend_shape_count() > 0

func _index_for_blend_shape_name(raw_name: String) -> int:
	var key := _blend_shape_key(raw_name)
	if _blend_shape_indices.has(key):
		return int(_blend_shape_indices[key])
	return -1

func _apply_value(index: int, raw_value: float, delta: float) -> void:
	var target_value := clampf(raw_value, 0.0, 1.0)
	var value := target_value
	if delta > 0.0 and smoothing_rate > 0.0:
		var previous := float(_smoothed_values.get(index, _face_mesh.get_blend_shape_value(index)))
		value = lerpf(previous, target_value, clampf(delta * smoothing_rate, 0.0, 1.0))
	_smoothed_values[index] = value
	_face_mesh.set_blend_shape_value(index, value)

func _apply_subject_packet(subject: Object, delta: float) -> void:
	var packet: Variant = subject.get("packet")
	if packet == null:
		return
	var names := _arkit_blendshape_names()
	var values: Variant = packet.get("blendshapes_array")
	if names.is_empty() or not (values is Array or values is PackedFloat32Array):
		return
	var packet_count: Variant = packet.get("number_of_blendshapes")
	var count: int = int(packet_count) if packet_count != null else values.size()
	apply_blendshape_packet(names.slice(0, count), Array(values).slice(0, count), delta)

func _arkit_server() -> Object:
	var singleton: Object = null
	if Engine.has_singleton("ARKitSingleton"):
		singleton = Engine.get_singleton("ARKitSingleton")
	else:
		var root_singleton := get_node_or_null("/root/ARKitSingleton")
		if root_singleton != null:
			singleton = root_singleton
	if singleton == null:
		return null
	return singleton.get("_server") as Object

func _start_server_once(server: Object) -> void:
	if _server_start_attempted:
		return
	_server_start_attempted = true
	if server.has_method("change_port"):
		server.call("change_port", server_port)
	if server.has_method("start"):
		server.call("start")

func _first_subject(server: Object) -> Object:
	var subjects: Variant = server.get("subjects")
	if subjects is Dictionary:
		for subject in (subjects as Dictionary).values():
			if subject is Object:
				return subject as Object
	return null

func _arkit_blendshape_names() -> Array:
	return ARKIT_BLEND_SHAPE_NAMES.duplicate()

func _blend_shape_key(raw_name: String) -> String:
	return raw_name.strip_edges().replace("_", "").replace("-", "").replace(" ", "").to_lower()
