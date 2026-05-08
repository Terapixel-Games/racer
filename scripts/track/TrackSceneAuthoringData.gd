extends RefCounted
class_name TrackSceneAuthoringData

const TrackDefinition = preload("res://scripts/track/TrackDefinition.gd")
const TrackGridRoadBuilder = preload("res://scripts/track/TrackGridRoadBuilder.gd")
const RaceLayout = preload("res://scripts/track/RaceLayout.gd")

const TRACK_NODE_NAME := "Track"
const ROAD_SOURCE_AUTO := "auto"
const ROAD_SOURCE_ROAD_GRID_MAP := "road_grid_map"
const ROAD_SOURCE_GRID := "grid"
const MVP_CELL_SIZE := 16.0
const MVP_MIN_HALF_EXTENT := 4
const MVP_MAX_HALF_EXTENT := 9

static func apply_to_definition(source: TrackDefinition, mode_config: Dictionary = {}) -> TrackDefinition:
	if source == null:
		return null
	var definition := source.duplicate(true) as TrackDefinition
	var road_source := _road_source_for(definition, mode_config)
	if definition.dressing_scene_path.strip_edges().is_empty():
		var fallback_layout := TrackGridRoadBuilder.race_layout_from_grid_layout(_mvp_grid_layout_from_definition(definition), definition.closed_loop)
		if fallback_layout != null and fallback_layout.is_valid():
			_apply_race_layout(definition, fallback_layout)
		return definition
	var packed := load(definition.dressing_scene_path)
	if not (packed is PackedScene):
		var fallback_layout := TrackGridRoadBuilder.race_layout_from_grid_layout(_mvp_grid_layout_from_definition(definition), definition.closed_loop)
		if fallback_layout != null and fallback_layout.is_valid():
			_apply_race_layout(definition, fallback_layout)
		return definition
	var scene_root := (packed as PackedScene).instantiate()
	if not (scene_root is Node3D):
		if scene_root != null:
			scene_root.queue_free()
		return definition
	_apply_scene_markers(definition, scene_root as Node3D, road_source)
	scene_root.queue_free()
	return definition

static func _apply_scene_markers(definition: TrackDefinition, scene_root: Node3D, road_source: String) -> void:
	var race_layout := _resolve_race_layout(definition, scene_root, road_source)
	if race_layout != null and race_layout.is_valid():
		_apply_race_layout(definition, race_layout)
	var stage_props := _collect_stage_props(scene_root)
	if not stage_props.is_empty():
		definition.stage_props = stage_props

static func _resolve_race_layout(definition: TrackDefinition, scene_root: Node3D, road_source: String) -> RaceLayout:
	var grid_layout := _race_layout_from_grid(scene_root, definition)
	if grid_layout != null and grid_layout.is_valid():
		return grid_layout
	return TrackGridRoadBuilder.race_layout_from_grid_layout(_mvp_grid_layout_from_definition(definition), definition.closed_loop)

static func _race_layout_from_grid(scene_root: Node3D, definition: TrackDefinition) -> RaceLayout:
	var grid_layout := _collect_road_grid(scene_root, definition.road_width)
	if grid_layout.is_empty():
		return null
	var race_layout := TrackGridRoadBuilder.race_layout_from_grid_layout(grid_layout, definition.closed_loop)
	return race_layout if race_layout.is_valid() else null

static func _apply_race_layout(definition: TrackDefinition, race_layout: RaceLayout) -> void:
	if not race_layout.road_visual_style.strip_edges().is_empty():
		definition.road_visual_style = race_layout.road_visual_style
	definition.road_grid_layout = race_layout.road_grid_layout.duplicate(true)
	if definition.road_grid_layout.has("road_width"):
		definition.road_width = float(definition.road_grid_layout.get("road_width", definition.road_width))
	definition.road_segment_layout = race_layout.road_segment_layout.duplicate(true)
	definition.route_points = race_layout.route_points.duplicate()
	if race_layout.checkpoint_indices.size() >= 3 and _indices_strictly_increasing(race_layout.checkpoint_indices):
		definition.checkpoint_indices = race_layout.checkpoint_indices.duplicate()
		definition.lap_gate_checkpoint_index = race_layout.lap_gate_checkpoint_index
	if race_layout.spawn_points.size() >= 8:
		definition.spawn_points = race_layout.spawn_points.duplicate()
	definition.item_sockets = []
	definition.hazard_sockets = []
	definition.shortcut_gates = []
	definition.alternate_routes = []
	definition.surface_segments = []
	definition.track_source_id = race_layout.source
	definition.progress_rule_id = race_layout.progress_rule_id
	definition.win_condition_id = race_layout.win_condition_id
	definition.set_meta("resolved_race_layout_source", race_layout.source)
	definition.set_meta("resolved_track_source", race_layout.source)
	definition.set_meta("progress_rule_id", race_layout.progress_rule_id)
	definition.set_meta("win_condition_id", race_layout.win_condition_id)

static func _road_source_for(definition: TrackDefinition, mode_config: Dictionary) -> String:
	var source := str(mode_config.get("road_source", ""))
	if source.strip_edges().is_empty() and definition.has_meta("road_source"):
		source = str(definition.get_meta("road_source", ""))
	return canonical_road_source(source)

static func canonical_road_source(value: String) -> String:
	var source := value.strip_edges().to_lower()
	match source:
		ROAD_SOURCE_ROAD_GRID_MAP, ROAD_SOURCE_GRID, "gridmap", "kenney_gridmap":
			return ROAD_SOURCE_ROAD_GRID_MAP
		_:
			return ROAD_SOURCE_AUTO

static func _collect_road_grid(root: Node3D, road_width: float) -> Dictionary:
	var grid := _find_authoring_holder(root, "RoadGridMap")
	if grid == null or not grid.has_method("to_grid_road_layout"):
		return {}
	var layout := grid.call("to_grid_road_layout", road_width) as Dictionary
	if (layout.get("ordered_route_cells", []) as Array).size() < 3:
		return {}
	return layout

static func _mvp_grid_layout_from_definition(definition: TrackDefinition) -> Dictionary:
	var bounds := _route_bounds(definition.route_points, definition.ground_size)
	var center := bounds.get("center", Vector3.ZERO) as Vector3
	var half_x := int(bounds.get("half_x_cells", MVP_MIN_HALF_EXTENT))
	var half_z := int(bounds.get("half_z_cells", MVP_MIN_HALF_EXTENT))
	var route_cells: Array[Vector3i] = []
	for x in range(-half_x, half_x + 1):
		route_cells.append(Vector3i(x, 0, -half_z))
	for z in range(-half_z + 1, half_z + 1):
		route_cells.append(Vector3i(half_x, 0, z))
	for x in range(half_x - 1, -half_x - 1, -1):
		route_cells.append(Vector3i(x, 0, half_z))
	for z in range(half_z - 1, -half_z, -1):
		route_cells.append(Vector3i(-half_x, 0, z))
	var route_points: Array[Vector3] = []
	var cells: Array[Dictionary] = []
	for i in range(route_cells.size()):
		var cell := route_cells[i]
		var position := center + Vector3(float(cell.x) * MVP_CELL_SIZE, 0.0, float(cell.z) * MVP_CELL_SIZE)
		route_points.append(position)
		var next_cell := route_cells[(i + 1) % route_cells.size()]
		var direction := Vector3(float(next_cell.x - cell.x), 0.0, float(next_cell.z - cell.z))
		var yaw := atan2(direction.x, direction.z) if direction.length_squared() > 0.001 else 0.0
		var basis := Basis(Vector3.UP, yaw)
		cells.append({
			"cell": cell,
			"item": TrackGridRoadBuilder.TILE_STRAIGHT,
			"orientation": 0,
			"orientation_basis": _basis_to_array(basis),
			"position": position,
		})
	var checkpoints: Array[int] = []
	var checkpoint_count := 6
	for i in range(checkpoint_count):
		var index := int(round(float(i) * float(route_points.size()) / float(checkpoint_count)))
		index = clampi(index, 0, route_points.size() - 1)
		if not checkpoints.has(index):
			checkpoints.append(index)
	return {
		"origin": center,
		"basis": _basis_to_array(Basis.IDENTITY),
		"cell_size": Vector3(MVP_CELL_SIZE, 4.0, MVP_CELL_SIZE),
		"road_width": definition.road_width,
		"cells": cells,
		"ordered_route_cells": route_cells,
		"ordered_route_points": route_points,
		"checkpoint_route_indices": checkpoints,
		"spawn_slots": [],
		"item_route_indices": [],
		"hazard_route_indices": [],
	}

static func _route_bounds(route_points: Array[Vector3], ground_size: Vector2) -> Dictionary:
	var min_x := INF
	var max_x := -INF
	var min_z := INF
	var max_z := -INF
	var y_total := 0.0
	var count := 0
	for point in route_points:
		min_x = minf(min_x, point.x)
		max_x = maxf(max_x, point.x)
		min_z = minf(min_z, point.z)
		max_z = maxf(max_z, point.z)
		y_total += point.y
		count += 1
	if count == 0:
		min_x = ground_size.x * -0.28
		max_x = ground_size.x * 0.28
		min_z = ground_size.y * -0.28
		max_z = ground_size.y * 0.28
	var center := Vector3((min_x + max_x) * 0.5, y_total / float(maxi(count, 1)), (min_z + max_z) * 0.5)
	var half_x := clampi(int(ceil(maxf(max_x - min_x, ground_size.x * 0.45) * 0.5 / MVP_CELL_SIZE)), MVP_MIN_HALF_EXTENT, MVP_MAX_HALF_EXTENT)
	var half_z := clampi(int(ceil(maxf(max_z - min_z, ground_size.y * 0.45) * 0.5 / MVP_CELL_SIZE)), MVP_MIN_HALF_EXTENT, MVP_MAX_HALF_EXTENT)
	return {
		"center": center,
		"half_x_cells": half_x,
		"half_z_cells": half_z,
	}

static func _collect_stage_props(root: Node) -> Array[Dictionary]:
	var props: Array[Dictionary] = []
	var holder := _find_authoring_holder(root, "Dressing")
	if holder == null:
		return props
	for child in _sorted_node3d_children(holder):
		if child.has_method("to_stage_prop"):
			props.append(child.call("to_stage_prop") as Dictionary)
	return props

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

static func _find_authoring_holder(root: Node, holder_name: String) -> Node:
	if root == null:
		return null
	var direct := root.get_node_or_null(holder_name)
	if direct != null:
		return direct
	for parent_name in [TRACK_NODE_NAME]:
		var nested := root.get_node_or_null("%s/%s" % [parent_name, holder_name])
		if nested != null:
			return nested
	return root.find_child(holder_name, true, false)

static func _basis_to_array(basis: Basis) -> Array:
	return [
		[basis.x.x, basis.x.y, basis.x.z],
		[basis.y.x, basis.y.y, basis.y.z],
		[basis.z.x, basis.z.y, basis.z.z],
	]

static func _sorted_node3d_children(source: Node) -> Array[Node]:
	var nodes: Array[Node] = []
	for child in source.get_children():
		if child is Node3D:
			nodes.append(child)
	nodes.sort_custom(func(a: Node, b: Node) -> bool:
		return str(a.name).naturalnocasecmp_to(str(b.name)) < 0
	)
	return nodes
