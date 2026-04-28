extends "res://tests/framework/TestCase.gd"

const RacerRoster = preload("res://scripts/logic/RacerRoster.gd")

func test_roster_contains_all_eight_racers() -> void:
	assert_equal(RacerRoster.ids(), [
		"Dash",
		"Moko",
		"Popper",
		"Rexx",
		"Sir Clink",
		"Slammo",
		"Tuggs",
		"Velva",
	], "Roster ids should match the approved cast")

func test_select_order_matches_character_select_art_sheet() -> void:
	assert_equal(RacerRoster.select_order(), [
		"Rexx",
		"Moko",
		"Tuggs",
		"Popper",
		"Sir Clink",
		"Slammo",
		"Velva",
		"Dash",
	], "Character select order should match the approved 4x2 portrait sheet")

func test_rexx_profile_matches_planned_balance() -> void:
	var profile := RacerRoster.get_profile("Rexx")
	assert_true(profile.has("class"), "Rexx profile should include a class")
	assert_true(profile.has("home_course"), "Rexx profile should include a home course")
	assert_true(profile.has("motive"), "Rexx profile should include a motive")
	assert_true(profile.has("portrait"), "Rexx profile should include a portrait")
	assert_true(profile.has("stats"), "Rexx profile should include stats")
	assert_equal(profile["class"], "Heavy", "Rexx should be Heavy")
	assert_equal(profile["home_course"], "Sandbox", "Rexx should own Sandbox")
	assert_true(ResourceLoader.exists(profile["portrait"]), "Rexx portrait should exist")
	assert_equal(profile["stats"]["weight"], 10, "Rexx weight should match the balance plan")
	assert_equal(profile["stats"]["speed"], 9, "Rexx speed should match the balance plan")
