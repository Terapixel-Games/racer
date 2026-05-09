extends "res://tests/framework/TestCase.gd"

const TrackGridRoadBuilder = preload("res://scripts/track/TrackGridRoadBuilder.gd")
const RoadGridMapAuthoring = preload("res://scripts/track/RoadGridMapAuthoring.gd")
const RoadGridSpawn = preload("res://scripts/track/RoadGridSpawn.gd")

func test_grid_layout_generates_ordered_route_points() -> void:
	var layout := {
		"origin": Vector3(10.0, 2.0, 20.0),
		"basis": [
			[1.0, 0.0, 0.0],
			[0.0, 1.0, 0.0],
			[0.0, 0.0, 1.0],
		],
		"cell_size": Vector3(16.0, 4.0, 16.0),
		"road_width": 12.0,
		"ordered_route_cells": [Vector3i(0, 0, 0), Vector3i(1, 0, 0), Vector3i(1, 0, 1), Vector3i(0, 0, 1)],
		"checkpoint_route_indices": [0, 1, 2],
	}
	var route := TrackGridRoadBuilder.route_points_from_grid_layout(layout, true)
	assert_equal(route.size(), 4, "Grid route should follow authored cell order")
	assert_equal(route[0], Vector3(18.0, 4.0, 28.0), "Grid route should start at the first authored cell center")
	assert_equal(route[2], Vector3(34.0, 4.0, 44.0), "Grid route should scale cells into world-space route points")
	assert_equal(TrackGridRoadBuilder.checkpoint_indices_from_grid_layout(layout, route), [0, 1, 2], "Grid checkpoints should use authored route indices")

func test_grid_layout_falls_back_to_cells_when_ordered_points_are_empty() -> void:
	var layout := {
		"origin": Vector3(10.0, 2.0, 20.0),
		"basis": [
			[1.0, 0.0, 0.0],
			[0.0, 1.0, 0.0],
			[0.0, 0.0, 1.0],
		],
		"cell_size": Vector3(16.0, 4.0, 16.0),
		"ordered_route_points": [],
		"ordered_route_cells": [Vector3i(0, 0, 0), Vector3i(1, 0, 0), Vector3i(1, 0, 1)],
	}
	var route := TrackGridRoadBuilder.route_points_from_grid_layout(layout, false)
	assert_equal(route.size(), 3, "Grid route should fall back to ordered cells when exported point data is empty")
	assert_equal(route[1], Vector3(34.0, 4.0, 28.0), "Cell fallback should still resolve world-space centers")

func test_grid_layout_generates_spawns_and_sockets() -> void:
	var layout := {
		"origin": Vector3.ZERO,
		"basis": [
			[1.0, 0.0, 0.0],
			[0.0, 1.0, 0.0],
			[0.0, 0.0, 1.0],
		],
		"cell_size": Vector3(16.0, 4.0, 16.0),
		"road_width": 12.0,
		"ordered_route_cells": [Vector3i(0, 0, 0), Vector3i(1, 0, 0), Vector3i(1, 0, 1), Vector3i(0, 0, 1)],
		"item_route_indices": [1],
	}
	var route := TrackGridRoadBuilder.route_points_from_grid_layout(layout, true)
	assert_equal(TrackGridRoadBuilder.spawn_points_from_grid_layout(layout, route).size(), 8, "Grid route should generate an 8-car start grid")
	assert_equal(TrackGridRoadBuilder.sockets_from_grid_layout(layout, route, "item_route_indices", 0).size(), 1, "Grid route should generate tagged sockets")

func test_road_grid_map_exports_spawn_slots() -> void:
	var grid := RoadGridMapAuthoring.new()
	grid.ordered_route_cells = [Vector3i.ZERO, Vector3i(1, 0, 0), Vector3i(2, 0, 0)]
	var slot := RoadGridSpawn.new()
	slot.route_index = 1
	slot.lateral_offset = -1.25
	slot.forward_offset = 2.5
	slot.y_offset = 1.1
	slot.yaw_offset_degrees = 15.0
	var grid_slots: Array[RoadGridSpawn] = [slot]
	grid.spawn_slots = grid_slots
	var layout := grid.to_grid_road_layout(12.0)
	var slots: Array = layout.get("spawn_slots", [])
	assert_equal(slots.size(), 1, "RoadGridMap should export authored spawn slot metadata")
	assert_equal(int((slots[0] as Dictionary).get("route_index", -1)), 1, "Spawn slot export should preserve route index")
	assert_equal(float((slots[0] as Dictionary).get("lateral_offset", 0.0)), -1.25, "Spawn slot export should preserve lateral offset")
	grid.free()

func test_road_grid_map_generates_route_metadata_from_painted_loop() -> void:
	var grid := RoadGridMapAuthoring.new()
	_paint_square_loop(grid)
	var result := grid.regenerate_route_metadata_from_painted_track(4)
	assert_true(bool(result.get("success", false)), "Painted simple loops should regenerate route metadata")
	assert_equal(grid.ordered_route_cells.size(), 4, "Generated route should include every painted loop cell")
	assert_equal(grid.checkpoint_route_indices, [0, 1, 2, 3], "Generated checkpoints should spread across the loop")
	assert_true(_route_cells_are_continuous_loop(grid.ordered_route_cells), "Generated route order should be a continuous closed loop")
	grid.free()

func test_road_grid_map_generates_elevated_route_metadata_from_painted_loop() -> void:
	var grid := RoadGridMapAuthoring.new()
	_paint_square_loop(grid, 1)
	var result := grid.regenerate_route_metadata_from_painted_track(3)
	assert_true(bool(result.get("success", false)), "Painted loops may climb one GridMap floor between adjacent route cells")
	assert_equal(grid.ordered_route_cells.size(), 4, "Elevated generated route should include every painted loop cell")
	assert_equal(grid.checkpoint_route_indices, [0, 1, 2], "Generated elevated checkpoints should spread across the loop")
	assert_true(grid.ordered_route_cells.has(Vector3i(1, 1, 0)), "Generated route should preserve painted Y floors")
	grid.free()

func test_road_grid_map_ignores_stray_painted_cells_when_generating_route() -> void:
	var grid := RoadGridMapAuthoring.new()
	_paint_square_loop(grid)
	grid.set_cell_item(Vector3i(8, 0, 8), 0, 0)
	var result := grid.regenerate_route_metadata_from_painted_track()
	assert_true(bool(result.get("success", false)), "Route generation should use the largest closed loop and ignore disconnected paint")
	assert_equal(grid.ordered_route_cells.size(), 4, "Generated route should not include stray painted cells")
	assert_true(not grid.ordered_route_cells.has(Vector3i(8, 0, 8)), "Generated route should ignore stray painted cells")
	grid.free()

func test_road_grid_map_generates_route_metadata_through_large_corner() -> void:
	var grid := RoadGridMapAuthoring.new()
	grid.set_cell_item(Vector3i(0, 0, 0), 4, 16)
	grid.set_cell_item(Vector3i(2, 0, 0), 1, 10)
	grid.set_cell_item(Vector3i(2, 0, -1), 0, 0)
	grid.set_cell_item(Vector3i(2, 0, -2), 1, 2)
	grid.set_cell_item(Vector3i(1, 0, -2), 0, 22)
	grid.set_cell_item(Vector3i(0, 0, -2), 1, 0)

	var result := grid.regenerate_route_metadata_from_painted_track(3)

	assert_true(bool(result.get("success", false)), "Painted loops should regenerate when a large corner connects two cells away")
	assert_equal(grid.ordered_route_cells.size(), 6, "Generated route should include the large corner anchor plus connected route cells")
	assert_true(grid.ordered_route_cells.has(Vector3i(0, 0, 0)), "Generated route should include the large corner anchor")
	assert_true(_route_cells_allow_large_corner_step(grid.ordered_route_cells), "Generated route should allow a single two-cell step through the large corner")
	grid.free()

func test_grid_layout_uses_authored_spawn_slots() -> void:
	var route: Array[Vector3] = [Vector3.ZERO, Vector3(10.0, 0.0, 0.0), Vector3(20.0, 0.0, 0.0)]
	var layout := {"road_width": 12.0, "spawn_slots": _spawn_slot_layouts(8)}
	var spawns := TrackGridRoadBuilder.spawn_points_from_grid_layout(layout, route)
	assert_equal(spawns.size(), 8, "Eight valid RoadGridMap spawn slots should produce eight runtime spawn transforms")
	assert_equal(spawns[0], Vector4(2.0, 1.2, -1.5, 100.0), "Authored spawn slot should resolve route-relative offsets into Vector4 spawn data")
	assert_equal(spawns[7], Vector4(9.0, 0.8, 1.5, 85.0), "Authored spawn order should be preserved for grid entry")

func test_grid_layout_falls_back_when_spawn_slots_are_incomplete() -> void:
	var route: Array[Vector3] = [Vector3.ZERO, Vector3(10.0, 0.0, 0.0), Vector3(20.0, 0.0, 0.0)]
	var layout := {
		"road_width": 12.0,
		"spawn_slots": _spawn_slot_layouts(7) + [{"route_index": 99}],
	}
	var spawns := TrackGridRoadBuilder.spawn_points_from_grid_layout(layout, route)
	assert_equal(spawns.size(), 8, "Incomplete RoadGridMap spawn slots should fall back to the generated 4x2 start grid")
	assert_equal(spawns[0], Vector4(0.0, 0.8, 1.5, 90.0), "Fallback grid should keep the existing route-start placement")

func test_grid_layout_builds_complete_race_layout() -> void:
	var layout := {
		"origin": Vector3.ZERO,
		"basis": [
			[1.0, 0.0, 0.0],
			[0.0, 1.0, 0.0],
			[0.0, 0.0, 1.0],
		],
		"cell_size": Vector3(16.0, 4.0, 16.0),
		"road_width": 12.0,
		"ordered_route_cells": [Vector3i(0, 0, 0), Vector3i(1, 0, 0), Vector3i(1, 0, 1), Vector3i(0, 0, 1)],
		"checkpoint_route_indices": [0, 1, 2],
		"spawn_slots": _spawn_slot_layouts(8),
		"item_route_indices": [1],
		"hazard_route_indices": [2],
	}
	var race_layout := TrackGridRoadBuilder.race_layout_from_grid_layout(layout, true)
	assert_true(race_layout.is_valid(), "RoadGridMap should adapt into a valid race layout")
	assert_equal(race_layout.source, "road_grid_map", "RoadGridMap race layout should identify the canonical gameplay source")
	assert_equal(race_layout.road_visual_style, "kenney_gridmap", "Grid race layout should use GridMap road visuals")
	assert_equal(race_layout.lap_gate_checkpoint_index, 0, "Grid race layout should use checkpoint zero as the lap gate")
	assert_true(race_layout.road_segment_layout.is_empty(), "Grid race layout should not co-enable segment road authoring")
	assert_equal(race_layout.route_points.size(), 4, "Grid race layout should expose route points")
	assert_equal(race_layout.checkpoint_indices, [0, 1, 2], "Grid race layout should expose checkpoint indices")
	assert_equal(race_layout.spawn_points.size(), 8, "Grid race layout should expose a start grid")
	assert_equal(race_layout.spawn_points[0], Vector4(10.0, 3.2, 6.5, 100.0), "Grid race layout should prefer authored spawn slots")
	assert_equal(race_layout.item_sockets.size(), 0, "MVP GridMap tracks should not expose item sockets")
	assert_equal(race_layout.hazard_sockets.size(), 0, "MVP GridMap tracks should not expose hazard sockets")

func test_kenney_gridmap_mesh_library_exposes_elevation_tiles() -> void:
	var library := load(TrackGridRoadBuilder.DEFAULT_MESH_LIBRARY_PATH) as MeshLibrary
	assert_true(library != null, "GridMap road MeshLibrary should load")
	for item_name in ["roadRamp", "roadRampLong", "roadRampLongCurved", "roadBump"]:
		var item_id := library.find_item_by_name(item_name)
		assert_true(item_id >= 0, "GridMap road MeshLibrary should expose %s for elevated road authoring" % item_name)
		assert_true(library.get_item_mesh(item_id) != null, "%s should have a paintable mesh" % item_name)
		assert_true(library.get_item_mesh_transform(item_id).basis.x.length() >= 16.0, "%s should match the 16-wide road footprint" % item_name)
		assert_true(library.get_item_mesh_transform(item_id).basis.y.length() > 1.0, "%s should scale visibly on Y for elevated road authoring" % item_name)

func test_kenney_gridmap_flat_tiles_keep_scaled_visual_thickness() -> void:
	var library := load(TrackGridRoadBuilder.DEFAULT_MESH_LIBRARY_PATH) as MeshLibrary
	assert_true(library != null, "GridMap road MeshLibrary should load")
	for item_name in ["roadStraight", "roadCornerSmall", "roadStart", "roadStraightLong", "roadCornerLarge"]:
		var item_id := library.find_item_by_name(item_name)
		assert_true(item_id >= 0, "GridMap road MeshLibrary should expose %s" % item_name)
		if item_id < 0:
			continue
		var transform := library.get_item_mesh_transform(item_id)
		var road_bounds := _transformed_surface_aabb(library.get_item_mesh(item_id), transform, "road")
		var full_bounds := _transformed_mesh_aabb(library.get_item_mesh(item_id), transform)
		assert_true(transform.basis.y.length() >= 16.0, "%s should scale its Kenney-authored height with the 16-unit tile footprint" % item_name)
		assert_true(absf(road_bounds.position.y) <= 0.01, "%s road surface should remain at driving height after vertical scaling" % item_name)
		assert_true(full_bounds.size.y >= 0.3, "%s should keep visible tile thickness instead of becoming paper-thin" % item_name)

func test_kenney_gridmap_long_tiles_keep_two_cell_footprint() -> void:
	var library := load(TrackGridRoadBuilder.DEFAULT_MESH_LIBRARY_PATH) as MeshLibrary
	assert_true(library != null, "GridMap road MeshLibrary should load")
	for item_name in ["roadRampLong", "roadRampLongCurved", "roadBump"]:
		var item_id := library.find_item_by_name(item_name)
		assert_true(item_id >= 0, "GridMap road MeshLibrary should expose %s" % item_name)
		if item_id < 0:
			continue
		var item_bounds := _transformed_mesh_aabb(library.get_item_mesh(item_id), library.get_item_mesh_transform(item_id))
		assert_true(is_equal_approx(item_bounds.size.x, 16.0), "%s should stay one lane wide" % item_name)
		assert_true(is_equal_approx(item_bounds.size.z, 32.0), "%s should keep its authored 2x1 footprint instead of being compressed into one cell" % item_name)

func test_kenney_gridmap_ramp_road_surface_reaches_next_elevation() -> void:
	var library := load(TrackGridRoadBuilder.DEFAULT_MESH_LIBRARY_PATH) as MeshLibrary
	assert_true(library != null, "GridMap road MeshLibrary should load")
	var straight_id := library.find_item_by_name("roadStraight")
	var straight_bounds := _transformed_surface_aabb(library.get_item_mesh(straight_id), library.get_item_mesh_transform(straight_id), "road")
	for item_name in ["roadRamp", "roadRampLong", "roadRampLongCurved"]:
		var item_id := library.find_item_by_name(item_name)
		assert_true(item_id >= 0, "GridMap road MeshLibrary should expose %s" % item_name)
		if item_id < 0:
			continue
		var road_bounds := _transformed_surface_aabb(library.get_item_mesh(item_id), library.get_item_mesh_transform(item_id), "road")
		assert_true(absf(road_bounds.position.y - straight_bounds.position.y) <= 0.01, "%s road surface should start at the same height as flat road" % item_name)
		assert_true(absf((road_bounds.position.y + road_bounds.size.y) - (straight_bounds.position.y + 4.0)) <= 0.01, "%s road surface should end flush with flat road one GridMap Y cell higher" % item_name)

func test_road_grid_map_long_tiles_connect_across_two_cells() -> void:
	var grid := RoadGridMapAuthoring.new()
	grid.set_cell_item(Vector3i(0, 0, 0), 6, 16)
	grid.set_cell_item(Vector3i(-1, 0, 0), 0, 16)
	grid.set_cell_item(Vector3i(2, 0, 0), 0, 16)
	var neighbors := grid._route_neighbors_for_cells([Vector3i(-1, 0, 0), Vector3i(0, 0, 0), Vector3i(2, 0, 0)], {
		Vector3i(-1, 0, 0): true,
		Vector3i(0, 0, 0): true,
		Vector3i(2, 0, 0): true,
	})
	var long_neighbors: Array = neighbors.get(Vector3i(0, 0, 0), [])
	assert_true(long_neighbors.has(Vector3i(-1, 0, 0)), "Long GridMap tiles should connect to the cell immediately behind their anchor")
	assert_true(long_neighbors.has(Vector3i(2, 0, 0)), "Long GridMap tiles should connect two cells forward so 2x1 ramps meet the next road tile")
	grid.free()

func test_kenney_gridmap_start_tile_matches_cell_footprint() -> void:
	var library := load(TrackGridRoadBuilder.DEFAULT_MESH_LIBRARY_PATH) as MeshLibrary
	assert_true(library != null, "GridMap road MeshLibrary should load")
	var straight_id := library.find_item_by_name("roadStraight") if library != null else -1
	var start_id := library.find_item_by_name("roadStart") if library != null else -1
	assert_true(straight_id >= 0, "GridMap road MeshLibrary should expose roadStraight")
	assert_true(start_id >= 0, "GridMap road MeshLibrary should expose roadStart")
	if straight_id < 0 or start_id < 0:
		return
	var straight_transform := library.get_item_mesh_transform(straight_id)
	var start_transform := library.get_item_mesh_transform(start_id)
	assert_true(library.get_item_mesh(start_id) == library.get_item_mesh(straight_id), "roadStart should reuse the flat straight tile mesh so it does not place a bump in front of racers")
	assert_true(is_equal_approx(start_transform.basis.x.length(), straight_transform.basis.x.length()), "roadStart should match straight tile width so the start line stays centered on the GridMap cell")
	assert_true(is_equal_approx(start_transform.basis.z.length(), straight_transform.basis.z.length()), "roadStart should match straight tile length so it does not shift into the next cell")
	assert_true(start_transform.origin.distance_to(straight_transform.origin) <= 0.05, "roadStart should use the same cell-local origin as roadStraight")

func test_grid_collision_mesh_uses_ramp_tile_geometry() -> void:
	var layout := {
		"mesh_library_path": TrackGridRoadBuilder.DEFAULT_MESH_LIBRARY_PATH,
		"cell_size": Vector3(16.0, 4.0, 16.0),
		"cells": [
			{
				"cell": Vector3i.ZERO,
				"item": 5,
				"orientation": 0,
				"position": Vector3.ZERO,
			},
		],
	}
	var mesh := TrackGridRoadBuilder.build_grid_collision_mesh(layout)
	assert_true(mesh.get_surface_count() > 0, "Grid collision mesh should include painted tile geometry")
	assert_true(mesh.get_aabb().size.y > 3.5, "Ramp collision should preserve the ramp height instead of flattening to the route ribbon")

func test_grid_boundary_walls_skip_same_height_internal_edges() -> void:
	var layout := _boundary_layout([
		{"cell": Vector3i(0, 0, 0), "item": TrackGridRoadBuilder.TILE_STRAIGHT},
		{"cell": Vector3i(1, 0, 0), "item": TrackGridRoadBuilder.TILE_STRAIGHT},
	], [Vector3i(0, 0, 0), Vector3i(1, 0, 0)])
	var segments := TrackGridRoadBuilder.boundary_wall_segments_from_grid_layout(layout, 3.0, 0.6)
	assert_true(segments.size() > 0, "Exposed GridMap edges should generate boundary walls")
	assert_true(not _has_wall_for_edge(segments, Vector3i(0, 0, 0), Vector3i.RIGHT), "Same-height connected route cells should not get an internal wall")
	assert_true(not _has_wall_for_edge(segments, Vector3i(1, 0, 0), Vector3i.LEFT), "The opposite side of the same-height connection should also stay open")

func test_grid_boundary_walls_generate_partial_wall_below_upper_neighbor() -> void:
	var layout := _boundary_layout([
		{"cell": Vector3i(0, 0, 0), "item": TrackGridRoadBuilder.TILE_STRAIGHT},
		{"cell": Vector3i(1, 1, 0), "item": TrackGridRoadBuilder.TILE_STRAIGHT},
	], [Vector3i(0, 0, 0), Vector3i(1, 1, 0)])
	var segments := TrackGridRoadBuilder.boundary_wall_segments_from_grid_layout(layout, 3.0, 0.6)
	var partial := _first_wall_for_edge(segments, Vector3i(0, 0, 0), Vector3i.RIGHT)
	assert_true(not partial.is_empty(), "A vertically separated upper neighbor should not suppress lower-road containment")
	if not partial.is_empty():
		var bottom := float(partial.get("bottom", 0.0))
		var height := float(partial.get("height", 0.0))
		assert_true(bottom + height < 6.0, "Partial lower wall should stay below the upper road surface")

func test_grid_boundary_walls_cover_long_tile_footprints() -> void:
	var layout := _boundary_layout([
		{"cell": Vector3i(0, 0, 0), "item": TrackGridRoadBuilder.TILE_RAMP_LONG},
	], [Vector3i(0, 0, 0)])
	var segments := TrackGridRoadBuilder.boundary_wall_segments_from_grid_layout(layout, 3.0, 0.6)
	assert_true(_has_any_wall_for_cell(segments, Vector3i(0, 0, 1)), "Long and ramp-long tiles should generate walls across their inferred second footprint cell")

func test_grid_boundary_walls_sample_ramp_elevation() -> void:
	var layout := _boundary_layout([
		{"cell": Vector3i(0, 0, 0), "item": TrackGridRoadBuilder.TILE_RAMP},
	], [Vector3i(0, 0, 0)])
	var segments := TrackGridRoadBuilder.boundary_wall_segments_from_grid_layout(layout, 3.0, 0.6)
	var found_sloped_segment := false
	for segment in segments:
		if (segment as Dictionary).get("cell", Vector3i.ZERO) == Vector3i(0, 0, 0) and float((segment as Dictionary).get("height", 0.0)) > 3.2:
			found_sloped_segment = true
			break
	assert_true(found_sloped_segment, "Ramp boundary walls should sample ramp endpoint heights instead of flattening to one elevation")

func test_grid_runtime_ignores_painted_cells_outside_route() -> void:
	var layout := {
		"mesh_library_path": TrackGridRoadBuilder.DEFAULT_MESH_LIBRARY_PATH,
		"cell_size": Vector3(16.0, 4.0, 16.0),
		"cells": [
			{"cell": Vector3i(0, 0, 0), "item": 0, "orientation": 0},
			{"cell": Vector3i(1, 0, 0), "item": 0, "orientation": 0},
			{"cell": Vector3i(9, 0, 9), "item": 0, "orientation": 0},
		],
		"ordered_route_cells": [Vector3i(0, 0, 0), Vector3i(1, 0, 0)],
	}
	var grid := TrackGridRoadBuilder.build_grid_road(layout) as GridMap
	assert_true(grid != null, "Grid runtime should build a GridMap when MeshLibrary data is available")
	assert_true(grid.get_cell_item(Vector3i(0, 0, 0)) >= 0, "Runtime GridRoad should include route cells")
	assert_true(grid.get_cell_item(Vector3i(1, 0, 0)) >= 0, "Runtime GridRoad should include route cells")
	assert_equal(grid.get_cell_item(Vector3i(9, 0, 9)), -1, "Runtime GridRoad should hide painted cells outside the resolved route")
	grid.queue_free()

func _spawn_slot_layouts(count: int) -> Array[Dictionary]:
	var slots: Array[Dictionary] = []
	for i in range(count):
		slots.append({
			"route_index": 0,
			"lateral_offset": 1.5 if i % 2 == 0 else -1.5,
			"forward_offset": 2.0 + float(i),
			"y_offset": 1.2 if i < 2 else 0.8,
			"yaw_offset_degrees": 10.0 if i % 2 == 0 else -5.0,
		})
	return slots

func _boundary_layout(cells: Array, route_cells: Array[Vector3i]) -> Dictionary:
	var out_cells: Array[Dictionary] = []
	for value in cells:
		var data := (value as Dictionary).duplicate(true)
		var yaw := float(data.get("yaw", 0.0))
		var basis := Basis(Vector3.UP, yaw)
		data["orientation_basis"] = _basis_to_array(basis)
		data["orientation"] = 0
		out_cells.append(data)
	return {
		"cell_size": Vector3(16.0, 4.0, 16.0),
		"basis": _basis_to_array(Basis.IDENTITY),
		"road_width": 16.0,
		"cells": out_cells,
		"ordered_route_cells": route_cells,
	}

func _has_wall_for_edge(segments: Array, cell: Vector3i, direction: Vector3i) -> bool:
	return not _first_wall_for_edge(segments, cell, direction).is_empty()

func _first_wall_for_edge(segments: Array, cell: Vector3i, direction: Vector3i) -> Dictionary:
	for segment in segments:
		var data := segment as Dictionary
		if data.get("cell", Vector3i.ZERO) == cell and data.get("direction", Vector3i.ZERO) == direction:
			return data
	return {}

func _has_any_wall_for_cell(segments: Array, cell: Vector3i) -> bool:
	for segment in segments:
		if (segment as Dictionary).get("cell", Vector3i.ZERO) == cell:
			return true
	return false

func _basis_to_array(basis: Basis) -> Array:
	return [
		[basis.x.x, basis.x.y, basis.x.z],
		[basis.y.x, basis.y.y, basis.y.z],
		[basis.z.x, basis.z.y, basis.z.z],
	]

func _paint_square_loop(grid: GridMap, raised_y := 0) -> void:
	grid.set_cell_item(Vector3i(0, 0, 0), 1, 0)
	grid.set_cell_item(Vector3i(1, raised_y, 0), 1, 22)
	grid.set_cell_item(Vector3i(1, raised_y, 1), 1, 10)
	grid.set_cell_item(Vector3i(0, 0, 1), 1, 16)

func _route_cells_are_continuous_loop(cells: Array[Vector3i]) -> bool:
	for i in range(cells.size()):
		var current := cells[i]
		var next := cells[(i + 1) % cells.size()]
		var delta := next - current
		if abs(delta.x) + abs(delta.z) != 1:
			return false
		if abs(delta.y) > 1:
			return false
	return true

func _route_cells_allow_large_corner_step(cells: Array[Vector3i]) -> bool:
	var two_cell_steps := 0
	for i in range(cells.size()):
		var current := cells[i]
		var next := cells[(i + 1) % cells.size()]
		var delta := next - current
		var horizontal_distance: int = abs(delta.x) + abs(delta.z)
		if horizontal_distance == 2:
			two_cell_steps += 1
		elif horizontal_distance != 1:
			return false
		if abs(delta.y) > 1:
			return false
	return two_cell_steps == 2

func _transformed_mesh_aabb(mesh: Mesh, transform: Transform3D) -> AABB:
	if mesh == null:
		return AABB()
	var aabb := mesh.get_aabb()
	var points := [
		aabb.position,
		aabb.position + Vector3(aabb.size.x, 0.0, 0.0),
		aabb.position + Vector3(0.0, aabb.size.y, 0.0),
		aabb.position + Vector3(0.0, 0.0, aabb.size.z),
		aabb.position + Vector3(aabb.size.x, aabb.size.y, 0.0),
		aabb.position + Vector3(aabb.size.x, 0.0, aabb.size.z),
		aabb.position + Vector3(0.0, aabb.size.y, aabb.size.z),
		aabb.position + aabb.size,
	]
	var out := AABB(transform * points[0], Vector3.ZERO)
	for i in range(1, points.size()):
		out = out.expand(transform * points[i])
	return out

func _transformed_surface_aabb(mesh: Mesh, transform: Transform3D, surface_name: String) -> AABB:
	if mesh == null:
		return AABB()
	var found := false
	var out := AABB()
	for surface_index in range(mesh.get_surface_count()):
		if mesh.surface_get_name(surface_index) != surface_name:
			continue
		var arrays := mesh.surface_get_arrays(surface_index)
		var vertices := arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
		for vertex in vertices:
			var point := transform * vertex
			if not found:
				out = AABB(point, Vector3.ZERO)
				found = true
			else:
				out = out.expand(point)
	return out
