extends "res://tests/framework/TestCase.gd"

const TrackCatalog = preload("res://scripts/track/TrackCatalog.gd")
const TrackDefinition = preload("res://scripts/track/TrackDefinition.gd")
const TrackMapDefinition = preload("res://scripts/track/TrackMapDefinition.gd")
const TrackSceneAuthoringData = preload("res://scripts/track/TrackSceneAuthoringData.gd")
const TrackRuntimeBuilder = preload("res://scripts/track/TrackRuntimeBuilder.gd")
const TrackGridRoadBuilder = preload("res://scripts/track/TrackGridRoadBuilder.gd")

const HOME_YARD_MODE_IDS := [
	"attic",
	"bedroom",
	"garden",
	"glam_closet",
	"kitchen",
	"outdoor_playground",
	"playroom",
	"sandbox",
]
const HOME_YARD_MAP_SCENE := "res://assets/gameplay/tracks/home_yard/home_yard_map.tscn"

func test_kitchen_map_definition_exposes_race_mode() -> void:
	var map_definition := TrackCatalog.get_map_definition("kitchen")
	assert_true(map_definition is TrackMapDefinition, "Kitchen should load as a track map definition")
	assert_equal(map_definition.id, "kitchen", "Kitchen map should keep the existing map id")
	assert_equal(map_definition.map_scene_path, "res://assets/gameplay/tracks/kitchen/kitchen_editable_room.tscn", "Kitchen map should own the reusable editable room scene")
	assert_true(map_definition.has_mode("race"), "Kitchen map should expose a race mode")
	var modes := TrackCatalog.list_modes("kitchen")
	assert_equal(modes.size(), 1, "Kitchen should expose one implemented mode in this pass")
	assert_equal(str(modes[0].get("id", "")), "race", "Kitchen's implemented mode should be race")
	assert_equal(str(modes[0].get("road_source", "")), "road_grid_map", "Kitchen race mode should use RoadGridMap as its source")

func test_home_yard_map_exposes_all_concept_course_modes() -> void:
	var map_definition := TrackCatalog.get_map_definition("home_yard")
	assert_true(map_definition is TrackMapDefinition, "Home Yard should load as a track map definition")
	assert_equal(map_definition.id, "home_yard", "Home Yard map id should be stable")
	assert_equal(map_definition.map_scene_path, HOME_YARD_MAP_SCENE, "Home Yard should own the shared floor-plan scene")
	var mode_ids := map_definition.list_mode_ids()
	assert_equal(mode_ids, HOME_YARD_MODE_IDS, "Home Yard should expose the eight concept course modes")
	for mode_id in HOME_YARD_MODE_IDS:
		var mode_summary := map_definition.mode_summary(mode_id)
		assert_equal(str(mode_summary.get("map_id", "")), "home_yard", "%s should belong to the Home Yard map" % mode_id)
		assert_equal(str(mode_summary.get("road_source", "")), "road_grid_map", "%s should use RoadGridMap mode metadata" % mode_id)

func test_public_home_course_ids_resolve_to_home_yard_modes() -> void:
	for mode_id in HOME_YARD_MODE_IDS:
		var definition := TrackCatalog.get_definition(mode_id)
		assert_true(definition is TrackDefinition, "%s public course id should resolve to a definition" % mode_id)
		assert_equal(str(definition.get_meta("track_map_id", "")), "home_yard", "%s should resolve through the Home Yard map" % mode_id)
		assert_equal(str(definition.get_meta("track_mode_id", "")), mode_id, "%s should resolve to its matching Home Yard mode" % mode_id)
		assert_equal(definition.dressing_scene_path, HOME_YARD_MAP_SCENE, "%s should use the shared Home Yard scene" % mode_id)
		assert_true(not definition.road_grid_layout.is_empty(), "%s should keep mode-specific RoadGridMap metadata" % mode_id)
		assert_equal(definition.validate(), [], "%s Home Yard mode definition should validate" % mode_id)

func test_legacy_kitchen_definition_adapter_returns_race_definition() -> void:
	var definition := TrackCatalog.get_definition("kitchen")
	assert_true(definition is TrackDefinition, "Legacy get_definition should still return a TrackDefinition")
	assert_equal(definition.id, "kitchen", "Legacy adapter should preserve the Kitchen track id")
	assert_equal(str(definition.get_meta("track_map_id", "")), "home_yard", "Adapted Kitchen definition should resolve through the shared Home Yard map")
	assert_equal(str(definition.get_meta("track_mode_id", "")), "kitchen", "Adapted Kitchen definition should remember its Home Yard mode")
	assert_equal(str(definition.get_meta("road_source", "")), "road_grid_map", "Adapted Kitchen race should use grid road authoring")
	assert_equal(definition.validate(), [], "Adapted Kitchen race definition should validate")

func test_kitchen_race_mode_uses_grid_without_segments() -> void:
	var definition := TrackSceneAuthoringData.apply_to_definition(TrackCatalog.get_definition("kitchen"))
	assert_equal(definition.road_visual_style, "kenney_gridmap", "Kitchen race mode should build grid road visuals")
	assert_equal(str(definition.get_meta("resolved_race_layout_source", "")), "road_grid_map", "Kitchen race mode should resolve RoadGridMap as the gameplay layout source")
	assert_equal(definition.track_source_id, "road_grid_map", "Kitchen resolved track source should be canonical")
	assert_equal(definition.progress_rule_id, "route_lap_progress", "Kitchen source should own route lap progress rules")
	assert_equal(definition.win_condition_id, "checkpoint_laps", "Kitchen source should own checkpoint lap finish rules")
	assert_true(not definition.road_grid_layout.is_empty(), "Kitchen race mode should collect RoadGridMap data")
	assert_true(definition.road_segment_layout.is_empty(), "Kitchen race mode should not co-enable segment road layout")
	assert_true(definition.route_points.size() >= (definition.road_grid_layout.get("ordered_route_cells", []) as Array).size(), "Kitchen route should be generated from grid cells")
	assert_equal((definition.road_grid_layout.get("spawn_slots", []) as Array).size(), 8, "Kitchen Home Yard mode should export authored start slots")
	assert_equal(definition.spawn_points.size(), 8, "Kitchen grid race layout should expose eight runtime spawn points")
	assert_true(_spawn_grid_starts_at_route_origin(definition.spawn_points, definition.route_points), "Kitchen start grid should align to route_points[0] from ordered_route_cells[0]")

func test_non_grid_source_request_does_not_synthesize_gridmap() -> void:
	var definition := TrackDefinition.new()
	definition.id = "kitchen_route_fixture"
	definition.display_name = "Kitchen Route Fixture"
	definition.laps = 1
	definition.road_visual_style = "procedural"
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
	var authored := TrackSceneAuthoringData.apply_to_definition(definition, {"road_source": "route"})
	assert_equal(str(authored.get_meta("resolved_race_layout_source", "")), "", "Legacy source requests should not resolve a race layout")
	assert_true(authored.road_grid_layout.is_empty(), "MVP racing should require real RoadGridMap metadata")
	assert_true(authored.road_segment_layout.is_empty(), "MVP racing should not keep segment layout data")
	assert_true(authored.validate().has("Track must include RoadGridMap layout metadata."), "Fixture tracks without RoadGridMap metadata should fail validation")

func test_road_source_aliases_resolve_to_canonical_track_sources() -> void:
	assert_equal(TrackSceneAuthoringData.canonical_road_source("grid"), "road_grid_map", "grid should remain a RoadGridMap alias")
	assert_equal(TrackSceneAuthoringData.canonical_road_source("kenney_gridmap"), "road_grid_map", "Kenney grid visuals should resolve to RoadGridMap")
	assert_equal(TrackSceneAuthoringData.canonical_road_source("route"), "auto", "Route markers should not resolve as an MVP track source")
	assert_equal(TrackSceneAuthoringData.canonical_road_source("segments"), "auto", "Segment roads should not resolve as an MVP track source")

func test_non_kitchen_track_resolves_grid_source_rules() -> void:
	var definition := TrackSceneAuthoringData.apply_to_definition(TrackCatalog.get_definition("garden"), {"road_source": "track_authoring_preview"})
	assert_equal(str(definition.get_meta("resolved_track_source", "")), "road_grid_map", "Catalog tracks should resolve through GridMap")
	assert_equal(definition.track_source_id, "road_grid_map", "Resolved track source should be canonical")
	assert_equal(definition.progress_rule_id, "route_lap_progress", "GridMap source should own route lap progress rules")
	assert_equal(definition.win_condition_id, "checkpoint_laps", "GridMap source should own checkpoint lap finish rules")
	assert_equal(definition.validate(), [], "Resolved GridMap track definition should validate")

func test_non_kitchen_tracks_load_as_gridmap_tracks() -> void:
	var definition := TrackCatalog.get_definition("garden")
	assert_true(definition is TrackDefinition, "Non-Kitchen tracks should load through get_definition")
	assert_equal(definition.id, "garden", "Garden id should be preserved")
	assert_equal(definition.track_source_id, "road_grid_map", "Garden should be authored as an MVP GridMap track")
	assert_true(not definition.road_grid_layout.is_empty(), "Garden should expose real RoadGridMap layout metadata")
	assert_equal(definition.validate(), [], "Garden GridMap definition should validate")

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
	assert_true(track_node.get_node_or_null("Rails") == null, "Grid race should not build legacy rail containment")
	assert_true(track_node.get_node_or_null("BoundaryWalls") != null and _enabled_collision_objects(track_node.get_node_or_null("BoundaryWalls")) > 0, "Grid race should generate invisible boundary wall containment")
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

func _spawn_grid_starts_at_route_origin(spawns: Array[Vector4], route_points: Array[Vector3]) -> bool:
	if spawns.size() < 8 or route_points.size() < 2:
		return false
	var start := route_points[0]
	var first_left := Vector3(spawns[0].x, start.y, spawns[0].z)
	var first_right := Vector3(spawns[1].x, start.y, spawns[1].z)
	var midpoint := first_left.lerp(first_right, 0.5)
	if midpoint.distance_to(Vector3(start.x, start.y, start.z)) > 0.01:
		return false
	var forward := route_points[1] - route_points[0]
	forward.y = 0.0
	if forward.length_squared() <= 0.001:
		return false
	forward = forward.normalized()
	var yaw := rad_to_deg(atan2(forward.x, forward.z))
	for spawn in spawns:
		if absf(angle_difference(deg_to_rad(spawn.w), deg_to_rad(yaw))) > 0.01:
			return false
	return true
