extends RefCounted
class_name TrackGridRoadBuilder

const RoadSegmentProfile = preload("res://scripts/track/RoadSegmentProfile.gd")
const RaceLayout = preload("res://scripts/track/RaceLayout.gd")

const TILE_STRAIGHT := 0
const TILE_CORNER := 1
const TILE_START := 2
const TILE_STRAIGHT_LONG := 3
const TILE_CORNER_LARGE := 4
const TILE_RAMP := 5
const TILE_RAMP_LONG := 6
const TILE_RAMP_LONG_CURVED := 7
const TILE_BUMP := 8
const DEFAULT_MESH_LIBRARY_PATH := "res://assets/source/kenney/racing_kit/racer_road_mesh_library.tres"
const BOUNDARY_WALL_JOIN_OVERLAP := 0.35
const BOUNDARY_WALL_UPPER_CLEARANCE := 0.25
const BOUNDARY_WALL_MIN_HEIGHT := 0.75
const BOUNDARY_WALL_SAME_SURFACE_TOLERANCE := 0.35
const BOUNDARY_WALL_SKIRT_DEPTH := 3.0
const GRID_SUPPORT_COLLISION_SURFACE_OFFSET := 0.0

static func race_layout_from_grid_layout(layout: Dictionary, closed_loop: bool) -> RaceLayout:
	var race_layout := RaceLayout.new()
	race_layout.source = "road_grid_map"
	race_layout.road_visual_style = "kenney_gridmap"
	race_layout.road_grid_layout = layout.duplicate(true)
	race_layout.road_segment_layout = []
	race_layout.route_points = route_points_from_grid_layout(layout, closed_loop)
	if race_layout.route_points.size() >= 3:
		race_layout.checkpoint_indices = checkpoint_indices_from_grid_layout(layout, race_layout.route_points)
		race_layout.lap_gate_checkpoint_index = 0
		race_layout.spawn_points = spawn_points_from_grid_layout(layout, race_layout.route_points)
	return race_layout

static func route_points_from_grid_layout(layout: Dictionary, closed_loop: bool) -> Array[Vector3]:
	var route: Array[Vector3] = []
	var route_cells := _vector3i_array_from_value(layout.get("ordered_route_cells", []))
	if layout.has("ordered_route_points"):
		for point in layout.get("ordered_route_points", []):
			route.append(_vector3_from_value(point, Vector3.ZERO))
		if not route.is_empty():
			route = _route_points_with_grid_surface_heights(layout, route, route_cells)
			if closed_loop and route.size() > 2 and route.front().distance_to(route.back()) <= 0.05:
				route.remove_at(route.size() - 1)
			return route
	for cell in route_cells:
		route.append(_cell_center(layout, cell))
	route = _route_points_with_grid_surface_heights(layout, route, route_cells)
	if closed_loop and route.size() > 2 and route.front().distance_to(route.back()) <= 0.05:
		route.remove_at(route.size() - 1)
	return route

static func checkpoint_indices_from_grid_layout(layout: Dictionary, route_points: Array[Vector3]) -> Array[int]:
	var out: Array[int] = []
	for value in layout.get("checkpoint_route_indices", []):
		var index := int(value)
		if index >= 0 and index < route_points.size() and not out.has(index):
			out.append(index)
	if out.size() < 3 and route_points.size() >= 3:
		out = [0, route_points.size() / 3, (route_points.size() * 2) / 3]
	out.sort()
	return out

static func spawn_points_from_grid_layout(layout: Dictionary, route_points: Array[Vector3]) -> Array[Vector4]:
	var authored_spawns: Array[Vector4] = []
	for value in layout.get("spawn_slots", []):
		if authored_spawns.size() >= 8:
			break
		if not (value is Dictionary):
			continue
		var spawn: Variant = _spawn_from_slot(route_points, value as Dictionary)
		if spawn is Vector4:
			authored_spawns.append(spawn as Vector4)
	if authored_spawns.size() >= 8:
		return authored_spawns
	return start_grid_from_grid_layout(layout, route_points)

static func start_grid_from_grid_layout(layout: Dictionary, route_points: Array[Vector3]) -> Array[Vector4]:
	var road_width := float(layout.get("road_width", 12.0))
	if route_points.size() < 2:
		return []
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
	var spawns: Array[Vector4] = []
	for row in range(4):
		for col in range(2):
			var lateral := (-0.5 if col == 0 else 0.5) * lane_gap
			var forward_offset := float(row) * row_gap
			var position := origin + forward * forward_offset + right * lateral + Vector3.UP * 0.8
			spawns.append(Vector4(position.x, position.y, position.z, yaw))
	return spawns

static func _spawn_from_slot(route_points: Array[Vector3], slot: Dictionary) -> Variant:
	if route_points.size() < 2:
		return null
	var index := int(slot.get("route_index", -1))
	if index < 0 or index >= route_points.size():
		return null
	var next := mini(index + 1, route_points.size() - 1)
	var previous := maxi(index - 1, 0)
	var forward := route_points[next] - route_points[index]
	if index == route_points.size() - 1:
		forward = route_points[index] - route_points[previous]
	forward.y = 0.0
	if forward.length_squared() <= 0.001:
		return null
	forward = forward.normalized()
	var right := Vector3(forward.z, 0.0, -forward.x).normalized()
	var position := route_points[index]
	position += forward * float(slot.get("forward_offset", 0.0))
	position += right * float(slot.get("lateral_offset", 0.0))
	position += Vector3.UP * float(slot.get("y_offset", 0.8))
	var yaw := rad_to_deg(atan2(forward.x, forward.z)) + float(slot.get("yaw_offset_degrees", 0.0))
	return Vector4(position.x, position.y, position.z, yaw)

static func sockets_from_grid_layout(layout: Dictionary, route_points: Array[Vector3], key: String, fallback_count: int) -> Array[Vector4]:
	var sockets: Array[Vector4] = []
	for value in layout.get(key, []):
		var index := int(value)
		if index >= 0 and index < route_points.size():
			sockets.append(_socket_from_route_index(route_points, index))
	if sockets.is_empty() and fallback_count > 0 and route_points.size() >= 2:
		var step := maxi(1, floori(float(route_points.size()) / float(fallback_count)))
		for i in range(fallback_count):
			sockets.append(_socket_from_route_index(route_points, (i * step + step / 2) % route_points.size()))
	return sockets

static func build_grid_road(layout: Dictionary, profile: RoadSegmentProfile = null) -> Node3D:
	if _can_build_grid_map_node(layout):
		return _build_grid_map_node(layout)
	var resolved_profile := profile if profile != null else RoadSegmentProfile.default_profile()
	var holder := Node3D.new()
	holder.name = "GridRoad"
	holder.set_meta("road_visual_style", "kenney_gridmap")
	var material := resolved_profile.road_material() if profile != null else null
	var route_cells := _route_cell_set(layout)
	for cell_data in layout.get("cells", []):
		if not (cell_data is Dictionary):
			continue
		var cell := _vector3i_from_value((cell_data as Dictionary).get("cell", Vector3i.ZERO))
		if not route_cells.is_empty() and not route_cells.has(cell):
			continue
		var item := int((cell_data as Dictionary).get("item", TILE_STRAIGHT))
		var segment_id := _segment_id_for_item(item)
		var scene := load(resolved_profile.segment_path(segment_id)) as PackedScene
		if scene == null:
			continue
		var node := scene.instantiate() as Node3D
		if node == null:
			continue
		node.name = "GridRoad_%s_%s_%s" % [cell.x, cell.y, cell.z]
		var position := _vector3_from_value((cell_data as Dictionary).get("position", _cell_center(layout, cell)), _cell_center(layout, cell))
		var road_width := float(layout.get("road_width", 12.0))
		var bounds := _combined_bounds(node)
		var scale := _scale_for_item(item, bounds, road_width, _cell_size(layout))
		var basis := _orientation_basis(cell_data as Dictionary)
		var scaled_basis := Basis(basis.x * scale.x, basis.y * scale.y, basis.z * scale.z)
		var center_offset := basis * _center_offset_for_item(item, _cell_size(layout))
		node.transform = Transform3D(scaled_basis, position + center_offset - scaled_basis * bounds.get_center())
		if material != null:
			_apply_material_override(node, material)
		_disable_gameplay_collision(node)
		holder.add_child(node)
	return holder

static func build_grid_collision_mesh(layout: Dictionary) -> ArrayMesh:
	var path := str(layout.get("mesh_library_path", ""))
	if path.is_empty():
		path = DEFAULT_MESH_LIBRARY_PATH
	var library := load(path) as MeshLibrary
	if library == null:
		return ArrayMesh.new()
	var vertices := PackedVector3Array()
	var indices := PackedInt32Array()
	var route_cells := _route_cell_set(layout)
	for cell_data in layout.get("cells", []):
		if not (cell_data is Dictionary):
			continue
		var fallback_cell := _vector3i_from_value((cell_data as Dictionary).get("cell", Vector3i.ZERO))
		if not route_cells.is_empty() and not route_cells.has(fallback_cell):
			continue
		var item := int((cell_data as Dictionary).get("item", TILE_STRAIGHT))
		var mesh := library.get_item_mesh(item)
		if mesh == null:
			continue
		var item_transform := library.get_item_mesh_transform(item)
		var orientation_basis := _orientation_basis(cell_data as Dictionary)
		var position := _vector3_from_value((cell_data as Dictionary).get("position", _cell_center(layout, fallback_cell)), _cell_center(layout, fallback_cell))
		_append_transformed_mesh(vertices, indices, mesh, Transform3D(orientation_basis, position) * item_transform)
	var collision_mesh := ArrayMesh.new()
	if vertices.is_empty() or indices.is_empty():
		return collision_mesh
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	collision_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return collision_mesh

static func build_grid_combined_collision_mesh(layout: Dictionary) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var indices := PackedInt32Array()
	_append_mesh_surface(vertices, indices, build_grid_collision_mesh(layout))
	_append_mesh_surface(vertices, indices, _build_grid_support_surface_collision_mesh(layout, GRID_SUPPORT_COLLISION_SURFACE_OFFSET))
	var collision_mesh := ArrayMesh.new()
	if vertices.is_empty() or indices.is_empty():
		return collision_mesh
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	collision_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return collision_mesh

static func _build_grid_support_surface_collision_mesh(layout: Dictionary, surface_offset: float) -> ArrayMesh:
	var footprint := _route_footprint_from_grid_layout(layout)
	var vertices := PackedVector3Array()
	var indices := PackedInt32Array()
	if footprint.is_empty():
		return ArrayMesh.new()
	var cell_size := _cell_size(layout)
	var grid_basis := _basis_from_value(layout.get("basis", []))
	var origin := _vector3_from_value(layout.get("origin", Vector3.ZERO), Vector3.ZERO)
	for key in footprint.keys():
		var cell := key as Vector3i
		var tile_data := footprint.get(cell, {}) as Dictionary
		var x0 := float(cell.x)
		var x1 := float(cell.x + 1)
		var z0 := float(cell.z)
		var z1 := float(cell.z + 1)
		var local_points := [
			Vector3(x0, 0.0, z0),
			Vector3(x1, 0.0, z0),
			Vector3(x0, 0.0, z1),
			Vector3(x1, 0.0, z1),
		]
		var base := vertices.size()
		for local_point in local_points:
			var local := local_point as Vector3
			var world := origin + grid_basis * Vector3(local.x * cell_size.x, 0.0, local.z * cell_size.z)
			world.y = _surface_y_for_grid_local_point(tile_data, local, cell_size) + surface_offset
			vertices.append(world)
		indices.append_array([base, base + 2, base + 1, base + 1, base + 2, base + 3])
	var mesh := ArrayMesh.new()
	if vertices.is_empty() or indices.is_empty():
		return mesh
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

static func _append_mesh_surface(vertices: PackedVector3Array, indices: PackedInt32Array, mesh: Mesh) -> void:
	if mesh == null or mesh.get_surface_count() <= 0:
		return
	var arrays := mesh.surface_get_arrays(0)
	var source_vertices := arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
	var source_indices := arrays[Mesh.ARRAY_INDEX] as PackedInt32Array
	if source_vertices.is_empty() or source_indices.is_empty():
		return
	var base := vertices.size()
	for vertex in source_vertices:
		vertices.append(vertex)
	for index in source_indices:
		indices.append(base + index)

static func boundary_wall_segments_from_grid_layout(layout: Dictionary, wall_height: float, wall_thickness: float) -> Array[Dictionary]:
	var footprint := _route_footprint_from_grid_layout(layout)
	var route_connections := _route_connection_set(layout)
	var segments: Array[Dictionary] = []
	var cell_size := _cell_size(layout)
	var grid_basis := _basis_from_value(layout.get("basis", []))
	var origin := _vector3_from_value(layout.get("origin", Vector3.ZERO), Vector3.ZERO)
	for key in footprint.keys():
		var cell := key as Vector3i
		var tile_data := footprint.get(cell, {}) as Dictionary
		for edge in _cell_boundary_edges(cell, footprint, route_connections):
			var a_local := edge.get("a", Vector3.ZERO) as Vector3
			var b_local := edge.get("b", Vector3.ZERO) as Vector3
			var outward_local := edge.get("outward", Vector3.FORWARD) as Vector3
			var a := origin + grid_basis * Vector3(a_local.x * cell_size.x, 0.0, a_local.z * cell_size.z)
			var b := origin + grid_basis * Vector3(b_local.x * cell_size.x, 0.0, b_local.z * cell_size.z)
			a.y = _surface_y_for_grid_local_point(tile_data, a_local, cell_size)
			b.y = _surface_y_for_grid_local_point(tile_data, b_local, cell_size)
			var outward := (grid_basis * outward_local).normalized()
			if bool(edge.get("connected_route_edge", false)):
				continue
			var height := _boundary_wall_height_for_edge(edge, tile_data, footprint, wall_height, cell_size)
			var segment := _boundary_wall_segment(a, b, outward, height, wall_thickness)
			if not segment.is_empty():
				segments.append(segment)
	return segments

static func _route_footprint_from_grid_layout(layout: Dictionary) -> Dictionary:
	var route_cells := _route_cell_set(layout)
	var footprint := {}
	for cell_data in layout.get("cells", []):
		if not (cell_data is Dictionary):
			continue
		var source := cell_data as Dictionary
		var cell := _vector3i_from_value(source.get("cell", Vector3i.ZERO))
		if not route_cells.is_empty() and not route_cells.has(cell):
			continue
		var item := int(source.get("item", TILE_STRAIGHT))
		var basis := _orientation_basis(source)
		var forward := _horizontal_direction_from_vector(basis.z)
		var right := _horizontal_direction_from_vector(basis.x)
		for footprint_cell in _footprint_cells_for_item(cell, item, forward, right):
			footprint[footprint_cell] = source
	return footprint

static func _route_connection_set(layout: Dictionary) -> Dictionary:
	var connections := {}
	var route_cells: Array[Vector3i] = []
	for value in layout.get("ordered_route_cells", []):
		route_cells.append(_vector3i_from_value(value))
	if route_cells.size() < 2:
		return connections
	for i in range(route_cells.size()):
		var current := route_cells[i]
		var next := route_cells[(i + 1) % route_cells.size()]
		if abs(current.x - next.x) + abs(current.z - next.z) != 1:
			continue
		if abs(current.y - next.y) > 1:
			continue
		connections[_edge_connection_key(current, next)] = true
	return connections

static func _route_points_with_grid_surface_heights(layout: Dictionary, route: Array[Vector3], route_cells: Array[Vector3i]) -> Array[Vector3]:
	if route.is_empty() or route_cells.is_empty():
		return route
	var footprint := _route_footprint_from_grid_layout(layout)
	if footprint.is_empty():
		return route
	var cell_size := _cell_size(layout)
	var out := route.duplicate()
	for i in range(mini(out.size(), route_cells.size())):
		var cell := route_cells[i]
		var tile_data: Dictionary = footprint.get(cell, {}) as Dictionary
		if tile_data.is_empty():
			continue
		var local_point := Vector3(float(cell.x) + 0.5, 0.0, float(cell.z) + 0.5)
		var surface_y := _surface_y_for_grid_local_point(tile_data, local_point, cell_size)
		var point: Vector3 = out[i]
		point.y = surface_y
		out[i] = point
	return out

static func _footprint_cells_for_item(cell: Vector3i, item: int, forward: Vector3i, right: Vector3i) -> Array[Vector3i]:
	if forward == Vector3i.ZERO:
		forward = Vector3i(0, 0, 1)
	if right == Vector3i.ZERO:
		right = Vector3i(1, 0, 0)
	match item:
		TILE_STRAIGHT_LONG, TILE_START, TILE_RAMP_LONG, TILE_RAMP_LONG_CURVED, TILE_BUMP:
			return [cell, cell + forward]
		TILE_CORNER_LARGE:
			return [cell, cell + forward, cell + right, cell + forward + right]
		_:
			return [cell]

static func _cell_boundary_edges(cell: Vector3i, footprint: Dictionary, route_connections: Dictionary = {}) -> Array[Dictionary]:
	var edges: Array[Dictionary] = []
	var x0 := float(cell.x)
	var x1 := float(cell.x + 1)
	var z0 := float(cell.z)
	var z1 := float(cell.z + 1)
	_append_boundary_edge(edges, footprint, route_connections, cell, Vector3i(-1, 0, 0), Vector3(x0, 0.0, z0), Vector3(x0, 0.0, z1), Vector3.LEFT)
	_append_boundary_edge(edges, footprint, route_connections, cell, Vector3i(1, 0, 0), Vector3(x1, 0.0, z1), Vector3(x1, 0.0, z0), Vector3.RIGHT)
	_append_boundary_edge(edges, footprint, route_connections, cell, Vector3i(0, 0, -1), Vector3(x1, 0.0, z0), Vector3(x0, 0.0, z0), Vector3.FORWARD)
	_append_boundary_edge(edges, footprint, route_connections, cell, Vector3i(0, 0, 1), Vector3(x0, 0.0, z1), Vector3(x1, 0.0, z1), Vector3.BACK)
	return edges

static func _append_boundary_edge(edges: Array[Dictionary], footprint: Dictionary, route_connections: Dictionary, cell: Vector3i, direction: Vector3i, a: Vector3, b: Vector3, outward: Vector3) -> void:
	var neighbor: Variant = _footprint_neighbor_for_edge(footprint, cell, direction)
	edges.append({
		"a": a,
		"b": b,
		"outward": outward,
		"direction": direction,
		"neighbor_cell": neighbor,
		"connected_route_edge": neighbor != null and route_connections.has(_edge_connection_key(cell, neighbor as Vector3i)),
	})

static func _footprint_neighbor_for_edge(footprint: Dictionary, cell: Vector3i, direction: Vector3i) -> Variant:
	for y_offset in [0, 1, -1]:
		var candidate := cell + direction + Vector3i(0, y_offset, 0)
		if footprint.has(candidate):
			return candidate
	return null

static func _edge_connection_key(a: Vector3i, b: Vector3i) -> String:
	if _cell_sort_key(a) <= _cell_sort_key(b):
		return "%s|%s" % [_cell_sort_key(a), _cell_sort_key(b)]
	return "%s|%s" % [_cell_sort_key(b), _cell_sort_key(a)]

static func _cell_sort_key(cell: Vector3i) -> String:
	return "%d,%d,%d" % [cell.x, cell.y, cell.z]

static func _boundary_wall_height_for_edge(edge: Dictionary, tile_data: Dictionary, footprint: Dictionary, wall_height: float, cell_size: Vector3) -> float:
	if bool(edge.get("connected_route_edge", false)):
		return 0.0
	var neighbor_value: Variant = edge.get("neighbor_cell", null)
	if neighbor_value == null:
		return wall_height
	var neighbor_cell: Vector3i = neighbor_value as Vector3i
	var neighbor_data: Dictionary = footprint.get(neighbor_cell, {}) as Dictionary
	var a_local: Vector3 = edge.get("a", Vector3.ZERO) as Vector3
	var b_local: Vector3 = edge.get("b", Vector3.ZERO) as Vector3
	var current_a: float = _surface_y_for_grid_local_point(tile_data, a_local, cell_size)
	var current_b: float = _surface_y_for_grid_local_point(tile_data, b_local, cell_size)
	var neighbor_a: float = _surface_y_for_grid_local_point(neighbor_data, a_local, cell_size)
	var neighbor_b: float = _surface_y_for_grid_local_point(neighbor_data, b_local, cell_size)
	var current_avg: float = (current_a + current_b) * 0.5
	var neighbor_avg: float = (neighbor_a + neighbor_b) * 0.5
	if absf(neighbor_avg - current_avg) <= BOUNDARY_WALL_SAME_SURFACE_TOLERANCE:
		return 0.0
	if neighbor_avg < current_avg:
		return wall_height
	var current_top_limit: float = maxf(current_a, current_b)
	var upper_bottom_limit: float = minf(neighbor_a, neighbor_b) - BOUNDARY_WALL_UPPER_CLEARANCE
	var partial_height: float = upper_bottom_limit - current_top_limit
	if partial_height <= 0.0:
		return 0.0
	if partial_height < BOUNDARY_WALL_MIN_HEIGHT:
		return partial_height
	return minf(wall_height, partial_height)

static func _surface_y_for_grid_local_point(tile_data: Dictionary, grid_point: Vector3, cell_size: Vector3) -> float:
	var cell := _vector3i_from_value(tile_data.get("cell", Vector3i.ZERO))
	var position := _vector3_from_value(tile_data.get("position", Vector3.ZERO), Vector3.ZERO)
	var item := int(tile_data.get("item", TILE_STRAIGHT))
	var basis := _orientation_basis(tile_data)
	var forward := _horizontal_direction_from_vector(basis.z)
	if not [TILE_RAMP, TILE_RAMP_LONG, TILE_RAMP_LONG_CURVED].has(item) or forward == Vector3i.ZERO:
		return position.y
	var anchor_center := Vector3((float(cell.x) + 0.5) * cell_size.x, 0.0, (float(cell.z) + 0.5) * cell_size.z)
	var point_xz := Vector3(grid_point.x * cell_size.x, 0.0, grid_point.z * cell_size.z)
	var forward_vec := Vector3(float(forward.x), 0.0, float(forward.z)).normalized()
	var length := cell_size.z
	if item == TILE_RAMP_LONG or item == TILE_RAMP_LONG_CURVED:
		length *= 2.0
	var start := anchor_center - forward_vec * (cell_size.z * 0.5)
	var progress := clampf((point_xz - start).dot(forward_vec) / maxf(length, 0.001), 0.0, 1.0)
	return position.y + progress * cell_size.y

static func _boundary_wall_segment(a: Vector3, b: Vector3, outward: Vector3, wall_height: float, wall_thickness: float) -> Dictionary:
	if wall_height <= 0.0:
		return {}
	var segment := b - a
	var length := segment.length()
	if length <= 0.05:
		return {}
	var x_axis := segment / length
	var z_axis := outward
	if z_axis.length_squared() <= 0.0001:
		z_axis = Vector3.FORWARD
	z_axis = (z_axis - x_axis * z_axis.dot(x_axis)).normalized()
	var y_axis := z_axis.cross(x_axis).normalized()
	if y_axis.dot(Vector3.UP) < 0.0:
		y_axis = -y_axis
		x_axis = -x_axis
	var height := wall_height
	var thickness := maxf(wall_thickness, 0.05)
	var basis := Basis(x_axis, y_axis, z_axis)
	var shape_height := height + BOUNDARY_WALL_SKIRT_DEPTH
	var position := a.lerp(b, 0.5) + y_axis * ((height - BOUNDARY_WALL_SKIRT_DEPTH) * 0.5) + z_axis * (thickness * 0.5)
	return {
		"position": position,
		"basis": basis,
		"size": Vector3(length + BOUNDARY_WALL_JOIN_OVERLAP, shape_height, thickness),
	}

static func _can_build_grid_map_node(layout: Dictionary) -> bool:
	var path := str(layout.get("mesh_library_path", ""))
	if path.is_empty():
		path = DEFAULT_MESH_LIBRARY_PATH
	if not ResourceLoader.exists(path):
		return false
	for cell_data in layout.get("cells", []):
		if not (cell_data is Dictionary):
			continue
		var cell := _vector3i_from_value((cell_data as Dictionary).get("cell", Vector3i.ZERO))
		var expected := _cell_center(layout, cell)
		var actual := _vector3_from_value((cell_data as Dictionary).get("position", expected), expected)
		if expected.distance_to(actual) > 0.05:
			return false
	return true

static func _build_grid_map_node(layout: Dictionary) -> GridMap:
	var grid := GridMap.new()
	grid.name = "GridRoad"
	grid.set_meta("road_visual_style", "kenney_gridmap")
	var path := str(layout.get("mesh_library_path", ""))
	if path.is_empty():
		path = DEFAULT_MESH_LIBRARY_PATH
	grid.mesh_library = load(path) as MeshLibrary
	grid.cell_size = _cell_size(layout)
	grid.transform = Transform3D(
		_basis_from_value(layout.get("basis", [])),
		_vector3_from_value(layout.get("origin", Vector3.ZERO), Vector3.ZERO)
	)
	grid.collision_layer = 0
	grid.collision_mask = 0
	var route_cells := _route_cell_set(layout)
	for cell_data in layout.get("cells", []):
		if not (cell_data is Dictionary):
			continue
		var cell := _vector3i_from_value((cell_data as Dictionary).get("cell", Vector3i.ZERO))
		if not route_cells.is_empty() and not route_cells.has(cell):
			continue
		var item := int((cell_data as Dictionary).get("item", TILE_STRAIGHT))
		var orientation := int((cell_data as Dictionary).get("orientation", 0))
		grid.set_cell_item(cell, item, orientation)
	return grid

static func _route_cell_set(layout: Dictionary) -> Dictionary:
	var route_cells := _vector3i_array_from_value(layout.get("ordered_route_cells", []))
	var out := {}
	for cell in route_cells:
		out[cell] = true
	return out

static func _cell_center(layout: Dictionary, cell: Vector3i) -> Vector3:
	var origin := _vector3_from_value(layout.get("origin", Vector3.ZERO), Vector3.ZERO)
	var basis := _basis_from_value(layout.get("basis", []))
	var size := _cell_size(layout)
	var local := Vector3(
		(float(cell.x) + 0.5) * size.x,
		(float(cell.y) + 0.5) * size.y,
		(float(cell.z) + 0.5) * size.z
	)
	return origin + basis * local

static func _cell_size(layout: Dictionary) -> Vector3:
	return _vector3_from_value(layout.get("cell_size", Vector3(16.0, 4.0, 16.0)), Vector3(16.0, 4.0, 16.0))

static func _segment_id_for_item(item: int) -> String:
	match item:
		TILE_STRAIGHT_LONG:
			return "straight_long"
		TILE_CORNER:
			return "corner_small"
		TILE_CORNER_LARGE:
			return "corner_large"
		TILE_START:
			return "start"
		_:
			return "straight"

static func _scale_for_item(item: int, bounds: AABB, road_width: float, cell_size: Vector3) -> Vector3:
	var safe_width := maxf(bounds.size.x, 0.001)
	var safe_length := maxf(bounds.size.z, 0.001)
	if item == TILE_CORNER:
		return Vector3(cell_size.x / safe_width, 1.0, cell_size.z / safe_length)
	if item == TILE_CORNER_LARGE:
		return Vector3((cell_size.x * 2.0) / safe_width, 1.0, (cell_size.z * 2.0) / safe_length)
	if item == TILE_STRAIGHT_LONG or item == TILE_START:
		return Vector3(road_width / safe_width, 1.0, (cell_size.z * 2.0) / safe_length)
	return Vector3(road_width / safe_width, 1.0, cell_size.z / safe_length)

static func _center_offset_for_item(item: int, cell_size: Vector3) -> Vector3:
	if item == TILE_STRAIGHT_LONG or item == TILE_START:
		return Vector3(0.0, 0.0, cell_size.z * 0.5)
	if item == TILE_CORNER_LARGE:
		return Vector3(cell_size.x * 0.5, 0.0, cell_size.z * 0.5)
	return Vector3.ZERO

static func _orientation_basis(cell_data: Dictionary) -> Basis:
	if cell_data.has("orientation_basis"):
		return _basis_from_value(cell_data.get("orientation_basis", []))
	var orientation := int(cell_data.get("orientation", 0))
	var grid := GridMap.new()
	var basis := grid.get_basis_with_orthogonal_index(orientation)
	grid.free()
	return basis

static func _horizontal_direction_from_vector(vector: Vector3) -> Vector3i:
	var x := int(roundf(vector.x))
	var z := int(roundf(vector.z))
	if abs(x) > abs(z):
		return Vector3i(1 if x > 0 else -1, 0, 0)
	if abs(z) > 0:
		return Vector3i(0, 0, 1 if z > 0 else -1)
	return Vector3i.ZERO

static func _socket_from_route_index(route_points: Array[Vector3], index: int) -> Vector4:
	var next := (index + 1) % route_points.size()
	var position := route_points[index] + Vector3.UP * 0.8
	var forward := route_points[next] - route_points[index]
	forward.y = 0.0
	if forward.length_squared() <= 0.001:
		forward = Vector3.FORWARD
	forward = forward.normalized()
	return Vector4(position.x, position.y, position.z, rad_to_deg(atan2(forward.x, forward.z)))

static func _apply_material_override(node: Node, material: Material) -> void:
	if node is MeshInstance3D:
		(node as MeshInstance3D).material_override = material
	for child in node.get_children():
		_apply_material_override(child, material)

static func _disable_gameplay_collision(node: Node) -> void:
	if node is CollisionObject3D:
		var collision := node as CollisionObject3D
		collision.collision_layer = 0
		collision.collision_mask = 0
	for child in node.get_children():
		_disable_gameplay_collision(child)

static func _combined_bounds(node: Node) -> AABB:
	var found := false
	var out := AABB()
	for child in node.find_children("*", "MeshInstance3D", true, false):
		var mesh_node := child as MeshInstance3D
		var local_aabb := mesh_node.get_aabb()
		var corners := [
			local_aabb.position,
			local_aabb.position + Vector3(local_aabb.size.x, 0.0, 0.0),
			local_aabb.position + Vector3(0.0, local_aabb.size.y, 0.0),
			local_aabb.position + Vector3(0.0, 0.0, local_aabb.size.z),
			local_aabb.position + Vector3(local_aabb.size.x, local_aabb.size.y, 0.0),
			local_aabb.position + Vector3(local_aabb.size.x, 0.0, local_aabb.size.z),
			local_aabb.position + Vector3(0.0, local_aabb.size.y, local_aabb.size.z),
			local_aabb.end,
		]
		for corner in corners:
			var point: Vector3 = mesh_node.transform * corner
			if not found:
				out = AABB(point, Vector3.ZERO)
				found = true
			else:
				out = out.expand(point)
	return out

static func _append_transformed_mesh(vertices: PackedVector3Array, indices: PackedInt32Array, mesh: Mesh, transform: Transform3D) -> void:
	for surface_index in range(mesh.get_surface_count()):
		var arrays := mesh.surface_get_arrays(surface_index)
		var source_vertices := arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
		if source_vertices.is_empty():
			continue
		var source_indices := arrays[Mesh.ARRAY_INDEX] as PackedInt32Array
		var base := vertices.size()
		for vertex in source_vertices:
			vertices.append(transform * vertex)
		if source_indices.is_empty():
			for index in range(source_vertices.size()):
				indices.append(base + index)
		else:
			for index in source_indices:
				indices.append(base + index)

static func _vector3i_array_from_value(value: Variant) -> Array[Vector3i]:
	var out: Array[Vector3i] = []
	if value is Array:
		for item in value:
			out.append(_vector3i_from_value(item))
	return out

static func _vector3i_from_value(value: Variant) -> Vector3i:
	if value is Vector3i:
		return value
	if value is Vector3:
		return Vector3i(roundi(value.x), roundi(value.y), roundi(value.z))
	if value is Array and value.size() >= 3:
		return Vector3i(int(value[0]), int(value[1]), int(value[2]))
	if value is Dictionary:
		return Vector3i(int(value.get("x", 0)), int(value.get("y", 0)), int(value.get("z", 0)))
	return Vector3i.ZERO

static func _vector3_from_value(value: Variant, fallback: Vector3) -> Vector3:
	if value is Vector3:
		return value
	if value is Vector3i:
		return Vector3(float(value.x), float(value.y), float(value.z))
	if value is Array and value.size() >= 3:
		return Vector3(float(value[0]), float(value[1]), float(value[2]))
	if value is Dictionary:
		return Vector3(float(value.get("x", fallback.x)), float(value.get("y", fallback.y)), float(value.get("z", fallback.z)))
	return fallback

static func _basis_from_value(value: Variant) -> Basis:
	if value is Basis:
		return value
	if value is Array and value.size() >= 3:
		var x := _vector3_from_value(value[0], Vector3.RIGHT)
		var y := _vector3_from_value(value[1], Vector3.UP)
		var z := _vector3_from_value(value[2], Vector3.BACK)
		return Basis(x, y, z)
	return Basis.IDENTITY
