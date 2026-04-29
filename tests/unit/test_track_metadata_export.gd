extends "res://tests/framework/TestCase.gd"

const TrackCatalog = preload("res://scripts/track/TrackCatalog.gd")
const TrackMetadataExporter = preload("res://scripts/track/TrackMetadataExporter.gd")

func test_kitchen_metadata_matches_server_shape() -> void:
	var definition := TrackCatalog.get_definition("kitchen")
	var metadata := TrackMetadataExporter.metadata_for(definition)
	assert_equal(str(metadata.get("id", "")), "kitchen", "Metadata should include track id")
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
	assert_true(float(metadata.get("route_length", 0.0)) > 950.0, "Metadata should include the full looped countertop route length")

func test_kitchen_metadata_json_is_parseable() -> void:
	var definition := TrackCatalog.get_definition("kitchen")
	var parsed = JSON.parse_string(TrackMetadataExporter.json_for(definition))
	assert_true(parsed is Dictionary, "Exported metadata JSON should parse")
	assert_equal(str((parsed as Dictionary).get("id", "")), "kitchen", "Parsed JSON should preserve track id")
