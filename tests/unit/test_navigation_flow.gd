extends "res://tests/framework/TestCase.gd"

const NavigationFlow = preload("res://scripts/logic/NavigationFlow.gd")

func test_local_tournament_selects_unique_tracks_and_first_track_metadata() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var tracks := NavigationFlow.prepare_local_tournament(NakamaService, rng)
	assert_true(tracks.size() >= 1, "Tournament should select at least one available track")
	assert_true(tracks.size() <= NavigationFlow.TOURNAMENT_ROUND_COUNT, "Tournament should select no more than four tracks")
	var seen := {}
	for track_id in tracks:
		seen[str(track_id)] = true
	assert_equal(seen.size(), tracks.size(), "Tournament tracks should be unique")
	assert_equal(NakamaService.get_meta_value("race_mode", ""), NavigationFlow.RACE_MODE_LOCAL_TOURNAMENT, "Tournament should write local tournament race mode")
	assert_equal(NakamaService.get_meta_value("nav_flow_mode", ""), NavigationFlow.FLOW_TOURNAMENT, "Tournament should preserve tournament navigation flow")
	assert_equal(NakamaService.get_meta_value("track_id", ""), tracks[0], "Tournament should prepare first round track")
	assert_true(NakamaService.get_meta_value("track_recipe", {}) is Dictionary, "Tournament should write first round track metadata")

func test_tournament_points_accumulate_by_finish_order() -> void:
	NakamaService.set_meta_value("tournament_points", {})
	var results := [
		{"racer_id": "Dash"},
		{"racer_id": "Rexx"},
		{"racer_id": "Moko"},
	]
	var points := NavigationFlow.award_tournament_points(NakamaService, results)
	assert_equal(points.get("Dash", 0), 15, "First place should receive 15 points")
	assert_equal(points.get("Rexx", 0), 12, "Second place should receive 12 points")
	assert_equal(points.get("Moko", 0), 10, "Third place should receive 10 points")
	NavigationFlow.award_tournament_points(NakamaService, results)
	points = NakamaService.get_meta_value("tournament_points", {})
	assert_equal(points.get("Dash", 0), 30, "Points should accumulate across rounds")

func test_placeholder_ending_resolves_win_and_loss() -> void:
	NakamaService.set_meta_value("selected_racer_id", "Dash")
	NakamaService.set_meta_value("tournament_points", {"Dash": 30, "Rexx": 24})
	var win_scene := NavigationFlow.resolve_placeholder_ending(NakamaService)
	assert_equal(win_scene, NavigationFlow.WIN_PLACEHOLDER_SCENE, "Player leading tournament should resolve win placeholder")
	assert_equal(NakamaService.get_meta_value("placeholder_ending_type", ""), "win", "Win placeholder type should be stored")

	NakamaService.set_meta_value("tournament_points", {"Dash": 12, "Rexx": 30})
	var loss_scene := NavigationFlow.resolve_placeholder_ending(NakamaService)
	assert_equal(loss_scene, NavigationFlow.LOSS_PLACEHOLDER_SCENE, "Player not leading tournament should resolve loss placeholder")
	assert_equal(NakamaService.get_meta_value("placeholder_ending_type", ""), "loss", "Loss placeholder type should be stored")

func test_single_multiplayer_writes_online_metadata() -> void:
	NavigationFlow.prepare_single_multiplayer(NakamaService)
	assert_equal(NakamaService.get_meta_value("race_flow", ""), NavigationFlow.RACE_FLOW_SINGLE_MULTIPLAYER, "Single multiplayer should preserve race flow")
	assert_equal(NakamaService.get_meta_value("race_mode", ""), NavigationFlow.RACE_MODE_ONLINE_SINGLE, "Single multiplayer should use online race mode")
	assert_equal(NakamaService.get_meta_value("online_mode", ""), "single_race", "Single multiplayer should use single online mode")
	assert_equal(NakamaService.get_meta_value("race_match_id", "stale"), "", "Single multiplayer should clear stale race match ids")

func test_tournament_multiplayer_writes_online_metadata() -> void:
	NavigationFlow.prepare_tournament_multiplayer(NakamaService)
	assert_equal(NakamaService.get_meta_value("race_flow", ""), NavigationFlow.RACE_FLOW_TOURNAMENT_MULTIPLAYER, "Tournament multiplayer should preserve race flow")
	assert_equal(NakamaService.get_meta_value("race_mode", ""), NavigationFlow.RACE_MODE_ONLINE_TOURNAMENT, "Tournament multiplayer should use online tournament race mode")
	assert_equal(NakamaService.get_meta_value("online_mode", ""), "tournament", "Tournament multiplayer should use tournament online mode")
