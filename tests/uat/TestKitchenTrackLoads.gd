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
	assert_true(instance.get_node_or_null("BuiltTrack/Walls") != null, "Kitchen track should include walls")
	assert_true(instance.get_node_or_null("BuiltTrack/CheckpointSystem") != null, "Kitchen track should include checkpoint system")
	assert_true(instance.get_node_or_null("BuiltTrack/SpawnPoints") != null, "Kitchen track should include spawn points")
	assert_true(instance.get_node_or_null("BuiltTrack/ItemSockets") != null, "Kitchen track should include item sockets")
	assert_true(instance.get_node_or_null("BuiltTrack/HazardSockets") != null, "Kitchen track should include hazard sockets")
	assert_true(instance.get_node_or_null("BuiltTrack/ShortcutGates") != null, "Kitchen track should include shortcut gates")
	assert_true(instance.get_node_or_null("BuiltTrack/ShortcutSurface") != null, "Kitchen track should include the table jump surface")
	assert_true(instance.get_node_or_null("BuiltTrack/SectionMarkers/SinkChicane") != null, "Kitchen track should include named layout section markers")
	assert_true(instance.get_node_or_null("BuiltTrack/FloorVisual") != null, "Kitchen track should include a non-colliding floor visual below the counter")
	assert_true(instance.get_node_or_null("BuiltTrack/Ground") == null, "Kitchen floor should not be a colliding ground plane")
	assert_true(instance.get_node_or_null("BuiltTrack/Dressing/FrontCounterBase") != null, "Kitchen track should include a life-sized front counter base")
	assert_true(instance.get_node_or_null("BuiltTrack/Dressing/KitchenSink") != null, "Kitchen track should include a life-sized sink landmark")
	assert_true(instance.get_node_or_null("BuiltTrack/Dressing/OvenCabinet") != null, "Kitchen track should include a life-sized oven cabinet landmark")
	assert_true(instance.get_node_or_null("BuiltTrack/Dressing/KitchenIslandBase") != null, "Kitchen track should include the central island footprint")
	assert_true(instance.get_node_or_null("BuiltTrack/Dressing/FridgeLandmark") != null, "Kitchen track should include a fridge corner landmark")
	assert_true(instance.get_node_or_null("BuiltTrack/Dressing/StoveHeatZone") != null, "Kitchen track should include a stove hairpin visual zone")
	assert_true(instance.get_node_or_null("BuiltTrack/Dressing/SinkChicaneWetStrip") != null, "Kitchen track should include a sink chicane visual zone")
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
