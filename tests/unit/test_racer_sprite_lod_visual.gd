extends "res://tests/framework/TestCase.gd"

const RacerSpriteLodVisual = preload("res://scripts/RacerSpriteLodVisual.gd")

func test_sprite_lod_frame_selection_uses_camera_relative_yaw() -> void:
	var transform := Transform3D(Basis.IDENTITY, Vector3.ZERO)
	assert_equal(RacerSpriteLodVisual.frame_index_for_camera(transform, Vector3(0, 0, 10), 16), 0, "Camera in front of the racer should use the front-facing frame")
	assert_equal(RacerSpriteLodVisual.frame_index_for_camera(transform, Vector3(10, 0, 0), 16), 4, "Camera to the side should use the quarter-turn frame")
	assert_equal(RacerSpriteLodVisual.frame_index_for_camera(transform, Vector3(0, 0, -10), 16), 8, "Camera behind the racer should use the rear frame")
	assert_equal(RacerSpriteLodVisual.frame_index_for_camera(transform, Vector3(-10, 0, 0), 16), 12, "Camera to the other side should use the opposite quarter-turn frame")

func test_sprite_lod_visual_applies_manifest_frame_layout() -> void:
	var texture := ImageTexture.create_from_image(Image.create(1024, 1024, false, Image.FORMAT_RGBA8))
	var visual := RacerSpriteLodVisual.new()
	visual.configure(texture, {"frame_count": 16, "columns": 4, "frame_size": 256})
	visual.update_for_camera(Transform3D(Basis.IDENTITY, Vector3.ZERO), Vector3(0, 0, -10))
	assert_equal(visual.current_frame_for_test(), 8, "Configured sprite visual should update the Sprite3D frame from camera yaw")
	visual.queue_free()
