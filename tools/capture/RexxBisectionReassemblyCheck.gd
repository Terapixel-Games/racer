@tool
extends SceneTree

const RacerRoster = preload("res://scripts/logic/RacerRoster.gd")

const DEFAULT_OUTPUT_DIR := "res://reports/rexx_bisection_reassembly"
const DEFAULT_BASELINE := "res://assets/optimized/racers/rexx/rexx_racer_in_kart_mobile_detail_phase1.glb"

const VIEWS := [
	{"id": "front", "camera_position": Vector3(0.0, 1.1, 6.0), "camera_target": Vector3(0.0, 0.35, 0.0), "fov": 34.0},
	{"id": "back", "camera_position": Vector3(0.0, 1.1, -6.0), "camera_target": Vector3(0.0, 0.35, 0.0), "fov": 34.0},
	{"id": "left", "camera_position": Vector3(-6.0, 1.1, 0.0), "camera_target": Vector3(0.0, 0.35, 0.0), "fov": 34.0},
	{"id": "right", "camera_position": Vector3(6.0, 1.1, 0.0), "camera_target": Vector3(0.0, 0.35, 0.0), "fov": 34.0},
	{"id": "top", "camera_position": Vector3(0.0, 7.0, 0.05), "camera_target": Vector3(0.0, 0.0, 0.0), "fov": 42.0},
	{"id": "three_quarter", "camera_position": Vector3(4.2, 2.3, 5.4), "camera_target": Vector3(0.0, 0.45, 0.0), "fov": 34.0},
	{"id": "level_select", "camera_position": Vector3(0.0, 1.45, 7.1), "camera_target": Vector3(0.0, 0.8, 0.0), "fov": 34.0},
	{"id": "driving_camera", "camera_position": Vector3(0.0, 2.2, 8.6), "camera_target": Vector3(0.0, 0.65, 0.0), "fov": 42.0},
]

var _scene_root: Node3D
var _camera: Camera3D
var _failures := 0
var _report := {}

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var options := _parse_options()
	var output_dir := _global_output_dir(str(options.get("output_dir", DEFAULT_OUTPUT_DIR)))
	var candidate_path := str(options.get("candidate", "")).strip_edges().trim_prefix("\"").trim_suffix("\"")
	var baseline_path := str(options.get("baseline", DEFAULT_BASELINE)).strip_edges()
	var width := maxi(320, int(options.get("width", 1280)))
	var height := maxi(240, int(options.get("height", 720)))
	root.size = Vector2i(width, height)
	root.transparent_bg = false
	DirAccess.make_dir_recursive_absolute(output_dir)
	_setup_world()

	_report = {
		"schema_version": 1,
		"strategy": "rexx_bisection_reassembly_experiment",
		"baseline_path": baseline_path,
		"candidate_path": candidate_path,
		"width": width,
		"height": height,
		"baseline": {},
		"candidate": {},
		"captures": [],
		"failures": [],
	}

	if candidate_path.is_empty():
		_record_failure("candidate path is required")
		_finish(output_dir)
		return

	_report["baseline"] = await _measure_asset("baseline", baseline_path, true, output_dir)
	_report["candidate"] = await _measure_asset("candidate", candidate_path, false, output_dir)
	_finish(output_dir)

func _setup_world() -> void:
	_scene_root = Node3D.new()
	_scene_root.name = "RexxBisectionReassemblyRoot"
	root.add_child(_scene_root)

	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.16, 0.17, 0.18, 1.0)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.72, 0.74, 0.78, 1.0)
	environment.ambient_light_energy = 0.85
	var world_environment := WorldEnvironment.new()
	world_environment.environment = environment
	root.add_child(world_environment)

	_camera = Camera3D.new()
	_camera.current = true
	root.add_child(_camera)

	var key_light := DirectionalLight3D.new()
	key_light.light_energy = 2.2
	key_light.rotation_degrees = Vector3(-42, -28, 0)
	root.add_child(key_light)

	var fill_light := OmniLight3D.new()
	fill_light.light_energy = 0.9
	fill_light.omni_range = 9.0
	fill_light.position = Vector3(2.6, 2.2, 4.0)
	root.add_child(fill_light)

func _measure_asset(label: String, path: String, resource_path: bool, output_dir: String) -> Dictionary:
	_clear_scene_root()
	var memory_before := _static_memory()
	var load_start := Time.get_ticks_usec()
	var node := _load_asset(path, resource_path)
	var load_usec := Time.get_ticks_usec() - load_start
	if node == null:
		_record_failure("%s failed to load: %s" % [label, path])
		return {"status": "failed", "path": path, "load_usec": load_usec}
	_scene_root.add_child(node)
	node.rotation_degrees.y = RacerRoster.FORWARD_AUTHORED_RACER_IN_KART_YAW_DEGREES
	_fit_node(node)
	for _i in range(8):
		await process_frame
	var memory_after_load := _static_memory()
	var frame_start := Time.get_ticks_usec()
	for _i in range(30):
		await process_frame
	var frame_usec_average := float(Time.get_ticks_usec() - frame_start) / 30.0

	var captures := []
	for view in VIEWS:
		var capture_path := await _capture_view(output_dir, label, view)
		captures.append({"view": str(view.get("id", "")), "file": capture_path})
		(_report["captures"] as Array).append({"asset": label, "view": str(view.get("id", "")), "file": capture_path})

	var counts := _count_render_resources(node)
	var result := {
		"status": "loaded",
		"path": path,
		"bytes": _file_size(path, resource_path),
		"load_usec": load_usec,
		"static_memory_before": memory_before,
		"static_memory_after_load": memory_after_load,
		"static_memory_delta": memory_after_load - memory_before,
		"frame_usec_average": frame_usec_average,
		"captures": captures,
	}
	result.merge(counts)
	return result

func _load_asset(path: String, resource_path: bool) -> Node3D:
	if resource_path:
		if path.is_empty() or not ResourceLoader.exists(path):
			return null
		var packed := load(path) as PackedScene
		return packed.instantiate() as Node3D if packed != null else null

	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	var error := doc.append_from_file(path, state)
	if error != OK:
		_record_failure("GLTFDocument append failed for %s: %d" % [path, error])
		return null
	var generated := doc.generate_scene(state)
	return generated as Node3D

func _capture_view(output_dir: String, label: String, view: Dictionary) -> String:
	_camera.fov = float(view.get("fov", 36.0))
	_camera.global_position = view.get("camera_position", Vector3(0.0, 1.45, 7.1)) as Vector3
	_camera.look_at(view.get("camera_target", Vector3(0.0, 0.8, 0.0)) as Vector3, Vector3.UP)
	for _i in range(4):
		await process_frame
	var viewport_texture := root.get_texture()
	var image := viewport_texture.get_image() if viewport_texture != null else null
	if image == null:
		_record_failure("viewport image unavailable for %s %s; headless dummy rendering may be active" % [label, str(view.get("id", "view"))])
		return ""
	var path := output_dir.path_join("%s_%s.png" % [label, str(view.get("id", "view"))])
	var error := image.save_png(path)
	if error != OK:
		_record_failure("failed to save %s: %d" % [path, error])
		return ""
	return path

func _fit_node(node: Node3D) -> void:
	var bounds := _combined_mesh_bounds(node)
	if bounds.size == Vector3.ZERO:
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

func _count_render_resources(node: Node) -> Dictionary:
	var mesh_instances := 0
	var material_slots := 0
	var surface_count := 0
	var node_count := 0
	var stack: Array[Node] = [node]
	while not stack.is_empty():
		var current: Node = stack.pop_back()
		node_count += 1
		if current is MeshInstance3D:
			mesh_instances += 1
			var mesh_instance := current as MeshInstance3D
			if mesh_instance.mesh != null:
				surface_count += mesh_instance.mesh.get_surface_count()
				material_slots += mesh_instance.mesh.get_surface_count()
		for child in current.get_children():
			stack.append(child)
	return {
		"node_count": node_count,
		"mesh_instance_count": mesh_instances,
		"surface_count": surface_count,
		"material_slot_count": material_slots,
	}

func _clear_scene_root() -> void:
	for child in _scene_root.get_children():
		_scene_root.remove_child(child)
		child.free()

func _finish(output_dir: String) -> void:
	var report_path := output_dir.path_join("rexx_bisection_reassembly_report.json")
	var file := FileAccess.open(report_path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(_report, "\t"))
		file.store_string("\n")
		file.close()
	print(JSON.stringify(_report, "\t"))
	quit(1 if _failures > 0 else 0)

func _record_failure(message: String) -> void:
	_failures += 1
	if not _report.has("failures"):
		_report["failures"] = []
	(_report["failures"] as Array).append(message)
	printerr("[RexxBisectionReassemblyCheck] %s" % message)

func _parse_options() -> Dictionary:
	var out := {
		"candidate": "",
		"baseline": DEFAULT_BASELINE,
		"output_dir": DEFAULT_OUTPUT_DIR,
		"width": 1280,
		"height": 720,
	}
	for raw_arg in OS.get_cmdline_user_args():
		var arg := str(raw_arg).strip_edges()
		if not arg.begins_with("--") or not arg.contains("="):
			continue
		var split_index := arg.find("=")
		var key := arg.substr(2, split_index - 2).strip_edges().to_lower()
		var value := arg.substr(split_index + 1).strip_edges()
		match key:
			"candidate", "baseline", "output_dir":
				out[key] = value
			"width", "height":
				if value.is_valid_int():
					out[key] = int(value)
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

func _file_size(path: String, resource_path: bool) -> int:
	var absolute := ProjectSettings.globalize_path(path) if resource_path else path
	if not FileAccess.file_exists(absolute):
		return 0
	var file := FileAccess.open(absolute, FileAccess.READ)
	if file == null:
		return 0
	var length := file.get_length()
	file.close()
	return length

func _static_memory() -> int:
	return int(Performance.get_monitor(Performance.MEMORY_STATIC))
