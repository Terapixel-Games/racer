extends "res://tests/framework/TestCase.gd"

const TrackCatalog = preload("res://scripts/track/TrackCatalog.gd")
const TrackDefinition = preload("res://scripts/track/TrackDefinition.gd")
const TrackMapDefinition = preload("res://scripts/track/TrackMapDefinition.gd")
const TrackSceneAuthoringData = preload("res://scripts/track/TrackSceneAuthoringData.gd")
const TrackRuntimeBuilder = preload("res://scripts/track/TrackRuntimeBuilder.gd")
const TrackGridRoadBuilder = preload("res://scripts/track/TrackGridRoadBuilder.gd")

func test_kitchen_map_definition_exposes_race_mode() -> void:
	var map_definition := TrackCatalog.get_map_definition("kitchen")
	assert_true(map_definition is TrackMapDefinition, "Kitchen should load as a track map definition")
	assert_equal(map_definition.id, "kitchen", "Kitchen map should keep the existing map id")
	assert_equal(map_definition.map_scene_path, "res://assets/gameplay/tracks/kitchen/kitchen_editable_room.tscn", "Kitchen map should own the reusable editable room scene")
	assert_true(map_definition.has_mode("race"), "Kitchen map should expose a race mode")
	var modes := TrackCatalog.list_modes("kitchen")
	assert_equal(modes.size(), 1, "Kitchen should expose one implemented mode in this pass")
	assert_equal(str(modes[0].get("id", "")), "race", "Kitchen's implemented mode should be race")
	assert_equal(str(modes[0].get("road_source", "")), "grid", "Kitchen race mode should use RoadGridMap as its source")

func test_legacy_kitchen_definition_adapter_returns_race_definition() -> void:
	var definition := TrackCatalog.get_definition("kitchen")
	assert_true(definition is TrackDefinition, "Legacy get_definition should still return a TrackDefinition")
	assert_equal(definition.id, "kitchen", "Legacy adapter should preserve the Kitchen track id")
	assert_equal(str(definition.get_meta("track_map_id", "")), "kitchen", "Adapted definition should remember its source map")
	assert_equal(str(definition.get_meta("track_mode_id", "")), "race", "Adapted definition should remember its source mode")
	assert_equal(str(definition.get_meta("road_source", "")), "grid", "Adapted Kitchen race should use grid road authoring")
	assert_equal(definition.validate(), [], "Adapted Kitchen race definition should validate")

func test_kitchen_race_mode_uses_grid_without_segments() -> void:
	var definition := TrackSceneAuthoringData.apply_to_definition(TrackCatalog.get_definition("kitchen"))
	assert_equal(definition.road_visual_style, "kenney_gridmap", "Kitchen race mode should build grid road visuals")
	assert_equal(str(definition.get_meta("resolved_race_layout_source", "")), "grid", "Kitchen race mode should resolve RoadGridMap as the gameplay layout source")
	assert_true(not definition.road_grid_layout.is_empty(), "Kitchen race mode should collect RoadGridMap data")
	assert_true(definition.road_segment_layout.is_empty(), "Kitchen race mode should not co-enable segment road layout")
	assert_true(definition.route_points.size() >= (definition.road_grid_layout.get("ordered_route_cells", []) as Array).size(), "Kitchen route should be generated from grid cells")
	assert_equal((definition.road_grid_layout.get("spawn_slots", []) as Array).size(), 8, "Kitchen RoadGridMap should author the full start grid")
	assert_equal(definition.spawn_points.size(), 8, "Kitchen grid race layout should expose eight runtime spawn points")
	var authored_spawns := TrackGridRoadBuilder.spawn_points_from_grid_layout(definition.road_grid_layout, definition.route_points)
	assert_equal(definition.spawn_points, authored_spawns, "Kitchen runtime spawn data should come from RoadGridMap spawn slots")

func test_kitchen_route_mode_does_not_fall_back_to_grid_or_legacy_route_authoring() -> void:
	var definition := TrackDefinition.new()
	definition.id = "kitchen_route_fixture"
	definition.display_name = "Kitchen Route Fixture"
	definition.laps = 1
	definition.road_visual_style = "procedural"
	definition.dressing_scene_path = "res://assets/gameplay/tracks/kitchen/kitchen_editable_room.tscn"
	definition.route_points = [
		Vector3(0, 0.5, 0),
		Vector3(10, 0.5, 0),
		Vector3(10, 0.5, 10),
	]
	definition.checkpoint_indices = [0, 1, 2]
	definition.spawn_points = [
		Vector4(0, 0.8, 0, 0),
		Vector4(1, 0.8, 0, 0),
		Vector4(2, 0.8, 0, 0),
		Vector4(3, 0.8, 0, 0),
		Vector4(4, 0.8, 0, 0),
		Vector4(5, 0.8, 0, 0),
		Vector4(6, 0.8, 0, 0),
		Vector4(7, 0.8, 0, 0),
	]
	definition.item_sockets = [Vector4(0, 0.8, 0, 0)]
	var authored := TrackSceneAuthoringData.apply_to_definition(definition, {"road_source": "route"})
	assert_equal(str(authored.get_meta("resolved_race_layout_source", "")), "", "Kitchen route mode should not resolve legacy route authoring")
	assert_true(authored.road_grid_layout.is_empty(), "Explicit route mode should ignore Kitchen RoadGridMap data")
	assert_true(authored.road_segment_layout.is_empty(), "Kitchen should not keep segment layout data in route mode")
	assert_equal(authored.route_points, definition.route_points, "Without legacy route markers, explicit route mode should leave supplied route points unchanged")

func test_legacy_non_kitchen_tracks_still_load() -> void:
	var definition := TrackCatalog.get_definition("garden")
	assert_true(definition is TrackDefinition, "Legacy non-Kitchen tracks should still load through get_definition")
	assert_equal(definition.id, "garden", "Legacy Garden id should be preserved")

func test_grid_visuals_and_generated_collision_are_independent() -> void:
	var definition := TrackCatalog.get_definition("kitchen")
	var built := TrackRuntimeBuilder.build(definition)
	var track_node := built.get("node", null) as Node3D
	scene_tree.root.add_child(track_node)
	assert_true(track_node.get_node_or_null("GridRoad") != null, "Grid race should keep RoadGridMap visual road output")
	assert_true((track_node.get_node_or_null("GridRoad") as Node3D).visible, "Grid race should show the GridRoad visuals")
	var collision_body := track_node.get_node_or_null("Road/CollisionBody") as StaticBody3D
	var collision_shape := track_node.get_node_or_null("Road/CollisionBody/CollisionShape3D") as CollisionShape3D
	assert_true(collision_body != null and collision_body.collision_layer == 1 and collision_body.collision_mask == 2, "Grid race collision should use the kart gameplay channel")
	assert_true(collision_shape != null and collision_shape.shape is ConcavePolygonShape3D, "Grid race should still generate shared slab collision from the resolved layout")
	if collision_shape != null and collision_shape.shape is ConcavePolygonShape3D:
		assert_true((collision_shape.shape as ConcavePolygonShape3D).backface_collision, "Grid race collision should be backface-collidable")
	assert_equal(_enabled_collision_objects(track_node.get_node_or_null("GridRoad")), 0, "Grid road visuals should remain collision-free")
	assert_true(_enabled_collision_objects(track_node.get_node_or_null("Road")) > 0, "Generated road slab should own gameplay collision")
	assert_true(track_node.get_node_or_null("Rails") != null and _enabled_collision_objects(track_node.get_node_or_null("Rails")) > 0, "Grid race should generate collidable route rails")
	assert_true(track_node.get_node_or_null("Waypoints") != null, "Grid race should generate route waypoint nodes")
	assert_true(track_node.get_node_or_null("CheckpointSystem") != null, "Grid race should generate checkpoint nodes")
	assert_true(track_node.get_node_or_null("SpawnPoints") != null, "Grid race should generate spawn nodes")
	track_node.queue_free()

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
