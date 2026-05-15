extends "res://tests/framework/TestCase.gd"

const TrackCatalog = preload("res://scripts/track/TrackCatalog.gd")
const TrackDefinition = preload("res://scripts/track/TrackDefinition.gd")

const HOME_YARD_MAP_SCENE := "res://assets/gameplay/tracks/home_yard_v3/home_yard_v3_map.tscn"
const HOME_YARD_VERSION := "home_yard_residential_openworld_v3_2026_05_12"

func test_kitchen_definition_validates() -> void:
	var definition := TrackCatalog.get_definition("kitchen")
	assert_true(definition != null, "Kitchen definition should load")
	assert_equal(definition.validate(), [], "Kitchen definition should be valid")
	assert_equal(definition.id, "kitchen", "Kitchen should keep the public course id inside the shared home-yard map")
	assert_equal(str(definition.get_meta("track_map_id", "")), "home_yard_v3", "Kitchen should resolve through the scratch-built shared home-yard v3 map")
	assert_equal(str(definition.get_meta("track_mode_id", "")), "kitchen", "Kitchen should resolve the Kitchen home-yard mode")
	assert_equal(definition.version, HOME_YARD_VERSION, "Kitchen should use the shared home-yard package version")
	assert_equal(definition.laps, 3, "Kitchen should run 3 laps")
	assert_equal(definition.road_visual_style, "kenney_gridmap", "Kitchen should pilot GridMap-authored Kenney roads")
	assert_true(not definition.road_grid_layout.is_empty(), "Kitchen should store authored RoadGridMap layout data")
	assert_true(definition.route_points.size() >= (definition.road_grid_layout.get("ordered_route_cells", []) as Array).size(), "Kitchen route should be generated from authored grid cells")
	assert_equal(definition.checkpoint_indices.size(), 6, "Kitchen should expose the shared map checkpoint set")
	assert_equal(definition.item_sockets.size(), 0, "MVP Kitchen should not expose item sockets")
	assert_equal(definition.hazard_sockets.size(), 0, "MVP Kitchen should not expose hazard sockets")
	assert_true(_route_fits_ground_bounds(definition), "Kitchen route should stay within the authored ground bounds")
	assert_equal(definition.reset_mode, "instant_pop", "Kitchen should use instant pop-back resets")
	assert_true(definition.out_of_bounds_y < definition.floor_visual_y, "Kitchen out-of-bounds threshold should sit below the authored floor")
	assert_equal(definition.dressing_scene_path, HOME_YARD_MAP_SCENE, "Kitchen should load the shared home-yard dressing scene")
	assert_equal(definition.preview_dressing_scene_path, HOME_YARD_MAP_SCENE, "Kitchen should use the shared home-yard preview dressing scene")
	assert_equal(definition.shortcut_gates.size(), 0, "MVP Kitchen should not expose shortcuts")
	assert_true(definition.stage_props.size() >= 5, "Kitchen should export home-yard route landmarks")
	assert_true(_has_stage_prop(definition, "kitchen_start_gate"), "Kitchen should export a shared-scene start gate")
	assert_true(_has_stage_prop(definition, "kitchen_finish_language_panel"), "Kitchen should export start/finish route language")
	assert_true(definition.stage_interactions.size() >= 2, "Kitchen should export shared-scene route interactions")
	assert_equal(definition.surface_segments.size(), 0, "MVP Kitchen should not export surface audio segment assignments")
	assert_equal(definition.audio_zones.size(), 4, "Kitchen should export authored audio zones")
	assert_equal(str(definition.audio_ids.get("sink_splash", "")), "res://assets/source/audio/canva/tracks/kitchen/kitchen_sink_water.mp3", "Kitchen sink zone should use the supplied sink water audio")
	assert_equal(str(definition.audio_ids.get("stove_sizzle", "")), "res://assets/source/audio/canva/tracks/kitchen/kitchen_oven_sizzle.mp3", "Kitchen stove zone should use the converted oven sizzle audio")
	assert_true(_route_fits_ground_bounds(definition), "Kitchen generated route should stay inside the authored race surface bounds")

func test_validation_rejects_missing_route() -> void:
	var definition := _base_definition()
	definition.route_points = []
	assert_true(_has_error(definition.validate(), "route"), "Missing route should be rejected")

func test_validation_rejects_missing_lap_gate() -> void:
	var definition := _base_definition()
	definition.lap_gate_checkpoint_index = 8
	assert_true(_has_error(definition.validate(), "lap gate"), "Invalid lap gate should be rejected")

func test_validation_rejects_too_few_spawns() -> void:
	var definition := _base_definition()
	definition.spawn_points = [Vector4(0, 0.8, 0, 0)]
	assert_true(_has_error(definition.validate(), "8 spawn"), "Track must require 8 spawn points")

func test_validation_rejects_off_road_spawns() -> void:
	var definition := _base_definition()
	definition.spawn_points[0] = Vector4(0, 0.8, -20, 0)
	assert_true(_has_error(definition.validate(), "outside the road"), "Track must reject spawn points outside road bounds")

func test_validation_rejects_non_monotonic_checkpoints() -> void:
	var definition := _base_definition()
	definition.checkpoint_indices = [0, 2, 1]
	assert_true(_has_error(definition.validate(), "strictly increasing"), "Checkpoints should follow route order")

func test_validation_accepts_gridmap_mvp_route() -> void:
	var definition := _base_definition()
	assert_equal(definition.validate(), [], "GridMap MVP route should validate")

func test_validation_accepts_stage_interactions_and_exports_metadata() -> void:
	var definition := _base_definition()
	definition.stage_interactions = [{
		"id": "test_boost",
		"action": "boost",
		"shape": "box",
		"position": Vector3(4, 1, 0),
		"yaw_degrees": 0.0,
		"size": Vector3(6, 3, 8),
		"duration": 0.5,
		"cooldown": 1.0,
		"boost_force": 72.0,
	}]
	assert_equal(definition.validate(), [], "Valid stage interactions should not break GridMap validation")
	var exported := definition.to_metadata().get("stage_interactions", []) as Array
	assert_equal(exported.size(), 1, "Metadata should export stage interactions")
	assert_equal(str((exported[0] as Dictionary).get("id", "")), "test_boost", "Metadata should preserve interaction ids")
	assert_equal(((exported[0] as Dictionary).get("size", []) as Array).size(), 3, "Metadata should serialize interaction extents")

func test_validation_rejects_invalid_stage_interactions() -> void:
	var definition := _base_definition()
	definition.stage_interactions = [{
		"id": "bad_zone",
		"action": "teleport",
		"shape": "box",
		"size": Vector3.ZERO,
	}]
	var errors := definition.validate()
	assert_true(_has_error(errors, "action"), "Stage interactions should reject unknown actions")
	assert_true(_has_error(errors, "box size"), "Stage interactions should reject empty box extents")

func test_validation_rejects_backtracking_alternate_route() -> void:
	var definition := _base_definition()
	definition.alternate_routes = [{
		"id": "bad_lane",
		"entry_checkpoint_index": 2,
		"exit_checkpoint_index": 1,
		"points": [Vector3(20, 0.5, 20), Vector3(20, 0.5, 0)],
	}]
	assert_true(_has_error(definition.validate(), "after entry"), "Alternate routes should rejoin at a later checkpoint")

func _base_definition() -> TrackDefinition:
	var definition := TrackDefinition.new()
	definition.id = "test"
	definition.display_name = "Test Track"
	definition.laps = 2
	definition.closed_loop = true
	definition.road_width = 12.0
	definition.track_source_id = "road_grid_map"
	definition.road_visual_style = "kenney_gridmap"
	definition.road_grid_layout = {"ordered_route_cells": [Vector3i(0, 0, 0), Vector3i(1, 0, 0), Vector3i(1, 0, 1), Vector3i(0, 0, 1)]}
	definition.route_points = [
		Vector3(0, 0.5, 0),
		Vector3(20, 0.5, 0),
		Vector3(20, 0.5, 20),
		Vector3(0, 0.5, 20),
	]
	definition.checkpoint_indices = [0, 1, 2]
	definition.lap_gate_checkpoint_index = 0
	definition.item_sockets = [Vector4(3, 0.8, 3, 0)]
	definition.spawn_points = [
		Vector4(0, 0.8, -2, 0),
		Vector4(2, 0.8, -2, 0),
		Vector4(4, 0.8, -2, 0),
		Vector4(6, 0.8, -2, 0),
		Vector4(0, 0.8, -5, 0),
		Vector4(2, 0.8, -5, 0),
		Vector4(4, 0.8, -5, 0),
		Vector4(6, 0.8, -5, 0),
	]
	return definition

func _has_error(errors: Array[String], needle: String) -> bool:
	for error in errors:
		if error.to_lower().contains(needle.to_lower()):
			return true
	return false

func _has_stage_prop(definition: TrackDefinition, prop_id: String) -> bool:
	return not _stage_prop(definition, prop_id).is_empty()

func _has_any_stage_prop(definition: TrackDefinition, prop_ids: Array[String]) -> bool:
	for prop_id in prop_ids:
		if _has_stage_prop(definition, prop_id):
			return true
	return false

func _stage_prop(definition: TrackDefinition, prop_id: String) -> Dictionary:
	for prop in definition.stage_props:
		if str(prop.get("id", "")) == prop_id:
			return prop
	return {}

func _route_height_range(route_points: Array[Vector3]) -> float:
	var min_y := INF
	var max_y := -INF
	for point in route_points:
		min_y = minf(min_y, point.y)
		max_y = maxf(max_y, point.y)
	return max_y - min_y

func _route_fits_ground_bounds(definition: TrackDefinition) -> bool:
	var half_width := definition.ground_size.x * 0.5
	var half_depth := definition.ground_size.y * 0.5
	var clearance := definition.road_width * 0.5
	for point in definition.route_points:
		if absf(point.x) + clearance > half_width:
			return false
		if absf(point.z) + clearance > half_depth:
			return false
	return true

func _route_has_fridge_top_section(route_points: Array[Vector3]) -> bool:
	var fridge_top_points := 0
	for point in route_points:
		if point.x >= 120.0 and point.x <= 132.0 and point.z >= 18.0 and point.z <= 52.0 and point.y >= 14.0:
			fridge_top_points += 1
	return fridge_top_points >= 2

func _route_has_no_unresolved_self_intersections(route_points: Array[Vector3], closed_loop: bool, min_vertical_clearance: float) -> bool:
	var segment_count := route_points.size() if closed_loop else route_points.size() - 1
	for i in range(segment_count):
		for j in range(i + 1, segment_count):
			if abs(i - j) <= 1:
				continue
			if closed_loop and i == 0 and j == segment_count - 1:
				continue
			var gap := _segment_crossing_height_gap(
				route_points[i],
				route_points[(i + 1) % route_points.size()],
				route_points[j],
				route_points[(j + 1) % route_points.size()]
			)
			if gap >= 0.0 and gap < min_vertical_clearance:
				return false
	return true

func _overpass_crossing_count(route_points: Array[Vector3], closed_loop: bool, min_vertical_clearance: float) -> int:
	var count := 0
	var segment_count := route_points.size() if closed_loop else route_points.size() - 1
	for i in range(segment_count):
		for j in range(i + 1, segment_count):
			if abs(i - j) <= 1:
				continue
			if closed_loop and i == 0 and j == segment_count - 1:
				continue
			var gap := _segment_crossing_height_gap(
				route_points[i],
				route_points[(i + 1) % route_points.size()],
				route_points[j],
				route_points[(j + 1) % route_points.size()]
			)
			if gap >= min_vertical_clearance:
				count += 1
	return count

func _segment_crossing_height_gap(a3: Vector3, b3: Vector3, c3: Vector3, d3: Vector3) -> float:
	var a := Vector2(a3.x, a3.z)
	var b := Vector2(b3.x, b3.z)
	var c := Vector2(c3.x, c3.z)
	var d := Vector2(d3.x, d3.z)
	if not _segments_intersect(a, b, c, d):
		return -1.0
	var r := b - a
	var s := d - c
	var denom := _cross2(r, s)
	if absf(denom) < 0.001:
		return 0.0
	var t := _cross2(c - a, s) / denom
	var u := _cross2(c - a, r) / denom
	if t < -0.001 or t > 1.001 or u < -0.001 or u > 1.001:
		return -1.0
	var y_a := lerpf(a3.y, b3.y, clampf(t, 0.0, 1.0))
	var y_b := lerpf(c3.y, d3.y, clampf(u, 0.0, 1.0))
	return absf(y_a - y_b)

func _route_follows_counter_or_island_space(route_points: Array[Vector3]) -> bool:
	for point in route_points:
		var on_front_or_back := absf(point.z + 84.0) <= 16.0 or absf(point.z - 84.0) <= 16.0
		var on_left_or_right := absf(point.x + 116.0) <= 28.0 or absf(point.x - 122.0) <= 28.0
		var on_island_loop := point.x >= -42.0 and point.x <= 90.0 and point.z >= -74.0 and point.z <= 8.0
		if not (on_front_or_back or on_left_or_right or on_island_loop):
			return false
	return true

func _segments_intersect(a: Vector2, b: Vector2, c: Vector2, d: Vector2) -> bool:
	var o1 := _orientation(a, b, c)
	var o2 := _orientation(a, b, d)
	var o3 := _orientation(c, d, a)
	var o4 := _orientation(c, d, b)
	if o1 * o2 < 0.0 and o3 * o4 < 0.0:
		return true
	return _point_on_segment(a, b, c) or _point_on_segment(a, b, d) or _point_on_segment(c, d, a) or _point_on_segment(c, d, b)

func _orientation(a: Vector2, b: Vector2, c: Vector2) -> float:
	return _cross2(b - a, c - a)

func _cross2(a: Vector2, b: Vector2) -> float:
	return a.x * b.y - a.y * b.x

func _point_on_segment(a: Vector2, b: Vector2, point: Vector2) -> bool:
	if absf(_orientation(a, b, point)) > 0.001:
		return false
	return point.x >= minf(a.x, b.x) - 0.001 and point.x <= maxf(a.x, b.x) + 0.001 and point.y >= minf(a.y, b.y) - 0.001 and point.y <= maxf(a.y, b.y) + 0.001
