extends "res://tests/framework/TestCase.gd"

const TrackCatalog = preload("res://scripts/track/TrackCatalog.gd")
const TrackRuntimeBuilder = preload("res://scripts/track/TrackRuntimeBuilder.gd")
const TrackSceneAuthoringData = preload("res://scripts/track/TrackSceneAuthoringData.gd")
const RaceController = preload("res://scripts/RaceController.gd")
const OutOfBoundsRules = preload("res://scripts/logic/OutOfBoundsRules.gd")

const ACTIVE_TRACK_IDS := [
	"kitchen",
	"bedroom",
	"sandbox",
	"garden",
	"glam_closet",
	"outdoor_playground",
	"playroom",
	"attic",
]
const BACKYARD_TRACK_IDS := ["sandbox", "garden", "outdoor_playground"]
const SIGNATURE_EFFECTS := {
	"kitchen": "SinkSplashZone",
	"bedroom": "LampBeaconZone",
	"sandbox": "SandBurstZone",
	"garden": "HoseSplashZone",
	"glam_closet": "PerfumeMistZone",
	"outdoor_playground": "SwingGateEffect",
	"playroom": "MarbleMachineEffect",
	"attic": "PrankTriggerZone",
}
const OUTDOOR_GRASS_SHADER := "res://assets/gameplay/materials/grass/playground_grass.gdshader"
const OUTDOOR_GRASS_BLADE_SHADER := "res://assets/gameplay/materials/grass/playground_grass_blades.gdshader"

func test_toybox_track_scenes_load_with_runtime_nodes() -> void:
	for track_id in ACTIVE_TRACK_IDS:
		var packed := load(TrackCatalog.get_scene_path(track_id))
		assert_true(packed is PackedScene, "%s track scene should load" % track_id)
		var instance := (packed as PackedScene).instantiate()
		scene_tree.root.add_child(instance)
		var built_track := instance.get_node_or_null("BuiltTrack")
		assert_true(built_track != null, "%s track scene should build runtime track" % track_id)
		assert_true(instance.get_node_or_null("BuiltTrack/Road") != null, "%s track should include generated road" % track_id)
		assert_true(instance.get_node_or_null("BuiltTrack/TrackBody") != null, "%s track should include a raised visual track body" % track_id)
		assert_true(instance.get_node_or_null("BuiltTrack/Rails") != null, "%s track should include generated route rails" % track_id)
		assert_true(instance.get_node_or_null("BuiltTrack/CheckpointSystem") != null, "%s track should include checkpoint system" % track_id)
		assert_true(instance.get_node_or_null("BuiltTrack/SpawnPoints") != null, "%s track should include spawn points" % track_id)
		assert_true(instance.get_node_or_null("BuiltTrack/ItemSockets") != null, "%s track should include item sockets" % track_id)
		assert_true(instance.get_node_or_null("BuiltTrack/HazardSockets") != null, "%s track should include hazard sockets" % track_id)
		assert_true(instance.get_node_or_null("BuiltTrack/ShortcutGates") != null, "%s track should include shortcut gates" % track_id)
		assert_true(instance.get_node_or_null("BuiltTrack/SurfaceSegments") != null, "%s track should include surface segment markers" % track_id)
		assert_true(instance.get_node_or_null("BuiltTrack/AudioZones/%s" % SIGNATURE_EFFECTS[track_id]) != null, "%s track should include its signature effect audio zone" % track_id)
		assert_true(instance.get_node_or_null("BuiltTrack/Dressing/EditableRoom") != null, "%s track should include the editable room scene" % track_id)
		assert_true(instance.get_node_or_null("BuiltTrack/Dressing/EditableRoom/RoutePoints/RoutePoint00") != null, "%s editable room should expose route points" % track_id)
		assert_true(instance.get_node_or_null("BuiltTrack/Dressing/EditableRoom/SpawnPoints/Start01") != null, "%s editable room should expose spawn points" % track_id)
		assert_true(instance.get_node_or_null("BuiltTrack/Dressing/EditableRoom/SignatureEffects/%s" % SIGNATURE_EFFECTS[track_id]) != null, "%s editable room should expose its signature effect hook" % track_id)
		assert_equal(_enabled_collision_objects(instance.get_node_or_null("BuiltTrack/Dressing/EditableRoom")), 0, "%s editable dressing should not collide with the kart" % track_id)
		if BACKYARD_TRACK_IDS.has(track_id):
			assert_true(instance.get_node_or_null("BuiltTrack/Dressing/EditableRoom/SharedBackyardBase") != null, "%s should include shared backyard dressing" % track_id)
			assert_true(instance.get_node_or_null("BuiltTrack/Dressing/EditableRoom/SharedBackyardBase/VisibleCourseTerritories/SandboxTerritory") != null, "%s should show sandbox territory" % track_id)
			assert_true(instance.get_node_or_null("BuiltTrack/Dressing/EditableRoom/SharedBackyardBase/VisibleCourseTerritories/GardenTerritory") != null, "%s should show garden territory" % track_id)
			assert_true(instance.get_node_or_null("BuiltTrack/Dressing/EditableRoom/SharedBackyardBase/VisibleCourseTerritories/PlaygroundTerritory") != null, "%s should show playground territory" % track_id)
			assert_true(instance.get_node_or_null("BuiltTrack/Dressing/EditableRoom/SharedBackyardBase/RoutePoints") == null, "%s shared backyard base should not contain active route markers" % track_id)
		instance.queue_free()

func test_toybox_authoring_scenes_build_editor_preview() -> void:
	for track_id in ACTIVE_TRACK_IDS:
		var definition = TrackCatalog.get_definition(track_id)
		var packed := load(definition.dressing_scene_path)
		assert_true(packed is PackedScene, "%s authoring scene should load" % track_id)
		var instance := (packed as PackedScene).instantiate()
		scene_tree.root.add_child(instance)
		assert_true(instance.has_method("refresh_preview"), "%s authoring root should expose preview refresh" % track_id)
		assert_true(instance.has_method("sync_markers_from_definition"), "%s authoring root should expose marker sync" % track_id)
		assert_true(instance.has_method("apply_markers_to_definition"), "%s authoring root should expose definition export" % track_id)
		assert_true(instance.has_method("export_metadata"), "%s authoring root should expose metadata export" % track_id)
		assert_true(instance.has_method("validate_authoring"), "%s authoring root should expose authoring validation" % track_id)
		var summary := instance.call("get_authoring_summary") as Dictionary
		assert_true(int(summary.get("route_points", 0)) >= 9, "%s builder should report editable route points" % track_id)
		assert_equal(int(summary.get("spawn_points", 0)), 8, "%s builder should report editable spawn points" % track_id)
		assert_equal(int(summary.get("checkpoints", 0)), 6, "%s builder should report editable checkpoints" % track_id)
		assert_true(int(summary.get("dressing_props", 0)) >= 6, "%s builder should report selectable editable dressing props" % track_id)
		assert_equal(int(summary.get("surface_segments", 0)), 3, "%s builder should report editable surface segments" % track_id)
		assert_equal(int(summary.get("audio_zones", 0)), 3, "%s builder should report editable audio zones" % track_id)
		assert_equal((instance.call("validate_authoring") as Array).size(), 0, "%s authoring markers should validate against track rules" % track_id)
		instance.set("preview_enabled", true)
		instance.call("refresh_preview")
		assert_true(instance.get_node_or_null("EditorTrackPreview/PreviewTrackBody") != null, "%s authoring preview should include the raised track body" % track_id)
		assert_true(instance.get_node_or_null("EditorTrackPreview/PreviewRoad") != null, "%s authoring preview should include generated road" % track_id)
		assert_true(instance.get_node_or_null("EditorTrackPreview/PreviewRails") != null, "%s authoring preview should include generated rails" % track_id)
		instance.queue_free()

func test_backyard_runtime_uses_grass_shader_and_visible_shared_base() -> void:
	for track_id in BACKYARD_TRACK_IDS:
		var definition := TrackSceneAuthoringData.apply_to_definition(TrackCatalog.get_definition(track_id))
		assert_true(definition != null, "%s definition should load" % track_id)
		var built := TrackRuntimeBuilder.build(definition)
		var track_node := built.get("node", null) as Node3D
		scene_tree.root.add_child(track_node)
		assert_true(definition.grass_zones.size() >= 2, "%s should use authored grass zones" % track_id)
		assert_equal(_mesh_shader_path(track_node, "FloorVisual"), OUTDOOR_GRASS_SHADER, "%s generated floor should use the grass shader" % track_id)
		assert_equal(_mesh_shader_path(track_node, "Dressing/EditableRoom/floor/MeshInstance3D"), OUTDOOR_GRASS_SHADER, "%s editable floor should use the grass shader at runtime" % track_id)
		assert_true(track_node.get_node_or_null("PlaygroundGrassBlades") is MultiMeshInstance3D, "%s should build an upright grass blade layer" % track_id)
		assert_true(_multimesh_instance_count(track_node, "PlaygroundGrassBlades") >= 18000, "%s grass should use enough blades to read from kart height" % track_id)
		assert_equal(_multimesh_shader_path(track_node, "PlaygroundGrassBlades"), OUTDOOR_GRASS_BLADE_SHADER, "%s grass blades should use the blade sway shader" % track_id)
		assert_true(_multimesh_instances_inside_grass_zones(track_node, "PlaygroundGrassBlades", definition.grass_zones, 300), "%s grass blades should be scattered inside authored grass zones" % track_id)
		track_node.queue_free()

func test_car_can_be_placed_on_toybox_start_grids() -> void:
	var car_scene := load("res://scenes/Car.tscn")
	assert_true(car_scene is PackedScene, "Car scene should load")
	for track_id in ACTIVE_TRACK_IDS:
		var definition := TrackCatalog.get_definition(track_id)
		var built := TrackRuntimeBuilder.build(definition)
		var track_node := built.get("node", null) as Node3D
		scene_tree.root.add_child(track_node)
		var spawns: Array = built.get("spawns", [])
		var route_points: Array[Vector3] = []
		for point in built.get("waypoints", definition.route_points):
			if point is Vector3:
				route_points.append(point)
		assert_true(spawns.size() >= 8, "%s builder should return 8 spawn transforms" % track_id)
		for spawn in spawns:
			if spawn is Transform3D:
				var distance := _distance_to_route_xz((spawn as Transform3D).origin, route_points, definition.closed_loop)
				assert_true(distance <= definition.road_width * 0.5 + 0.1, "%s start grid should place every spawn on the road" % track_id)
		var car := (car_scene as PackedScene).instantiate() as Node3D
		scene_tree.root.add_child(car)
		car.global_transform = spawns[0]
		assert_true(car.global_transform.origin.distance_to((spawns[0] as Transform3D).origin) < 0.01, "%s car should be placeable on the start grid" % track_id)
		car.queue_free()
		track_node.queue_free()

func test_out_of_bounds_instant_pop_reset() -> void:
	var definition := TrackCatalog.get_definition("kitchen")
	assert_true(not OutOfBoundsRules.should_reset(-10.0, definition.out_of_bounds_y, definition.reset_mode), "Driving on the authored floor should not auto-reset")
	assert_true(OutOfBoundsRules.should_reset(definition.out_of_bounds_y - 0.5, definition.out_of_bounds_y, definition.reset_mode), "Falling below the floor should trigger reset")
	var car_scene := load("res://scenes/Car.tscn")
	assert_true(car_scene is PackedScene, "Car scene should load")
	var car := (car_scene as PackedScene).instantiate() as CharacterBody3D
	scene_tree.root.add_child(car)
	car.global_transform.origin = Vector3(0, 0.2, 0)
	car.velocity = Vector3(4, -8, 2)
	var reset_transform := Transform3D(Basis(Vector3.UP, deg_to_rad(90.0)), Vector3(-82, 3.8, -79))
	RaceController.apply_instant_reset(car, reset_transform)
	assert_equal(car.global_transform.origin, reset_transform.origin, "Instant pop reset should move the car back to the safe transform")
	assert_equal(car.velocity, Vector3.ZERO, "Instant pop reset should stop the car")
	car.queue_free()

func test_manual_return_uses_last_road_center_point() -> void:
	var definition := TrackCatalog.get_definition("kitchen")
	var off_course_position := definition.route_points[3] + Vector3(18.0, 0.0, 0.0)
	var reset_transform := RaceController.centered_track_return_transform(definition.route_points, off_course_position, definition.closed_loop)
	var distance := _distance_to_route_xz(reset_transform.origin, definition.route_points, definition.closed_loop)
	assert_true(distance <= 0.01, "Manual return transform should land on the route centerline")
	assert_true(reset_transform.origin.y >= _route_min_y(definition.route_points) + 0.8, "Manual return transform should preserve kart clearance above the route")
	assert_true(reset_transform.origin.y <= _route_max_y(definition.route_points) + 1.2, "Manual return transform should not lift the kart above the authored route envelope")

func _distance_to_route_xz(point: Vector3, route_points: Array[Vector3], closed_loop: bool) -> float:
	var best := INF
	var segment_count := route_points.size() if closed_loop else route_points.size() - 1
	for i in range(segment_count):
		best = minf(best, _distance_to_segment_xz(point, route_points[i], route_points[(i + 1) % route_points.size()]))
	return best

func _distance_to_segment_xz(point: Vector3, a3: Vector3, b3: Vector3) -> float:
	var point_2d := Vector2(point.x, point.z)
	var a := Vector2(a3.x, a3.z)
	var b := Vector2(b3.x, b3.z)
	var ab := b - a
	var length_squared := ab.length_squared()
	if length_squared <= 0.0001:
		return point_2d.distance_to(a)
	var t := clampf((point_2d - a).dot(ab) / length_squared, 0.0, 1.0)
	return point_2d.distance_to(a + ab * t)

func _route_min_y(route_points: Array[Vector3]) -> float:
	var min_y := INF
	for point in route_points:
		min_y = minf(min_y, point.y)
	return min_y

func _route_max_y(route_points: Array[Vector3]) -> float:
	var max_y := -INF
	for point in route_points:
		max_y = maxf(max_y, point.y)
	return max_y

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

func _mesh_shader_path(root: Node, path: NodePath) -> String:
	var mesh := root.get_node_or_null(path) as MeshInstance3D
	if mesh == null:
		return ""
	if mesh.material_override is ShaderMaterial:
		var material := mesh.material_override as ShaderMaterial
		if material.shader != null:
			return material.shader.resource_path
	return ""

func _multimesh_instance_count(root: Node, path: NodePath) -> int:
	var instance := root.get_node_or_null(path) as MultiMeshInstance3D
	if instance == null or instance.multimesh == null:
		return 0
	return instance.multimesh.instance_count

func _multimesh_shader_path(root: Node, path: NodePath) -> String:
	var instance := root.get_node_or_null(path) as MultiMeshInstance3D
	if instance == null or instance.multimesh == null or instance.multimesh.mesh == null:
		return ""
	var material := instance.multimesh.mesh.surface_get_material(0)
	if material is ShaderMaterial:
		var shader_material := material as ShaderMaterial
		if shader_material.shader != null:
			return shader_material.shader.resource_path
	return ""

func _multimesh_instances_inside_grass_zones(root: Node, path: NodePath, zones: Array[Dictionary], sample_count: int) -> bool:
	var instance := root.get_node_or_null(path) as MultiMeshInstance3D
	if instance == null or instance.multimesh == null:
		return false
	var sample_positions := instance.get_meta("scatter_sample_positions", []) as Array
	if not sample_positions.is_empty():
		var metadata_count := mini(sample_count, sample_positions.size())
		for i in range(metadata_count):
			var position_value: Variant = sample_positions[i]
			if not (position_value is Vector3):
				return false
			if not _point_inside_any_grass_zone(position_value as Vector3, zones):
				return false
		return true
	var count := mini(sample_count, instance.multimesh.instance_count)
	for i in range(count):
		var position := instance.multimesh.get_instance_transform(i).origin
		if not _point_inside_any_grass_zone(position, zones):
			return false
	return true

func _point_inside_any_grass_zone(point: Vector3, zones: Array[Dictionary]) -> bool:
	for zone in zones:
		if not bool(zone.get("enabled", true)):
			continue
		var center := _point_from_value(zone.get("position", Vector3.ZERO))
		var size := _vector2_from_value(zone.get("size", Vector2.ZERO))
		var yaw := deg_to_rad(float(zone.get("yaw_degrees", 0.0)))
		var local := Basis(Vector3.UP, -yaw) * (point - center)
		if absf(local.x) <= size.x * 0.5 + 0.01 and absf(local.z) <= size.y * 0.5 + 0.01:
			return true
	return false

func _point_from_value(value: Variant) -> Vector3:
	if value is Vector3:
		return value
	if value is Array and value.size() >= 3:
		return Vector3(float(value[0]), float(value[1]), float(value[2]))
	return Vector3.ZERO

func _vector2_from_value(value: Variant) -> Vector2:
	if value is Vector2:
		return value
	if value is Array and value.size() >= 2:
		return Vector2(float(value[0]), float(value[1]))
	return Vector2.ZERO
