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

func _reset_selected_racer() -> void:
	NakamaService.set_meta_value("selected_racer_id", RacerRoster.DEFAULT_RACER_ID)
