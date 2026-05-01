extends "res://tests/framework/TestCase.gd"

const TrackDefinition = preload("res://scripts/track/TrackDefinition.gd")
const TrackCatalog = preload("res://scripts/track/TrackCatalog.gd")
const TrackRuntimeBuilder = preload("res://scripts/track/TrackRuntimeBuilder.gd")

const TMP_SCENE_PATH := "user://tmp_scene_source_route.tscn"

func test_runtime_builds_enabled_alternate_route_geometry() -> void:
	var definition := _branch_definition()
	var built := TrackRuntimeBuilder.build(definition)
	var track := built.get("node", null) as Node3D
	scene_tree.root.add_child(track)
	var rails := track.get_node_or_null("Rails")
	assert_true(rails != null, "Runtime should build canonical route rails")
	assert_true(rails != null and rails.get_child_count() > 0, "Canonical route rails should instantiate rail pieces")
	assert_true(_enabled_collision_objects(rails) > 0, "Canonical route rails should include collision")
	assert_true(track.get_node_or_null("AlternateRoutes/InsideLaneRoad") != null, "Runtime should build alternate route road geometry")
	assert_true(track.get_node_or_null("AlternateRoutes/InsideLaneRoad/CollisionBody/CollisionShape3D") != null, "Alternate route road should include collision")
	var alternate_rails := track.get_node_or_null("AlternateRoutes/InsideLaneRails")
	assert_true(alternate_rails != null, "Runtime should build alternate route rails")
	assert_true(alternate_rails != null and alternate_rails.get_child_count() > 0, "Alternate route rails should instantiate rail pieces")
	assert_true(_enabled_collision_objects(alternate_rails) > 0, "Alternate route rails should include collision")
	assert_true(track.get_node_or_null("CheckpointSystem/Checkpoint01") != null, "Alternate routes should keep shared checkpoint system")
	track.queue_free()

func test_runtime_uses_route_points_from_editable_scene() -> void:
	var definition := (TrackCatalog.get_definition("kitchen") as TrackDefinition).duplicate(true) as TrackDefinition
	var packed := load(definition.dressing_scene_path) as PackedScene
	assert_true(packed != null, "Kitchen editable scene should load")
	var scene_root := packed.instantiate() as Node3D
	scene_tree.root.add_child(scene_root)
	var marker := scene_root.get_node_or_null("RoutePoints/RoutePoint00") as Marker3D
	assert_true(marker != null, "Editable scene should expose route point markers")
	if marker == null:
		scene_root.queue_free()
		return
	var original := marker.position
	var moved := original + Vector3(3.0, 0.0, 0.0)
	marker.position = moved
	var temp_scene := PackedScene.new()
	var save_error := temp_scene.pack(scene_root)
	assert_equal(save_error, OK, "Temporary scene should pack")
	if save_error == OK:
		save_error = ResourceSaver.save(temp_scene, TMP_SCENE_PATH)
	assert_equal(save_error, OK, "Temporary scene should save")
	scene_root.queue_free()
	if save_error != OK:
		return
	definition.dressing_scene_path = TMP_SCENE_PATH
	var built := TrackRuntimeBuilder.build(definition)
	var waypoints := built.get("waypoints", []) as Array
	assert_true(waypoints.size() > 0, "Runtime should build waypoints from scene-sourced route")
	if waypoints.size() > 0:
		assert_true((waypoints[0] as Vector3).distance_to(moved) < 0.01, "Runtime route should follow the editable scene marker")
	var track := built.get("node", null) as Node3D
	if track != null:
		track.queue_free()
	if FileAccess.file_exists(TMP_SCENE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TMP_SCENE_PATH))

func _branch_definition() -> TrackDefinition:
	var definition := TrackDefinition.new()
	definition.id = "branch_test"
	definition.display_name = "Branch Test"
	definition.laps = 1
	definition.closed_loop = true
	definition.road_width = 10.0
	definition.route_points = [
		Vector3(0, 0.5, 0),
		Vector3(20, 0.5, 0),
		Vector3(20, 0.5, 20),
		Vector3(0, 0.5, 20),
	]
	definition.checkpoint_indices = [0, 1, 2]
	definition.lap_gate_checkpoint_index = 0
	definition.spawn_points = [
		Vector4(0, 1.0, -2, 0),
		Vector4(2, 1.0, -2, 0),
		Vector4(4, 1.0, -2, 0),
		Vector4(6, 1.0, -2, 0),
		Vector4(0, 1.0, -5, 0),
		Vector4(2, 1.0, -5, 0),
		Vector4(4, 1.0, -5, 0),
		Vector4(6, 1.0, -5, 0),
	]
	definition.item_sockets = [Vector4(4, 1.0, 4, 0)]
	definition.alternate_routes = [{
		"id": "inside_lane",
		"entry_checkpoint_index": 0,
		"exit_checkpoint_index": 2,
		"points": [Vector3(0, 0.5, 4), Vector3(12, 0.5, 10), Vector3(20, 0.5, 20)],
		"road_width": 8.0,
		"enabled": true,
	}]
	return definition

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
