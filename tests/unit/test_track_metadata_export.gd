extends "res://tests/framework/TestCase.gd"

const TrackCatalog = preload("res://scripts/track/TrackCatalog.gd")
const TrackMetadataExporter = preload("res://scripts/track/TrackMetadataExporter.gd")

func test_kitchen_metadata_matches_server_shape() -> void:
	var definition := TrackCatalog.get_definition("kitchen")
	var metadata := TrackMetadataExporter.metadata_for(definition)
	assert_equal(str(metadata.get("id", "")), "kitchen", "Metadata should include track id")
	assert_equal((metadata.get("route_points", []) as Array).size(), 8, "Metadata should export route points")
	assert_equal((metadata.get("checkpoints", []) as Array).size(), 4, "Metadata should export checkpoints")
	assert_equal((metadata.get("spawn_points", []) as Array).size(), 8, "Metadata should export 8 spawns")
	assert_true(float(metadata.get("route_length", 0.0)) > 300.0, "Metadata should include route length")

func test_kitchen_metadata_json_is_parseable() -> void:
	var definition := TrackCatalog.get_definition("kitchen")
	var parsed = JSON.parse_string(TrackMetadataExporter.json_for(definition))
	assert_true(parsed is Dictionary, "Exported metadata JSON should parse")
	assert_equal(str((parsed as Dictionary).get("id", "")), "kitchen", "Parsed JSON should preserve track id")
