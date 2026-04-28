@tool
extends Node3D
class_name TrackAuthoringPreview

const RoadMeshScript = preload("res://scripts/RoadMesh.gd")
const TrackRibbonMesh = preload("res://scripts/track/TrackRibbonMesh.gd")
const TrackWalls = preload("res://scripts/TrackWalls.gd")

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
@export var track_body_color := Color(0.08, 0.08, 0.1, 0.95):
	set(value):
		track_body_color = value
		_queue_preview_refresh()

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

	_add_ground_preview(preview_root)
	_add_track_body_preview(preview_root, route_points)
	_add_road_preview(preview_root, route_points)
	_add_wall_preview(preview_root, route_points)
	_add_marker_previews(preview_root)
	_last_preview_signature = _preview_signature()

func clear_preview() -> void:
	_clear_preview()

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
	road.set("road_material", _material(Color(0.025, 0.025, 0.03, 0.88), true))
	parent.add_child(road)
	road.call("_rebuild")

func _add_wall_preview(parent: Node3D, route_points: Array[Vector3]) -> void:
	var holder := Node3D.new()
	holder.name = "PreviewWalls"
	parent.add_child(holder)
	var packed := PackedVector3Array()
	for point in route_points:
		packed.append(point)
	var walls := TrackWalls.build_walls(holder, packed, road_width * 0.5, wall_height, wall_thickness, false, closed_loop, false)
	var wall_material := _material(Color(1.0, 0.42, 0.08, 0.82), true)
	for key in ["left", "right"]:
		if walls.has(key) and walls[key] is MeshInstance3D:
			(walls[key] as MeshInstance3D).material_override = wall_material

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

func _sorted_marker_children(source: Node) -> Array[Node]:
	var markers: Array[Node] = []
	for child in source.get_children():
		if child is Marker3D:
			markers.append(child)
	markers.sort_custom(func(a: Node, b: Node) -> bool:
		return str(a.name).naturalnocasecmp_to(str(b.name)) < 0
	)
	return markers

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
	]
	for holder_name in ["RoutePoints", "SpawnPoints", "Checkpoints", "ItemSockets", "HazardSockets", "ShortcutGates"]:
		parts.append(holder_name)
		var source := get_node_or_null(holder_name)
		if source == null:
			continue
		for marker in _sorted_marker_children(source):
			var marker_3d := marker as Marker3D
			parts.append("%s:%0.3f,%0.3f,%0.3f" % [marker_3d.name, marker_3d.position.x, marker_3d.position.y, marker_3d.position.z])
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
