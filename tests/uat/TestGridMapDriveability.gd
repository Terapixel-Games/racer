extends "res://tests/framework/TestCase.gd"

const TrackCatalog = preload("res://scripts/track/TrackCatalog.gd")
const TrackRuntimeBuilder = preload("res://scripts/track/TrackRuntimeBuilder.gd")
const CarScene = preload("res://scenes/Car.tscn")

const SIM_DELTA := 1.0 / 60.0
const CONNECTION_CASE_LIMIT := 4
const EDGE_CASE_LIMIT := 4
const ROUTE_DRIVE_SAMPLE_LIMIT := 4
const RAMP_LAUNCH_CASE_LIMIT := 3
const REAL_PHYSICS_RAMP_CASES := [116, 117, 136, 137, 138, 139, 140]

func test_gridmap_player_kart_crosses_kitchen_ramps_under_real_physics() -> void:
	for track_id in _gridmap_track_ids_under_test():
		var fixture := _build_track_runtime(track_id)
		var definition = fixture["definition"]
		var route_points: Array[Vector3] = definition.route_points
		await _settle_physics_frames(4)
		for route_index in REAL_PHYSICS_RAMP_CASES:
			if route_index >= route_points.size() - 1:
				continue
			var result := await _drive_real_physics_route_window(fixture, route_points, route_index, 6)
			var detail := " start=%d progress=%.2f min_y=%.2f max_y=%.2f airborne=%d final=%s route_dist=%.2f" % [
				route_index,
				float(result.get("progress", 0.0)),
				float(result.get("min_y", 0.0)),
				float(result.get("max_y", 0.0)),
				int(result.get("airborne_frames", 0)),
				str(result.get("position", Vector3.ZERO)),
				float(result.get("route_distance", -1.0)),
			]
			assert_true(bool(result.get("advanced", false)), "%s real physics should let a kart drive across ramp route index %d instead of stopping on invisible collision.%s" % [track_id, route_index, detail])
			assert_true(bool(result.get("above_bounds", false)), "%s real physics should keep a kart above the course rescue floor at route index %d.%s" % [track_id, route_index, detail])
			assert_true(bool(result.get("stable_contact", false)), "%s real physics should not become a long airborne/floating pass at route index %d.%s" % [track_id, route_index, detail])
			assert_true(bool(result.get("near_route", false)), "%s real physics should keep the kart near the GridMap route corridor at route index %d.%s" % [track_id, route_index, detail])
		_teardown_fixture(fixture)

func test_gridmap_player_kart_crosses_connected_route_edges() -> void:
	for track_id in _gridmap_track_ids_under_test():
		var fixture := _build_track_runtime(track_id)
		var definition = fixture["definition"]
		var route_points: Array[Vector3] = definition.route_points
		var cases := _connected_route_cases(definition, CONNECTION_CASE_LIMIT)
		assert_true(cases.size() > 0, "%s should expose connected route seams for driveability coverage" % track_id)
		for seam_case in cases:
			var result := await _drive_connection_case(fixture, seam_case as Dictionary, route_points)
			assert_true(bool(result.get("advanced", false)), "%s route index %d cell %s item %d should let the kart cross the connected edge" % [track_id, int((seam_case as Dictionary).get("route_index", -1)), str((seam_case as Dictionary).get("cell", Vector3i.ZERO)), int((seam_case as Dictionary).get("item", -1))])
			assert_true(bool(result.get("above_bounds", false)), "%s route index %d should keep the kart above out-of-bounds while crossing" % [track_id, int((seam_case as Dictionary).get("route_index", -1))])
			assert_true(bool(result.get("near_route", false)), "%s route index %d should keep the kart near the GridMap route corridor" % [track_id, int((seam_case as Dictionary).get("route_index", -1))])
		_teardown_fixture(fixture)

func test_gridmap_player_kart_cannot_drive_off_exposed_tile_edges() -> void:
	for track_id in _gridmap_track_ids_under_test():
		var fixture := _build_track_runtime(track_id)
		var definition = fixture["definition"]
		var cases := _exposed_edge_cases(definition, EDGE_CASE_LIMIT)
		assert_true(cases.size() > 0, "%s should expose outer GridMap edges for containment coverage" % track_id)
		for edge_case in cases:
			var result := await _drive_outward_edge_case(fixture, edge_case as Dictionary)
			assert_true(bool(result.get("contained", false)), "%s cell %s item %d edge %s should contain the kart at the exposed course edge" % [track_id, str((edge_case as Dictionary).get("cell", Vector3i.ZERO)), int((edge_case as Dictionary).get("item", -1)), str((edge_case as Dictionary).get("edge", Vector3i.ZERO))])
			assert_true(bool(result.get("above_bounds", false)), "%s cell %s edge %s should not rely on below-world rescue for containment" % [track_id, str((edge_case as Dictionary).get("cell", Vector3i.ZERO)), str((edge_case as Dictionary).get("edge", Vector3i.ZERO))])
		_teardown_fixture(fixture)

func test_gridmap_player_kart_cannot_escape_at_route_connections() -> void:
	for track_id in _gridmap_track_ids_under_test():
		var fixture := _build_track_runtime(track_id)
		var definition = fixture["definition"]
		var route_points: Array[Vector3] = definition.route_points
		var cases := _connected_route_cases(definition, CONNECTION_CASE_LIMIT)
		assert_true(cases.size() > 0, "%s should expose connected route seams for diagonal escape coverage" % track_id)
		for seam_case in cases:
			var result := await _drive_diagonal_connection_case(fixture, seam_case as Dictionary, route_points)
			assert_true(bool(result.get("advanced", false)), "%s route index %d should still allow forward progress when the kart enters the seam off-center" % [track_id, int((seam_case as Dictionary).get("route_index", -1))])
			assert_true(bool(result.get("contained", false)), "%s route index %d cell %s should not let the kart squeeze out at the connection" % [track_id, int((seam_case as Dictionary).get("route_index", -1)), str((seam_case as Dictionary).get("cell", Vector3i.ZERO))])
			assert_true(bool(result.get("above_bounds", false)), "%s route index %d should keep diagonal connection driving above out-of-bounds" % [track_id, int((seam_case as Dictionary).get("route_index", -1))])
		_teardown_fixture(fixture)

func test_gridmap_player_kart_stays_on_track_during_sampled_route_drive() -> void:
	for track_id in _gridmap_track_ids_under_test():
		var fixture := _build_track_runtime(track_id)
		var definition = fixture["definition"]
		var route_points: Array[Vector3] = definition.route_points
		var step := maxi(1, floori(float(route_points.size()) / float(ROUTE_DRIVE_SAMPLE_LIMIT)))
		for route_index in range(0, route_points.size(), step):
			var next_index := (route_index + 1) % route_points.size()
			var seam_case := _route_case(definition, route_index, next_index)
			var result := await _drive_connection_case(fixture, seam_case, route_points)
			assert_true(bool(result.get("above_bounds", false)), "%s sampled route index %d should stay above out-of-bounds" % [track_id, route_index])
			assert_true(bool(result.get("near_route", false)), "%s sampled route index %d should stay inside the road corridor" % [track_id, route_index])
		_teardown_fixture(fixture)

func test_gridmap_player_kart_cannot_jump_off_ramp_edges() -> void:
	for track_id in _gridmap_track_ids_under_test():
		var fixture := _build_track_runtime(track_id)
		var definition = fixture["definition"]
		var route_points: Array[Vector3] = definition.route_points
		var cases: Array[Dictionary] = []
		for route_index in [116, 136, 138]:
			if route_index < route_points.size():
				cases.append(_route_case(definition, route_index, (route_index + 1) % route_points.size()))
		assert_true(cases.size() > 0, "%s should expose ramp/elevation route cases for airborne containment coverage" % track_id)
		for ramp_case in cases:
			for side in [-1.0, 1.0]:
				var result := await _drive_ramp_launch_case(fixture, ramp_case as Dictionary, route_points, side)
				var detail := " final=%s dist=%.2f ramp_floor=%.2f" % [str(result.get("position", Vector3.ZERO)), float(result.get("route_distance", -1.0)), float(result.get("ramp_floor_y", 0.0))]
				assert_true(bool(result.get("contained", false)), "%s route index %d cell %s item %d side %.0f should keep an airborne kart inside the GridMap road corridor.%s" % [track_id, int((ramp_case as Dictionary).get("route_index", -1)), str((ramp_case as Dictionary).get("cell", Vector3i.ZERO)), int((ramp_case as Dictionary).get("item", -1)), side, detail])
				assert_true(bool(result.get("above_ramp_floor", false)), "%s route index %d side %.0f should not let an airborne kart drop to the stage/floor below the ramp.%s" % [track_id, int((ramp_case as Dictionary).get("route_index", -1)), side, detail])
				assert_true(bool(result.get("above_bounds", false)), "%s route index %d side %.0f should not rely on below-world rescue after ramp launch.%s" % [track_id, int((ramp_case as Dictionary).get("route_index", -1)), side, detail])
		_teardown_fixture(fixture)

func test_gridmap_player_kart_stays_supported_through_ramp_sequences() -> void:
	for track_id in _gridmap_track_ids_under_test():
		var fixture := _build_track_runtime(track_id)
		var definition = fixture["definition"]
		var route_points: Array[Vector3] = definition.route_points
		var cases := _ramp_launch_cases(definition, RAMP_LAUNCH_CASE_LIMIT)
		assert_true(cases.size() > 0, "%s should expose ramp/elevation route cases for support coverage" % track_id)
		for ramp_case in cases:
			var result := await _drive_ramp_sequence_case(fixture, ramp_case as Dictionary, route_points)
			var detail := " final=%s min_y=%.2f expected=%.2f dist=%.2f" % [str(result.get("position", Vector3.ZERO)), float(result.get("min_y", 0.0)), float(result.get("expected_floor", 0.0)), float(result.get("route_distance", -1.0))]
			assert_true(bool(result.get("supported", false)), "%s route index %d should keep the kart supported while driving through a ramp sequence.%s" % [track_id, int((ramp_case as Dictionary).get("route_index", -1)), detail])
			assert_true(bool(result.get("near_route", false)), "%s route index %d should keep the kart near the route while driving through a ramp sequence.%s" % [track_id, int((ramp_case as Dictionary).get("route_index", -1)), detail])
		_teardown_fixture(fixture)

func test_gridmap_player_kart_stays_supported_on_ramp_side_edges() -> void:
	for track_id in _gridmap_track_ids_under_test():
		var fixture := _build_track_runtime(track_id)
		var definition = fixture["definition"]
		var route_points: Array[Vector3] = definition.route_points
		for route_index in [136, 137, 138, 139, 140]:
			if route_index >= route_points.size():
				continue
			for side in [-1.0, 1.0]:
				var result := await _drive_ramp_side_support_case(fixture, route_points, route_index, side)
				var detail := " bottom=%.2f floor=%.2f ceiling=%.2f progress=%.2f pos=%s dist=%.2f" % [float(result.get("bottom_y", 0.0)), float(result.get("floor_y", 0.0)), float(result.get("ceiling_y", 0.0)), float(result.get("progress", 0.0)), str(result.get("position", Vector3.ZERO)), float(result.get("route_distance", -1.0))]
				assert_true(bool(result.get("above_surface", false)), "%s route index %d side %.0f should not let the kart body drop into the ramp-side GridMap surface.%s" % [track_id, route_index, side, detail])
				assert_true(bool(result.get("not_floating", false)), "%s route index %d side %.0f should not let the kart ride on an invisible raised collision ribbon above the GridMap surface.%s" % [track_id, route_index, side, detail])
				assert_true(bool(result.get("advanced", false)), "%s route index %d side %.0f should keep moving across the ramp-side surface instead of getting stuck on overlapping collision.%s" % [track_id, route_index, side, detail])
				assert_true(bool(result.get("near_route", false)), "%s route index %d side %.0f should stay near the ramp-side route corridor.%s" % [track_id, route_index, side, detail])
		_teardown_fixture(fixture)

func test_gridmap_start_slots_are_not_pinned_by_boundary_walls() -> void:
	for track_id in _gridmap_track_ids_under_test():
		var fixture_with_walls := _build_track_runtime(track_id, true)
		var fixture_without_walls := _build_track_runtime(track_id, false)
		var with_walls := await _simulate_start_slots_individually(fixture_with_walls)
		var without_walls := await _simulate_start_slots_individually(fixture_without_walls)
		assert_true(int(with_walls.get("advanced_count", 0)) >= int(without_walls.get("advanced_count", 0)), "%s boundary walls should not pin authored start slots compared with the same slots without walls. with=%d without=%d" % [track_id, int(with_walls.get("advanced_count", 0)), int(without_walls.get("advanced_count", 0))])
		assert_true(bool(with_walls.get("all_above_bounds", false)), "%s start-slot karts should stay above bounds with boundary walls enabled" % track_id)
		assert_true(bool(with_walls.get("all_near_route", false)), "%s start-slot karts should stay near the route corridor with boundary walls enabled" % track_id)
		_teardown_fixture(fixture_with_walls)
		_teardown_fixture(fixture_without_walls)

func _gridmap_track_ids_under_test() -> Array[String]:
	return ["kitchen"]

func _build_track_runtime(track_id: String, boundary_walls_override: Variant = null) -> Dictionary:
	var definition = TrackCatalog.get_definition(track_id)
	assert_true(definition != null, "%s should resolve a track definition" % track_id)
	if definition != null:
		if boundary_walls_override != null:
			definition = definition.duplicate(true)
			definition.boundary_walls_enabled = bool(boundary_walls_override)
		assert_equal(definition.road_visual_style, "kenney_gridmap", "%s should be a GridMap-backed track" % track_id)
		assert_true(not definition.road_grid_layout.is_empty(), "%s should expose RoadGridMap layout data" % track_id)
	var built := TrackRuntimeBuilder.build(definition)
	var root := built.get("node", null) as Node3D
	assert_true(root != null, "%s runtime track should build a root node" % track_id)
	if root != null:
		scene_tree.root.add_child(root)
	return {"definition": definition, "root": root, "built": built, "cars": []}

func _teardown_fixture(fixture: Dictionary) -> void:
	for car in fixture.get("cars", []):
		if is_instance_valid(car) and car is Node:
			(car as Node).queue_free()
	var root := fixture.get("root", null) as Node
	if root != null:
		root.queue_free()

func _spawn_probe_kart(fixture: Dictionary, transform: Transform3D) -> CarController:
	var car := CarScene.instantiate() as CarController
	assert_true(car != null, "Probe kart should instantiate from the gameplay car scene")
	if car == null:
		return null
	car.name = "GridMapDriveabilityProbe"
	car.controlled_locally = true
	car.visual_animation_enabled = false
	car.global_transform = transform
	scene_tree.root.add_child(car)
	var cars: Array = fixture.get("cars", [])
	cars.append(car)
	fixture["cars"] = cars
	return car

func _settle_physics_frames(count: int) -> void:
	for i in range(maxi(count, 0)):
		await scene_tree.physics_frame

func _drive_real_physics_route_window(fixture: Dictionary, route_points: Array[Vector3], start_index: int, window_size: int) -> Dictionary:
	var definition = fixture["definition"]
	var start := route_points[start_index]
	var first_target := route_points[(start_index + 1) % route_points.size()]
	var forward := _flat_direction(start, first_target)
	var spawn := Transform3D(Basis(Vector3.UP, atan2(forward.x, forward.z)), start - forward * 5.0 + Vector3.UP * 1.25)
	var car := _spawn_probe_kart(fixture, spawn)
	if car == null:
		return {}
	car.ground_snap_distance = 0.85
	car.floor_snap_length = maxf(car.floor_snap_length, car.ground_snap_distance)
	await _settle_physics_frames(3)
	var initial_progress := _route_progress(car.global_transform.origin, route_points)
	var target_index := (start_index + 1) % route_points.size()
	var end_index := (start_index + window_size) % route_points.size()
	var min_y := INF
	var max_y := -INF
	var airborne_frames := 0
	for frame in range(420):
		var target := route_points[target_index]
		var previous := route_points[(target_index - 1 + route_points.size()) % route_points.size()]
		var target_forward := _flat_direction(previous, target)
		_set_kart_input_toward(car, target + target_forward * 8.0, 0.85)
		await scene_tree.physics_frame
		if not car.is_on_floor():
			airborne_frames += 1
		min_y = minf(min_y, car.global_transform.origin.y)
		max_y = maxf(max_y, car.global_transform.origin.y)
		var segment_progress := (car.global_transform.origin - previous).dot(target_forward)
		if target_index != end_index and (car.global_transform.origin.distance_to(target) < 7.0 or segment_progress > previous.distance_to(target) * 0.65):
			target_index = (target_index + 1) % route_points.size()
	var final_position := car.global_transform.origin
	var final_progress := _route_progress(final_position, route_points)
	var progress_delta := final_progress - initial_progress
	if progress_delta < -float(definition.road_width):
		progress_delta += _route_length(route_points)
	var route_distance := _nearest_route_distance(final_position, route_points)
	return {
		"advanced": progress_delta > 18.0,
		"above_bounds": min_y > float(definition.out_of_bounds_y) + 2.0,
		"stable_contact": airborne_frames < 90,
		"near_route": route_distance <= float(definition.road_width) * 0.95,
		"position": final_position,
		"progress": progress_delta,
		"min_y": min_y,
		"max_y": max_y,
		"airborne_frames": airborne_frames,
		"route_distance": route_distance,
	}

func _connected_route_cases(definition, limit: int) -> Array[Dictionary]:
	var cases: Array[Dictionary] = []
	var route_cells := _route_cells(definition)
	for i in range(route_cells.size()):
		var next_index := (i + 1) % route_cells.size()
		var current := route_cells[i]
		var next := route_cells[next_index]
		if abs(current.x - next.x) + abs(current.z - next.z) != 1:
			continue
		if abs(current.y - next.y) > 1:
			continue
		var route_case := _route_case(definition, i, next_index)
		var priority := 0
		if current.y != next.y:
			priority += 4
		if int(route_case.get("item", -1)) in [5, 6, 7] or int(route_case.get("next_item", -1)) in [5, 6, 7]:
			priority += 3
		if _route_turns_at(route_cells, i):
			priority += 2
		route_case["priority"] = priority
		cases.append(route_case)
	cases.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("priority", 0)) > int(b.get("priority", 0))
	)
	return cases.slice(0, mini(limit, cases.size()))

func _ramp_launch_cases(definition, limit: int) -> Array[Dictionary]:
	var cases: Array[Dictionary] = []
	var route_cells := _route_cells(definition)
	for i in range(route_cells.size()):
		var next_index := (i + 1) % route_cells.size()
		var current := route_cells[i]
		var next := route_cells[next_index]
		var route_case := _route_case(definition, i, next_index)
		var item := int(route_case.get("item", -1))
		var next_item := int(route_case.get("next_item", -1))
		if not (item in [5, 6, 7] or next_item in [5, 6, 7] or current.y != next.y):
			continue
		var priority := 0
		if current.y != next.y:
			priority += 4
		if item in [5, 6, 7]:
			priority += 3
		if next_item in [5, 6, 7]:
			priority += 2
		if _route_turns_at(route_cells, i):
			priority += 1
		route_case["priority"] = priority
		cases.append(route_case)
	cases.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("priority", 0)) > int(b.get("priority", 0))
	)
	return cases.slice(0, mini(limit, cases.size()))

func _exposed_edge_cases(definition, limit: int) -> Array[Dictionary]:
	var cases: Array[Dictionary] = []
	var route_lookup := _route_cell_lookup(definition)
	var cell_lookup := _cell_data_lookup(definition)
	for cell in _route_cells(definition):
		var data: Dictionary = cell_lookup.get(cell, {})
		for direction in [Vector3i.LEFT, Vector3i.RIGHT, Vector3i.FORWARD, Vector3i.BACK]:
			if route_lookup.has(cell + direction) or route_lookup.has(cell + direction + Vector3i.UP) or route_lookup.has(cell + direction + Vector3i.DOWN):
				continue
			var priority := 0
			var item := int(data.get("item", -1))
			if item in [5, 6, 7]:
				priority += 4
			if cell.y != 0:
				priority += 2
			if item in [2, 3, 4]:
				priority += 1
			cases.append({
				"cell": cell,
				"edge": direction,
				"item": item,
				"data": data,
				"position": _vector3_from_value(data.get("position", Vector3.ZERO), Vector3.ZERO),
				"priority": priority,
			})
	cases.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("priority", 0)) > int(b.get("priority", 0))
	)
	return cases.slice(0, mini(limit, cases.size()))

func _drive_connection_case(fixture: Dictionary, seam_case: Dictionary, route_points: Array[Vector3]) -> Dictionary:
	var definition = fixture["definition"]
	var route_index := int(seam_case.get("route_index", 0))
	var next_index := int(seam_case.get("next_index", (route_index + 1) % route_points.size()))
	var start := route_points[route_index]
	var target := route_points[next_index]
	var forward := _flat_direction(start, target)
	var spawn := Transform3D(Basis(Vector3.UP, atan2(forward.x, forward.z)), start - forward * 5.0 + Vector3.UP * 1.8)
	var car := _spawn_probe_kart(fixture, spawn)
	if car == null:
		return {}
	var initial_progress := (car.global_transform.origin - start).dot(forward)
	var result := await _simulate_kart_toward(car, target + forward * 10.0, 1.8, 1.0)
	var final_position := car.global_transform.origin
	var final_progress := (final_position - start).dot(forward)
	return {
		"advanced": final_progress > initial_progress + 6.0,
		"above_bounds": final_position.y > float(definition.out_of_bounds_y) + 2.0,
		"near_route": _nearest_route_distance(final_position, route_points) <= float(definition.road_width) * 0.75,
		"result": result,
	}

func _drive_diagonal_connection_case(fixture: Dictionary, seam_case: Dictionary, route_points: Array[Vector3]) -> Dictionary:
	var definition = fixture["definition"]
	var route_index := int(seam_case.get("route_index", 0))
	var next_index := int(seam_case.get("next_index", (route_index + 1) % route_points.size()))
	var start := route_points[route_index]
	var target := route_points[next_index]
	var forward := _flat_direction(start, target)
	var lateral := Vector3(forward.z, 0.0, -forward.x).normalized()
	var spawn := Transform3D(Basis(Vector3.UP, atan2((forward + lateral * 0.45).normalized().x, (forward + lateral * 0.45).normalized().z)), start - forward * 4.0 + lateral * 4.2 + Vector3.UP * 1.8)
	var car := _spawn_probe_kart(fixture, spawn)
	if car == null:
		return {}
	var initial_progress := (car.global_transform.origin - start).dot(forward)
	var result := await _simulate_kart_toward(car, target + forward * 9.0 + lateral * 4.2, 1.6, 1.0)
	var final_position := car.global_transform.origin
	var final_progress := (final_position - start).dot(forward)
	return {
		"advanced": final_progress > initial_progress + 4.0,
		"contained": _nearest_route_distance(final_position, route_points) <= float(definition.road_width) * 0.85,
		"above_bounds": final_position.y > float(definition.out_of_bounds_y) + 2.0,
		"result": result,
	}

func _drive_ramp_launch_case(fixture: Dictionary, ramp_case: Dictionary, route_points: Array[Vector3], side: float) -> Dictionary:
	var definition = fixture["definition"]
	var route_index := int(ramp_case.get("route_index", 0))
	var next_index := int(ramp_case.get("next_index", (route_index + 1) % route_points.size()))
	var start := route_points[route_index]
	var target := route_points[next_index]
	var forward := _flat_direction(start, target)
	var lateral := Vector3(forward.z, 0.0, -forward.x).normalized() * side
	var drive_direction := (forward + lateral * 0.65).normalized()
	var yaw_direction := drive_direction
	var spawn_position := start - forward * 5.0 + lateral * (float(definition.road_width) * 0.42) + Vector3.UP * 2.0
	var spawn := Transform3D(Basis(Vector3.UP, atan2(yaw_direction.x, yaw_direction.z)), spawn_position)
	var car := _spawn_probe_kart(fixture, spawn)
	if car == null:
		return {}
	car.velocity = (forward * 18.0) + (lateral * 3.0)
	var result := await _simulate_kart_toward(car, target + forward * 12.0 + lateral * 6.0, 1.6, 0.85)
	var final_position := car.global_transform.origin
	var ramp_floor_y := minf(start.y, target.y) - 4.0
	var route_distance := _nearest_route_distance(final_position, route_points)
	return {
		"contained": route_distance <= float(definition.road_width) * 0.95,
		"above_ramp_floor": final_position.y > float(definition.out_of_bounds_y) + 2.0,
		"above_bounds": final_position.y > float(definition.out_of_bounds_y) + 2.0,
		"position": final_position,
		"route_distance": route_distance,
		"ramp_floor_y": ramp_floor_y,
		"result": result,
	}

func _drive_ramp_sequence_case(fixture: Dictionary, ramp_case: Dictionary, route_points: Array[Vector3]) -> Dictionary:
	var definition = fixture["definition"]
	var route_index := int(ramp_case.get("route_index", 0))
	var start_index := posmod(route_index - 2, route_points.size())
	var end_index := posmod(route_index + 4, route_points.size())
	var start := route_points[start_index]
	var next := route_points[posmod(start_index + 1, route_points.size())]
	var forward := _flat_direction(start, next)
	var spawn := Transform3D(Basis(Vector3.UP, atan2(forward.x, forward.z)), start - forward * 4.0 + Vector3.UP * 1.0)
	var car := _spawn_probe_kart(fixture, spawn)
	if car == null:
		return {}
	var min_y := INF
	var expected_floor := INF
	var expected_index := start_index
	while true:
		expected_floor = minf(expected_floor, route_points[expected_index].y)
		if expected_index == end_index:
			break
		expected_index = posmod(expected_index + 1, route_points.size())
	expected_floor -= 2.0
	var target_index := posmod(start_index + 1, route_points.size())
	for frame in range(360):
		var target := route_points[target_index]
		var segment_start := route_points[posmod(target_index - 1, route_points.size())]
		var target_forward := _flat_direction(segment_start, target)
		var segment_length := segment_start.distance_to(target)
		var segment_progress := (car.global_transform.origin - segment_start).dot(target_forward)
		if target_index != end_index and (car.global_transform.origin.distance_to(target) < 8.0 or segment_progress >= segment_length * 0.45):
			target_index = posmod(target_index + 1, route_points.size())
			target = route_points[target_index]
			segment_start = route_points[posmod(target_index - 1, route_points.size())]
			target_forward = _flat_direction(segment_start, target)
		await _simulate_kart_toward(car, target + target_forward * 6.0, SIM_DELTA, 0.55)
		min_y = minf(min_y, car.global_transform.origin.y)
	var final_position := car.global_transform.origin
	var route_distance := _nearest_route_distance(final_position, route_points)
	return {
		"supported": min_y >= expected_floor,
		"near_route": route_distance <= float(definition.road_width) * 0.95,
		"position": final_position,
		"min_y": min_y,
		"expected_floor": expected_floor,
		"route_distance": route_distance,
	}

func _drive_ramp_side_support_case(fixture: Dictionary, route_points: Array[Vector3], route_index: int, side: float) -> Dictionary:
	var definition = fixture["definition"]
	var start := route_points[route_index]
	var target := route_points[(route_index + 1) % route_points.size()]
	var forward := _flat_direction(start, target)
	var lateral := Vector3(forward.z, 0.0, -forward.x).normalized() * side
	var drive_direction := (forward + lateral * 0.35).normalized()
	var spawn := Transform3D(
		Basis(Vector3.UP, atan2(drive_direction.x, drive_direction.z)),
		start - forward * 7.0 + lateral * 4.2 + Vector3.UP * 2.0
	)
	var car := _spawn_probe_kart(fixture, spawn)
	if car == null:
		return {}
	var initial_progress := (car.global_transform.origin - start).dot(forward)
	for frame in range(360):
		await _simulate_kart_toward(car, target + forward * 16.0 + lateral * 8.0, SIM_DELTA, 1.0)
	var final_position := car.global_transform.origin
	var final_progress := (final_position - start).dot(forward)
	var route_distance := _nearest_route_distance(final_position, route_points)
	var expected_floor := minf(start.y, target.y) - 4.0
	var expected_ceiling := maxf(start.y, target.y) + 1.85
	var bottom_y := _car_collision_bottom_y(car)
	return {
		"above_surface": final_position.y > float(definition.out_of_bounds_y) + 2.0,
		"not_floating": car.is_on_floor() or final_position.y <= expected_ceiling + 2.0,
		"advanced": final_progress > initial_progress + 4.0,
		"near_route": route_distance <= float(definition.road_width) * 0.95,
		"position": final_position,
		"bottom_y": bottom_y,
		"floor_y": expected_floor,
		"ceiling_y": expected_ceiling,
		"progress": final_progress - initial_progress,
		"route_distance": route_distance,
	}

func _drive_outward_edge_case(fixture: Dictionary, edge_case: Dictionary) -> Dictionary:
	var definition = fixture["definition"]
	var cell_size := _cell_size(definition)
	var direction := edge_case.get("edge", Vector3i.ZERO) as Vector3i
	var outward := Vector3(float(direction.x), 0.0, float(direction.z)).normalized()
	var data := edge_case.get("data", {}) as Dictionary
	var position := edge_case.get("position", Vector3.ZERO) as Vector3
	var cell := edge_case.get("cell", Vector3i.ZERO) as Vector3i
	var edge_grid_point := Vector3(float(cell.x) + 0.5 + outward.x * 0.5, 0.0, float(cell.z) + 0.5 + outward.z * 0.5)
	var edge_center := position + Vector3(outward.x * cell_size.x * 0.5, 0.0, outward.z * cell_size.z * 0.5)
	edge_center.y = _surface_y_for_grid_point(data, edge_grid_point, cell_size)
	var spawn_position := edge_center - outward * 2.2 + Vector3.UP * 1.8
	var spawn := Transform3D(Basis(Vector3.UP, atan2(outward.x, outward.z)), spawn_position)
	var car := _spawn_probe_kart(fixture, spawn)
	if car == null:
		return {}
	var before_edge_distance := (car.global_transform.origin - edge_center).dot(outward)
	var result := await _simulate_kart_toward(car, edge_center + outward * 18.0, 1.35, 1.0)
	var final_position := car.global_transform.origin
	var after_edge_distance := (final_position - edge_center).dot(outward)
	return {
		"contained": after_edge_distance <= 1.4 and after_edge_distance <= before_edge_distance + 3.8,
		"above_bounds": final_position.y > float(definition.out_of_bounds_y) + 2.0,
		"result": result,
	}

func _simulate_kart_toward(car: CarController, target: Vector3, seconds: float, throttle: float) -> Dictionary:
	var frames := ceili(seconds / SIM_DELTA)
	for i in range(frames):
		_set_kart_input_toward(car, target, throttle)
		await scene_tree.physics_frame
	return {"position": car.global_transform.origin, "velocity": car.velocity}

func _simulate_start_slots_individually(fixture: Dictionary) -> Dictionary:
	var definition = fixture["definition"]
	var route_points: Array[Vector3] = definition.route_points
	var spawn_points: Array[Vector4] = definition.spawn_points
	if spawn_points.size() < 8:
		return {"advanced_count": 0, "all_above_bounds": false, "all_near_route": false}
	var advanced_count := 0
	var all_above_bounds := true
	var all_near_route := true
	for i in range(8):
		var spawn := _spawn_transform_from_vector4(spawn_points[i])
		var car := _spawn_probe_kart(fixture, spawn)
		if car == null:
			continue
		var start_progress := _route_progress(car.global_transform.origin, route_points)
		for frame in range(360):
			var nearest := _nearest_route_index(car.global_transform.origin, route_points)
			var target := route_points[(nearest + 6) % route_points.size()]
			_set_kart_input_toward(car, target, 0.75)
			await scene_tree.physics_frame
		var position := car.global_transform.origin
		var progress_delta := _route_progress(position, route_points) - start_progress
		if progress_delta < -float(definition.road_width):
			progress_delta += _route_length(route_points)
		if progress_delta > 8.0:
			advanced_count += 1
		all_above_bounds = all_above_bounds and position.y > float(definition.out_of_bounds_y) + 2.0
		all_near_route = all_near_route and _nearest_route_distance(position, route_points) <= float(definition.road_width) * 1.15
		car.queue_free()
		var cars: Array = fixture.get("cars", [])
		cars.erase(car)
		fixture["cars"] = cars
	return {
		"advanced_count": advanced_count,
		"all_above_bounds": all_above_bounds,
		"all_near_route": all_near_route,
	}

func _step_kart_toward(car: CarController, target: Vector3, throttle: float) -> void:
	_set_kart_input_toward(car, target, throttle)
	car.call("_physics_process", SIM_DELTA)

func _set_kart_input_toward(car: CarController, target: Vector3, throttle: float) -> void:
	var to_target := target - car.global_transform.origin
	to_target.y = 0.0
	var forward := car.global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var steer := 0.0
	if to_target.length_squared() > 0.001 and forward.length_squared() > 0.001:
		var desired := to_target.normalized()
		steer = clampf(forward.cross(desired).y * 1.8, -1.0, 1.0)
	car.set_input({"throttle": throttle, "brake": 0.0, "steer": steer, "drift": false, "boost": false, "item_use": false})

func _route_case(definition, route_index: int, next_index: int) -> Dictionary:
	var route_cells := _route_cells(definition)
	var cell_lookup := _cell_data_lookup(definition)
	var cell := route_cells[route_index]
	var next_cell := route_cells[next_index]
	var data: Dictionary = cell_lookup.get(cell, {})
	var next_data: Dictionary = cell_lookup.get(next_cell, {})
	return {
		"route_index": route_index,
		"next_index": next_index,
		"cell": cell,
		"next_cell": next_cell,
		"item": int(data.get("item", -1)),
		"next_item": int(next_data.get("item", -1)),
	}

func _route_cells(definition) -> Array[Vector3i]:
	var cells: Array[Vector3i] = []
	for value in definition.road_grid_layout.get("ordered_route_cells", []):
		cells.append(_vector3i_from_value(value))
	return cells

func _route_cell_lookup(definition) -> Dictionary:
	var lookup := {}
	for cell in _route_cells(definition):
		lookup[cell] = true
	return lookup

func _cell_data_lookup(definition) -> Dictionary:
	var lookup := {}
	for value in definition.road_grid_layout.get("cells", []):
		if value is Dictionary:
			var data := value as Dictionary
			lookup[_vector3i_from_value(data.get("cell", Vector3i.ZERO))] = data
	return lookup

func _route_turns_at(route_cells: Array[Vector3i], index: int) -> bool:
	if route_cells.size() < 3:
		return false
	var previous := route_cells[(index - 1 + route_cells.size()) % route_cells.size()]
	var current := route_cells[index]
	var next := route_cells[(index + 1) % route_cells.size()]
	var incoming := Vector2i(current.x - previous.x, current.z - previous.z)
	var outgoing := Vector2i(next.x - current.x, next.z - current.z)
	return incoming != outgoing

func _nearest_route_distance(position: Vector3, route_points: Array[Vector3]) -> float:
	var best := INF
	for i in range(route_points.size()):
		var a := route_points[i]
		var b := route_points[(i + 1) % route_points.size()]
		var a2 := Vector2(a.x, a.z)
		var b2 := Vector2(b.x, b.z)
		var p2 := Vector2(position.x, position.z)
		var segment := b2 - a2
		var t := 0.0
		if segment.length_squared() > 0.001:
			t = clampf((p2 - a2).dot(segment) / segment.length_squared(), 0.0, 1.0)
		best = minf(best, p2.distance_to(a2 + segment * t))
	return best

func _nearest_route_index(position: Vector3, route_points: Array[Vector3]) -> int:
	var best := INF
	var best_index := 0
	var p2 := Vector2(position.x, position.z)
	for i in range(route_points.size()):
		var point := route_points[i]
		var distance := p2.distance_to(Vector2(point.x, point.z))
		if distance < best:
			best = distance
			best_index = i
	return best_index

func _route_progress(position: Vector3, route_points: Array[Vector3]) -> float:
	var best_distance := INF
	var best_progress := 0.0
	var accumulated := 0.0
	var p2 := Vector2(position.x, position.z)
	for i in range(route_points.size()):
		var a := route_points[i]
		var b := route_points[(i + 1) % route_points.size()]
		var a2 := Vector2(a.x, a.z)
		var b2 := Vector2(b.x, b.z)
		var segment := b2 - a2
		var segment_length := segment.length()
		var t := 0.0
		if segment.length_squared() > 0.001:
			t = clampf((p2 - a2).dot(segment) / segment.length_squared(), 0.0, 1.0)
		var closest := a2 + segment * t
		var distance := p2.distance_to(closest)
		if distance < best_distance:
			best_distance = distance
			best_progress = accumulated + segment_length * t
		accumulated += segment_length
	return best_progress

func _route_surface_y_at(position: Vector3, route_points: Array[Vector3]) -> float:
	var best_distance := INF
	var best_y := position.y
	var p2 := Vector2(position.x, position.z)
	for i in range(route_points.size()):
		var a := route_points[i]
		var b := route_points[(i + 1) % route_points.size()]
		var a2 := Vector2(a.x, a.z)
		var b2 := Vector2(b.x, b.z)
		var segment := b2 - a2
		var t := 0.0
		if segment.length_squared() > 0.001:
			t = clampf((p2 - a2).dot(segment) / segment.length_squared(), 0.0, 1.0)
		var closest := a2 + segment * t
		var distance := p2.distance_to(closest)
		if distance < best_distance:
			best_distance = distance
			best_y = lerpf(a.y, b.y, t)
	return best_y

func _route_length(route_points: Array[Vector3]) -> float:
	var length := 0.0
	for i in range(route_points.size()):
		var a := route_points[i]
		var b := route_points[(i + 1) % route_points.size()]
		length += Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z))
	return length

func _spawn_transform_from_vector4(spawn: Vector4) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, deg_to_rad(spawn.w)), Vector3(spawn.x, spawn.y, spawn.z))

func _car_collision_bottom_y(car: CarController) -> float:
	var shape_node := car.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if shape_node == null or not (shape_node.shape is BoxShape3D):
		return car.global_transform.origin.y
	var box := shape_node.shape as BoxShape3D
	return car.global_transform.origin.y + shape_node.transform.origin.y - box.size.y * 0.5

func _flat_direction(from: Vector3, to: Vector3) -> Vector3:
	var delta := to - from
	delta.y = 0.0
	if delta.length_squared() <= 0.001:
		return Vector3.FORWARD
	return delta.normalized()

func _cell_size(definition) -> Vector3:
	return _vector3_from_value(definition.road_grid_layout.get("cell_size", Vector3(16.0, 4.0, 16.0)), Vector3(16.0, 4.0, 16.0))

func _surface_y_for_grid_point(cell_data: Dictionary, grid_point: Vector3, cell_size: Vector3) -> float:
	var cell := _vector3i_from_value(cell_data.get("cell", Vector3i.ZERO))
	var position := _vector3_from_value(cell_data.get("position", Vector3.ZERO), Vector3.ZERO)
	var item := int(cell_data.get("item", -1))
	var basis := _orientation_basis(cell_data)
	var forward := _horizontal_direction_from_vector(basis.z)
	if not item in [5, 6, 7] or forward == Vector3i.ZERO:
		return position.y
	var anchor_center := Vector3((float(cell.x) + 0.5) * cell_size.x, 0.0, (float(cell.z) + 0.5) * cell_size.z)
	var point_xz := Vector3(grid_point.x * cell_size.x, 0.0, grid_point.z * cell_size.z)
	var forward_vec := Vector3(float(forward.x), 0.0, float(forward.z)).normalized()
	var length := cell_size.z
	if item in [6, 7]:
		length *= 2.0
	var start := anchor_center - forward_vec * (cell_size.z * 0.5)
	var progress := clampf((point_xz - start).dot(forward_vec) / maxf(length, 0.001), 0.0, 1.0)
	return position.y + progress * cell_size.y

func _orientation_basis(cell_data: Dictionary) -> Basis:
	if cell_data.has("orientation_basis"):
		return _basis_from_value(cell_data.get("orientation_basis", []))
	var grid := GridMap.new()
	var basis := grid.get_basis_with_orthogonal_index(int(cell_data.get("orientation", 0)))
	grid.free()
	return basis

func _horizontal_direction_from_vector(vector: Vector3) -> Vector3i:
	var x := int(roundf(vector.x))
	var z := int(roundf(vector.z))
	if abs(x) > abs(z):
		return Vector3i(1 if x > 0 else -1, 0, 0)
	if abs(z) > 0:
		return Vector3i(0, 0, 1 if z > 0 else -1)
	return Vector3i.ZERO

func _vector3i_from_value(value: Variant) -> Vector3i:
	if value is Vector3i:
		return value as Vector3i
	if value is Vector3:
		var vector := value as Vector3
		return Vector3i(roundi(vector.x), roundi(vector.y), roundi(vector.z))
	if value is Array and (value as Array).size() >= 3:
		var array := value as Array
		return Vector3i(int(array[0]), int(array[1]), int(array[2]))
	return Vector3i.ZERO

func _vector3_from_value(value: Variant, fallback: Vector3) -> Vector3:
	if value is Vector3:
		return value as Vector3
	if value is Vector3i:
		var vector := value as Vector3i
		return Vector3(float(vector.x), float(vector.y), float(vector.z))
	if value is Array and (value as Array).size() >= 3:
		var array := value as Array
		return Vector3(float(array[0]), float(array[1]), float(array[2]))
	return fallback

func _basis_from_value(value: Variant) -> Basis:
	if value is Basis:
		return value as Basis
	if value is Array and (value as Array).size() >= 3:
		var array := value as Array
		return Basis(
			_vector3_from_value(array[0], Vector3.RIGHT),
			_vector3_from_value(array[1], Vector3.UP),
			_vector3_from_value(array[2], Vector3.BACK)
		)
	return Basis.IDENTITY
