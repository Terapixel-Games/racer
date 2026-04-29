extends "res://tests/framework/TestCase.gd"

const RaceController = preload("res://scripts/RaceController.gd")

func test_camera_occlusion_places_camera_before_blocker() -> void:
	var look_target := Vector3(0, 1, 0)
	var desired := Vector3(0, 2, -6)
	var hit_position := look_target.lerp(desired, 0.5)
	var resolved := RaceController.camera_position_before_occluder(look_target, desired, hit_position, 0.7, 1.1)
	assert_true(resolved.distance_to(look_target) < hit_position.distance_to(look_target), "Occlusion solver should keep the camera on the player side of the blocker")
	assert_true(resolved.distance_to(look_target) >= 1.1, "Occlusion solver should preserve a usable minimum camera distance when there is room")

func test_camera_occlusion_does_not_push_through_close_blocker() -> void:
	var look_target := Vector3.ZERO
	var desired := Vector3(0, 0, -6)
	var hit_position := Vector3(0, 0, -0.5)
	var resolved := RaceController.camera_position_before_occluder(look_target, desired, hit_position, 0.7, 1.1)
	assert_true(resolved.distance_to(look_target) < hit_position.distance_to(look_target), "Close blockers should not force the camera past the blocker")
