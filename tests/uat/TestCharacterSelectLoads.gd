extends "res://tests/framework/TestCase.gd"

const CharacterSelectScene = preload("res://scenes/CharacterSelect.tscn")
const RacerRoster = preload("res://scripts/logic/RacerRoster.gd")

func test_character_select_scene_builds_all_racer_cards() -> void:
	_reset_selected_racer()
	var screen := CharacterSelectScene.instantiate()
	scene_tree.root.add_child(screen)
	assert_true(screen.has_method("get_card_count"), "Character select should expose card count for smoke tests")
	assert_equal(screen.call("get_card_count"), 8, "Character select should build one card per racer")
	assert_equal(screen.call("get_selected_racer_id"), RacerRoster.DEFAULT_RACER_ID, "Character select should default to the vertical-slice racer")
	screen.queue_free()

func test_character_select_portraits_exist_for_full_roster() -> void:
	_reset_selected_racer()
	var screen := CharacterSelectScene.instantiate()
	scene_tree.root.add_child(screen)
	for racer_id in RacerRoster.select_order():
		assert_true(screen.call("has_portrait_for", racer_id), "%s should have a runtime portrait" % racer_id)
	screen.queue_free()

func test_character_select_writes_selected_racer_metadata() -> void:
	_reset_selected_racer()
	var screen := CharacterSelectScene.instantiate()
	scene_tree.root.add_child(screen)
	var dash_card := screen.find_child("DashCard", true, false) as Button
	assert_true(dash_card != null, "Dash card should exist")
	dash_card.emit_signal("pressed")
	assert_equal(NakamaService.get_meta_value("selected_racer_id", ""), "Dash", "Pressed racer card should write selected racer metadata")
	screen.queue_free()
	_reset_selected_racer()

func test_character_select_flow_actions_route_from_nav_mode() -> void:
	_reset_selected_racer()
	NakamaService.set_meta_value("nav_flow_mode", "single_race")
	var screen := CharacterSelectScene.instantiate()
	scene_tree.root.add_child(screen)
	var labels: Array = screen.call("get_flow_action_labels_for_test")
	assert_true(labels.has("Local"), "Single-race character select should show Local")
	assert_true(labels.has("Multiplayer"), "Single-race character select should show Multiplayer")
	assert_equal(screen.call("prepare_local_flow_for_test"), "res://scenes/LevelSelect.tscn", "Single local should route to level select")
	assert_equal(screen.call("prepare_multiplayer_flow_for_test"), "res://scenes/Lobby.tscn", "Single multiplayer should route to lobby")
	assert_equal(NakamaService.get_meta_value("race_flow", ""), "single_multiplayer", "Single multiplayer should write race flow")
	assert_equal(NakamaService.get_meta_value("race_mode", ""), "online_single", "Single multiplayer should write online single mode")
	screen.queue_free()
	NakamaService.set_meta_value("nav_flow_mode", "")

func test_character_select_tournament_local_writes_tournament_state() -> void:
	_reset_selected_racer()
	NakamaService.set_meta_value("nav_flow_mode", "tournament")
	var screen := CharacterSelectScene.instantiate()
	scene_tree.root.add_child(screen)
	assert_equal(screen.call("prepare_local_flow_for_test"), "res://scenes/Race.tscn", "Tournament local should route to race")
	assert_equal(NakamaService.get_meta_value("race_mode", ""), "local_tournament", "Tournament local should write race mode")
	assert_true((NakamaService.get_meta_value("tournament_track_ids", []) as Array).size() >= 1, "Tournament local should select tracks")
	screen.queue_free()
	NakamaService.set_meta_value("nav_flow_mode", "")

func test_character_select_tournament_multiplayer_writes_online_state() -> void:
	_reset_selected_racer()
	NakamaService.set_meta_value("nav_flow_mode", "tournament")
	var screen := CharacterSelectScene.instantiate()
	scene_tree.root.add_child(screen)
	assert_equal(screen.call("prepare_multiplayer_flow_for_test"), "res://scenes/Lobby.tscn", "Tournament multiplayer should route to lobby")
	assert_equal(NakamaService.get_meta_value("race_mode", ""), "online_tournament", "Tournament multiplayer should write online tournament mode")
	assert_equal(NakamaService.get_meta_value("online_mode", ""), "tournament", "Tournament multiplayer should write tournament online mode")
	screen.queue_free()
	NakamaService.set_meta_value("nav_flow_mode", "")

func _reset_selected_racer() -> void:
	NakamaService.set_meta_value("selected_racer_id", RacerRoster.DEFAULT_RACER_ID)
