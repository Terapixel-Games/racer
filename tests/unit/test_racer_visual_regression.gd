extends "res://tests/framework/TestCase.gd"

const RacerVisualRegression = preload("res://scripts/logic/RacerVisualRegression.gd")

func test_visual_regression_targets_cover_level_select_and_driving_camera() -> void:
	var target_ids := []
	for target in RacerVisualRegression.capture_targets():
		target_ids.append(str((target as Dictionary).get("id", "")))
	assert_true(target_ids.has(RacerVisualRegression.TARGET_LEVEL_SELECT), "Visual regression should capture level-select racer preview")
	assert_true(target_ids.has(RacerVisualRegression.TARGET_DRIVING_CAMERA), "Visual regression should capture driving-camera racer view")

func test_visual_regression_detail_crops_cover_required_regions() -> void:
	for crop_id in ["eyes", "face_teeth", "decals", "tire_treads"]:
		assert_true(RacerVisualRegression.DETAIL_CROPS.has(crop_id), "Visual regression should define %s detail crop" % crop_id)

func test_visual_regression_crop_rects_stay_inside_capture_bounds() -> void:
	var crop_rects := RacerVisualRegression.crop_rects_for_pixels(1280, 720)
	for crop_id in crop_rects.keys():
		var rect := crop_rects[crop_id] as Rect2i
		assert_true(rect.position.x >= 0, "%s crop should start inside the image" % crop_id)
		assert_true(rect.position.y >= 0, "%s crop should start inside the image" % crop_id)
		assert_true(rect.size.x > 0 and rect.size.y > 0, "%s crop should have positive size" % crop_id)
		assert_true(rect.position.x + rect.size.x <= 1280, "%s crop should fit horizontally" % crop_id)
		assert_true(rect.position.y + rect.size.y <= 720, "%s crop should fit vertically" % crop_id)

func test_visual_regression_thresholds_match_phase5_gate() -> void:
	assert_equal(RacerVisualRegression.DETAIL_SCORE_THRESHOLD, 0.99, "LOD0 detail crop threshold should match the Phase 5 gate")
	assert_equal(RacerVisualRegression.FULL_SCORE_THRESHOLD, 0.99, "Full render threshold should match the Phase 5 gate")
