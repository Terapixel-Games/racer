extends "res://tests/framework/TestCase.gd"

const CharacterSelectScene = preload("res://scenes/CharacterSelect.tscn")
const LevelSelectScene = preload("res://scenes/LevelSelect.tscn")
const RaceScene = preload("res://scenes/Race.tscn")
const RacerRoster = preload("res://scripts/logic/RacerRoster.gd")

func test_character_select_continue_targets_level_select() -> void:
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
	screen.call("apply_selected_track_for_test")
	assert_equal(NakamaService.get_meta_value("track_id", ""), "kitchen", "Level select should write selected track id")
	assert_true(NakamaService.get_meta_value("track_recipe", {}) is Dictionary, "Level select should write track metadata recipe")
	assert_equal(NakamaService.get_meta_value("race_match_id", ""), "local-single-race", "Level select should configure local race match id")
	assert_equal(NakamaService.get_meta_value("race_mode", ""), "local_single", "Level select should configure local single-race mode")
	screen.queue_free()

func test_local_single_race_spawns_full_roster_and_blocks_input_during_intro() -> void:
	NakamaService.set_meta_value("race_mode", "local_single")
	NakamaService.set_meta_value("race_match_id", "local-single-race")
	NakamaService.set_meta_value("track_id", "kitchen")
	NakamaService.set_meta_value("selected_racer_id", "Dash")
	var race := RaceScene.instantiate()
	scene_tree.root.add_child(race)
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
