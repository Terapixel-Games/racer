extends "res://tests/framework/TestCase.gd"

const TrackRuntimeBuilder = preload("res://scripts/track/TrackRuntimeBuilder.gd")
const TrackGridRoadBuilder = preload("res://scripts/track/TrackGridRoadBuilder.gd")
const LAB_SCENE := "res://tests/scenarios/GridMapBoundaryWallLab.tscn"
const CAR_SCENE := "res://scenes/Car.tscn"
const TEST_PROBE_ACCELERATION := 180.0
const TEST_PROBE_MAX_SPEED := 96.0
const TEST_PROBE_STEER_SPEED := 5.5

func test_wall_lab_builds_invisible_boundary_walls_without_rails() -> void:
	var context := _build_wall_lab_runtime(false)
	var track := context.get("track", null) as Node3D
	scene_tree.root.add_child(track)
	await _settle_physics()

	assert_true(track.get_node_or_null("GridRoad") != null, "Wall lab should build GridMap road visuals")
	assert_equal(_enabled_collision_objects(track.get_node_or_null("GridRoad")), 0, "GridRoad visuals should remain collision-free")
	assert_true(track.get_node_or_null("Rails") == null, "Wall lab should not build rail containment")
	var road_shape := track.get_node_or_null("Road/CollisionBody/CollisionShape3D") as CollisionShape3D
	assert_true(road_shape != null and road_shape.shape is ConcavePolygonShape3D, "Wall lab should keep the hidden generated Road collider")
	if road_shape != null and road_shape.shape is ConcavePolygonShape3D:
		assert_true((road_shape.shape as ConcavePolygonShape3D).backface_collision, "Hidden Road collider should remain backface-collidable")
	var boundary_walls := track.get_node_or_null("BoundaryWalls")
	assert_true(boundary_walls != null, "Wall lab should build BoundaryWalls")
	assert_true(_enabled_collision_objects(boundary_walls) > 0, "BoundaryWalls should have enabled collision")
	assert_true(_boundary_walls_use_car_only_layer(boundary_walls), "BoundaryWalls should collide with karts without acting as camera occluders")
	assert_equal(_mesh_instance_count(boundary_walls), 0, "BoundaryWalls should not render meshes by default")
	track.queue_free()

func test_wall_lab_debug_boundary_walls_are_transparent_meshes_when_enabled() -> void:
	var context := _build_wall_lab_runtime(true)
	var track := context.get("track", null) as Node3D
	scene_tree.root.add_child(track)
	await _settle_physics()

	var boundary_walls := track.get_node_or_null("BoundaryWalls")
	assert_true(boundary_walls != null, "Debug wall lab should build BoundaryWalls")
	assert_true(_enabled_collision_objects(boundary_walls) > 0, "Debug boundary walls should keep collision")
	assert_true(_boundary_walls_use_car_only_layer(boundary_walls), "Debug boundary walls should keep car-only collision layers")
	assert_true(_mesh_instance_count(boundary_walls) > 0, "Debug boundary walls should render transparent meshes")
	assert_true(_first_mesh_alpha(boundary_walls) < 1.0, "Debug boundary meshes should be transparent")
	track.queue_free()

func test_wall_lab_player_kart_crosses_valid_gridmap_connections() -> void:
	var context := _build_wall_lab_runtime(false)
	var track := context.get("track", null) as Node3D
	var definition = context.get("definition", null)
	scene_tree.root.add_child(track)
	await _settle_physics()

	for route_index in [1, 4, 5, 6, 9, 10]:
		var transform := _route_transform_for_index(track, definition, route_index, 0.0)
		var car := _spawn_probe_kart(transform)
		await _settle_physics(12)
		var start := car.global_position
		await _simulate_kart(car, 58, {"throttle": 1.0, "brake": 0.0, "steer": 0.0, "drift": false, "boost": false, "item_use": false}, transform.basis.z * 12.0)
		await _settle_physics()
		var traveled := Vector2(car.global_position.x - start.x, car.global_position.z - start.z).length()
		assert_true(traveled > 5.0, "Probe kart should cross route seam %d without an invisible blocker" % route_index)
		assert_true(car.global_position.y > float(definition.out_of_bounds_y), "Probe kart should stay above out-of-bounds while crossing route seam %d" % route_index)
		assert_true(_ray_hits_road(track, car.global_position + Vector3.UP * 8.0, 20.0), "Probe kart should remain over road collision after route seam %d" % route_index)
		car.queue_free()
		await _settle_physics(2)
	track.queue_free()

func test_wall_lab_boundary_walls_do_not_occlude_follow_camera() -> void:
	var context := _build_wall_lab_runtime(false)
	var track := context.get("track", null) as Node3D
	var definition = context.get("definition", null)
	scene_tree.root.add_child(track)
	await _settle_physics()

	var cases := _representative_boundary_segments(track, definition, 3)
	assert_true(cases.size() >= 3, "Wall lab should expose representative camera clearance cases")
	var space_state := track.get_world_3d().direct_space_state
	for segment in cases:
		var transform := _inside_edge_transform(track, segment as Dictionary, 0.0)
		var look_target := transform.origin + Vector3.UP * 0.8
		var desired := transform.origin + (-transform.basis.z * 3.75) + Vector3.UP * 1.35
		var query := PhysicsRayQueryParameters3D.create(look_target, desired, 1)
		query.collide_with_areas = false
		query.collide_with_bodies = true
		var result := space_state.intersect_ray(query)
		assert_true(not _ray_result_is_boundary_wall(track, result), "Boundary wall should not be on the camera occlusion layer")
	track.queue_free()

func test_wall_lab_player_kart_cannot_escape_exposed_edges_at_angles_and_speeds() -> void:
	var context := _build_wall_lab_runtime(false)
	var track := context.get("track", null) as Node3D
	var definition = context.get("definition", null)
	scene_tree.root.add_child(track)
	await _settle_physics()

	var cases := _representative_boundary_segments(track, definition, 4)
	assert_true(cases.size() >= 3, "Wall lab should expose representative flat and ramp boundary segments")
	for case_index in range(cases.size()):
		var segment := cases[case_index] as Dictionary
		for angle in [-35.0, 0.0, 35.0]:
			for speed in [10.0, 24.0, 40.0]:
				var transform := _inside_edge_transform(track, segment, angle)
				var car := _spawn_probe_kart(transform)
				await _settle_physics(10)
				var direction := transform.basis.z.normalized()
				await _simulate_kart(car, 48, {"throttle": 1.0, "brake": 0.0, "steer": 0.0, "drift": false, "boost": false, "item_use": false}, direction * speed)
				await _settle_physics()
				var signed_distance := _signed_edge_distance(car.global_position, segment)
				assert_true(signed_distance <= 1.4, "Boundary wall should contain kart at case %d angle %.1f speed %.1f" % [case_index, angle, speed])
				assert_true(car.global_position.y > float(definition.out_of_bounds_y), "Boundary wall should keep kart in scene at case %d angle %.1f speed %.1f" % [case_index, angle, speed])
				car.queue_free()
				await _settle_physics(2)
	track.queue_free()

func test_wall_lab_walls_do_not_block_grade_separated_routes() -> void:
	var context := _build_wall_lab_runtime(false)
	var track := context.get("track", null) as Node3D
	var definition = context.get("definition", null)
	scene_tree.root.add_child(track)
	await _settle_physics()

	for route_index in [5, 6, 9, 10]:
		var transform := _route_transform_for_index(track, definition, route_index, 0.0)
		var car := _spawn_probe_kart(transform)
		await _settle_physics(12)
		var start := car.global_position
		await _simulate_kart(car, 64, {"throttle": 1.0, "brake": 0.0, "steer": 0.0, "drift": false, "boost": false, "item_use": false}, transform.basis.z * 14.0)
		await _settle_physics()
		var traveled := Vector2(car.global_position.x - start.x, car.global_position.z - start.z).length()
		assert_true(traveled > 5.0, "Grade-separated route index %d should remain open for valid driving" % route_index)
		assert_true(car.global_position.y > float(definition.out_of_bounds_y), "Grade-separated route index %d should not eject the kart below the scene" % route_index)
		car.queue_free()
		await _settle_physics(2)
	track.queue_free()

func _build_wall_lab_runtime(debug_walls: bool) -> Dictionary:
	var packed := load(LAB_SCENE) as PackedScene
	assert_true(packed != null, "GridMap wall lab scene should load")
	var lab := packed.instantiate()
	var definition = lab.call("make_definition", debug_walls)
	lab.queue_free()
	var built := TrackRuntimeBuilder.build(definition)
	return {
		"definition": definition,
		"track": built.get("node", null),
	}

func _spawn_probe_kart(transform: Transform3D) -> CharacterBody3D:
	var packed := load(CAR_SCENE) as PackedScene
	assert_true(packed != null, "Car scene should load for wall probe")
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
	var direction := next - current
	direction.y = 0.0
	if direction.length_squared() <= 0.001:
		direction = Vector3.FORWARD
	direction = direction.normalized()
	var yaw := atan2(direction.x, direction.z) + deg_to_rad(yaw_offset_degrees)
	var surface := _road_surface_at(track, current)
	return Transform3D(Basis(Vector3.UP, yaw), surface + Vector3.UP * 1.0)

func _inside_edge_transform(track: Node3D, segment: Dictionary, yaw_offset_degrees: float) -> Transform3D:
	var a := segment.get("a", Vector3.ZERO) as Vector3
	var b := segment.get("b", Vector3.ZERO) as Vector3
	var outward := (segment.get("outward", Vector3.FORWARD) as Vector3).normalized()
	var mid := (a + b) * 0.5
	var inside := mid - outward * 2.4
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
	var inside := ((a + b) * 0.5) - outward * 2.4
	return not _road_surface_hit_at(track, inside).is_empty()

func _road_surface_at(track: Node3D, point: Vector3) -> Vector3:
	var hit := _road_surface_hit_at(track, point)
	if hit.is_empty():
		return point
	return hit.get("position", point) as Vector3

func _road_surface_hit_at(track: Node3D, point: Vector3) -> Dictionary:
	var space := track.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(point + Vector3.UP * 24.0, point + Vector3.DOWN * 40.0, 1)
	query.collide_with_areas = false
	query.exclude = _boundary_wall_rids(track)
	var hit := space.intersect_ray(query)
	var road_body := track.get_node_or_null("Road/CollisionBody") as StaticBody3D
	if hit.is_empty() or hit.get("collider", null) != road_body:
		return {}
	return hit

func _ray_hits_road(track: Node3D, from: Vector3, distance: float) -> bool:
	var road_body := track.get_node_or_null("Road/CollisionBody") as StaticBody3D
	var space := track.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * distance, 1)
	query.collide_with_areas = false
	query.exclude = _boundary_wall_rids(track)
	var hit := space.intersect_ray(query)
	return not hit.is_empty() and hit.get("collider", null) == road_body

func _boundary_wall_rids(track: Node3D) -> Array[RID]:
	var out: Array[RID] = []
	var walls := track.get_node_or_null("BoundaryWalls")
	if walls == null:
		return out
	for child in walls.get_children():
		if child is CollisionObject3D:
			out.append((child as CollisionObject3D).get_rid())
	return out

func _ray_result_is_boundary_wall(track: Node3D, result: Dictionary) -> bool:
	if not result.has("collider"):
		return false
	var collider := result.get("collider", null) as Node
	var walls := track.get_node_or_null("BoundaryWalls")
	return collider != null and walls != null and walls.is_ancestor_of(collider)

func _signed_edge_distance(point: Vector3, segment: Dictionary) -> float:
	var a := segment.get("a", Vector3.ZERO) as Vector3
	var b := segment.get("b", Vector3.ZERO) as Vector3
	var outward := (segment.get("outward", Vector3.FORWARD) as Vector3).normalized()
	var mid := (a + b) * 0.5
	return (point - mid).dot(outward)

func _settle_physics(frames := 3) -> void:
	for _i in range(frames):
		await scene_tree.physics_frame

func _enabled_collision_objects(node: Node) -> int:
	if node == null:
		return 0
	var count := 0
	if node is CollisionObject3D:
		var collision_object := node as CollisionObject3D
		if collision_object.collision_layer != 0 or collision_object.collision_mask != 0:
			count += 1
	if node is CollisionShape3D and not (node as CollisionShape3D).disabled:
		count += 1
	for child in node.get_children():
		count += _enabled_collision_objects(child)
	return count

func _boundary_walls_use_car_only_layer(node: Node) -> bool:
	if node == null:
		return false
	var found := false
	for child in node.find_children("*", "CollisionObject3D", true, false):
		var collision_object := child as CollisionObject3D
		if collision_object == null:
			continue
		if collision_object.collision_layer == 0 and collision_object.collision_mask == 0:
			continue
		found = true
		if collision_object.collision_layer != 2 or collision_object.collision_mask != 2:
			return false
	return found

func _mesh_instance_count(node: Node) -> int:
	if node == null:
		return 0
	var count := 1 if node is MeshInstance3D else 0
	for child in node.get_children():
		count += _mesh_instance_count(child)
	return count

func _first_mesh_alpha(node: Node) -> float:
	if node == null:
		return 1.0
	if node is MeshInstance3D:
		var mesh := node as MeshInstance3D
		if mesh.material_override is StandardMaterial3D:
			return (mesh.material_override as StandardMaterial3D).albedo_color.a
	for child in node.get_children():
		var alpha := _first_mesh_alpha(child)
		if alpha < 1.0:
			return alpha
	return 1.0
