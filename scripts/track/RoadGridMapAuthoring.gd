@tool
extends GridMap
class_name RoadGridMapAuthoring

@export var ordered_route_cells: Array[Vector3i] = []
@export var checkpoint_route_indices: Array[int] = []
@export var item_route_indices: Array[int] = []
@export var hazard_route_indices: Array[int] = []
@export var spawn_slots: Array[RoadGridSpawn] = []
@export var road_width_override := 0.0

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
