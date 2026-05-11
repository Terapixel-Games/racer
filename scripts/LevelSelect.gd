extends Control

const TrackCatalog = preload("res://scripts/track/TrackCatalog.gd")
const TrackRuntimeBuilder = preload("res://scripts/track/TrackRuntimeBuilder.gd")
const NavigationFlow = preload("res://scripts/logic/NavigationFlow.gd")
const RacerRoster = preload("res://scripts/logic/RacerRoster.gd")

const PREVIEW_CAMERA_ROUTE_SPEED := 0.035
const PREVIEW_CAMERA_BLEND := 0.055
const RACER_PREVIEW_ROTATION_SPEED := 0.75
const RACER_PREVIEW_TARGET_SIZE := 3.4

var _tracks: Array[Dictionary] = []
var _track_index := 0
var _racer_ids: Array[String] = []
var _racer_index := 0
var _selected_racer_id := RacerRoster.DEFAULT_RACER_ID
var _preview_root: Node3D
var _camera: Camera3D
var _route_points: Array[Vector3] = []
var _preview_time := 0.0
var _preview_cache: Dictionary = {}
var _threaded_scene_requests: Dictionary = {}
var _racer_preview_anchor: Node3D
var _racer_preview_model: Node3D

var _title_label: Label
var _track_name_label: Label
var _meta_label: Label
var _racer_name_label: Label
var _racer_meta_label: Label
var _select_button: Button
var _prev_button: Button
var _next_button: Button
var _racer_prev_button: Button
var _racer_next_button: Button

func _ready() -> void:
	_tracks = TrackCatalog.list_tracks()
	_racer_ids = RacerRoster.select_order()
	_selected_racer_id = RacerRoster.normalize_id(str(NakamaService.get_meta_value("selected_racer_id", RacerRoster.DEFAULT_RACER_ID)))
	_racer_index = maxi(0, _racer_ids.find(_selected_racer_id))
	_request_all_scene_preloads()
	_build_screen()
	_show_selected_track(false)
	_show_selected_racer(false)

func _exit_tree() -> void:
	_dispose_racer_preview_model()
	for build in _preview_cache.values():
		if not (build is Dictionary):
			continue
		var node := (build as Dictionary).get("node", null) as Node
		if node != null and is_instance_valid(node):
			node.queue_free()
	_preview_cache.clear()

func _process(delta: float) -> void:
	_preview_time += delta
	_update_preview_camera()
	if _racer_preview_anchor != null:
		_racer_preview_anchor.rotate_y(delta * RACER_PREVIEW_ROTATION_SPEED)

func get_track_count() -> int:
	return _tracks.size()

func get_selected_track_id() -> String:
	if _tracks.is_empty():
		return ""
	return str(_tracks[_track_index].get("id", ""))

func apply_selected_track_for_test() -> void:
	_apply_selected_track_metadata()

func get_selected_racer_id_for_test() -> String:
	return _selected_racer_id

func select_racer_for_test(racer_id: String) -> bool:
	var normalized := racer_id.strip_edges()
	if not RacerRoster.has(normalized):
		return false
	for i in range(_racer_ids.size()):
		if _racer_ids[i] == normalized:
			_racer_index = i
			_show_selected_racer(false)
			return true
	return false

func racer_preview_has_model_for_test() -> bool:
	return _racer_preview_model != null and is_instance_valid(_racer_preview_model)

func racer_preview_rotation_for_test() -> float:
	if _racer_preview_anchor == null:
		return 0.0
	return _racer_preview_anchor.rotation.y

func select_track_for_test(track_id: String) -> bool:
	for i in range(_tracks.size()):
		if str((_tracks[i] as Dictionary).get("id", "")) == track_id:
			_track_index = i
			_show_selected_track(false)
			return true
	return false

func get_back_target_for_test() -> String:
	return "res://scenes/CharacterSelect.tscn"

func preview_has_visible_road_edges_for_test() -> bool:
	return _has_visible_preview_road_edges(_preview_root)

func preview_has_visible_rails_for_test() -> bool:
	return _has_visible_named_node(_preview_root, "Rails")

func preview_has_backyard_dressing_for_test() -> bool:
	return (
		_has_visible_named_node(_preview_root, "PlaygroundSet")
		and _has_visible_named_node(_preview_root, "SwingSet")
		and _has_visible_named_node(_preview_root, "SandboxFossil")
	)

func _build_screen() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	anchor_right = 1.0
	anchor_bottom = 1.0

	var background := ColorRect.new()
	background.name = "Background"
	background.color = Color(0.035, 0.04, 0.055, 1.0)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var preview_container := SubViewportContainer.new()
	preview_container.name = "Preview"
	preview_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	preview_container.stretch = true
	preview_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(preview_container)

	var viewport := SubViewport.new()
	viewport.name = "SubViewport"
	viewport.size = Vector2i(1280, 720)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	preview_container.add_child(viewport)

	_preview_root = Node3D.new()
	_preview_root.name = "PreviewRoot"
	viewport.add_child(_preview_root)

	_camera = Camera3D.new()
	_camera.name = "PreviewCamera"
	_camera.current = true
	_camera.fov = 64.0
	viewport.add_child(_camera)

	var light := DirectionalLight3D.new()
	light.name = "PreviewLight"
	light.light_energy = 1.4
	light.rotation_degrees = Vector3(-55, 35, 0)
	viewport.add_child(light)

	_build_racer_preview_layer()

	var scrim := ColorRect.new()
	scrim.name = "Scrim"
	scrim.color = Color(0.0, 0.0, 0.0, 0.28)
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(scrim)

	var margin := MarginContainer.new()
	margin.name = "Layout"
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 24)
	add_child(margin)

	var root := VBoxContainer.new()
	root.name = "Root"
	root.add_theme_constant_override("separation", 18)
	margin.add_child(root)

	var header := HBoxContainer.new()
	header.name = "Header"
	root.add_child(header)

	var title_box := VBoxContainer.new()
	title_box.name = "TitleBox"
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_box)

	_title_label = Label.new()
	_title_label.name = "Title"
	_title_label.text = "Select Track"
	_title_label.add_theme_font_size_override("font_size", 48)
	_title_label.add_theme_color_override("font_color", Color(1.0, 0.96, 0.82, 1.0))
	title_box.add_child(_title_label)

	_meta_label = Label.new()
	_meta_label.name = "Meta"
	_meta_label.text = ""
	_meta_label.add_theme_font_size_override("font_size", 18)
	_meta_label.add_theme_color_override("font_color", Color(0.78, 0.86, 0.98, 0.95))
	title_box.add_child(_meta_label)

	var back_button := _make_button("Back", Vector2(118, 52))
	back_button.name = "BackButton"
	back_button.pressed.connect(_go_back)
	header.add_child(back_button)

	var spacer := Control.new()
	spacer.name = "Spacer"
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(spacer)

	var racer_dock := HBoxContainer.new()
	racer_dock.name = "RacerDock"
	racer_dock.alignment = BoxContainer.ALIGNMENT_CENTER
	racer_dock.add_theme_constant_override("separation", 12)
	root.add_child(racer_dock)

	_racer_prev_button = _make_button("<", Vector2(68, 58))
	_racer_prev_button.name = "PrevRacerButton"
	_racer_prev_button.pressed.connect(_cycle_racer.bind(-1))
	racer_dock.add_child(_racer_prev_button)

	var racer_panel := PanelContainer.new()
	racer_panel.name = "RacerPanel"
	racer_panel.custom_minimum_size = Vector2(340, 82)
	racer_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.045, 0.05, 0.075, 0.74), Color(0.38, 0.72, 1.0, 0.55), 2, 14))
	racer_dock.add_child(racer_panel)

	var racer_margin := MarginContainer.new()
	racer_margin.add_theme_constant_override("margin_left", 16)
	racer_margin.add_theme_constant_override("margin_top", 10)
	racer_margin.add_theme_constant_override("margin_right", 16)
	racer_margin.add_theme_constant_override("margin_bottom", 10)
	racer_panel.add_child(racer_margin)

	var racer_box := VBoxContainer.new()
	racer_box.add_theme_constant_override("separation", 2)
	racer_margin.add_child(racer_box)

	_racer_name_label = Label.new()
	_racer_name_label.name = "RacerName"
	_racer_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_racer_name_label.add_theme_font_size_override("font_size", 26)
	_racer_name_label.add_theme_color_override("font_color", Color(1.0, 0.96, 0.82, 1.0))
	racer_box.add_child(_racer_name_label)

	_racer_meta_label = Label.new()
	_racer_meta_label.name = "RacerMeta"
	_racer_meta_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_racer_meta_label.add_theme_font_size_override("font_size", 15)
	_racer_meta_label.add_theme_color_override("font_color", Color(0.76, 0.9, 1.0, 0.92))
	racer_box.add_child(_racer_meta_label)

	_racer_next_button = _make_button(">", Vector2(68, 58))
	_racer_next_button.name = "NextRacerButton"
	_racer_next_button.pressed.connect(_cycle_racer.bind(1))
	racer_dock.add_child(_racer_next_button)

	var footer := HBoxContainer.new()
	footer.name = "Footer"
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	footer.add_theme_constant_override("separation", 14)
	root.add_child(footer)

	_prev_button = _make_button("<", Vector2(74, 64))
	_prev_button.name = "PrevButton"
	_prev_button.pressed.connect(_cycle_track.bind(-1))
	footer.add_child(_prev_button)

	var info_panel := PanelContainer.new()
	info_panel.name = "InfoPanel"
	info_panel.custom_minimum_size = Vector2(420, 104)
	info_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.04, 0.05, 0.075, 0.82), Color(0.92, 0.74, 0.22, 0.62), 2, 16))
	footer.add_child(info_panel)

	var info_margin := MarginContainer.new()
	info_margin.add_theme_constant_override("margin_left", 18)
	info_margin.add_theme_constant_override("margin_top", 12)
	info_margin.add_theme_constant_override("margin_right", 18)
	info_margin.add_theme_constant_override("margin_bottom", 12)
	info_panel.add_child(info_margin)

	var info_box := VBoxContainer.new()
	info_box.add_theme_constant_override("separation", 6)
	info_margin.add_child(info_box)

	_track_name_label = Label.new()
	_track_name_label.name = "TrackName"
	_track_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_track_name_label.add_theme_font_size_override("font_size", 28)
	_track_name_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.78, 1.0))
	info_box.add_child(_track_name_label)

	_select_button = _make_button("Race This Track", Vector2(0, 54))
	_select_button.name = "SelectButton"
	_select_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_select_button.pressed.connect(_start_selected_track)
	info_box.add_child(_select_button)

	_next_button = _make_button(">", Vector2(74, 64))
	_next_button.name = "NextButton"
	_next_button.pressed.connect(_cycle_track.bind(1))
	footer.add_child(_next_button)

func _build_racer_preview_layer() -> void:
	var preview_container := SubViewportContainer.new()
	preview_container.name = "RacerPreview"
	preview_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	preview_container.stretch = true
	preview_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(preview_container)

	var viewport := SubViewport.new()
	viewport.name = "RacerViewport"
	viewport.size = Vector2i(1280, 720)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.transparent_bg = true
	viewport.own_world_3d = true
	preview_container.add_child(viewport)

	var root := Node3D.new()
	root.name = "RacerPreviewRoot"
	viewport.add_child(root)

	_racer_preview_anchor = Node3D.new()
	_racer_preview_anchor.name = "RacerPreviewAnchor"
	root.add_child(_racer_preview_anchor)

	var camera := Camera3D.new()
	camera.name = "RacerPreviewCamera"
	camera.current = true
	camera.fov = 34.0
	camera.position = Vector3(0.0, 1.45, 7.1)
	root.add_child(camera)
	camera.look_at(Vector3(0.0, 0.8, 0.0), Vector3.UP)

	var key_light := DirectionalLight3D.new()
	key_light.name = "RacerKeyLight"
	key_light.light_energy = 2.2
	key_light.rotation_degrees = Vector3(-42, -28, 0)
	root.add_child(key_light)

	var fill_light := OmniLight3D.new()
	fill_light.name = "RacerFillLight"
	fill_light.light_energy = 0.9
	fill_light.omni_range = 7.0
	fill_light.position = Vector3(2.6, 2.2, 3.8)
	root.add_child(fill_light)

func _cycle_track(step: int) -> void:
	if _tracks.is_empty():
		return
	_track_index = posmod(_track_index + step, _tracks.size())
	_show_selected_track(true)

func _cycle_racer(step: int) -> void:
	if _racer_ids.is_empty():
		return
	_racer_index = posmod(_racer_index + step, _racer_ids.size())
	_show_selected_racer(true)

func _show_selected_track(animated: bool) -> void:
	if _tracks.is_empty():
		_track_name_label.text = "No tracks available"
		_select_button.disabled = true
		return
	var selected := _tracks[_track_index]
	var track_id := str(selected.get("id", ""))
	_track_name_label.text = str(selected.get("display_name", selected.get("id", "Track")))
	_meta_label.text = "Track %d/%d  /  %s" % [_track_index + 1, _tracks.size(), str(selected.get("version", "prototype"))]
	_prev_button.disabled = _tracks.size() <= 1
	_next_button.disabled = _tracks.size() <= 1
	_select_button.disabled = false
	_rebuild_preview(track_id)
	_request_scene_preload(track_id)
	_request_neighbor_scene_preloads()
	if animated:
		_track_name_label.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_property(_track_name_label, "modulate:a", 1.0, 0.18)

func _show_selected_racer(animated: bool) -> void:
	if _racer_ids.is_empty():
		_selected_racer_id = RacerRoster.DEFAULT_RACER_ID
	else:
		_selected_racer_id = RacerRoster.normalize_id(_racer_ids[_racer_index])
	NakamaService.set_meta_value("selected_racer_id", _selected_racer_id)

	var profile := RacerRoster.get_profile(_selected_racer_id)
	if _racer_name_label != null:
		_racer_name_label.text = _selected_racer_id
	if _racer_meta_label != null:
		_racer_meta_label.text = "%s  /  %s" % [str(profile.get("class", "Racer")), str(profile.get("home_course", "Home Course"))]
	if _racer_prev_button != null:
		_racer_prev_button.disabled = _racer_ids.size() <= 1
	if _racer_next_button != null:
		_racer_next_button.disabled = _racer_ids.size() <= 1
	_load_racer_preview_model(_selected_racer_id)
	if animated and _racer_name_label != null:
		_racer_name_label.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_property(_racer_name_label, "modulate:a", 1.0, 0.16)

func _load_racer_preview_model(racer_id: String) -> void:
	if _racer_preview_anchor == null:
		return
	_dispose_racer_preview_model()

	var model_path := RacerRoster.get_racer_in_kart_model_path(racer_id)
	if model_path.is_empty() or not ResourceLoader.exists(model_path):
		return
	var scene := load(model_path) as PackedScene
	if scene == null:
		return
	var model := scene.instantiate() as Node3D
	if model == null:
		return
	model.name = "SelectedRacerPreviewModel"
	model.rotation_degrees.y = RacerRoster.get_racer_in_kart_yaw_degrees(racer_id)
	_racer_preview_anchor.add_child(model)
	_fit_racer_preview_model(model)
	_racer_preview_model = model

func _dispose_racer_preview_model() -> void:
	if _racer_preview_model == null or not is_instance_valid(_racer_preview_model):
		_racer_preview_model = null
		return
	if _racer_preview_model.get_parent() != null:
		_racer_preview_model.get_parent().remove_child(_racer_preview_model)
	_racer_preview_model.free()
	_racer_preview_model = null

func _fit_racer_preview_model(model: Node3D) -> void:
	var bounds := _combined_mesh_bounds(model)
	if bounds.size == Vector3.ZERO:
		model.position = Vector3(0.0, -0.55, 0.0)
		model.scale = Vector3.ONE
		return
	var max_dimension: float = maxf(bounds.size.x, maxf(bounds.size.y, bounds.size.z))
	var scale_factor := RACER_PREVIEW_TARGET_SIZE / maxf(max_dimension, 0.001)
	var center := bounds.get_center()
	model.scale = Vector3.ONE * scale_factor
	model.position = Vector3(-center.x * scale_factor, -center.y * scale_factor + 0.2, -center.z * scale_factor)

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

func _rebuild_preview(track_id: String) -> void:
	_detach_preview_children()
	_route_points.clear()
	if _preview_cache.has(track_id):
		_attach_preview_build(track_id, _preview_cache[track_id] as Dictionary)
		return
	var definition = TrackCatalog.get_definition(track_id)
	if definition == null:
		return
	var built := _build_lightweight_preview(definition)
	_preview_cache[track_id] = built
	_attach_preview_build(track_id, built)

func _attach_preview_build(track_id: String, built: Dictionary) -> void:
	var node := built.get("node", null) as Node
	if node != null:
		if node.get_parent() != null:
			node.get_parent().remove_child(node)
		_preview_root.add_child(node)
		_hide_preview_road_edges(node)
	for point in built.get("waypoints", []):
		if point is Vector3:
			_route_points.append(point)
	_preview_time = 0.0
	_update_preview_camera(true)

func _build_lightweight_preview(definition) -> Dictionary:
	var preview_definition = definition.duplicate(true)
	preview_definition.id = "%s_preview" % definition.id
	preview_definition.dressing_scene_path = str(definition.dressing_scene_path)
	var empty_stage_props: Array[Dictionary] = []
	preview_definition.stage_props = empty_stage_props
	return TrackRuntimeBuilder.build(preview_definition)

func _detach_preview_children() -> void:
	for child in _preview_root.get_children():
		_preview_root.remove_child(child)

func _update_preview_camera(snap: bool = false) -> void:
	if _camera == null:
		return
	var count := _route_points.size()
	if count < 2:
		_camera.global_transform.origin = Vector3(0, 48, -72)
		_camera.look_at(Vector3.ZERO, Vector3.UP)
		return
	var segment_count := count
	var travel: float = fposmod(_preview_time * PREVIEW_CAMERA_ROUTE_SPEED, 1.0) * float(segment_count)
	var index := int(floor(travel)) % count
	var next_index := (index + 1) % count
	var ratio: float = travel - floor(travel)
	var point: Vector3 = _route_points[index].lerp(_route_points[next_index], ratio)
	var next_point := _route_points[next_index]
	var forward: Vector3 = next_point - point
	forward.y = 0.0
	if forward.length_squared() <= 0.001:
		forward = Vector3.FORWARD
	forward = forward.normalized()
	var side := forward.cross(Vector3.UP).normalized()
	var desired: Vector3 = point - forward * 18.0 + side * 9.0 + Vector3.UP * 13.0
	if snap:
		_camera.global_transform.origin = desired
	else:
		_camera.global_transform.origin = _camera.global_transform.origin.lerp(desired, PREVIEW_CAMERA_BLEND)
	_camera.look_at(point + Vector3.UP * 2.0, Vector3.UP)

func _hide_preview_road_edges(node: Node) -> void:
	if _is_preview_road_edge_node(node) and node is Node3D:
		(node as Node3D).visible = false
	for child in node.get_children():
		_hide_preview_road_edges(child)

func _has_visible_preview_road_edges(node: Node) -> bool:
	if node == null:
		return false
	if _is_preview_road_edge_node(node) and node is Node3D and (node as Node3D).visible:
		return true
	for child in node.get_children():
		if _has_visible_preview_road_edges(child):
			return true
	return false

func _is_preview_road_edge_node(node: Node) -> bool:
	var node_name := str(node.name).to_lower()
	return (
		node_name == "trackbody"
		or node_name.ends_with("trackbody")
		or node_name == "road"
	)

func _has_visible_named_node(node: Node, target_name: String) -> bool:
	if node == null:
		return false
	if str(node.name) == target_name and node is Node3D and (node as Node3D).visible:
		return true
	for child in node.get_children():
		if _has_visible_named_node(child, target_name):
			return true
	return false

func _start_selected_track() -> void:
	_apply_selected_track_metadata()
	get_tree().change_scene_to_file("res://scenes/Race.tscn")

func _apply_selected_track_metadata() -> void:
	var track_id := get_selected_track_id()
	if track_id.is_empty():
		return
	NakamaService.set_meta_value("selected_racer_id", _selected_racer_id)
	NakamaService.set_meta_value("track_id", track_id)
	NakamaService.set_meta_value("track_recipe", {"track_id": track_id, "id": track_id})
	NakamaService.set_meta_value("prepared_track_package", {})
	_request_scene_preload(track_id)
	NakamaService.set_meta_value("race_match_id", "local-single-race")
	NakamaService.set_meta_value("race_mode", "local_single")

func _request_neighbor_scene_preloads() -> void:
	if _tracks.size() <= 1:
		return
	for offset in [-1, 1]:
		var index := posmod(_track_index + offset, _tracks.size())
		_request_scene_preload(str((_tracks[index] as Dictionary).get("id", "")))

func _request_all_scene_preloads() -> void:
	for track in _tracks:
		if track is Dictionary:
			_request_scene_preload(str((track as Dictionary).get("id", "")))

func _request_scene_preload(track_id: String) -> void:
	if track_id.is_empty() or _threaded_scene_requests.has(track_id):
		return
	var scene_path := TrackCatalog.get_scene_path(track_id)
	if scene_path.is_empty():
		return
	var err := ResourceLoader.load_threaded_request(scene_path)
	if err == OK or err == ERR_BUSY:
		_threaded_scene_requests[track_id] = scene_path

func _go_back() -> void:
	if NavigationFlow.get_nav_flow_mode(NakamaService) == NavigationFlow.FLOW_SINGLE_RACE:
		NavigationFlow.set_nav_flow_mode(NakamaService, NavigationFlow.FLOW_SINGLE_RACE)
		get_tree().change_scene_to_file("res://scenes/CharacterSelect.tscn")
		return
	get_tree().change_scene_to_file("res://scenes/CharacterSelect.tscn")

func _make_button(text: String, min_size: Vector2) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = min_size
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", Color(0.05, 0.05, 0.07, 1.0))
	button.add_theme_stylebox_override("normal", _button_style(Color(0.96, 0.78, 0.24, 0.95), Color(1.0, 0.96, 0.75, 0.9)))
	button.add_theme_stylebox_override("hover", _button_style(Color(1.0, 0.86, 0.34, 1.0), Color(1.0, 1.0, 1.0, 1.0)))
	button.add_theme_stylebox_override("pressed", _button_style(Color(0.86, 0.62, 0.14, 1.0), Color(1.0, 0.9, 0.55, 1.0)))
	return button

func _button_style(bg: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(16)
	style.content_margin_left = 18
	style.content_margin_top = 10
	style.content_margin_right = 18
	style.content_margin_bottom = 10
	return style

func _panel_style(bg: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 16
	style.content_margin_top = 12
	style.content_margin_right = 16
	style.content_margin_bottom = 12
	style.shadow_color = Color(0, 0, 0, 0.32)
	style.shadow_size = 12
	return style
