extends "res://tests/framework/TestCase.gd"

const TrackCatalog = preload("res://scripts/track/TrackCatalog.gd")
const TrackMetadataExporter = preload("res://scripts/track/TrackMetadataExporter.gd")

func test_kitchen_metadata_matches_server_shape() -> void:
	var definition := TrackCatalog.get_definition("kitchen")
	var metadata := TrackMetadataExporter.metadata_for(definition)
	assert_equal(str(metadata.get("id", "")), "kitchen", "Metadata should include track id")
	assert_equal(str(metadata.get("track_id", "")), "kitchen", "Metadata should include stable server track id")
	assert_equal(str(metadata.get("version", "")), "kitchen_v2_2026_04_29", "Metadata should include the cooked track package version")
	assert_equal(int(metadata.get("laps", 0)), 3, "Metadata should export the longer 3-lap Kitchen race length")
	assert_equal((metadata.get("route_points", []) as Array).size(), 38, "Metadata should export route points")
	assert_equal((metadata.get("checkpoints", []) as Array).size(), 6, "Metadata should export checkpoints")
	assert_equal((metadata.get("spawn_points", []) as Array).size(), 8, "Metadata should export 8 spawns")
	assert_equal((metadata.get("item_sockets", []) as Array).size(), 10, "Metadata should export 10 item sockets")
	assert_equal((metadata.get("hazard_sockets", []) as Array).size(), 8, "Metadata should export 8 hazard sockets")
	assert_equal((metadata.get("shortcut_gates", []) as Array).size(), 1, "Metadata should export the table shortcut")
	assert_true((metadata.get("stage_props", []) as Array).size() >= 10, "Metadata should export stage props")
	assert_equal((metadata.get("surface_segments", []) as Array).size(), 3, "Metadata should export surface segments")
	assert_equal((metadata.get("audio_zones", []) as Array).size(), 3, "Metadata should export audio zones")
	assert_equal(bool(((metadata.get("shortcut_gates", []) as Array)[0] as Dictionary).get("surface_enabled", true)), false, "Metadata should mark the blocking table shortcut surface disabled")
	assert_equal(str(metadata.get("reset_mode", "")), "instant_pop", "Metadata should include reset mode")
	assert_equal(float(metadata.get("out_of_bounds_y", 0.0)), 1.5, "Metadata should include out-of-bounds height")
	assert_true(float(metadata.get("floor_visual_y", 0.0)) <= -8.0, "Metadata should keep the visible floor far below the countertop")
	assert_true(float(metadata.get("route_length", 0.0)) > 950.0, "Metadata should include the full looped countertop route length")

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
