@tool
extends SceneTree

const TrackCatalog = preload("res://scripts/track/TrackCatalog.gd")
const TrackDefinition = preload("res://scripts/track/TrackDefinition.gd")
const TrackMetadataExporter = preload("res://scripts/track/TrackMetadataExporter.gd")
const TrackSceneAuthoringData = preload("res://scripts/track/TrackSceneAuthoringData.gd")
const RoadSegmentAuthoring = preload("res://scripts/track/RoadSegmentAuthoring.gd")

func _init() -> void:
	var scene_errors := false
	var scene_paths := _track_authoring_scene_paths()
	for path in scene_paths:
		var errors := _migrate_scene(path)
		if errors.is_empty():
			print("[RoadSegmentMigration] migrated %s" % path)
		else:
			scene_errors = true
			for error in errors:
				printerr("[RoadSegmentMigration] %s" % error)
	if not scene_errors:
		_export_track_definitions_and_metadata()
	quit()

func _track_authoring_scene_paths() -> Array[String]:
	var paths: Array[String] = []
	for summary in TrackCatalog.list_tracks():
		var definition := TrackCatalog.get_definition(str(summary.get("id", ""))) as TrackDefinition
		if definition == null:
			continue
		if not definition.dressing_scene_path.strip_edges().is_empty() and not paths.has(definition.dressing_scene_path):
			paths.append(definition.dressing_scene_path)
	var kitchen_authoring := "res://assets/gameplay/tracks/kitchen/kitchen_authoring.tscn"
	if ResourceLoader.exists(kitchen_authoring) and not paths.has(kitchen_authoring):
		paths.append(kitchen_authoring)
	return paths

func _export_track_definitions_and_metadata() -> void:
	for summary in TrackCatalog.list_tracks():
		var track_id := str(summary.get("id", ""))
		var package := TrackCatalog.get_package(track_id)
		var definition_path := str(package.get("definition_path", ""))
		if definition_path.is_empty():
			printerr("[RoadSegmentMigration] %s has no definition path" % track_id)
			continue
		var source := load(definition_path) as TrackDefinition
		if source == null:
			printerr("[RoadSegmentMigration] %s definition failed to load: %s" % [track_id, definition_path])
			continue
		var generated := TrackSceneAuthoringData.apply_to_definition(source)
		if generated == null:
			printerr("[RoadSegmentMigration] %s generated definition is null" % track_id)
			continue
		var validation := generated.validate()
		if not validation.is_empty():
			printerr("[RoadSegmentMigration] %s generated definition is invalid: %s" % [track_id, "; ".join(validation)])
			continue
		var save_error := ResourceSaver.save(generated, definition_path)
		if save_error != OK:
			printerr("[RoadSegmentMigration] failed to save %s definition: %s" % [track_id, save_error])
			continue
		var metadata_path := str(package.get("metadata_path", ""))
		if not metadata_path.is_empty():
			var metadata_error := TrackMetadataExporter.save_json(generated, metadata_path)
			if metadata_error != OK:
				printerr("[RoadSegmentMigration] failed to save %s metadata: %s" % [track_id, metadata_error])
				continue
		print("[RoadSegmentMigration] exported %s definition and metadata" % track_id)

func _migrate_scene(path: String) -> Array[String]:
	var errors: Array[String] = []
	var packed := load(path) as PackedScene
	if packed == null:
		return ["Could not load scene: %s" % path]
	var root := packed.instantiate() as Node3D
	if root == null:
		return ["Scene root is not Node3D: %s" % path]
	var route := _route_points(root)
	if route.size() < 2:
		root.queue_free()
		return ["Scene has fewer than two route points: %s" % path]
	var holder := root.get_node_or_null("RoadSegments") as Node3D
	if holder == null:
		holder = Node3D.new()
		holder.name = "RoadSegments"
		root.add_child(holder)
		holder.owner = root
	for child in holder.get_children():
		holder.remove_child(child)
		child.queue_free()
	var checkpoint_indices := _checkpoint_route_indices(root, route)
	var item_segments := _nearest_segment_indices(root, route, "ItemSockets")
	var hazard_segments := _nearest_segment_indices(root, route, "HazardSockets")
	var closed_loop := true
	var segment_count := route.size() if closed_loop else route.size() - 1
	for i in range(segment_count):
		var a := route[i]
		var b := route[(i + 1) % route.size()]
		var delta := b - a
		if delta.length() <= 0.1:
			continue
		var segment := RoadSegmentAuthoring.new()
		segment.name = "RoadSegment%03d" % i
		segment.segment_id = "ramp_long" if absf(delta.y / maxf(Vector2(delta.x, delta.z).length(), 0.001)) >= 0.08 else "straight_long"
		segment.segment_length = delta.length()
		segment.pitch_degrees = rad_to_deg(atan2(delta.y, Vector2(delta.x, delta.z).length()))
		segment.position = a.lerp(b, 0.5)
		segment.rotation_degrees.y = rad_to_deg(atan2(delta.x, delta.z))
		segment.preview_enabled = true
		var roles: Array[String] = []
		if checkpoint_indices.has(i):
			roles.append("checkpoint")
			if i == checkpoint_indices.front():
				roles.append("start")
		if item_segments.has(i):
			roles.append("item")
		if hazard_segments.has(i):
			roles.append("hazard")
		segment.role_tags = roles
		holder.add_child(segment)
		segment.owner = root
	var new_packed := PackedScene.new()
	var pack_error := new_packed.pack(root)
	if pack_error != OK:
		errors.append("Failed to pack %s: %s" % [path, pack_error])
	else:
		var save_error := ResourceSaver.save(new_packed, path)
		if save_error != OK:
			errors.append("Failed to save %s: %s" % [path, save_error])
	root.queue_free()
	return errors

func _route_points(root: Node3D) -> Array[Vector3]:
	var out: Array[Vector3] = []
	var holder := root.get_node_or_null("RoutePoints")
	if holder == null:
		return out
	for child in _sorted_node_children(holder):
		if child is Node3D:
			out.append(_root_space_position(root, child as Node3D))
	return out

func _checkpoint_route_indices(root: Node3D, route: Array[Vector3]) -> Array[int]:
	var indices: Array[int] = []
	var holder := root.get_node_or_null("Checkpoints")
	if holder == null:
		return indices
	for child in _sorted_node_children(holder):
		if child is Node3D:
			var index := _nearest_route_index(_root_space_position(root, child as Node3D), route)
			if index >= 0 and not indices.has(index):
				indices.append(index)
	indices.sort()
	return indices

func _nearest_segment_indices(root: Node3D, route: Array[Vector3], holder_name: String) -> Array[int]:
	var indices: Array[int] = []
	var holder := root.get_node_or_null(holder_name)
	if holder == null:
		return indices
	for child in _sorted_node_children(holder):
		if child is Node3D:
			var index := _nearest_segment_index(_root_space_position(root, child as Node3D), route)
			if index >= 0 and not indices.has(index):
				indices.append(index)
	indices.sort()
	return indices

func _nearest_segment_index(point: Vector3, route: Array[Vector3]) -> int:
	var best_index := -1
	var best_distance := INF
	for i in range(route.size()):
		var distance := _distance_to_segment_xz(point, route[i], route[(i + 1) % route.size()])
		if distance < best_distance:
			best_distance = distance
			best_index = i
	return best_index

func _nearest_route_index(point: Vector3, route: Array[Vector3]) -> int:
	var best_index := -1
	var best_distance := INF
	for i in range(route.size()):
		var distance := point.distance_squared_to(route[i])
		if distance < best_distance:
			best_distance = distance
			best_index = i
	return best_index

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

func _root_space_position(root: Node3D, node: Node3D) -> Vector3:
	return _root_space_transform(root, node).origin

func _root_space_transform(root: Node3D, node: Node3D) -> Transform3D:
	var transform := Transform3D.IDENTITY
	var current: Node = node
	while current != null and current != root:
		if current is Node3D:
			transform = (current as Node3D).transform * transform
		current = current.get_parent()
	return transform

func _sorted_node_children(source: Node) -> Array[Node]:
	var nodes: Array[Node] = []
	for child in source.get_children():
		nodes.append(child)
	nodes.sort_custom(func(a: Node, b: Node) -> bool:
		return str(a.name).naturalnocasecmp_to(str(b.name)) < 0
	)
	return nodes
