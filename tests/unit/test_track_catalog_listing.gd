extends "res://tests/framework/TestCase.gd"

const TrackCatalog = preload("res://scripts/track/TrackCatalog.gd")
const TrackSceneAuthoringData = preload("res://scripts/track/TrackSceneAuthoringData.gd")

const ACTIVE_TRACK_IDS := [
	"kitchen",
	"bedroom",
	"sandbox",
	"garden",
	"glam_closet",
	"outdoor_playground",
	"playroom",
	"attic",
]
const BACKYARD_TRACK_IDS := ["sandbox", "garden", "outdoor_playground"]
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
const INDOOR_FLOOR_SIZE := Vector2(292.0, 190.0)
const BACKYARD_FLOOR_SIZE := Vector2(840.0, 620.0)
const ARCHIVE_ROOT := "res://assets/gameplay/tracks/_archive/2026-05-02_pre_toybox_dominion"
const BACKYARD_BASE_PATH := "res://assets/gameplay/tracks/shared/backyard/backyard_base.tscn"
const REQUIRED_AUTHORING_GROUPS := [
	"RoutePoints",
	"SpawnPoints",
	"Checkpoints",
	"ItemSockets",
	"HazardSockets",
	"AlternateRoutes",
	"ShortcutGates",
	"Dressing",
	"SurfaceSegments",
	"AudioZones",
	"GrassZones",
	"SignatureEffects",
]

func test_list_tracks_returns_toybox_default_first_summary() -> void:
	var tracks := TrackCatalog.list_tracks()
	assert_equal(tracks.size(), 8, "Track catalog should expose the eight active Toybox stages")
	var first: Dictionary = tracks[0]
	assert_equal(str(first.get("id", "")), TrackCatalog.get_default_track_id(), "Default track should appear first")
	assert_equal(str(first.get("display_name", "")), "Kitchen / Sir Clink", "Track summary should expose display name")
	for summary in tracks:
		assert_true(ACTIVE_TRACK_IDS.has(str(summary.get("id", ""))), "Catalog should only expose active Toybox track IDs")
		assert_true(not str(summary.get("scene_path", "")).contains("/_archive/"), "Catalog scene paths should not point at archived stages")
		assert_true(not str(summary.get("definition_path", "")).contains("/_archive/"), "Catalog definition paths should not point at archived stages")
		assert_true(not str(summary.get("metadata_path", "")).contains("/_archive/"), "Catalog metadata paths should not point at archived stages")

func test_toybox_tracks_are_human_editable() -> void:
	assert_true(ResourceLoader.exists(BACKYARD_BASE_PATH), "Shared backyard base scene should exist")
	for track_id in ACTIVE_TRACK_IDS:
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
		assert_equal(definition.road_width, 12.0, "%s should preserve stage road width" % track_id)
		assert_equal(definition.spawn_points.size(), 8, "%s should expose 8 spawns" % track_id)
		assert_equal(definition.item_sockets.size(), 8, "%s should expose item sockets" % track_id)
		assert_equal(definition.hazard_sockets.size(), 6, "%s should expose hazard sockets" % track_id)
		assert_equal(definition.rail_texture_path, "res://assets/gameplay/materials/metal/toy_metal_albedo.png", "%s should use stage rails" % track_id)
		assert_equal(definition.rail_texture_uv_scale, 0.5, "%s should use the configured rail UV scale" % track_id)
		assert_equal(definition.sky_preset_id, str(EXPECTED_STAGE_SKY_PRESETS[track_id]), "%s should use its stage sky preset" % track_id)
		var expected_ground_shader := OUTDOOR_GRASS_SHADER if BACKYARD_TRACK_IDS.has(track_id) else ""
		assert_equal(definition.ground_shader_path, expected_ground_shader, "%s should use the expected ground shader" % track_id)
		assert_true(not definition.sky_weather.strip_edges().is_empty(), "%s should expose editor-friendly sky weather" % track_id)
		assert_true(definition.sky_cloud_amount >= 0.0 and definition.sky_cloud_amount <= 1.0, "%s sky cloud amount should be normalized" % track_id)
		assert_true(definition.sky_haze_amount >= 0.0 and definition.sky_haze_amount <= 1.0, "%s sky haze amount should be normalized" % track_id)
		var metadata: Dictionary = definition.to_metadata()
		assert_equal(str(metadata.get("sky_preset_id", "")), str(EXPECTED_STAGE_SKY_PRESETS[track_id]), "%s metadata should export sky preset" % track_id)
		assert_equal(str(metadata.get("ground_shader_path", "")), expected_ground_shader, "%s metadata should export ground shader" % track_id)
		assert_true((metadata.get("sky_top_color", []) as Array).size() == 4, "%s metadata should export sky top color" % track_id)
		var expected_ground_size := BACKYARD_FLOOR_SIZE if BACKYARD_TRACK_IDS.has(track_id) else INDOOR_FLOOR_SIZE
		assert_equal(definition.ground_size, expected_ground_size, "%s definition should match its authored floor dimensions" % track_id)
		assert_true(_route_has_no_self_intersections(definition.route_points, definition.closed_loop), "%s route should not overlap itself" % track_id)
		assert_equal(_floor_mesh_size(str(definition.dressing_scene_path)), expected_ground_size, "%s editable floor should match its authored dimensions" % track_id)
		_assert_authoring_scene(definition.dressing_scene_path, track_id)
		if BACKYARD_TRACK_IDS.has(track_id):
			var authored_definition = TrackSceneAuthoringData.apply_to_definition(definition)
			assert_true(authored_definition.grass_zones.size() >= 2, "%s should expose editable grass zones" % track_id)
			assert_true((authored_definition.to_metadata().get("grass_zones", []) as Array).size() >= 2, "%s metadata should export grass zones" % track_id)

func test_archive_preserves_old_packages_without_catalog_entries() -> void:
	assert_true(FileAccess.file_exists("%s/README.md" % ARCHIVE_ROOT), "Archive README should document the legacy stage package move")
	for track_id in ACTIVE_TRACK_IDS:
		assert_true(FileAccess.file_exists("%s/%s/%s_track_metadata.json" % [ARCHIVE_ROOT, track_id, track_id]), "%s old metadata should be archived" % track_id)
		assert_true(ResourceLoader.exists("%s/%s/%s_track_definition.tres" % [ARCHIVE_ROOT, track_id, track_id]), "%s old definition should be archived" % track_id)

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
	if BACKYARD_TRACK_IDS.has(track_id):
		assert_true(root.get_node_or_null("SharedBackyardBase") != null, "%s should instance the shared backyard base" % track_id)
		assert_true(root.get_node_or_null("SharedBackyardBase/VisibleCourseTerritories/SandboxTerritory") != null, "%s should see the sandbox territory" % track_id)
		assert_true(root.get_node_or_null("SharedBackyardBase/VisibleCourseTerritories/GardenTerritory") != null, "%s should see the garden territory" % track_id)
		assert_true(root.get_node_or_null("SharedBackyardBase/VisibleCourseTerritories/PlaygroundTerritory") != null, "%s should see the playground territory" % track_id)
		assert_true(root.get_node("GrassZones").get_child_count() >= 2, "%s should expose multiple editable grass zones" % track_id)
		assert_true(_has_editable_grass_zone_bounds(root.get_node("GrassZones")), "%s grass zones should expose editable Area3D bounds and visible editor previews" % track_id)
		assert_true(root.get_node_or_null("SharedBackyardBase/RoutePoints") == null, "%s shared backyard base should not include active gameplay route markers" % track_id)
	assert_true(root.get_node("RoutePoints").get_child_count() >= 9, "%s should expose route markers" % track_id)
	assert_equal(root.get_node("SpawnPoints").get_child_count(), 8, "%s should expose editable spawn markers" % track_id)
	assert_true(root.get_node("Dressing").get_child_count() >= 6, "%s should expose editable dressing props" % track_id)
	assert_true(root.get_node("SignatureEffects").get_child_count() >= 1, "%s should expose a signature effect hook" % track_id)
	root.queue_free()

func _has_editable_grass_zone_bounds(holder: Node) -> bool:
	for child in holder.get_children():
		if child is Area3D and child.get_node_or_null("CollisionShape3D") is CollisionShape3D and child.get_node_or_null("BoundsPreview") is MeshInstance3D:
			return true
	return false

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
