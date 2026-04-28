extends Control

const RacerRoster = preload("res://scripts/logic/RacerRoster.gd")

var selected_racer_id := RacerRoster.DEFAULT_RACER_ID
var card_buttons: Dictionary = {}
var stat_bars: Dictionary = {}

var _body: BoxContainer
var _grid: GridContainer
var _preview_panel: PanelContainer
var _preview_texture: TextureRect
var _title_label: Label
var _subtitle_label: Label
var _name_label: Label
var _class_label: Label
var _motive_label: Label
var _continue_button: Button

func _ready() -> void:
	_build_screen()
	var stored_id := str(_get_meta_value("selected_racer_id", RacerRoster.DEFAULT_RACER_ID))
	if not RacerRoster.has(stored_id):
		stored_id = RacerRoster.DEFAULT_RACER_ID
	_select_racer(stored_id)
	_refresh_layout()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and _grid != null:
		_refresh_layout()

func get_selected_racer_id() -> String:
	return selected_racer_id

func get_card_count() -> int:
	return card_buttons.size()

func has_portrait_for(racer_id: String) -> bool:
	var profile := RacerRoster.get_profile(racer_id)
	var path := str(profile.get("portrait", ""))
	return not path.is_empty() and ResourceLoader.exists(path)

func _build_screen() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	anchor_right = 1.0
	anchor_bottom = 1.0

	var background := ColorRect.new()
	background.name = "Background"
	background.color = Color(0.045, 0.05, 0.075, 1.0)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var glow := ColorRect.new()
	glow.name = "ToyBoxWash"
	glow.color = Color(0.16, 0.19, 0.28, 0.48)
	glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(glow)

	var margin := MarginContainer.new()
	margin.name = "Layout"
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 24)
	add_child(margin)

	var main := VBoxContainer.new()
	main.name = "Main"
	main.add_theme_constant_override("separation", 18)
	margin.add_child(main)

	var header := HBoxContainer.new()
	header.name = "Header"
	header.alignment = BoxContainer.ALIGNMENT_BEGIN
	main.add_child(header)

	var header_text := VBoxContainer.new()
	header_text.name = "HeaderText"
	header_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(header_text)

	_title_label = Label.new()
	_title_label.name = "Title"
	_title_label.text = "Choose Racer"
	_title_label.add_theme_color_override("font_color", Color(0.98, 0.97, 0.92, 1.0))
	_title_label.add_theme_font_size_override("font_size", 54)
	header_text.add_child(_title_label)

	_subtitle_label = Label.new()
	_subtitle_label.name = "Subtitle"
	_subtitle_label.text = "Lock a toy rival before the Kitchen shakedown."
	_subtitle_label.add_theme_color_override("font_color", Color(0.76, 0.81, 0.9, 0.92))
	_subtitle_label.add_theme_font_size_override("font_size", 20)
	header_text.add_child(_subtitle_label)

	var back_button := Button.new()
	back_button.name = "BackButton"
	back_button.text = "Back"
	back_button.custom_minimum_size = Vector2(116, 52)
	back_button.add_theme_font_size_override("font_size", 18)
	back_button.add_theme_stylebox_override("normal", _button_style(Color(0.12, 0.14, 0.2, 0.95), Color(0.55, 0.62, 0.75, 0.58)))
	back_button.add_theme_stylebox_override("hover", _button_style(Color(0.16, 0.18, 0.26, 0.98), Color(0.8, 0.86, 1.0, 0.72)))
	back_button.pressed.connect(_go_back)
	header.add_child(back_button)

	_body = HBoxContainer.new()
	_body.name = "Body"
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", 18)
	main.add_child(_body)

	_preview_panel = PanelContainer.new()
	_preview_panel.name = "PreviewPanel"
	_preview_panel.custom_minimum_size = Vector2(360, 0)
	_preview_panel.size_flags_horizontal = Control.SIZE_FILL
	_preview_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.add_child(_preview_panel)

	var preview_scroll := ScrollContainer.new()
	preview_scroll.name = "PreviewScroll"
	preview_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	preview_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_preview_panel.add_child(preview_scroll)

	var preview_box := VBoxContainer.new()
	preview_box.name = "Preview"
	preview_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_box.add_theme_constant_override("separation", 14)
	preview_scroll.add_child(preview_box)

	_preview_texture = TextureRect.new()
	_preview_texture.name = "SelectedPortrait"
	_preview_texture.custom_minimum_size = Vector2(300, 300)
	_preview_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_preview_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	preview_box.add_child(_preview_texture)

	_name_label = Label.new()
	_name_label.name = "RacerName"
	_name_label.add_theme_color_override("font_color", Color(1.0, 0.96, 0.86, 1.0))
	_name_label.add_theme_font_size_override("font_size", 38)
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_box.add_child(_name_label)

	_class_label = Label.new()
	_class_label.name = "ClassLine"
	_class_label.add_theme_color_override("font_color", Color(0.82, 0.9, 1.0, 0.96))
	_class_label.add_theme_font_size_override("font_size", 20)
	_class_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_box.add_child(_class_label)

	_motive_label = Label.new()
	_motive_label.name = "Motive"
	_motive_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_motive_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_motive_label.add_theme_color_override("font_color", Color(0.88, 0.88, 0.92, 0.9))
	_motive_label.add_theme_font_size_override("font_size", 18)
	preview_box.add_child(_motive_label)

	var stat_box := VBoxContainer.new()
	stat_box.name = "Stats"
	stat_box.add_theme_constant_override("separation", 8)
	preview_box.add_child(stat_box)
	for stat_name in ["speed", "accel", "handling", "weight", "traction", "boost"]:
		var row := HBoxContainer.new()
		row.name = stat_name.capitalize()
		row.add_theme_constant_override("separation", 10)
		stat_box.add_child(row)

		var label := Label.new()
		label.custom_minimum_size = Vector2(92, 0)
		label.text = stat_name.capitalize()
		label.add_theme_color_override("font_color", Color(0.78, 0.82, 0.9, 0.92))
		label.add_theme_font_size_override("font_size", 16)
		row.add_child(label)

		var bar := ProgressBar.new()
		bar.name = "Bar"
		bar.min_value = 0
		bar.max_value = 10
		bar.step = 1
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(0, 16)
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(bar)
		stat_bars[stat_name] = bar

	_continue_button = Button.new()
	_continue_button.name = "ContinueButton"
	_continue_button.text = "Lock In"
	_continue_button.custom_minimum_size = Vector2(0, 68)
	_continue_button.add_theme_font_size_override("font_size", 28)
	_continue_button.add_theme_color_override("font_color", Color(0.06, 0.05, 0.08, 1.0))
	_continue_button.pressed.connect(_continue_to_lobby)
	preview_box.add_child(_continue_button)

	var grid_panel := PanelContainer.new()
	grid_panel.name = "GridPanel"
	grid_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.09, 0.1, 0.145, 0.9), Color(0.45, 0.54, 0.68, 0.35), 2, 18))
	_body.add_child(grid_panel)

	var scroll := ScrollContainer.new()
	scroll.name = "Scroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid_panel.add_child(scroll)

	_grid = GridContainer.new()
	_grid.name = "RacerGrid"
	_grid.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_grid.add_theme_constant_override("h_separation", 12)
	_grid.add_theme_constant_override("v_separation", 12)
	scroll.add_child(_grid)

	for racer_id in RacerRoster.select_order():
		_grid.add_child(_make_card(racer_id))

func _make_card(racer_id: String) -> Button:
	var profile := RacerRoster.get_profile(racer_id)
	var accent: Color = profile.get("accent", Color(0.8, 0.8, 0.8, 1.0))

	var card := Button.new()
	card.name = racer_id.replace(" ", "") + "Card"
	card.toggle_mode = true
	card.focus_mode = Control.FOCUS_ALL
	card.custom_minimum_size = Vector2(172, 230)
	card.size_flags_horizontal = Control.SIZE_FILL
	card.add_theme_stylebox_override("normal", _card_style(Color(0.135, 0.145, 0.19, 0.96), accent.darkened(0.45), 1))
	card.add_theme_stylebox_override("hover", _card_style(Color(0.16, 0.17, 0.23, 0.98), accent, 2))
	card.add_theme_stylebox_override("pressed", _card_style(Color(0.18, 0.18, 0.24, 1.0), accent, 3))
	card.add_theme_stylebox_override("focus", _card_style(Color(0.18, 0.18, 0.24, 0.9), Color(1.0, 0.96, 0.75, 0.95), 3))
	card.set_meta("racer_id", racer_id)
	card.pressed.connect(_on_card_pressed.bind(card))

	var content := VBoxContainer.new()
	content.name = "Content"
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 10
	content.offset_top = 10
	content.offset_right = -10
	content.offset_bottom = -10
	content.add_theme_constant_override("separation", 8)
	card.add_child(content)

	var portrait := TextureRect.new()
	portrait.name = "Portrait"
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.custom_minimum_size = Vector2(0, 138)
	portrait.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var portrait_path := str(profile.get("portrait", ""))
	if ResourceLoader.exists(portrait_path):
		var texture := load(portrait_path)
		if texture is Texture2D:
			portrait.texture = texture
	content.add_child(portrait)

	var name := Label.new()
	name.name = "Name"
	name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name.text = racer_id
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name.add_theme_color_override("font_color", Color(0.98, 0.96, 0.9, 1.0))
	name.add_theme_font_size_override("font_size", 20)
	content.add_child(name)

	var class_label := Label.new()
	class_label.name = "Class"
	class_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	class_label.text = str(profile.get("class", ""))
	class_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	class_label.add_theme_color_override("font_color", accent.lightened(0.35))
	class_label.add_theme_font_size_override("font_size", 15)
	content.add_child(class_label)

	card_buttons[racer_id] = card
	return card

func _on_card_pressed(card: Button) -> void:
	_select_racer(str(card.get_meta("racer_id", RacerRoster.DEFAULT_RACER_ID)))

func _select_racer(racer_id: String) -> void:
	if not RacerRoster.has(racer_id):
		return
	selected_racer_id = racer_id
	_set_meta_value("selected_racer_id", racer_id)
	var profile := RacerRoster.get_profile(racer_id)
	var accent: Color = profile.get("accent", Color(0.8, 0.8, 0.8, 1.0))
	_preview_panel.add_theme_stylebox_override("panel", _panel_style(accent.darkened(0.72), accent, 3, 22))
	_continue_button.add_theme_stylebox_override("normal", _button_style(accent.lightened(0.15), Color(1.0, 0.96, 0.8, 0.95)))
	_continue_button.add_theme_stylebox_override("hover", _button_style(accent.lightened(0.25), Color(1.0, 1.0, 1.0, 1.0)))
	_continue_button.text = "Lock In: %s" % racer_id

	for id in card_buttons.keys():
		var card := card_buttons[id] as Button
		card.button_pressed = id == racer_id

	var portrait_path := str(profile.get("portrait", ""))
	_preview_texture.texture = load(portrait_path) if ResourceLoader.exists(portrait_path) else null
	_name_label.text = racer_id
	_class_label.text = "%s  /  Home: %s" % [profile.get("class", ""), profile.get("home_course", "")]
	_motive_label.text = str(profile.get("motive", ""))
	var stats: Dictionary = profile.get("stats", {})
	for stat_name in stat_bars.keys():
		var bar := stat_bars[stat_name] as ProgressBar
		bar.value = int(stats.get(stat_name, 0))

func _refresh_layout() -> void:
	var width := get_viewport_rect().size.x
	var height := get_viewport_rect().size.y
	if width >= 1500:
		_grid.columns = 4
	elif width >= 1050:
		_grid.columns = 3
	elif width >= 900:
		_grid.columns = 2
	else:
		_grid.columns = 1

	var compact_width := width < 900
	var compact_height := height < 850
	_preview_panel.custom_minimum_size = Vector2(290 if compact_width else 360, 0)
	_preview_texture.custom_minimum_size = Vector2(190, 190) if compact_height else (Vector2(220, 220) if compact_width else Vector2(300, 300))
	_title_label.add_theme_font_size_override("font_size", 42 if compact_width else 54)
	_subtitle_label.add_theme_font_size_override("font_size", 16 if compact_width else 20)
	_name_label.add_theme_font_size_override("font_size", 30 if compact_height else 38)
	_class_label.add_theme_font_size_override("font_size", 17 if compact_height else 20)
	_motive_label.add_theme_font_size_override("font_size", 16 if compact_height else 18)
	_continue_button.custom_minimum_size = Vector2(0, 58 if compact_height else 68)
	for card in card_buttons.values():
		(card as Button).custom_minimum_size = Vector2(154, 218) if compact_width else Vector2(172, 230)

func _continue_to_lobby() -> void:
	_set_meta_value("selected_racer_id", selected_racer_id)
	get_tree().change_scene_to_file("res://scenes/Lobby.tscn")

func _go_back() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _get_meta_value(key: String, default_value: Variant) -> Variant:
	if not Engine.has_singleton("NakamaService"):
		return default_value
	var service := Engine.get_singleton("NakamaService")
	if service != null and service.has_method("get_meta_value"):
		return service.call("get_meta_value", key, default_value)
	return default_value

func _set_meta_value(key: String, value: Variant) -> void:
	if not Engine.has_singleton("NakamaService"):
		return
	var service := Engine.get_singleton("NakamaService")
	if service != null and service.has_method("set_meta_value"):
		service.call("set_meta_value", key, value)

func _panel_style(bg: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 20
	style.content_margin_top = 20
	style.content_margin_right = 20
	style.content_margin_bottom = 20
	style.shadow_color = Color(0, 0, 0, 0.28)
	style.shadow_size = 14
	return style

func _card_style(bg: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var style := _panel_style(bg, border, border_width, 16)
	style.content_margin_left = 8
	style.content_margin_top = 8
	style.content_margin_right = 8
	style.content_margin_bottom = 8
	style.shadow_size = 8
	return style

func _button_style(bg: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(18)
	style.content_margin_left = 18
	style.content_margin_top = 12
	style.content_margin_right = 18
	style.content_margin_bottom = 12
	return style
