extends RefCounted
class_name TrackRuntimeBuilder

const CheckpointAreaScript = preload("res://scripts/CheckpointArea.gd")
const CheckpointSystemScript = preload("res://scripts/CheckpointSystem.gd")
const FinishLineAreaScript = preload("res://scripts/FinishLineArea.gd")
const RoadMeshScript = preload("res://scripts/RoadMesh.gd")
const TrackDefinition = preload("res://scripts/track/TrackDefinition.gd")
const TrackWalls = preload("res://scripts/TrackWalls.gd")

static func build(definition: TrackDefinition) -> Dictionary:
	if definition == null:
		return {"node": Node3D.new(), "spawns": [], "waypoints": [], "laps": 1, "metadata": {}}
	var errors := definition.validate()
	if not errors.is_empty():
		push_error("Invalid track definition %s: %s" % [definition.id, "; ".join(errors)])

	var root := Node3D.new()
	root.name = "%s_Track" % definition.id.capitalize().replace(" ", "")

	_build_environment(root)
	_build_ground(root, definition)
	_build_road(root, definition)
	_build_walls(root, definition)
	var spawns := _build_spawns(root, definition)
	var waypoints := _build_waypoints(root, definition)
	_build_checkpoints(root, definition)
	_build_sockets(root, "ItemSockets", definition.item_sockets)
	_build_sockets(root, "HazardSockets", definition.hazard_sockets)
	_build_audio_zones(root)
	_build_dressing(root, definition)

	return {
		"node": root,
		"spawns": spawns,
		"waypoints": waypoints,
		"laps": definition.laps,
		"checkpoints": definition.checkpoint_indices.size(),
		"metadata": definition.to_metadata(),
	}

static func _build_environment(root: Node3D) -> void:
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_horizon_color = Color(0.58, 0.72, 0.9)
	sky_material.ground_horizon_color = Color(0.64, 0.62, 0.58)
	var sky := Sky.new()
	sky.sky_material = sky_material
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_sky_contribution = 0.8
	environment.ambient_light_energy = 1.1
	environment.glow_enabled = true
	environment.glow_intensity = 0.04
	var env_node := WorldEnvironment.new()
	env_node.name = "WorldEnvironment"
	env_node.environment = environment
	root.add_child(env_node)

	var light := DirectionalLight3D.new()
	light.name = "SunLight"
	light.transform.basis = Basis().looking_at(Vector3(0.5, -0.8, 0.35).normalized(), Vector3.UP)
	light.light_energy = 2.4
	light.shadow_enabled = true
	root.add_child(light)

static func _build_ground(root: Node3D, definition: TrackDefinition) -> void:
	var ground := StaticBody3D.new()
	ground.name = "Ground"
	var shape_node := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(definition.ground_size.x, 0.2, definition.ground_size.y)
	shape_node.shape = shape
	ground.add_child(shape_node)
	root.add_child(ground)

	var visual := MeshInstance3D.new()
	visual.name = "GroundVisual"
	var plane := PlaneMesh.new()
	plane.size = definition.ground_size
	visual.mesh = plane
	visual.transform.origin = Vector3(0, -0.1, 0)
	var material := StandardMaterial3D.new()
	material.albedo_color = definition.ground_color
	material.roughness = 0.72
	if not definition.ground_texture_path.is_empty():
		var texture := load(definition.ground_texture_path)
		if texture is Texture2D:
			material.albedo_texture = texture
	visual.material_override = material
	root.add_child(visual)

static func _build_road(root: Node3D, definition: TrackDefinition) -> void:
	var road := MeshInstance3D.new()
	road.name = "Road"
	road.set_script(RoadMeshScript)
	road.set("points", definition.route_points)
	road.set("width", definition.road_width)
	road.set("force_close", definition.closed_loop)
	road.set("show_wall_preview", false)
	road.set("generate_walls_runtime", false)
	if not definition.road_texture_path.is_empty():
		var texture := load(definition.road_texture_path)
		if texture is Texture2D:
			road.set("road_texture", texture)

	var collision_body := StaticBody3D.new()
	collision_body.name = "CollisionBody"
	var collision_shape := CollisionShape3D.new()
	collision_shape.name = "CollisionShape3D"
	collision_body.add_child(collision_shape)
	road.add_child(collision_body)
	root.add_child(road)

static func _build_walls(root: Node3D, definition: TrackDefinition) -> void:
	var holder := Node3D.new()
	holder.name = "Walls"
	root.add_child(holder)
	var points := PackedVector3Array()
	for point in definition.route_points:
		points.append(point)
	TrackWalls.build_walls(
		holder,
		points,
		definition.road_width * 0.5,
		definition.wall_height,
		definition.wall_thickness,
		false,
		definition.closed_loop,
		true
	)

static func _build_spawns(root: Node3D, definition: TrackDefinition) -> Array:
	var holder := Node3D.new()
	holder.name = "SpawnPoints"
	root.add_child(holder)
	var out: Array = []
	for i in range(definition.spawn_points.size()):
		var socket := definition.spawn_points[i]
		var marker := Marker3D.new()
		marker.name = "Start%02d" % (i + 1)
		marker.transform = _transform_from_socket(socket)
		holder.add_child(marker)
		out.append(marker.transform)
	return out

static func _build_waypoints(root: Node3D, definition: TrackDefinition) -> Array:
	var holder := Node3D.new()
	holder.name = "Waypoints"
	root.add_child(holder)
	var out: Array = []
	for i in range(definition.route_points.size()):
		var marker := Marker3D.new()
		marker.name = "Waypoint%02d" % (i + 1)
		marker.transform.origin = definition.route_points[i]
		holder.add_child(marker)
		out.append(definition.route_points[i])
	return out

static func _build_checkpoints(root: Node3D, definition: TrackDefinition) -> void:
	var holder := Node3D.new()
	holder.name = "CheckpointSystem"
	holder.set_script(CheckpointSystemScript)
	holder.set("checkpoint_count", definition.checkpoint_indices.size())
	holder.set("lap_gate_index", definition.lap_gate_checkpoint_index)
	root.add_child(holder)

	for i in range(definition.checkpoint_indices.size()):
		var route_index := definition.checkpoint_indices[i]
		var area := Area3D.new()
		area.name = "Checkpoint%02d" % i
		area.set_script(CheckpointAreaScript)
		area.set("checkpoint_index", i)
		area.set("is_lap_gate", i == definition.lap_gate_checkpoint_index)
		area.transform = _transform_for_route_index(definition, route_index)
		_add_area_shape(area, Vector3(definition.road_width + 2.0, 3.0, 4.0))
		holder.add_child(area)

	var lap_gate_route_index := definition.checkpoint_indices[definition.lap_gate_checkpoint_index]
	var finish := Area3D.new()
	finish.name = "FinishLine"
	finish.set_script(FinishLineAreaScript)
	finish.transform = _transform_for_route_index(definition, lap_gate_route_index)
	_add_area_shape(finish, Vector3(definition.road_width + 4.0, 3.0, 4.0))
	holder.add_child(finish)

static func _build_sockets(root: Node3D, holder_name: String, sockets: Array[Vector4]) -> void:
	var holder := Node3D.new()
	holder.name = holder_name
	root.add_child(holder)
	for i in range(sockets.size()):
		var marker := Marker3D.new()
		marker.name = "%s%02d" % [holder_name.trim_suffix("s"), i + 1]
		marker.transform = _transform_from_socket(sockets[i])
		holder.add_child(marker)

static func _build_audio_zones(root: Node3D) -> void:
	var holder := Node3D.new()
	holder.name = "AudioZones"
	root.add_child(holder)

static func _build_dressing(root: Node3D, definition: TrackDefinition) -> void:
	var holder := Node3D.new()
	holder.name = "Dressing"
	root.add_child(holder)
	if definition.id != "kitchen":
		return
	_add_scene_instance(holder, "res://assets/source/kenney/furniture_kit/table.glb", Vector3(0, 0, 34), 0.0, Vector3(5, 5, 5), "KitchenTable")
	_add_scene_instance(holder, "res://assets/source/kenney/furniture_kit/kitchenSink.glb", Vector3(-64, 0, -8), 90.0, Vector3(5, 5, 5), "KitchenSink")
	_add_scene_instance(holder, "res://assets/source/kenney/food_kit/cooking-spoon.glb", Vector3(42, 0.15, 22), -20.0, Vector3(7, 7, 7), "SpoonHazard")
	_add_scene_instance(holder, "res://assets/source/kenney/food_kit/cutting-board.glb", Vector3(30, 0.1, -42), 18.0, Vector3(6, 6, 6), "CuttingBoard")
	_add_scene_instance(holder, "res://assets/source/meshy/2026-04-27-character-track-batch/sir_clink/landmark_set.glb", Vector3(-34, 0, 40), 35.0, Vector3(1.8, 1.8, 1.8), "SirClinkLandmark")

static func _add_scene_instance(parent: Node3D, path: String, position: Vector3, yaw_degrees: float, scale: Vector3, node_name: String) -> void:
	var packed := load(path)
	if not (packed is PackedScene):
		return
	var instance := (packed as PackedScene).instantiate()
	if not (instance is Node3D):
		instance.queue_free()
		return
	var node := instance as Node3D
	node.name = node_name
	node.transform = Transform3D(Basis(Vector3.UP, deg_to_rad(yaw_degrees)).scaled(scale), position)
	parent.add_child(node)

static func _add_area_shape(area: Area3D, size: Vector3) -> void:
	var shape_node := CollisionShape3D.new()
	shape_node.name = "CollisionShape3D"
	var shape := BoxShape3D.new()
	shape.size = size
	shape_node.shape = shape
	area.add_child(shape_node)

static func _transform_for_route_index(definition: TrackDefinition, route_index: int) -> Transform3D:
	var point := definition.route_points[clamp(route_index, 0, definition.route_points.size() - 1)]
	var next := definition.route_points[(route_index + 1) % definition.route_points.size()]
	var prev := definition.route_points[(route_index - 1 + definition.route_points.size()) % definition.route_points.size()]
	var tangent := (next - prev).normalized()
	if tangent == Vector3.ZERO:
		tangent = Vector3.FORWARD
	var yaw := atan2(tangent.x, tangent.z)
	return Transform3D(Basis(Vector3.UP, yaw), point + Vector3.UP * 1.0)

static func _transform_from_socket(socket: Vector4) -> Transform3D:
	var position := Vector3(socket.x, socket.y, socket.z)
	var basis := Basis(Vector3.UP, deg_to_rad(socket.w))
	return Transform3D(basis, position)
