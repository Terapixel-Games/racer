extends RefCounted
class_name TrackRuntimeBuilder

const CheckpointAreaScript = preload("res://scripts/CheckpointArea.gd")
const CheckpointSystemScript = preload("res://scripts/CheckpointSystem.gd")
const FinishLineAreaScript = preload("res://scripts/FinishLineArea.gd")
const RoadMeshScript = preload("res://scripts/RoadMesh.gd")
const TrackDefinition = preload("res://scripts/track/TrackDefinition.gd")
const TrackRibbonMesh = preload("res://scripts/track/TrackRibbonMesh.gd")
const TrackWalls = preload("res://scripts/TrackWalls.gd")
const TrackSceneAuthoringData = preload("res://scripts/track/TrackSceneAuthoringData.gd")
const RailScene = preload("res://assets/source/kenney/racing_kit/rail.glb")

const RAIL_SIDE_SCALE := 8.0
const RAIL_SEGMENT_LENGTH := 10.0
const RAIL_EDGE_OFFSET := 0.0
const RAIL_SEGMENT_GAP := 0.85
const RAIL_Y_OFFSET := 0.12
const RAIL_VISUAL_CENTER := Vector3(0.15, 0.07, -0.625)
const RAIL_COLLISION_RADIUS := 0.055
const RAIL_COLLISION_HEIGHT := 1.0

static func build(definition: TrackDefinition) -> Dictionary:
	if definition == null:
		return {"node": Node3D.new(), "spawns": [], "waypoints": [], "laps": 1, "metadata": {}}
	definition = TrackSceneAuthoringData.apply_to_definition(definition)
	var errors := definition.validate()
	if not errors.is_empty():
		push_error("Invalid track definition %s: %s" % [definition.id, "; ".join(errors)])

	var root := Node3D.new()
	root.name = "%s_Track" % definition.id.capitalize().replace(" ", "")

	_build_environment(root)
	_build_ground(root, definition)
	_build_track_body(root, definition)
	_build_road(root, definition)
	_build_alternate_routes(root, definition)
	_build_route_rails(root, "Rails", definition.route_points, definition.road_width, definition.closed_loop, definition.rail_texture_path, definition.rail_texture_uv_scale)
	var spawns := _build_spawns(root, definition)
	var waypoints := _build_waypoints(root, definition)
	_build_checkpoints(root, definition)
	_build_sockets(root, "ItemSockets", definition.item_sockets)
	_build_sockets(root, "HazardSockets", definition.hazard_sockets)
	_build_shortcuts(root, definition)
	_build_section_markers(root, definition)
	_build_surface_segments(root, definition)
	_build_audio_zones(root, definition)
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
	var floor_is_out_of_bounds := definition.reset_mode == "instant_pop"
	if not floor_is_out_of_bounds:
		var ground := StaticBody3D.new()
		ground.name = "Ground"
		var shape_node := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(definition.ground_size.x, 0.2, definition.ground_size.y)
		shape_node.shape = shape
		ground.add_child(shape_node)
		root.add_child(ground)

	var visual := MeshInstance3D.new()
	visual.name = "FloorVisual" if floor_is_out_of_bounds else "GroundVisual"
	var plane := PlaneMesh.new()
	plane.size = definition.ground_size
	visual.mesh = plane
	visual.transform.origin = Vector3(0, definition.floor_visual_y if floor_is_out_of_bounds else -0.1, 0)
	var material := StandardMaterial3D.new()
	material.albedo_color = definition.ground_color
	material.roughness = 0.72
	if not definition.ground_texture_path.is_empty():
		var texture := load(definition.ground_texture_path)
		if texture is Texture2D:
			material.albedo_texture = texture
	visual.material_override = material
	root.add_child(visual)
	if floor_is_out_of_bounds and definition.id == "kitchen":
		_build_floor_tile_grid(root, definition)

static func _build_floor_tile_grid(root: Node3D, definition: TrackDefinition) -> void:
	var holder := Node3D.new()
	holder.name = "FloorTileGrid"
	root.add_child(holder)
	var y := definition.floor_visual_y + 0.03
	var tile_size := 8.0
	var half_x := definition.ground_size.x * 0.5
	var half_z := definition.ground_size.y * 0.5
	var line_color := Color(0.66, 0.82, 0.92)
	var x := -half_x
	while x <= half_x:
		_add_visual_box(holder, "TileLineX", Vector3(x, y, 0.0), Vector3(0.12, 0.035, definition.ground_size.y), 0.0, line_color)
		x += tile_size
	var z := -half_z
	while z <= half_z:
		_add_visual_box(holder, "TileLineZ", Vector3(0.0, y, z), Vector3(definition.ground_size.x, 0.035, 0.12), 0.0, line_color)
		z += tile_size

static func _build_track_body(root: Node3D, definition: TrackDefinition) -> void:
	var body := MeshInstance3D.new()
	body.name = "TrackBody"
	body.mesh = TrackRibbonMesh.build_slab_mesh(definition.route_points, definition.road_width, definition.track_body_depth, definition.closed_loop)
	var material := StandardMaterial3D.new()
	material.albedo_color = definition.track_body_color
	material.roughness = 0.58
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	body.material_override = material
	root.add_child(body)

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

static func _build_alternate_routes(root: Node3D, definition: TrackDefinition) -> void:
	if definition.alternate_routes.is_empty():
		return
	var holder := Node3D.new()
	holder.name = "AlternateRoutes"
	root.add_child(holder)
	for route in definition.alternate_routes:
		if not bool(route.get("enabled", true)):
			continue
		var points := _vector3_array_from_value(route.get("points", []))
		if points.size() < 2:
			continue
		var route_id := _safe_node_name(str(route.get("id", "alternate")))
		var width := float(route.get("road_width", definition.road_width))
		var body := MeshInstance3D.new()
		body.name = "%sTrackBody" % route_id
		body.mesh = TrackRibbonMesh.build_slab_mesh(points, width, definition.track_body_depth, false)
		var body_material := StandardMaterial3D.new()
		body_material.albedo_color = definition.track_body_color
		body_material.roughness = 0.58
		body_material.cull_mode = BaseMaterial3D.CULL_DISABLED
		body.material_override = body_material
		holder.add_child(body)

		var road := MeshInstance3D.new()
		road.name = "%sRoad" % route_id
		road.set_script(RoadMeshScript)
		road.set("points", points)
		road.set("width", width)
		road.set("force_close", false)
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
		holder.add_child(road)
		_build_route_rails(holder, "%sRails" % route_id, points, width, false, definition.rail_texture_path, definition.rail_texture_uv_scale)

static func _build_walls(root: Node3D, definition: TrackDefinition) -> void:
	var holder := Node3D.new()
	holder.name = "Walls"
	root.add_child(holder)
	var points := PackedVector3Array()
	for point in definition.route_points:
		points.append(point)
	var wall_gap_segments := TrackWalls.detect_grade_separated_crossing_segments(points, definition.closed_loop, definition.wall_height + 0.2, 2)
	TrackWalls.build_walls(
		holder,
		points,
		definition.road_width * 0.5,
		definition.wall_height,
		definition.wall_thickness,
		false,
		definition.closed_loop,
		true,
		wall_gap_segments
	)

static func _build_route_rails(parent: Node3D, holder_name: String, route_points: Array[Vector3], road_width: float, closed_loop: bool, rail_texture_path: String, rail_texture_uv_scale: float) -> void:
	if route_points.size() < 2 or road_width <= 0.0:
		return
	var holder := Node3D.new()
	holder.name = holder_name
	parent.add_child(holder)
	var rail_material := _rail_material(rail_texture_path, rail_texture_uv_scale)
	var edge_offset := road_width * 0.5 + RAIL_EDGE_OFFSET
	var edges := _road_edge_points(route_points, edge_offset, closed_loop)
	_add_rail_polyline_pieces(holder, edges.get("left", []), closed_loop, "L", rail_material)
	_add_rail_polyline_pieces(holder, edges.get("right", []), closed_loop, "R", rail_material)
	if holder.get_child_count() == 0:
		holder.queue_free()

static func _rail_material(rail_texture_path: String, rail_texture_uv_scale: float) -> Material:
	var material := StandardMaterial3D.new()
	material.roughness = 0.54
	material.uv1_scale = Vector3(rail_texture_uv_scale, rail_texture_uv_scale, 1.0)
	if not rail_texture_path.strip_edges().is_empty():
		var texture := load(rail_texture_path)
		if texture is Texture2D:
			material.albedo_texture = texture
	return material

static func _road_edge_points(route_points: Array[Vector3], offset: float, closed_loop: bool) -> Dictionary:
	var normals: Array[Vector3] = []
	var segment_count := route_points.size() - 1
	for i in range(segment_count):
		var direction := (route_points[i + 1] - route_points[i]).normalized()
		if direction == Vector3.ZERO:
			direction = Vector3.FORWARD
		normals.append(Vector3(direction.z, 0.0, -direction.x))
	if closed_loop:
		var direction := (route_points[0] - route_points[route_points.size() - 1]).normalized()
		if direction == Vector3.ZERO:
			direction = Vector3.FORWARD
		normals.append(Vector3(direction.z, 0.0, -direction.x))

	var left_points: Array[Vector3] = []
	var right_points: Array[Vector3] = []
	for i in range(route_points.size()):
		var previous_normal: Vector3
		var next_normal: Vector3
		if closed_loop:
			previous_normal = normals[(i - 1 + normals.size()) % normals.size()]
			next_normal = normals[i % normals.size()]
		else:
			previous_normal = normals[i - 1] if i > 0 else normals[0]
			next_normal = normals[i] if i < normals.size() else normals[normals.size() - 1]
		right_points.append(_road_miter_point(route_points[i], previous_normal, next_normal, offset))
		left_points.append(_road_miter_point(route_points[i], -previous_normal, -next_normal, offset))
	return {"left": left_points, "right": right_points}

static func _road_miter_point(point: Vector3, previous_normal: Vector3, next_normal: Vector3, offset: float) -> Vector3:
	var miter := previous_normal + next_normal
	if miter.length() < 0.001:
		miter = previous_normal
	miter = miter.normalized()
	var denom := miter.dot(previous_normal.normalized())
	if abs(denom) < 0.001:
		denom = 0.001 * (1.0 if denom >= 0.0 else -1.0)
	return point + miter * (abs(offset) / denom)

static func _add_rail_polyline_pieces(parent: Node3D, points: Array, closed_loop: bool, side_name: String, rail_material: Material) -> void:
	if points.size() < 2:
		return
	var segment_count := points.size() if closed_loop else points.size() - 1
	for i in range(segment_count):
		_add_rail_segment_pieces(parent, points[i] as Vector3, points[(i + 1) % points.size()] as Vector3, side_name, i, rail_material)

static func _add_rail_segment_pieces(parent: Node3D, a: Vector3, b: Vector3, side_name: String, segment_index: int, rail_material: Material) -> void:
	var segment := b - a
	var flat := Vector3(segment.x, 0.0, segment.z)
	var flat_length := flat.length()
	var segment_length := segment.length()
	if segment_length <= RAIL_SEGMENT_GAP * 2.0 + 0.05 or flat_length <= 0.05:
		return
	var segment_dir := segment / segment_length
	var usable_length := segment_length - RAIL_SEGMENT_GAP * 2.0
	var pieces: int = maxi(1, ceili(usable_length / RAIL_SEGMENT_LENGTH))
	var piece_length: float = usable_length / float(pieces)
	var rail_x := segment_dir
	var rail_z := rail_x.cross(Vector3.UP).normalized()
	if rail_z.length_squared() <= 0.0001:
		rail_z = Vector3.FORWARD
	var rail_y := rail_z.cross(rail_x).normalized()
	var basis := Basis(rail_x, rail_y, rail_z).scaled(Vector3(piece_length, RAIL_SIDE_SCALE, RAIL_SIDE_SCALE))
	for piece_index in range(pieces):
		var distance_along := RAIL_SEGMENT_GAP + (float(piece_index) + 0.5) * piece_length
		var t := distance_along / segment_length
		var visual_center := a.lerp(b, t) + Vector3.UP * RAIL_Y_OFFSET
		var position := visual_center - basis * RAIL_VISUAL_CENTER
		var rail: Node = RailScene.instantiate()
		if not (rail is Node3D):
			if rail != null:
				rail.queue_free()
			continue
		var rail_node := rail as Node3D
		rail_node.name = "Rail_%02d_%s_%02d" % [segment_index, side_name, piece_index]
		rail_node.transform = Transform3D(basis, position)
		_apply_material_override(rail_node, rail_material)
		_disable_gameplay_collision(rail_node)
		_add_rail_collision(rail_node)
		parent.add_child(rail_node)

static func _add_rail_collision(rail_node: Node3D) -> void:
	var body := StaticBody3D.new()
	body.name = "CollisionBody"
	body.collision_layer = 1
	body.collision_mask = 2
	var physics_material := PhysicsMaterial.new()
	physics_material.friction = 0.02
	physics_material.bounce = 0.0
	physics_material.rough = false
	body.physics_material_override = physics_material
	body.position = RAIL_VISUAL_CENTER + Vector3(0.0, 0.02, 0.0)
	var shape_node := CollisionShape3D.new()
	shape_node.name = "CollisionShape3D"
	shape_node.rotation_degrees = Vector3(0.0, 0.0, 90.0)
	var shape := CapsuleShape3D.new()
	shape.radius = RAIL_COLLISION_RADIUS
	shape.height = RAIL_COLLISION_HEIGHT
	shape_node.shape = shape
	body.add_child(shape_node)
	rail_node.add_child(body)

static func _apply_material_override(node: Node, material: Material) -> void:
	if node is MeshInstance3D:
		(node as MeshInstance3D).material_override = material
	for child in node.get_children():
		_apply_material_override(child, material)

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

static func _build_shortcuts(root: Node3D, definition: TrackDefinition) -> void:
	var holder := Node3D.new()
	holder.name = "ShortcutGates"
	root.add_child(holder)
	for gate in definition.shortcut_gates:
		var id := str(gate.get("id", "shortcut"))
		var entry := _point_from_gate_value(gate.get("entry", []))
		var exit := _point_from_gate_value(gate.get("exit", []))
		var width := float(gate.get("width", definition.road_width * 0.55))
		var entry_marker := Marker3D.new()
		entry_marker.name = "%s_Entry" % id
		entry_marker.transform.origin = entry
		holder.add_child(entry_marker)
		var exit_marker := Marker3D.new()
		exit_marker.name = "%s_Exit" % id
		exit_marker.transform.origin = exit
		holder.add_child(exit_marker)
		var surface_enabled := bool(gate.get("surface_enabled", true))
		if definition.id == "kitchen" and id == "table_jump" and surface_enabled:
			_build_table_jump_shortcut(root, entry, exit, width)

static func _build_table_jump_shortcut(root: Node3D, entry: Vector3, exit: Vector3, width: float) -> void:
	var holder := Node3D.new()
	holder.name = "ShortcutSurface"
	root.add_child(holder)
	var flat_direction := exit - entry
	flat_direction.y = 0.0
	if flat_direction.length_squared() <= 0.0001:
		flat_direction = Vector3.FORWARD
	flat_direction = flat_direction.normalized()
	var usable_width: float = maxf(width, 12.0)
	var approach_start := entry - flat_direction * 10.0 + Vector3.UP * 0.03
	var approach_end := entry + flat_direction * 2.0 + Vector3.UP * 0.03
	var midpoint := entry.lerp(exit, 0.5)
	var apex := midpoint + Vector3.UP * 0.95
	var ramp_entry := entry + Vector3.DOWN * 0.12
	var landing_start := exit - flat_direction * 2.0 + Vector3.UP * 0.03
	var landing_end := exit + flat_direction * 8.0 + Vector3.UP * 0.03
	_add_shortcut_box(holder, "TableJumpApproach", approach_start.lerp(approach_end, 0.5), approach_start, approach_end, usable_width, 0.18, Color(0.7, 0.38, 0.28))
	_add_shortcut_box(holder, "TableJumpRampUp", ramp_entry.lerp(apex, 0.5), ramp_entry, apex, usable_width, 0.32, Color(0.86, 0.32, 0.18))
	_add_shortcut_box(holder, "TableJumpRampDown", apex.lerp(exit, 0.5), apex, exit, usable_width, 0.32, Color(0.86, 0.32, 0.18))
	_add_shortcut_box(holder, "TableJumpDeck", apex, entry.lerp(exit, 0.42) + Vector3.UP * 0.95, entry.lerp(exit, 0.58) + Vector3.UP * 0.95, usable_width, 0.28, Color(0.95, 0.72, 0.28))
	_add_shortcut_box(holder, "TableJumpLanding", landing_start.lerp(landing_end, 0.5), landing_start, landing_end, usable_width, 0.18, Color(0.7, 0.38, 0.28))

static func _add_shortcut_box(parent: Node3D, node_name: String, origin: Vector3, a: Vector3, b: Vector3, width: float, thickness: float, color: Color) -> void:
	var body := StaticBody3D.new()
	body.name = node_name
	var direction := b - a
	var length: float = maxf(direction.length(), 0.1)
	direction = direction.normalized()
	var basis := Basis().looking_at(direction, Vector3.UP).orthonormalized()
	body.transform = Transform3D(basis, origin)
	var shape_node := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(width, thickness, length)
	shape_node.shape = shape
	body.add_child(shape_node)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = shape.size
	mesh.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.55
	mesh.material_override = material
	body.add_child(mesh)
	parent.add_child(body)

static func _build_surface_segments(root: Node3D, definition: TrackDefinition) -> void:
	var holder := Node3D.new()
	holder.name = "SurfaceSegments"
	root.add_child(holder)
	for segment in definition.surface_segments:
		var marker := Marker3D.new()
		marker.name = str(segment.get("id", "SurfaceSegment"))
		marker.transform.origin = _vector3_from_value(segment.get("position", Vector3.ZERO), Vector3.ZERO)
		marker.set_meta("start_route_index", int(segment.get("start_route_index", 0)))
		marker.set_meta("end_route_index", int(segment.get("end_route_index", 0)))
		marker.set_meta("surface_audio_id", str(segment.get("surface_audio_id", "")))
		marker.set_meta("surface_material_id", str(segment.get("surface_material_id", "")))
		holder.add_child(marker)

static func _build_audio_zones(root: Node3D, definition: TrackDefinition) -> void:
	var holder := Node3D.new()
	holder.name = "AudioZones"
	root.add_child(holder)
	for zone in definition.audio_zones:
		var area := Area3D.new()
		area.name = str(zone.get("id", "AudioZone"))
		area.transform.origin = _vector3_from_value(zone.get("position", Vector3.ZERO), Vector3.ZERO)
		area.set_meta("audio_id", str(zone.get("audio_id", "")))
		area.set_meta("audio_path", str(zone.get("audio_path", "")))
		area.set_meta("zone_kind", str(zone.get("zone_kind", "ambient")))
		area.set_meta("volume_db", float(zone.get("volume_db", 0.0)))
		var shape_node := CollisionShape3D.new()
		shape_node.name = "CollisionShape3D"
		var shape := SphereShape3D.new()
		shape.radius = maxf(float(zone.get("radius", 12.0)), 0.1)
		shape_node.shape = shape
		area.add_child(shape_node)
		holder.add_child(area)

static func _build_section_markers(root: Node3D, definition: TrackDefinition) -> void:
	if definition.id != "kitchen":
		return
	var holder := Node3D.new()
	holder.name = "SectionMarkers"
	root.add_child(holder)
	_add_section_marker(holder, "StartFinishStraight", Vector3(-46, 3.65, -78))
	_add_section_marker(holder, "StoveHairpin", Vector3(-100, 3.75, -24))
	_add_section_marker(holder, "IslandSweeper", Vector3(22, 5.55, -38))
	_add_section_marker(holder, "BackStraight", Vector3(112, 4.7, 18))
	_add_section_marker(holder, "SinkChicane", Vector3(-8, 4.15, 74))
	_add_section_marker(holder, "FridgeClimb", Vector3(122, 3.6, -18))
	_add_section_marker(holder, "FridgeTopRun", Vector3(122, 3.6, 30))
	_add_section_marker(holder, "FridgeCorner", Vector3(112, 3.6, 72))

static func _add_section_marker(parent: Node3D, marker_name: String, position: Vector3) -> void:
	var marker := Marker3D.new()
	marker.name = marker_name
	marker.transform.origin = position
	parent.add_child(marker)

static func _build_dressing(root: Node3D, definition: TrackDefinition) -> void:
	var holder := Node3D.new()
	holder.name = "Dressing"
	root.add_child(holder)
	_add_dressing_scene(holder, definition)
	if definition.id == "kitchen":
		return
	_build_stage_props(holder, definition)

static func _build_full_size_kitchen_room(holder: Node3D) -> void:
	_add_visual_box(holder, "KitchenBackWall", Vector3(0, 16.0, 98), Vector3(252, 32.0, 2.0), 0.0, Color(0.62, 0.57, 0.49))
	_add_visual_box(holder, "KitchenLeftWall", Vector3(-128, 16.0, 0), Vector3(2.0, 32.0, 196), 0.0, Color(0.58, 0.54, 0.48))
	_add_visual_box(holder, "KitchenRightWall", Vector3(146, 16.0, 0), Vector3(2.0, 32.0, 196), 0.0, Color(0.58, 0.54, 0.48))
	_add_visual_box(holder, "KitchenCeiling", Vector3(9, 25.8, 0), Vector3(292.0, 1.0, 200.0), 0.0, Color(0.8, 0.76, 0.68))
	_add_visual_box(holder, "KitchenFrontWallLeft", Vector3(-80, 13.0, -98), Vector3(96.0, 26.0, 2.0), 0.0, Color(0.6, 0.56, 0.5))
	_add_visual_box(holder, "KitchenFrontWallRight", Vector3(80, 13.0, -98), Vector3(96.0, 26.0, 2.0), 0.0, Color(0.6, 0.56, 0.5))
	_add_visual_box(holder, "KitchenFrontDoorHeader", Vector3(0, 22.0, -98), Vector3(64.0, 8.0, 2.0), 0.0, Color(0.6, 0.56, 0.5))
	_add_visual_box(holder, "KitchenDoorFrameLeft", Vector3(-33, 8.0, -99), Vector3(2.0, 16.0, 1.0), 0.0, Color(0.32, 0.17, 0.08))
	_add_visual_box(holder, "KitchenDoorFrameRight", Vector3(33, 8.0, -99), Vector3(2.0, 16.0, 1.0), 0.0, Color(0.32, 0.17, 0.08))
	_add_visual_box(holder, "KitchenDoorFrameTop", Vector3(0, 16.5, -99), Vector3(68.0, 1.7, 1.0), 0.0, Color(0.32, 0.17, 0.08))
	_add_visual_box(holder, "KitchenBacksplash", Vector3(0, 5.2, 91.3), Vector3(230, 3.6, 0.35), 0.0, Color(0.54, 0.46, 0.38))
	_add_visual_box(holder, "KitchenWindowFrame", Vector3(-8, 12.5, 96.6), Vector3(54, 18.0, 0.5), 0.0, Color(0.16, 0.18, 0.2))
	_add_visual_box(holder, "KitchenWindowGlass", Vector3(-8, 12.5, 96.25), Vector3(46, 14.2, 0.55), 0.0, Color(0.66, 0.86, 1.0))
	_add_visual_box(holder, "WindowCrossbarVertical", Vector3(-8, 12.5, 95.9), Vector3(1.0, 14.8, 0.8), 0.0, Color(0.94, 0.91, 0.82))
	_add_visual_box(holder, "WindowCrossbarHorizontal", Vector3(-8, 12.5, 95.85), Vector3(47.0, 0.9, 0.8), 0.0, Color(0.94, 0.91, 0.82))
	_add_visual_box(holder, "FrontCounterBase", Vector3(0, 1.35, -84), Vector3(230, 2.7, 12), 0.0, Color(0.78, 0.72, 0.62))
	_add_visual_box(holder, "BackCounterBase", Vector3(0, 1.35, 84), Vector3(224, 2.7, 12), 0.0, Color(0.78, 0.72, 0.62))
	_add_visual_box(holder, "LeftCounterBase", Vector3(-116, 1.35, -2), Vector3(12, 2.7, 156), 0.0, Color(0.72, 0.68, 0.58))
	_add_visual_box(holder, "RightCounterBase", Vector3(122, 1.35, -2), Vector3(12, 2.7, 156), 0.0, Color(0.72, 0.68, 0.58))
	_add_visual_box(holder, "KitchenIslandBase", Vector3(22, 1.35, -36), Vector3(132, 2.7, 84), 0.0, Color(0.76, 0.69, 0.58))
	_add_visual_box(holder, "FrontCountertop", Vector3(0, 2.95, -84), Vector3(234, 0.36, 16), 0.0, Color(0.86, 0.78, 0.65))
	_add_visual_box(holder, "BackCountertop", Vector3(0, 2.95, 84), Vector3(228, 0.36, 16), 0.0, Color(0.86, 0.78, 0.65))
	_add_visual_box(holder, "LeftCountertop", Vector3(-116, 2.95, -2), Vector3(16, 0.36, 160), 0.0, Color(0.82, 0.76, 0.66))
	_add_visual_box(holder, "RightCountertop", Vector3(122, 2.95, -2), Vector3(16, 0.36, 160), 0.0, Color(0.82, 0.76, 0.66))
	_add_visual_box(holder, "KitchenIslandCountertop", Vector3(22, 2.95, -36), Vector3(140, 0.36, 92), 0.0, Color(0.88, 0.8, 0.68))
	_add_visual_box(holder, "BackUpperCabinetRun", Vector3(36, 16.0, 92), Vector3(138, 10.0, 9.0), 0.0, Color(0.42, 0.22, 0.1))
	_add_visual_box(holder, "LeftUpperCabinetRun", Vector3(-123, 15.8, -18), Vector3(8.0, 9.4, 104), 0.0, Color(0.38, 0.2, 0.09))
	_add_visual_box(holder, "RightUpperCabinetRun", Vector3(145, 15.8, -8), Vector3(8.0, 9.4, 116), 0.0, Color(0.38, 0.2, 0.09))
	_add_visual_box(holder, "RangeHood", Vector3(-118, 9.2, -24), Vector3(14.0, 5.0, 36.0), 0.0, Color(0.58, 0.6, 0.62))
	_add_visual_box(holder, "OvenDoor", Vector3(-124.4, 2.05, -24), Vector3(0.55, 3.2, 30.0), 0.0, Color(0.08, 0.08, 0.08))
	_add_visual_box(holder, "FridgeLandmark", Vector3(126, 7.0, 34), Vector3(10.0, 14.0, 38.0), 0.0, Color(0.68, 0.72, 0.76))
	_add_visual_box(holder, "FridgeFreezerLine", Vector3(120.8, 9.4, 34), Vector3(0.45, 0.35, 35.0), 0.0, Color(0.2, 0.23, 0.27))
	_add_visual_box(holder, "FridgeHandleUpper", Vector3(120.4, 10.8, 22), Vector3(0.5, 5.2, 0.7), 0.0, Color(0.9, 0.92, 0.9))
	_add_visual_box(holder, "FridgeHandleLower", Vector3(120.4, 5.0, 22), Vector3(0.5, 5.0, 0.7), 0.0, Color(0.9, 0.92, 0.9))
	_add_visual_box(holder, "IslandPendantLightA", Vector3(8, 19.5, -36), Vector3(4.0, 2.8, 4.0), 0.0, Color(1.0, 0.9, 0.68))
	_add_visual_box(holder, "IslandPendantLightB", Vector3(36, 19.5, -36), Vector3(4.0, 2.8, 4.0), 0.0, Color(1.0, 0.9, 0.68))
	_add_visual_box(holder, "PendantCordA", Vector3(8, 23.0, -36), Vector3(0.35, 5.4, 0.35), 0.0, Color(0.08, 0.08, 0.08))
	_add_visual_box(holder, "PendantCordB", Vector3(36, 23.0, -36), Vector3(0.35, 5.4, 0.35), 0.0, Color(0.08, 0.08, 0.08))

static func _build_full_size_sink(holder: Node3D) -> void:
	_add_visual_box(holder, "KitchenSinkCutout", Vector3(-8, 3.18, 88.4), Vector3(54.0, 0.08, 16.0), 0.0, Color(0.08, 0.1, 0.12))
	_add_visual_box(holder, "KitchenSinkRimFront", Vector3(-8, 3.26, 80.2), Vector3(56.0, 0.16, 0.8), 0.0, Color(0.68, 0.72, 0.72))
	_add_visual_box(holder, "KitchenSinkRimBack", Vector3(-8, 3.26, 96.6), Vector3(56.0, 0.16, 0.8), 0.0, Color(0.68, 0.72, 0.72))
	_add_visual_box(holder, "KitchenSinkRimLeft", Vector3(-36.4, 3.26, 88.4), Vector3(0.8, 0.16, 16.0), 0.0, Color(0.68, 0.72, 0.72))
	_add_visual_box(holder, "KitchenSinkRimCenter", Vector3(-8.0, 3.27, 88.4), Vector3(0.9, 0.18, 16.0), 0.0, Color(0.72, 0.76, 0.76))
	_add_visual_box(holder, "KitchenSinkRimRight", Vector3(20.4, 3.26, 88.4), Vector3(0.8, 0.16, 16.0), 0.0, Color(0.68, 0.72, 0.72))
	_add_visual_box(holder, "KitchenFaucetColumn", Vector3(-8, 4.9, 96.6), Vector3(1.2, 3.4, 1.2), 0.0, Color(0.78, 0.82, 0.82))
	_add_visual_box(holder, "KitchenFaucetSpout", Vector3(-8, 6.55, 91.6), Vector3(1.0, 0.9, 10.2), 0.0, Color(0.78, 0.82, 0.82))

static func build_dressing_preview(root: Node3D, definition: TrackDefinition) -> void:
	_build_dressing(root, definition)

static func _add_dressing_scene(parent: Node3D, definition: TrackDefinition) -> void:
	if definition.dressing_scene_path.strip_edges().is_empty():
		return
	var packed := load(definition.dressing_scene_path)
	if not (packed is PackedScene):
		push_error("Track dressing scene is not a PackedScene: %s" % definition.dressing_scene_path)
		return
	var instance := (packed as PackedScene).instantiate()
	if not (instance is Node3D):
		instance.queue_free()
		push_error("Track dressing scene root must be Node3D: %s" % definition.dressing_scene_path)
		return
	instance.name = "EditableRoom"
	_disable_gameplay_collision(instance)
	parent.add_child(instance)

static func _disable_gameplay_collision(node: Node) -> void:
	if node is CollisionShape3D:
		(node as CollisionShape3D).disabled = true
	if node is CollisionObject3D:
		var collision_object := node as CollisionObject3D
		collision_object.collision_layer = 0
		collision_object.collision_mask = 0
	for child in node.get_children():
		_disable_gameplay_collision(child)

static func _build_stage_props(parent: Node3D, definition: TrackDefinition) -> void:
	if definition.stage_props.is_empty():
		return
	var holder := Node3D.new()
	holder.name = "StageProps"
	parent.add_child(holder)
	for prop in definition.stage_props:
		_add_stage_prop(holder, prop)

static func _add_stage_prop(parent: Node3D, prop: Dictionary) -> void:
	var node_name := str(prop.get("id", "StageProp"))
	var kind := str(prop.get("kind", "box"))
	var position := _vector3_from_value(prop.get("position", Vector3.ZERO), Vector3.ZERO)
	var scale := _vector3_from_value(prop.get("scale", Vector3.ONE), Vector3.ONE)
	var yaw_degrees := float(prop.get("yaw_degrees", 0.0))
	var audio_material_id := str(prop.get("audio_material_id", ""))
	var gameplay_tag := str(prop.get("gameplay_tag", ""))
	if kind == "scene":
		var path := str(prop.get("asset_path", ""))
		var packed := load(path)
		if not (packed is PackedScene):
			return
		var instance := (packed as PackedScene).instantiate()
		if not (instance is Node3D):
			instance.queue_free()
			return
		var scene_node := instance as Node3D
		scene_node.name = node_name
		scene_node.transform = Transform3D(Basis(Vector3.UP, deg_to_rad(yaw_degrees)).scaled(scale), position)
		scene_node.set_meta("audio_material_id", audio_material_id)
		scene_node.set_meta("gameplay_tag", gameplay_tag)
		parent.add_child(scene_node)
		return
	var body := StaticBody3D.new()
	body.name = node_name
	body.transform = Transform3D(Basis(Vector3.UP, deg_to_rad(yaw_degrees)).scaled(scale), position)
	body.set_meta("audio_material_id", audio_material_id)
	body.set_meta("gameplay_tag", gameplay_tag)
	var mesh := MeshInstance3D.new()
	mesh.name = "Mesh"
	var box := BoxMesh.new()
	box.size = _vector3_from_value(prop.get("box_size", Vector3.ONE), Vector3.ONE)
	mesh.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = _color_from_value(prop.get("box_color", Color.WHITE), Color.WHITE)
	material.roughness = 0.64
	mesh.material_override = material
	body.add_child(mesh)
	if str(prop.get("collision_mode", "visual")) == "static":
		var shape_node := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = box.size
		shape_node.shape = shape
		body.add_child(shape_node)
	parent.add_child(body)

static func _add_visual_box(parent: Node3D, node_name: String, position: Vector3, size: Vector3, yaw_degrees: float, color: Color) -> void:
	var mesh := MeshInstance3D.new()
	mesh.name = node_name
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.64
	mesh.material_override = material
	mesh.transform = Transform3D(Basis(Vector3.UP, deg_to_rad(yaw_degrees)), position)
	parent.add_child(mesh)

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

static func _add_scene_instance_with_override(definition: TrackDefinition, parent: Node3D, path: String, position: Vector3, yaw_degrees: float, scale: Vector3, node_name: String) -> void:
	var override := _dressing_override(definition, node_name, position, yaw_degrees, scale)
	_add_scene_instance(parent, path, override["position"], override["yaw_degrees"], override["scale"], node_name)

static func _dressing_override(definition: TrackDefinition, node_name: String, fallback_position: Vector3, fallback_yaw_degrees: float, fallback_scale: Vector3) -> Dictionary:
	if definition == null or not definition.dressing_overrides.has(node_name):
		return {"position": fallback_position, "yaw_degrees": fallback_yaw_degrees, "scale": fallback_scale}
	var data := definition.dressing_overrides[node_name] as Dictionary
	return {
		"position": _vector3_from_value(data.get("position", fallback_position), fallback_position),
		"yaw_degrees": float(data.get("yaw_degrees", fallback_yaw_degrees)),
		"scale": _vector3_from_value(data.get("scale", fallback_scale), fallback_scale),
	}

static func _vector3_from_value(value: Variant, fallback: Vector3) -> Vector3:
	if value is Vector3:
		return value
	if value is Array and value.size() >= 3:
		return Vector3(float(value[0]), float(value[1]), float(value[2]))
	return fallback

static func _color_from_value(value: Variant, fallback: Color) -> Color:
	if value is Color:
		return value
	if value is Array and value.size() >= 4:
		return Color(float(value[0]), float(value[1]), float(value[2]), float(value[3]))
	return fallback

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

static func _point_from_gate_value(value: Variant) -> Vector3:
	if value is Vector3:
		return value
	if value is Array and value.size() >= 3:
		return Vector3(float(value[0]), float(value[1]), float(value[2]))
	return Vector3.ZERO

static func _vector3_array_from_value(value: Variant) -> Array[Vector3]:
	var points: Array[Vector3] = []
	if not (value is Array):
		return points
	for item in value:
		if item is Vector3:
			points.append(item)
		elif item is Array and item.size() >= 3:
			points.append(Vector3(float(item[0]), float(item[1]), float(item[2])))
		elif item is Dictionary:
			points.append(Vector3(float(item.get("x", 0.0)), float(item.get("y", 0.0)), float(item.get("z", 0.0))))
	return points

static func _safe_node_name(value: String) -> String:
	var out := value.strip_edges()
	if out.is_empty():
		return "Alternate"
	var parts := out.replace("-", "_").replace(" ", "_").split("_", false)
	var name := ""
	for part in parts:
		name += str(part).capitalize().replace(" ", "")
	return "Alternate" if name.is_empty() else name
