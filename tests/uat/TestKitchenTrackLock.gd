extends "res://tests/framework/TestCase.gd"

const RaceScene = preload("res://scenes/Race.tscn")
const TrackCatalog = preload("res://scripts/track/TrackCatalog.gd")
const TrackSceneAuthoringData = preload("res://scripts/track/TrackSceneAuthoringData.gd")

const START_SUPPORT_MIN_Y_OFFSET := -1.5
const START_SUPPORT_MAX_Y_OFFSET := 6.0

func test_kitchen_runtime_uses_gridmap_wall_collision_contract() -> void:
	var package := TrackCatalog.get_package("kitchen")
	var packed := load(str(package.get("scene_path", ""))) as PackedScene
	assert_true(packed != null, "Kitchen track scene should load")
	if packed == null:
		return

	var instance := packed.instantiate()
	scene_tree.root.add_child(instance)
	await _settle_physics()

	var built_track := instance.get_node_or_null("BuiltTrack")
	assert_true(built_track != null, "Kitchen should build the runtime track package")
	assert_true(instance.get_node_or_null("BuiltTrack/TrackBody") == null, "Kitchen GridMap mode should not show the old broad track body")
	assert_true(instance.get_node_or_null("BuiltTrack/GridRoad") is GridMap, "Kitchen visible road should be the generated GridMap road")
	assert_equal(_enabled_collision_objects(instance.get_node_or_null("BuiltTrack/GridRoad")), 0, "GridRoad visuals should stay collision-free")
	assert_true(instance.get_node_or_null("BuiltTrack/Rails") == null, "Kitchen should not build rail containment")
	var boundary_walls := instance.get_node_or_null("BuiltTrack/BoundaryWalls")
	assert_true(boundary_walls != null, "Kitchen should build invisible boundary wall containment")
	assert_true(_enabled_collision_objects(boundary_walls) > 0, "Kitchen boundary walls should be collidable")
	assert_equal(_mesh_instance_count(boundary_walls), 0, "Kitchen boundary walls should not render debug meshes in normal runtime")

	var road_body := instance.get_node_or_null("BuiltTrack/Road/CollisionBody") as StaticBody3D
	var road_shape := instance.get_node_or_null("BuiltTrack/Road/CollisionBody/CollisionShape3D") as CollisionShape3D
	assert_true(road_body != null, "Kitchen should include the hidden Road collision body")
	if road_body != null:
		assert_equal(road_body.collision_layer, 1, "Hidden Road should collide on the world collision layer")
		assert_equal(road_body.collision_mask, 2, "Hidden Road should mask against karts")
	assert_true(road_shape != null and not road_shape.disabled, "Hidden Road collision shape should be enabled")
	if road_shape != null:
		assert_true(road_shape.shape is ConcavePolygonShape3D, "Hidden Road should use the generated concave road collision")
		if road_shape.shape is ConcavePolygonShape3D:
			assert_true((road_shape.shape as ConcavePolygonShape3D).backface_collision, "Hidden Road collision should support backface hits")

	var definition := TrackSceneAuthoringData.apply_to_definition(TrackCatalog.get_definition("kitchen"))
	assert_true(_route_samples_hit_road(instance, definition), "Representative Kitchen route samples should ray-hit the hidden Road collider")
	instance.queue_free()

func test_kitchen_local_race_starts_player_supported_by_track() -> void:
	NakamaService.set_meta_value("race_mode", "local_single")
	NakamaService.set_meta_value("race_match_id", "local-single-race")
	NakamaService.set_meta_value("track_id", "kitchen")
	NakamaService.set_meta_value("selected_racer_id", "Dash")

	var race := RaceScene.instantiate()
	scene_tree.root.add_child(race)
	await _settle_physics(8)

	var local_id := str(race.get("local_user_id"))
	var cars: Dictionary = race.get("cars")
	var car := cars.get(local_id, null) as CharacterBody3D
	assert_true(car != null, "Local Kitchen race should spawn a player kart")
	if car == null:
		race.queue_free()
		return

	var spawns: Array = race.get("spawn_points")
	assert_true(spawns.size() >= 8, "Kitchen local race should use the full fallback RoadGridMap start grid")
	var expected_spawn := spawns[0] as Transform3D
	assert_true(Vector2(car.global_position.x, car.global_position.z).distance_to(Vector2(expected_spawn.origin.x, expected_spawn.origin.z)) <= _kitchen_spawn_settle_radius(), "Player kart should start on the generated Kitchen route-start lane after physics settles")
	assert_true(car.global_position.y >= expected_spawn.origin.y + START_SUPPORT_MIN_Y_OFFSET, "Player kart should not fall through the Kitchen track at spawn")
	assert_true(car.global_position.y <= expected_spawn.origin.y + START_SUPPORT_MAX_Y_OFFSET, "Player kart should not float far above the Kitchen track at spawn")
	assert_true(_ray_hits_any_track_collision(race, car.global_position + Vector3.UP * 4.0, 12.0), "Player spawn should have enabled track collision beneath it")

	race.queue_free()

func _settle_physics(frames := 3) -> void:
	for _i in range(frames):
		await scene_tree.physics_frame

func _route_samples_hit_road(instance: Node, definition) -> bool:
	if definition == null:
		return false
	var route: Array[Vector3] = definition.route_points
	if route.is_empty():
		return false
	var road_body := instance.get_node_or_null("BuiltTrack/Road/CollisionBody") as StaticBody3D
	if road_body == null:
		return false
	var space := (instance as Node3D).get_world_3d().direct_space_state
	for index in _route_ray_sample_indices(route.size(), 12):
		var point := route[index]
		var query := PhysicsRayQueryParameters3D.create(point + Vector3.UP * 12.0, point + Vector3.DOWN * 12.0, 1)
		query.collide_with_areas = false
		var hit := space.intersect_ray(query)
		if hit.is_empty():
			return false
		if hit.get("collider", null) != road_body:
			return false
	return true

func _kitchen_spawn_settle_radius() -> float:
	var definition := TrackSceneAuthoringData.apply_to_definition(TrackCatalog.get_definition("kitchen"))
	if definition == null:
		return 4.0
	return maxf(4.0, float(definition.road_width) * 0.5 + 0.25)

func _route_ray_sample_indices(route_size: int, sample_count: int) -> Array[int]:
	var out: Array[int] = []
	if route_size <= 0:
		return out
	var count := mini(route_size, sample_count)
	for i in range(count):
		var index := clampi(roundi(float(i) * float(route_size - 1) / float(maxi(count - 1, 1))), 0, route_size - 1)
		if not out.has(index):
			out.append(index)
	return out

func _ray_hits_any_track_collision(root: Node, from: Vector3, distance: float) -> bool:
	var space := (root as Node3D).get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * distance, 1)
	query.collide_with_areas = false
	var hit := space.intersect_ray(query)
	return not hit.is_empty()

func _enabled_collision_objects(node: Node) -> int:
	if node == null:
		return 0
	var count := 0
	if node is CollisionObject3D:
		var collision_object := node as CollisionObject3D
		if collision_object.collision_layer != 0 or collision_object.collision_mask != 0:
			count += 1
	for child in node.get_children():
		count += _enabled_collision_objects(child)
	return count

func _mesh_instance_count(node: Node) -> int:
	if node == null:
		return 0
	var count := 1 if node is MeshInstance3D else 0
	for child in node.get_children():
		count += _mesh_instance_count(child)
	return count
