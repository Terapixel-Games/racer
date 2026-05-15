extends Control

const NavigationFlow = preload("res://scripts/logic/NavigationFlow.gd")
const TrackCatalog = preload("res://scripts/track/TrackCatalog.gd")
const TrackRuntimeBuilder = preload("res://scripts/track/TrackRuntimeBuilder.gd")
const TrackRuntimeScene = preload("res://scripts/track/TrackRuntimeScene.gd")

const ARKIT_FACE_PREVIEW_SCENE := "res://scenes/dev/ARKitFacePreview.tscn"
const PREVIEW_CAMERA_ROUTE_SPEED := 0.03
const PREVIEW_CAMERA_BLEND := 0.05
const HOME_HUB_TRACK_ID := "kitchen"
const FRONT_DOOR_ENTRY_DURATION := 0.9

var _preview_root: Node3D
var _camera: Camera3D
var _route_points: Array[Vector3] = []
var _preview_time := 0.0
var _preview_track_id := ""
var _start_button: Button
var _ar_face_button: Button
var _quit_button: Button
var _entering_home := false

func _ready() -> void:
	_clear_scene_children()
	_build_screen()
	_rebuild_preview(HOME_HUB_TRACK_ID)
	if _quit_button != null:
		_quit_button.visible = false

func _process(delta: float) -> void:
	_preview_time += delta
	_update_preview_camera()

func get_preview_track_id_for_test() -> String:
	return HOME_HUB_TRACK_ID if _preview_track_id.is_empty() else _preview_track_id

func has_root_buttons_for_test() -> bool:
	return _start_button != null and _start_button.visible

func get_ar_face_preview_scene_for_test() -> String:
	return ARKIT_FACE_PREVIEW_SCENE

func get_title_text_for_test() -> String:
	var title := find_child("Title", true, false) as Label
	return title.text if title != null else ""

func start_game_for_test() -> void:
	_prepare_home_selection()

func start_single_race_for_test() -> void:
	NavigationFlow.set_nav_flow_mode(NakamaService, NavigationFlow.FLOW_SINGLE_RACE)

func start_tournament_for_test() -> void:
	NavigationFlow.set_nav_flow_mode(NakamaService, NavigationFlow.FLOW_TOURNAMENT)

func _clear_scene_children() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()

func _build_screen() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	anchor_right = 1.0
	anchor_bottom = 1.0

	var preview_container := SubViewportContainer.new()
	preview_container.name = "RaceVignette"
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
	_camera.fov = 58.0
	viewport.add_child(_camera)

	var light := DirectionalLight3D.new()
	light.name = "PreviewKeyLight"
	light.light_energy = 1.25
	light.rotation_degrees = Vector3(-52, 34, 0)
	viewport.add_child(light)

	var scrim := ColorRect.new()
	scrim.name = "MenuScrim"
	scrim.color = Color(0.0, 0.0, 0.0, 0.42)
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(scrim)

	var margin := MarginContainer.new()
	margin.name = "Layout"
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 34)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_right", 34)
	margin.add_theme_constant_override("margin_bottom", 28)
	add_child(margin)

	var root := VBoxContainer.new()
	root.name = "Root"
	root.add_theme_constant_override("separation", 18)
	margin.add_child(root)

	var header := VBoxContainer.new()
	header.name = "Header"
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(header)

	var kicker := Label.new()
	kicker.name = "Kicker"
	kicker.text = "TERAPIXEL"
	kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kicker.add_theme_font_size_override("font_size", 18)
	kicker.add_theme_color_override("font_color", Color(0.68, 0.94, 1.0, 0.92))
	header.add_child(kicker)

	var title := Label.new()
	title.name = "Title"
	title.text = "Toy Dominion"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 58)
	title.add_theme_color_override("font_color", Color(1.0, 0.96, 0.78, 1.0))
	header.add_child(title)

	var subtitle := Label.new()
	subtitle.name = "Subtitle"
	subtitle.text = "Tiny racers. One giant home."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 19)
	subtitle.add_theme_color_override("font_color", Color(0.82, 0.9, 1.0, 0.92))
	header.add_child(subtitle)

	var spacer := Control.new()
	spacer.name = "Spacer"
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(spacer)

	var panel := PanelContainer.new()
	panel.name = "ModePanel"
	panel.custom_minimum_size = Vector2(430, 0)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	panel.add_theme_stylebox_override("panel", _panel_style())
	root.add_child(panel)

	var box := VBoxContainer.new()
	box.name = "ModeButtons"
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)

	_start_button = _make_button("Start", Vector2(380, 68))
	_start_button.name = "StartButton"
	_start_button.pressed.connect(_on_start_pressed)
	box.add_child(_start_button)

	_ar_face_button = _make_button("AR Face Test", Vector2(380, 58), false)
	_ar_face_button.name = "ARFaceTestButton"
	_ar_face_button.pressed.connect(_on_ar_face_test_pressed)
	_ar_face_button.visible = false
	box.add_child(_ar_face_button)

	_quit_button = _make_button("Quit", Vector2(380, 58), false)
	_quit_button.name = "QuitButton"
	_quit_button.pressed.connect(func(): get_tree().quit())
	box.add_child(_quit_button)

func _on_start_pressed() -> void:
	if _entering_home:
		return
	_entering_home = true
	if _start_button != null:
		_start_button.disabled = true
	_play_front_door_entry()

func _on_ar_face_test_pressed() -> void:
	NakamaService.set_meta_value("selected_racer_id", "Rexx")
	get_tree().change_scene_to_file(ARKIT_FACE_PREVIEW_SCENE)

func _prepare_home_selection() -> void:
	NavigationFlow.set_nav_flow_mode(NakamaService, NavigationFlow.FLOW_SINGLE_RACE)

func _play_front_door_entry() -> void:
	_prepare_home_selection()
	if _camera == null:
		get_tree().change_scene_to_file("res://scenes/LevelSelect.tscn")
		return
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(_set_menu_camera_entry_pose, 0.0, 1.0, FRONT_DOOR_ENTRY_DURATION)
	tween.finished.connect(func(): get_tree().change_scene_to_file("res://scenes/LevelSelect.tscn"))

func _set_menu_camera_entry_pose(ratio: float) -> void:
	var start := _camera.global_transform.origin
	var end := Vector3(-50.0, 10.0, 176.0).lerp(Vector3(-50.0, 4.5, 130.0), ratio)
	_camera.global_transform.origin = start.lerp(end, clampf(ratio, 0.0, 1.0))
	_camera.look_at(Vector3(-50.0, 5.0, 118.0), Vector3.UP)

func _rebuild_preview(track_id: String) -> void:
	_preview_track_id = track_id
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
		_hide_preview_road_edges(node)
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
	if _entering_home:
		return
	var count := _route_points.size()
	if count < 2:
		_camera.global_transform.origin = Vector3(-88, 92, 282)
		_camera.look_at(Vector3(-35, 24, 45), Vector3.UP)
		return
	var bounds := AABB(_route_points[0], Vector3.ZERO)
	for route_point in _route_points:
		bounds = bounds.expand(route_point)
	var center := bounds.get_center()
	var orbit_angle := _preview_time * 0.12 + 0.4
	var desired := center + Vector3(cos(orbit_angle) * 185.0, 96.0, sin(orbit_angle) * 185.0 + 72.0)
	if snap:
		_camera.global_transform.origin = desired
	else:
		_camera.global_transform.origin = _camera.global_transform.origin.lerp(desired, PREVIEW_CAMERA_BLEND)
	_camera.look_at(center + Vector3.UP * 18.0, Vector3.UP)

func _hide_preview_road_edges(node: Node) -> void:
	if _is_preview_road_edge_node(node) and node is Node3D:
		(node as Node3D).visible = false
	for child in node.get_children():
		_hide_preview_road_edges(child)

func _is_preview_road_edge_node(node: Node) -> bool:
	var node_name := str(node.name).to_lower()
	return (
		node_name == "trackbody"
		or node_name.ends_with("trackbody")
		or node_name == "road"
	)

func _make_button(text: String, min_size: Vector2, primary: bool = true) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = min_size
	button.add_theme_font_size_override("font_size", 24 if primary else 18)
	button.add_theme_color_override("font_color", Color(0.05, 0.05, 0.07, 1.0) if primary else Color(0.9, 0.95, 1.0, 1.0))
	var bg := Color(0.96, 0.78, 0.24, 0.96) if primary else Color(0.12, 0.14, 0.2, 0.92)
	var border := Color(1.0, 0.96, 0.75, 0.88) if primary else Color(0.68, 0.78, 0.96, 0.56)
	button.add_theme_stylebox_override("normal", _button_style(bg, border))
	button.add_theme_stylebox_override("hover", _button_style(bg.lightened(0.1), border.lightened(0.1)))
	button.add_theme_stylebox_override("pressed", _button_style(bg.darkened(0.12), border))
	return button

func _button_style(bg: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 18
	style.content_margin_top = 12
	style.content_margin_right = 18
	style.content_margin_bottom = 12
	return style

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.04, 0.06, 0.86)
	style.border_color = Color(0.75, 0.86, 1.0, 0.36)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 18
	style.content_margin_top = 18
	style.content_margin_right = 18
	style.content_margin_bottom = 18
	style.shadow_color = Color(0, 0, 0, 0.45)
	style.shadow_size = 14
	return style
