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
	assert_true(profile.has("racer_in_kart_model"), "Rexx profile should include a racer-in-kart model")
	assert_true(profile.has("racer_in_kart_yaw_degrees"), "Rexx profile should include a racer-in-kart yaw")
	assert_true(profile.has("stats"), "Rexx profile should include stats")
	assert_equal(profile["class"], "Heavy", "Rexx should be Heavy")
	assert_equal(profile["home_course"], "Sandbox", "Rexx should own Sandbox")
	assert_true(ResourceLoader.exists(profile["portrait"]), "Rexx portrait should exist")
	assert_true(ResourceLoader.exists(profile["racer_in_kart_model"]), "Rexx racer-in-kart model should exist")
	assert_equal(profile["racer_in_kart_yaw_degrees"], RacerRoster.FORWARD_AUTHORED_RACER_IN_KART_YAW_DEGREES, "Rexx should use the forward-authored racer-in-kart yaw")
	assert_equal(profile["stats"]["weight"], 10, "Rexx weight should match the balance plan")
	assert_equal(profile["stats"]["speed"], 9, "Rexx speed should match the balance plan")

func test_roster_normalizes_invalid_visual_selection() -> void:
	assert_equal(RacerRoster.normalize_id("Moko"), "Moko", "Known racer ids should remain unchanged")
	assert_equal(RacerRoster.normalize_id("missing"), RacerRoster.DEFAULT_RACER_ID, "Unknown racer ids should fall back to the default")
	assert_true(ResourceLoader.exists(RacerRoster.get_racer_in_kart_model_path("missing")), "Fallback racer-in-kart model should exist")

func test_racer_asset_profile_defaults_to_source_models() -> void:
	var source_path := RacerRoster.get_racer_in_kart_source_model_path("Rexx")
	assert_equal(RacerRoster.normalize_asset_profile("bad-profile"), RacerRoster.RACER_ASSET_PROFILE_SOURCE, "Unknown racer asset profiles should fall back to source")
	assert_equal(RacerRoster.get_racer_in_kart_model_path_for_profile("Rexx", RacerRoster.RACER_ASSET_PROFILE_SOURCE), source_path, "Source asset profile should use the authored GLB")
	assert_true(ResourceLoader.exists(source_path), "Source racer model should remain available")

func test_mobile_detail_profile_exposes_optimized_paths_with_source_fallback() -> void:
	var expected := "res://assets/optimized/racers/rexx/rexx_racer_in_kart_mobile_detail.glb"
	var source_path := RacerRoster.get_racer_in_kart_source_model_path("Rexx")
	assert_equal(RacerRoster.get_racer_in_kart_model_path_for_profile("Rexx", RacerRoster.RACER_ASSET_PROFILE_MOBILE_DETAIL, false), expected, "Mobile detail profile should resolve the staged optimized asset path")
	assert_equal(RacerRoster.get_racer_in_kart_model_path_for_profile("Rexx", RacerRoster.RACER_ASSET_PROFILE_MOBILE_DETAIL, true), source_path, "Mobile detail profile should fall back until optimized GLBs are staged in res://")
	assert_equal(RacerRoster.get_racer_in_kart_model_path_for_profile("Sir Clink", RacerRoster.RACER_ASSET_PROFILE_MOBILE_DETAIL_PHASE1, false), "res://assets/optimized/racers/sir_clink/sir_clink_racer_in_kart_mobile_detail_phase1.glb", "Phase profiles should preserve racer slugs with spaces")

func test_configured_racer_asset_profile_uses_staged_phase1_glbs() -> void:
	assert_equal(RacerRoster.get_racer_asset_profile(), RacerRoster.RACER_ASSET_PROFILE_MOBILE_DETAIL_PHASE1, "The project should use the staged optimized racer profile")
	for racer_id in RacerRoster.select_order():
		var path := RacerRoster.get_racer_in_kart_model_path(racer_id)
		assert_true(path.contains("_mobile_detail_phase1.glb"), "%s should resolve to the phase1 optimized racer GLB" % racer_id)
		assert_true(ResourceLoader.exists(path), "%s optimized racer GLB should be staged in res://" % racer_id)

func test_racer_in_kart_direction_groups_match_import_orientation() -> void:
	for racer_id in ["Rexx", "Moko", "Popper", "Slammo"]:
		assert_equal(RacerRoster.get_racer_in_kart_yaw_degrees(racer_id), RacerRoster.FORWARD_AUTHORED_RACER_IN_KART_YAW_DEGREES, "%s should use the forward-authored racer-in-kart yaw" % racer_id)
	for racer_id in ["Tuggs", "Sir Clink", "Velva", "Dash"]:
		assert_equal(RacerRoster.get_racer_in_kart_yaw_degrees(racer_id), RacerRoster.VELVA_RACER_IN_KART_YAW_DEGREES, "%s should use Velva's racer-in-kart yaw" % racer_id)
