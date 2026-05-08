extends "res://tests/framework/TestCase.gd"

const TrackCatalog = preload("res://scripts/track/TrackCatalog.gd")
const TrackRuntimeBuilder = preload("res://scripts/track/TrackRuntimeBuilder.gd")
const TrackSceneAuthoringData = preload("res://scripts/track/TrackSceneAuthoringData.gd")

func test_all_tracks_build_kenney_segment_roads_with_generated_collision() -> void:
	for summary in TrackCatalog.list_tracks():
		var track_id := str(summary.get("id", ""))
		var definition := TrackSceneAuthoringData.apply_to_definition(TrackCatalog.get_definition(track_id))
		assert_true(definition != null, "%s definition should load" % track_id)
		if definition == null:
			continue
		if track_id == "kitchen":
			assert_equal(definition.road_visual_style, "kenney_gridmap", "Kitchen should pilot GridMap-authored roads")
			assert_true(not definition.road_grid_layout.is_empty(), "Kitchen should use authored RoadGridMap data")
			assert_true(_authoring_scene_has_road_grid(definition), "Kitchen authoring scene should include RoadGridMap")
			assert_true(_authoring_scene_has_grid_spawns(definition), "Kitchen authoring scene should keep spawn slots on RoadGridMap")
			assert_true(not _authoring_scene_has_road_segments(definition), "Kitchen authoring scene should only keep RoadGridMap for now")
		else:
			assert_true(not definition.road_segment_layout.is_empty(), "%s should use authored road segment layout data" % track_id)
			assert_true(_authoring_scene_has_road_segments(definition), "%s authoring scene should include RoadSegments" % track_id)
		var built := TrackRuntimeBuilder.build(definition)
		var track_node := built.get("node", null) as Node3D
		assert_true(track_node != null, "%s runtime track should build" % track_id)
		if track_node == null:
			continue
		scene_tree.root.add_child(track_node)
		if track_id == "kitchen":
			var grid_road := track_node.get_node_or_null("GridRoad")
			assert_true(grid_road != null, "Kitchen should build GridMap-derived Kenney road visuals")
			assert_true(grid_road != null and (grid_road as Node3D).visible, "Kitchen GridRoad visuals should be visible")
			assert_equal(_enabled_collision_objects(grid_road), 0, "Kitchen GridRoad tile visuals should not own gameplay collision")
		else:
			assert_true(track_node.get_node_or_null("SegmentRoad") != null, "%s should build Kenney segment road visuals" % track_id)
			var segment_road := track_node.get_node_or_null("SegmentRoad") as Node3D
			if segment_road != null:
				assert_equal(str(segment_road.get_meta("source", "")), "explicit_layout", "%s segment road should come from authored layout data" % track_id)
		assert_true(track_node.get_node_or_null("TrackBody") != null, "%s should keep generated track body support" % track_id)
		var road := track_node.get_node_or_null("Road") as MeshInstance3D
		assert_true(road != null, "%s should keep generated road collision node" % track_id)
		if road != null:
			assert_true(not road.visible, "%s procedural road should be hidden behind Kenney segments" % track_id)
		var collision_shape := track_node.get_node_or_null("Road/CollisionBody/CollisionShape3D") as CollisionShape3D
		assert_true(collision_shape != null and collision_shape.shape is ConcavePolygonShape3D, "%s should keep generated slab road collision" % track_id)
		if collision_shape != null and collision_shape.shape is ConcavePolygonShape3D:
			assert_true((collision_shape.shape as ConcavePolygonShape3D).backface_collision, "%s road collision should catch karts from above and below" % track_id)
		var collision_body := track_node.get_node_or_null("Road/CollisionBody") as StaticBody3D
		assert_true(collision_body != null and collision_body.collision_layer == 1 and collision_body.collision_mask == 2, "%s road collision should use the kart gameplay collision channel" % track_id)
		assert_true((built.get("waypoints", []) as Array).size() >= 3, "%s should expose gameplay waypoints" % track_id)
		assert_true(track_node.get_node_or_null("Waypoints") != null, "%s should include generated waypoint nodes" % track_id)
		assert_true(track_node.get_node_or_null("CheckpointSystem") != null, "%s should include checkpoints" % track_id)
		assert_true(track_node.get_node_or_null("SpawnPoints") != null, "%s should include spawns" % track_id)
		if track_id == "kitchen":
			assert_true(track_node.get_node_or_null("SpawnPoints/Start08") != null, "Kitchen should generate the full eight-car grid from RoadGridMap slots")
		assert_true(track_node.get_node_or_null("ItemSockets") != null, "%s should include item sockets" % track_id)
		assert_true(track_node.get_node_or_null("HazardSockets") != null, "%s should include hazard sockets" % track_id)
		var rails := track_node.get_node_or_null("Rails")
		assert_true(rails != null and _enabled_collision_objects(rails) > 0, "%s should include collidable route rails" % track_id)
		track_node.queue_free()

func _authoring_scene_has_road_segments(definition) -> bool:
	var path := str(definition.dressing_scene_path)
	if path.is_empty():
		return false
	var packed := load(path) as PackedScene
	if packed == null:
		return false
	var root := packed.instantiate()
	if root == null:
		return false
	var holder := _find_authoring_node(root, "RoadSegments")
	var found := holder != null and holder.get_child_count() > 0
	root.queue_free()
	return found

func _authoring_scene_has_road_grid(definition) -> bool:
	var path := str(definition.dressing_scene_path)
	if path.is_empty():
		return false
	var packed := load(path) as PackedScene
	if packed == null:
		return false
	var root := packed.instantiate()
	if root == null:
		return false
	var grid := _find_authoring_node(root, "RoadGridMap")
	var found := grid != null and grid.has_method("to_grid_road_layout")
	root.queue_free()
	return found

func _authoring_scene_has_grid_spawns(definition) -> bool:
	var path := str(definition.dressing_scene_path)
	if path.is_empty():
		return false
	var packed := load(path) as PackedScene
	if packed == null:
		return false
	var root := packed.instantiate()
	if root == null:
		return false
	var grid := _find_authoring_node(root, "RoadGridMap")
	var found := grid != null and ((grid.get("spawn_slots") as Array).size() >= 8)
	root.queue_free()
	return found

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
