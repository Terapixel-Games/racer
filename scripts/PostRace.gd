extends Control

@onready var results_list: VBoxContainer = %ResultsList
@onready var lobby_button: Button = %LobbyButton
@onready var menu_button: Button = %MenuButton
@onready var title_label: Label = %Title

func _ready() -> void:
	if _is_local_single_race():
		lobby_button.text = "Restart"
		menu_button.text = "Level Select"
	_populate_results()
	lobby_button.pressed.connect(_on_primary_pressed)
	menu_button.pressed.connect(_on_secondary_pressed)

func _populate_results() -> void:
	for child in results_list.get_children():
		child.queue_free()
	var results = NakamaService.get_meta_value("race_results", [])
	if results.is_empty():
		var label := Label.new()
		label.text = "Results unavailable."
		results_list.add_child(label)
		return
	results = _sorted_results(results)
	_update_title(results)
	_add_header()
	var rank := 1
	var local_id := ""
	if _is_local_single_race():
		local_id = "local_player"
	elif NakamaService.session:
		local_id = NakamaService.session.user_id
	for r in results:
		results_list.add_child(_build_row(r, rank, r.get("id", "") == local_id))
		rank += 1

func _on_primary_pressed() -> void:
	if _is_local_single_race():
		NakamaService.set_meta_value("race_match_id", "local-single-race")
		NakamaService.set_meta_value("race_mode", "local_single")
		get_tree().change_scene_to_file("res://scenes/Race.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/Lobby.tscn")

func _on_secondary_pressed() -> void:
	if _is_local_single_race():
		get_tree().change_scene_to_file("res://scenes/LevelSelect.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _is_local_single_race() -> bool:
	return str(NakamaService.get_meta_value("race_mode", "")) == "local_single"

func _sorted_results(results: Array) -> Array:
	var copy := results.duplicate(true)
	copy.sort_custom(func(a, b):
		var a_finished := bool(a.get("finished", false))
		var b_finished := bool(b.get("finished", false))
		if a_finished != b_finished:
			return a_finished and not b_finished
		var a_wasted := bool(a.get("wasted", false))
		var b_wasted := bool(b.get("wasted", false))
		if a_wasted != b_wasted:
			return (not a_wasted) and b_wasted
		var a_ft := float(a.get("finish_time", -1.0))
		var b_ft := float(b.get("finish_time", -1.0))
		if a_finished and b_finished and a_ft >= 0 and b_ft >= 0 and a_ft != b_ft:
			return a_ft < b_ft
		var a_prog := float(a.get("progress", _fallback_progress(a)))
		var b_prog := float(b.get("progress", _fallback_progress(b)))
		if a_prog == b_prog:
			return String(a.get("id", "")) < String(b.get("id", ""))
		return a_prog > b_prog
	)
	return copy

func _fallback_progress(entry: Dictionary) -> float:
	var lap: int = int(entry.get("lap", 0))
	var checkpoint: int = int(entry.get("checkpoint", 0))
	return float((lap - 1) * 10 + checkpoint) # arbitrary checkpoint count if unknown

func _display_name(entry: Dictionary, is_local: bool) -> String:
	var rid := str(entry.get("id", ""))
	var is_ai := bool(entry.get("is_ai", rid.begins_with("ai_")))
	var racer_id := str(entry.get("racer_id", "")).strip_edges()
	var name := racer_id if not racer_id.is_empty() else rid
	if is_ai and racer_id.is_empty() and rid.begins_with("ai_"):
		name = "AI " + rid.trim_prefix("ai_")
	if is_local:
		name += " (You)"
	return name

func _status_text(entry: Dictionary) -> String:
	if bool(entry.get("finished", false)):
		return "Finished"
	if bool(entry.get("wasted", false)):
		return "Wasted"
	return "Racing"

func _add_header() -> void:
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	header.add_child(_header_label("#", 50))
	header.add_child(_header_label("Racer", 220))
	header.add_child(_header_label("Status", 120))
	header.add_child(_header_label("Lap", 80))
	results_list.add_child(header)

func _header_label(text: String, min_width: int) -> Label:
	var l := Label.new()
	l.text = text
	l.custom_minimum_size.x = min_width
	l.add_theme_color_override("font_color", Color(0.85, 0.9, 1))
	return l

func _build_row(entry: Dictionary, rank: int, is_local: bool) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.add_child(_cell_label(str(rank), 50, true))
	row.add_child(_cell_label(_display_name(entry, is_local), 220, is_local))
	row.add_child(_cell_label(_status_text(entry), 120, is_local))
	var lap: int = int(entry.get("lap", 0))
	row.add_child(_cell_label(str(lap), 80, is_local))
	return row

func _cell_label(text: String, min_width: int, emphasize: bool) -> Label:
	var l := Label.new()
	l.text = text
	l.custom_minimum_size.x = min_width
	if emphasize:
		l.add_theme_color_override("font_color", Color(0.95, 1, 0.8))
	return l

func _update_title(results: Array) -> void:
	if title_label == null or results.is_empty():
		return
	var winner : Variant = results[0]
	var local_id := "local_player" if _is_local_single_race() else (NakamaService.session.user_id if NakamaService.session else "")
	var winner_name := _display_name(winner, winner.get("id", "") == local_id)
	title_label.text = "Race Results — Winner: %s" % winner_name
