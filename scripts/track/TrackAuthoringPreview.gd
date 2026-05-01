@tool
extends Node3D
class_name TrackAuthoringPreview

const RoadMeshScript = preload("res://scripts/RoadMesh.gd")
const TrackDefinition = preload("res://scripts/track/TrackDefinition.gd")
const TrackMetadataExporter = preload("res://scripts/track/TrackMetadataExporter.gd")
const TrackRuntimeBuilder = preload("res://scripts/track/TrackRuntimeBuilder.gd")
const TrackRibbonMesh = preload("res://scripts/track/TrackRibbonMesh.gd")
const TrackWalls = preload("res://scripts/TrackWalls.gd")
const StagePropAuthoring = preload("res://scripts/track/StagePropAuthoring.gd")
const SurfaceSegmentAuthoring = preload("res://scripts/track/SurfaceSegmentAuthoring.gd")
const AudioZoneAuthoring = preload("res://scripts/track/AudioZoneAuthoring.gd")

const PREVIEW_ROOT_NAME := "EditorTrackPreview"

@export var preview_enabled := true:
	set(value):
		preview_enabled = value
		_queue_preview_refresh()
@export var live_update_in_editor := true:
	set(value):
		live_update_in_editor = value
		set_process(Engine.is_editor_hint() and live_update_in_editor)
@export var road_width := 12.0:
	set(value):
		road_width = value
		_queue_preview_refresh()
@export var wall_height := 1.6:
	set(value):
		wall_height = value
		_queue_preview_refresh()
@export var wall_thickness := 0.45:
	set(value):
		wall_thickness = value
		_queue_preview_refresh()
@export var closed_loop := true:
	set(value):
		closed_loop = value
		_queue_preview_refresh()
@export var ground_size := Vector2(250.0, 190.0):
	set(value):
		ground_size = value
		_queue_preview_refresh()
@export var ground_y := 2.92:
	set(value):
		ground_y = value
		_queue_preview_refresh()
@export var road_y_offset := 0.04:
	set(value):
		road_y_offset = value
		_queue_preview_refresh()
@export var track_body_depth := 0.38:
	set(value):
		track_body_depth = value
		_queue_preview_refresh()
@export var track_body_color := Color(0.08, 0.08, 0.1, 0.35):
	set(value):
		track_body_color = value
		_queue_preview_refresh()
@export_file("*.tres") var track_definition_path := "":
	set(value):
		track_definition_path = value
		_queue_preview_refresh()
@export_file("*.json") var metadata_output_path := "res://assets/gameplay/tracks/kitchen/kitchen_track_metadata.json"
@export var show_marker_labels := false:
	set(value):
		show_marker_labels = value
		_queue_preview_refresh()
@export var show_dressing_preview := false:
	set(value):
		show_dressing_preview = value
		_queue_preview_refresh()
@export var show_auto_wall_preview := false:
	set(value):
		show_auto_wall_preview = value
		_queue_preview_refresh()
@export var show_height_guides := true:
	set(value):
		show_height_guides = value
		_queue_preview_refresh()
@export var show_surface_segments := true:
	set(value):
		show_surface_segments = value
		_queue_preview_refresh()
@export var show_audio_zones := true:
	set(value):
		show_audio_zones = value
		_queue_preview_refresh()
@export var metadata_authoring_enabled := true:
	set(value):
		metadata_authoring_enabled = value
		_queue_preview_refresh()
@export var marker_label_lift := 1.15:
	set(value):
		marker_label_lift = value
		_queue_preview_refresh()
@export_range(0.05, 1.0, 0.01) var road_preview_alpha := 0.46:
	set(value):
		road_preview_alpha = value
		_queue_preview_refresh()
@export_range(0.05, 1.0, 0.01) var wall_preview_alpha := 0.34:
	set(value):
		wall_preview_alpha = value
		_queue_preview_refresh()
@export_range(0.05, 1.0, 0.01) var dressing_preview_alpha := 0.2:
	set(value):
		dressing_preview_alpha = value
		_queue_preview_refresh()
@export_group("Builder Actions")
@export var sync_markers_from_definition_now := false:
	set(value):
		if value:
			sync_markers_from_definition()
		sync_markers_from_definition_now = false
@export var apply_markers_to_definition_now := false:
	set(value):
		if value:
			apply_markers_to_definition()
		apply_markers_to_definition_now = false
@export var export_metadata_now := false:
	set(value):
		if value:
			export_metadata()
		export_metadata_now = false
@export var validate_authoring_now := false:
	set(value):
		if value:
			print_authoring_validation()
		validate_authoring_now = false

var _last_preview_signature := ""

func _ready() -> void:
	set_process(Engine.is_editor_hint() and live_update_in_editor)
	if preview_enabled:
		refresh_preview()

func _process(_delta: float) -> void:
	if not Engine.is_editor_hint() or not live_update_in_editor:
		return
	var signature := _preview_signature()
	if signature == _last_preview_signature:
		return
	_last_preview_signature = signature
	refresh_preview()

func refresh_preview() -> void:
	_clear_preview()
	if not preview_enabled:
		return
	var route_points := _collect_marker_positions("RoutePoints", road_y_offset)
	if route_points.size() < 2:
		return

	var preview_root := Node3D.new()
	preview_root.name = PREVIEW_ROOT_NAME
	preview_root.set_meta("generated_track_authoring_preview", true)
	add_child(preview_root)

	_add_track_body_preview(preview_root, route_points)
	_add_road_preview(preview_root, route_points)
	_add_rail_preview(preview_root, route_points)
	_add_alternate_route_previews(preview_root)
	_last_preview_signature = _preview_signature()

func clear_preview() -> void:
	_clear_preview()

func sync_markers_from_definition() -> Array[String]:
	var definition := _load_definition()
	if definition == null:
		return ["Track definition could not be loaded from %s." % track_definition_path]
	_replace_marker_group("RoutePoints", _route_marker_specs(definition.route_points))
	_replace_marker_group("SpawnPoints", _socket_marker_specs(definition.spawn_points, "Start", 1))
	_replace_marker_group("Checkpoints", _checkpoint_marker_specs(definition))
	_replace_marker_group("ItemSockets", _socket_marker_specs(definition.item_sockets, "ItemSocket", 1))
	_replace_marker_group("HazardSockets", _socket_marker_specs(definition.hazard_sockets, "HazardSocket", 1))
	_replace_marker_group("ShortcutGates", _shortcut_marker_specs(definition.shortcut_gates))
	_replace_alternate_routes(definition.alternate_routes)
	if metadata_authoring_enabled:
		_replace_stage_props(definition.stage_props)
		_replace_surface_segments(definition.surface_segments)
		_replace_audio_zones(definition.audio_zones)
	refresh_preview()
	print("Track builder synced markers from %s" % track_definition_path)
	return []

func apply_markers_to_definition() -> Array[String]:
	var definition := _definition_from_markers()
	if definition == null:
		return ["Track definition could not be loaded from %s." % track_definition_path]
	var errors := definition.validate()
	if not errors.is_empty():
		_print_authoring_errors(errors)
		return errors
	var save_error := ResourceSaver.save(definition, track_definition_path)
	if save_error != OK:
		var message := "Track definition save failed: %s" % save_error
		push_error(message)
		return [message]
	refresh_preview()
	print("Track builder applied markers to %s" % track_definition_path)
	return []

func export_metadata() -> Array[String]:
	var definition := _load_definition()
	if definition == null:
		return ["Track definition could not be loaded from %s." % track_definition_path]
	var errors := definition.validate()
	if not errors.is_empty():
		_print_authoring_errors(errors)
		return errors
	var export_path := metadata_output_path
	if export_path.strip_edges().is_empty():
		export_path = track_definition_path.get_basename() + "_metadata.json"
	var error := TrackMetadataExporter.save_json(definition, export_path)
	if error != OK:
		var message := "Track metadata export failed: %s" % error
		push_error(message)
		return [message]
	print("Track builder exported metadata to %s" % export_path)
	return []

func validate_authoring() -> Array[String]:
	var definition := _definition_from_markers()
	if definition == null:
		return ["Track definition could not be loaded from %s." % track_definition_path]
	return definition.validate()

func print_authoring_validation() -> void:
	var errors := validate_authoring()
	if errors.is_empty():
		print("Track builder validation passed for %s" % track_definition_path)
	else:
		_print_authoring_errors(errors)

func get_authoring_summary() -> Dictionary:
	return {
		"route_points": _sorted_marker_children(_get_or_create_holder("RoutePoints")).size(),
		"spawn_points": _sorted_marker_children(_get_or_create_holder("SpawnPoints")).size(),
		"checkpoints": _sorted_marker_children(_get_or_create_holder("Checkpoints")).size(),
		"item_sockets": _sorted_marker_children(_get_or_create_holder("ItemSockets")).size(),
		"hazard_sockets": _sorted_marker_children(_get_or_create_holder("HazardSockets")).size(),
		"shortcut_markers": _sorted_marker_children(_get_or_create_holder("ShortcutGates")).size(),
		"alternate_routes": _sorted_node3d_children(_get_or_create_holder("AlternateRoutes")).size(),
		"dressing_props": _sorted_node3d_children(_get_or_create_holder("Dressing")).size(),
		"surface_segments": _sorted_marker_children(_get_or_create_holder("SurfaceSegments")).size(),
		"audio_zones": _sorted_marker_children(_get_or_create_holder("AudioZones")).size(),
	}

func _add_ground_preview(parent: Node3D) -> void:
	var ground := MeshInstance3D.new()
	ground.name = "PreviewCounterSurface"
	var plane := PlaneMesh.new()
	plane.size = ground_size
	ground.mesh = plane
	ground.transform.origin = Vector3(0.0, ground_y, 0.0)
	ground.material_override = _material(Color(0.76, 0.68, 0.55, 0.3), true)
	parent.add_child(ground)

func _add_track_body_preview(parent: Node3D, route_points: Array[Vector3]) -> void:
	var body := MeshInstance3D.new()
	body.name = "PreviewTrackBody"
	body.mesh = TrackRibbonMesh.build_slab_mesh(route_points, road_width, track_body_depth, closed_loop)
	body.material_override = _material(track_body_color, true)
	parent.add_child(body)

func _add_road_preview(parent: Node3D, route_points: Array[Vector3]) -> void:
	var road := RoadMeshScript.new() as MeshInstance3D
	road.name = "PreviewRoad"
	road.set("points", route_points)
	road.set("width", road_width)
	road.set("force_close", closed_loop)
	road.set("show_wall_preview", false)
	road.set("generate_walls_runtime", false)
	road.set("road_material", _material(Color(0.025, 0.025, 0.03, road_preview_alpha), true))
	parent.add_child(road)
	road.call("_rebuild")

func _add_rail_preview(parent: Node3D, route_points: Array[Vector3]) -> void:
	TrackRuntimeBuilder._build_route_rails(parent, "PreviewRails", route_points, road_width, closed_loop, "", 1.0)
	var rails := parent.get_node_or_null("PreviewRails")
	if rails != null:
		TrackRuntimeBuilder._disable_gameplay_collision(rails)

func _add_alternate_route_previews(parent: Node3D) -> void:
	var routes := _collect_alternate_routes([])
	if routes.is_empty():
		return
	var holder := Node3D.new()
	holder.name = "PreviewAlternateRoutes"
	parent.add_child(holder)
	for route in routes:
		if not bool(route.get("enabled", true)):
			continue
		var points := _vector3_array_from_value(route.get("points", []))
		if points.size() < 2:
			continue
		var width := float(route.get("road_width", road_width))
		var route_id := str(route.get("id", "Alternate"))
		var body := MeshInstance3D.new()
		body.name = "%sTrackBody" % route_id
		body.mesh = TrackRibbonMesh.build_slab_mesh(points, width, track_body_depth, false)
		body.material_override = _material(Color(0.16, 0.55, 1.0, 0.22), true)
		holder.add_child(body)
		var road := RoadMeshScript.new() as MeshInstance3D
		road.name = "%sRoad" % route_id
		road.set("points", points)
		road.set("width", width)
		road.set("force_close", false)
		road.set("show_wall_preview", false)
		road.set("generate_walls_runtime", false)
		road.set("road_material", _material(Color(0.08, 0.35, 1.0, road_preview_alpha), true))
		holder.add_child(road)
		road.call("_rebuild")
		TrackRuntimeBuilder._build_route_rails(holder, "%sRails" % route_id, points, width, false, "", 1.0)
		var rails := holder.get_node_or_null("%sRails" % route_id)
		if rails != null:
			TrackRuntimeBuilder._disable_gameplay_collision(rails)

func _add_wall_preview(parent: Node3D, route_points: Array[Vector3]) -> void:
	var holder := Node3D.new()
	holder.name = "PreviewWalls"
	parent.add_child(holder)
	var packed := PackedVector3Array()
	for point in route_points:
		packed.append(point)
	var wall_gap_segments := TrackWalls.detect_grade_separated_crossing_segments(packed, closed_loop, wall_height + 0.2, 2)
	var walls := TrackWalls.build_walls(holder, packed, road_width * 0.5, wall_height, wall_thickness, false, closed_loop, false, wall_gap_segments)
	var wall_material := _material(Color(1.0, 0.42, 0.08, wall_preview_alpha), true)
	for key in ["left", "right"]:
		if walls.has(key) and walls[key] is MeshInstance3D:
			(walls[key] as MeshInstance3D).material_override = wall_material
	_add_wall_gap_labels(holder, route_points, wall_gap_segments)

func _add_dressing_preview(parent: Node3D) -> void:
	if not show_dressing_preview or track_definition_path.is_empty():
		return
	var definition := _definition_from_markers()
	if definition == null:
		return
	var holder := Node3D.new()
	holder.name = "PreviewDressingLayout"
	parent.add_child(holder)
	TrackRuntimeBuilder.build_dressing_preview(holder, definition)
	_apply_preview_opacity(holder, dressing_preview_alpha)
	if show_marker_labels:
		_label_dressing_layout(holder)

func _add_height_guides(parent: Node3D, route_points: Array[Vector3]) -> void:
	if not show_height_guides:
		return
	var holder := Node3D.new()
	holder.name = "PreviewHeightGuides"
	parent.add_child(holder)
	for i in range(route_points.size()):
		_add_height_post(holder, "RouteHeight%02d" % i, route_points[i], 0.22, _height_color(route_points[i].y, 0.55))

	var packed := PackedVector3Array()
	for point in route_points:
		packed.append(point)
	var wall_gap_segments := TrackWalls.detect_grade_separated_crossing_segments(packed, closed_loop, wall_height + 0.2, 2)
	for segment_index in wall_gap_segments:
		var i := int(segment_index)
		if i < 0 or i >= route_points.size():
			continue
		var next_index := (i + 1) % route_points.size()
		var midpoint := route_points[i].lerp(route_points[next_index], 0.5)
		_add_height_post(holder, "OverUnderGap%02d" % i, midpoint, 0.72, _height_color(midpoint.y, 0.9))
		if show_marker_labels:
			_add_label(
				holder,
				"OverUnderGap%02d_Label" % i,
				"Gap S%02d  y=%.1f" % [i, midpoint.y],
				midpoint + Vector3.UP * 1.35,
				_height_color(midpoint.y, 1.0)
			)

func _add_height_post(parent: Node3D, node_name: String, route_point: Vector3, thickness: float, color: Color) -> void:
	var post := MeshInstance3D.new()
	post.name = node_name
	var box := BoxMesh.new()
	var base_y := ground_y + 0.05
	var post_height := maxf(absf(route_point.y - base_y), 0.2)
	box.size = Vector3(thickness, post_height, thickness)
	post.mesh = box
	post.position = Vector3(route_point.x, minf(route_point.y, base_y) + post_height * 0.5, route_point.z)
	post.material_override = _material(color, true)
	parent.add_child(post)

func _add_marker_previews(parent: Node3D) -> void:
	var holder := Node3D.new()
	holder.name = "PreviewMarkers"
	parent.add_child(holder)
	_add_marker_group(holder, "RoutePoints", Vector3(1.4, 0.18, 1.4), Color(1.0, 0.88, 0.15, 0.92), 0.16)
	_add_marker_group(holder, "SpawnPoints", Vector3(2.4, 0.28, 2.4), Color(0.2, 0.9, 0.35, 0.9), 0.24)
	_add_marker_group(holder, "Checkpoints", Vector3(road_width + 1.0, 0.08, 2.4), Color(0.15, 0.45, 1.0, 0.48), 0.3)
	_add_marker_group(holder, "ItemSockets", Vector3(2.0, 0.26, 2.0), Color(1.0, 0.9, 0.18, 0.88), 0.24)
	_add_marker_group(holder, "HazardSockets", Vector3(2.0, 0.3, 2.0), Color(1.0, 0.18, 0.14, 0.9), 0.28)
	_add_marker_group(holder, "ShortcutGates", Vector3(3.0, 0.32, 3.0), Color(0.65, 0.25, 1.0, 0.88), 0.34)
	_add_marker_group(holder, "SectionMarkers", Vector3(3.8, 0.12, 3.8), Color(0.2, 0.95, 1.0, 0.7), 0.38)
	_add_marker_group(holder, "Dressing", Vector3(3.2, 0.2, 3.2), Color(0.8, 0.9, 1.0, 0.62), 0.35)
	if show_surface_segments:
		_add_marker_group(holder, "SurfaceSegments", Vector3(3.6, 0.16, 3.6), Color(0.18, 0.88, 0.58, 0.72), 0.38)
	if show_audio_zones:
		_add_audio_zone_previews(holder)

func _add_marker_group(parent: Node3D, source_holder_name: String, size: Vector3, color: Color, y_lift: float) -> void:
	var source := get_node_or_null(source_holder_name)
	if source == null:
		return
	var group := Node3D.new()
	group.name = source_holder_name
	parent.add_child(group)
	var material := _material(color, true)
	for marker in _sorted_marker_children(source):
		var marker_3d := marker as Marker3D
		var mesh := MeshInstance3D.new()
		mesh.name = marker_3d.name
		var box := BoxMesh.new()
		box.size = size
		mesh.mesh = box
		mesh.material_override = material
		mesh.transform = marker_3d.transform
		mesh.position.y += y_lift
		group.add_child(mesh)
		if show_marker_labels:
			_add_label(
				group,
				"%s_Label" % marker_3d.name,
				_marker_label_text(marker_3d.name, marker_3d.position),
				marker_3d.position + Vector3.UP * (y_lift + marker_label_lift),
				color
			)

func _add_wall_gap_labels(parent: Node3D, route_points: Array[Vector3], wall_gap_segments: Array) -> void:
	if not show_marker_labels or wall_gap_segments.is_empty():
		return
	var holder := Node3D.new()
	holder.name = "WallGapLabels"
	parent.add_child(holder)
	for segment_index in wall_gap_segments:
		var i := int(segment_index)
		if i < 0 or i >= route_points.size():
			continue
		var next_index := (i + 1) % route_points.size()
		var midpoint := route_points[i].lerp(route_points[next_index], 0.5)
		_add_label(
			holder,
			"WallGap%02d_Label" % i,
			"Rail gap S%02d\n%s" % [i, _position_text(midpoint)],
			midpoint + Vector3.UP * 1.8,
			Color(1.0, 0.48, 0.08, 1.0)
		)

func _label_dressing_layout(preview_holder: Node3D) -> void:
	var dressing := preview_holder.get_node_or_null("Dressing")
	if dressing == null:
		return
	var labels := Node3D.new()
	labels.name = "DressingLabels"
	preview_holder.add_child(labels)
	for child in dressing.get_children():
		if child is Node3D:
			var node := child as Node3D
			_add_label(
				labels,
				"%s_Label" % node.name,
				_marker_label_text(node.name, node.position),
				node.position + Vector3.UP * 2.0,
				Color(0.84, 0.93, 1.0, 1.0)
			)

func _add_label(parent: Node3D, label_name: String, text: String, position: Vector3, color: Color) -> void:
	var label := Label3D.new()
	label.name = label_name
	label.text = text
	label.position = position
	label.pixel_size = 0.035
	label.font_size = 18
	label.fixed_size = false
	label.no_depth_test = false
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = color
	label.outline_modulate = Color(0.0, 0.0, 0.0, 0.88)
	label.outline_size = 2
	parent.add_child(label)

func _apply_preview_opacity(node: Node, alpha: float) -> void:
	for child in node.get_children():
		if child is MeshInstance3D:
			var mesh := child as MeshInstance3D
			var color := Color(0.72, 0.82, 0.92, alpha)
			if mesh.material_override is StandardMaterial3D:
				var existing := mesh.material_override as StandardMaterial3D
				color = existing.albedo_color
				color.a = alpha
			mesh.material_override = _material(color, true)
		_apply_preview_opacity(child, alpha)

func _height_color(y: float, alpha: float) -> Color:
	var t := clampf((y - ground_y) / 3.5, 0.0, 1.0)
	return Color(0.12 + 0.92 * t, 0.92 - 0.48 * t, 1.0 - 0.82 * t, alpha)

func _marker_label_text(marker_name: String, position: Vector3) -> String:
	return "%s\n%s" % [marker_name, _position_text(position)]

func _position_text(position: Vector3) -> String:
	return "(%.1f, %.1f, %.1f)" % [position.x, position.y, position.z]

func _collect_marker_positions(source_holder_name: String, y_offset: float = 0.0) -> Array[Vector3]:
	var out: Array[Vector3] = []
	var source := get_node_or_null(source_holder_name)
	if source == null:
		return out
	for marker in _sorted_marker_children(source):
		var point := (marker as Marker3D).position
		point.y += y_offset
		out.append(point)
	return out

func _definition_from_markers() -> TrackDefinition:
	var source := _load_definition()
	if source == null:
		return null
	var definition := source.duplicate(true) as TrackDefinition
	definition.route_points = _collect_marker_positions("RoutePoints")
	definition.spawn_points = _collect_socket_markers("SpawnPoints")
	definition.checkpoint_indices = _collect_checkpoint_indices(definition.route_points)
	definition.lap_gate_checkpoint_index = _collect_lap_gate_checkpoint_index()
	definition.item_sockets = _collect_socket_markers("ItemSockets")
	definition.hazard_sockets = _collect_socket_markers("HazardSockets")
	definition.shortcut_gates = _collect_shortcut_gates(definition.shortcut_gates)
	definition.alternate_routes = _collect_alternate_routes(definition.alternate_routes)
	if metadata_authoring_enabled:
		definition.dressing_overrides = _collect_dressing_overrides(definition.dressing_overrides)
		definition.stage_props = _collect_stage_props()
		definition.surface_segments = _collect_surface_segments()
		definition.audio_zones = _collect_audio_zones()
	return definition

func _load_definition() -> TrackDefinition:
	if track_definition_path.strip_edges().is_empty():
		return null
	return load(track_definition_path) as TrackDefinition

func _collect_socket_markers(holder_name: String) -> Array[Vector4]:
	var sockets: Array[Vector4] = []
	var holder := get_node_or_null(holder_name)
	if holder == null:
		return sockets
	for marker in _sorted_marker_children(holder):
		var marker_3d := marker as Marker3D
		sockets.append(Vector4(marker_3d.position.x, marker_3d.position.y, marker_3d.position.z, marker_3d.rotation_degrees.y))
	return sockets

func _collect_checkpoint_indices(route_points: Array[Vector3]) -> Array[int]:
	var indices: Array[int] = []
	var holder := get_node_or_null("Checkpoints")
	if holder == null:
		return indices
	for marker in _sorted_marker_children(holder):
		indices.append(_nearest_route_index((marker as Marker3D).position, route_points))
	return indices

func _collect_lap_gate_checkpoint_index() -> int:
	var holder := get_node_or_null("Checkpoints")
	if holder == null:
		return 0
	var checkpoints := _sorted_marker_children(holder)
	for i in range(checkpoints.size()):
		if str(checkpoints[i].name).to_lower().contains("lap"):
			return i
	return 0

func _collect_shortcut_gates(existing_gates: Array[Dictionary]) -> Array[Dictionary]:
	var holder := get_node_or_null("ShortcutGates")
	if holder == null:
		return existing_gates
	var by_id := {}
	for marker in _sorted_marker_children(holder):
		var marker_3d := marker as Marker3D
		var name := str(marker_3d.name)
		if name.ends_with("_Entry"):
			var id := name.trim_suffix("_Entry")
			if not by_id.has(id):
				by_id[id] = {}
			by_id[id]["entry"] = [marker_3d.position.x, marker_3d.position.y, marker_3d.position.z]
		elif name.ends_with("_Exit"):
			var id := name.trim_suffix("_Exit")
			if not by_id.has(id):
				by_id[id] = {}
			by_id[id]["exit"] = [marker_3d.position.x, marker_3d.position.y, marker_3d.position.z]
	var gates: Array[Dictionary] = []
	for id in by_id.keys():
		var previous := _find_shortcut_gate(existing_gates, str(id))
		var gate := by_id[id] as Dictionary
		gate["id"] = str(id)
		gate["kind"] = str(previous.get("kind", "shortcut"))
		gate["width"] = float(previous.get("width", road_width * 0.55))
		gate["surface_enabled"] = bool(previous.get("surface_enabled", true))
		if gate.has("entry") and gate.has("exit"):
			gates.append(gate)
	return gates

func _find_shortcut_gate(gates: Array[Dictionary], id: String) -> Dictionary:
	for gate in gates:
		if str(gate.get("id", "")) == id:
			return gate
	return {}

func _collect_alternate_routes(existing_routes: Array[Dictionary]) -> Array[Dictionary]:
	var holder := get_node_or_null("AlternateRoutes")
	if holder == null:
		return existing_routes
	var routes: Array[Dictionary] = []
	for route_node in _sorted_node3d_children(holder):
		var id := str(route_node.name)
		var previous := _find_alternate_route(existing_routes, id)
		var points: Array[Vector3] = []
		for marker in _sorted_marker_children(route_node):
			points.append((marker as Marker3D).position)
		routes.append({
			"id": id,
			"points": points,
			"entry_checkpoint_index": int(previous.get("entry_checkpoint_index", 0)),
			"exit_checkpoint_index": int(previous.get("exit_checkpoint_index", min(1, max(0, _sorted_marker_children(_get_or_create_holder("Checkpoints")).size() - 1)))),
			"road_width": float(previous.get("road_width", road_width)),
			"enabled": bool(previous.get("enabled", true)),
		})
	return routes

func _find_alternate_route(routes: Array[Dictionary], id: String) -> Dictionary:
	for route in routes:
		if str(route.get("id", "")) == id:
			return route
	return {}

func _nearest_route_index(point: Vector3, route_points: Array[Vector3]) -> int:
	var best_index := 0
	var best_distance := INF
	for i in range(route_points.size()):
		var distance := point.distance_squared_to(route_points[i])
		if distance < best_distance:
			best_distance = distance
			best_index = i
	return best_index

func _replace_marker_group(holder_name: String, specs: Array[Dictionary]) -> void:
	var holder := _get_or_create_holder(holder_name)
	for child in holder.get_children():
		holder.remove_child(child)
		child.queue_free()
	for spec in specs:
		var marker := Marker3D.new()
		marker.name = str(spec.get("name", "Marker"))
		marker.position = spec.get("position", Vector3.ZERO) as Vector3
		marker.rotation_degrees.y = float(spec.get("yaw_degrees", 0.0))
		marker.scale = spec.get("scale", Vector3.ONE) as Vector3
		holder.add_child(marker)
		if Engine.is_editor_hint():
			marker.owner = owner if owner != null else self

func _replace_stage_props(props: Array[Dictionary]) -> void:
	var holder := _get_or_create_holder("Dressing")
	for child in holder.get_children():
		holder.remove_child(child)
		child.queue_free()
	for prop in props:
		var node := StagePropAuthoring.new()
		node.name = str(prop.get("id", "StageProp"))
		node.prop_id = str(prop.get("id", node.name))
		node.prop_kind = str(prop.get("kind", "box"))
		node.asset_path = str(prop.get("asset_path", ""))
		node.box_size = _vector3_from_value(prop.get("box_size", Vector3.ONE), Vector3.ONE)
		node.box_color = _color_from_value(prop.get("box_color", Color.WHITE), Color.WHITE)
		node.collision_mode = str(prop.get("collision_mode", "visual"))
		node.audio_material_id = str(prop.get("audio_material_id", ""))
		node.gameplay_tag = str(prop.get("gameplay_tag", ""))
		node.position = _point_from_gate_value(prop.get("position", Vector3.ZERO))
		node.rotation_degrees.y = float(prop.get("yaw_degrees", 0.0))
		node.scale = _vector3_from_value(prop.get("scale", Vector3.ONE), Vector3.ONE)
		holder.add_child(node)
		if Engine.is_editor_hint():
			node.owner = owner if owner != null else self

func _replace_surface_segments(segments: Array[Dictionary]) -> void:
	var holder := _get_or_create_holder("SurfaceSegments")
	for child in holder.get_children():
		holder.remove_child(child)
		child.queue_free()
	for segment in segments:
		var node := SurfaceSegmentAuthoring.new()
		node.name = str(segment.get("id", "SurfaceSegment"))
		node.segment_id = node.name
		node.start_route_index = int(segment.get("start_route_index", 0))
		node.end_route_index = int(segment.get("end_route_index", 0))
		node.surface_audio_id = str(segment.get("surface_audio_id", ""))
		node.surface_material_id = str(segment.get("surface_material_id", ""))
		node.position = _point_from_gate_value(segment.get("position", Vector3.ZERO))
		holder.add_child(node)
		if Engine.is_editor_hint():
			node.owner = owner if owner != null else self

func _replace_audio_zones(zones: Array[Dictionary]) -> void:
	var holder := _get_or_create_holder("AudioZones")
	for child in holder.get_children():
		holder.remove_child(child)
		child.queue_free()
	for zone in zones:
		var node := AudioZoneAuthoring.new()
		node.name = str(zone.get("id", "AudioZone"))
		node.zone_id = node.name
		node.audio_id = str(zone.get("audio_id", ""))
		node.audio_path = str(zone.get("audio_path", ""))
		node.zone_kind = str(zone.get("zone_kind", "ambient"))
		node.radius = float(zone.get("radius", 12.0))
		node.volume_db = float(zone.get("volume_db", -6.0))
		node.position = _point_from_gate_value(zone.get("position", Vector3.ZERO))
		holder.add_child(node)
		if Engine.is_editor_hint():
			node.owner = owner if owner != null else self

func _replace_alternate_routes(routes: Array[Dictionary]) -> void:
	var holder := _get_or_create_holder("AlternateRoutes")
	for child in holder.get_children():
		holder.remove_child(child)
		child.queue_free()
	for route in routes:
		var route_node := Node3D.new()
		route_node.name = str(route.get("id", "AlternateRoute"))
		holder.add_child(route_node)
		if Engine.is_editor_hint():
			route_node.owner = owner if owner != null else self
		var points := _vector3_array_from_value(route.get("points", []))
		for i in range(points.size()):
			var marker := Marker3D.new()
			marker.name = "Point%02d" % i
			marker.position = points[i]
			route_node.add_child(marker)
			if Engine.is_editor_hint():
				marker.owner = owner if owner != null else self

func _get_or_create_holder(holder_name: String) -> Node3D:
	var holder := get_node_or_null(holder_name) as Node3D
	if holder != null:
		return holder
	holder = Node3D.new()
	holder.name = holder_name
	add_child(holder)
	if Engine.is_editor_hint():
		holder.owner = owner if owner != null else self
	return holder

func _route_marker_specs(points: Array[Vector3]) -> Array[Dictionary]:
	var specs: Array[Dictionary] = []
	for i in range(points.size()):
		specs.append({"name": "RoutePoint%02d" % i, "position": points[i], "yaw_degrees": 0.0})
	return specs

func _socket_marker_specs(sockets: Array[Vector4], prefix: String, start_index: int) -> Array[Dictionary]:
	var specs: Array[Dictionary] = []
	for i in range(sockets.size()):
		var socket := sockets[i]
		specs.append({
			"name": "%s%02d" % [prefix, i + start_index],
			"position": Vector3(socket.x, socket.y, socket.z),
			"yaw_degrees": socket.w,
		})
	return specs

func _checkpoint_marker_specs(definition: TrackDefinition) -> Array[Dictionary]:
	var specs: Array[Dictionary] = []
	for i in range(definition.checkpoint_indices.size()):
		var route_index := definition.checkpoint_indices[i]
		var name := "Checkpoint%02d" % i
		if i == definition.lap_gate_checkpoint_index:
			name += "_LapGate"
		var position := definition.route_points[route_index] if route_index >= 0 and route_index < definition.route_points.size() else Vector3.ZERO
		specs.append({"name": name, "position": position, "yaw_degrees": 0.0})
	return specs

func _shortcut_marker_specs(gates: Array[Dictionary]) -> Array[Dictionary]:
	var specs: Array[Dictionary] = []
	for gate in gates:
		var id := str(gate.get("id", "shortcut"))
		specs.append({"name": "%s_Entry" % id, "position": _point_from_gate_value(gate.get("entry", [])), "yaw_degrees": 0.0})
		specs.append({"name": "%s_Exit" % id, "position": _point_from_gate_value(gate.get("exit", [])), "yaw_degrees": 0.0})
	return specs

func _dressing_marker_specs(definition: TrackDefinition) -> Array[Dictionary]:
	var specs: Array[Dictionary] = []
	specs.append(_dressing_marker_spec(definition, "KitchenSink", Vector3(-8, 2.15, 88), 180.0, Vector3(10.5, 10.5, 10.5)))
	return specs

func _dressing_marker_spec(definition: TrackDefinition, node_name: String, position: Vector3, yaw_degrees: float, scale: Vector3) -> Dictionary:
	var override := definition.dressing_overrides.get(node_name, {}) as Dictionary
	return {
		"name": node_name,
		"position": _point_from_gate_value(override.get("position", position)),
		"yaw_degrees": float(override.get("yaw_degrees", yaw_degrees)),
		"scale": _point_from_gate_value(override.get("scale", scale)),
	}

func _collect_dressing_overrides(existing_overrides: Dictionary) -> Dictionary:
	var overrides := existing_overrides.duplicate(true)
	var holder := get_node_or_null("Dressing")
	if holder == null:
		return overrides
	for marker in _sorted_marker_children(holder):
		var marker_3d := marker as Marker3D
		overrides[str(marker_3d.name)] = {
			"position": [marker_3d.position.x, marker_3d.position.y, marker_3d.position.z],
			"yaw_degrees": marker_3d.rotation_degrees.y,
			"scale": [marker_3d.scale.x, marker_3d.scale.y, marker_3d.scale.z],
		}
	return overrides

func _collect_stage_props() -> Array[Dictionary]:
	var props: Array[Dictionary] = []
	var holder := get_node_or_null("Dressing")
	if holder == null:
		return props
	for child in _sorted_node3d_children(holder):
		if child.has_method("to_stage_prop"):
			props.append(child.call("to_stage_prop") as Dictionary)
	return props

func _collect_surface_segments() -> Array[Dictionary]:
	var segments: Array[Dictionary] = []
	var holder := get_node_or_null("SurfaceSegments")
	if holder == null:
		return segments
	for child in _sorted_marker_children(holder):
		if child.has_method("to_surface_segment"):
			segments.append(child.call("to_surface_segment") as Dictionary)
	return segments

func _collect_audio_zones() -> Array[Dictionary]:
	var zones: Array[Dictionary] = []
	var holder := get_node_or_null("AudioZones")
	if holder == null:
		return zones
	for child in _sorted_marker_children(holder):
		if child.has_method("to_audio_zone"):
			zones.append(child.call("to_audio_zone") as Dictionary)
	return zones

func _point_from_gate_value(value: Variant) -> Vector3:
	if value is Vector3:
		return value
	if value is Array and value.size() >= 3:
		return Vector3(float(value[0]), float(value[1]), float(value[2]))
	return Vector3.ZERO

func _vector3_from_value(value: Variant, fallback: Vector3) -> Vector3:
	if value is Vector3:
		return value
	if value is Array and value.size() >= 3:
		return Vector3(float(value[0]), float(value[1]), float(value[2]))
	return fallback

func _vector3_array_from_value(value: Variant) -> Array[Vector3]:
	var points: Array[Vector3] = []
	if not (value is Array):
		return points
	for item in value:
		if item is Vector3:
			points.append(item)
		elif item is Array and item.size() >= 3:
			points.append(Vector3(float(item[0]), float(item[1]), float(item[2])))
		elif item is Dictionary:
			points.append(Vector3(float(item.get("x", 0.0)), float(item.get("y", 0.0)), float(item.get("z", 0.0))))
	return points

func _color_from_value(value: Variant, fallback: Color) -> Color:
	if value is Color:
		return value
	if value is Array and value.size() >= 4:
		return Color(float(value[0]), float(value[1]), float(value[2]), float(value[3]))
	return fallback

func _print_authoring_errors(errors: Array[String]) -> void:
	for error in errors:
		push_error("Track builder validation: %s" % error)

func _sorted_marker_children(source: Node) -> Array[Node]:
	var markers: Array[Node] = []
	for child in source.get_children():
		if child is Marker3D:
			markers.append(child)
	markers.sort_custom(func(a: Node, b: Node) -> bool:
		return str(a.name).naturalnocasecmp_to(str(b.name)) < 0
	)
	return markers

func _sorted_node3d_children(source: Node) -> Array[Node]:
	var nodes: Array[Node] = []
	for child in source.get_children():
		if child is Node3D:
			nodes.append(child)
	nodes.sort_custom(func(a: Node, b: Node) -> bool:
		return str(a.name).naturalnocasecmp_to(str(b.name)) < 0
	)
	return nodes

func _preview_signature() -> String:
	var parts: Array[String] = [
		str(preview_enabled),
		str(road_width),
		str(wall_height),
		str(wall_thickness),
		str(closed_loop),
		str(ground_size),
		str(ground_y),
		str(road_y_offset),
		str(track_body_depth),
		str(track_body_color),
		str(track_definition_path),
		str(show_marker_labels),
		str(show_dressing_preview),
		str(show_auto_wall_preview),
		str(show_height_guides),
		str(show_surface_segments),
		str(show_audio_zones),
		str(metadata_authoring_enabled),
		str(marker_label_lift),
		str(road_preview_alpha),
		str(wall_preview_alpha),
		str(dressing_preview_alpha),
	]
	for holder_name in ["RoutePoints", "SpawnPoints", "Checkpoints", "ItemSockets", "HazardSockets", "ShortcutGates", "AlternateRoutes", "SectionMarkers", "Dressing", "SurfaceSegments", "AudioZones"]:
		parts.append(holder_name)
		var source := get_node_or_null(holder_name)
		if source == null:
			continue
		for node in _sorted_node3d_children(source):
			var node_3d := node as Node3D
			parts.append("%s:%0.3f,%0.3f,%0.3f:%0.3f:%0.3f,%0.3f,%0.3f" % [
				node_3d.name,
				node_3d.position.x,
				node_3d.position.y,
				node_3d.position.z,
				node_3d.rotation_degrees.y,
				node_3d.scale.x,
				node_3d.scale.y,
				node_3d.scale.z,
			])
	return "|".join(parts)

func _queue_preview_refresh() -> void:
	if not is_inside_tree():
		return
	call_deferred("refresh_preview")

func _clear_preview() -> void:
	var existing := get_node_or_null(PREVIEW_ROOT_NAME)
	if existing == null:
		return
	existing.name = "%s_Removing" % PREVIEW_ROOT_NAME
	remove_child(existing)
	if Engine.is_editor_hint():
		existing.queue_free()
	else:
		existing.free()

func _material(color: Color, transparent: bool) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.65
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	if transparent or color.a < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return mat

func _add_audio_zone_previews(parent: Node3D) -> void:
	var source := get_node_or_null("AudioZones")
	if source == null:
		return
	var group := Node3D.new()
	group.name = "AudioZones"
	parent.add_child(group)
	for marker in _sorted_marker_children(source):
		var marker_3d := marker as Marker3D
		var mesh := MeshInstance3D.new()
		mesh.name = marker_3d.name
		var sphere := SphereMesh.new()
		var radius := 6.0
		if marker_3d.has_method("to_audio_zone"):
			var data := marker_3d.call("to_audio_zone") as Dictionary
			radius = maxf(float(data.get("radius", 6.0)), 0.1)
		sphere.radius = radius
		sphere.height = radius * 2.0
		mesh.mesh = sphere
		mesh.material_override = _material(Color(0.25, 0.55, 1.0, 0.14), true)
		mesh.position = marker_3d.position
		group.add_child(mesh)
		if show_marker_labels:
			_add_label(group, "%s_Label" % marker_3d.name, _marker_label_text(marker_3d.name, marker_3d.position), marker_3d.position + Vector3.UP * (radius + 1.0), Color(0.4, 0.72, 1.0, 1.0))
