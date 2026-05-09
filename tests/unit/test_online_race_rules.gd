extends "res://tests/framework/TestCase.gd"

const OnlineRaceRules = preload("res://scripts/logic/OnlineRaceRules.gd")

func test_online_mode_normalization_and_room_code_cleanup() -> void:
	assert_equal(OnlineRaceRules.normalize_mode("online_tournament"), OnlineRaceRules.MODE_TOURNAMENT, "Online tournament mode should normalize to tournament")
	assert_equal(OnlineRaceRules.normalize_mode(""), OnlineRaceRules.MODE_SINGLE_RACE, "Blank online mode should default to single race")
	assert_equal(OnlineRaceRules.normalize_room_code(" ab-12 c "), "AB12C", "Room codes should normalize for user entry")

func test_single_race_track_selection_prefers_requested_track() -> void:
	var tracks := [
		{"id": "kitchen"},
		{"id": "sandbox"},
		{"id": "attic"},
	]
	var selected := OnlineRaceRules.select_track_ids(tracks, OnlineRaceRules.MODE_SINGLE_RACE, "sandbox")
	assert_equal(selected, ["sandbox"], "Single race should use the requested valid track")

func test_tournament_track_selection_is_unique_and_capped() -> void:
	var tracks := [
		{"id": "kitchen"},
		{"id": "sandbox"},
		{"id": "attic"},
		{"id": "bedroom"},
		{"id": "garden"},
	]
	var selected := OnlineRaceRules.select_track_ids(tracks, OnlineRaceRules.MODE_TOURNAMENT, "attic")
	assert_equal(selected.size(), OnlineRaceRules.TOURNAMENT_ROUND_COUNT, "Tournament should select four tracks")
	assert_equal(selected[0], "attic", "Requested track should seed the first tournament round")
	var seen := {}
	for track_id in selected:
		seen[str(track_id)] = true
	assert_equal(seen.size(), selected.size(), "Tournament track ids should be unique")

func test_points_and_standings_accumulate_by_finish_order() -> void:
	var points := OnlineRaceRules.award_points([
		{"racer_id": "Dash"},
		{"racer_id": "Rexx"},
	], {"Rexx": 3})
	assert_equal(points.get("Dash", 0), 15, "First place should receive 15 points")
	assert_equal(points.get("Rexx", 0), 15, "Second place should add 12 points to existing standings")
	var standings := OnlineRaceRules.sorted_standings(points)
	assert_equal((standings[0] as Dictionary).get("racer_id", ""), "Dash", "Tied standings should sort by racer id for stability")

func test_progress_validation_rejects_backwards_updates() -> void:
	assert_true(OnlineRaceRules.should_accept_progress({"progress": 10.0}, {"progress": 10.1}), "Forward progress should be accepted")
	assert_true(not OnlineRaceRules.should_accept_progress({"progress": 10.0}, {"progress": 9.0}), "Backward progress should be rejected")
	assert_true(not OnlineRaceRules.should_accept_progress({"finished": true, "progress": 20.0}, {"progress": 21.0}), "Finished racers should not be mutable")
