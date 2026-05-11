@tool
extends SceneTree

const RacerRoster = preload("res://scripts/logic/RacerRoster.gd")
const RacerVisualRegression = preload("res://scripts/logic/RacerVisualRegression.gd")

const DEFAULT_OUTPUT_DIR := "res://reports/racer_visual_regression"

var _camera: Camera3D
var _scene_root: Node3D
var _capture_failures := 0
var _manifest := {}

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var options := _parse_options()
	var output_dir := _global_output_dir(str(options.get("output_dir", DEFAULT_OUTPUT_DIR)))
	var phase := str(options.get("phase", "candidate")).strip_edges().to_lower()
	if phase.is_empty():
		phase = "candidate"
	var manifest_only := bool(options.get("manifest_only", false))
	var width := maxi(320, int(options.get("width", RacerVisualRegression.DEFAULT_WIDTH)))
	var height := maxi(240, int(options.get("height", RacerVisualRegression.DEFAULT_HEIGHT)))
	var racers := _parse_racers(str(options.get("racers", "")))
	var target_filter := _parse_filter(str(options.get("targets", "")))

	root.size = Vector2i(width, height)
	root.transparent_bg = false
	DirAccess.make_dir_recursive_absolute(output_dir)

	_setup_world()
	_manifest = {
		"schema_version": 1,
		"phase": phase,
		"width": width,
		"height": height,
		"asset_profile": RacerRoster.get_racer_asset_profile(),
		"detail_score_threshold": RacerVisualRegression.DETAIL_SCORE_THRESHOLD,
		"full_score_threshold": RacerVisualRegression.FULL_SCORE_THRESHOLD,
		"captures": [],
		"failed_attempts": [],
	}

	for racer_id in racers:
		for target in RacerVisualRegression.capture_targets():
			if not target_filter.is_empty() and not target_filter.has(str(target.get("id", ""))):
				continue
			await _capture_target(output_dir, phase, racer_id, target, width, height, manifest_only)

	_write_manifest(output_dir, phase)
	if _capture_failures > 0:
		printerr("[RacerVisualRegressionCapture] failed captures=%d" % _capture_failures)
		quit(1)
		return
	print("[RacerVisualRegressionCapture] wrote %d captures to %s" % [(_manifest.get("captures", []) as Array).size(), output_dir])
	quit(0)

func _setup_world() -> void:
	_scene_root = Node3D.new()
	_scene_root.name = "RacerVisualRegressionRoot"
	root.add_child(_scene_root)

	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.16, 0.17, 0.18, 1.0)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.72, 0.74, 0.78, 1.0)
	environment.ambient_light_energy = 0.85
	var world_environment := WorldEnvironment.new()
	world_environment.name = "RacerVisualRegressionEnvironment"
	world_environment.environment = environment
	root.add_child(world_environment)

	_camera = Camera3D.new()
	_camera.name = "RacerVisualRegressionCamera"
	_camera.current = true
	root.add_child(_camera)

	var key_light := DirectionalLight3D.new()
	key_light.name = "KeyLight"
	key_light.light_energy = 2.2
	key_light.rotation_degrees = Vector3(-42, -28, 0)
	root.add_child(key_light)

	var fill_light := OmniLight3D.new()
	fill_light.name = "FillLight"
	fill_light.light_energy = 0.9
	fill_light.omni_range = 9.0
	fill_light.position = Vector3(2.6, 2.2, 4.0)
	root.add_child(fill_light)

func _capture_target(output_dir: String, phase: String, racer_id: String, target: Dictionary, width: int, height: int, manifest_only: bool) -> void:
	_clear_scene_root()
	var normalized := RacerRoster.normalize_id(racer_id)
	var target_id := str(target.get("id", "capture"))
	var requested_lod := RacerRoster.normalize_model_lod(str(target.get("lod", RacerRoster.RACER_MODEL_LOD0)))
	var model_path := RacerRoster.get_racer_in_kart_model_path_for_lod(normalized, requested_lod, false)
	var capture := {
		"racer_id": normalized,
		"target": target_id,
		"requested_lod": requested_lod,
		"selected_asset_profile": RacerRoster.get_racer_asset_profile(),
		"model_path": model_path,
		"model_bytes": _file_size(model_path),
		"note": str(target.get("note", "")),
		"crops": [],
	}

	var node := _build_target_node(normalized, target)
	if node == null:
		_capture_failures += 1
		capture["status"] = "failed"
		capture["error"] = "target node failed to build"
		(_manifest["failed_attempts"] as Array).append(capture.duplicate(true))
		(_manifest["captures"] as Array).append(capture)
		return
	_scene_root.add_child(node)
	if str(target.get("kind", "model")) == "car" and node.has_method("set_racer_visual_lod"):
		node.call("set_racer_visual_lod", normalized, requested_lod)
	_fit_node(node)

	_camera.fov = float(target.get("fov", 36.0))
	_camera.global_position = target.get("camera_position", Vector3(0.0, 1.45, 7.1)) as Vector3
	_camera.look_at(target.get("camera_target", Vector3(0.0, 0.8, 0.0)) as Vector3, Vector3.UP)
	for _i in range(8):
		await process_frame

	var file_name := "%s_%s_%s.png" % [phase, normalized.to_snake_case(), target_id]
	var image_path := output_dir.path_join(file_name)
	var image: Image = null
	var save_error := OK
	if not manifest_only:
		var texture := root.get_texture()
		image = texture.get_image() if texture != null else null
		if image == null:
			save_error = ERR_CANT_CREATE
		else:
			save_error = image.save_png(image_path)
	else:
		image_path = ""

	if save_error != OK:
		_capture_failures += 1
		capture["status"] = "failed"
		capture["error"] = "png save failed: %d" % save_error
		(_manifest["failed_attempts"] as Array).append(capture.duplicate(true))
	else:
		capture["status"] = "captured"
	capture["file"] = image_path
	capture["save_error"] = save_error
	capture["camera_position"] = _vec3_to_array(_camera.global_position)
	capture["camera_target"] = _vec3_to_array(target.get("camera_target", Vector3.ZERO) as Vector3)
	capture["full_score_threshold"] = RacerVisualRegression.FULL_SCORE_THRESHOLD
	capture["detail_score_threshold"] = RacerVisualRegression.DETAIL_SCORE_THRESHOLD

	for crop_id in RacerVisualRegression.DETAIL_CROPS.keys():
		var normalized_rect := RacerVisualRegression.DETAIL_CROPS[crop_id] as Rect2
		var pixel_rect := RacerVisualRegression.normalized_to_pixel_rect(normalized_rect, width, height)
		var crop_path := ""
		var crop_error := OK
		if image != null:
			crop_path = output_dir.path_join("%s_%s_%s_%s.png" % [phase, normalized.to_snake_case(), target_id, crop_id])
			crop_error = image.get_region(pixel_rect).save_png(crop_path)
		(capture["crops"] as Array).append({
			"id": crop_id,
			"file": crop_path,
			"normalized_rect": RacerVisualRegression.normalized_rect_to_array(normalized_rect),
			"pixel_rect": RacerVisualRegression.rect_to_array(pixel_rect),
			"score_threshold": RacerVisualRegression.DETAIL_SCORE_THRESHOLD,
			"save_error": crop_error,
		})

	(_manifest["captures"] as Array).append(capture)

func _build_target_node(racer_id: String, target: Dictionary) -> Node3D:
	if str(target.get("kind", "model")) == "car":
		var car_scene := load("res://scenes/Car.tscn") as PackedScene
		if car_scene == null:
			return null
		var car := car_scene.instantiate() as Node3D
		if car == null:
			return null
		return car

	var model_path := RacerRoster.get_racer_in_kart_model_path_for_lod(racer_id, str(target.get("lod", RacerRoster.RACER_MODEL_LOD0)), false)
	if model_path.is_empty() or not ResourceLoader.exists(model_path):
		return null
	var packed := load(model_path) as PackedScene
	if packed == null:
		return null
	var model := packed.instantiate() as Node3D
	if model == null:
		return null
	model.rotation_degrees.y = RacerRoster.get_racer_in_kart_yaw_degrees(racer_id)
	return model

func _fit_node(node: Node3D) -> void:
	var bounds := _combined_mesh_bounds(node)
	if bounds.size == Vector3.ZERO:
		node.position = Vector3.ZERO
		node.scale = Vector3.ONE
		return
	var max_dimension: float = maxf(bounds.size.x, maxf(bounds.size.y, bounds.size.z))
	var scale_factor := 3.4 / maxf(max_dimension, 0.001)
	var center := bounds.get_center()
	node.scale = Vector3.ONE * scale_factor
	node.position = Vector3(-center.x * scale_factor, -center.y * scale_factor + 0.15, -center.z * scale_factor)

func _combined_mesh_bounds(node: Node) -> AABB:
	var has_bounds := false
	var combined := AABB()
	var stack: Array[Node] = [node]
	while not stack.is_empty():
		var current: Node = stack.pop_back()
		if current is MeshInstance3D:
			var mesh_instance := current as MeshInstance3D
			if mesh_instance.mesh != null:
				var local_bounds := mesh_instance.get_aabb()
				for i in range(8):
					var point: Vector3 = mesh_instance.global_transform * local_bounds.get_endpoint(i)
					if not has_bounds:
						combined = AABB(point, Vector3.ZERO)
						has_bounds = true
					else:
						combined = combined.expand(point)
		for child in current.get_children():
			stack.append(child)
	return combined if has_bounds else AABB()

func _clear_scene_root() -> void:
	for child in _scene_root.get_children():
		_scene_root.remove_child(child)
		child.free()

func _write_manifest(output_dir: String, phase: String) -> void:
	var path := output_dir.path_join("%s_manifest.json" % phase)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		printerr("[RacerVisualRegressionCapture] failed to write manifest: %s" % path)
		return
	file.store_string(JSON.stringify(_manifest, "\t"))
	file.store_string("\n")
	file.close()

func _parse_options() -> Dictionary:
	var out := {
		"output_dir": DEFAULT_OUTPUT_DIR,
		"phase": "candidate",
		"width": RacerVisualRegression.DEFAULT_WIDTH,
		"height": RacerVisualRegression.DEFAULT_HEIGHT,
		"racers": "",
		"targets": "",
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
			"output_dir", "phase", "racers", "targets":
				out[key] = value
			"width", "height":
				if value.is_valid_int():
					out[key] = int(value)
			"manifest_only":
				out[key] = value.to_lower() in ["1", "true", "yes"]
	return out

func _parse_racers(raw: String) -> Array[String]:
	var out: Array[String] = []
	for part in raw.split(",", false):
		var racer_id := RacerRoster.normalize_id(part.strip_edges())
		if RacerRoster.has(racer_id):
			out.append(racer_id)
	if out.is_empty():
		out.assign(RacerVisualRegression.DEFAULT_RACERS)
	return out

func _parse_filter(raw: String) -> Dictionary:
	var out := {}
	for part in raw.split(",", false):
		var key := part.strip_edges()
		if not key.is_empty():
			out[key] = true
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

func _file_size(res_path: String) -> int:
	if res_path.is_empty():
		return 0
	var path := ProjectSettings.globalize_path(res_path)
	if not FileAccess.file_exists(path):
		return 0
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return 0
	var length := file.get_length()
	file.close()
	return length

func _vec3_to_array(value: Vector3) -> Array[float]:
	return [value.x, value.y, value.z]
