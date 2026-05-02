extends "res://tests/framework/TestCase.gd"

const TrackCatalog = preload("res://scripts/track/TrackCatalog.gd")
const TrackMetadataExporter = preload("res://scripts/track/TrackMetadataExporter.gd")
const StageSky = preload("res://scripts/track/StageSky.gd")
const TrackDefinition = preload("res://scripts/track/TrackDefinition.gd")

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

func test_toybox_metadata_matches_server_shape() -> void:
	for track_id in ACTIVE_TRACK_IDS:
		var definition := TrackCatalog.get_definition(track_id)
		var metadata := TrackMetadataExporter.metadata_for(definition)
		assert_equal(str(metadata.get("id", "")), track_id, "%s metadata should include track id" % track_id)
		assert_equal(str(metadata.get("track_id", "")), track_id, "%s metadata should include stable server track id" % track_id)
		assert_true(str(metadata.get("version", "")).contains("_toybox_v1_2026_05_02"), "%s metadata should include Toybox package version" % track_id)
		assert_equal(int(metadata.get("laps", 0)), 3, "%s metadata should export 3 laps" % track_id)
		assert_true((metadata.get("route_points", []) as Array).size() >= 9, "%s metadata should export route points" % track_id)
		assert_equal((metadata.get("checkpoints", []) as Array).size(), 6, "%s metadata should export checkpoints" % track_id)
		assert_equal((metadata.get("spawn_points", []) as Array).size(), 8, "%s metadata should export 8 spawns" % track_id)
		assert_equal((metadata.get("item_sockets", []) as Array).size(), 8, "%s metadata should export item sockets" % track_id)
		assert_equal((metadata.get("hazard_sockets", []) as Array).size(), 6, "%s metadata should export hazard sockets" % track_id)
		assert_equal((metadata.get("shortcut_gates", []) as Array).size(), 1, "%s metadata should export shortcut gates" % track_id)
		assert_equal((metadata.get("alternate_routes", []) as Array).size(), 1, "%s metadata should export alternate routes" % track_id)
		assert_true((metadata.get("stage_props", []) as Array).size() >= 6, "%s metadata should export visible stage props" % track_id)
		assert_equal((metadata.get("surface_segments", []) as Array).size(), 3, "%s metadata should export surface segments" % track_id)
		assert_equal((metadata.get("audio_zones", []) as Array).size(), 3, "%s metadata should export audio zones" % track_id)
		assert_equal(str(metadata.get("reset_mode", "")), "instant_pop", "%s metadata should include reset mode" % track_id)
		assert_true(float(metadata.get("out_of_bounds_y", 0.0)) < -10.0, "%s out-of-bounds height should sit below the authored floor" % track_id)
		assert_true(float(metadata.get("floor_visual_y", 0.0)) <= -32.0, "%s visible floor should sit below the track" % track_id)
		assert_equal(str(metadata.get("rail_texture_path", "")), "res://assets/gameplay/materials/metal/toy_metal_albedo.png", "%s metadata should include stage rail texture" % track_id)
		assert_equal(float(metadata.get("rail_texture_uv_scale", 0.0)), 0.5, "%s metadata should include stage rail UV scale" % track_id)
		assert_true((metadata.get("sky_top_color", []) as Array).size() == 4, "%s metadata should export sky top color" % track_id)
		assert_equal(str(metadata.get("dressing_scene_path", "")), "res://assets/gameplay/tracks/%s/%s_editable_room.tscn" % [track_id, track_id], "%s metadata should expose the editable dressing scene" % track_id)
		assert_true(float(metadata.get("route_length", 0.0)) > 300.0, "%s metadata should include a playable loop length" % track_id)

func test_stage_sky_falls_back_without_definition_fields() -> void:
	var definition := TrackDefinition.new()
	definition.sky_preset_id = ""
	var sky := StageSky.build_sky(definition)
	assert_true(sky.sky_material is ProceduralSkyMaterial, "Missing sky preset should use the generic procedural sky fallback")

func test_metadata_json_is_parseable() -> void:
	for track_id in ACTIVE_TRACK_IDS:
		var definition := TrackCatalog.get_definition(track_id)
		var parsed = JSON.parse_string(TrackMetadataExporter.json_for(definition))
		assert_true(parsed is Dictionary, "%s exported metadata JSON should parse" % track_id)
		assert_equal(str((parsed as Dictionary).get("id", "")), track_id, "%s parsed JSON should preserve track id" % track_id)

func test_track_catalog_uses_active_toybox_package_metadata() -> void:
	for track_id in ACTIVE_TRACK_IDS:
		var package := TrackCatalog.get_package(track_id)
		assert_equal(str(package.get("scene_path", "")), "res://assets/gameplay/tracks/%s/%s_track.tscn" % [track_id, track_id], "%s catalog should expose the active client scene path" % track_id)
		assert_equal(str(package.get("definition_path", "")), "res://assets/gameplay/tracks/%s/%s_track_definition.tres" % [track_id, track_id], "%s catalog should expose the active definition path" % track_id)
		assert_equal(str(package.get("metadata_path", "")), "res://assets/gameplay/tracks/%s/%s_track_metadata.json" % [track_id, track_id], "%s catalog should expose exported server metadata" % track_id)
		assert_true(str(package.get("version", "")).contains("_toybox_v1_2026_05_02"), "%s catalog should expose the Toybox package version" % track_id)
		var metadata := TrackCatalog.get_metadata(track_id)
		assert_equal(int(metadata.get("laps", 0)), 3, "%s catalog metadata should come from the exported metadata JSON" % track_id)
		assert_equal(str(metadata.get("runtime_scene_path", "")), str(package.get("scene_path", "")), "%s catalog should stamp scene path into metadata" % track_id)
		assert_equal(str(metadata.get("metadata_path", "")), str(package.get("metadata_path", "")), "%s catalog should stamp metadata path into returned metadata" % track_id)
