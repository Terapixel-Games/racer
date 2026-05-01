extends "res://tests/framework/TestCase.gd"

const TrackCatalog = preload("res://scripts/track/TrackCatalog.gd")

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
const REQUIRED_AUTHORING_GROUPS := [
	"RoutePoints",
	"SpawnPoints",
	"Checkpoints",
	"ItemSockets",
	"HazardSockets",
	"AlternateRoutes",
	"Dressing",
	"SurfaceSegments",
	"AudioZones",
]

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
		var definition = load(definition_path)
		assert_true(definition != null, "%s definition should load" % track_id)
		assert_equal(definition.validate(), [], "%s definition should validate" % track_id)
		assert_equal(definition.laps, 3, "%s should run 3 laps" % track_id)
		assert_equal(definition.road_width, 12.0, "%s should preserve Kitchen road width" % track_id)
		assert_equal(definition.spawn_points.size(), 8, "%s should expose 8 spawns" % track_id)
		assert_equal(definition.rail_texture_path, "res://assets/gameplay/materials/metal/toy_metal_albedo.png", "%s should use stage rails" % track_id)
		assert_equal(definition.rail_texture_uv_scale, 0.5, "%s should use the configured rail UV scale" % track_id)
		assert_equal(definition.sky_preset_id, str(EXPECTED_STAGE_SKY_PRESETS[track_id]), "%s should use its stage sky preset" % track_id)
		var expected_ground_shader := OUTDOOR_GRASS_SHADER if track_id == "outdoor_playground" else ""
		assert_equal(definition.ground_shader_path, expected_ground_shader, "%s should use the expected ground shader" % track_id)
		assert_true(not definition.sky_weather.strip_edges().is_empty(), "%s should expose editor-friendly sky weather" % track_id)
		assert_true(definition.sky_cloud_amount >= 0.0 and definition.sky_cloud_amount <= 1.0, "%s sky cloud amount should be normalized" % track_id)
		assert_true(definition.sky_haze_amount >= 0.0 and definition.sky_haze_amount <= 1.0, "%s sky haze amount should be normalized" % track_id)
		var metadata: Dictionary = definition.to_metadata()
		assert_equal(str(metadata.get("sky_preset_id", "")), str(EXPECTED_STAGE_SKY_PRESETS[track_id]), "%s metadata should export sky preset" % track_id)
		assert_equal(str(metadata.get("ground_shader_path", "")), expected_ground_shader, "%s metadata should export ground shader" % track_id)
		assert_true((metadata.get("sky_top_color", []) as Array).size() == 4, "%s metadata should export sky top color" % track_id)
		assert_equal(definition.ground_size, kitchen_floor_size, "%s definition should match Kitchen floor dimensions" % track_id)
		assert_true(_route_has_no_self_intersections(definition.route_points, definition.closed_loop), "%s route should not overlap itself" % track_id)
		assert_equal(_floor_mesh_size(str(definition.dressing_scene_path)), kitchen_floor_size, "%s editable floor should match Kitchen floor dimensions" % track_id)
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
	for group_name in REQUIRED_AUTHORING_GROUPS:
		assert_true(root.get_node_or_null(group_name) != null, "%s should expose %s" % [track_id, group_name])
	assert_true(root.get_node("RoutePoints").get_child_count() >= 30, "%s should expose route markers" % track_id)
	assert_equal(root.get_node("SpawnPoints").get_child_count(), 8, "%s should expose editable spawn markers" % track_id)
	assert_true(root.get_node("Dressing").get_child_count() >= 5, "%s should expose editable dressing props" % track_id)
	root.queue_free()

func _floor_mesh_size(scene_path: String) -> Vector2:
	var packed := load(scene_path) as PackedScene
	if packed == null:
		return Vector2.ZERO
	var root := packed.instantiate()
	if root == null:
		return Vector2.ZERO
	var mesh_instance := root.get_node_or_null("floor/MeshInstance3D") as MeshInstance3D
	var size := Vector2.ZERO
	if mesh_instance != null and mesh_instance.mesh is PlaneMesh:
		size = (mesh_instance.mesh as PlaneMesh).size
	root.queue_free()
	return size

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
