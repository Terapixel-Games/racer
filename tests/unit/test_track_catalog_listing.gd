extends "res://tests/framework/TestCase.gd"

const TrackCatalog = preload("res://scripts/track/TrackCatalog.gd")
const TrackSceneAuthoringData = preload("res://scripts/track/TrackSceneAuthoringData.gd")

const HOME_COURSE_IDS := [
	"sandbox",
	"garden",
	"bedroom",
	"attic",
	"playroom",
	"glam_closet",
	"outdoor_playground",
]
const EXPECTED_STAGE_SKY_PRESETS := {
	"kitchen": "noon_clear",
	"sandbox": "hot_afternoon",
	"garden": "fresh_morning",
	"bedroom": "soft_morning",
	"attic": "stormy_moonlight_night",
	"playroom": "party_evening",
	"glam_closet": "night_city_glow",
	"outdoor_playground": "clear_afternoon",
}
const OUTDOOR_GRASS_SHADER := "res://assets/gameplay/materials/grass/playground_grass.gdshader"
const OUTDOOR_PLAYGROUND_FLOOR_TEXTURE := "res://assets/gameplay/materials/playground/outdoor_playground_floor_albedo.png"
const OUTDOOR_PLAYGROUND_EDITABLE_FLOOR_SIZE := Vector2(800.0, 800.0)
func test_list_tracks_returns_default_first_summary() -> void:
	var tracks := TrackCatalog.list_tracks()
	assert_true(tracks.size() >= 1, "Track catalog should expose at least one selectable track")
	var first: Dictionary = tracks[0]
	assert_equal(str(first.get("id", "")), TrackCatalog.get_default_track_id(), "Default track should appear first")
	assert_equal(str(first.get("display_name", "")), "Kitchen / Sir Clink", "Track summary should expose display name")
	assert_true(str(first.get("scene_path", "")).ends_with(".tscn"), "Track summary should expose runtime scene path")
	assert_true(str(first.get("definition_path", "")).ends_with(".tres"), "Track summary should expose definition path")
	assert_true(str(first.get("metadata_path", "")).ends_with(".json"), "Track summary should expose metadata path")

func test_home_course_tracks_are_human_editable_and_match_kitchen_scale() -> void:
	var kitchen_floor_size := _floor_mesh_size("res://assets/gameplay/tracks/kitchen/kitchen_editable_room.tscn")
	assert_equal(kitchen_floor_size, Vector2(292.0, 190.0), "Kitchen floor node should remain the stage scale source")
	for track_id in HOME_COURSE_IDS:
		var package := TrackCatalog.get_package(track_id)
		assert_true(not package.is_empty(), "%s should be listed in the track catalog" % track_id)
		var scene_path := str(package.get("scene_path", ""))
		var definition_path := str(package.get("definition_path", ""))
		var metadata_path := str(package.get("metadata_path", ""))
		assert_true(ResourceLoader.exists(scene_path), "%s runtime scene should exist" % track_id)
		assert_true(ResourceLoader.exists(definition_path), "%s definition should exist" % track_id)
		assert_true(FileAccess.file_exists(metadata_path), "%s metadata should exist" % track_id)
		var definition = TrackCatalog.get_definition(track_id)
		assert_true(definition != null, "%s definition should load" % track_id)
		assert_equal(definition.validate(), [], "%s definition should validate" % track_id)
		assert_equal(definition.track_source_id, "road_grid_map", "%s should resolve as a GridMap MVP track" % track_id)
		assert_equal(definition.road_visual_style, "kenney_gridmap", "%s should use GridMap road visuals" % track_id)
		assert_true(not definition.road_grid_layout.is_empty(), "%s should expose GridMap layout metadata" % track_id)
		assert_equal(definition.laps, 3, "%s should run 3 laps" % track_id)
		var expected_road_width := 15.0 if track_id == "attic" else 12.0
		assert_equal(definition.road_width, expected_road_width, "%s should use its planned road width" % track_id)
		assert_equal(definition.spawn_points.size(), 8, "%s should expose 8 spawns" % track_id)
		assert_equal(definition.rail_texture_path, "res://assets/gameplay/materials/metal/toy_metal_albedo.png", "%s should use stage rails" % track_id)
		assert_equal(definition.rail_texture_uv_scale, 0.5, "%s should use the configured rail UV scale" % track_id)
		assert_equal(definition.sky_preset_id, str(EXPECTED_STAGE_SKY_PRESETS[track_id]), "%s should use its stage sky preset" % track_id)
		var expected_ground_shader := OUTDOOR_GRASS_SHADER if track_id == "outdoor_playground" else ""
		assert_equal(definition.ground_shader_path, expected_ground_shader, "%s should use the expected ground shader" % track_id)
		if track_id == "outdoor_playground":
			assert_equal(definition.ground_texture_path, OUTDOOR_PLAYGROUND_FLOOR_TEXTURE, "Outdoor Playground should use the authored floor texture")
		assert_true(not definition.sky_weather.strip_edges().is_empty(), "%s should expose editor-friendly sky weather" % track_id)
		assert_true(definition.sky_cloud_amount >= 0.0 and definition.sky_cloud_amount <= 1.0, "%s sky cloud amount should be normalized" % track_id)
		assert_true(definition.sky_haze_amount >= 0.0 and definition.sky_haze_amount <= 1.0, "%s sky haze amount should be normalized" % track_id)
		var metadata: Dictionary = definition.to_metadata()
		assert_equal(str(metadata.get("sky_preset_id", "")), str(EXPECTED_STAGE_SKY_PRESETS[track_id]), "%s metadata should export sky preset" % track_id)
		assert_equal(str(metadata.get("ground_shader_path", "")), expected_ground_shader, "%s metadata should export ground shader" % track_id)
		if track_id == "outdoor_playground":
			assert_equal(str(metadata.get("ground_texture_path", "")), OUTDOOR_PLAYGROUND_FLOOR_TEXTURE, "Outdoor Playground metadata should export floor texture")
		assert_true((metadata.get("sky_top_color", []) as Array).size() == 4, "%s metadata should export sky top color" % track_id)
		var expected_ground_size := OUTDOOR_PLAYGROUND_EDITABLE_FLOOR_SIZE if track_id == "outdoor_playground" else kitchen_floor_size
		assert_equal(definition.ground_size, expected_ground_size, "%s definition should match its authored floor dimensions" % track_id)
		assert_true(definition.road_segment_layout.is_empty(), "%s should not use legacy segment layout data" % track_id)
		assert_true(definition.route_points.size() >= 12, "%s route should be generated from GridMap metadata" % track_id)
		var expected_editable_floor_size := OUTDOOR_PLAYGROUND_EDITABLE_FLOOR_SIZE if track_id == "outdoor_playground" else kitchen_floor_size
		assert_equal(_floor_mesh_size(str(definition.dressing_scene_path)), expected_editable_floor_size, "%s editable floor should match its authored dimensions" % track_id)
		_assert_authoring_scene(definition.dressing_scene_path, track_id)

func test_track_sky_presets_match_stage_plan() -> void:
	for track_id in EXPECTED_STAGE_SKY_PRESETS.keys():
		var definition = TrackCatalog.get_definition(str(track_id))
		assert_true(definition != null, "%s definition should load" % track_id)
		assert_equal(definition.sky_preset_id, str(EXPECTED_STAGE_SKY_PRESETS[track_id]), "%s should use the planned sky preset" % track_id)
		var metadata: Dictionary = TrackCatalog.get_metadata(str(track_id))
		assert_equal(str(metadata.get("sky_preset_id", "")), str(EXPECTED_STAGE_SKY_PRESETS[track_id]), "%s package metadata should export the planned sky preset" % track_id)

func _assert_authoring_scene(scene_path: String, track_id: String) -> void:
	var packed := load(scene_path) as PackedScene
	assert_true(packed != null, "%s editable scene should load" % track_id)
	var root := packed.instantiate()
	assert_true(root != null, "%s editable scene should instantiate" % track_id)
	if track_id == "outdoor_playground":
		var grass_zones := _find_authoring_node(root, "GrassZones")
		assert_true(grass_zones != null, "Outdoor Playground should expose editable GrassZones")
		assert_true(grass_zones != null and grass_zones.get_child_count() >= 2, "Outdoor Playground should expose multiple editable grass zones")
		assert_true(grass_zones != null and _has_editable_grass_zone_bounds(grass_zones), "Outdoor Playground grass zones should expose editable Area3D bounds and visible editor previews")
		assert_true(grass_zones != null and _grass_zone_shapes_are_unique(grass_zones), "Outdoor Playground grass zones should use unique collision shapes so zones can be resized independently")
	var dressing := _find_authoring_node(root, "Dressing")
	assert_true(dressing != null and dressing.get_child_count() >= 5, "%s should expose editable dressing props" % track_id)
	root.queue_free()

func _has_editable_grass_zone_bounds(holder: Node) -> bool:
	for child in holder.get_children():
		if child is Area3D and child.get_node_or_null("CollisionShape3D") is CollisionShape3D and child.get_node_or_null("BoundsPreview") is MeshInstance3D:
			return true
	return false

func _grass_zone_shapes_are_unique(holder: Node) -> bool:
	var shape_ids := {}
	for child in holder.get_children():
		if not (child is Area3D):
			continue
		var shape_node := child.get_node_or_null("CollisionShape3D") as CollisionShape3D
		if shape_node == null or shape_node.shape == null:
			return false
		var shape_id := shape_node.shape.get_instance_id()
		if shape_ids.has(shape_id):
			return false
		shape_ids[shape_id] = true
	return true

func _floor_mesh_size(scene_path: String) -> Vector2:
	var packed := load(scene_path) as PackedScene
	if packed == null:
		return Vector2.ZERO
	var root := packed.instantiate()
	if root == null:
		return Vector2.ZERO
	var mesh_instance := root.get_node_or_null("floor/MeshInstance3D") as MeshInstance3D
	if mesh_instance == null:
		mesh_instance = root.get_node_or_null("Track/floor/MeshInstance3D") as MeshInstance3D
	if mesh_instance == null:
		var floor_holder := root.find_child("floor", true, false)
		if floor_holder != null:
			mesh_instance = floor_holder.get_node_or_null("MeshInstance3D") as MeshInstance3D
	var size := Vector2.ZERO
	if mesh_instance != null and mesh_instance.mesh is PlaneMesh:
		size = (mesh_instance.mesh as PlaneMesh).size
	root.queue_free()
	return size

func _find_authoring_node(root: Node, node_name: String) -> Node:
	var direct := root.get_node_or_null(node_name)
	if direct != null:
		return direct
	for parent_name in ["TrackAuthoringPreview", "Track"]:
		var nested := root.get_node_or_null("%s/%s" % [parent_name, node_name])
		if nested != null:
			return nested
	return root.find_child(node_name, true, false)

func _route_has_no_self_intersections(route_points: Array[Vector3], closed_loop: bool) -> bool:
	var segment_count := route_points.size() if closed_loop else route_points.size() - 1
	for i in range(segment_count):
		for j in range(i + 1, segment_count):
			if abs(i - j) <= 1:
				continue
			if closed_loop and i == 0 and j == segment_count - 1:
				continue
			if _segments_intersect(
				Vector2(route_points[i].x, route_points[i].z),
				Vector2(route_points[(i + 1) % route_points.size()].x, route_points[(i + 1) % route_points.size()].z),
				Vector2(route_points[j].x, route_points[j].z),
				Vector2(route_points[(j + 1) % route_points.size()].x, route_points[(j + 1) % route_points.size()].z)
			):
				return false
	return true

func _segments_intersect(a: Vector2, b: Vector2, c: Vector2, d: Vector2) -> bool:
	var o1 := _orientation(a, b, c)
	var o2 := _orientation(a, b, d)
	var o3 := _orientation(c, d, a)
	var o4 := _orientation(c, d, b)
	if o1 * o2 < 0.0 and o3 * o4 < 0.0:
		return true
	return _point_on_segment(a, b, c) or _point_on_segment(a, b, d) or _point_on_segment(c, d, a) or _point_on_segment(c, d, b)

func _orientation(a: Vector2, b: Vector2, c: Vector2) -> float:
	return _cross2(b - a, c - a)

func _cross2(a: Vector2, b: Vector2) -> float:
	return a.x * b.y - a.y * b.x

func _point_on_segment(a: Vector2, b: Vector2, point: Vector2) -> bool:
	if absf(_orientation(a, b, point)) > 0.001:
		return false
	return point.x >= minf(a.x, b.x) - 0.001 and point.x <= maxf(a.x, b.x) + 0.001 and point.y >= minf(a.y, b.y) - 0.001 and point.y <= maxf(a.y, b.y) + 0.001
