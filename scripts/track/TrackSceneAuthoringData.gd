extends RefCounted
class_name TrackSceneAuthoringData

const TrackDefinition = preload("res://scripts/track/TrackDefinition.gd")
const TrackGridRoadBuilder = preload("res://scripts/track/TrackGridRoadBuilder.gd")
const RaceLayout = preload("res://scripts/track/RaceLayout.gd")

const TRACK_NODE_NAME := "Track"
const ROAD_SOURCE_AUTO := "auto"
const ROAD_SOURCE_ROAD_GRID_MAP := "road_grid_map"
const ROAD_SOURCE_GRID := "grid"

static func apply_to_definition(source: TrackDefinition, mode_config: Dictionary = {}) -> TrackDefinition:
	if source == null:
		return null
	var definition := source.duplicate(true) as TrackDefinition
	var road_source := _road_source_for(definition, mode_config)
	if definition.dressing_scene_path.strip_edges().is_empty():
		var explicit_layout := _race_layout_from_definition_grid(definition)
		if explicit_layout != null and explicit_layout.is_valid():
			_apply_race_layout(definition, explicit_layout)
			return definition
		return definition
	var packed := load(definition.dressing_scene_path)
	if not (packed is PackedScene):
		var explicit_layout := _race_layout_from_definition_grid(definition)
		if explicit_layout != null and explicit_layout.is_valid():
			_apply_race_layout(definition, explicit_layout)
			return definition
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

static func _resolve_race_layout(definition: TrackDefinition, scene_root: Node3D, _road_source: String) -> RaceLayout:
	var grid_layout := _race_layout_from_grid(scene_root, definition)
	if grid_layout != null and grid_layout.is_valid():
		return grid_layout
	return null

static func _race_layout_from_grid(scene_root: Node3D, definition: TrackDefinition) -> RaceLayout:
	var grid_layout := _collect_road_grid(scene_root, definition.road_width)
	if grid_layout.is_empty():
		return null
	var race_layout := TrackGridRoadBuilder.race_layout_from_grid_layout(grid_layout, definition.closed_loop)
	return race_layout if race_layout.is_valid() else null

static func _race_layout_from_definition_grid(definition: TrackDefinition) -> RaceLayout:
	if not _definition_has_complete_grid_layout(definition):
		return null
	var race_layout := TrackGridRoadBuilder.race_layout_from_grid_layout(definition.road_grid_layout, definition.closed_loop)
	return race_layout if race_layout.is_valid() else null

static func _definition_has_complete_grid_layout(definition: TrackDefinition) -> bool:
	if definition == null or definition.road_grid_layout.is_empty():
		return false
	var cells := definition.road_grid_layout.get("cells", []) as Array
	var route_cells := definition.road_grid_layout.get("ordered_route_cells", []) as Array
	return cells.size() >= 3 and route_cells.size() >= 3

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
	return null

static func _sorted_node3d_children(source: Node) -> Array[Node]:
	var nodes: Array[Node] = []
	for child in source.get_children():
		if child is Node3D:
			nodes.append(child)
	nodes.sort_custom(func(a: Node, b: Node) -> bool:
		return str(a.name).naturalnocasecmp_to(str(b.name)) < 0
	)
	return nodes
