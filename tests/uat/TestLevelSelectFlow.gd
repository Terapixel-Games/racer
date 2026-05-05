extends "res://tests/framework/TestCase.gd"

const CharacterSelectScene = preload("res://scenes/CharacterSelect.tscn")
const LevelSelectScene = preload("res://scenes/LevelSelect.tscn")
const RaceScene = preload("res://scenes/Race.tscn")
const RacerRoster = preload("res://scripts/logic/RacerRoster.gd")

func test_character_select_continue_targets_level_select() -> void:
	NakamaService.set_meta_value("selected_racer_id", RacerRoster.DEFAULT_RACER_ID)
	var screen := CharacterSelectScene.instantiate()
	scene_tree.root.add_child(screen)
	var button := screen.find_child("ContinueButton", true, false) as Button
	assert_true(button != null, "Character select should expose the continue button")
	assert_equal(NakamaService.get_meta_value("selected_racer_id", RacerRoster.DEFAULT_RACER_ID), RacerRoster.DEFAULT_RACER_ID, "Character select should keep selected racer metadata ready for level select")
	screen.queue_free()

func test_level_select_loads_default_track_and_writes_local_single_metadata() -> void:
	NakamaService.set_meta_value("selected_racer_id", "Dash")
	var screen := LevelSelectScene.instantiate()
	scene_tree.root.add_child(screen)
	assert_true(screen.has_method("get_track_count"), "Level select should expose selectable track count for smoke tests")
	assert_true(int(screen.call("get_track_count")) >= 1, "Level select should load at least one track")
	assert_equal(str(screen.call("get_selected_track_id")), "kitchen", "Level select should default to the catalog default track")
	assert_true(not bool(screen.call("preview_has_visible_road_edges_for_test")), "Level select preview should hide temporary rail edge visuals")
	screen.call("apply_selected_track_for_test")
	assert_equal(NakamaService.get_meta_value("track_id", ""), "kitchen", "Level select should write selected track id")
	assert_true(NakamaService.get_meta_value("track_recipe", {}) is Dictionary, "Level select should write track metadata recipe")
	assert_equal(NakamaService.get_meta_value("race_match_id", ""), "local-single-race", "Level select should configure local race match id")
	assert_equal(NakamaService.get_meta_value("race_mode", ""), "local_single", "Level select should configure local single-race mode")
	screen.queue_free()

func test_level_select_back_target_returns_to_character_select_for_single_flow() -> void:
	NakamaService.set_meta_value("nav_flow_mode", "single_race")
	var screen := LevelSelectScene.instantiate()
	scene_tree.root.add_child(screen)
	assert_equal(screen.call("get_back_target_for_test"), "res://scenes/CharacterSelect.tscn", "Level select back target should return to character select")
	assert_equal(NakamaService.get_meta_value("nav_flow_mode", ""), "single_race", "Level select should preserve single-race navigation flow")
	screen.queue_free()

func test_local_single_race_spawns_full_roster_and_blocks_input_during_intro() -> void:
	var race: Node = _make_local_race()
	assert_true(bool(race.get("local_single_race")), "Race scene should branch into local single-race mode")
	assert_equal((race.get("local_racer_ids") as Array).size(), 8, "Local single race should spawn the full roster")
	assert_equal((race.get("ai_racer_ids") as Array).size(), 7, "Local single race should create seven CPU racers")
	assert_true(not bool(race.get("player_input_enabled")), "Stage intro should block player input")
	var visual_ids: Dictionary = race.get("racer_visual_ids")
	var unique_visuals := {}
	for visual_id in visual_ids.values():
		unique_visuals[str(visual_id)] = true
	assert_equal(unique_visuals.size(), 8, "Every local racer should use a unique roster visual")
	race.call("_set_local_phase", "racing")
	assert_true(bool(race.get("player_input_enabled")), "GO phase should enable player input")
	var first_ai := str((race.get("ai_racer_ids") as Array)[0])
	race.call("_tick_ai_input", first_ai, 0.016)
	var car = (race.get("cars") as Dictionary).get(first_ai, null)
	assert_true(car != null, "CPU racer should have a spawned car")
	if car != null:
		var input_state: Dictionary = car.get("input_state")
		assert_true(float(input_state.get("throttle", 0.0)) > 0.0, "CPU racers should drive through CarController input")
	race.queue_free()

func test_local_single_countdown_uses_large_overlay() -> void:
	var race: Node = _make_local_race()
	race.call("_set_local_phase", "countdown")
	race.call("_update_countdown")
	var countdown := race.find_child("CountdownOverlay", true, false) as Label
	assert_true(countdown != null, "Race HUD should create a dedicated countdown overlay")
	assert_true(countdown != null and countdown.visible, "Countdown overlay should be visible during countdown")
	assert_equal(countdown.text, "3", "Countdown should start at 3")
	assert_true(countdown != null and countdown.get_theme_font_size("font_size") >= 120, "Countdown should use a large readable font")
	race.set("phase_timer", 1.1)
	race.call("_update_countdown")
	assert_equal(countdown.text, "2", "Countdown should animate through 2")
	race.set("phase_timer", 3.1)
	race.call("_update_countdown")
	assert_equal(countdown.text, "GO!", "Countdown should show GO before enabling racing")
	race.queue_free()

func test_local_out_of_bounds_returns_to_last_road_center() -> void:
	var race: Node = _make_local_race()
	var last_center := Transform3D(Basis(Vector3.UP, deg_to_rad(30.0)), Vector3(24.0, 4.35, -18.0))
	var checkpoint_reset := Transform3D(Basis.IDENTITY, Vector3(-102.0, 4.35, -74.0))
	race.set("last_on_track_center_transform", last_center)
	race.set("has_last_on_track_center_transform", true)
	race.set("local_respawn_transform", checkpoint_reset)
	race.set("has_local_respawn_transform", true)
	var resolved: Transform3D = race.call("_reset_transform_for_local_player")
	assert_equal(resolved.origin, last_center.origin, "Out-of-bounds reset should prefer the last road center over the checkpoint/start respawn")
	race.queue_free()

func test_local_single_ai_uses_lane_offsets_and_steers_toward_route_sample() -> void:
	var race: Node = _make_local_race()
	race.call("_set_local_phase", "racing")
	var ai_ids: Array = race.get("ai_racer_ids")
	var driver_state: Dictionary = race.get("ai_driver_state")
	var lane_offsets := {}
	for rid in ai_ids:
		var state: Dictionary = driver_state.get(str(rid), {})
		lane_offsets[float(state.get("lane_offset", 0.0))] = true
	assert_true(lane_offsets.size() >= 6, "CPU racers should use varied lane offsets to avoid bundling")

	var first_ai := str(ai_ids[0])
	var cars: Dictionary = race.get("cars")
	var car: CarController = cars.get(first_ai, null)
	assert_true(car != null, "CPU racer should have a car for steering tests")
	if car != null:
		driver_state[first_ai] = {"lane_offset": 0.0, "lookahead": 10.0, "last_progress": 0.0, "stuck_timer": 0.0, "last_safe_transform": Transform3D.IDENTITY, "last_position": Vector3.ZERO}
		race.set("track_waypoints", [Vector3.ZERO, Vector3(40, 0, 0), Vector3(80, 0, 0)])
		car.global_transform = Transform3D.IDENTITY
		race.call("_tick_ai_input", first_ai, 0.016)
		assert_true(float((car.get("input_state") as Dictionary).get("steer", 0.0)) > 0.0, "Target to the right should produce positive steering")
		race.set("track_waypoints", [Vector3.ZERO, Vector3(-40, 0, 0), Vector3(-80, 0, 0)])
		car.global_transform = Transform3D.IDENTITY
		race.call("_tick_ai_input", first_ai, 0.016)
		assert_true(float((car.get("input_state") as Dictionary).get("steer", 0.0)) < 0.0, "Target to the left should produce negative steering")
	race.queue_free()

func test_local_single_ai_moves_cars_from_start() -> void:
	var race: Node = _make_local_race()
	race.call("_set_local_phase", "racing")
	var ai_ids: Array = race.get("ai_racer_ids")
	var cars: Dictionary = race.get("cars")
	var start_positions := {}
	for rid in ai_ids:
		var car: CarController = cars.get(str(rid), null)
		if car != null:
			start_positions[str(rid)] = car.global_transform.origin
	for i in range(20):
		for rid in ai_ids:
			var car: CarController = cars.get(str(rid), null)
			if car != null:
				race.call("_tick_ai_input", str(rid), 0.016)
				car.call("_physics_process", 0.016)
	var moved := 0
	for rid in ai_ids:
		var car: CarController = cars.get(str(rid), null)
		if car != null and car.global_transform.origin.distance_to(start_positions.get(str(rid), car.global_transform.origin)) > 0.08:
			moved += 1
	assert_true(moved >= 6, "Most CPU racers should move away from their start positions under physics input")
	race.queue_free()

func test_local_single_finished_ai_keeps_cruising_after_final_lap() -> void:
	var race: Node = _make_local_race()
	race.call("_set_local_phase", "racing")
	var ai_ids: Array = race.get("ai_racer_ids")
	var first_ai := str(ai_ids[0])
	var states: Dictionary = race.get("racer_states")
	var ai_state: Dictionary = states.get(first_ai, {})
	ai_state["finished"] = true
	ai_state["finish_time"] = 8.0
	states[first_ai] = ai_state
	var cars: Dictionary = race.get("cars")
	var car: CarController = cars.get(first_ai, null)
	assert_true(car != null, "CPU racer should have a car after finishing")
	if car != null:
		race.set("track_waypoints", [Vector3.ZERO, Vector3(0, 0, -40), Vector3(0, 0, -80)])
		car.global_transform = Transform3D.IDENTITY
		race.call("_tick_ai_input", first_ai, 0.016)
		var input_state: Dictionary = car.get("input_state")
		assert_true(float(input_state.get("throttle", 0.0)) > 0.0, "Finished CPU racers should continue cruising after the final lap")
		assert_true(not bool(input_state.get("boost", false)), "Finished CPU racers should cruise without boost")
	race.queue_free()

func test_ai_unstuck_reset_does_not_advance_racer_progress() -> void:
	var race: Node = _make_local_race()
	race.call("_set_local_phase", "racing")
	race.set("track_waypoints", [Vector3(0, 0, 0), Vector3(0, 0, -100)])
	race.set("track_closed_loop", false)
	var ai_ids: Array = race.get("ai_racer_ids")
	var first_ai := str(ai_ids[0])
	var cars: Dictionary = race.get("cars")
	var car: CarController = cars.get(first_ai, null)
	assert_true(car != null, "CPU racer should exist for unstuck recovery")
	if car != null:
		car.global_transform = Transform3D(Basis.IDENTITY, Vector3(0, 1, 0))
		car.velocity = Vector3.ZERO
		var driver := {
			"lane_offset": 0.0,
			"lookahead": 10.0,
			"last_progress": 0.0,
			"stuck_timer": 2.4,
			"last_safe_transform": Transform3D(Basis.IDENTITY, Vector3(0, 1, 0)),
			"last_position": Vector3(0, 1, 0),
			"unstuck_count": 0,
		}
		race.call("_update_ai_stuck_state", first_ai, car, driver, 0.0, 0.2)
		assert_true(absf(car.global_transform.origin.z) <= 0.2, "AI unstuck reset should not move racers forward along the route")
		assert_equal(car.velocity, Vector3.ZERO, "AI unstuck reset should clear velocity before resuming")
	race.queue_free()

func test_finished_ai_cruise_does_not_unstuck_while_moving() -> void:
	var race: Node = _make_local_race()
	race.call("_set_local_phase", "racing")
	var ai_ids: Array = race.get("ai_racer_ids")
	var first_ai := str(ai_ids[0])
	var cars: Dictionary = race.get("cars")
	var car: CarController = cars.get(first_ai, null)
	assert_true(car != null, "CPU racer should exist for finished cruise recovery")
	if car != null:
		car.global_transform = Transform3D(Basis.IDENTITY, Vector3(0, 1, -12))
		car.velocity = Vector3(0, 0, -12)
		var driver := {
			"lane_offset": 0.0,
			"lookahead": 10.0,
			"last_progress": 999.0,
			"stuck_timer": 2.4,
			"last_safe_transform": Transform3D(Basis.IDENTITY, Vector3(0, 1, 0)),
			"last_position": Vector3(0, 1, 0),
			"unstuck_count": 0,
		}
		race.call("_update_ai_stuck_state", first_ai, car, driver, 999.0, 0.2, true)
		assert_true(car.global_transform.origin.distance_to(Vector3(0, 1, -12)) <= 0.01, "Moving finished racers should keep driving instead of being unstuck")
		assert_equal(float(driver.get("stuck_timer", -1.0)), 0.0, "Movement during finished cruise should reset stuck timer")
	race.queue_free()

func test_finished_ai_cruise_uses_centerline_instead_of_race_lane() -> void:
	var race: Node = _make_local_race()
	race.call("_set_local_phase", "racing")
	var ai_ids: Array = race.get("ai_racer_ids")
	var first_ai := str(ai_ids[0])
	var states: Dictionary = race.get("racer_states")
	var ai_state: Dictionary = states.get(first_ai, {})
	ai_state["finished"] = true
	states[first_ai] = ai_state
	var cars: Dictionary = race.get("cars")
	var car: CarController = cars.get(first_ai, null)
	assert_true(car != null, "CPU racer should exist for finished centerline cruise")
	if car != null:
		race.set("track_waypoints", [Vector3.ZERO, Vector3(0, 0, -80)])
		var driver_state: Dictionary = race.get("ai_driver_state")
		driver_state[first_ai] = {
			"lane_offset": 20.0,
			"lookahead": 18.0,
			"last_progress": 999.0,
			"stuck_timer": 0.0,
			"last_safe_transform": Transform3D.IDENTITY,
			"last_position": Vector3.ZERO,
		}
		car.global_transform = Transform3D(Basis.IDENTITY, Vector3(0, 1, 0))
		race.call("_tick_ai_input", first_ai, 0.016)
		var input_state: Dictionary = car.get("input_state")
		assert_true(absf(float(input_state.get("steer", 0.0))) <= 0.05, "Finished AI cruise should target the route centerline instead of its race lane")
		assert_true(not bool(input_state.get("drift", true)), "Finished AI cruise should not drift into rails or edge geometry")
	race.queue_free()

func test_local_finish_shows_live_overlay_then_finalizes_without_scene_change() -> void:
	var race: Node = _make_local_race()
	race.call("_set_local_phase", "racing")
	var states: Dictionary = race.get("racer_states")
	var local_state: Dictionary = states.get("local_player", {})
	local_state["finished"] = true
	local_state["finish_time"] = 1.0
	states["local_player"] = local_state
	var leader_id := str((race.get("ai_racer_ids") as Array)[0])
	var leader_state: Dictionary = states.get(leader_id, {})
	leader_state["finished"] = true
	leader_state["finish_time"] = 0.5
	leader_state["progress"] = 999.0
	states[leader_id] = leader_state
	race.call("_tick_local_race", 0.016)
	assert_equal(str(race.get("race_phase")), "player_finish_follow", "Player finish should enter the player camera beat")
	assert_true(not bool(race.get("player_input_enabled")), "Player input should disable after finish")
	assert_true(bool(race.call("results_overlay_is_visible_for_test")), "Results overlay should appear immediately as provisional")
	assert_true(not bool(race.call("results_overlay_is_final_for_test")), "Immediate overlay should be provisional")
	assert_equal(str(race.call("get_camera_follow_target_id_for_test")), "local_player", "Camera should initially stay on the finished player")
	race.call("_physics_process_local_single", 2.1)
	assert_equal(str(race.get("race_phase")), "winner_follow_results", "Camera phase should switch to winner follow after the player beat")
	assert_equal(str(race.call("get_camera_follow_target_id_for_test")), leader_id, "Winner follow should target the first-place racer")
	for rid in race.get("local_racer_ids"):
		var state: Dictionary = states.get(str(rid), {})
		state["finished"] = true
		state["finish_time"] = float(state.get("finish_time", 5.0))
		states[str(rid)] = state
	race.call("_submit_local_results")
	assert_equal(str(race.get("race_phase")), "results", "Finalization should keep the race scene in results phase")
	assert_true(bool(race.call("results_overlay_is_final_for_test")), "Final results should mark the overlay final")
	assert_true(race.is_inside_tree(), "Local single results should remain over Race.tscn instead of changing scene")
	var cars: Dictionary = race.get("cars")
	var leader_car: CarController = cars.get(leader_id, null)
	assert_true(leader_car != null, "Winner follow should still have a winner car during final results")
	if leader_car != null:
		race.call("_physics_process_local_single", 0.016)
		var input_state: Dictionary = leader_car.get("input_state")
		assert_true(float(input_state.get("throttle", 0.0)) > 0.0, "Winner AI should keep cruising after final results are shown")
	race.queue_free()

func test_final_results_recovers_winner_if_they_fall_off_track() -> void:
	var race: Node = _make_local_race()
	race.call("_set_local_phase", "racing")
	var leader_id := str((race.get("ai_racer_ids") as Array)[0])
	var states: Dictionary = race.get("racer_states")
	var leader_state: Dictionary = states.get(leader_id, {})
	leader_state["finished"] = true
	leader_state["finish_time"] = 0.5
	leader_state["progress"] = 999.0
	states[leader_id] = leader_state
	for rid in race.get("local_racer_ids"):
		if str(rid) == leader_id:
			continue
		var state: Dictionary = states.get(str(rid), {})
		state["finished"] = true
		state["finish_time"] = 5.0
		states[str(rid)] = state
	race.call("_submit_local_results")
	var cars: Dictionary = race.get("cars")
	var leader_car: CarController = cars.get(leader_id, null)
	assert_true(leader_car != null, "Winner car should exist in final results")
	if leader_car != null:
		leader_car.global_transform.origin = Vector3(0, -80, 0)
		race.call("_physics_process_local_single", 0.016)
		assert_true(leader_car.global_transform.origin.y > -20.0, "Final results should recover the winner if they fall below the track")
	race.queue_free()

func test_local_tournament_results_show_next_race_before_final_round() -> void:
	var race: Node = _make_local_tournament_race(0)
	race.call("show_results", [
		{"id": "local_player", "racer_id": "Dash", "finished": true, "finish_time": 1.0},
		{"id": "ai_1", "racer_id": "Rexx", "finished": true, "finish_time": 2.0},
	], true)
	assert_equal(str(race.call("get_primary_results_button_text_for_test")), "Next Race", "Tournament result primary action should advance to the next race while rounds remain")
	race.queue_free()

func test_local_tournament_results_show_ending_after_final_round() -> void:
	var race: Node = _make_local_tournament_race(3)
	race.call("show_results", [
		{"id": "local_player", "racer_id": "Dash", "finished": true, "finish_time": 1.0},
	], true)
	assert_equal(str(race.call("get_primary_results_button_text_for_test")), "Show Ending", "Final tournament round should route to placeholder ending")
	race.queue_free()

func test_race_ignores_music_audio_zones_to_avoid_duplicate_track_music() -> void:
	var race: Node = _make_local_tournament_race(0)
	race.set("track_audio_ids", {"music": "res://assets/source/audio/suno/tracks/kitchen/kitchen_loop_suno_01.mp3"})
	assert_true(bool(race.call("_is_music_audio_zone", {"audio_id": "music"})), "Audio zone using the music id should be treated as track music")
	assert_true(bool(race.call("_is_music_audio_zone", {"audio_path": "res://assets/source/audio/suno/tracks/kitchen/kitchen_loop_suno_01.mp3"})), "Audio zone using the active music path should be treated as track music")
	assert_true(not bool(race.call("_is_music_audio_zone", {"audio_id": "sink"})), "Non-music audio zones should still play as zones")
	race.queue_free()

func _make_local_race() -> Node:
	NakamaService.set_meta_value("race_mode", "local_single")
	NakamaService.set_meta_value("race_match_id", "local-single-race")
	NakamaService.set_meta_value("track_id", "kitchen")
	NakamaService.set_meta_value("selected_racer_id", "Dash")
	var race := RaceScene.instantiate()
	scene_tree.root.add_child(race)
	return race

func _make_local_tournament_race(round_index: int) -> Node:
	NakamaService.set_meta_value("race_mode", "local_tournament")
	NakamaService.set_meta_value("race_match_id", "local-tournament-race")
	NakamaService.set_meta_value("track_id", "kitchen")
	NakamaService.set_meta_value("selected_racer_id", "Dash")
	NakamaService.set_meta_value("tournament_track_ids", ["kitchen", "sandbox", "attic", "bedroom"])
	NakamaService.set_meta_value("tournament_round_index", round_index)
	NakamaService.set_meta_value("tournament_points", {})
	var race := RaceScene.instantiate()
	scene_tree.root.add_child(race)
	return race
