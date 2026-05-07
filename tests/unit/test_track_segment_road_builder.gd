extends "res://tests/framework/TestCase.gd"

const RoadSegmentProfile = preload("res://scripts/track/RoadSegmentProfile.gd")
const TrackDefinition = preload("res://scripts/track/TrackDefinition.gd")
const TrackRuntimeBuilder = preload("res://scripts/track/TrackRuntimeBuilder.gd")
const TrackSegmentRoadBuilder = preload("res://scripts/track/TrackSegmentRoadBuilder.gd")

func test_kenney_profile_loads_required_segments() -> void:
	var profile := RoadSegmentProfile.default_profile()
	assert_equal(profile.validate(), [], "Kenney Racing Kit profile should load every curated segment scene")
	assert_true(profile.required_scene_paths().size() >= 10, "Profile should expose the curated road segment set")

func test_segment_road_builds_from_route_without_collisions() -> void:
	var route: Array[Vector3] = [
		Vector3(0.0, 1.0, 0.0),
		Vector3(32.0, 1.0, 0.0),
		Vector3(32.0, 1.0, 32.0),
		Vector3(0.0, 1.0, 32.0),
	]
	var road := TrackSegmentRoadBuilder.build_segment_road(route, 12.0, true)
	assert_equal(road.name, "SegmentRoad", "Builder should create the shared segment-road node")
	assert_true(road.get_child_count() >= 4, "Builder should instantiate modular road pieces")
	assert_equal(_enabled_collision_objects(road), 0, "Visual Kenney segments should not own gameplay collision")
	var first_piece := road.get_child(0) as Node3D
	assert_true(first_piece != null, "Segment road should expose placed Node3D pieces")
	if first_piece != null:
		assert_true(absf(first_piece.transform.basis.x.length() - 12.0) <= 0.1, "Kenney piece local width should scale to the authored road width")
		assert_true(absf(first_piece.transform.basis.z.length() - 8.0) <= 0.1, "Kenney piece local length scale should fill the generated segment interval")
	road.queue_free()

func test_explicit_segment_layout_generates_route_and_tagged_sockets() -> void:
	var layout: Array[Dictionary] = [
		{
			"segment_id": "straight_long",
			"position": Vector3(0.0, 1.0, 8.0),
			"yaw_degrees": 0.0,
			"length": 16.0,
			"road_width": 12.0,
			"roles": ["start", "checkpoint"],
		},
		{
			"segment_id": "straight_long",
			"position": Vector3(16.0, 1.0, 16.0),
			"yaw_degrees": 90.0,
			"length": 32.0,
			"road_width": 12.0,
			"roles": ["item"],
		},
		{
			"segment_id": "straight_long",
			"position": Vector3(32.0, 1.0, 0.0),
			"yaw_degrees": 180.0,
			"length": 32.0,
			"road_width": 12.0,
			"roles": ["checkpoint", "hazard"],
		},
	]
	var route := TrackSegmentRoadBuilder.route_points_from_layout(layout, false)
	assert_equal(route.size(), 4, "Explicit segment layout should generate connected route endpoints")
	assert_true(route.front().distance_to(Vector3(0.0, 1.0, 0.0)) <= 0.01, "Layout route should start at the first segment connection")
	assert_true(route.back().distance_to(Vector3(32.0, 1.0, -16.0)) <= 0.01, "Layout route should end at the final segment connection")
	var checkpoints := TrackSegmentRoadBuilder.checkpoint_indices_from_layout(layout, route, false)
	assert_true(checkpoints.has(0), "Start-tagged segments should emit checkpoint indices")
	var items := TrackSegmentRoadBuilder.sockets_from_layout(layout, "item", 0, 12.0)
	var hazards := TrackSegmentRoadBuilder.sockets_from_layout(layout, "hazard", 0, 12.0)
	assert_equal(items.size(), 1, "Item-tagged segments should emit item sockets")
	assert_equal(hazards.size(), 1, "Hazard-tagged segments should emit hazard sockets")

func test_generated_segment_route_is_continuous() -> void:
	var route: Array[Vector3] = [Vector3(0.0, 0.0, 0.0), Vector3(48.0, 0.0, 0.0), Vector3(48.0, 0.0, 48.0)]
	var generated := TrackSegmentRoadBuilder.generated_route_points(route, false)
	assert_true(generated.size() > route.size(), "Generated route should contain snapped segment-centerline samples")
	assert_equal(generated.front(), route.front(), "Generated route should preserve the route start")
	assert_equal(generated.back(), route.back(), "Generated route should preserve the route end")
	for i in range(generated.size() - 1):
		assert_true((generated[i] as Vector3).distance_to(generated[i + 1]) <= 17.0, "Generated route samples should stay close enough for checkpoints and minimap")

func test_runtime_keeps_generated_slab_collision_and_segment_visuals() -> void:
	var definition := _base_definition()
	var built := TrackRuntimeBuilder.build(definition)
	var track := built.get("node", null) as Node3D
	assert_true(track != null, "Runtime builder should return a track root")
	if track == null:
		return
	scene_tree.root.add_child(track)
	assert_true(track.get_node_or_null("SegmentRoad") != null, "Runtime track should include Kenney segment visuals")
	var road := track.get_node_or_null("Road") as MeshInstance3D
	assert_true(road != null, "Runtime track should keep the procedural road node for collision")
	if road != null:
		assert_true(not road.visible, "Procedural road should be hidden when Kenney segments render the surface")
	var collision_shape := track.get_node_or_null("Road/CollisionBody/CollisionShape3D") as CollisionShape3D
	assert_true(collision_shape != null and collision_shape.shape is ConcavePolygonShape3D, "Runtime road should keep generated slab collision")
	track.queue_free()

func _base_definition() -> TrackDefinition:
	var definition := TrackDefinition.new()
	definition.id = "segment_test"
	definition.display_name = "Segment Test"
	definition.laps = 1
	definition.road_width = 12.0
	definition.closed_loop = true
	definition.route_points = [
		Vector3(0.0, 1.0, 0.0),
		Vector3(32.0, 1.0, 0.0),
		Vector3(32.0, 1.0, 32.0),
		Vector3(0.0, 1.0, 32.0),
	]
	definition.checkpoint_indices = [0, 1, 2]
	definition.lap_gate_checkpoint_index = 0
	definition.road_segment_layout = [
		{
			"segment_id": "straight_long",
			"position": Vector3(16.0, 1.0, 0.0),
			"yaw_degrees": 90.0,
			"length": 32.0,
			"road_width": 12.0,
			"roles": ["start", "checkpoint"],
		},
		{
			"segment_id": "straight_long",
			"position": Vector3(32.0, 1.0, 16.0),
			"yaw_degrees": 0.0,
			"length": 32.0,
			"road_width": 12.0,
			"roles": ["checkpoint", "item"],
		},
		{
			"segment_id": "straight_long",
			"position": Vector3(16.0, 1.0, 32.0),
			"yaw_degrees": -90.0,
			"length": 32.0,
			"road_width": 12.0,
			"roles": ["checkpoint"],
		},
		{
			"segment_id": "straight_long",
			"position": Vector3(0.0, 1.0, 16.0),
			"yaw_degrees": 180.0,
			"length": 32.0,
			"road_width": 12.0,
			"roles": [],
		},
	]
	definition.spawn_points = [
		Vector4(0.0, 1.5, -2.0, 0.0),
		Vector4(2.0, 1.5, -2.0, 0.0),
		Vector4(4.0, 1.5, -2.0, 0.0),
		Vector4(6.0, 1.5, -2.0, 0.0),
		Vector4(0.0, 1.5, -5.0, 0.0),
		Vector4(2.0, 1.5, -5.0, 0.0),
		Vector4(4.0, 1.5, -5.0, 0.0),
		Vector4(6.0, 1.5, -5.0, 0.0),
	]
	definition.item_sockets = [Vector4(8.0, 1.5, 0.0, 0.0)]
	return definition

func _enabled_collision_objects(node: Node) -> int:
	var count := 0
	if node is CollisionObject3D:
		var collision := node as CollisionObject3D
		if collision.collision_layer != 0 or collision.collision_mask != 0:
			count += 1
	for child in node.get_children():
		count += _enabled_collision_objects(child)
	return count
