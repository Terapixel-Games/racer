extends "res://tests/framework/TestCase.gd"

func test_main_scene_resource_loads() -> void:
	var main_scene := str(ProjectSettings.get_setting("application/run/main_scene", ""))
	assert_true(not main_scene.is_empty(), "application/run/main_scene must be set")
	assert_true(ResourceLoader.exists(main_scene), "Main scene does not exist: %s" % main_scene)
	var packed := load(main_scene)
	assert_true(packed is PackedScene, "Main scene is not a PackedScene: %s" % main_scene)
	if packed is PackedScene:
		var instance := (packed as PackedScene).instantiate()
		assert_true(instance != null, "Main scene instantiate() returned null")
		if instance is Node:
			(instance as Node).queue_free()

func test_main_menu_sets_navigation_flow_and_preview_track() -> void:
	var packed := load("res://scenes/MainMenu.tscn")
	assert_true(packed is PackedScene, "Main menu scene should load")
	if not (packed is PackedScene):
		return
	var screen := (packed as PackedScene).instantiate()
	scene_tree.root.add_child(screen)
	assert_true(screen.has_method("has_root_buttons_for_test"), "Main menu should expose root button test hook")
	assert_true(bool(screen.call("has_root_buttons_for_test")), "Main menu should expose Single Race and Tournament buttons")
	assert_true(screen.has_method("get_preview_track_id_for_test"), "Main menu should expose preview track test hook")
	assert_true(str(screen.call("get_preview_track_id_for_test")) != "", "Main menu should choose a preview track")
	screen.call("start_single_race_for_test")
	assert_equal(NakamaService.get_meta_value("nav_flow_mode", ""), "single_race", "Single Race should write navigation flow")
	screen.call("start_tournament_for_test")
	assert_equal(NakamaService.get_meta_value("nav_flow_mode", ""), "tournament", "Tournament should write navigation flow")
	screen.queue_free()
