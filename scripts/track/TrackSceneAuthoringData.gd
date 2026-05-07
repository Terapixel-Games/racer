extends RefCounted
class_name TrackSceneAuthoringData

const TrackDefinition = preload("res://scripts/track/TrackDefinition.gd")
const TrackSegmentRoadBuilder = preload("res://scripts/track/TrackSegmentRoadBuilder.gd")
const TrackGridRoadBuilder = preload("res://scripts/track/TrackGridRoadBuilder.gd")

static func apply_to_definition(source: TrackDefinition) -> TrackDefinition:
	if source == null:
		return null
	var definition := source.duplicate(true) as TrackDefinition
	if definition.dressing_scene_path.strip_edges().is_empty():
		return definition
	var packed := load(definition.dressing_scene_path)
	if not (packed is PackedScene):
		return definition
	var scene_root := (packed as PackedScene).instantiate()
	if not (scene_root is Node3D):
		if scene_root != null:
			scene_root.queue_free()
		return definition
	_apply_scene_markers(definition, scene_root as Node3D)
	scene_root.queue_free()
	return definition

static func _apply_scene_markers(definition: TrackDefinition, scene_root: Node3D) -> void:
	var grid_layout := _collect_road_grid(scene_root, definition.road_width)
	if not grid_layout.is_empty():
		definition.road_visual_style = "kenney_gridmap"
		definition.road_grid_layout = grid_layout
		definition.road_segment_layout = []
		var grid_route := TrackGridRoadBuilder.route_points_from_grid_layout(grid_layout, definition.closed_loop)
		if grid_route.size() >= 3:
			definition.route_points = grid_route
			var grid_checkpoints := TrackGridRoadBuilder.checkpoint_indices_from_grid_layout(grid_layout, definition.route_points)
			if grid_checkpoints.size() >= 3 and _indices_strictly_increasing(grid_checkpoints):
				definition.checkpoint_indices = grid_checkpoints
				definition.lap_gate_checkpoint_index = 0
			definition.spawn_points = TrackGridRoadBuilder.start_grid_from_grid_layout(grid_layout, definition.route_points)
			definition.item_sockets = TrackGridRoadBuilder.sockets_from_grid_layout(grid_layout, definition.route_points, "item_route_indices", 10)
			definition.hazard_sockets = TrackGridRoadBuilder.sockets_from_grid_layout(grid_layout, definition.route_points, "hazard_route_indices", 8)
	var segment_layout := _collect_road_segments(scene_root, definition.road_width)
	if grid_layout.is_empty() and not segment_layout.is_empty():
		definition.road_segment_layout = segment_layout
		var segment_route := TrackSegmentRoadBuilder.route_points_from_layout(segment_layout, definition.closed_loop)
		if segment_route.size() >= 3:
			definition.route_points = segment_route
			var segment_checkpoints := TrackSegmentRoadBuilder.checkpoint_indices_from_layout(segment_layout, definition.route_points, definition.closed_loop)
			if segment_checkpoints.size() >= 3 and _indices_strictly_increasing(segment_checkpoints):
				definition.checkpoint_indices = segment_checkpoints
				definition.lap_gate_checkpoint_index = 0
			definition.spawn_points = TrackSegmentRoadBuilder.start_grid_from_layout(segment_layout, definition.road_width)
			var generated_items := TrackSegmentRoadBuilder.sockets_from_layout(segment_layout, "item", 10, definition.road_width)
			if not generated_items.is_empty():
				definition.item_sockets = generated_items
			var generated_hazards := TrackSegmentRoadBuilder.sockets_from_layout(segment_layout, "hazard", 8, definition.road_width)
			if not generated_hazards.is_empty():
				definition.hazard_sockets = generated_hazards
	var route_points := _collect_marker_positions(scene_root, "RoutePoints")
	if route_points.size() >= 3:
		if grid_layout.is_empty() and segment_layout.is_empty():
			definition.route_points = route_points
		var checkpoint_indices := _collect_checkpoint_indices(scene_root, route_points)
		if grid_layout.is_empty() and segment_layout.is_empty() and checkpoint_indices.size() >= 3 and _indices_strictly_increasing(checkpoint_indices):
			definition.checkpoint_indices = checkpoint_indices
			definition.lap_gate_checkpoint_index = _collect_lap_gate_checkpoint_index(scene_root)
		if grid_layout.is_empty() and segment_layout.is_empty() and not _spawn_points_on_route(definition.spawn_points, definition.route_points, definition.road_width, definition.closed_loop):
			definition.spawn_points = _start_grid_from_route(definition.route_points, definition.road_width)
	var item_sockets := _collect_socket_markers(scene_root, "ItemSockets")
	if grid_layout.is_empty() and segment_layout.is_empty() and not item_sockets.is_empty():
		definition.item_sockets = item_sockets
	var hazard_sockets := _collect_socket_markers(scene_root, "HazardSockets")
	if grid_layout.is_empty() and segment_layout.is_empty() and not hazard_sockets.is_empty():
		definition.hazard_sockets = hazard_sockets
	var shortcut_gates := _collect_shortcut_gates(scene_root, definition.shortcut_gates)
	if not shortcut_gates.is_empty():
		definition.shortcut_gates = shortcut_gates
	var alternate_routes := _collect_alternate_routes(scene_root, definition.alternate_routes)
	if not alternate_routes.is_empty():
		definition.alternate_routes = alternate_routes
	var stage_props := _collect_stage_props(scene_root)
	if not stage_props.is_empty():
		definition.stage_props = stage_props
	var surface_segments := _collect_surface_segments(scene_root)
	if not surface_segments.is_empty():
		definition.surface_segments = surface_segments
	var audio_zones := _collect_audio_zones(scene_root)
	if not audio_zones.is_empty():
		definition.audio_zones = audio_zones
	var grass_zones := _collect_grass_zones(scene_root)
	if not grass_zones.is_empty():
		definition.grass_zones = grass_zones

static func _collect_road_grid(root: Node3D, road_width: float) -> Dictionary:
	var grid := root.get_node_or_null("RoadGridMap")
	if grid == null or not grid.has_method("to_grid_road_layout"):
		return {}
	var layout := grid.call("to_grid_road_layout", road_width) as Dictionary
	if (layout.get("ordered_route_cells", []) as Array).size() < 3:
		return {}
	return layout

static func _collect_road_segments(root: Node3D, road_width: float) -> Array[Dictionary]:
	var segments: Array[Dictionary] = []
	var holder := root.get_node_or_null("RoadSegments")
	if holder == null:
		return segments
	for child in _sorted_node3d_children(holder):
		if child.has_method("to_road_segment"):
			segments.append(child.call("to_road_segment", road_width) as Dictionary)
	return segments

static func _collect_marker_positions(root: Node3D, holder_name: String) -> Array[Vector3]:
	var out: Array[Vector3] = []
	var holder := root.get_node_or_null(holder_name)
	if holder == null:
		return out
	for marker in _sorted_marker_children(holder):
		out.append(_root_space_position(root, marker as Node3D))
	return out

static func _collect_socket_markers(root: Node3D, holder_name: String) -> Array[Vector4]:
	var sockets: Array[Vector4] = []
	var holder := root.get_node_or_null(holder_name)
	if holder == null:
		return sockets
	for marker in _sorted_marker_children(holder):
		var marker_3d := marker as Marker3D
		var position := _root_space_position(root, marker_3d)
		sockets.append(Vector4(position.x, position.y, position.z, _root_space_yaw(root, marker_3d)))
	return sockets

static func _collect_checkpoint_indices(root: Node3D, route_points: Array[Vector3]) -> Array[int]:
	var indices: Array[int] = []
	var holder := root.get_node_or_null("Checkpoints")
	if holder == null:
		return indices
	for marker in _sorted_marker_children(holder):
		indices.append(_nearest_route_index(_root_space_position(root, marker as Node3D), route_points))
	return indices

static func _collect_lap_gate_checkpoint_index(root: Node3D) -> int:
	var holder := root.get_node_or_null("Checkpoints")
	if holder == null:
		return 0
	var checkpoints := _sorted_marker_children(holder)
	for i in range(checkpoints.size()):
		if str(checkpoints[i].name).to_lower().contains("lap"):
			return i
	return 0

static func _collect_shortcut_gates(root: Node3D, existing_gates: Array[Dictionary]) -> Array[Dictionary]:
	var holder := root.get_node_or_null("ShortcutGates")
	if holder == null:
		return []
	var by_id := {}
	for marker in _sorted_marker_children(holder):
		var marker_3d := marker as Marker3D
		var name := str(marker_3d.name)
		if name.ends_with("_Entry"):
			var id := name.trim_suffix("_Entry")
			if not by_id.has(id):
				by_id[id] = {}
			var entry_position := _root_space_position(root, marker_3d)
			by_id[id]["entry"] = [entry_position.x, entry_position.y, entry_position.z]
		elif name.ends_with("_Exit"):
			var id := name.trim_suffix("_Exit")
			if not by_id.has(id):
				by_id[id] = {}
			var exit_position := _root_space_position(root, marker_3d)
			by_id[id]["exit"] = [exit_position.x, exit_position.y, exit_position.z]
	var gates: Array[Dictionary] = []
	for id in by_id.keys():
		var previous := _find_by_id(existing_gates, str(id))
		var gate := by_id[id] as Dictionary
		gate["id"] = str(id)
		gate["kind"] = str(previous.get("kind", "shortcut"))
		gate["width"] = float(previous.get("width", 0.0))
		gate["surface_enabled"] = bool(previous.get("surface_enabled", true))
		if gate.has("entry") and gate.has("exit"):
			gates.append(gate)
	return gates

static func _collect_alternate_routes(root: Node3D, existing_routes: Array[Dictionary]) -> Array[Dictionary]:
	var holder := root.get_node_or_null("AlternateRoutes")
	if holder == null:
		return []
	var routes: Array[Dictionary] = []
	for route_node in _sorted_node3d_children(holder):
		var id := str(route_node.name)
		var previous := _find_by_id(existing_routes, id)
		var points: Array[Vector3] = []
		for marker in _sorted_marker_children(route_node):
			points.append(_root_space_position(root, marker as Node3D))
		routes.append({
			"id": id,
			"points": points,
			"entry_checkpoint_index": int(previous.get("entry_checkpoint_index", 0)),
			"exit_checkpoint_index": int(previous.get("exit_checkpoint_index", 0)),
			"road_width": float(previous.get("road_width", 0.0)),
			"enabled": bool(previous.get("enabled", true)),
		})
	return routes

static func _find_by_id(items: Array[Dictionary], id: String) -> Dictionary:
	for item in items:
		if str(item.get("id", "")) == id:
			return item
	return {}

static func _collect_stage_props(root: Node) -> Array[Dictionary]:
	var props: Array[Dictionary] = []
	var holder := root.get_node_or_null("Dressing")
	if holder == null:
		return props
	for child in _sorted_node3d_children(holder):
		if child.has_method("to_stage_prop"):
			props.append(child.call("to_stage_prop") as Dictionary)
	return props

static func _collect_surface_segments(root: Node) -> Array[Dictionary]:
	var segments: Array[Dictionary] = []
	var holder := root.get_node_or_null("SurfaceSegments")
	if holder == null:
		return segments
	for child in _sorted_marker_children(holder):
		if child.has_method("to_surface_segment"):
			segments.append(child.call("to_surface_segment") as Dictionary)
	return segments

static func _collect_audio_zones(root: Node) -> Array[Dictionary]:
	var zones: Array[Dictionary] = []
	var holder := root.get_node_or_null("AudioZones")
	if holder == null:
		return zones
	for child in _sorted_marker_children(holder):
		if child.has_method("to_audio_zone"):
			zones.append(child.call("to_audio_zone") as Dictionary)
	return zones

static func _collect_grass_zones(root: Node) -> Array[Dictionary]:
	var zones: Array[Dictionary] = []
	var holder := root.get_node_or_null("GrassZones")
	if holder == null:
		return zones
	for child in _sorted_node3d_children(holder):
		if child.has_method("to_grass_zone"):
			zones.append(child.call("to_grass_zone") as Dictionary)
		elif child is Area3D:
			var zone := _grass_zone_from_area(child as Area3D)
			if not zone.is_empty():
				zones.append(zone)
	return zones

static func _grass_zone_from_area(area: Area3D) -> Dictionary:
	var shape_node := area.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if shape_node == null or not (shape_node.shape is BoxShape3D):
		return {}
	var shape_scale := shape_node.transform.basis.get_scale().abs()
	var shape_size := (shape_node.shape as BoxShape3D).size
	var center := area.position + area.transform.basis * shape_node.position
	return {
		"id": str(area.name),
		"position": [center.x, center.y, center.z],
		"yaw_degrees": area.rotation_degrees.y + shape_node.rotation_degrees.y,
		"size": [shape_size.x * shape_scale.x, shape_size.z * shape_scale.z],
		"density": float(area.get_meta("grass_density", 1.0)),
		"enabled": bool(area.get_meta("grass_enabled", true)),
	}

static func _nearest_route_index(point: Vector3, route_points: Array[Vector3]) -> int:
	var best_index := 0
	var best_distance := INF
	for i in range(route_points.size()):
		var distance := point.distance_squared_to(route_points[i])
		if distance < best_distance:
			best_distance = distance
			best_index = i
	return best_index

static func _indices_strictly_increasing(indices: Array[int]) -> bool:
	var previous := -1
	for index in indices:
		if index <= previous:
			return false
		previous = index
	return true

static func _spawn_points_on_route(spawn_points: Array[Vector4], route_points: Array[Vector3], road_width: float, closed_loop: bool) -> bool:
	if spawn_points.size() < 8 or route_points.size() < 2:
		return false
	var max_distance := road_width * 0.5 + 0.1
	for spawn in spawn_points:
		var point := Vector3(spawn.x, 0.0, spawn.z)
		if _distance_to_route_xz(point, route_points, closed_loop) > max_distance:
			return false
	return true

static func _start_grid_from_route(route_points: Array[Vector3], road_width: float) -> Array[Vector4]:
	var spawns: Array[Vector4] = []
	if route_points.size() < 2:
		return spawns
	var origin := route_points[0]
	var forward := route_points[1] - route_points[0]
	forward.y = 0.0
	if forward.length_squared() <= 0.001:
		forward = Vector3.FORWARD
	forward = forward.normalized()
	var right := Vector3(forward.z, 0.0, -forward.x).normalized()
	var yaw := rad_to_deg(atan2(forward.x, forward.z))
	var lane_gap := minf(road_width * 0.28, 3.0)
	var row_gap := 5.0
	for row in range(4):
		for col in range(2):
			var lateral := (-0.5 if col == 0 else 0.5) * lane_gap
			var forward_offset := float(row) * row_gap
			var position := origin + forward * forward_offset + right * lateral + Vector3.UP * 0.8
			spawns.append(Vector4(position.x, position.y, position.z, yaw))
	return spawns

static func _distance_to_route_xz(point: Vector3, route_points: Array[Vector3], closed_loop: bool) -> float:
	var best := INF
	var segment_count := route_points.size() if closed_loop else route_points.size() - 1
	for i in range(segment_count):
		best = minf(best, _distance_to_segment_xz(point, route_points[i], route_points[(i + 1) % route_points.size()]))
	return best

static func _distance_to_segment_xz(point: Vector3, a3: Vector3, b3: Vector3) -> float:
	var point_2d := Vector2(point.x, point.z)
	var a := Vector2(a3.x, a3.z)
	var b := Vector2(b3.x, b3.z)
	var ab := b - a
	var length_squared := ab.length_squared()
	if length_squared <= 0.0001:
		return point_2d.distance_to(a)
	var t := clampf((point_2d - a).dot(ab) / length_squared, 0.0, 1.0)
	return point_2d.distance_to(a + ab * t)

static func _sorted_marker_children(source: Node) -> Array[Node]:
	var markers: Array[Node] = []
	for child in source.get_children():
		if child is Marker3D:
			markers.append(child)
	markers.sort_custom(func(a: Node, b: Node) -> bool:
		return str(a.name).naturalnocasecmp_to(str(b.name)) < 0
	)
	return markers

static func _sorted_node3d_children(source: Node) -> Array[Node]:
	var nodes: Array[Node] = []
	for child in source.get_children():
		if child is Node3D:
			nodes.append(child)
	nodes.sort_custom(func(a: Node, b: Node) -> bool:
		return str(a.name).naturalnocasecmp_to(str(b.name)) < 0
	)
	return nodes

static func _root_space_position(root: Node3D, node: Node3D) -> Vector3:
	if node == root:
		return Vector3.ZERO
	return _root_space_transform(root, node).origin

static func _root_space_yaw(root: Node3D, node: Node3D) -> float:
	return rad_to_deg(_root_space_transform(root, node).basis.get_euler().y)

static func _root_space_transform(root: Node3D, node: Node3D) -> Transform3D:
	var transform := Transform3D.IDENTITY
	var current: Node = node
	while current != null and current != root:
		if current is Node3D:
			transform = (current as Node3D).transform * transform
		current = current.get_parent()
	return transform
