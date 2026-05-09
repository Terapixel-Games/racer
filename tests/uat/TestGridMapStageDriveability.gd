extends "res://tests/framework/TestCase.gd"

const TrackCatalog = preload("res://scripts/track/TrackCatalog.gd")
const TrackGridRoadBuilder = preload("res://scripts/track/TrackGridRoadBuilder.gd")
const TrackRuntimeBuilder = preload("res://scripts/track/TrackRuntimeBuilder.gd")
const TrackSourceRules = preload("res://scripts/track/TrackSourceRules.gd")

const CAR_SCENE := "res://scenes/Car.tscn"
const TEST_PROBE_ACCELERATION := 180.0
const TEST_PROBE_MAX_SPEED := 96.0
const TEST_PROBE_STEER_SPEED := 5.5

func test_gridmap_track_centerline_has_continuous_road_collision() -> void:
	for track_id in _gridmap_track_ids_under_test():
		var context := _build_track_runtime(track_id)
		var track := context.get("track", null) as Node3D
		var definition = context.get("definition", null)
		scene_tree.root.add_child(track)
		await _settle_physics()
		assert_true(track != null, "%s runtime track should build" % track_id)
		if track == null:
			continue
		var route: Array[Vector3] = definition.route_points
		assert_true(route.size() >= 4, "%s should expose a driveable route" % track_id)
		var segment_count := route.size() if definition.closed_loop else route.size() - 1
		for route_index in range(segment_count):
			var a := route[route_index]
			var b := route[(route_index + 1) % route.size()]
			for ratio in [0.1, 0.25, 0.5, 0.75, 0.9]:
				var sample := a.lerp(b, float(ratio))
				assert_true(_ray_hits_road_near(track, sample + Vector3.UP * 40.0, 90.0), "%s centerline road collision should exist at route %d ratio %.2f" % [track_id, route_index, ratio])
		track.queue_free()
		await _settle_physics(2)

func test_gridmap_track_centerline_driver_completes_three_laps() -> void:
	for track_id in _gridmap_track_ids_under_test():
		var context := _build_track_runtime(track_id)
		var track := context.get("track", null) as Node3D
		var definition = context.get("definition", null)
		scene_tree.root.add_child(track)
		await _settle_physics()
		var car := _spawn_probe_kart(_route_transform_for_index(track, definition, 0, 0.0))
		await _settle_physics()

		var current_checkpoint := 0
		var lap := 1
		var lap_gate_passed := false
		var finished := false
		var guard_laps := 0
		var checkpoint_count: int = definition.checkpoint_indices.size()
		while not finished and guard_laps < definition.laps + 1:
			for route_index in range(definition.route_points.size()):
				car.global_transform = _route_transform_for_index(track, definition, route_index, 0.0)
				await scene_tree.physics_frame
				assert_true(car.global_position.y > float(definition.out_of_bounds_y), "%s centerline driver should stay above out-of-bounds at route %d lap %d" % [track_id, route_index, lap])
				assert_true(_ray_hits_road_near(track, car.global_position + Vector3.UP * 12.0, 30.0), "%s centerline driver should remain over road collision at route %d lap %d" % [track_id, route_index, lap])
				if checkpoint_count > 0 and route_index == int(definition.checkpoint_indices[current_checkpoint]):
					var result := TrackSourceRules.apply_checkpoint_pass(
						definition.win_condition_id,
						current_checkpoint,
						lap,
						lap_gate_passed,
						current_checkpoint,
						checkpoint_count,
						definition.lap_gate_checkpoint_index,
						definition.laps
					)
					assert_true(bool(result.get("accepted", false)), "%s centerline driver should hit checkpoint %d in order on lap %d" % [track_id, current_checkpoint, lap])
					current_checkpoint = int(result.get("checkpoint", current_checkpoint))
					lap = int(result.get("lap", lap))
					lap_gate_passed = bool(result.get("lap_gate_passed", lap_gate_passed))
					finished = bool(result.get("finished", false))
					if finished:
						break
			guard_laps += 1

		assert_true(finished, "%s centerline driver should complete the 3-lap race" % track_id)
		car.queue_free()
		track.queue_free()
		await _settle_physics(2)

func test_gridmap_track_boundary_walls_contain_exposed_edge_probes() -> void:
	for track_id in _gridmap_track_ids_under_test():
		var context := _build_track_runtime(track_id)
		var track := context.get("track", null) as Node3D
		var definition = context.get("definition", null)
		scene_tree.root.add_child(track)
		await _settle_physics()
		var cases := _representative_boundary_segments(track, definition, 2)
		assert_true(cases.size() >= 2, "%s should expose representative boundary wall test cases" % track_id)
		for case_index in range(cases.size()):
			var segment := cases[case_index] as Dictionary
			for speed in [18.0, 32.0]:
				var transform := _inside_edge_transform(track, segment, 0.0)
				var car := _spawn_probe_kart(transform)
				await _settle_physics(8)
				await _simulate_kart(car, 36, {"throttle": 1.0, "brake": 0.0, "steer": 0.0, "drift": false, "boost": false, "item_use": false}, transform.basis.z.normalized() * speed)
				await _settle_physics()
				var signed_distance := _signed_edge_distance(car.global_position, segment)
				assert_true(signed_distance <= 3.0, "%s boundary wall should contain edge case %d at speed %.1f" % [track_id, case_index, speed])
				assert_true(car.global_position.y > float(definition.out_of_bounds_y), "%s boundary wall should keep edge case %d in scene at speed %.1f" % [track_id, case_index, speed])
				car.queue_free()
				await _settle_physics(2)
		track.queue_free()
		await _settle_physics(2)

func _gridmap_track_ids_under_test() -> Array[String]:
	var ids: Array[String] = []
	for summary in TrackCatalog.list_tracks():
		ids.append(str(summary.get("id", "")))
	return ids

func _build_track_runtime(track_id: String) -> Dictionary:
	var definition := TrackCatalog.get_definition(track_id)
	assert_true(definition != null, "%s definition should load" % track_id)
	if definition != null:
		assert_equal(definition.track_source_id, "road_grid_map", "%s should resolve as RoadGridMap" % track_id)
		assert_equal(definition.road_visual_style, "kenney_gridmap", "%s should use GridMap road visuals" % track_id)
		assert_equal(definition.validate(), [], "%s definition should validate before driveability tests" % track_id)
	var built := TrackRuntimeBuilder.build(definition)
	return {
		"definition": definition,
		"track": built.get("node", null),
	}

func _spawn_probe_kart(transform: Transform3D) -> CharacterBody3D:
	var packed := load(CAR_SCENE) as PackedScene
	assert_true(packed != null, "Car scene should load for GridMap driveability probe")
	var car := packed.instantiate() as CharacterBody3D
	car.set("controlled_locally", true)
	car.set("visual_animation_enabled", false)
	car.set("acceleration", TEST_PROBE_ACCELERATION)
	car.set("max_speed", TEST_PROBE_MAX_SPEED)
	car.set("steer_speed", TEST_PROBE_STEER_SPEED)
	car.global_transform = transform
	scene_tree.root.add_child(car)
	return car

func _simulate_kart(car: CharacterBody3D, frames: int, input_state: Dictionary, initial_velocity := Vector3.ZERO) -> void:
	car.velocity = initial_velocity
	if car.has_method("set_input"):
		car.call("set_input", input_state)
	for _i in range(frames):
		await scene_tree.physics_frame
	if car.has_method("set_input"):
		car.call("set_input", {"throttle": 0.0, "brake": 1.0, "steer": 0.0, "drift": false, "boost": false, "item_use": false})

func _route_transform_for_index(track: Node3D, definition, route_index: int, yaw_offset_degrees: float) -> Transform3D:
	var route: Array[Vector3] = definition.route_points
	var index := clampi(route_index, 0, route.size() - 1)
	var next := route[(index + 1) % route.size()]
	var current := route[index]
	var sampled := current.lerp(next, 0.1)
	var direction := next - current
	direction.y = 0.0
	if direction.length_squared() <= 0.001:
		direction = Vector3.FORWARD
	direction = direction.normalized()
	var yaw := atan2(direction.x, direction.z) + deg_to_rad(yaw_offset_degrees)
	var surface := _road_surface_at(track, sampled)
	return Transform3D(Basis(Vector3.UP, yaw), surface + Vector3.UP * 1.0)

func _inside_edge_transform(track: Node3D, segment: Dictionary, yaw_offset_degrees: float) -> Transform3D:
	var a := segment.get("a", Vector3.ZERO) as Vector3
	var b := segment.get("b", Vector3.ZERO) as Vector3
	var outward := (segment.get("outward", Vector3.FORWARD) as Vector3).normalized()
	var mid := (a + b) * 0.5
	var inside := mid - outward * 2.6
	var surface := _road_surface_at(track, inside)
	var yaw := atan2(outward.x, outward.z) + deg_to_rad(yaw_offset_degrees)
	return Transform3D(Basis(Vector3.UP, yaw), surface + Vector3.UP * 1.0)

func _representative_boundary_segments(track: Node3D, definition, max_count: int) -> Array[Dictionary]:
	var all_segments := TrackGridRoadBuilder.boundary_wall_segments_from_grid_layout(definition.road_grid_layout, definition.wall_height, definition.wall_thickness)
	var selected: Array[Dictionary] = []
	var seen_items := {}
	for segment in all_segments:
		var data := segment as Dictionary
		if not _edge_case_starts_on_road(track, data):
			continue
		var item := int(data.get("item", -1))
		if seen_items.has(item):
			continue
		seen_items[item] = true
		selected.append(data)
		if selected.size() >= max_count:
			return selected
	for segment in all_segments:
		if selected.size() >= max_count:
			break
		if not _edge_case_starts_on_road(track, segment as Dictionary):
			continue
		selected.append(segment as Dictionary)
	return selected

func _edge_case_starts_on_road(track: Node3D, segment: Dictionary) -> bool:
	var a := segment.get("a", Vector3.ZERO) as Vector3
	var b := segment.get("b", Vector3.ZERO) as Vector3
	var outward := (segment.get("outward", Vector3.FORWARD) as Vector3).normalized()
	var inside := ((a + b) * 0.5) - outward * 2.6
	return not _road_surface_hit_at(track, inside).is_empty()

func _road_surface_at(track: Node3D, point: Vector3) -> Vector3:
	var hit := _road_surface_hit_near(track, point)
	if hit.is_empty():
		return point
	return hit.get("position", point) as Vector3

func _road_surface_hit_at(track: Node3D, point: Vector3) -> Dictionary:
	var road_body := track.get_node_or_null("Road/CollisionBody") as StaticBody3D
	var space := track.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(point + Vector3.UP * 48.0, point + Vector3.DOWN * 96.0, 1)
	query.collide_with_areas = false
	query.exclude = _boundary_wall_rids(track)
	var hit := space.intersect_ray(query)
	if hit.is_empty() or hit.get("collider", null) != road_body:
		return {}
	return hit

func _road_surface_hit_near(track: Node3D, point: Vector3) -> Dictionary:
	var hit := _road_surface_hit_at(track, point)
	if not hit.is_empty():
		return hit
	for offset in _tiny_centerline_offsets():
		hit = _road_surface_hit_at(track, point + offset)
		if not hit.is_empty():
			return hit
	return {}

func _ray_hits_road_near(track: Node3D, from: Vector3, distance: float) -> bool:
	if _ray_hits_road(track, from, distance):
		return true
	for offset in _tiny_centerline_offsets():
		if _ray_hits_road(track, from + offset, distance):
			return true
	return false

func _ray_hits_road(track: Node3D, from: Vector3, distance: float) -> bool:
	var road_body := track.get_node_or_null("Road/CollisionBody") as StaticBody3D
	var space := track.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * distance, 1)
	query.collide_with_areas = false
	query.exclude = _boundary_wall_rids(track)
	var hit := space.intersect_ray(query)
	return not hit.is_empty() and hit.get("collider", null) == road_body

func _tiny_centerline_offsets() -> Array[Vector3]:
	return [
		Vector3(0.35, 0.0, 0.0),
		Vector3(-0.35, 0.0, 0.0),
		Vector3(0.0, 0.0, 0.35),
		Vector3(0.0, 0.0, -0.35),
	]

func _boundary_wall_rids(track: Node3D) -> Array[RID]:
	var out: Array[RID] = []
	var walls := track.get_node_or_null("BoundaryWalls")
	if walls == null:
		return out
	for child in walls.get_children():
		if child is CollisionObject3D:
			out.append((child as CollisionObject3D).get_rid())
	return out

func _signed_edge_distance(point: Vector3, segment: Dictionary) -> float:
	var a := segment.get("a", Vector3.ZERO) as Vector3
	var b := segment.get("b", Vector3.ZERO) as Vector3
	var outward := (segment.get("outward", Vector3.FORWARD) as Vector3).normalized()
	var mid := (a + b) * 0.5
	return (point - mid).dot(outward)

func _settle_physics(frames := 3) -> void:
	for _i in range(frames):
		await scene_tree.physics_frame
