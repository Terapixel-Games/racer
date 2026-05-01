extends "res://tests/framework/TestCase.gd"

const TrackCatalog = preload("res://scripts/track/TrackCatalog.gd")
const TrackProgressRules = preload("res://scripts/track/TrackProgressRules.gd")
const RaceController = preload("res://scripts/RaceController.gd")

func test_projection_progress_increases_along_route() -> void:
	var definition := TrackCatalog.get_definition("kitchen")
	var near_start := TrackProgressRules.project_position(definition.route_points, Vector3(-86, 3.0, -76), true)
	var later := TrackProgressRules.project_position(definition.route_points, Vector3(116, 3.0, -18), true)
	assert_true(float(later.get("distance", 0.0)) > float(near_start.get("distance", 0.0)), "Projected route distance should increase along the route")

func test_sample_route_at_distance_returns_position_and_tangent() -> void:
	var route: Array[Vector3] = [Vector3.ZERO, Vector3(10, 0, 0), Vector3(10, 0, 10)]
	var sample := TrackProgressRules.sample_route_at_distance(route, 5.0, false)
	assert_true((sample.get("position", Vector3.ZERO) as Vector3).distance_to(Vector3(5, 0, 0)) < 0.01, "Sampler should interpolate along the first segment")
	assert_true((sample.get("tangent", Vector3.ZERO) as Vector3).distance_to(Vector3.RIGHT) < 0.01, "Sampler should return the segment tangent")
	assert_equal(int(sample.get("segment_index", -1)), 0, "Sampler should report the active segment")

func test_sample_route_wraps_closed_loop_distance() -> void:
	var route: Array[Vector3] = [Vector3.ZERO, Vector3(10, 0, 0), Vector3(10, 0, 10), Vector3(0, 0, 10)]
	var sample := TrackProgressRules.sample_route_at_distance(route, 50.0, true)
	assert_true((sample.get("position", Vector3.ZERO) as Vector3).distance_to(Vector3(10, 0, 0)) < 0.01, "Closed route sampling should wrap beyond total length")
	assert_true(float(sample.get("route_ratio", -1.0)) >= 0.0 and float(sample.get("route_ratio", -1.0)) <= 1.0, "Wrapped route ratio should stay normalized")

func test_checkpoint_order_advances_and_finishes_after_lap_sequence() -> void:
	var checkpoint := 0
	var lap := 1
	var lap_gate_passed := false
	var result := TrackProgressRules.apply_checkpoint_pass(checkpoint, lap, lap_gate_passed, 0, 6, 0, 2)
	assert_true(bool(result.get("accepted", false)), "First checkpoint should be accepted")
	checkpoint = int(result.get("checkpoint", 0))
	lap = int(result.get("lap", 1))
	lap_gate_passed = bool(result.get("lap_gate_passed", false))
	assert_equal(checkpoint, 1, "Checkpoint should advance to 1")
	assert_equal(lap, 1, "Lap should not advance at the lap gate alone")

	for passed in [1, 2, 3, 4, 5]:
		result = TrackProgressRules.apply_checkpoint_pass(checkpoint, lap, lap_gate_passed, passed, 6, 0, 2)
		checkpoint = int(result.get("checkpoint", 0))
		lap = int(result.get("lap", 1))
		lap_gate_passed = bool(result.get("lap_gate_passed", false))
	assert_equal(checkpoint, 0, "Checkpoint should wrap after the full sequence")
	assert_equal(lap, 2, "Lap should advance only after the full checkpoint sequence")
	assert_true(not bool(result.get("finished", false)), "Race should not finish until lap exceeds total laps")

	result = TrackProgressRules.apply_checkpoint_pass(0, 2, false, 0, 6, 0, 2)
	checkpoint = int(result.get("checkpoint", 0))
	lap = int(result.get("lap", 2))
	lap_gate_passed = bool(result.get("lap_gate_passed", false))
	for passed in [1, 2, 3, 4, 5]:
		result = TrackProgressRules.apply_checkpoint_pass(checkpoint, lap, lap_gate_passed, passed, 6, 0, 2)
		checkpoint = int(result.get("checkpoint", 0))
		lap = int(result.get("lap", 2))
		lap_gate_passed = bool(result.get("lap_gate_passed", false))
	assert_true(bool(result.get("finished", false)), "Race should finish after completing the final lap sequence")

func test_wrong_checkpoint_is_rejected() -> void:
	var result := TrackProgressRules.apply_checkpoint_pass(1, 1, false, 3, 6, 0, 2)
	assert_true(not bool(result.get("accepted", false)), "Wrong checkpoint should be rejected")
	assert_equal(int(result.get("checkpoint", -1)), 1, "Rejected checkpoint should not advance")

func test_route_network_projection_uses_nearest_alternate_route() -> void:
	var route_points: Array[Vector3] = [
		Vector3(0, 0, 0),
		Vector3(20, 0, 0),
		Vector3(40, 0, 0),
		Vector3(60, 0, 0),
	]
	var checkpoints: Array[int] = [0, 1, 3]
	var alternates: Array[Dictionary] = [{
		"id": "high_lane",
		"entry_checkpoint_index": 1,
		"exit_checkpoint_index": 2,
		"points": [Vector3(20, 0, 10), Vector3(40, 0, 10), Vector3(60, 0, 10)],
		"enabled": true,
	}]
	var projection := TrackProgressRules.project_route_network(route_points, alternates, checkpoints, Vector3(40, 0, 10), false)
	assert_true(bool(projection.get("is_alternate", false)), "Projection should prefer the closer alternate branch")
	assert_equal(str(projection.get("route_id", "")), "high_lane", "Projection should identify the selected branch")
	assert_true(absf(float(projection.get("distance", 0.0)) - 40.0) < 0.2, "Branch midpoint should map into the canonical checkpoint span")

func test_return_to_track_uses_alternate_route_center() -> void:
	var route_points: Array[Vector3] = [
		Vector3(0, 0, 0),
		Vector3(20, 0, 0),
		Vector3(40, 0, 0),
		Vector3(60, 0, 0),
	]
	var checkpoints: Array[int] = [0, 1, 3]
	var alternates: Array[Dictionary] = [{
		"id": "high_lane",
		"entry_checkpoint_index": 1,
		"exit_checkpoint_index": 2,
		"points": [Vector3(20, 0, 10), Vector3(40, 0, 10), Vector3(60, 0, 10)],
		"enabled": true,
	}]
	var reset := RaceController.centered_track_return_transform(route_points, Vector3(38, 0, 14), false, alternates, checkpoints)
	assert_true(reset.origin.distance_to(Vector3(38, 1, 10)) < 0.3, "Manual return should snap to the closest branch center")
