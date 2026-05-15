extends "res://tests/framework/TestCase.gd"

const HomeYardVisualGateContract = preload("res://scripts/logic/HomeYardVisualGateContract.gd")

func test_third_person_route_obstruction_views_are_required() -> void:
	var view_ids := HomeYardVisualGateContract.required_view_ids()
	for view_id in [
		"start_grid",
		"third_person_launch",
		"first_turn_chase",
		"camera_clearance",
		"overhead_route",
		"route_sample_25",
		"route_sample_50",
		"route_sample_75",
	]:
		assert_true(view_ids.has(view_id), "Home-yard visual gate should require %s." % view_id)

func test_visual_gate_reviews_third_person_camera_obstruction() -> void:
	var categories := HomeYardVisualGateContract.review_categories()
	for category in [
		"third_person_camera_clearance",
		"central_view_occlusion",
		"road_visibility",
		"next_turn_readability",
		"route_corridor_clearance",
		"collision_risk",
		"visual_confusion",
	]:
		assert_true(categories.has(category), "Visual review should score %s." % category)

	var launch_gate := HomeYardVisualGateContract.gate_metadata("third_person_launch")
	assert_equal(launch_gate.get("gate_class", ""), "third_person_route_obstruction", "Launch view should be a third-person obstruction gate.")
	assert_equal(launch_gate.get("manual_review_required", false), true, "Launch view should require screenshot review.")
	assert_true(float(launch_gate.get("central_occlusion_fail_ratio", 1.0)) <= 0.35, "Central occlusion threshold should reject blocked chase-camera views.")
	assert_true(int(launch_gate.get("minimum_review_score", 0)) >= 4, "Visual gate should require production-level review scores.")

func test_stage_capture_declares_required_visual_gate_views() -> void:
	var capture_source := FileAccess.get_file_as_string("res://tools/capture/StageVisualDiffCapture.gd")
	assert_true(capture_source.contains("HomeYardVisualGateContract"), "Stage capture should use the home-yard visual gate contract.")
	assert_true(capture_source.contains("\"kitchen\""), "Stage capture should include kitchen because it is the shared-map regression course most likely to expose floor/preview blockers.")
	assert_true(capture_source.contains("\"third_person_launch\""), "Stage capture should include a third-person launch view.")
	assert_true(capture_source.contains("\"first_turn_chase\""), "Stage capture should include a first-turn chase view.")
	assert_true(capture_source.contains("_with_visual_gate_metadata"), "Stage capture should attach gate metadata to screenshots.")
