extends Node3D

const ARKitFaceDriverScript := preload("res://scripts/ARKitFaceDriver.gd")

@export_file("*.glb") var model_path := "res://assets/optimized/racers/rexx/arkit/rexx_racer_in_kart_mobile_detail_phase1.glb"
@export_range(1, 65535, 1) var server_port := 11111
@export var auto_start_server := true
@export var demo_without_phone := false

@onready var _status_label: Label = %StatusLabel
@onready var _camera: Camera3D = %PreviewCamera

var _model: Node3D = null
var _driver: ARKitFaceDriver = null
var _demo_time := 0.0

func _ready() -> void:
	_load_preview_model()
	_update_status()

func _process(delta: float) -> void:
	if demo_without_phone:
		_demo_time += delta
		_apply_demo_pose(delta)
	_update_status()

func _load_preview_model() -> void:
	if not ResourceLoader.exists(model_path):
		push_error("ARKit preview model does not exist: %s" % model_path)
		return
	var packed := load(model_path)
	if not (packed is PackedScene):
		push_error("ARKit preview model is not a PackedScene: %s" % model_path)
		return
	_model = (packed as PackedScene).instantiate() as Node3D
	if _model == null:
		push_error("ARKit preview model root is not Node3D: %s" % model_path)
		return
	_model.name = "RexxARKitPreviewModel"
	add_child(_model)
	_disable_gameplay_collision(_model)
	_fit_model_to_preview(_model)
	_attach_driver(_model)

func _attach_driver(model: Node3D) -> void:
	_driver = ARKitFaceDriverScript.new()
	_driver.name = "ARKitFaceDriver"
	_driver.auto_start_server = auto_start_server
	_driver.server_port = server_port
	model.add_child(_driver)
	if not _driver.bind_to_model(model):
		push_error("No blendshape MeshInstance3D found in ARKit preview model.")

func _fit_model_to_preview(model: Node3D) -> void:
	var aabb := _node_aabb(model)
	if aabb.size == Vector3.ZERO:
		return
	var center := aabb.get_center()
	model.global_position -= center
	var max_size := maxf(aabb.size.x, maxf(aabb.size.y, aabb.size.z))
	if max_size > 0.0:
		model.scale *= 2.2 / max_size
	_camera.look_at(Vector3(0.0, 0.35, 0.0), Vector3.UP)

func _node_aabb(root: Node3D) -> AABB:
	var result := AABB()
	var initialized := false
	for child in root.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := child as MeshInstance3D
		if mesh_instance == null or mesh_instance.mesh == null:
			continue
		var local_aabb := mesh_instance.mesh.get_aabb()
		var corners: Array[Vector3] = [
			local_aabb.position,
			local_aabb.position + Vector3(local_aabb.size.x, 0.0, 0.0),
			local_aabb.position + Vector3(0.0, local_aabb.size.y, 0.0),
			local_aabb.position + Vector3(0.0, 0.0, local_aabb.size.z),
			local_aabb.position + Vector3(local_aabb.size.x, local_aabb.size.y, 0.0),
			local_aabb.position + Vector3(local_aabb.size.x, 0.0, local_aabb.size.z),
			local_aabb.position + Vector3(0.0, local_aabb.size.y, local_aabb.size.z),
			local_aabb.position + local_aabb.size,
		]
		for corner in corners:
			var world_corner: Vector3 = mesh_instance.global_transform * corner
			if initialized:
				result = result.expand(world_corner)
			else:
				result = AABB(world_corner, Vector3.ZERO)
				initialized = true
	return result

func _apply_demo_pose(delta: float) -> void:
	if _driver == null:
		return
	var values := {
		"JawOpen": absf(sin(_demo_time * 1.8)) * 0.9,
		"MouthSmileLeft": absf(sin(_demo_time * 1.2)) * 0.75,
		"MouthSmileRight": absf(sin(_demo_time * 1.2)) * 0.75,
		"EyeBlinkLeft": maxf(0.0, sin(_demo_time * 4.0)) * 0.8,
		"EyeBlinkRight": maxf(0.0, sin(_demo_time * 4.0)) * 0.8,
		"BrowInnerUp": absf(sin(_demo_time * 0.85)) * 0.7,
	}
	_driver.apply_blendshape_dictionary(values, delta)

func _update_status() -> void:
	if _status_label == null:
		return
	var mapped := _driver.get_mapped_blend_shape_count() if _driver != null else 0
	var subjects := _subject_count()
	var server_state := "listening" if subjects > 0 else "waiting"
	if demo_without_phone:
		server_state = "demo"
	_status_label.text = "ARKit Face Preview | port %d | %s | subjects %d | shapes %d" % [server_port, server_state, subjects, mapped]

func _subject_count() -> int:
	var server := _arkit_server()
	if server == null:
		return 0
	var subjects: Variant = server.get("subjects")
	return subjects.size() if subjects is Dictionary else 0

func _arkit_server() -> Object:
	var singleton := get_node_or_null("/root/ARKitSingleton")
	if singleton == null:
		return null
	return singleton.get("_server") as Object

func _disable_gameplay_collision(node: Node) -> void:
	if node is CollisionShape3D:
		(node as CollisionShape3D).disabled = true
	elif node is CollisionObject3D:
		var collision_object := node as CollisionObject3D
		collision_object.collision_layer = 0
		collision_object.collision_mask = 0
	if node is Area3D:
		var area := node as Area3D
		area.monitoring = false
		area.monitorable = false
	for child in node.get_children():
		_disable_gameplay_collision(child)
