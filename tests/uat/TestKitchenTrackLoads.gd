extends "res://tests/framework/TestCase.gd"

const TrackCatalog = preload("res://scripts/track/TrackCatalog.gd")
const TrackRuntimeBuilder = preload("res://scripts/track/TrackRuntimeBuilder.gd")
const RaceController = preload("res://scripts/RaceController.gd")
const OutOfBoundsRules = preload("res://scripts/logic/OutOfBoundsRules.gd")

func test_kitchen_track_scene_loads_with_runtime_nodes() -> void:
	var packed := load("res://assets/gameplay/tracks/kitchen/kitchen_track.tscn")
	assert_true(packed is PackedScene, "Kitchen track scene should load")
	var instance := (packed as PackedScene).instantiate()
	scene_tree.root.add_child(instance)
	var built_track := instance.get_node_or_null("BuiltTrack")
	assert_true(built_track != null, "Kitchen track scene should build runtime track")
	assert_true(instance.get_node_or_null("BuiltTrack/Road") != null, "Kitchen track should include generated road")
	var road_shape_node := instance.get_node_or_null("BuiltTrack/Road/CollisionBody/CollisionShape3D") as CollisionShape3D
	assert_true(road_shape_node != null, "Kitchen road should include collision shape")
	if road_shape_node != null:
		assert_true(road_shape_node.shape is ConcavePolygonShape3D, "Kitchen road should use generated mesh collision")
		if road_shape_node.shape is ConcavePolygonShape3D:
			assert_true((road_shape_node.shape as ConcavePolygonShape3D).backface_collision, "Kitchen road collision should be visible to camera probes from underneath")
	assert_true(instance.get_node_or_null("BuiltTrack/TrackBody") != null, "Kitchen track should include a raised visual track body")
	assert_true(instance.get_node_or_null("BuiltTrack/Walls") == null, "Kitchen track should not auto-generate route walls while guard segments are being authored")
	assert_true(instance.get_node_or_null("BuiltTrack/CheckpointSystem") != null, "Kitchen track should include checkpoint system")
	assert_true(instance.get_node_or_null("BuiltTrack/SpawnPoints") != null, "Kitchen track should include spawn points")
	assert_true(instance.get_node_or_null("BuiltTrack/ItemSockets") != null, "Kitchen track should include item sockets")
	assert_true(instance.get_node_or_null("BuiltTrack/HazardSockets") != null, "Kitchen track should include hazard sockets")
	assert_true(instance.get_node_or_null("BuiltTrack/ShortcutGates") != null, "Kitchen track should include shortcut gates")
	assert_true(instance.get_node_or_null("BuiltTrack/ShortcutSurface") == null, "Kitchen table jump surface should stay disabled while it blocks the main path")
	assert_true(instance.get_node_or_null("BuiltTrack/SurfaceSegments/FridgeTop") != null, "Kitchen track should include surface segment metadata markers")
	assert_true(instance.get_node_or_null("BuiltTrack/AudioZones/SinkSplashZone") != null, "Kitchen track should include authored audio zone markers")
	assert_true(instance.get_node_or_null("BuiltTrack/SectionMarkers/SinkChicane") != null, "Kitchen track should include named layout section markers")
	assert_true(instance.get_node_or_null("BuiltTrack/SectionMarkers/FridgeTopRun") != null, "Kitchen track should include the fridge-top route section marker")
	assert_true(instance.get_node_or_null("BuiltTrack/FloorVisual") != null, "Kitchen track should include a non-colliding floor visual below the counter")
	assert_true(_node_position(instance, "BuiltTrack/FloorVisual").y <= -8.0, "Kitchen floor visual should be far below the countertop route")
	assert_true(instance.get_node_or_null("BuiltTrack/Ground") == null, "Kitchen floor should not be a colliding ground plane")
	assert_true(instance.get_node_or_null("BuiltTrack/Dressing/KitchenCeiling") == null, "Kitchen runtime should not add old hardcoded ceiling geometry over authored room scale")
	assert_true(instance.get_node_or_null("BuiltTrack/Dressing/FridgeLandmark") == null, "Kitchen runtime should not duplicate old hardcoded fridge geometry over authored room scale")
	assert_true(instance.get_node_or_null("BuiltTrack/Dressing/StageProps/FrontCabinetBase") != null, "Kitchen track should include authored front cabinet base")
	assert_true(instance.get_node_or_null("BuiltTrack/Dressing/StageProps/IslandCabinetBase") != null, "Kitchen track should include authored island cabinet base")
	assert_true(instance.get_node_or_null("BuiltTrack/Dressing/StageProps/KitchenBackWall") != null, "Kitchen track should include authored full-size room walls")
	assert_true(instance.get_node_or_null("BuiltTrack/Dressing/StageProps/KitchenLeftWall") != null, "Kitchen track should include an authored full-size left wall")
	assert_true(instance.get_node_or_null("BuiltTrack/Dressing/StageProps/KitchenRightWall") != null, "Kitchen track should include an authored full-size right wall")
	assert_true(_node_position(instance, "BuiltTrack/Dressing/StageProps/KitchenRightWall").x > 140.0, "Kitchen right wall should contain the fridge-top road width")
	assert_true(instance.get_node_or_null("BuiltTrack/Dressing/StageProps/KitchenCeiling") != null, "Kitchen track should include an authored full-size ceiling")
	assert_true(_node_position(instance, "BuiltTrack/Dressing/StageProps/KitchenCeiling").y > 50.0, "Kitchen ceiling should sit high above the toy-scale counter")
	assert_true(instance.get_node_or_null("BuiltTrack/Dressing/StageProps/FrontCountertop") != null, "Kitchen track should include authored countertop surfaces for toy scale")
	assert_true(instance.get_node_or_null("BuiltTrack/Dressing/KitchenSink") != null, "Kitchen track should include a life-sized sink landmark")
	assert_true(instance.get_node_or_null("BuiltTrack/Dressing/StageProps/KitchenSink") != null, "Kitchen runtime should include scene-authored sink prop data")
	assert_true(instance.get_node_or_null("BuiltTrack/Dressing/StageProps/FridgeLandmark") != null, "Kitchen runtime should include scene-authored fridge prop data")
	assert_true(_node_scale_x(instance, "BuiltTrack/Dressing/KitchenSink") >= 10.0, "Kitchen sink asset should be scaled up compared to toy racers")
	assert_true(_box_size_x(instance, "BuiltTrack/Dressing/KitchenSinkCutout") > 50.0, "Kitchen sink basin should read as full-sized on the counter")
	assert_true(_box_size_y(instance, "BuiltTrack/Dressing/KitchenFaucetColumn") > 3.0, "Kitchen faucet should be tall enough to read as full-sized")
	assert_true(instance.get_node_or_null("BuiltTrack/Dressing/OvenCabinet") != null, "Kitchen track should include a life-sized oven cabinet landmark")
	assert_true(instance.get_node_or_null("BuiltTrack/Dressing/StageProps/KitchenIslandCountertop") != null, "Kitchen track should include the central island footprint")
	assert_true(instance.get_node_or_null("BuiltTrack/Dressing/FridgeTopSpeedStrip") != null, "Kitchen track should dress the fridge-top route")
	assert_true(_node_position(instance, "BuiltTrack/Dressing/ShortcutBowlMarker").distance_to(Vector3(70, 3.8, -66)) > 8.0, "Shortcut bowl marker should sit beside the ramp entry instead of blocking it")
	assert_true(instance.get_node_or_null("BuiltTrack/Dressing/StoveHeatZone") != null, "Kitchen track should include a stove hairpin visual zone")
	assert_true(instance.get_node_or_null("BuiltTrack/Dressing/SinkChicaneWetStrip") != null, "Kitchen track should include a sink chicane visual zone")
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
	assert_equal(int(summary.get("audio_zones", 0)), 3, "Kitchen builder should report editable audio zones")
	assert_equal((instance.call("validate_authoring") as Array).size(), 0, "Kitchen authoring markers should validate against track rules")
	instance.call("refresh_preview")
	assert_true(instance.get_node_or_null("EditorTrackPreview/PreviewCounterSurface") != null, "Authoring preview should include the countertop surface")
	assert_true(instance.get_node_or_null("EditorTrackPreview/PreviewTrackBody") != null, "Authoring preview should include the raised track body")
	assert_true(instance.get_node_or_null("EditorTrackPreview/PreviewRoad") != null, "Authoring preview should include generated road")
	assert_true(instance.get_node_or_null("EditorTrackPreview/PreviewWalls") == null, "Authoring preview should keep auto wall preview off by default")
	assert_true(instance.get_node_or_null("EditorTrackPreview/PreviewHeightGuides/RouteHeight00") != null, "Authoring preview should include compact route height guides")
	assert_true(instance.get_node_or_null("EditorTrackPreview/PreviewHeightGuides/OverUnderGap04") != null, "Authoring preview should mark the over-under rail gap without requiring labels")
	assert_true(instance.get_node_or_null("EditorTrackPreview/PreviewMarkers/RoutePoints/RoutePoint00") != null, "Authoring preview should include route markers")
	assert_true(instance.get_node_or_null("EditorTrackPreview/PreviewMarkers/RoutePoints/RoutePoint00_Label") == null, "Authoring preview should keep position labels off by default so they do not block the scene")
	assert_true(instance.get_node_or_null("EditorTrackPreview/PreviewMarkers/ItemSockets/ItemSocket01") != null, "Authoring preview should include item socket markers")
	assert_true(instance.get_node_or_null("EditorTrackPreview/PreviewMarkers/SurfaceSegments/CountertopMain") != null, "Authoring preview should include surface segment markers")
	assert_true(instance.get_node_or_null("EditorTrackPreview/PreviewMarkers/AudioZones/SinkSplashZone") != null, "Authoring preview should include audio zone radius markers")
	assert_true(instance.get_node_or_null("EditorTrackPreview/PreviewDressingLayout/Dressing/KitchenSink") != null, "Authoring preview should include runtime dressing layout")
	assert_true(instance.get_node_or_null("Dressing/KitchenSink") != null, "Authoring scene should include an editable KitchenSink dressing marker")
	assert_true(instance.get_node_or_null("Dressing/KitchenSink").has_method("to_stage_prop"), "Kitchen sink should be a selectable stage prop authoring node")
	assert_true(instance.get_node_or_null("Dressing/FridgeLandmark").has_method("to_stage_prop"), "Kitchen fridge should be a selectable stage prop authoring node")
	assert_true(instance.get_node_or_null("SurfaceSegments/FridgeTop").has_method("to_surface_segment"), "Kitchen surface segments should export authoring data")
	assert_true(instance.get_node_or_null("AudioZones/SinkSplashZone").has_method("to_audio_zone"), "Kitchen audio zones should export authoring data")
	assert_true(instance.get_node_or_null("EditorTrackPreview/PreviewDressingLayout/DressingLabels/KitchenSink_Label") == null, "Authoring preview should keep dressing labels off by default")
	instance.set("show_marker_labels", true)
	instance.call("refresh_preview")
	assert_true(instance.get_node_or_null("EditorTrackPreview/PreviewMarkers/RoutePoints/RoutePoint00_Label") != null, "Authoring preview should label route marker positions when enabled")
	assert_true(instance.get_node_or_null("EditorTrackPreview/PreviewDressingLayout/DressingLabels/KitchenSink_Label") != null, "Authoring preview should label dressing object positions")
	instance.queue_free()

func test_car_can_be_placed_on_kitchen_start_grid() -> void:
	var definition := TrackCatalog.get_definition("kitchen")
	var built := TrackRuntimeBuilder.build(definition)
	var track_node := built.get("node", null) as Node3D
	scene_tree.root.add_child(track_node)
	var spawns: Array = built.get("spawns", [])
	assert_true(spawns.size() >= 8, "Kitchen builder should return 8 spawn transforms")
	for spawn in spawns:
		if spawn is Transform3D:
			var distance := _distance_to_route_xz((spawn as Transform3D).origin, definition.route_points, definition.closed_loop)
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
	assert_true(OutOfBoundsRules.should_reset(0.2, definition.out_of_bounds_y, definition.reset_mode), "Dropping to the floor should trigger Kitchen reset")
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
