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
const BOUNDARY_WALL_HEIGHT := 3.0
const BOUNDARY_WALL_THICKNESS := 0.6
const BOUNDARY_WALL_EDGE_OVERLAP := 0.25
const BOUNDARY_WALL_JOIN_OVERLAP := 0.35
const BOUNDARY_WALL_MAX_SEGMENT_LENGTH := 2.0
const BOUNDARY_WALL_SKIRT_DEPTH := 0.25
const BOUNDARY_WALL_UPPER_CLEARANCE := 0.65
const BOUNDARY_WALL_MIN_HEIGHT := 0.75
const BOUNDARY_WALL_SAME_SURFACE_TOLERANCE := 0.35

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
	if layout.has("ordered_route_points"):
		for point in layout.get("ordered_route_points", []):
			route.append(_vector3_from_value(point, Vector3.ZERO))
		if not route.is_empty():
			if closed_loop and route.size() > 2 and route.front().distance_to(route.back()) <= 0.05:
				route.remove_at(route.size() - 1)
			return route
	var route_cells := _vector3i_array_from_value(layout.get("ordered_route_cells", []))
	for cell in route_cells:
		route.append(_cell_center(layout, cell))
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

static func boundary_wall_segments_from_grid_layout(layout: Dictionary, wall_height := BOUNDARY_WALL_HEIGHT, wall_thickness := BOUNDARY_WALL_THICKNESS) -> Array[Dictionary]:
	var segments: Array[Dictionary] = []
	if layout.is_empty():
		return segments
	var owners := _route_footprint_owners(layout)
	if owners.is_empty():
		return segments
	for footprint_cell in owners.keys():
		var owner := owners[footprint_cell] as Dictionary
		for direction in _cardinal_grid_directions():
			var neighbor := _neighbor_owner_for_edge(owners, footprint_cell as Vector3i, direction)
			if _edge_is_internal_same_surface(layout, owner, direction, neighbor):
				continue
			_append_boundary_wall_segments_for_edge(segments, layout, owner, direction, neighbor, wall_height, wall_thickness)
	return segments

static func _append_boundary_wall_segments_for_edge(
	segments: Array[Dictionary],
	layout: Dictionary,
	owner: Dictionary,
	direction: Vector3i,
	neighbor: Dictionary,
	wall_height: float,
	wall_thickness: float
) -> void:
	var footprint_cell := owner.get("footprint_cell", Vector3i.ZERO) as Vector3i
	var edge := _footprint_edge_points(layout, footprint_cell, direction)
	var edge_a := edge.get("a", Vector3.ZERO) as Vector3
	var edge_b := edge.get("b", Vector3.ZERO) as Vector3
	var outward := edge.get("outward", Vector3.ZERO) as Vector3
	if edge_a.distance_to(edge_b) <= 0.001 or outward.length_squared() <= 0.001:
		return
	var parts := maxi(1, ceili(edge_a.distance_to(edge_b) / BOUNDARY_WALL_MAX_SEGMENT_LENGTH))
	for part_index in range(parts):
		var t0 := float(part_index) / float(parts)
		var t1 := float(part_index + 1) / float(parts)
		var a := edge_a.lerp(edge_b, t0)
		var b := edge_a.lerp(edge_b, t1)
		var bottom := minf(
			_surface_y_for_world_point(layout, owner, a),
			_surface_y_for_world_point(layout, owner, b)
		) - BOUNDARY_WALL_SKIRT_DEPTH
		var current_top := maxf(
			_surface_y_for_world_point(layout, owner, a),
			_surface_y_for_world_point(layout, owner, b)
		) + wall_height
		var capped_top := current_top
		if not neighbor.is_empty() and int(neighbor.get("y_offset", 0)) > 0:
			var neighbor_top := minf(
				_surface_y_for_world_point(layout, neighbor, a),
				_surface_y_for_world_point(layout, neighbor, b)
			) - BOUNDARY_WALL_UPPER_CLEARANCE
			capped_top = minf(capped_top, neighbor_top)
		var height := capped_top - bottom
		if height < BOUNDARY_WALL_MIN_HEIGHT:
			continue
		segments.append({
			"a": a,
			"b": b,
			"outward": outward.normalized(),
			"bottom": bottom,
			"height": height,
			"thickness": wall_thickness,
			"edge_overlap": BOUNDARY_WALL_EDGE_OVERLAP,
			"join_overlap": BOUNDARY_WALL_JOIN_OVERLAP,
			"cell": footprint_cell,
			"anchor_cell": owner.get("anchor_cell", Vector3i.ZERO),
			"item": int(owner.get("item", TILE_STRAIGHT)),
			"direction": direction,
		})

static func _route_footprint_owners(layout: Dictionary) -> Dictionary:
	var route_cells := _route_cell_set(layout)
	var owners := {}
	for cell_data in layout.get("cells", []):
		if not (cell_data is Dictionary):
			continue
		var cell := _vector3i_from_value((cell_data as Dictionary).get("cell", Vector3i.ZERO))
		if not route_cells.is_empty() and not route_cells.has(cell):
			continue
		var owner_data := (cell_data as Dictionary).duplicate(true)
		owner_data["anchor_cell"] = cell
		owner_data["item"] = int(owner_data.get("item", TILE_STRAIGHT))
		for footprint_cell in _footprint_cells_for_cell(layout, owner_data):
			if owners.has(footprint_cell):
				continue
			var owner := owner_data.duplicate(true)
			owner["footprint_cell"] = footprint_cell
			owners[footprint_cell] = owner
	return owners

static func _footprint_cells_for_cell(layout: Dictionary, cell_data: Dictionary) -> Array[Vector3i]:
	var anchor := _vector3i_from_value(cell_data.get("anchor_cell", cell_data.get("cell", Vector3i.ZERO)))
	var item := int(cell_data.get("item", TILE_STRAIGHT))
	var forward := _grid_direction_from_basis_vector((_orientation_basis(cell_data)).z)
	var right := _grid_direction_from_basis_vector((_orientation_basis(cell_data)).x)
	var cells: Array[Vector3i] = [anchor]
	match item:
		TILE_STRAIGHT_LONG, TILE_START, TILE_RAMP_LONG, TILE_RAMP_LONG_CURVED, TILE_BUMP:
			if forward != Vector3i.ZERO:
				cells.append(anchor + forward)
		TILE_CORNER_LARGE:
			if forward != Vector3i.ZERO:
				cells.append(anchor + forward)
			if right != Vector3i.ZERO:
				cells.append(anchor + right)
			if forward != Vector3i.ZERO and right != Vector3i.ZERO:
				cells.append(anchor + forward + right)
	return cells

static func _neighbor_owner_for_edge(owners: Dictionary, footprint_cell: Vector3i, direction: Vector3i) -> Dictionary:
	var base := footprint_cell + direction
	for y_offset in [0, 1, -1]:
		var candidate := base + Vector3i(0, int(y_offset), 0)
		if owners.has(candidate):
			var neighbor := (owners[candidate] as Dictionary).duplicate(true)
			neighbor["y_offset"] = int(y_offset)
			return neighbor
	return {}

static func _edge_is_internal_same_surface(layout: Dictionary, owner: Dictionary, direction: Vector3i, neighbor: Dictionary) -> bool:
	if neighbor.is_empty():
		return false
	if int(neighbor.get("y_offset", 0)) != 0 and not _edge_surfaces_match(layout, owner, direction, neighbor):
		return false
	return _edge_surfaces_match(layout, owner, direction, neighbor)

static func _edge_surfaces_match(layout: Dictionary, owner: Dictionary, direction: Vector3i, neighbor: Dictionary) -> bool:
	var footprint_cell := owner.get("footprint_cell", Vector3i.ZERO) as Vector3i
	var edge := _footprint_edge_points(layout, footprint_cell, direction)
	var a := edge.get("a", Vector3.ZERO) as Vector3
	var b := edge.get("b", Vector3.ZERO) as Vector3
	for t in [0.0, 0.5, 1.0]:
		var sample := a.lerp(b, float(t))
		var current_y := _surface_y_for_world_point(layout, owner, sample)
		var neighbor_y := _surface_y_for_world_point(layout, neighbor, sample)
		if absf(current_y - neighbor_y) > BOUNDARY_WALL_SAME_SURFACE_TOLERANCE:
			return false
	return true

static func _footprint_edge_points(layout: Dictionary, footprint_cell: Vector3i, direction: Vector3i) -> Dictionary:
	var basis := _basis_from_value(layout.get("basis", []))
	var size := _cell_size(layout)
	var center := _cell_center(layout, footprint_cell)
	var half_x := basis.x * (size.x * 0.5)
	var half_z := basis.z * (size.z * 0.5)
	if direction.x > 0:
		return {"a": center + half_x - half_z, "b": center + half_x + half_z, "outward": basis.x}
	if direction.x < 0:
		return {"a": center - half_x + half_z, "b": center - half_x - half_z, "outward": -basis.x}
	if direction.z > 0:
		return {"a": center + half_z + half_x, "b": center + half_z - half_x, "outward": basis.z}
	return {"a": center - half_z - half_x, "b": center - half_z + half_x, "outward": -basis.z}

static func _surface_y_for_world_point(layout: Dictionary, owner: Dictionary, world_point: Vector3) -> float:
	var cell_data := owner
	var anchor := _vector3i_from_value(cell_data.get("anchor_cell", cell_data.get("cell", Vector3i.ZERO)))
	var anchor_center := _cell_center(layout, anchor)
	var item := int(cell_data.get("item", TILE_STRAIGHT))
	var local := (_orientation_basis(cell_data).inverse()) * (world_point - anchor_center)
	var size := _cell_size(layout)
	var base_y := anchor_center.y
	match item:
		TILE_RAMP:
			var t := clampf((size.z * 0.5 - local.z) / maxf(size.z, 0.001), 0.0, 1.0)
			return base_y + t * size.y
		TILE_RAMP_LONG, TILE_RAMP_LONG_CURVED:
			var t := clampf((size.z * 0.5 - local.z) / maxf(size.z * 2.0, 0.001), 0.0, 1.0)
			return base_y + t * size.y
	return base_y

static func _cardinal_grid_directions() -> Array[Vector3i]:
	return [Vector3i.RIGHT, Vector3i.LEFT, Vector3i.FORWARD, Vector3i.BACK]

static func _grid_direction_from_basis_vector(vector: Vector3) -> Vector3i:
	var horizontal := Vector3(vector.x, 0.0, vector.z)
	if horizontal.length_squared() <= 0.001:
		return Vector3i.ZERO
	horizontal = horizontal.normalized()
	if absf(horizontal.x) >= absf(horizontal.z):
		return Vector3i(1 if horizontal.x >= 0.0 else -1, 0, 0)
	return Vector3i(0, 0, 1 if horizontal.z >= 0.0 else -1)

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
