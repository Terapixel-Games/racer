extends "res://tests/framework/TestCase.gd"

const TrackCatalog = preload("res://scripts/track/TrackCatalog.gd")
const TrackDefinition = preload("res://scripts/track/TrackDefinition.gd")
const TrackSceneAuthoringData = preload("res://scripts/track/TrackSceneAuthoringData.gd")

const SELECTABLE_TRACK_IDS := [
	"kitchen",
	"attic",
	"bedroom",
	"garden",
	"glam_closet",
	"outdoor_playground",
	"playroom",
	"sandbox",
]
const BACKYARD_TRACK_IDS := [
	"outdoor_playground",
	"garden",
	"sandbox",
]
const EXPECTED_STAGE_SKY_PRESETS := {
	"kitchen": "noon_clear",
	"attic": "stormy_moonlight_night",
	"bedroom": "soft_morning",
	"garden": "fresh_morning",
	"glam_closet": "night_city_glow",
	"outdoor_playground": "clear_afternoon",
	"playroom": "party_evening",
	"sandbox": "hot_afternoon",
}
const LEGACY_GAMEPLAY_NODES := [
	"TrackAuthoringPreview",
	"RoutePoints",
	"RoadSegments",
	"SpawnPoints",
	"Checkpoints",
	"ItemSockets",
	"HazardSockets",
]
const INDOOR_FLOOR_SIZE := Vector2(360.0, 240.0)
const BACKYARD_FLOOR_SIZE := Vector2(900.0, 720.0)
const KITCHEN_DEFINITION_GROUND_SIZE := Vector2(560.0, 400.0)
const KITCHEN_EDITABLE_FLOOR_SIZE := Vector2(560.0, 400.0)
const OUTDOOR_GRASS_SHADER := "res://assets/gameplay/materials/grass/playground_grass.gdshader"
const OUTDOOR_PLAYGROUND_FLOOR_TEXTURE := "res://assets/gameplay/materials/playground/outdoor_playground_floor_albedo.png"
const BACKYARD_PREVIEW_SHELL := "res://assets/gameplay/tracks/shared/backyard_optimized/backyard_preview_shell.tscn"
const OLD_BACKYARD_RESOURCE_MARKERS := [
	"wooden_playground_set_static.glb",
	"wooden_playground_set_swing.glb",
	"trex_skeleton.glb",
]

func test_list_tracks_returns_default_first_summary() -> void:
	var tracks := TrackCatalog.list_tracks()
	assert_equal(tracks.size(), SELECTABLE_TRACK_IDS.size(), "Track catalog should expose the eight MVP GridMap tracks")
	var first: Dictionary = tracks[0]
	assert_equal(str(first.get("id", "")), TrackCatalog.get_default_track_id(), "Default track should appear first")
	assert_equal(str(first.get("display_name", "")), "Kitchen / Sir Clink", "Track summary should expose display name")
	assert_true(str(first.get("scene_path", "")).ends_with(".tscn"), "Track summary should expose runtime scene path")
	assert_true(str(first.get("definition_path", "")).ends_with(".tres"), "Track summary should expose definition path")
	assert_true(str(first.get("metadata_path", "")).ends_with(".json"), "Track summary should expose metadata path")

func test_catalog_exposes_only_gridmap_backed_tracks() -> void:
	var listed_ids: Array[String] = []
	for summary in TrackCatalog.list_tracks():
		var track_id := str(summary.get("id", ""))
		listed_ids.append(track_id)
		assert_true(SELECTABLE_TRACK_IDS.has(track_id), "%s should be one of the selectable MVP tracks" % track_id)
		var definition := TrackCatalog.get_definition(track_id)
		assert_true(definition is TrackDefinition, "%s definition should load" % track_id)
		if definition is TrackDefinition:
			_assert_gridmap_contract(definition, track_id)
	for expected_id in SELECTABLE_TRACK_IDS:
		assert_true(listed_ids.has(expected_id), "%s should remain selectable" % expected_id)

func test_tracks_without_real_gridmap_metadata_fail_validation() -> void:
	var definition := TrackDefinition.new()
	definition.id = "no_grid_fixture"
	definition.display_name = "No Grid Fixture"
	definition.laps = 3
	definition.track_source_id = "road_grid_map"
	definition.road_visual_style = "kenney_gridmap"
	definition.road_width = 16.0
	definition.route_points = [
		Vector3(0, 0, 0),
		Vector3(16, 0, 0),
		Vector3(16, 0, 16),
		Vector3(0, 0, 16),
	]
	definition.checkpoint_indices = [0, 1, 2, 3]
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
	assert_true(authored.road_grid_layout.is_empty(), "Legacy route data should not synthesize GridMap metadata")
	assert_true(authored.validate().has("Track must include RoadGridMap layout metadata."), "Definitions without real RoadGridMap metadata should fail validation")

func test_track_sky_presets_match_stage_plan() -> void:
	for track_id in EXPECTED_STAGE_SKY_PRESETS.keys():
		var definition := TrackCatalog.get_definition(str(track_id))
		assert_true(definition != null, "%s definition should load" % track_id)
		assert_equal(definition.sky_preset_id, str(EXPECTED_STAGE_SKY_PRESETS[track_id]), "%s should use the planned sky preset" % track_id)
		var metadata: Dictionary = TrackCatalog.get_metadata(str(track_id))
		assert_equal(str(metadata.get("sky_preset_id", "")), str(EXPECTED_STAGE_SKY_PRESETS[track_id]), "%s package metadata should export the planned sky preset" % track_id)

func test_authoring_scenes_use_road_gridmap_without_legacy_gameplay_nodes() -> void:
	var backyard_positions := {}
	for track_id in SELECTABLE_TRACK_IDS:
		var definition := TrackCatalog.get_definition(track_id)
		assert_true(definition != null, "%s definition should load" % track_id)
		var packed := load(definition.dressing_scene_path) as PackedScene
		assert_true(packed != null, "%s editable scene should load" % track_id)
		if packed == null:
			continue
		var root := packed.instantiate()
		assert_true(root != null, "%s editable scene should instantiate" % track_id)
		if root == null:
			continue
		for legacy_name in LEGACY_GAMEPLAY_NODES:
			assert_true(root.find_child(legacy_name, true, false) == null, "%s should not keep legacy gameplay node %s" % [track_id, legacy_name])
		var grid := _find_authoring_road_grid(root)
		assert_true(grid != null and grid.has_method("to_grid_road_layout"), "%s should author gameplay through RoadGridMap" % track_id)
		if grid != null:
			assert_equal((grid.get("spawn_slots") as Array).size(), 8, "%s RoadGridMap should author exactly 8 spawn slots" % track_id)
			if BACKYARD_TRACK_IDS.has(track_id):
				backyard_positions[track_id] = (grid as Node3D).position
		var dressing := root.get_node_or_null("Dressing")
		if track_id != "kitchen":
			var expected_dressing_count := 3 if BACKYARD_TRACK_IDS.has(track_id) else 4
			assert_true(dressing != null and dressing.get_child_count() >= expected_dressing_count, "%s should retain editable visual dressing" % track_id)
		if BACKYARD_TRACK_IDS.has(track_id):
			assert_true(root.get_node_or_null("BackyardShell") != null, "%s should instance the shared backyard shell" % track_id)
		assert_equal(_floor_mesh_size_from_root(root), _expected_editable_floor_size(track_id), "%s editable floor should match its stage shell scale" % track_id)
		root.queue_free()
	assert_true(backyard_positions.size() == BACKYARD_TRACK_IDS.size(), "Backyard trio should all expose RoadGridMap positions")
	assert_true(backyard_positions["outdoor_playground"] != backyard_positions["garden"], "Dash and Moko tracks should occupy different backyard areas")
	assert_true(backyard_positions["garden"] != backyard_positions["sandbox"], "Moko and Rexx tracks should occupy different backyard areas")
	assert_true(backyard_positions["outdoor_playground"] != backyard_positions["sandbox"], "Dash and Rexx tracks should occupy different backyard areas")

func _assert_gridmap_contract(definition: TrackDefinition, track_id: String) -> void:
	assert_equal(definition.validate(), [], "%s definition should validate" % track_id)
	assert_equal(definition.track_source_id, "road_grid_map", "%s should resolve as a GridMap track" % track_id)
	assert_equal(definition.road_visual_style, "kenney_gridmap", "%s should use GridMap road visuals" % track_id)
	assert_equal(definition.road_width, 16.0, "%s should use the fixed MVP road width" % track_id)
	assert_equal(definition.rails_enabled, false, "%s should not build rails in the GridMap MVP" % track_id)
	assert_equal(definition.boundary_walls_enabled, true, "%s should build invisible boundary containment" % track_id)
	assert_equal(definition.boundary_wall_debug_visible, false, "%s should hide boundary debug meshes by default" % track_id)
	assert_equal(definition.laps, 3, "%s should run 3 laps" % track_id)
	assert_true(not definition.road_grid_layout.is_empty(), "%s should expose GridMap layout metadata" % track_id)
	assert_equal(definition.road_segment_layout.size(), 0, "%s should not use legacy segment layout data" % track_id)
	assert_true(definition.route_points.size() >= 12, "%s route should be generated from GridMap route cells" % track_id)
	assert_true(definition.checkpoint_indices.size() >= 5, "%s should expose at least 5 checkpoints" % track_id)
	assert_equal(definition.lap_gate_checkpoint_index, 0, "%s checkpoint 0 should be the lap gate" % track_id)
	assert_equal(definition.spawn_points.size(), 8, "%s should expose exactly 8 spawns" % track_id)
	assert_equal(definition.item_sockets.size(), 0, "%s MVP metadata should not export item sockets" % track_id)
	assert_equal(definition.hazard_sockets.size(), 0, "%s MVP metadata should not export hazard sockets" % track_id)
	assert_equal(str(definition.road_grid_layout.get("mesh_library_path", "")), "res://assets/source/kenney/racing_kit/racer_road_mesh_library.tres", "%s should use the shared Kenney GridMap mesh library" % track_id)
	assert_true((definition.road_grid_layout.get("ordered_route_cells", []) as Array).size() >= 12, "%s should export ordered GridMap route cells" % track_id)
	assert_equal((definition.road_grid_layout.get("spawn_slots", []) as Array).size(), 8, "%s should export RoadGridMap spawn slots" % track_id)
	assert_equal(definition.sky_preset_id, str(EXPECTED_STAGE_SKY_PRESETS[track_id]), "%s should use its stage sky preset" % track_id)
	var expected_ground_shader := OUTDOOR_GRASS_SHADER if track_id == "outdoor_playground" else ""
	assert_equal(definition.ground_shader_path, expected_ground_shader, "%s should use the expected ground shader" % track_id)
	if track_id == "outdoor_playground":
		assert_equal(definition.ground_texture_path, OUTDOOR_PLAYGROUND_FLOOR_TEXTURE, "Outdoor Playground should use the authored floor texture")
	assert_equal(definition.ground_size, _expected_definition_ground_size(track_id), "%s definition should match its runtime ground dimensions" % track_id)
	if BACKYARD_TRACK_IDS.has(track_id):
		assert_equal(definition.preview_dressing_scene_path, BACKYARD_PREVIEW_SHELL, "%s should use the optimized backyard preview dressing" % track_id)
	else:
		assert_equal(definition.preview_dressing_scene_path, "", "%s should not require preview-only dressing" % track_id)
	var metadata: Dictionary = definition.to_metadata()
	assert_equal(str(metadata.get("track_source_id", "")), "road_grid_map", "%s metadata should export GridMap source" % track_id)
	assert_equal(str(metadata.get("progress_rule_id", "")), "route_lap_progress", "%s metadata should export route progress rules" % track_id)
	assert_equal(str(metadata.get("win_condition_id", "")), "checkpoint_laps", "%s metadata should export checkpoint lap rules" % track_id)
	assert_equal(bool(metadata.get("boundary_walls_enabled", false)), true, "%s metadata should export boundary wall containment" % track_id)
	assert_equal(bool(metadata.get("rails_enabled", true)), false, "%s metadata should export disabled rails" % track_id)
	assert_equal(str(metadata.get("preview_dressing_scene_path", "")), definition.preview_dressing_scene_path, "%s metadata should export preview dressing path" % track_id)

func test_backyard_scenes_do_not_reference_old_meshy_landmarks() -> void:
	for track_id in BACKYARD_TRACK_IDS:
		var definition := TrackCatalog.get_definition(track_id)
		assert_true(definition != null, "%s definition should load" % track_id)
		if definition == null:
			continue
		_assert_scene_text_excludes_old_backyard_resources(definition.dressing_scene_path)
		_assert_scene_text_excludes_old_backyard_resources(definition.preview_dressing_scene_path)

func _assert_scene_text_excludes_old_backyard_resources(path: String) -> void:
	assert_true(ResourceLoader.exists(path), "%s should exist" % path)
	var file := FileAccess.open(path, FileAccess.READ)
	assert_true(file != null, "%s should be readable" % path)
	if file == null:
		return
	var text := file.get_as_text()
	file.close()
	for marker in OLD_BACKYARD_RESOURCE_MARKERS:
		assert_true(not text.contains(marker), "%s should not reference old heavy resource %s" % [path, marker])

func _find_authoring_road_grid(root: Node) -> Node:
	var direct := root.get_node_or_null("RoadGridMap")
	if direct != null:
		return direct
	var nested := root.get_node_or_null("Track/RoadGridMap")
	if nested != null:
		return nested
	return null

func _expected_definition_ground_size(track_id: String) -> Vector2:
	if track_id == "kitchen":
		return KITCHEN_DEFINITION_GROUND_SIZE
	if BACKYARD_TRACK_IDS.has(track_id):
		return BACKYARD_FLOOR_SIZE
	return INDOOR_FLOOR_SIZE

func _expected_editable_floor_size(track_id: String) -> Vector2:
	if track_id == "kitchen":
		return KITCHEN_EDITABLE_FLOOR_SIZE
	if BACKYARD_TRACK_IDS.has(track_id):
		return BACKYARD_FLOOR_SIZE
	return INDOOR_FLOOR_SIZE

func _floor_mesh_size_from_root(root: Node) -> Vector2:
	var mesh_instance := root.get_node_or_null("floor/MeshInstance3D") as MeshInstance3D
	if mesh_instance == null:
		mesh_instance = root.get_node_or_null("BackyardShell/floor/MeshInstance3D") as MeshInstance3D
	if mesh_instance == null:
		mesh_instance = root.get_node_or_null("Track/floor/MeshInstance3D") as MeshInstance3D
	if mesh_instance == null:
		var floor_holder := root.find_child("floor", true, false)
		if floor_holder != null:
			mesh_instance = floor_holder.get_node_or_null("MeshInstance3D") as MeshInstance3D
	if mesh_instance != null and mesh_instance.mesh is PlaneMesh:
		return (mesh_instance.mesh as PlaneMesh).size
	return Vector2.ZERO
