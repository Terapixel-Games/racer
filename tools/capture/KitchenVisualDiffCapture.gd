@tool
extends SceneTree

const TrackCatalog = preload("res://scripts/track/TrackCatalog.gd")
const TrackRuntimeBuilder = preload("res://scripts/track/TrackRuntimeBuilder.gd")
const TrackSceneAuthoringData = preload("res://scripts/track/TrackSceneAuthoringData.gd")

const DEFAULT_OUTPUT_DIR := "res://tmp/visual_diffs/kitchen"
const DEFAULT_WIDTH := 1600
const DEFAULT_HEIGHT := 900

var _camera: Camera3D
var _track_node: Node3D
var _capture_failures := 0
var _manifest := {
	"track_id": "kitchen",
	"views": [],
}

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var options := _parse_options()
	var output_dir := _global_output_dir(str(options.get("output_dir", DEFAULT_OUTPUT_DIR)))
	var phase := str(options.get("phase", "capture")).strip_edges().to_lower()
	if phase.is_empty():
		phase = "capture"
	var manifest_only := bool(options.get("manifest_only", false))
	var width := maxi(320, int(options.get("width", DEFAULT_WIDTH)))
	var height := maxi(240, int(options.get("height", DEFAULT_HEIGHT)))
	root.size = Vector2i(width, height)
	root.transparent_bg = false
	DirAccess.make_dir_recursive_absolute(output_dir)

	var definition := TrackSceneAuthoringData.apply_to_definition(TrackCatalog.get_definition("kitchen"))
	if definition == null:
		_fail("Kitchen definition failed to load")
		return
	var built := TrackRuntimeBuilder.build(definition)
	_track_node = built.get("node", null) as Node3D
	if _track_node == null:
		_fail("Kitchen runtime track failed to build")
		return
	root.add_child(_track_node)

	_camera = Camera3D.new()
	_camera.name = "VisualDiffCamera"
	_camera.current = true
	_camera.fov = 58.0
	_camera.near = 0.05
	_camera.far = 1500.0
	root.add_child(_camera)

	for _i in range(6):
		await process_frame

	var route: Array[Vector3] = definition.route_points
	var views := _camera_views(route)
	for view in views:
		await _capture_view(output_dir, phase, view, manifest_only)

	_write_manifest(output_dir, phase)
	if _capture_failures > 0:
		_fail("failed to capture %d views" % _capture_failures)
		return
	print("[KitchenVisualDiffCapture] wrote %d views to %s" % [views.size(), output_dir])
	quit(0)

func _camera_views(route: Array[Vector3]) -> Array[Dictionary]:
	var bounds := _route_bounds(route)
	var center := bounds.get_center()
	var size := bounds.size
	var start := route[0] if not route.is_empty() else Vector3.ZERO
	var second := route[1] if route.size() > 1 else start + Vector3.FORWARD
	var forward := _flat_forward(second - start)
	var right := Vector3(forward.z, 0.0, -forward.x).normalized()
	var views: Array[Dictionary] = [
		{
			"id": "start_grid",
			"position": start - forward * 44.0 + right * 4.0 + Vector3.UP * 30.0,
			"target": start + forward * 34.0 + Vector3.UP * 4.0,
			"note": "Race-start player read; validates fallback spawns at ordered_route_cells[0].",
		},
		{
			"id": "low_floor_player",
			"position": center + Vector3(-35.0, -23.0, -120.0),
			"target": center + Vector3(0.0, -8.0, 0.0),
			"note": "Floor-level leak and floating-prop check.",
		},
		{
			"id": "overhead_route",
			"position": center + Vector3(0.0, 94.0, 0.01),
			"target": center + Vector3(0.0, -28.0, 0.0),
			"projection": "orthogonal",
			"orthogonal_size": maxf(size.x, size.z) + 80.0,
			"hidden_paths": ["Dressing/EditableRoom/Track/RoomShell/Ceiling"],
			"note": "Route, envelope, and composition overview.",
		},
		{
			"id": "level_select_angle",
			"position": center + Vector3(120.0, 70.0, 135.0),
			"target": center + Vector3(-25.0, -8.0, -20.0),
			"note": "Approximate level-select preview angle.",
		},
		{
			"id": "back_cabinet_wall_run",
			"position": Vector3(-30.0, 18.0, 160.0),
			"target": Vector3(-30.0, 5.0, 74.0),
			"note": "Cabinet backs, sink run, back wall, and window alignment.",
		},
		{
			"id": "left_wall_corner_run",
			"position": Vector3(-185.0, 16.0, -18.0),
			"target": Vector3(-116.0, 7.0, -18.0),
			"note": "Left wall cabinets, appliances, and room corner closure.",
		},
		{
			"id": "ceiling_clearance",
			"position": Vector3(-220.0, 16.0, -135.0),
			"target": Vector3(-255.0, 88.0, 30.0),
			"note": "Ceiling clearance above tall objects.",
		},
		{
			"id": "door_lintel_seam",
			"position": Vector3(-118.0, 55.0, -268.0),
			"target": Vector3(-118.0, 88.0, -196.0),
			"fov": 45.0,
			"note": "Front door header, ceiling seam, and frame closure.",
		},
		{
			"id": "front_door_frame_fit",
			"position": Vector3(-150.0, 46.0, -285.0),
			"target": Vector3(-172.0, 28.0, -190.0),
			"fov": 60.0,
			"note": "Front wall returns and lintel must align to the closed-door prefab frame.",
		},
		{
			"id": "rear_doorway_header_gap",
			"position": Vector3(-130.0, 92.0, 132.0),
			"target": Vector3(-75.0, 94.0, 132.0),
			"fov": 38.0,
			"note": "Interior doorway header infill between the doorway frame and ceiling seam.",
		},
		{
			"id": "door_frame_wall_fit",
			"position": Vector3(-14.0, 62.0, 126.0),
			"target": Vector3(-74.0, 88.0, 132.0),
			"fov": 42.0,
			"note": "Doorway wall pieces must fit the prefab frame without protruding chunks or gaps.",
		},
		{
			"id": "interior_door_depth_fit",
			"position": Vector3(24.0, 56.0, 120.0),
			"target": Vector3(-74.0, 40.0, 132.0),
			"fov": 48.0,
			"note": "Interior doorway frame depth must fit inside the surrounding wall thickness.",
		},
		{
			"id": "right_countertop_corner",
			"position": Vector3(70.0, 50.0, 118.0),
			"target": Vector3(112.0, 25.0, 154.0),
			"note": "Right cabinet corner top plane and side-face alignment.",
		},
		{
			"id": "counter_wall_closure",
			"position": Vector3(112.0, 50.0, 110.0),
			"target": Vector3(48.0, 24.0, 172.0),
			"fov": 42.0,
			"note": "Counter/cabinet run must visually close to the back and right wall planes.",
		},
		{
			"id": "washer_water_containment",
			"position": Vector3(-12.0, 20.0, 116.0),
			"target": Vector3(31.0, 5.0, 148.0),
			"note": "Washer water must stay inside the washer door/glass.",
		},
		{
			"id": "washer_water_natural_closeup",
			"position": Vector3(1.0, 12.0, 112.0),
			"target": Vector3(31.0, 4.5, 148.0),
			"fov": 34.0,
			"note": "Washer water silhouette should read as a natural fill inside the round porthole, not a square decal.",
		},
		{
			"id": "stove_hood_appliance_slot",
			"position": Vector3(-190.0, 52.0, -126.0),
			"target": Vector3(-266.0, 28.0, -48.0),
			"note": "Oven/stove bay, neighboring cabinets, and hood centering.",
		},
		{
			"id": "oven_side_gap_closeup",
			"position": Vector3(-194.0, 30.0, -80.0),
			"target": Vector3(-268.0, 4.0, -46.0),
			"fov": 36.0,
			"note": "Lower cabinets must leave a visible side gap around the oven/stove.",
		},
		{
			"id": "fridge_upper_clearance",
			"position": Vector3(-220.0, 76.0, 118.0),
			"target": Vector3(-272.0, 62.0, 72.0),
			"note": "Fridge clearance from upper cabinets.",
		},
		{
			"id": "right_wall_ceiling_seam",
			"position": Vector3(40.0, 96.0, 230.0),
			"target": Vector3(145.0, 107.0, 160.0),
			"note": "Right wall and ceiling flushness near visible corner seams.",
		},
		{
			"id": "right_wall_panel_joints",
			"position": Vector3(28.0, 48.0, 132.0),
			"target": Vector3(-76.0, 44.0, 132.0),
			"fov": 42.0,
			"note": "Coplanar right-wall panel joints behind cabinet and doorway dressing.",
		},
		{
			"id": "back_wall_window_joints",
			"position": Vector3(-194.0, 54.0, 118.0),
			"target": Vector3(-194.0, 46.0, 196.0),
			"fov": 42.0,
			"note": "Back-wall window panel joints and seam-cover strips.",
		},
		{
			"id": "back_upper_cabinet_faces",
			"position": Vector3(-16.0, 64.0, 84.0),
			"target": Vector3(-16.0, 64.0, 176.0),
			"fov": 46.0,
			"note": "Back-wall upper cabinet doors must face into the room, not into the wall.",
		},
		_node_anchor_view("sink_effect_anchor", "Dressing/EditableRoom/Track/Appliances/kitchenSink", Vector3(88.0, 30.0, -90.0), "Sink and sink-water alignment."),
		_node_anchor_view("washer_effect_anchor", "Dressing/EditableRoom/Track/RoomShell/washer", Vector3(-82.0, 30.0, -88.0), "Washer and washer-water alignment."),
	]
	for ratio in [0.25, 0.5, 0.75]:
		var index := clampi(roundi(float(route.size() - 1) * float(ratio)), 0, maxi(route.size() - 1, 0))
		if route.is_empty():
			continue
		var point := route[index]
		var next := route[(index + 1) % route.size()]
		var route_forward := _flat_forward(next - point)
		views.append({
			"id": "route_sample_%02d" % int(ratio * 100.0),
			"position": point - route_forward * 30.0 + Vector3.UP * 12.0,
			"target": point + route_forward * 20.0 + Vector3.UP * 2.0,
			"route_index": index,
			"note": "Representative on-route player camera sample.",
		})
	return views

func _node_anchor_view(view_id: String, path: NodePath, offset: Vector3, note: String) -> Dictionary:
	var node := _track_node.get_node_or_null(path) as Node3D
	var target := node.global_position if node != null else Vector3.ZERO
	return {
		"id": view_id,
		"position": target + offset,
		"target": target + Vector3.UP * 3.0,
		"node_path": str(path),
		"note": note,
	}

func _capture_view(output_dir: String, phase: String, view: Dictionary, manifest_only: bool) -> void:
	var position := view.get("position", Vector3.ZERO) as Vector3
	var target := view.get("target", Vector3.ZERO) as Vector3
	var hidden_nodes: Array[Dictionary] = []
	for raw_path in view.get("hidden_paths", []):
		var hidden := _track_node.get_node_or_null(raw_path) as Node3D
		if hidden == null:
			continue
		hidden_nodes.append({
			"node": hidden,
			"visible": hidden.visible,
		})
		hidden.visible = false
	var previous_projection := _camera.projection
	var previous_size := _camera.size
	var previous_fov := _camera.fov
	if str(view.get("projection", "perspective")).to_lower() == "orthogonal":
		_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		_camera.size = maxf(1.0, float(view.get("orthogonal_size", 300.0)))
	else:
		_camera.projection = Camera3D.PROJECTION_PERSPECTIVE
		_camera.fov = float(view.get("fov", 58.0))
	_camera.global_position = position
	_camera.look_at(target, Vector3.UP)
	for _i in range(4):
		await process_frame
	var file_name := "%s_%s.png" % [phase, str(view.get("id", "view"))]
	var path := output_dir.path_join(file_name)
	var error := OK
	if manifest_only:
		path = ""
	else:
		var texture := root.get_texture()
		var image := texture.get_image() if texture != null else null
		if image == null:
			error = ERR_CANT_CREATE
		else:
			error = image.save_png(path)
		if error != OK:
			_capture_failures += 1
	var manifest_view := view.duplicate(true)
	manifest_view["file"] = path
	manifest_view["save_error"] = error
	manifest_view["camera_position"] = _vec3_to_array(position)
	manifest_view["camera_target"] = _vec3_to_array(target)
	_manifest["views"].append(manifest_view)
	for entry in hidden_nodes:
		var node := entry.get("node") as Node3D
		if node != null:
			node.visible = bool(entry.get("visible", true))
	_camera.projection = previous_projection
	_camera.size = previous_size
	_camera.fov = previous_fov

func _write_manifest(output_dir: String, phase: String) -> void:
	var path := output_dir.path_join("%s_manifest.json" % phase)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		printerr("[KitchenVisualDiffCapture] failed to write manifest: %s" % path)
		return
	file.store_string(JSON.stringify(_manifest, "\t"))
	file.store_string("\n")
	file.close()

func _route_bounds(route: Array[Vector3]) -> AABB:
	if route.is_empty():
		return AABB(Vector3.ZERO, Vector3.ONE)
	var bounds := AABB(route[0], Vector3.ZERO)
	for i in range(1, route.size()):
		bounds = bounds.expand(route[i])
	return bounds

func _flat_forward(value: Vector3) -> Vector3:
	var out := value
	out.y = 0.0
	if out.length_squared() <= 0.001:
		return Vector3.FORWARD
	return out.normalized()

func _parse_options() -> Dictionary:
	var out := {
		"output_dir": DEFAULT_OUTPUT_DIR,
		"phase": "capture",
		"width": DEFAULT_WIDTH,
		"height": DEFAULT_HEIGHT,
		"manifest_only": false,
	}
	for raw_arg in OS.get_cmdline_user_args():
		var arg := str(raw_arg).strip_edges()
		if not arg.begins_with("--") or not arg.contains("="):
			continue
		var split_index := arg.find("=")
		var key := arg.substr(2, split_index - 2).strip_edges().to_lower()
		var value := arg.substr(split_index + 1).strip_edges()
		match key:
			"output_dir", "phase":
				out[key] = value
			"width", "height":
				if value.is_valid_int():
					out[key] = int(value)
			"manifest_only":
				out[key] = value.to_lower() in ["1", "true", "yes"]
	return out

func _global_output_dir(path: String) -> String:
	var normalized := path.strip_edges().trim_prefix("\"").trim_suffix("\"").replace("\\", "/")
	if normalized.is_empty():
		normalized = DEFAULT_OUTPUT_DIR
	if normalized.begins_with("res://") or normalized.begins_with("user://"):
		return ProjectSettings.globalize_path(normalized)
	if normalized.is_absolute_path():
		return normalized
	return ProjectSettings.globalize_path("res://%s" % normalized)

func _vec3_to_array(value: Vector3) -> Array:
	return [value.x, value.y, value.z]

func _fail(message: String) -> void:
	printerr("[KitchenVisualDiffCapture] %s" % message)
	quit(1)
