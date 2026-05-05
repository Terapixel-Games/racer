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

func test_motion_blur_intensity_is_zero_below_threshold() -> void:
	var intensity := RaceController.motion_blur_intensity_for_speed(12.0, 16.0, 50.0, 0.72)
	assert_equal(intensity, 0.0, "Speed below threshold should not enable motion blur")

func test_motion_blur_intensity_caps_at_high_speed() -> void:
	var intensity := RaceController.motion_blur_intensity_for_speed(90.0, 16.0, 50.0, 0.72)
	assert_equal(intensity, 0.72, "High speed should cap at configured max blur")

func test_motion_blur_intensity_interpolates_mid_speed() -> void:
	var intensity := RaceController.motion_blur_intensity_for_speed(33.0, 16.0, 50.0, 0.72)
	assert_true(intensity > 0.0, "Mid speed should enable some motion blur")
	assert_true(intensity < 0.72, "Mid speed should not hit max blur")
	assert_true(absf(intensity - 0.36) <= 0.001, "Mid speed should map near half intensity")

func test_motion_blur_approach_moves_without_overshooting() -> void:
	var increasing := RaceController.approach_motion_blur_intensity(0.1, 0.3, 0.1, 5.0)
	assert_true(increasing > 0.1, "Increasing blur should move toward target")
	assert_true(increasing <= 0.3, "Increasing blur should not overshoot target")
	var decreasing := RaceController.approach_motion_blur_intensity(0.3, 0.0, 0.1, 7.0)
	assert_true(decreasing < 0.3, "Decreasing blur should move toward target")
	assert_true(decreasing >= 0.0, "Decreasing blur should not undershoot target")
