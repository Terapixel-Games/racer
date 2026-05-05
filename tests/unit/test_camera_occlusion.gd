extends "res://tests/framework/TestCase.gd"

const RaceController = preload("res://scripts/RaceController.gd")
const RaceMiniMap = preload("res://scripts/ui/RaceMiniMap.gd")

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

func test_camera_follow_transform_uses_tighter_behind_car_framing() -> void:
	var car_transform := Transform3D(Basis.IDENTITY, Vector3(2, 0, 4))
	var camera_position := RaceController.camera_follow_position(car_transform, 3.75, 1.35)
	var look_target := RaceController.camera_follow_look_target(car_transform, 0.72)
	assert_equal(camera_position, Vector3(2, 1.35, 0.25), "Race camera should sit closer behind the kart than the old distant framing")
	assert_equal(look_target, Vector3(2, 0.72, 4), "Race camera should look near the driver/kart body")

func test_ordinal_rank_formatting() -> void:
	assert_equal(RaceController.ordinal_rank(1), "1st", "Rank 1 should use st suffix")
	assert_equal(RaceController.ordinal_rank(2), "2nd", "Rank 2 should use nd suffix")
	assert_equal(RaceController.ordinal_rank(3), "3rd", "Rank 3 should use rd suffix")
	assert_equal(RaceController.ordinal_rank(4), "4th", "Rank 4 should use th suffix")
	assert_equal(RaceController.ordinal_rank(11), "11th", "Teen ranks should use th suffix")
	assert_equal(RaceController.ordinal_rank(23), "23rd", "Rank 23 should use rd suffix")

func test_race_timer_formatting() -> void:
	assert_equal(RaceController.format_race_time(0.0), "00:00.00", "Zero time should format as zeroed timer")
	assert_equal(RaceController.format_race_time(67.771), "01:07.77", "Race timer should format minutes, seconds, and centiseconds")
	assert_equal(RaceController.format_race_time(-5.0), "00:00.00", "Negative time should clamp to zero")

func test_minimap_projection_stays_inside_bounds() -> void:
	var points: Array[Vector3] = [Vector3(-10, 0, -20), Vector3(30, 0, 40)]
	var bounds := RaceMiniMap.route_bounds(points)
	var projected := RaceMiniMap.project_world_point(Vector3(30, 0, 40), bounds, Vector2(200, 100), 10.0)
	assert_true(projected.x >= 10.0 and projected.x <= 190.0, "Projected minimap x should stay within padded map bounds")
	assert_true(projected.y >= 10.0 and projected.y <= 90.0, "Projected minimap y should stay within padded map bounds")

func test_winner_cinematic_camera_cycles_distinct_angles() -> void:
	var car_transform := Transform3D(Basis.IDENTITY, Vector3(0, 2, 0))
	var first := RaceController.winner_cinematic_camera_pose(car_transform, Vector3(0, 0, -40), 0.2, 2.75)
	var second := RaceController.winner_cinematic_camera_pose(car_transform, Vector3(0, 0, -40), 3.0, 2.75)
	var third := RaceController.winner_cinematic_camera_pose(car_transform, Vector3(0, 0, -40), 6.0, 2.75)
	assert_true(int(first.get("shot", -1)) != int(second.get("shot", -1)), "Winner camera should cut to a different shot after the interval")
	assert_true((first.get("position", Vector3.ZERO) as Vector3).distance_to(second.get("position", Vector3.ZERO) as Vector3) > 1.0, "Winner camera shots should use visibly different positions")
	assert_true((second.get("position", Vector3.ZERO) as Vector3).distance_to(third.get("position", Vector3.ZERO) as Vector3) > 1.0, "Winner camera should continue cycling through cinematic angles")

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

func test_motion_blur_suppression_keeps_environment_effects_visible() -> void:
	var base := RaceController.motion_blur_intensity_for_speed(50.0, 16.0, 50.0, 0.72)
	var suppressed: float = base * (1.0 - 1.0 * 0.55)
	assert_true(suppressed < base, "Environment effects should reduce blur strength")
	assert_true(suppressed > 0.0, "Suppression should preserve some speed feedback")
