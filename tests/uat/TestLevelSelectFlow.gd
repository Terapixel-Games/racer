extends "res://tests/framework/TestCase.gd"

const LevelSelectScene = preload("res://scenes/LevelSelect.tscn")
const RaceScene = preload("res://scenes/Race.tscn")
const RacerRoster = preload("res://scripts/logic/RacerRoster.gd")
const TrackCatalog = preload("res://scripts/track/TrackCatalog.gd")

func test_level_select_defaults_selected_racer_for_unified_flow() -> void:
	NakamaService.set_meta_value("selected_racer_id", RacerRoster.DEFAULT_RACER_ID)
	var screen := LevelSelectScene.instantiate()
	scene_tree.root.add_child(screen)
	assert_equal(str(screen.call("get_selected_racer_id_for_test")), RacerRoster.DEFAULT_RACER_ID, "Level select should default selected racer metadata for unified flow")
	screen.queue_free()

func test_level_select_loads_default_track_and_writes_local_single_metadata() -> void:
	NakamaService.set_meta_value("selected_racer_id", "Dash")
	var screen := LevelSelectScene.instantiate()
	scene_tree.root.add_child(screen)
	assert_true(screen.has_method("get_track_count"), "Level select should expose selectable track count for smoke tests")
	assert_true(int(screen.call("get_track_count")) >= 1, "Level select should load at least one track")
	assert_equal(str(screen.call("get_selected_track_id")), "kitchen", "Level select should default to the catalog default track")
	assert_true(not bool(screen.call("preview_has_visible_road_edges_for_test")), "Level select preview should hide generated support road visuals")
	assert_true(not bool(screen.call("preview_has_visible_rails_for_test")), "Level select preview should not show rail-era containment")
	screen.call("apply_selected_track_for_test")
	assert_equal(NakamaService.get_meta_value("track_id", ""), "kitchen", "Level select should write selected track id")
	assert_true(NakamaService.get_meta_value("track_recipe", {}) is Dictionary, "Level select should write track metadata recipe")
	assert_equal(NakamaService.get_meta_value("race_match_id", ""), "local-single-race", "Level select should configure local race match id")
	assert_equal(NakamaService.get_meta_value("race_mode", ""), "local_single", "Level select should configure local single-race mode")
	screen.queue_free()

func test_level_select_shows_rotating_selected_racer_preview() -> void:
	NakamaService.set_meta_value("selected_racer_id", "Dash")
	var screen := LevelSelectScene.instantiate()
	scene_tree.root.add_child(screen)
	assert_equal(str(screen.call("get_selected_racer_id_for_test")), "Dash", "Level select should inherit the selected racer metadata")
	assert_true(bool(screen.call("racer_preview_has_model_for_test")), "Level select should render the selected racer model over the track preview")
	var start_rotation := float(screen.call("racer_preview_rotation_for_test"))
	screen.call("_process", 0.5)
	var next_rotation := float(screen.call("racer_preview_rotation_for_test"))
	assert_true(absf(angle_difference(start_rotation, next_rotation)) > 0.01, "Racer preview should rotate for visual inspection")
	assert_true(bool(screen.call("select_racer_for_test", "Rexx")), "Level select should allow racer changes from the preview test bed")
	assert_equal(str(screen.call("get_selected_racer_id_for_test")), "Rexx", "Level select should update the selected racer")
	assert_equal(NakamaService.get_meta_value("selected_racer_id", ""), "Rexx", "Level select should persist racer selection metadata for race launch")
	screen.queue_free()

func test_level_select_uses_optimized_backyard_preview_dressing() -> void:
	var screen := LevelSelectScene.instantiate()
	scene_tree.root.add_child(screen)
	assert_true(bool(screen.call("select_track_for_test", "outdoor_playground")), "Level select should expose the Dash backyard track")
	assert_true(bool(screen.call("preview_has_backyard_dressing_for_test")), "Backyard stage preview should show optimized dressed landmarks")
	assert_true(not bool(screen.call("preview_has_visible_road_edges_for_test")), "Dressed backyard preview should still hide support road visuals")
	screen.queue_free()

func test_level_select_back_target_returns_to_main_menu_and_clears_flow() -> void:
	NakamaService.set_meta_value("nav_flow_mode", "single_race")
	var screen := LevelSelectScene.instantiate()
	scene_tree.root.add_child(screen)
	assert_equal(screen.call("get_back_target_for_test"), "res://scenes/MainMenu.tscn", "Level select back target should return to main menu")
	screen.call("_go_back")
	assert_equal(NakamaService.get_meta_value("nav_flow_mode", ""), "", "Level select back should clear navigation flow")
	screen.queue_free()

func test_level_select_single_flow_actions_prepare_local_and_multiplayer() -> void:
	NakamaService.set_meta_value("nav_flow_mode", "single_race")
	NakamaService.set_meta_value("selected_racer_id", "Dash")
	var screen := LevelSelectScene.instantiate()
	scene_tree.root.add_child(screen)
	assert_true(bool(screen.call("select_track_for_test", "kitchen")), "Level select should expose selectable kitchen track")
	var labels: Array = screen.call("get_flow_action_labels_for_test")
	assert_true(labels.has("Race This Track"), "Single flow should show local race action")
	assert_true(labels.has("Multiplayer Lobby"), "Single flow should show multiplayer lobby action")
	assert_equal(screen.call("prepare_local_flow_for_test"), "res://scenes/Race.tscn", "Single local should route directly to race")
	assert_equal(NakamaService.get_meta_value("race_mode", ""), "local_single", "Single local should write local single mode")
	assert_equal(NakamaService.get_meta_value("race_match_id", ""), "local-single-race", "Single local should write local match id")
	assert_equal(NakamaService.get_meta_value("track_id", ""), "kitchen", "Single local should keep selected track")
	assert_equal(NakamaService.get_meta_value("selected_racer_id", ""), "Dash", "Single local should keep selected racer")
	assert_equal(screen.call("prepare_multiplayer_flow_for_test"), "res://scenes/Lobby.tscn", "Single multiplayer should route to lobby")
	assert_equal(NakamaService.get_meta_value("race_mode", ""), "online_single", "Single multiplayer should write online single mode")
	assert_equal(NakamaService.get_meta_value("online_mode", ""), "single_race", "Single multiplayer should write online mode")
	assert_equal(NakamaService.get_meta_value("track_id", ""), "kitchen", "Single multiplayer should keep selected track for lobby")
	screen.queue_free()
	NakamaService.set_meta_value("nav_flow_mode", "")

func test_level_select_tournament_flow_actions_prepare_local_and_multiplayer() -> void:
	NakamaService.set_meta_value("nav_flow_mode", "tournament")
	NakamaService.set_meta_value("selected_racer_id", "Dash")
	var screen := LevelSelectScene.instantiate()
	scene_tree.root.add_child(screen)
	assert_true(bool(screen.call("select_track_for_test", "kitchen")), "Level select should expose selectable kitchen track")
	var labels: Array = screen.call("get_flow_action_labels_for_test")
	assert_true(labels.has("Start Cup"), "Tournament flow should show local cup action")
	assert_true(labels.has("Tournament Lobby"), "Tournament flow should show tournament lobby action")
	assert_equal(screen.call("prepare_local_flow_for_test"), "res://scenes/Race.tscn", "Tournament local should route directly to race")
	var track_ids: Array = NakamaService.get_meta_value("tournament_track_ids", [])
	assert_equal(NakamaService.get_meta_value("race_mode", ""), "local_tournament", "Tournament local should write local tournament mode")
	assert_true(track_ids.size() >= 1, "Tournament local should select tracks")
	assert_equal(str(track_ids[0]), "kitchen", "Tournament local should seed round one from selected track")
	assert_equal(NakamaService.get_meta_value("tournament_round_index", -1), 0, "Tournament local should start at round zero")
	assert_equal(screen.call("prepare_multiplayer_flow_for_test"), "res://scenes/Lobby.tscn", "Tournament multiplayer should route to lobby")
	assert_equal(NakamaService.get_meta_value("race_mode", ""), "online_tournament", "Tournament multiplayer should write online tournament mode")
	assert_equal(NakamaService.get_meta_value("online_mode", ""), "tournament", "Tournament multiplayer should write tournament online mode")
	assert_equal(NakamaService.get_meta_value("track_id", ""), "kitchen", "Tournament multiplayer should keep selected track for lobby")
	screen.queue_free()
	NakamaService.set_meta_value("nav_flow_mode", "")

func test_local_single_race_spawns_full_roster_and_blocks_input_during_intro() -> void:
	var race: Node = _make_local_race()
	assert_true(bool(race.get("local_single_race")), "Race scene should branch into local single-race mode")
	assert_equal((race.get("local_racer_ids") as Array).size(), 8, "Local single race should spawn the full roster")
	assert_equal((race.get("ai_racer_ids") as Array).size(), 7, "Local single race should create seven CPU racers")
	assert_equal((race.get("spawn_points") as Array).size(), 8, "Local single race should load the RoadGridMap-authored start grid")
	var states: Dictionary = race.get("racer_states")
	assert_true(_same_spawn_lane((states.get("local_player") as Dictionary).get("grid_transform", Transform3D.IDENTITY), (race.get("spawn_points") as Array)[0]), "Local player grid transform should use generated Start01")
	var first_grid_ai := str((race.get("ai_racer_ids") as Array)[0])
	assert_true(_same_spawn_lane((states.get(first_grid_ai) as Dictionary).get("grid_transform", Transform3D.IDENTITY), (race.get("spawn_points") as Array)[1]), "First CPU grid transform should use generated Start02")
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

func test_active_ai_movement_resets_stuck_timer_when_progress_projection_stalls() -> void:
	var race: Node = _make_local_race()
	race.call("_set_local_phase", "racing")
	race.set("track_waypoints", [Vector3(0, 0, 0), Vector3(0, 0, -100)])
	race.set("track_closed_loop", false)
	var first_ai := str((race.get("ai_racer_ids") as Array)[0])
	var cars: Dictionary = race.get("cars")
	var car: CarController = cars.get(first_ai, null)
	assert_true(car != null, "CPU racer should exist for active movement stuck recovery")
	if car != null:
		car.global_transform = Transform3D(Basis.IDENTITY, Vector3(0, 1, -5))
		car.velocity = Vector3.ZERO
		var driver := {
			"lane_offset": 0.0,
			"lookahead": 10.0,
			"last_progress": 10.0,
			"stuck_timer": 2.4,
			"last_safe_transform": Transform3D(Basis.IDENTITY, Vector3(0, 1, 0)),
			"last_position": Vector3(0, 1, 0),
			"unstuck_count": 0,
		}
		race.call("_update_ai_stuck_state", first_ai, car, driver, 10.0, 0.2)
		assert_equal(float(driver.get("stuck_timer", -1.0)), 0.0, "Active AI that is physically moving should not be treated as stuck when progress projection stalls")
		assert_equal(int(driver.get("unstuck_count", -1)), 0, "Active AI movement should prevent an unnecessary unstuck reset")
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

func test_local_position_prefers_cleared_checkpoints_over_route_projection() -> void:
	var race: Node = _make_local_race()
	race.call("_set_local_phase", "racing")
	race.set("track_waypoints", [Vector3.ZERO, Vector3(0, 0, -100)])
	race.set("track_closed_loop", false)
	race.set("track_checkpoint_total", 4)
	var local_id := str(race.get("local_user_id"))
	var ai_id := "ai_visible_ahead"
	race.set("racer_states", {
		local_id: {
			"racer_id": "Dash",
			"lap": 1,
			"checkpoint": 1,
			"pos": Vector3(0, 1, -20),
			"finished": false,
			"wasted": false,
		},
		ai_id: {
			"racer_id": "Tuggs",
			"lap": 1,
			"checkpoint": 0,
			"pos": Vector3(0, 1, -70),
			"finished": false,
			"wasted": false,
		},
	})
	var entries: Array = race.call("_sorted_position_entries")
	assert_equal(str((entries[0] as Dictionary).get("id", "")), local_id, "A racer with more cleared checkpoints should rank ahead of raw route projection")
	assert_equal(int(race.call("_local_position")), 1, "Local position should be checkpoint-authoritative during active racing")
	race.queue_free()

func test_local_position_does_not_rank_lap_gate_seam_as_full_lap() -> void:
	var race: Node = _make_local_race()
	race.call("_set_local_phase", "racing")
	race.set("track_waypoints", [
		Vector3(-108, 0, -72),
		Vector3(0, 0, -76),
		Vector3(128, 0, -30),
		Vector3(60, 0, 78),
		Vector3(-94, 0, 54),
		Vector3(-126, 0, -40),
		Vector3(-112, 0, -68),
	])
	race.set("track_closed_loop", true)
	race.set("track_checkpoint_total", 6)
	var checkpoint_indices: Array[int] = [0, 1, 2, 3, 4, 5]
	race.set("track_checkpoint_indices", checkpoint_indices)
	var local_id := str(race.get("local_user_id"))
	var ai_id := "ai_ahead_after_gate"
	race.set("racer_states", {
		local_id: {
			"racer_id": "Dash",
			"lap": 1,
			"checkpoint": 1,
			"pos": Vector3(-110, 1, -70),
			"finished": false,
			"wasted": false,
			"progress": 5.8,
		},
		ai_id: {
			"racer_id": "Tuggs",
			"lap": 1,
			"checkpoint": 2,
			"pos": Vector3(40, 1, -74),
			"finished": false,
			"wasted": false,
			"progress": 2.0,
		},
	})
	var local_progress := float(race.call("_compute_progress", 1, 1, Vector3(-110, 1, -70), 6, false, -1.0))
	assert_true(local_progress < 2.0, "Lap-gate seam projection should stay inside the current checkpoint window")
	var entries: Array = race.call("_sorted_position_entries")
	assert_equal(str((entries[0] as Dictionary).get("id", "")), ai_id, "Cached seam progress should not put the local racer first while opponents are ahead")
	assert_equal(int(race.call("_local_position")), 2, "Local position should account for visible opponents ahead after the lap gate")
	race.queue_free()

func test_local_position_uses_completed_lap_distance_across_seam() -> void:
	var race: Node = _make_local_race()
	race.call("_set_local_phase", "racing")
	race.set("track_waypoints", [
		Vector3.ZERO,
		Vector3(100, 0, 0),
		Vector3(100, 0, 100),
		Vector3(0, 0, 100),
	])
	race.set("track_closed_loop", true)
	race.set("track_checkpoint_total", 4)
	var checkpoint_indices: Array[int] = [0, 1, 2, 3]
	race.set("track_checkpoint_indices", checkpoint_indices)
	var local_id := str(race.get("local_user_id"))
	var ai_id := "ai_previous_lap_near_finish"
	race.set("racer_states", {
		local_id: {
			"racer_id": "Dash",
			"lap": 2,
			"checkpoint": 1,
			"pos": Vector3(10, 1, 0),
			"finished": false,
			"wasted": false,
		},
		ai_id: {
			"racer_id": "Tuggs",
			"lap": 1,
			"checkpoint": 0,
			"pos": Vector3(1, 1, 0),
			"finished": false,
			"wasted": false,
		},
	})
	var entries: Array = race.call("_sorted_position_entries")
	assert_equal(str((entries[0] as Dictionary).get("id", "")), local_id, "A racer on a later lap should rank ahead even near the route seam")
	race.queue_free()

func test_local_progress_catches_up_when_checkpoint_trigger_is_missed() -> void:
	var race: Node = _make_local_race()
	race.call("_set_local_phase", "racing")
	race.set("track_waypoints", [
		Vector3.ZERO,
		Vector3(50, 0, 0),
		Vector3(100, 0, 0),
	])
	race.set("track_closed_loop", false)
	race.set("track_checkpoint_total", 3)
	var checkpoint_indices: Array[int] = [0, 1, 2]
	race.set("track_checkpoint_indices", checkpoint_indices)
	var local_id := str(race.get("local_user_id"))
	var states: Dictionary = race.get("racer_states")
	var local_state: Dictionary = states.get(local_id, {})
	local_state["lap"] = 1
	local_state["checkpoint"] = 1
	local_state["finished"] = false
	local_state["route_distance"] = 48.0
	states[local_id] = local_state
	race.set("racer_states", states)
	var cars: Dictionary = race.get("cars")
	var car: CarController = cars.get(local_id, null)
	assert_true(car != null, "Local race should provide a local car for progress ticking")
	if car != null:
		car.global_transform = Transform3D(Basis.IDENTITY, Vector3(56, 1, 14))
		race.call("_tick_local_racer_progress")
		states = race.get("racer_states")
		local_state = states.get(local_id, {})
		assert_equal(int(local_state.get("checkpoint", -1)), 2, "Route-distance catch-up should advance a missed checkpoint after clearly passing it")
	race.queue_free()

func test_local_progress_does_not_catch_up_from_initial_projected_position() -> void:
	var race: Node = _make_local_race()
	race.call("_set_local_phase", "racing")
	race.set("track_waypoints", [
		Vector3.ZERO,
		Vector3(50, 0, 0),
		Vector3(100, 0, 0),
	])
	race.set("track_closed_loop", false)
	race.set("track_checkpoint_total", 3)
	var checkpoint_indices: Array[int] = [0, 1, 2]
	race.set("track_checkpoint_indices", checkpoint_indices)
	var local_id := str(race.get("local_user_id"))
	var states: Dictionary = race.get("racer_states")
	var local_state: Dictionary = states.get(local_id, {})
	local_state["lap"] = 1
	local_state["checkpoint"] = 1
	local_state["finished"] = false
	local_state.erase("route_distance")
	states[local_id] = local_state
	race.set("racer_states", states)
	var cars: Dictionary = race.get("cars")
	var car: CarController = cars.get(local_id, null)
	assert_true(car != null, "Local race should provide a local car for progress ticking")
	if car != null:
		car.global_transform = Transform3D(Basis.IDENTITY, Vector3(56, 1, 14))
		race.call("_tick_local_racer_progress")
		states = race.get("racer_states")
		local_state = states.get(local_id, {})
		assert_equal(int(local_state.get("checkpoint", -1)), 1, "Catch-up should require crossing from a prior route distance, not initial projection")
	race.queue_free()

func test_local_progress_catches_up_missed_start_checkpoint_on_first_lap() -> void:
	var race: Node = _make_local_race()
	race.call("_set_local_phase", "racing")
	race.set("track_waypoints", [
		Vector3.ZERO,
		Vector3(50, 0, 0),
		Vector3(100, 0, 0),
	])
	race.set("track_closed_loop", false)
	race.set("track_checkpoint_total", 3)
	race.set("track_lap_gate_checkpoint_index", 0)
	var checkpoint_indices: Array[int] = [0, 1, 2]
	race.set("track_checkpoint_indices", checkpoint_indices)
	var local_id := str(race.get("local_user_id"))
	var states: Dictionary = race.get("racer_states")
	var local_state: Dictionary = states.get(local_id, {})
	local_state["lap"] = 1
	local_state["checkpoint"] = 0
	local_state["finished"] = false
	local_state.erase("route_distance")
	states[local_id] = local_state
	race.set("racer_states", states)
	var cars: Dictionary = race.get("cars")
	var car: CarController = cars.get(local_id, null)
	assert_true(car != null, "Local race should provide a local car for progress ticking")
	if car != null:
		car.global_transform = Transform3D(Basis.IDENTITY, Vector3(10, 1, 0))
		race.call("_tick_local_racer_progress")
		states = race.get("racer_states")
		local_state = states.get(local_id, {})
		assert_equal(int(local_state.get("checkpoint", -1)), 1, "First-lap start checkpoint should catch up after leaving the grid")
		assert_equal(int(local_state.get("lap", -1)), 1, "Start checkpoint catch-up should not advance the lap")
		assert_true(not bool(local_state.get("finished", false)), "Start checkpoint catch-up should not finish the race")
	race.queue_free()

func test_local_position_can_rank_player_last_in_full_field() -> void:
	var race: Node = _make_local_race()
	race.call("_set_local_phase", "racing")
	race.set("track_waypoints", [Vector3.ZERO, Vector3(0, 0, -140)])
	race.set("track_closed_loop", false)
	race.set("track_checkpoint_total", 4)
	var local_id := str(race.get("local_user_id"))
	var states := {
		local_id: {
			"racer_id": "Dash",
			"lap": 1,
			"checkpoint": 1,
			"pos": Vector3(0, 1, -10),
			"finished": false,
			"wasted": false,
		},
	}
	var roster_ids := ["Tuggs", "Moko", "Rexx", "Popper", "Sir Clink", "Slammo", "Velva"]
	for i in range(roster_ids.size()):
		states["cpu_%02d" % [i + 1]] = {
			"racer_id": roster_ids[i],
			"lap": 1,
			"checkpoint": 1,
			"pos": Vector3(0, 1, -30 - i * 12),
			"finished": false,
			"wasted": false,
	}
	race.set("racer_states", states)
	assert_equal(int(race.call("_local_position")), 8, "Local position should be able to show 8th when the full field is ahead")
	race.call("_update_positions")
	var rows := race.get_node("UI/HUD/TopLeftPanel/Margin/VBox/LeaderboardRows") as VBoxContainer
	assert_true(rows.get_child_count() >= 8, "Race leaderboard should create enough rows for the full local field")
	var visible_rows := 0
	for child in rows.get_children():
		if (child as Control).visible:
			visible_rows += 1
	assert_equal(visible_rows, 8, "Race leaderboard should display all eight local racers")
	var last_row := rows.get_child(7)
	var last_label := last_row.find_child("*Label", true, false) as Label
	assert_true(last_label != null and last_label.text.begins_with("8  YOU"), "Visible leaderboard should show the local racer in 8th when last")
	race.queue_free()

func test_local_position_can_rank_player_last_before_first_checkpoint() -> void:
	var race: Node = _make_local_race()
	race.call("_set_local_phase", "racing")
	race.set("track_waypoints", [Vector3.ZERO, Vector3(0, 0, -140)])
	race.set("track_closed_loop", false)
	race.set("track_checkpoint_total", 4)
	race.set("track_lap_gate_checkpoint_index", 0)
	var local_id := str(race.get("local_user_id"))
	var states := {
		local_id: {
			"racer_id": "Dash",
			"lap": 1,
			"checkpoint": 0,
			"pos": Vector3(0, 1, -10),
			"finished": false,
			"wasted": false,
		},
	}
	var roster_ids := ["Tuggs", "Moko", "Rexx", "Popper", "Sir Clink", "Slammo", "Velva"]
	for i in range(roster_ids.size()):
		states["cpu_%02d" % [i + 1]] = {
			"racer_id": roster_ids[i],
			"lap": 1,
			"checkpoint": 0,
			"pos": Vector3(0, 1, -30 - i * 12),
			"finished": false,
			"wasted": false,
		}
	race.set("racer_states", states)
	assert_equal(int(race.call("_local_position")), 8, "Local position should show 8th when seven racers are ahead before the first checkpoint")
	race.queue_free()

func test_kitchen_grid_route_positions_drive_local_rank() -> void:
	var race: Node = _make_local_race()
	race.call("_set_local_phase", "racing")
	var definition := TrackCatalog.get_definition("kitchen")
	var route: Array[Vector3] = definition.route_points
	assert_true(route.size() >= 12, "Kitchen RoadGridMap route should expose enough route points for rank tests")
	if route.size() < 12:
		race.queue_free()
		return
	var local_id := str(race.get("local_user_id"))
	var ai_id := "ai_grid_leader"
	race.set("track_waypoints", route)
	race.set("track_checkpoint_indices", definition.checkpoint_indices)
	race.set("track_checkpoint_total", definition.checkpoint_indices.size())
	race.set("track_lap_gate_checkpoint_index", definition.lap_gate_checkpoint_index)
	race.set("track_closed_loop", definition.closed_loop)
	race.set("racer_states", {
		local_id: {
			"racer_id": "Dash",
			"lap": 1,
			"checkpoint": 0,
			"pos": route[2],
			"finished": false,
			"wasted": false,
		},
		ai_id: {
			"racer_id": "Moko",
			"lap": 1,
			"checkpoint": 0,
			"pos": route[10],
			"finished": false,
			"wasted": false,
		},
	})
	assert_equal(int(race.call("_local_position")), 2, "Kitchen RoadGridMap route position should rank the farther kart ahead")
	race.queue_free()

func test_close_position_changes_preserve_previous_order_until_gap_is_clear() -> void:
	var race: Node = _make_local_race()
	race.call("_set_local_phase", "racing")
	var definition := TrackCatalog.get_definition("kitchen")
	var route: Array[Vector3] = definition.route_points
	assert_true(route.size() >= 3, "Kitchen RoadGridMap route should expose enough route points for hysteresis tests")
	if route.size() < 3:
		race.queue_free()
		return
	var local_id := str(race.get("local_user_id"))
	var ai_id := "ai_close_rival"
	var local_position := route[1].lerp(route[2], 0.20)
	var ai_position := route[1].lerp(route[2], 0.18)
	var small_overtake_position := route[1].lerp(route[2], 0.24)
	race.set("track_waypoints", route)
	race.set("track_checkpoint_indices", definition.checkpoint_indices)
	race.set("track_checkpoint_total", definition.checkpoint_indices.size())
	race.set("track_lap_gate_checkpoint_index", definition.lap_gate_checkpoint_index)
	race.set("track_closed_loop", definition.closed_loop)
	race.set("racer_states", {
		local_id: {
			"racer_id": "Dash",
			"lap": 1,
			"checkpoint": 1,
			"pos": local_position,
			"finished": false,
			"wasted": false,
		},
		ai_id: {
			"racer_id": "Moko",
			"lap": 1,
			"checkpoint": 1,
			"pos": ai_position,
			"finished": false,
			"wasted": false,
		},
	})
	race.call("_update_positions")
	var states: Dictionary = race.get("racer_states")
	var ai_state: Dictionary = states.get(ai_id, {})
	ai_state["pos"] = small_overtake_position
	states[ai_id] = ai_state
	race.set("racer_states", states)
	var entries: Array = race.call("_sorted_position_entries")
	assert_equal(str((entries[0] as Dictionary).get("id", "")), local_id, "Small progress noise should not reorder racers without a clear overtake")
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

func _same_spawn_lane(actual_value: Variant, expected_value: Variant) -> bool:
	if not (actual_value is Transform3D) or not (expected_value is Transform3D):
		return false
	var actual := actual_value as Transform3D
	var expected := expected_value as Transform3D
	var actual_yaw := actual.basis.get_euler().y
	var expected_yaw := expected.basis.get_euler().y
	return Vector2(actual.origin.x, actual.origin.z).distance_to(Vector2(expected.origin.x, expected.origin.z)) <= 0.01 and absf(angle_difference(actual_yaw, expected_yaw)) <= 0.01
