@tool
extends GridMap
class_name RoadGridMapAuthoring

@export var ordered_route_cells: Array[Vector3i] = []
@export var checkpoint_route_indices: Array[int] = []
@export var item_route_indices: Array[int] = []
@export var hazard_route_indices: Array[int] = []
@export var spawn_slots: Array[RoadGridSpawn] = []
@export var road_width_override := 0.0
@export var regenerate_route_from_painted_track := false:
	set(value):
		if value:
			var result := regenerate_route_metadata_from_painted_track()
			var warning := str(result.get("warning", ""))
			if not warning.is_empty():
				push_warning(warning)
		regenerate_route_from_painted_track = false

const ROUTE_DIRECTIONS := [
	Vector3i(1, 0, 0),
	Vector3i(0, 0, 1),
	Vector3i(-1, 0, 0),
	Vector3i(0, 0, -1),
]
const GENERATED_CHECKPOINT_COUNT := 6
const TILE_CORNER := 1
const TILE_START := 2
const TILE_STRAIGHT_LONG := 3
const TILE_CORNER_LARGE := 4
const TILE_RAMP := 5
const TILE_RAMP_LONG := 6
const TILE_RAMP_LONG_CURVED := 7
const TILE_BUMP := 8

func regenerate_route_metadata_from_painted_track(checkpoint_count := GENERATED_CHECKPOINT_COUNT) -> Dictionary:
	var route := route_cells_from_painted_track()
	if route.size() < 4:
		var bridge_cell := _single_cell_bridge_for_painted_route()
		if bridge_cell != Vector3i(999999, 999999, 999999):
			_paint_bridge_cell(bridge_cell)
			route = route_cells_from_painted_track()
	if route.size() < 4:
		return {
			"success": false,
			"warning": "RoadGridMap route generation needs one continuous painted loop with at least four cells.",
			"route_cells": route,
		}
	ordered_route_cells.assign(route)
	checkpoint_route_indices.assign(_checkpoint_indices_for_route(route.size(), checkpoint_count))
	notify_property_list_changed()
	return {
		"success": true,
		"route_cells": ordered_route_cells.duplicate(),
		"checkpoint_route_indices": checkpoint_route_indices.duplicate(),
	}

func route_cells_from_painted_track() -> Array[Vector3i]:
	var cells := _painted_road_cells()
	if cells.size() < 4:
		return []
	var cell_set := {}
	for cell in cells:
		cell_set[cell] = true
	var neighbors := _route_neighbors_for_cells(cells, cell_set)
	for component in _route_components(cells, neighbors):
		var core := _cycle_core_for_component(component, neighbors)
		if core.size() < 4:
			continue
		var core_set := _cell_set_from_array(core)
		var core_neighbors := _neighbors_limited_to_core(core, neighbors, core_set)
		if not _all_cells_have_degree(core, core_neighbors, 2):
			continue
		var route := _walk_cycle(core, core_neighbors)
		if route.size() >= 4:
			return route
	return []

func _single_cell_bridge_for_painted_route() -> Vector3i:
	var cells := _painted_road_cells()
	if cells.size() < 4:
		return Vector3i(999999, 999999, 999999)
	var cell_set := {}
	for cell in cells:
		cell_set[cell] = true
	var neighbors := _route_neighbors_for_cells(cells, cell_set)
	var components := _route_components(cells, neighbors)
	for component in components:
		var endpoints: Array[Vector3i] = []
		for cell in component:
			var cell_neighbors: Array = neighbors.get(cell, [])
			if cell_neighbors.size() == 1:
				endpoints.append(cell)
		if endpoints.size() != 2:
			continue
		var a := endpoints[0]
		var b := endpoints[1]
		if a.y != b.y:
			continue
		var delta := b - a
		if abs(delta.x) + abs(delta.z) != 2:
			continue
		if abs(delta.x) == 2 and delta.z == 0:
			var bridge := Vector3i((a.x + b.x) / 2, a.y, a.z)
			if not cell_set.has(bridge):
				return bridge
		if abs(delta.z) == 2 and delta.x == 0:
			var bridge := Vector3i(a.x, a.y, (a.z + b.z) / 2)
			if not cell_set.has(bridge):
				return bridge
	return Vector3i(999999, 999999, 999999)

func _paint_bridge_cell(cell: Vector3i) -> void:
	var x_neighbors := _has_painted_neighbor(cell + Vector3i(-1, 0, 0)) and _has_painted_neighbor(cell + Vector3i(1, 0, 0))
	var orientation := 22 if x_neighbors else 0
	set_cell_item(cell, 0, orientation)

func _walk_cycle(cells: Array[Vector3i], neighbors: Dictionary) -> Array[Vector3i]:
	var cell_set := _cell_set_from_array(cells)
	var start := _route_start_cell(cells, cell_set)
	var route: Array[Vector3i] = [start]
	var previous := Vector3i(999999, 999999, 999999)
	var current := start
	while true:
		var current_neighbors: Array = neighbors.get(current, [])
		if current_neighbors.size() != 2:
			return []
		var next := current_neighbors[0] as Vector3i
		if next == previous:
			next = current_neighbors[1] as Vector3i
		if next == start:
			return route if route.size() == cells.size() else []
		if route.has(next):
			return []
		route.append(next)
		previous = current
		current = next
	return []

func to_grid_road_layout(default_road_width := 12.0) -> Dictionary:
	var cells: Array[Dictionary] = []
	for cell in get_used_cells():
		var orientation := get_cell_item_orientation(cell)
		cells.append({
			"cell": cell,
			"item": get_cell_item(cell),
			"orientation": orientation,
			"orientation_basis": _basis_to_array(get_basis_with_orthogonal_index(orientation)),
			"position": _root_space_transform() * map_to_local(cell),
		})
	cells.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var acell := a.get("cell", Vector3i.ZERO) as Vector3i
		var bcell := b.get("cell", Vector3i.ZERO) as Vector3i
		if acell.z != bcell.z:
			return acell.z < bcell.z
		if acell.x != bcell.x:
			return acell.x < bcell.x
		return acell.y < bcell.y
	)
	return {
		"origin": _root_space_transform().origin,
		"basis": _basis_to_array(_root_space_transform().basis),
		"cell_size": cell_size,
		"mesh_library_path": mesh_library.resource_path if mesh_library != null else "",
		"road_width": road_width_override if road_width_override > 0.0 else default_road_width,
		"cells": cells,
		"ordered_route_cells": ordered_route_cells.duplicate(),
		"ordered_route_points": _ordered_route_points(),
		"checkpoint_route_indices": checkpoint_route_indices.duplicate(),
		"spawn_slots": _spawn_slot_layouts(),
		"item_route_indices": item_route_indices.duplicate(),
		"hazard_route_indices": hazard_route_indices.duplicate(),
	}

func _ordered_route_points() -> Array[Vector3]:
	var points: Array[Vector3] = []
	var root_transform := _root_space_transform()
	for cell in ordered_route_cells:
		points.append(root_transform * map_to_local(cell))
	return points

func _spawn_slot_layouts() -> Array[Dictionary]:
	var slots: Array[Dictionary] = []
	for slot in spawn_slots:
		if slot != null:
			slots.append(slot.to_layout_data())
	return slots

func _root_space_transform() -> Transform3D:
	if is_inside_tree():
		var root := get_tree().edited_scene_root if Engine.is_editor_hint() else null
		if root is Node3D:
			return (root as Node3D).global_transform.affine_inverse() * global_transform
	var resolved := transform
	var current := get_parent()
	while current != null and current is Node3D:
		resolved = (current as Node3D).transform * resolved
		current = current.get_parent()
	return resolved

func _basis_to_array(basis: Basis) -> Array:
	return [
		[basis.x.x, basis.x.y, basis.x.z],
		[basis.y.x, basis.y.y, basis.y.z],
		[basis.z.x, basis.z.y, basis.z.z],
	]

func _painted_road_cells() -> Array[Vector3i]:
	var cells: Array[Vector3i] = []
	for cell in get_used_cells():
		if get_cell_item(cell) >= 0:
			cells.append(cell)
	cells.sort_custom(func(a: Vector3i, b: Vector3i) -> bool:
		if a.y != b.y:
			return a.y < b.y
		if a.z != b.z:
			return a.z < b.z
		return a.x < b.x
	)
	return cells

func _route_neighbors_for_cells(cells: Array[Vector3i], cell_set: Dictionary) -> Dictionary:
	var neighbors := {}
	for cell in cells:
		var cell_neighbors: Array[Vector3i] = []
		for connection in _connection_offsets_for_cell(cell):
			var direction := connection.get("direction", Vector3i.ZERO) as Vector3i
			var distance := int(connection.get("distance", 1))
			for y_offset in [-1, 0, 1]:
				var candidate: Vector3i = cell + direction * distance + Vector3i(0, y_offset, 0)
				if cell_set.has(candidate) and _cell_connects_toward(candidate, -direction):
					cell_neighbors.append(candidate)
					break
		neighbors[cell] = cell_neighbors
	return neighbors

func _route_start_cell(cells: Array[Vector3i], cell_set: Dictionary) -> Vector3i:
	if not ordered_route_cells.is_empty() and cell_set.has(ordered_route_cells[0]):
		return ordered_route_cells[0]
	return cells[0]

func _checkpoint_indices_for_route(route_size: int, checkpoint_count: int) -> Array[int]:
	var count := clampi(checkpoint_count, 2, route_size)
	var indices: Array[int] = []
	for i in range(count):
		var index := int(floor(float(i * route_size) / float(count)))
		if not indices.has(index):
			indices.append(index)
	if indices[0] != 0:
		indices.push_front(0)
	return indices

func _route_components(cells: Array[Vector3i], neighbors: Dictionary) -> Array[Array]:
	var components: Array[Array] = []
	var visited := {}
	for cell in cells:
		if visited.has(cell):
			continue
		var component: Array[Vector3i] = []
		var stack: Array[Vector3i] = [cell]
		visited[cell] = true
		while not stack.is_empty():
			var current: Vector3i = stack.pop_back()
			component.append(current)
			for neighbor in neighbors.get(current, []):
				if not visited.has(neighbor):
					visited[neighbor] = true
					stack.append(neighbor)
		components.append(component)
	components.sort_custom(func(a: Array, b: Array) -> bool:
		return a.size() > b.size()
	)
	return components

func _cycle_core_for_component(component: Array[Vector3i], neighbors: Dictionary) -> Array[Vector3i]:
	var active := _cell_set_from_array(component)
	var changed := true
	while changed:
		changed = false
		var to_remove: Array[Vector3i] = []
		for cell in active.keys():
			if _degree_limited_to_active(cell, neighbors, active) <= 1:
				to_remove.append(cell)
		for cell in to_remove:
			active.erase(cell)
			changed = true
	var core: Array[Vector3i] = []
	for cell in active.keys():
		core.append(cell)
	core.sort_custom(func(a: Vector3i, b: Vector3i) -> bool:
		return _sort_cell(a, b)
	)
	return core

func _neighbors_limited_to_core(cells: Array[Vector3i], neighbors: Dictionary, core_set: Dictionary) -> Dictionary:
	var limited := {}
	for cell in cells:
		var kept: Array[Vector3i] = []
		for neighbor in neighbors.get(cell, []):
			if core_set.has(neighbor):
				kept.append(neighbor)
		limited[cell] = kept
	return limited

func _all_cells_have_degree(cells: Array[Vector3i], neighbors: Dictionary, expected_degree: int) -> bool:
	for cell in cells:
		var cell_neighbors: Array = neighbors.get(cell, [])
		if cell_neighbors.size() != expected_degree:
			return false
	return true

func _degree_limited_to_active(cell: Vector3i, neighbors: Dictionary, active: Dictionary) -> int:
	var degree := 0
	for neighbor in neighbors.get(cell, []):
		if active.has(neighbor):
			degree += 1
	return degree

func _cell_set_from_array(cells: Array) -> Dictionary:
	var cell_set := {}
	for cell in cells:
		cell_set[cell] = true
	return cell_set

func _connection_directions_for_cell(cell: Vector3i) -> Array[Vector3i]:
	var directions: Array[Vector3i] = []
	for connection in _connection_offsets_for_cell(cell):
		var direction := connection.get("direction", Vector3i.ZERO) as Vector3i
		if direction != Vector3i.ZERO and not directions.has(direction):
			directions.append(direction)
	return directions

func _connection_offsets_for_cell(cell: Vector3i) -> Array[Dictionary]:
	var item := get_cell_item(cell)
	var orientation := get_cell_item_orientation(cell)
	var basis := get_basis_with_orthogonal_index(orientation)
	match item:
		TILE_CORNER, TILE_CORNER_LARGE:
			return _connections_for_directions(_unique_horizontal_directions([basis.x, basis.z]))
		TILE_STRAIGHT_LONG, TILE_RAMP_LONG, TILE_RAMP_LONG_CURVED, TILE_BUMP:
			var forward_long := _horizontal_direction_from_vector(basis.z)
			return [
				{"direction": forward_long, "distance": 2},
				{"direction": -forward_long, "distance": 1},
			]
		TILE_START, TILE_RAMP:
			var forward := _horizontal_direction_from_vector(basis.z)
			return _connections_for_directions(_opposite_directions(forward))
		_:
			var forward := _horizontal_direction_from_vector(basis.z)
			return _connections_for_directions(_opposite_directions(forward))

func _cell_connects_toward(cell: Vector3i, direction: Vector3i) -> bool:
	return _connection_directions_for_cell(cell).has(direction)

func _has_painted_neighbor(cell: Vector3i) -> bool:
	for y_offset in [-1, 0, 1]:
		if get_cell_item(cell + Vector3i(0, y_offset, 0)) >= 0:
			return true
	return false

func _unique_horizontal_directions(vectors: Array) -> Array[Vector3i]:
	var directions: Array[Vector3i] = []
	for vector in vectors:
		var direction := _horizontal_direction_from_vector(vector as Vector3)
		if direction != Vector3i.ZERO and not directions.has(direction):
			directions.append(direction)
	return directions

func _opposite_directions(direction: Vector3i) -> Array[Vector3i]:
	var directions: Array[Vector3i] = []
	if direction != Vector3i.ZERO:
		directions.append(direction)
		directions.append(-direction)
	return directions

func _connections_for_directions(directions: Array[Vector3i]) -> Array[Dictionary]:
	var connections: Array[Dictionary] = []
	for direction in directions:
		connections.append({"direction": direction, "distance": 1})
	return connections

func _horizontal_direction_from_vector(vector: Vector3) -> Vector3i:
	var x := int(roundf(vector.x))
	var z := int(roundf(vector.z))
	if abs(x) > abs(z):
		return Vector3i(1 if x > 0 else -1, 0, 0)
	if abs(z) > 0:
		return Vector3i(0, 0, 1 if z > 0 else -1)
	return Vector3i.ZERO

func _sort_cell(a: Vector3i, b: Vector3i) -> bool:
	if a.y != b.y:
		return a.y < b.y
	if a.z != b.z:
		return a.z < b.z
	return a.x < b.x
