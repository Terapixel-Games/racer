extends "res://tests/framework/TestCase.gd"

const PlayerTrackBuildRules = preload("res://scripts/track_builder/PlayerTrackBuildRules.gd")

func test_navigation_build_accepts_connected_open_path() -> void:
	var build := PlayerTrackBuildRules.empty_build("user-a", "home_yard_v3")
	PlayerTrackBuildRules.add_or_replace_piece(build, {"piece_id": "endpoint", "cell": Vector3i(0, 0, 0)})
	PlayerTrackBuildRules.add_or_replace_piece(build, {"piece_id": "straight", "cell": Vector3i(1, 0, 0)})
	PlayerTrackBuildRules.add_or_replace_piece(build, {"piece_id": "straight", "cell": Vector3i(2, 0, 0)})
	var result := PlayerTrackBuildRules.validate_navigation(build)
	assert_equal(result.get("status", ""), "navigation_valid", "Connected open paths should be valid for navigation")
	assert_equal(build.route_cells.size(), 3, "Navigation validation should produce route cells")
	assert_equal(PlayerTrackBuildRules.validate_race(build).get("status", ""), "invalid", "Open navigation paths should not promote as race tracks")

func test_disconnected_path_is_invalid_for_navigation() -> void:
	var build := PlayerTrackBuildRules.empty_build("user-a", "home_yard_v3")
	PlayerTrackBuildRules.add_or_replace_piece(build, {"piece_id": "straight", "cell": Vector3i(0, 0, 0)})
	PlayerTrackBuildRules.add_or_replace_piece(build, {"piece_id": "straight", "cell": Vector3i(3, 0, 0)})
	var result := PlayerTrackBuildRules.validate_navigation(build)
	assert_equal(result.get("status", ""), "invalid", "Disconnected build pieces should fail navigation validation")

func test_closed_loop_promotes_to_track_definition() -> void:
	var build := PlayerTrackBuildRules.empty_build("user-a", "home_yard_v3")
	build.build_id = "loop-a"
	build.display_name = "Loop A"
	PlayerTrackBuildRules.add_or_replace_piece(build, {"piece_id": "endpoint", "cell": Vector3i(0, 0, 0)})
	PlayerTrackBuildRules.add_or_replace_piece(build, {"piece_id": "straight", "cell": Vector3i(1, 0, 0)})
	PlayerTrackBuildRules.add_or_replace_piece(build, {"piece_id": "corner", "cell": Vector3i(1, 0, 1)})
	PlayerTrackBuildRules.add_or_replace_piece(build, {"piece_id": "corner", "cell": Vector3i(0, 0, 1)})
	var result := PlayerTrackBuildRules.validate_race(build)
	assert_equal(result.get("status", ""), "race_valid", "Closed loops should be race promotion eligible")
	var definition := PlayerTrackBuildRules.promote_to_track_definition(build, {"track_id": "player_loop_a"})
	assert_true(definition != null, "Race-valid builds should promote to TrackDefinition")
	if definition != null:
		assert_equal(definition.id, "player_loop_a", "Promoted track id should be applied")
		assert_equal(definition.track_source_id, "road_grid_map", "Promoted tracks should reuse RoadGridMap source")
		assert_equal(definition.spawn_points.size(), 8, "Promoted tracks should generate 8 spawn slots")
		assert_equal(definition.validate(), [], "Promoted track definition should pass public validation")

func test_protected_zone_blocks_navigation() -> void:
	var build := PlayerTrackBuildRules.empty_build("user-a", "home_yard_v3")
	PlayerTrackBuildRules.add_or_replace_piece(build, {"piece_id": "straight", "cell": Vector3i(0, 0, 0)})
	PlayerTrackBuildRules.add_or_replace_piece(build, {"piece_id": "straight", "cell": Vector3i(1, 0, 0)})
	var zones: Array[Dictionary] = [{
		"id": "wall",
		"min": Vector3(0, 0, 0),
		"max": Vector3(20, 8, 20),
	}]
	var result := PlayerTrackBuildRules.validate_navigation(build, zones)
	assert_equal(result.get("status", ""), "invalid", "Build pieces inside protected zones should fail validation")
