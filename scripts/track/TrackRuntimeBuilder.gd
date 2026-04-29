extends RefCounted
class_name TrackRuntimeBuilder

const CheckpointAreaScript = preload("res://scripts/CheckpointArea.gd")
const CheckpointSystemScript = preload("res://scripts/CheckpointSystem.gd")
const FinishLineAreaScript = preload("res://scripts/FinishLineArea.gd")
const RoadMeshScript = preload("res://scripts/RoadMesh.gd")
const TrackDefinition = preload("res://scripts/track/TrackDefinition.gd")
const TrackRibbonMesh = preload("res://scripts/track/TrackRibbonMesh.gd")
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
	_build_track_body(root, definition)
	_build_road(root, definition)
	var spawns := _build_spawns(root, definition)
	var waypoints := _build_waypoints(root, definition)
	_build_checkpoints(root, definition)
	_build_sockets(root, "ItemSockets", definition.item_sockets)
	_build_sockets(root, "HazardSockets", definition.hazard_sockets)
	_build_shortcuts(root, definition)
	_build_section_markers(root, definition)
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
	visual.transform.origin = Vector3(0, 0.0 if floor_is_out_of_bounds else -0.1, 0)
	var material := StandardMaterial3D.new()
	material.albedo_color = definition.ground_color
	material.roughness = 0.72
	if not definition.ground_texture_path.is_empty():
		var texture := load(definition.ground_texture_path)
		if texture is Texture2D:
			material.albedo_texture = texture
	visual.material_override = material
	root.add_child(visual)

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
		if definition.id == "kitchen" and id == "table_jump":
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

static func _build_audio_zones(root: Node3D) -> void:
	var holder := Node3D.new()
	holder.name = "AudioZones"
	root.add_child(holder)

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
	_add_section_marker(holder, "FridgeClimb", Vector3(122, 10.5, -18))
	_add_section_marker(holder, "FridgeTopRun", Vector3(128, 15.1, 34))
	_add_section_marker(holder, "FridgeCorner", Vector3(104, 9.4, 74))

static func _add_section_marker(parent: Node3D, marker_name: String, position: Vector3) -> void:
	var marker := Marker3D.new()
	marker.name = marker_name
	marker.transform.origin = position
	parent.add_child(marker)

static func _build_dressing(root: Node3D, definition: TrackDefinition) -> void:
	var holder := Node3D.new()
	holder.name = "Dressing"
	root.add_child(holder)
	if definition.id != "kitchen":
		return
	_build_full_size_kitchen_room(holder)
	_add_visual_box(holder, "StartFinishTape", Vector3(-48, 3.45, -79.4), Vector3(1.9, 0.06, 13.0), -4.0, Color(0.04, 0.04, 0.04))
	_add_visual_box(holder, "UnderCabinetLedStrip", Vector3(-12, 3.25, -77.8), Vector3(92.0, 0.08, 0.7), 0.0, Color(0.3, 0.92, 1.0))
	_add_visual_box(holder, "StoveHeatZone", Vector3(-98, 3.58, -24), Vector3(15.0, 0.06, 32.0), -18.0, Color(1.0, 0.34, 0.12))
	_add_visual_box(holder, "IslandSweeperBankStripe", Vector3(28, 5.72, -55), Vector3(72.0, 0.06, 1.6), -5.0, Color(0.18, 0.62, 1.0))
	_add_visual_box(holder, "BackStraightSpeedStrip", Vector3(112, 4.55, 10), Vector3(1.7, 0.06, 78.0), 0.0, Color(1.0, 0.9, 0.2))
	_add_visual_box(holder, "SinkChicaneWetStrip", Vector3(-8, 4.04, 74), Vector3(58.0, 0.06, 1.7), 4.0, Color(0.2, 0.62, 0.95))
	_add_visual_box(holder, "FridgeTopSpeedStrip", Vector3(128, 15.05, 34), Vector3(1.5, 0.06, 36.0), 0.0, Color(0.7, 0.86, 1.0))
	_add_visual_box(holder, "FridgeCornerRecoveryStripe", Vector3(104, 9.35, 74), Vector3(24.0, 0.06, 14.0), -20.0, Color(0.7, 0.86, 1.0))
	_add_visual_box(holder, "StoveCooktop", Vector3(-118, 3.02, -24), Vector3(12.0, 0.08, 34.0), 0.0, Color(0.02, 0.02, 0.02))
	_add_scene_instance(holder, "res://assets/source/kenney/furniture_kit/table.glb", Vector3(24, 1.7, -34), 8.0, Vector3(7.8, 7.8, 7.8), "KitchenTable")
	_add_scene_instance(holder, "res://assets/source/kenney/furniture_kit/pottedPlant.glb", Vector3(20, 3.0, -34), 15.0, Vector3(7.0, 7.0, 7.0), "IslandPlanter")
	_add_scene_instance(holder, "res://assets/source/kenney/furniture_kit/kitchenSink.glb", Vector3(-8, 2.15, 88), 180.0, Vector3(10.5, 10.5, 10.5), "KitchenSink")
	_build_full_size_sink(holder)
	_add_scene_instance(holder, "res://assets/source/kenney/furniture_kit/kitchenCabinet.glb", Vector3(-118, 2.15, -24), 90.0, Vector3(7.0, 7.0, 7.0), "OvenCabinet")
	_add_scene_instance(holder, "res://assets/source/kenney/furniture_kit/kitchenCabinetDrawer.glb", Vector3(-38, 2.1, 90), 180.0, Vector3(6.8, 6.8, 6.8), "BackCounterCabinetLeft")
	_add_scene_instance(holder, "res://assets/source/kenney/furniture_kit/kitchenCabinetDrawer.glb", Vector3(42, 2.1, 90), 180.0, Vector3(6.8, 6.8, 6.8), "BackCounterCabinetRight")
	_add_scene_instance(holder, "res://assets/source/kenney/food_kit/cooking-spoon.glb", Vector3(-8, 4.1, 72), 92.0, Vector3(8.0, 8.0, 8.0), "SpoonHazard")
	_add_scene_instance(holder, "res://assets/source/kenney/food_kit/cutting-board.glb", Vector3(18, 5.25, 0), 116.0, Vector3(7.0, 7.0, 7.0), "CuttingBoard")
	_add_scene_instance(holder, "res://assets/source/kenney/food_kit/cup.glb", Vector3(-36, 3.52, -78), 90.0, Vector3(6.4, 6.4, 6.4), "FrontCupHazard")
	_add_scene_instance(holder, "res://assets/source/kenney/food_kit/apple.glb", Vector3(24, 3.6, -78), 18.0, Vector3(6.2, 6.2, 6.2), "RollingAppleHazard")
	_add_scene_instance(holder, "res://assets/source/kenney/food_kit/bowl.glb", Vector3(80, 3.8, -57), 130.0, Vector3(4.2, 4.2, 4.2), "ShortcutBowlMarker")
	_add_scene_instance(holder, "res://assets/source/kenney/food_kit/cooking-knife.glb", Vector3(-98, 3.95, -40), -34.0, Vector3(6.0, 6.0, 6.0), "OvenKnifeGate")
	_add_scene_instance(holder, "res://assets/source/meshy/2026-04-27-character-track-batch/sir_clink/landmark_set.glb", Vector3(-40, 4.45, 74), 35.0, Vector3(2.2, 2.2, 2.2), "SirClinkLandmark")

static func _build_full_size_kitchen_room(holder: Node3D) -> void:
	_add_visual_box(holder, "KitchenBackWall", Vector3(0, 16.0, 98), Vector3(252, 32.0, 2.0), 0.0, Color(0.62, 0.57, 0.49))
	_add_visual_box(holder, "KitchenLeftWall", Vector3(-128, 16.0, 0), Vector3(2.0, 32.0, 196), 0.0, Color(0.58, 0.54, 0.48))
	_add_visual_box(holder, "KitchenRightWall", Vector3(128, 16.0, 0), Vector3(2.0, 32.0, 196), 0.0, Color(0.58, 0.54, 0.48))
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
	_add_visual_box(holder, "RightUpperCabinetRun", Vector3(127, 15.8, -8), Vector3(8.0, 9.4, 116), 0.0, Color(0.38, 0.2, 0.09))
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
