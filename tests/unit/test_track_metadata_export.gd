extends "res://tests/framework/TestCase.gd"

const TrackCatalog = preload("res://scripts/track/TrackCatalog.gd")
const TrackMetadataExporter = preload("res://scripts/track/TrackMetadataExporter.gd")
const StageSky = preload("res://scripts/track/StageSky.gd")
const TrackDefinition = preload("res://scripts/track/TrackDefinition.gd")

func test_kitchen_metadata_matches_server_shape() -> void:
	var definition := TrackCatalog.get_definition("kitchen")
	var metadata := TrackMetadataExporter.metadata_for(definition)
	assert_equal(str(metadata.get("id", "")), "kitchen", "Metadata should include track id")
	assert_equal(str(metadata.get("track_id", "")), "kitchen", "Metadata should include stable server track id")
	assert_equal(str(metadata.get("version", "")), "kitchen_v2_2026_04_29", "Metadata should include the cooked track package version")
	assert_equal(int(metadata.get("laps", 0)), 3, "Metadata should export the longer 3-lap Kitchen race length")
	assert_true((metadata.get("road_grid_layout", {}) as Dictionary).size() > 0, "Metadata should export authored RoadGridMap layout data")
	assert_true((metadata.get("route_points", []) as Array).size() >= (((metadata.get("road_grid_layout", {}) as Dictionary).get("ordered_route_cells", [])) as Array).size(), "Metadata should export route points generated from grid cells")
	assert_equal((metadata.get("checkpoints", []) as Array).size(), 6, "Metadata should export checkpoints")
	assert_equal((metadata.get("spawn_points", []) as Array).size(), 8, "Metadata should export 8 spawns")
	assert_equal((metadata.get("item_sockets", []) as Array).size(), 10, "Metadata should export 10 item sockets")
	assert_equal((metadata.get("hazard_sockets", []) as Array).size(), 8, "Metadata should export 8 hazard sockets")
	assert_equal((metadata.get("shortcut_gates", []) as Array).size(), 1, "Metadata should export the table shortcut")
	assert_equal((metadata.get("alternate_routes", []) as Array).size(), 0, "Metadata should export an empty alternate route list for tracks without branches")
	assert_true((metadata.get("stage_props", []) as Array).size() >= 10, "Metadata should export stage props")
	assert_equal((metadata.get("surface_segments", []) as Array).size(), 3, "Metadata should export surface segments")
	assert_equal((metadata.get("audio_zones", []) as Array).size(), 4, "Metadata should export audio zones")
	var audio_ids := metadata.get("audio_ids", {}) as Dictionary
	assert_equal(str(audio_ids.get("sink_splash", "")), "res://assets/source/audio/canva/tracks/kitchen/kitchen_sink_water.mp3", "Metadata should use the supplied sink water audio")
	assert_equal(str(audio_ids.get("stove_sizzle", "")), "res://assets/source/audio/canva/tracks/kitchen/kitchen_oven_sizzle.mp3", "Metadata should include the converted oven sizzle audio")
	assert_equal(bool(((metadata.get("shortcut_gates", []) as Array)[0] as Dictionary).get("surface_enabled", true)), false, "Metadata should mark the blocking table shortcut surface disabled")
	assert_equal(str(metadata.get("reset_mode", "")), "instant_pop", "Metadata should include reset mode")
	assert_true(float(metadata.get("out_of_bounds_y", 0.0)) < -10.0, "Metadata should keep the out-of-bounds height below the authored floor")
	assert_true(float(metadata.get("floor_visual_y", 0.0)) <= -8.0, "Metadata should keep the visible floor far below the countertop")
	assert_equal(str(metadata.get("rail_texture_path", "")), "res://assets/gameplay/materials/metal/toy_metal_albedo.png", "Metadata should include the stage rail texture")
	assert_equal(float(metadata.get("rail_texture_uv_scale", 0.0)), 0.5, "Metadata should include the stage rail texture UV scale")
	assert_equal(str(metadata.get("sky_preset_id", "")), "noon_clear", "Metadata should include Kitchen sky preset")
	assert_equal(str(metadata.get("sky_weather", "")), "clear", "Metadata should include Kitchen sky weather")
	assert_equal(float(metadata.get("sky_cloud_amount", -1.0)), 0.16, "Metadata should include Kitchen sky cloud amount")
	assert_equal((metadata.get("sky_top_color", []) as Array).size(), 4, "Metadata should export Kitchen sky top color")
	assert_equal(str(metadata.get("dressing_scene_path", "")), "res://assets/gameplay/tracks/kitchen/kitchen_editable_room.tscn", "Metadata should expose the editable dressing scene")
	assert_true(float(metadata.get("route_length", 0.0)) > 700.0, "Metadata should include the full looped countertop route length")

func test_stage_sky_falls_back_without_definition_fields() -> void:
	var definition := TrackDefinition.new()
	definition.sky_preset_id = ""
	var sky := StageSky.build_sky(definition)
	assert_true(sky.sky_material is ProceduralSkyMaterial, "Missing sky preset should use the generic procedural sky fallback")

func test_kitchen_metadata_json_is_parseable() -> void:
	var definition := TrackCatalog.get_definition("kitchen")
	var parsed = JSON.parse_string(TrackMetadataExporter.json_for(definition))
	assert_true(parsed is Dictionary, "Exported metadata JSON should parse")
	assert_equal(str((parsed as Dictionary).get("id", "")), "kitchen", "Parsed JSON should preserve track id")

func test_track_catalog_uses_cooked_package_metadata() -> void:
	var package := TrackCatalog.get_package("kitchen")
	assert_equal(str(package.get("scene_path", "")), "res://assets/gameplay/tracks/kitchen/kitchen_track.tscn", "Catalog should expose the cooked client scene path")
	assert_equal(str(package.get("definition_path", "")), "res://assets/gameplay/tracks/kitchen/kitchen_track_definition.tres", "Catalog should expose the authored runtime definition")
	assert_equal(str(package.get("metadata_path", "")), "res://assets/gameplay/tracks/kitchen/kitchen_track_metadata.json", "Catalog should expose exported server metadata")
	assert_equal(str(package.get("version", "")), "kitchen_v2_2026_04_29", "Catalog should expose the package version")
	var metadata := TrackCatalog.get_metadata("kitchen")
	assert_equal(int(metadata.get("laps", 0)), 3, "Catalog metadata should come from the exported Kitchen metadata JSON")
	assert_equal(str(metadata.get("runtime_scene_path", "")), str(package.get("scene_path", "")), "Catalog should stamp scene path into metadata for client/server compatibility checks")
	assert_equal(str(metadata.get("metadata_path", "")), str(package.get("metadata_path", "")), "Catalog should stamp metadata path into returned metadata")
