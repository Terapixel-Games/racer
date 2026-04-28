extends "res://tests/framework/TestCase.gd"

const CharacterSelectScene = preload("res://scenes/CharacterSelect.tscn")
const RacerRoster = preload("res://scripts/logic/RacerRoster.gd")

func test_character_select_scene_builds_all_racer_cards() -> void:
	var screen := CharacterSelectScene.instantiate()
	scene_tree.root.add_child(screen)
	assert_true(screen.has_method("get_card_count"), "Character select should expose card count for smoke tests")
	assert_equal(screen.call("get_card_count"), 8, "Character select should build one card per racer")
	assert_equal(screen.call("get_selected_racer_id"), RacerRoster.DEFAULT_RACER_ID, "Character select should default to the vertical-slice racer")
	screen.queue_free()

func test_character_select_portraits_exist_for_full_roster() -> void:
	var screen := CharacterSelectScene.instantiate()
	scene_tree.root.add_child(screen)
	for racer_id in RacerRoster.select_order():
		assert_true(screen.call("has_portrait_for", racer_id), "%s should have a runtime portrait" % racer_id)
	screen.queue_free()
