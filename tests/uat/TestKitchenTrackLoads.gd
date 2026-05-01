extends "res://tests/framework/TestCase.gd"

const TrackCatalog = preload("res://scripts/track/TrackCatalog.gd")
const TrackRuntimeBuilder = preload("res://scripts/track/TrackRuntimeBuilder.gd")
const RaceController = preload("res://scripts/RaceController.gd")
const OutOfBoundsRules = preload("res://scripts/logic/OutOfBoundsRules.gd")
const OUTDOOR_GRASS_SHADER := "res://assets/gameplay/materials/grass/playground_grass.gdshader"
const OUTDOOR_GRASS_BLADE_SHADER := "res://assets/gameplay/materials/grass/playground_grass_blades.gdshader"

func test_kitchen_track_scene_loads_with_runtime_nodes() -> void:
	var packed := load("res://assets/gameplay/tracks/kitchen/kitchen_track.tscn")
	assert_true(packed is PackedScene, "Kitchen track scene should load")
	var instance := (packed as PackedScene).instantiate()
	scene_tree.root.add_child(instance)
	var built_track := instance.get_node_or_null("BuiltTrack")
	assert_true(built_track != null, "Kitchen track scene should build runtime track")
	assert_true(instance.get_node_or_null("BuiltTrack/Road") != null, "Kitchen track should include generated road")
	assert_equal(_node_count_by_type(built_track, "WorldEnvironment"), 1, "Kitchen runtime should build exactly one WorldEnvironment")
	var world_environment := instance.get_node_or_null("BuiltTrack/WorldEnvironment") as WorldEnvironment
	assert_true(world_environment != null, "Kitchen track should include a world environment")
	if world_environment != null:
		assert_true(world_environment.environment != null, "Kitchen world environment should own an Environment resource")
		if world_environment.environment != null:
			assert_true(world_environment.environment.sky != null, "Kitchen world environment should include a sky")
			if world_environment.environment.sky != null:
				assert_true(world_environment.environment.sky.sky_material is ShaderMaterial, "Kitchen sky should use the stage sky shader material")
	assert_true(instance.get_node_or_null("BuiltTrack/SunLight") is DirectionalLight3D, "Kitchen runtime should include the stage directional light")
	var road_shape_node := instance.get_node_or_null("BuiltTrack/Road/CollisionBody/CollisionShape3D") as CollisionShape3D
	assert_true(road_shape_node != null, "Kitchen road should include collision shape")
	if road_shape_node != null:
		assert_true(road_shape_node.shape is ConcavePolygonShape3D, "Kitchen road should use generated mesh collision")
		if road_shape_node.shape is ConcavePolygonShape3D:
			assert_true((road_shape_node.shape as ConcavePolygonShape3D).backface_collision, "Kitchen road collision should be visible to camera probes from underneath")
	assert_true(instance.get_node_or_null("BuiltTrack/TrackBody") != null, "Kitchen track should include a raised visual track body")
	assert_true(instance.get_node_or_null("BuiltTrack/Rails") != null, "Kitchen track should include generated route rails")
	assert_true(_child_count(instance.get_node_or_null("BuiltTrack/Rails")) > 0, "Kitchen route rails should instantiate rail asset pieces")
	assert_true(_enabled_collision_objects(instance.get_node_or_null("BuiltTrack/Rails")) > 0, "Kitchen generated rails should be collidable")
	assert_equal(_first_material_texture_path(instance.get_node_or_null("BuiltTrack/Rails")), "res://assets/gameplay/materials/metal/toy_metal_albedo.png", "Kitchen generated rails should use the stage metal material")
	assert_true(absf(_first_material_uv_scale(instance.get_node_or_null("BuiltTrack/Rails")) - 0.5) <= 0.01, "Kitchen generated rails should use the stage rail texture UV scale")
	assert_true(instance.get_node_or_null("BuiltTrack/Walls") == null, "Kitchen track should not auto-generate route walls while guard segments are being authored")
	assert_true(instance.get_node_or_null("BuiltTrack/CheckpointSystem") != null, "Kitchen track should include checkpoint system")
	assert_true(instance.get_node_or_null("BuiltTrack/SpawnPoints") != null, "Kitchen track should include spawn points")
	assert_true(instance.get_node_or_null("BuiltTrack/ItemSockets") != null, "Kitchen track should include item sockets")
	assert_true(instance.get_node_or_null("BuiltTrack/HazardSockets") != null, "Kitchen track should include hazard sockets")
	assert_true(instance.get_node_or_null("BuiltTrack/ShortcutGates") != null, "Kitchen track should include shortcut gates")
	assert_true(instance.get_node_or_null("BuiltTrack/ShortcutSurface") == null, "Kitchen table jump surface should stay disabled while it blocks the main path")
	assert_true(instance.get_node_or_null("BuiltTrack/SurfaceSegments/FridgeTop") != null, "Kitchen track should include surface segment metadata markers")
	assert_true(instance.get_node_or_null("BuiltTrack/AudioZones/SinkSplashZone") != null, "Kitchen track should include authored audio zone markers")
	assert_true(instance.get_node_or_null("BuiltTrack/AudioZones/StoveSizzleZone") != null, "Kitchen track should include stove sizzle audio zone markers")
	assert_true(instance.get_node_or_null("BuiltTrack/SectionMarkers/SinkChicane") != null, "Kitchen track should include named layout section markers")
	assert_true(instance.get_node_or_null("BuiltTrack/SectionMarkers/FridgeTopRun") != null, "Kitchen track should include the fridge-top route section marker")
	assert_true(instance.get_node_or_null("BuiltTrack/FloorVisual") != null, "Kitchen track should include a non-colliding floor visual below the counter")
	assert_true(instance.get_node_or_null("BuiltTrack/FloorTileGrid") != null, "Kitchen floor should include visible tile grid lines for room scale")
	assert_true(_node_position(instance, "BuiltTrack/FloorVisual").y <= -8.0, "Kitchen floor visual should be far below the countertop route")
	assert_true(instance.get_node_or_null("BuiltTrack/Ground") == null, "Kitchen floor should not be a colliding ground plane")
	assert_true(instance.get_node_or_null("BuiltTrack/Dressing/KitchenCeiling") == null, "Kitchen runtime should not add old hardcoded ceiling geometry over authored room scale")
	assert_true(instance.get_node_or_null("BuiltTrack/Dressing/FridgeLandmark") == null, "Kitchen runtime should not duplicate old hardcoded fridge geometry over authored room scale")
	assert_true(instance.get_node_or_null("BuiltTrack/Dressing/EditableRoom") != null, "Kitchen track should include the directly editable room scene")
	assert_true(instance.get_node_or_null("BuiltTrack/Dressing/EditableRoom/RoutePoints/RoutePoint00") != null, "Editable room scene should expose editable route points")
	assert_true(instance.get_node_or_null("BuiltTrack/Dressing/EditableRoom/RoutePoints/rail") == null, "Editable room route points should not contain generated rail instances")
	assert_true(instance.get_node_or_null("BuiltTrack/Dressing/EditableRoom/SpawnPoints/Start01") != null, "Editable room scene should expose editable spawn points")
	assert_true(instance.get_node_or_null("BuiltTrack/Dressing/EditableRoom/Checkpoints/Checkpoint00_LapGate") != null, "Editable room scene should expose editable checkpoints")
	assert_true(instance.get_node_or_null("BuiltTrack/Dressing/EditableRoom/ItemSockets/ItemSocket01") != null, "Editable room scene should expose editable item sockets")
	assert_true(instance.get_node_or_null("BuiltTrack/Dressing/EditableRoom/floor") != null, "Editable room scene should include the authored floor")
	assert_true(not (instance.get_node_or_null("BuiltTrack/Dressing/EditableRoom/floor") is CollisionObject3D), "Editable room floor should be visual-only so it cannot block the course")
	assert_true(_node_position(instance, "BuiltTrack/Dressing/EditableRoom/floor").y <= -32.0, "Editable room floor should stay below the playable course")
	assert_true(instance.get_node_or_null("BuiltTrack/Dressing/EditableRoom/RoomShell/BackWall") != null, "Editable room scene should include selectable room shell pieces")
	assert_true(not _node_visible(instance, "BuiltTrack/Dressing/EditableRoom/RoomShell/BackWall"), "Kitchen back wall should be split around the window instead of blocking the view")
	assert_true(instance.get_node_or_null("BuiltTrack/Dressing/EditableRoom/RoomShell/BackWallLeftOfWindow") != null, "Kitchen window should keep editable wall trim on the left")
	assert_true(instance.get_node_or_null("BuiltTrack/Dressing/EditableRoom/RoomShell/BackWallRightOfWindow") != null, "Kitchen window should keep editable wall trim on the right")
	assert_true(_mesh_material_alpha(instance, "BuiltTrack/Dressing/EditableRoom/RoomShell/WindowGlass") <= 0.15, "Kitchen window glass should be transparent enough for sky visibility")
	assert_true(instance.get_node_or_null("BuiltTrack/Dressing/EditableRoom/Appliances/kitchenSink") != null, "Editable room scene should preserve hand-placed kitchen props")
	assert_true(instance.get_node_or_null("BuiltTrack/Dressing/EditableRoom/WaterSurfaces/SinkWater") != null, "Editable room scene should include authored sink water")
	assert_true(_node_position(instance, "BuiltTrack/Dressing/EditableRoom/WaterSurfaces/SinkWater").distance_to(Vector3(-87.55, 4.35, 73.55)) <= 0.05, "Kitchen sink water should sit on the authored sink pair")
	assert_true(instance.get_node_or_null("BuiltTrack/Dressing/EditableRoom/WaterSurfaces/WasherWater") != null, "Editable room scene should include authored washer water")
	assert_true(_node_has_script(instance, "BuiltTrack/Dressing/EditableRoom/washer"), "Editable room washer should run its in-place rumble script")
	assert_true(_node_has_script(instance, "BuiltTrack/Dressing/EditableRoom/dryer"), "Editable room dryer should run its in-place rumble script")
	assert_true(instance.get_node_or_null("BuiltTrack/Dressing/EditableRoom/UpperCabinets") != null, "Editable room scene should preserve authored upper cabinet grouping")
	assert_equal(_enabled_collision_objects(instance.get_node_or_null("BuiltTrack/Dressing/EditableRoom")), 0, "Editable room dressing should not collide with the kart")
	assert_equal(instance.get_node_or_null("BuiltTrack/Dressing").get_child_count(), 1, "Kitchen runtime dressing should only instantiate the editable room")
	assert_true(instance.get_node_or_null("BuiltTrack/Dressing/StageProps") == null, "Kitchen runtime should not instantiate metadata stage props")
	assert_true(instance.get_node_or_null("BuiltTrack/Dressing/KitchenTable") == null, "Kitchen runtime should not add hardcoded kitchen table dressing")
	assert_true(instance.get_node_or_null("BuiltTrack/Dressing/KitchenSink") == null, "Kitchen runtime should not add hardcoded sink dressing")
	assert_true(instance.get_node_or_null("BuiltTrack/Dressing/SpoonHazard") == null, "Kitchen runtime should not add hardcoded food hazards")
	assert_true(instance.get_node_or_null("BuiltTrack/Dressing/FridgeTopSpeedStrip") == null, "Kitchen runtime should not add hardcoded route stripes")
	instance.queue_free()

func test_kitchen_authoring_scene_builds_editor_preview() -> void:
	var packed := load("res://assets/gameplay/tracks/kitchen/kitchen_authoring.tscn")
	assert_true(packed is PackedScene, "Kitchen authoring scene should load")
	var instance := (packed as PackedScene).instantiate()
	scene_tree.root.add_child(instance)
	assert_true(instance.has_method("refresh_preview"), "Kitchen authoring root should expose preview refresh")
	assert_true(instance.has_method("sync_markers_from_definition"), "Kitchen authoring root should expose marker sync")
	assert_true(instance.has_method("apply_markers_to_definition"), "Kitchen authoring root should expose definition export")
	assert_true(instance.has_method("export_metadata"), "Kitchen authoring root should expose metadata export")
	assert_true(instance.has_method("validate_authoring"), "Kitchen authoring root should expose authoring validation")
	var summary := instance.call("get_authoring_summary") as Dictionary
	assert_equal(int(summary.get("route_points", 0)), 38, "Kitchen builder should report editable route points")
	assert_equal(int(summary.get("spawn_points", 0)), 8, "Kitchen builder should report editable spawn points")
	assert_equal(int(summary.get("checkpoints", 0)), 6, "Kitchen builder should report editable checkpoints")
	assert_true(int(summary.get("dressing_props", 0)) >= 10, "Kitchen builder should report selectable editable dressing props")
	assert_equal(int(summary.get("surface_segments", 0)), 3, "Kitchen builder should report editable surface segments")
	assert_equal(int(summary.get("audio_zones", 0)), 4, "Kitchen builder should report editable audio zones")
	assert_equal((instance.call("validate_authoring") as Array).size(), 0, "Kitchen authoring markers should validate against track rules")
	instance.set("preview_enabled", true)
	instance.call("refresh_preview")
	assert_true(instance.get_node_or_null("EditorTrackPreview/PreviewCounterSurface") == null, "Authoring preview should not ghost the room surface")
	assert_true(instance.get_node_or_null("EditorTrackPreview/PreviewTrackBody") != null, "Authoring preview should include the raised track body")
	assert_true(instance.get_node_or_null("EditorTrackPreview/PreviewRoad") != null, "Authoring preview should include generated road")
	assert_true(instance.get_node_or_null("EditorTrackPreview/PreviewRails") != null, "Authoring preview should include generated rails")
	assert_true(instance.get_node_or_null("EditorTrackPreview/PreviewWalls") == null, "Authoring preview should keep auto wall preview off by default")
	assert_true(instance.get_node_or_null("EditorTrackPreview/PreviewHeightGuides/RouteHeight00") == null, "Authoring preview should not ghost height guides")
	assert_true(instance.get_node_or_null("EditorTrackPreview/PreviewHeightGuides/OverUnderGap04") == null, "Authoring preview should not show old over-under gap markers on the flattened room route")
	assert_true(instance.get_node_or_null("EditorTrackPreview/PreviewMarkers/RoutePoints/RoutePoint00") == null, "Authoring preview should not ghost marker blocks")
	assert_true(instance.get_node_or_null("EditorTrackPreview/PreviewMarkers/RoutePoints/RoutePoint00_Label") == null, "Authoring preview should keep position labels off by default so they do not block the scene")
	assert_true(instance.get_node_or_null("EditorTrackPreview/PreviewMarkers/ItemSockets/ItemSocket01") == null, "Authoring preview should not ghost item socket markers")
	assert_true(instance.get_node_or_null("EditorTrackPreview/PreviewMarkers/SurfaceSegments/CountertopMain") == null, "Authoring preview should not ghost surface segment markers")
	assert_true(instance.get_node_or_null("EditorTrackPreview/PreviewMarkers/AudioZones/SinkSplashZone") == null, "Authoring preview should not ghost audio zone markers")
	assert_true(instance.get_node_or_null("EditorTrackPreview/PreviewMarkers/AudioZones/StoveSizzleZone") == null, "Authoring preview should not ghost stove audio zone markers")
	assert_true(instance.get_node_or_null("EditorTrackPreview/PreviewDressingLayout/Dressing/EditableRoom") == null, "Authoring preview should not ghost the editable room dressing layout")
	assert_true(instance.get_node_or_null("EditorTrackPreview/PreviewDressingLayout/Dressing/KitchenSink") == null, "Authoring preview should not add legacy runtime dressing")
	assert_true(instance.get_node_or_null("Dressing/KitchenSink") != null, "Authoring scene should include an editable KitchenSink dressing marker")
	assert_true(instance.get_node_or_null("Dressing/KitchenSink").has_method("to_stage_prop"), "Kitchen sink should be a selectable stage prop authoring node")
	assert_true(instance.get_node_or_null("Dressing/FridgeLandmark").has_method("to_stage_prop"), "Kitchen fridge should be a selectable stage prop authoring node")
	assert_true(instance.get_node_or_null("SurfaceSegments/FridgeTop").has_method("to_surface_segment"), "Kitchen surface segments should export authoring data")
	assert_true(instance.get_node_or_null("AudioZones/SinkSplashZone").has_method("to_audio_zone"), "Kitchen audio zones should export authoring data")
	assert_true(instance.get_node_or_null("EditorTrackPreview/PreviewDressingLayout/DressingLabels/EditableRoom_Label") == null, "Authoring preview should keep dressing labels off by default")
	instance.set("show_marker_labels", true)
	instance.call("refresh_preview")
	assert_true(instance.get_node_or_null("EditorTrackPreview/PreviewMarkers/RoutePoints/RoutePoint00_Label") == null, "Authoring preview should not label marker ghosts")
	assert_true(instance.get_node_or_null("EditorTrackPreview/PreviewDressingLayout/DressingLabels/EditableRoom_Label") == null, "Authoring preview should not label dressing ghosts")
	instance.queue_free()

func test_outdoor_playground_runtime_uses_grass_shader() -> void:
	var definition := TrackCatalog.get_definition("outdoor_playground")
	assert_true(definition != null, "Outdoor Playground definition should load")
	var built := TrackRuntimeBuilder.build(definition)
	var track_node := built.get("node", null) as Node3D
	scene_tree.root.add_child(track_node)
	assert_equal(_mesh_shader_path(track_node, "FloorVisual"), OUTDOOR_GRASS_SHADER, "Outdoor Playground generated floor should use the grass shader")
	assert_equal(_mesh_shader_path(track_node, "Dressing/EditableRoom/floor/MeshInstance3D"), OUTDOOR_GRASS_SHADER, "Outdoor Playground editable floor should use the grass shader at runtime")
	assert_true(track_node.get_node_or_null("PlaygroundGrassBlades") is MultiMeshInstance3D, "Outdoor Playground should build an upright grass blade layer")
	assert_true(_multimesh_instance_count(track_node, "PlaygroundGrassBlades") >= 18000, "Outdoor Playground grass should use enough blades to read as grass from kart height")
	assert_equal(_multimesh_shader_path(track_node, "PlaygroundGrassBlades"), OUTDOOR_GRASS_BLADE_SHADER, "Outdoor Playground grass blades should use the blade sway shader")
	assert_true(_first_multimesh_instance_y(track_node, "PlaygroundGrassBlades") > definition.floor_visual_y + 10.0, "Outdoor Playground grass blades should sit on the authored visible floor, not the lower reset plane")
	track_node.queue_free()

func test_car_can_be_placed_on_kitchen_start_grid() -> void:
	var definition := TrackCatalog.get_definition("kitchen")
	var built := TrackRuntimeBuilder.build(definition)
	var track_node := built.get("node", null) as Node3D
	scene_tree.root.add_child(track_node)
	var spawns: Array = built.get("spawns", [])
	var route_points: Array[Vector3] = []
	for point in built.get("waypoints", definition.route_points):
		if point is Vector3:
			route_points.append(point)
	assert_true(spawns.size() >= 8, "Kitchen builder should return 8 spawn transforms")
	for spawn in spawns:
		if spawn is Transform3D:
			var distance := _distance_to_route_xz((spawn as Transform3D).origin, route_points, definition.closed_loop)
			assert_true(distance <= definition.road_width * 0.5 + 0.1, "Kitchen start grid should place every spawn on the road")
	var car_scene := load("res://scenes/Car.tscn")
	assert_true(car_scene is PackedScene, "Car scene should load")
	var car := (car_scene as PackedScene).instantiate() as Node3D
	scene_tree.root.add_child(car)
	car.global_transform = spawns[0]
	assert_true(car.global_transform.origin.distance_to((spawns[0] as Transform3D).origin) < 0.01, "Car should be placeable on the Kitchen start grid")
	car.queue_free()
	track_node.queue_free()

func test_kitchen_out_of_bounds_instant_pop_reset() -> void:
	var definition := TrackCatalog.get_definition("kitchen")
	assert_true(not OutOfBoundsRules.should_reset(-10.0, definition.out_of_bounds_y, definition.reset_mode), "Driving on the authored floor should not auto-reset")
	assert_true(OutOfBoundsRules.should_reset(definition.out_of_bounds_y - 0.5, definition.out_of_bounds_y, definition.reset_mode), "Falling below the floor should trigger Kitchen reset")
	var car_scene := load("res://scenes/Car.tscn")
	assert_true(car_scene is PackedScene, "Car scene should load")
	var car := (car_scene as PackedScene).instantiate() as CharacterBody3D
	scene_tree.root.add_child(car)
	car.global_transform.origin = Vector3(0, 0.2, 0)
	car.velocity = Vector3(4, -8, 2)
	var reset_transform := Transform3D(Basis(Vector3.UP, deg_to_rad(90.0)), Vector3(-82, 3.8, -79))
	RaceController.apply_instant_reset(car, reset_transform)
	assert_equal(car.global_transform.origin, reset_transform.origin, "Instant pop reset should move the car back to the safe transform")
	assert_equal(car.velocity, Vector3.ZERO, "Instant pop reset should stop the car")
	car.queue_free()

func test_manual_return_uses_last_road_center_point() -> void:
	var definition := TrackCatalog.get_definition("kitchen")
	var off_course_position := definition.route_points[3] + Vector3(18.0, 0.0, 0.0)
	var reset_transform := RaceController.centered_track_return_transform(definition.route_points, off_course_position, definition.closed_loop)
	var distance := _distance_to_route_xz(reset_transform.origin, definition.route_points, definition.closed_loop)
	assert_true(distance <= 0.01, "Manual return transform should land on the route centerline")
	assert_true(absf(reset_transform.origin.y - (definition.route_points[3].y + 1.0)) < 0.2, "Manual return transform should preserve the road height plus kart clearance")

func _distance_to_route_xz(point: Vector3, route_points: Array[Vector3], closed_loop: bool) -> float:
	var best := INF
	var segment_count := route_points.size() if closed_loop else route_points.size() - 1
	for i in range(segment_count):
		best = minf(best, _distance_to_segment_xz(point, route_points[i], route_points[(i + 1) % route_points.size()]))
	return best

func _distance_to_segment_xz(point: Vector3, a3: Vector3, b3: Vector3) -> float:
	var point_2d := Vector2(point.x, point.z)
	var a := Vector2(a3.x, a3.z)
	var b := Vector2(b3.x, b3.z)
	var ab := b - a
	var length_squared := ab.length_squared()
	if length_squared <= 0.0001:
		return point_2d.distance_to(a)
	var t := clampf((point_2d - a).dot(ab) / length_squared, 0.0, 1.0)
	return point_2d.distance_to(a + ab * t)

func _node_scale_x(root: Node, path: NodePath) -> float:
	var node := root.get_node_or_null(path) as Node3D
	if node == null:
		return 0.0
	return node.transform.basis.get_scale().x

func _node_position(root: Node, path: NodePath) -> Vector3:
	var node := root.get_node_or_null(path) as Node3D
	if node == null:
		return Vector3.ZERO
	return node.transform.origin

func _node_visible(root: Node, path: NodePath) -> bool:
	var node := root.get_node_or_null(path) as Node3D
	if node == null:
		return false
	return node.visible

func _node_has_script(root: Node, path: NodePath) -> bool:
	var node := root.get_node_or_null(path)
	return node != null and node.get_script() != null

func _box_size_x(root: Node, path: NodePath) -> float:
	var mesh_instance := root.get_node_or_null(path) as MeshInstance3D
	if mesh_instance == null or not (mesh_instance.mesh is BoxMesh):
		return 0.0
	return (mesh_instance.mesh as BoxMesh).size.x

func _box_size_y(root: Node, path: NodePath) -> float:
	var mesh_instance := root.get_node_or_null(path) as MeshInstance3D
	if mesh_instance == null or not (mesh_instance.mesh is BoxMesh):
		return 0.0
	return (mesh_instance.mesh as BoxMesh).size.y

func _child_count(node: Node) -> int:
	if node == null:
		return 0
	return node.get_child_count()

func _first_material_texture_path(node: Node) -> String:
	if node == null:
		return ""
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.material_override is StandardMaterial3D:
			var material := mesh_instance.material_override as StandardMaterial3D
			if material.albedo_texture != null:
				return material.albedo_texture.resource_path
	for child in node.get_children():
		var found := _first_material_texture_path(child)
		if not found.is_empty():
			return found
	return ""

func _first_material_uv_scale(node: Node) -> float:
	if node == null:
		return 0.0
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.material_override is StandardMaterial3D:
			return (mesh_instance.material_override as StandardMaterial3D).uv1_scale.x
	for child in node.get_children():
		var found := _first_material_uv_scale(child)
		if found > 0.0:
			return found
	return 0.0

func _enabled_collision_objects(node: Node) -> int:
	if node == null:
		return 0
	var count := 0
	if node is CollisionObject3D:
		var collision_object := node as CollisionObject3D
		if collision_object.collision_layer != 0 or collision_object.collision_mask != 0:
			count += 1
	if node is CollisionShape3D and not (node as CollisionShape3D).disabled:
		count += 1
	for child in node.get_children():
		count += _enabled_collision_objects(child)
	return count

func _node_count_by_type(node: Node, type_name: String) -> int:
	if node == null:
		return 0
	var count := 1 if node.is_class(type_name) else 0
	for child in node.get_children():
		count += _node_count_by_type(child, type_name)
	return count

func _mesh_material_alpha(root: Node, path: NodePath) -> float:
	var mesh := root.get_node_or_null(path) as MeshInstance3D
	if mesh == null:
		return 1.0
	var material := mesh.material_override
	if material is StandardMaterial3D:
		return (material as StandardMaterial3D).albedo_color.a
	return 1.0

func _mesh_shader_path(root: Node, path: NodePath) -> String:
	var mesh := root.get_node_or_null(path) as MeshInstance3D
	if mesh == null:
		return ""
	if mesh.material_override is ShaderMaterial:
		var material := mesh.material_override as ShaderMaterial
		if material.shader != null:
			return material.shader.resource_path
	return ""

func _multimesh_instance_count(root: Node, path: NodePath) -> int:
	var instance := root.get_node_or_null(path) as MultiMeshInstance3D
	if instance == null or instance.multimesh == null:
		return 0
	return instance.multimesh.instance_count

func _multimesh_shader_path(root: Node, path: NodePath) -> String:
	var instance := root.get_node_or_null(path) as MultiMeshInstance3D
	if instance == null or instance.multimesh == null or instance.multimesh.mesh == null:
		return ""
	var material := instance.multimesh.mesh.surface_get_material(0)
	if material is ShaderMaterial:
		var shader_material := material as ShaderMaterial
		if shader_material.shader != null:
			return shader_material.shader.resource_path
	return ""

func _first_multimesh_instance_y(root: Node, path: NodePath) -> float:
	var instance := root.get_node_or_null(path) as MultiMeshInstance3D
	if instance == null or instance.multimesh == null or instance.multimesh.instance_count == 0:
		return -INF
	return instance.multimesh.get_instance_transform(0).origin.y
