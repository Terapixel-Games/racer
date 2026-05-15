@tool
extends SceneTree

const TrackCatalog = preload("res://scripts/track/TrackCatalog.gd")
const TrackRuntimeBuilder = preload("res://scripts/track/TrackRuntimeBuilder.gd")
const TrackSceneAuthoringData = preload("res://scripts/track/TrackSceneAuthoringData.gd")
const HomeYardVisualGateContract = preload("res://scripts/logic/HomeYardVisualGateContract.gd")

const DEFAULT_OUTPUT_DIR := "res://tmp/visual_diffs/stages"
const DEFAULT_WIDTH := 1600
const DEFAULT_HEIGHT := 900
const DEFAULT_TRACK_IDS := [
	"attic",
	"bedroom",
	"glam_closet",
	"kitchen",
	"playroom",
	"outdoor_playground",
	"garden",
	"sandbox",
]
const INDOOR_TRACK_IDS := [
	"attic",
	"bedroom",
	"glam_closet",
	"kitchen",
	"playroom",
]

var _camera: Camera3D
var _track_node: Node3D
var _capture_failures := 0
var _manifest := {
	"schema_version": 1,
	"phase": "capture",
	"tracks": [],
	"views": [],
	"failed_attempts": [],
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
	var track_ids := _parse_track_ids(str(options.get("track_id", "all")))
	root.size = Vector2i(width, height)
	root.transparent_bg = false
	DirAccess.make_dir_recursive_absolute(output_dir)

	_camera = Camera3D.new()
	_camera.name = "StageVisualDiffCamera"
	_camera.current = true
	_camera.fov = 58.0
	_camera.near = 0.05
	_camera.far = 2000.0
	root.add_child(_camera)

	_manifest = {
		"schema_version": 1,
		"phase": phase,
		"width": width,
		"height": height,
		"tracks": track_ids,
		"views": [],
		"failed_attempts": [],
	}

	for track_id in track_ids:
		await _capture_track(track_id, output_dir, phase, manifest_only)

	_write_manifest(output_dir, phase)
	_clear_track()
	if _capture_failures > 0:
		_fail("failed to capture %d views" % _capture_failures)
		return
	print("[StageVisualDiffCapture] wrote %d views to %s" % [(_manifest.get("views", []) as Array).size(), output_dir])
	quit(0)

func _capture_track(track_id: String, output_dir: String, phase: String, manifest_only: bool) -> void:
	_clear_track()
	var definition := TrackSceneAuthoringData.apply_to_definition(TrackCatalog.get_definition(track_id))
	if definition == null:
		_record_failure(track_id, "definition failed to load")
		return
	var built := TrackRuntimeBuilder.build(definition)
	_track_node = built.get("node", null) as Node3D
	if _track_node == null:
		_record_failure(track_id, "runtime track failed to build")
		return
	_track_node.name = "CapturedTrack_%s" % track_id
	root.add_child(_track_node)
	for _i in range(8):
		await process_frame

	for view in _camera_views(track_id, definition):
		await _capture_view(track_id, output_dir, phase, view, manifest_only)

func _camera_views(track_id: String, definition) -> Array[Dictionary]:
	var route: Array[Vector3] = definition.route_points
	var bounds := _route_bounds(route)
	var center := bounds.get_center()
	var size := bounds.size
	var start := route[0] if not route.is_empty() else Vector3.ZERO
	var second := route[1] if route.size() > 1 else start + Vector3.FORWARD
	var third := route[2] if route.size() > 2 else second + (second - start)
	var start_forward := _flat_forward(second - start)
	var second_forward := _flat_forward(third - second)
	var start_right := Vector3(start_forward.z, 0.0, -start_forward.x).normalized()
	var second_right := Vector3(second_forward.z, 0.0, -second_forward.x).normalized()
	var overhead_hidden: Array[String] = []
	if INDOOR_TRACK_IDS.has(track_id):
		overhead_hidden.append("Dressing/EditableRoom/RoomShell/Ceiling")

	var views: Array[Dictionary] = [
		{
			"id": "start_grid",
			"position": start - start_forward * 54.0 + start_right * 10.0 + Vector3.UP * 28.0,
			"target": start + start_forward * 36.0 + Vector3.UP * 4.0,
			"note": "Start grid, first turn, and ordered_route_cells[0] alignment.",
		},
		{
			"id": "low_player_view",
			"position": start - start_forward * 30.0 + start_right * 7.0 + Vector3.UP * 5.0,
			"target": start + start_forward * 44.0 + Vector3.UP * 4.0,
			"fov": 68.0,
			"note": "Low kart-height read for leaks, clutter, and first-ten-second route clarity.",
		},
		{
			"id": "third_person_launch",
			"position": start - start_forward * HomeYardVisualGateContract.CHASE_CAMERA_DISTANCE + Vector3.UP * HomeYardVisualGateContract.CHASE_CAMERA_HEIGHT,
			"target": start + Vector3.UP * HomeYardVisualGateContract.CHASE_CAMERA_LOOK_HEIGHT,
			"fov": 58.0,
			"note": "Third-person chase-camera launch view; fails if props, walls, or shell pieces fill the central view or make the kart read as blocked.",
		},
		{
			"id": "first_turn_chase",
			"position": second - second_forward * HomeYardVisualGateContract.CHASE_CAMERA_DISTANCE + second_right * 0.75 + Vector3.UP * HomeYardVisualGateContract.CHASE_CAMERA_HEIGHT,
			"target": second + Vector3.UP * HomeYardVisualGateContract.CHASE_CAMERA_LOOK_HEIGHT,
			"fov": 58.0,
			"note": "Third-person first-turn chase view; road, next turn, and exit lane must remain readable.",
		},
		{
			"id": "overhead_route",
			"position": center + Vector3(0.0, maxf(120.0, maxf(size.x, size.z) * 0.9), 0.01),
			"target": center,
			"projection": "orthogonal",
			"orthogonal_size": maxf(size.x, size.z) + 120.0,
			"hidden_paths": overhead_hidden,
			"note": "Route shape, stage-specific blockout, and containment overview.",
		},
		{
			"id": "level_select_angle",
			"position": _level_select_camera_position(track_id, center, size),
			"target": center + Vector3(0.0, 8.0, 0.0),
			"fov": 52.0,
			"note": "Preview composition and hero landmark read.",
		},
		{
			"id": "camera_clearance",
			"position": center - start_forward * 72.0 + Vector3.UP * 34.0,
			"target": center + start_forward * 36.0 + Vector3.UP * 12.0,
			"fov": 58.0,
			"note": "Worst-case stage ceiling/landmark clearance from third-person chase-camera height.",
		},
		{
			"id": "envelope_seams",
			"position": _envelope_camera_position(track_id, center, size),
			"target": center + Vector3(0.0, 16.0, 0.0),
			"fov": 54.0,
			"note": "Indoor room seams or outdoor horizon containment.",
		},
	]

	for ratio in [0.25, 0.5, 0.75]:
		views.append(_route_sample_view(route, ratio))
	for view in _elevation_transition_views(route):
		views.append(view)
	for view in _hero_landmark_views(definition, center):
		views.append(view)
	for view in _interaction_views(definition):
		views.append(view)
	for i in range(views.size()):
		var view := views[i]
		views[i] = _with_visual_gate_metadata(view)
	return views

func _route_sample_view(route: Array[Vector3], ratio: float) -> Dictionary:
	if route.is_empty():
		return {
			"id": "route_sample_%d" % int(ratio * 100.0),
			"position": Vector3(0, 24, -64),
			"target": Vector3.ZERO,
		}
	var index := clampi(int(round((route.size() - 1) * ratio)), 0, route.size() - 1)
	var point := route[index]
	var next := route[(index + 1) % route.size()] if route.size() > 1 else point + Vector3.FORWARD
	var forward := _flat_forward(next - point)
	var right := Vector3(forward.z, 0.0, -forward.x).normalized()
	return {
		"id": "route_sample_%d" % int(ratio * 100.0),
		"position": point - forward * 38.0 + right * 14.0 + Vector3.UP * 18.0,
		"target": point + forward * 36.0 + Vector3.UP * 5.0,
		"fov": 62.0,
		"note": "Representative third-person playable route sample at %d percent; route corridor and chase-camera view must stay clear." % int(ratio * 100.0),
	}

func _with_visual_gate_metadata(view: Dictionary) -> Dictionary:
	var out := view.duplicate(true)
	var view_id := str(out.get("id", "view"))
	var gate_metadata := HomeYardVisualGateContract.gate_metadata(view_id)
	for key in gate_metadata.keys():
		out[key] = gate_metadata[key]
	return out

func _elevation_transition_views(route: Array[Vector3]) -> Array[Dictionary]:
	var views: Array[Dictionary] = []
	if route.size() < 2:
		return views
	for i in range(route.size()):
		var current := route[i]
		var next := route[(i + 1) % route.size()]
		if absf(next.y - current.y) < 0.1:
			continue
		var forward := _flat_forward(next - current)
		var right := Vector3(forward.z, 0.0, -forward.x).normalized()
		var mid := current.lerp(next, 0.5)
		var direction_label := "climb" if next.y > current.y else "descent"
		views.append({
			"id": "elevation_%s_%d" % [direction_label, views.size()],
			"position": mid + right * 64.0 + Vector3.UP * 24.0,
			"target": mid + Vector3.UP * 5.0,
			"fov": 50.0,
			"note": "Side-profile check for %s transition, ramp orientation, landing clearance, and containment." % direction_label,
		})
		if views.size() >= 3:
			break
	return views

func _hero_landmark_views(definition, route_center: Vector3) -> Array[Dictionary]:
	var views: Array[Dictionary] = []
	var props: Array = definition.stage_props
	for i in range(mini(3, props.size())):
		var prop := props[i] as Dictionary
		var prop_id := str(prop.get("id", "stage_prop_%d" % i))
		var position := _point_from_value(prop.get("position", route_center), route_center)
		var offset := _flat_forward(route_center - position)
		if offset.length_squared() <= 0.001:
			offset = Vector3(0.7, 0.0, 0.7).normalized()
		views.append({
			"id": "hero_landmark_%s" % prop_id.to_snake_case(),
			"position": position - offset * 58.0 + Vector3.UP * 28.0,
			"target": position + Vector3.UP * 9.0,
			"fov": 48.0,
			"note": "Hero landmark check for %s." % prop_id,
		})
	return views

func _interaction_views(definition) -> Array[Dictionary]:
	var views: Array[Dictionary] = []
	for interaction in definition.stage_interactions:
		var data := interaction as Dictionary
		var interaction_id := str(data.get("id", "stage_interaction"))
		var position := _point_from_value(data.get("position", Vector3.ZERO), Vector3.ZERO)
		var yaw := deg_to_rad(float(data.get("yaw_degrees", 0.0)))
		var forward := Vector3(sin(yaw), 0.0, cos(yaw))
		if forward.length_squared() <= 0.001:
			forward = Vector3.FORWARD
		views.append({
			"id": "interaction_%s" % interaction_id.to_snake_case(),
			"position": position - forward.normalized() * 46.0 + Vector3.UP * 22.0,
			"target": position + Vector3.UP * 4.0,
			"fov": 54.0,
			"note": "Interaction zone anchor, readability, and surrounding lane check for %s." % interaction_id,
		})
	return views

func _envelope_camera_position(track_id: String, center: Vector3, size: Vector3) -> Vector3:
	if INDOOR_TRACK_IDS.has(track_id):
		return center + Vector3(size.x * 0.5 + 72.0, 58.0, -size.z * 0.5 - 84.0)
	return center + Vector3(size.x * 0.55 + 110.0, 64.0, -size.z * 0.55 - 110.0)

func _level_select_camera_position(track_id: String, center: Vector3, size: Vector3) -> Vector3:
	if INDOOR_TRACK_IDS.has(track_id):
		return center + Vector3(
			minf(size.x * 0.32 + 42.0, 128.0),
			46.0,
			minf(size.z * 0.28 + 38.0, 86.0)
		)
	return center + Vector3(size.x * 0.42 + 86.0, 76.0, size.z * 0.46 + 92.0)

func _capture_view(track_id: String, output_dir: String, phase: String, view: Dictionary, manifest_only: bool) -> void:
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
	for _i in range(5):
		await process_frame
	var file_name := "%s_%s_%s.png" % [phase, track_id, str(view.get("id", "view"))]
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
		_record_failure(track_id, "png save failed for %s: %d" % [str(view.get("id", "view")), error])
	var manifest_view := view.duplicate(true)
	manifest_view["track_id"] = track_id
	manifest_view["file"] = path
	manifest_view["save_error"] = error
	manifest_view["camera_position"] = _vec3_to_array(position)
	manifest_view["camera_target"] = _vec3_to_array(target)
	(_manifest["views"] as Array).append(manifest_view)
	for entry in hidden_nodes:
		var node := entry.get("node") as Node3D
		if node != null:
			node.visible = bool(entry.get("visible", true))
	_camera.projection = previous_projection
	_camera.size = previous_size
	_camera.fov = previous_fov

func _clear_track() -> void:
	if _track_node == null:
		return
	if _track_node.get_parent() != null:
		_track_node.get_parent().remove_child(_track_node)
	_track_node.free()
	_track_node = null

func _write_manifest(output_dir: String, phase: String) -> void:
	var path := output_dir.path_join("%s_manifest.json" % phase)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		printerr("[StageVisualDiffCapture] failed to write manifest: %s" % path)
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

func _point_from_value(value, fallback: Vector3) -> Vector3:
	if value is Vector3:
		return value
	if value is Array and (value as Array).size() >= 3:
		return Vector3(float(value[0]), float(value[1]), float(value[2]))
	return fallback

func _parse_options() -> Dictionary:
	var out := {
		"track_id": "all",
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
			"track_id", "output_dir", "phase":
				out[key] = value
			"width", "height":
				if value.is_valid_int():
					out[key] = int(value)
			"manifest_only":
				out[key] = value.to_lower() in ["1", "true", "yes"]
	return out

func _parse_track_ids(raw_value: String) -> Array[String]:
	var normalized := raw_value.strip_edges().to_lower()
	if normalized.is_empty() or normalized == "all":
		return _default_track_ids()
	var out: Array[String] = []
	for raw_part in normalized.split(",", false):
		var track_id := raw_part.strip_edges()
		if DEFAULT_TRACK_IDS.has(track_id) and not out.has(track_id):
			out.append(track_id)
	return out if not out.is_empty() else _default_track_ids()

func _default_track_ids() -> Array[String]:
	var out: Array[String] = []
	for track_id in DEFAULT_TRACK_IDS:
		out.append(str(track_id))
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

func _record_failure(track_id: String, message: String) -> void:
	_capture_failures += 1
	(_manifest["failed_attempts"] as Array).append({
		"track_id": track_id,
		"message": message,
	})
	printerr("[StageVisualDiffCapture] %s: %s" % [track_id, message])

func _fail(message: String) -> void:
	printerr("[StageVisualDiffCapture] %s" % message)
	quit(1)
