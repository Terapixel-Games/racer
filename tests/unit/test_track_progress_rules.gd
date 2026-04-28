extends "res://tests/framework/TestCase.gd"

const TrackCatalog = preload("res://scripts/track/TrackCatalog.gd")
const TrackProgressRules = preload("res://scripts/track/TrackProgressRules.gd")

func test_projection_progress_increases_along_route() -> void:
	var definition := TrackCatalog.get_definition("kitchen")
	var near_start := TrackProgressRules.project_position(definition.route_points, Vector3(-28, 3.0, -58), true)
	var later := TrackProgressRules.project_position(definition.route_points, Vector3(74, 3.0, -8), true)
	assert_true(float(later.get("distance", 0.0)) > float(near_start.get("distance", 0.0)), "Projected route distance should increase along the route")

func test_checkpoint_order_advances_and_finishes_after_lap_sequence() -> void:
	var checkpoint := 0
	var lap := 1
	var lap_gate_passed := false
	var result := TrackProgressRules.apply_checkpoint_pass(checkpoint, lap, lap_gate_passed, 0, 4, 0, 2)
	assert_true(bool(result.get("accepted", false)), "First checkpoint should be accepted")
	checkpoint = int(result.get("checkpoint", 0))
	lap = int(result.get("lap", 1))
	lap_gate_passed = bool(result.get("lap_gate_passed", false))
	assert_equal(checkpoint, 1, "Checkpoint should advance to 1")
	assert_equal(lap, 1, "Lap should not advance at the lap gate alone")

	for passed in [1, 2, 3]:
		result = TrackProgressRules.apply_checkpoint_pass(checkpoint, lap, lap_gate_passed, passed, 4, 0, 2)
		checkpoint = int(result.get("checkpoint", 0))
		lap = int(result.get("lap", 1))
		lap_gate_passed = bool(result.get("lap_gate_passed", false))
	assert_equal(checkpoint, 0, "Checkpoint should wrap after the full sequence")
	assert_equal(lap, 2, "Lap should advance only after the full checkpoint sequence")
	assert_true(not bool(result.get("finished", false)), "Race should not finish until lap exceeds total laps")

	result = TrackProgressRules.apply_checkpoint_pass(0, 2, false, 0, 4, 0, 2)
	checkpoint = int(result.get("checkpoint", 0))
	lap = int(result.get("lap", 2))
	lap_gate_passed = bool(result.get("lap_gate_passed", false))
	for passed in [1, 2, 3]:
		result = TrackProgressRules.apply_checkpoint_pass(checkpoint, lap, lap_gate_passed, passed, 4, 0, 2)
		checkpoint = int(result.get("checkpoint", 0))
		lap = int(result.get("lap", 2))
		lap_gate_passed = bool(result.get("lap_gate_passed", false))
	assert_true(bool(result.get("finished", false)), "Race should finish after completing the final lap sequence")

func test_wrong_checkpoint_is_rejected() -> void:
	var result := TrackProgressRules.apply_checkpoint_pass(1, 1, false, 3, 4, 0, 2)
	assert_true(not bool(result.get("accepted", false)), "Wrong checkpoint should be rejected")
	assert_equal(int(result.get("checkpoint", -1)), 1, "Rejected checkpoint should not advance")
