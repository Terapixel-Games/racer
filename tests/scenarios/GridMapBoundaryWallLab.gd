extends Node3D
class_name GridMapBoundaryWallLab

const TrackDefinition = preload("res://scripts/track/TrackDefinition.gd")
const TrackGridRoadBuilder = preload("res://scripts/track/TrackGridRoadBuilder.gd")

const CELL_SIZE := Vector3(16.0, 4.0, 16.0)

func make_definition(debug_walls := false) -> TrackDefinition:
	var definition := TrackDefinition.new()
	definition.id = "gridmap_wall_lab"
	definition.display_name = "GridMap Wall Lab"
	definition.version = "uat"
	definition.laps = 1
	definition.track_source_id = "road_grid_map"
	definition.road_visual_style = "kenney_gridmap"
	definition.road_width = 16.0
	definition.wall_height = 3.0
	definition.wall_thickness = 0.6
	definition.boundary_walls_enabled = true
	definition.boundary_wall_debug_visible = debug_walls
	definition.rails_enabled = false
	definition.closed_loop = true
	definition.out_of_bounds_y = -24.0
	definition.reset_mode = "instant_pop"
	definition.floor_visual_y = -28.0
	definition.ground_size = Vector2(160.0, 160.0)
	definition.road_grid_layout = make_layout()
	var race_layout := TrackGridRoadBuilder.race_layout_from_grid_layout(definition.road_grid_layout, definition.closed_loop)
	definition.route_points = race_layout.route_points.duplicate()
	definition.checkpoint_indices = race_layout.checkpoint_indices.duplicate()
	definition.lap_gate_checkpoint_index = race_layout.lap_gate_checkpoint_index
	definition.spawn_points = race_layout.spawn_points.duplicate()
	return definition

func make_layout() -> Dictionary:
	var cells: Array[Dictionary] = [
		_cell(Vector3i(0, 0, 0), TrackGridRoadBuilder.TILE_START, deg_to_rad(90.0)),
		_cell(Vector3i(1, 0, 0), TrackGridRoadBuilder.TILE_STRAIGHT, deg_to_rad(90.0)),
		_cell(Vector3i(2, 0, 0), TrackGridRoadBuilder.TILE_STRAIGHT, deg_to_rad(90.0)),
		_cell(Vector3i(3, 0, 0), TrackGridRoadBuilder.TILE_CORNER, 0.0),
		_cell(Vector3i(3, 0, 1), TrackGridRoadBuilder.TILE_STRAIGHT, 0.0),
		_cell(Vector3i(3, 0, 2), TrackGridRoadBuilder.TILE_RAMP, deg_to_rad(180.0)),
		_cell(Vector3i(3, 1, 3), TrackGridRoadBuilder.TILE_STRAIGHT, deg_to_rad(90.0)),
		_cell(Vector3i(2, 1, 3), TrackGridRoadBuilder.TILE_STRAIGHT, deg_to_rad(90.0)),
		_cell(Vector3i(1, 1, 3), TrackGridRoadBuilder.TILE_STRAIGHT, deg_to_rad(90.0)),
		_cell(Vector3i(0, 1, 3), TrackGridRoadBuilder.TILE_CORNER, deg_to_rad(180.0)),
		_cell(Vector3i(0, 0, 2), TrackGridRoadBuilder.TILE_RAMP, deg_to_rad(180.0)),
		_cell(Vector3i(0, 0, 1), TrackGridRoadBuilder.TILE_STRAIGHT, 0.0),
	]
	var route_cells: Array[Vector3i] = [
		Vector3i(0, 0, 0),
		Vector3i(1, 0, 0),
		Vector3i(2, 0, 0),
		Vector3i(3, 0, 0),
		Vector3i(3, 0, 1),
		Vector3i(3, 0, 2),
		Vector3i(3, 1, 3),
		Vector3i(2, 1, 3),
		Vector3i(1, 1, 3),
		Vector3i(0, 1, 3),
		Vector3i(0, 0, 2),
		Vector3i(0, 0, 1),
	]
	return {
		"origin": Vector3(-32.0, 0.0, -32.0),
		"basis": _basis_to_array(Basis.IDENTITY),
		"cell_size": CELL_SIZE,
		"mesh_library_path": TrackGridRoadBuilder.DEFAULT_MESH_LIBRARY_PATH,
		"road_width": 16.0,
		"cells": cells,
		"ordered_route_cells": route_cells,
		"checkpoint_route_indices": [0, 3, 6, 9],
		"spawn_slots": [],
		"item_route_indices": [],
		"hazard_route_indices": [],
	}

func _cell(cell: Vector3i, item: int, yaw: float) -> Dictionary:
	var basis := Basis(Vector3.UP, yaw)
	return {
		"cell": cell,
		"item": item,
		"orientation": _orientation_index_for_basis(basis),
		"orientation_basis": _basis_to_array(basis),
	}

func _orientation_index_for_basis(basis: Basis) -> int:
	var grid := GridMap.new()
	var index := grid.get_orthogonal_index_from_basis(basis)
	grid.free()
	return index

func _basis_to_array(basis: Basis) -> Array:
	return [
		[basis.x.x, basis.x.y, basis.x.z],
		[basis.y.x, basis.y.y, basis.y.z],
		[basis.z.x, basis.z.y, basis.z.z],
	]
