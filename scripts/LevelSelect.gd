extends Control

const TrackCatalog = preload("res://scripts/track/TrackCatalog.gd")
const TrackRuntimeBuilder = preload("res://scripts/track/TrackRuntimeBuilder.gd")
const TrackRuntimeScene = preload("res://scripts/track/TrackRuntimeScene.gd")

var _tracks: Array[Dictionary] = []
var _track_index := 0
var _preview_root: Node3D
var _camera: Camera3D
var _route_points: Array[Vector3] = []
var _preview_time := 0.0

var _title_label: Label
var _track_name_label: Label
var _meta_label: Label
var _select_button: Button
var _prev_button: Button
var _next_button: Button

func _ready() -> void:
	_tracks = TrackCatalog.list_tracks()
	_build_screen()
	_show_selected_track(false)

func _process(delta: float) -> void:
	_preview_time += delta
	_update_preview_camera()

func get_track_count() -> int:
	return _tracks.size()

func get_selected_track_id() -> String:
	if _tracks.is_empty():
		return ""
	return str(_tracks[_track_index].get("id", ""))

func apply_selected_track_for_test() -> void:
	_apply_selected_track_metadata()

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

func _cycle_track(step: int) -> void:
	if _tracks.is_empty():
		return
	_track_index = posmod(_track_index + step, _tracks.size())
	_show_selected_track(true)

func _show_selected_track(animated: bool) -> void:
	if _tracks.is_empty():
		_track_name_label.text = "No tracks available"
		_select_button.disabled = true
		return
	var selected := _tracks[_track_index]
	_track_name_label.text = str(selected.get("display_name", selected.get("id", "Track")))
	_meta_label.text = "Track %d/%d  /  %s" % [_track_index + 1, _tracks.size(), str(selected.get("version", "prototype"))]
	_prev_button.disabled = _tracks.size() <= 1
	_next_button.disabled = _tracks.size() <= 1
	_select_button.disabled = false
	_rebuild_preview(str(selected.get("id", "")))
	if animated:
		_track_name_label.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_property(_track_name_label, "modulate:a", 1.0, 0.18)

func _rebuild_preview(track_id: String) -> void:
	for child in _preview_root.get_children():
		child.queue_free()
	_route_points.clear()
	var definition = TrackCatalog.get_definition(track_id)
	if definition == null:
		return
	var built := _instantiate_track_package(track_id, definition)
	var node := built.get("node", null) as Node
	if node != null:
		_preview_root.add_child(node)
	for point in built.get("waypoints", definition.route_points):
		if point is Vector3:
			_route_points.append(point)
	_preview_time = 0.0
	_update_preview_camera(true)

func _instantiate_track_package(track_id: String, definition) -> Dictionary:
	var scene_path := TrackCatalog.get_scene_path(track_id)
	if not scene_path.is_empty():
		var packed := load(scene_path)
		if packed is PackedScene:
			var scene_root: Node = (packed as PackedScene).instantiate()
			if scene_root is TrackRuntimeScene:
				(scene_root as TrackRuntimeScene).definition = definition
				(scene_root as TrackRuntimeScene).rebuild_on_ready = false
				var package_build = (scene_root as TrackRuntimeScene).rebuild()
				if package_build is Dictionary:
					package_build["node"] = scene_root
					return package_build
			elif scene_root != null:
				return {"node": scene_root, "waypoints": definition.route_points}
	return TrackRuntimeBuilder.build(definition)

func _update_preview_camera(snap: bool = false) -> void:
	if _camera == null:
		return
	var count := _route_points.size()
	if count < 2:
		_camera.global_transform.origin = Vector3(0, 48, -72)
		_camera.look_at(Vector3.ZERO, Vector3.UP)
		return
	var segment_count := count
	var travel: float = fposmod(_preview_time * 0.18, 1.0) * float(segment_count)
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
		_camera.global_transform.origin = _camera.global_transform.origin.lerp(desired, 0.08)
	_camera.look_at(point + Vector3.UP * 2.0, Vector3.UP)

func _start_selected_track() -> void:
	_apply_selected_track_metadata()
	get_tree().change_scene_to_file("res://scenes/Race.tscn")

func _apply_selected_track_metadata() -> void:
	var track_id := get_selected_track_id()
	if track_id.is_empty():
		return
	NakamaService.set_meta_value("track_id", track_id)
	NakamaService.set_meta_value("track_recipe", TrackCatalog.get_metadata(track_id))
	NakamaService.set_meta_value("race_match_id", "local-single-race")
	NakamaService.set_meta_value("race_mode", "local_single")

func _go_back() -> void:
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
