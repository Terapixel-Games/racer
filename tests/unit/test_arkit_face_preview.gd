extends "res://tests/framework/TestCase.gd"

func test_arkit_face_preview_loads_rexx_blendshape_driver() -> void:
	var preview_scene := load("res://scenes/dev/ARKitFacePreview.tscn")
	assert_true(preview_scene is PackedScene, "ARKit face preview scene should load")
	var preview := (preview_scene as PackedScene).instantiate()
	preview.set("auto_start_server", false)
	scene_tree.root.add_child(preview)
	await scene_tree.process_frame
	var driver := preview.find_child("ARKitFaceDriver", true, false) as ARKitFaceDriver
	assert_true(driver != null, "ARKit face preview should attach the runtime face driver")
	if driver != null:
		assert_true(driver.has_face_mesh(), "ARKit face preview should bind to a blendshape face mesh")
		assert_equal(driver.get_mapped_blend_shape_count(), 52, "ARKit face preview should expose all 52 ARKit blendshapes")
	preview.queue_free()
