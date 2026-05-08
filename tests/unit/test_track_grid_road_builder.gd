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
	assert_equal(route[0], Vector3(10.0, 2.0, 20.0), "Grid route should start at the first authored cell center")
	assert_equal(route[2], Vector3(26.0, 2.0, 36.0), "Grid route should scale cells into world-space route points")
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
	assert_equal(route[1], Vector3(26.0, 2.0, 20.0), "Cell fallback should still resolve world-space centers")

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
	assert_equal(race_layout.spawn_points[0], Vector4(2.0, 1.2, -1.5, 100.0), "Grid race layout should prefer authored spawn slots")
	assert_equal(race_layout.item_sockets.size(), 1, "Grid race layout should expose item sockets")
	assert_equal(race_layout.hazard_sockets.size(), 1, "Grid race layout should expose hazard sockets")

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
