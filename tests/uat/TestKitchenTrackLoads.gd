extends "res://tests/framework/TestCase.gd"

const TrackCatalog = preload("res://scripts/track/TrackCatalog.gd")
const TrackRuntimeBuilder = preload("res://scripts/track/TrackRuntimeBuilder.gd")

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
	instance.queue_free()

func test_car_can_be_placed_on_kitchen_start_grid() -> void:
	var definition := TrackCatalog.get_definition("kitchen")
	var built := TrackRuntimeBuilder.build(definition)
	var track_node := built.get("node", null) as Node3D
	scene_tree.root.add_child(track_node)
	var spawns: Array = built.get("spawns", [])
	assert_true(spawns.size() >= 8, "Kitchen builder should return 8 spawn transforms")
	var car_scene := load("res://scenes/Car.tscn")
	assert_true(car_scene is PackedScene, "Car scene should load")
	var car := (car_scene as PackedScene).instantiate() as Node3D
	scene_tree.root.add_child(car)
	car.global_transform = spawns[0]
	assert_true(car.global_transform.origin.distance_to((spawns[0] as Transform3D).origin) < 0.01, "Car should be placeable on the Kitchen start grid")
	car.queue_free()
	track_node.queue_free()
