extends "res://tests/framework/TestCase.gd"

const TrackGridRoadBuilder = preload("res://scripts/track/TrackGridRoadBuilder.gd")

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
	assert_equal(TrackGridRoadBuilder.start_grid_from_grid_layout(layout, route).size(), 8, "Grid route should generate an 8-car start grid")
	assert_equal(TrackGridRoadBuilder.sockets_from_grid_layout(layout, route, "item_route_indices", 0).size(), 1, "Grid route should generate tagged sockets")
