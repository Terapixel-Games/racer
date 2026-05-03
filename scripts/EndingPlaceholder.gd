extends Control

@export_enum("win", "loss") var ending_type := "win"

const NavigationFlow = preload("res://scripts/logic/NavigationFlow.gd")
const RacerRoster = preload("res://scripts/logic/RacerRoster.gd")

func _ready() -> void:
	_build_screen()

func _build_screen() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	anchor_right = 1.0
	anchor_bottom = 1.0

	var background := ColorRect.new()
	background.name = "Background"
	background.color = Color(0.035, 0.04, 0.06, 1.0)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var margin := MarginContainer.new()
	margin.name = "Layout"
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_top", 32)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_bottom", 32)
	add_child(margin)

	var center := CenterContainer.new()
	center.name = "Center"
	margin.add_child(center)

	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.custom_minimum_size = Vector2(720, 0)
	panel.add_theme_stylebox_override("panel", _panel_style())
	center.add_child(panel)

	var box := VBoxContainer.new()
	box.name = "Content"
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)

	var selected := RacerRoster.normalize_id(str(NakamaService.get_meta_value(NavigationFlow.KEY_SELECTED_RACER_ID, RacerRoster.DEFAULT_RACER_ID)))
	var rank := int(NakamaService.get_meta_value(NavigationFlow.KEY_PLAYER_TOURNAMENT_RANK, 0))
	var title := Label.new()
	title.name = "Title"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.42, 1.0))
	title.text = "%s Wins The Cup" % selected if ending_type == "win" else "Front Door Exit"
	box.add_child(title)

	var body := Label.new()
	body.name = "Body"
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 22)
	body.add_theme_color_override("font_color", Color(0.88, 0.93, 1.0, 0.94))
	if ending_type == "win":
		body.text = "Placeholder cinematic ending for %s. Tournament placement: %s." % [selected, str(rank if rank > 0 else 1)]
	else:
		body.text = "Placeholder shared loss vignette. The selected racer gets tossed out the front door, the door slams, and the final cinematic will replace this screen later."
	box.add_child(body)

	var ending_id := Label.new()
	ending_id.name = "EndingId"
	ending_id.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ending_id.add_theme_font_size_override("font_size", 15)
	ending_id.add_theme_color_override("font_color", Color(0.68, 0.78, 0.95, 0.86))
	ending_id.text = "Runtime id: %s" % str(NakamaService.get_meta_value(NavigationFlow.KEY_PLACEHOLDER_ENDING_ID, "placeholder"))
	box.add_child(ending_id)

	var button := Button.new()
	button.name = "MainMenuButton"
	button.text = "Back to Main Menu"
	button.custom_minimum_size = Vector2(0, 58)
	button.add_theme_font_size_override("font_size", 22)
	button.add_theme_color_override("font_color", Color(0.05, 0.05, 0.07, 1.0))
	button.add_theme_stylebox_override("normal", _button_style(Color(0.96, 0.78, 0.24, 0.96)))
	button.add_theme_stylebox_override("hover", _button_style(Color(1.0, 0.86, 0.34, 1.0)))
	button.pressed.connect(_back_to_main_menu)
	box.add_child(button)

func _back_to_main_menu() -> void:
	NavigationFlow.clear_nav_flow_mode(NakamaService)
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.075, 0.085, 0.12, 0.94)
	style.border_color = Color(0.78, 0.86, 1.0, 0.42)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 28
	style.content_margin_top = 26
	style.content_margin_right = 28
	style.content_margin_bottom = 26
	style.shadow_color = Color(0, 0, 0, 0.44)
	style.shadow_size = 16
	return style

func _button_style(bg: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = Color(1.0, 0.96, 0.75, 0.88)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 18
	style.content_margin_top = 10
	style.content_margin_right = 18
	style.content_margin_bottom = 10
	return style
