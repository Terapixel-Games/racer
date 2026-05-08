extends "res://tests/framework/TestCase.gd"

const TrackDefinition = preload("res://scripts/track/TrackDefinition.gd")
const TrackCatalog = preload("res://scripts/track/TrackCatalog.gd")
const TrackRuntimeBuilder = preload("res://scripts/track/TrackRuntimeBuilder.gd")
const TrackGridRoadBuilder = preload("res://scripts/track/TrackGridRoadBuilder.gd")

const TMP_SCENE_PATH := "res://tmp_scene_source_route.tscn"

func test_runtime_ignores_alternate_routes_for_mvp_gridmap() -> void:
	var definition := _branch_definition()
	var built := TrackRuntimeBuilder.build(definition)
	var track := built.get("node", null) as Node3D
	scene_tree.root.add_child(track)
	var rails := track.get_node_or_null("Rails")
	assert_true(rails != null, "Runtime should build canonical route rails")
	assert_true(rails != null and rails.get_child_count() > 0, "Canonical route rails should instantiate rail pieces")
	assert_true(_enabled_collision_objects(rails) > 0, "Canonical route rails should include collision")
	assert_true(_first_collision_shape(rails) is CapsuleShape3D, "Canonical route rails should use rounded capsule collision so karts can roll off")
	var rail_body := _first_collision_body(rails)
	assert_true(rail_body != null and rail_body.physics_material_override != null, "Canonical route rails should use a slick physics material")
	if rail_body != null and rail_body.physics_material_override != null:
		assert_true(rail_body.physics_material_override.friction <= 0.05, "Rail collision should stay slick instead of grabbing karts")
	var rail_shape := _first_enabled_collision_shape(rails) as CapsuleShape3D
	assert_true(rail_shape != null and rail_shape.radius <= 0.05, "Rail collision should use low world-space radius instead of inheriting visual scale")
	assert_true(track.get_node_or_null("AlternateRoutes") == null, "MVP GridMap runtime should not build alternate route geometry")
	assert_true(track.get_node_or_null("CheckpointSystem/Checkpoint01") != null, "Alternate routes should keep shared checkpoint system")
	track.queue_free()

func test_rail_join_gaps_clip_branch_merge_segments() -> void:
	var parts := TrackRuntimeBuilder._clipped_rail_segments(
		Vector3(-12, 1.0, 0),
		Vector3(12, 1.0, 0),
		[{"position": Vector3(0, 1.0, 0), "radius": 5.0}]
	)
	assert_equal(parts.size(), 2, "Rail clipping should open a gap around branch merge points")
	assert_true(((parts[0] as Dictionary).get("b", Vector3.ZERO) as Vector3).x <= -4.99, "Left rail fragment should stop before the merge opening")
	assert_true(((parts[1] as Dictionary).get("a", Vector3.ZERO) as Vector3).x >= 4.99, "Right rail fragment should resume after the merge opening")

func test_rail_overlap_filter_keeps_grade_separated_crossings() -> void:
	var route_network: Array = [{
		"key": "main",
		"points": [Vector3(0, 0.0, 0), Vector3(20, 0.0, 0)],
		"width": 12.0,
		"closed_loop": false,
	}]
	assert_true(
		TrackRuntimeBuilder._rail_segment_overlaps_other_route(Vector3(2, 0.2, 4), Vector3(18, 0.2, 4), route_network, "branch"),
		"Rails inside another same-height road corridor should be filtered"
	)
	assert_true(
		not TrackRuntimeBuilder._rail_segment_overlaps_other_route(Vector3(2, 3.0, 4), Vector3(18, 3.0, 4), route_network, "branch"),
		"Rails at grade-separated crossings should be preserved"
	)

func test_rail_route_smoothing_rounds_flat_corners() -> void:
	var route: Array[Vector3] = [
		Vector3(0, 0, 0),
		Vector3(16, 0, 0),
		Vector3(16, 0, 16),
		Vector3(0, 0, 16),
	]
	var smoothed := TrackRuntimeBuilder._smoothed_rail_route_points(route, true, 7.5, 4)
	assert_true(smoothed.size() > route.size(), "Rail route smoothing should add curve samples around flat GridMap corners")
	assert_true(not smoothed.has(Vector3(16, 0, 0)), "Rail route smoothing should replace hard corner center points with rounded arc samples")
	assert_true(smoothed.has(Vector3(8.8, 0, 0)), "Rail route smoothing should start the corner arc before the hard turn")
	assert_true(smoothed.has(Vector3(16, 0, 7.2)), "Rail route smoothing should end the corner arc after the hard turn")

func test_rail_route_smoothing_preserves_elevation_changes() -> void:
	var route: Array[Vector3] = [
		Vector3(0, 0, 0),
		Vector3(16, 4, 0),
		Vector3(16, 4, 16),
	]
	var smoothed := TrackRuntimeBuilder._smoothed_rail_route_points(route, false, 7.5, 4)
	assert_equal(smoothed, route, "Rail route smoothing should not round across ramp/elevation transitions")

func test_rail_edge_offsets_keep_full_width_on_ramps() -> void:
	var route: Array[Vector3] = [
		Vector3(0, 0, 0),
		Vector3(16, 4, 0),
	]
	var edges := TrackRuntimeBuilder._road_edge_points(route, 6.69, false)
	var left := edges.get("left", []) as Array
	var right := edges.get("right", []) as Array
	assert_equal(left.size(), 2, "Ramp rail edges should include both route points")
	assert_equal(right.size(), 2, "Ramp rail edges should include both route points")
	assert_true(is_equal_approx(absf((left[0] as Vector3).z), 6.69), "Ramp rail offset should use the visible Kenney road-side mesh edge, not the full GridMap cell edge")
	assert_true(is_equal_approx(absf((right[0] as Vector3).z), 6.69), "Ramp rail offset should use the visible Kenney road-side mesh edge, not the full GridMap cell edge")
	assert_true(is_equal_approx((left[1] as Vector3).y, 4.0), "Ramp rail edges should still follow vertical route elevation")

func test_ramp_rail_visuals_stay_upright() -> void:
	var holder := Node3D.new()
	TrackRuntimeBuilder._add_rail_segment_pieces(holder, Vector3(0, 0, 0), Vector3(16, 4, 0), "L", 0, null)
	var rail := holder.get_node_or_null("Rail_00_L_00") as Node3D
	assert_true(rail != null, "Ramp rail generation should create a visual rail piece")
	if rail != null:
		var along := rail.transform.basis.x.normalized()
		var up := rail.transform.basis.y.normalized()
		assert_true(along.distance_to(Vector3(16, 4, 0).normalized()) <= 0.01, "Ramp rail visuals should align their length axis with the 3D ramp slope")
		assert_true(absf(along.dot(up)) <= 0.01, "Ramp rail visual basis should stay orthogonal so rails do not bow on slopes")
	holder.queue_free()

func test_runtime_uses_road_grid_from_editable_scene() -> void:
	var definition := (TrackCatalog.get_definition("kitchen") as TrackDefinition).duplicate(true) as TrackDefinition
	var packed := load(definition.dressing_scene_path) as PackedScene
	assert_true(packed != null, "Kitchen editable scene should load")
	var scene_root := packed.instantiate() as Node3D
	scene_tree.root.add_child(scene_root)
	var grid := _find_authoring_node(scene_root, "RoadGridMap") as Node3D
	assert_true(grid != null and grid.has_method("to_grid_road_layout"), "Editable scene should expose RoadGridMap")
	if grid == null or not grid.has_method("to_grid_road_layout"):
		scene_root.queue_free()
		return
	var original := grid.position
	var moved := original + Vector3(3.0, 0.0, 0.0)
	grid.position = moved
	var expected_layout := grid.call("to_grid_road_layout", definition.road_width) as Dictionary
	var expected_route := TrackGridRoadBuilder.route_points_from_grid_layout(expected_layout, definition.closed_loop)
	var expected_start := expected_route[0] if not expected_route.is_empty() else Vector3.ZERO
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
	assert_true(waypoints.size() > 0, "Runtime should build waypoints from scene-sourced RoadGridMap")
	if waypoints.size() > 0:
		assert_true((waypoints[0] as Vector3).distance_to(expected_start) < 0.01, "Runtime route should follow the editable RoadGridMap")
	var track := built.get("node", null) as Node3D
	if track != null:
		track.queue_free()
	if FileAccess.file_exists(TMP_SCENE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TMP_SCENE_PATH))

func test_runtime_uses_road_grid_when_holder_is_moved() -> void:
	var definition := (TrackCatalog.get_definition("kitchen") as TrackDefinition).duplicate(true) as TrackDefinition
	var packed := load(definition.dressing_scene_path) as PackedScene
	assert_true(packed != null, "Kitchen editable scene should load")
	var scene_root := packed.instantiate() as Node3D
	scene_tree.root.add_child(scene_root)
	var grid := _find_authoring_node(scene_root, "RoadGridMap") as Node3D
	assert_true(grid != null and grid.has_method("to_grid_road_layout"), "Editable scene should expose a movable RoadGridMap")
	if grid == null or not grid.has_method("to_grid_road_layout"):
		scene_root.queue_free()
		return
	grid.position += Vector3(9.0, 0.0, 4.0)
	var expected_layout := grid.call("to_grid_road_layout", definition.road_width) as Dictionary
	var expected_route := TrackGridRoadBuilder.route_points_from_grid_layout(expected_layout, definition.closed_loop)
	var expected_start := expected_route[0] if not expected_route.is_empty() else Vector3.ZERO
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
	assert_true(waypoints.size() > 0, "Runtime should build waypoints from scene-sourced RoadGridMap")
	if waypoints.size() > 0:
		assert_true((waypoints[0] as Vector3).distance_to(expected_start) < 0.01, "Runtime route should include RoadGridMap transforms")
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
	definition.track_source_id = "road_grid_map"
	definition.road_visual_style = "kenney_gridmap"
	definition.road_grid_layout = {"ordered_route_cells": [Vector3i(0, 0, 0), Vector3i(1, 0, 0), Vector3i(1, 0, 1), Vector3i(0, 0, 1)]}
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

func _find_authoring_node(root: Node, node_name: String) -> Node:
	var direct := root.get_node_or_null(node_name)
	if direct != null:
		return direct
	for parent_name in ["TrackAuthoringPreview", "Track"]:
		var nested := root.get_node_or_null("%s/%s" % [parent_name, node_name])
		if nested != null:
			return nested
	return root.find_child(node_name, true, false)

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

func _first_collision_shape(node: Node) -> Shape3D:
	if node == null:
		return null
	if node is CollisionShape3D:
		return (node as CollisionShape3D).shape
	for child in node.get_children():
		var found := _first_collision_shape(child)
		if found != null:
			return found
	return null

func _first_enabled_collision_shape(node: Node) -> Shape3D:
	if node == null:
		return null
	if node is CollisionShape3D and not (node as CollisionShape3D).disabled:
		return (node as CollisionShape3D).shape
	for child in node.get_children():
		var found := _first_enabled_collision_shape(child)
		if found != null:
			return found
	return null

func _first_collision_body(node: Node) -> StaticBody3D:
	if node == null:
		return null
	if node is StaticBody3D:
		return node as StaticBody3D
	for child in node.get_children():
		var found := _first_collision_body(child)
		if found != null:
			return found
	return null
