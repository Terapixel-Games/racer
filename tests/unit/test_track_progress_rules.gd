extends "res://tests/framework/TestCase.gd"

const TrackCatalog = preload("res://scripts/track/TrackCatalog.gd")
const TrackProgressRules = preload("res://scripts/track/TrackProgressRules.gd")
const RaceController = preload("res://scripts/RaceController.gd")

func test_projection_progress_increases_along_route() -> void:
	var definition := TrackCatalog.get_definition("kitchen")
	var route: Array[Vector3] = definition.route_points
	assert_true(route.size() >= 12, "Kitchen route should expose enough points for projection ordering")
	if route.size() < 12:
		return
	var near_start := TrackProgressRules.project_position(route, route[2], true)
	var later := TrackProgressRules.project_position(route, route[10], true)
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

func test_race_distance_combines_lap_and_projected_route_distance() -> void:
	var route: Array[Vector3] = [Vector3.ZERO, Vector3(100, 0, 0), Vector3(100, 0, 100), Vector3(0, 0, 100)]
	var distance := TrackProgressRules.race_distance(route, [], [0, 1, 2, 3], Vector3(50, 0, 0), 2, true)
	assert_true(absf(float(distance.get("route_length", 0.0)) - 400.0) < 0.01, "Closed route length should include the return segment")
	assert_true(absf(float(distance.get("lap_distance", 0.0)) - 50.0) < 0.01, "Lap distance should come from route projection")
	assert_true(absf(float(distance.get("total_distance", 0.0)) - 450.0) < 0.01, "Total race distance should include completed laps")

func test_kitchen_grid_route_positions_order_racers_by_distance() -> void:
	var definition := TrackCatalog.get_definition("kitchen")
	var route: Array[Vector3] = definition.route_points
	assert_true(route.size() >= 12, "Kitchen RoadGridMap route should expose enough points for rank projection")
	if route.size() < 12:
		return
	var trailing := TrackProgressRules.race_distance(route, definition.alternate_routes, definition.checkpoint_indices, route[2], 1, definition.closed_loop)
	var leading := TrackProgressRules.race_distance(route, definition.alternate_routes, definition.checkpoint_indices, route[10], 1, definition.closed_loop)
	var trailing_progress := TrackProgressRules.progress_from_race_distance(1, definition.checkpoint_indices.size(), float(trailing.get("route_ratio", 0.0)))
	var leading_progress := TrackProgressRules.progress_from_race_distance(1, definition.checkpoint_indices.size(), float(leading.get("route_ratio", 0.0)))
	assert_true(leading_progress > trailing_progress, "Kitchen RoadGridMap route projection should rank farther karts ahead")

func test_progress_from_race_distance_does_not_double_count_checkpoint_index() -> void:
	var value := TrackProgressRules.progress_from_race_distance(1, 6, 0.25, false)
	assert_true(absf(value - 1.5) < 0.01, "Continuous progress should be route ratio scaled by checkpoint count, not checkpoint plus route ratio")

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

func test_kitchen_grid_checkpoint_sequence_tracks_laps_and_finish() -> void:
	var definition := TrackCatalog.get_definition("kitchen")
	var checkpoint_count := definition.checkpoint_indices.size()
	assert_true(checkpoint_count >= 3, "Kitchen RoadGridMap route should expose race checkpoints")
	var checkpoint := 0
	var lap := 1
	var lap_gate_passed := false
	var result := {}
	for completed_lap in range(1, definition.laps + 1):
		for passed in range(checkpoint_count):
			result = TrackProgressRules.apply_checkpoint_pass(
				checkpoint,
				lap,
				lap_gate_passed,
				passed,
				checkpoint_count,
				definition.lap_gate_checkpoint_index,
				definition.laps
			)
			assert_true(bool(result.get("accepted", false)), "Kitchen checkpoint %d should advance in sequence" % passed)
			checkpoint = int(result.get("checkpoint", checkpoint))
			lap = int(result.get("lap", lap))
			lap_gate_passed = bool(result.get("lap_gate_passed", lap_gate_passed))
		if completed_lap < definition.laps:
			assert_equal(lap, completed_lap + 1, "Kitchen lap should advance after the full checkpoint loop")
			assert_true(not bool(result.get("finished", false)), "Kitchen should not finish before the final lap loop")
	assert_true(bool(result.get("finished", false)), "Kitchen should finish after the final RoadGridMap checkpoint loop")

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
