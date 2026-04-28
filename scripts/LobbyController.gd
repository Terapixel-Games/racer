extends Control

const RacerRoster = preload("res://scripts/logic/RacerRoster.gd")

@onready var room_code_label: Label = %RoomCodeLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var player_list: VBoxContainer = %PlayerList
@onready var status_label: Label = %StatusLabel
@onready var leave_button: Button = %LeaveButton

var lobby_match_id := ""

func _ready() -> void:
	status_label.text = "Joining lobby..."
	leave_button.pressed.connect(_leave_to_menu)
	await NakamaService.ensure_connected()
	if NakamaService.offline_mode:
		_start_offline_lobby()
		return
	_connect_socket_handlers()
	await _join_or_create_lobby()

func _connect_socket_handlers() -> void:
	if not NakamaService.socket.received_match_state.is_connected(_on_match_state):
		NakamaService.socket.received_match_state.connect(_on_match_state)

func _join_or_create_lobby() -> void:
	var join_metadata := lobby_join_metadata_for_racer(_selected_racer_id())
	var res := await NakamaService.call_rpc("lobby_join_or_create", join_metadata.duplicate())
	lobby_match_id = res.get("match_id", "")
	NakamaService.set_meta_value("lobby_room_code", res.get("room_code", ""))
	if res.has("track"):
		NakamaService.set_meta_value("track_recipe", res.get("track"))
		NakamaService.set_meta_value("track_id", res.get("track").get("id", ""))
	if lobby_match_id == "":
		status_label.text = "Failed to join lobby"
		return
	await NakamaService.join_match(lobby_match_id, join_metadata)
	status_label.text = ""
	room_code_label.text = "Room: %s" % res.get("room_code", "----")

func _start_offline_lobby() -> void:
	var selected_racer := _selected_racer_id()
	var res := await NakamaService.call_rpc("lobby_join_or_create", lobby_join_metadata_for_racer(selected_racer))
	lobby_match_id = str(res.get("match_id", "offline-lobby"))
	NakamaService.set_meta_value("lobby_room_code", res.get("room_code", "LOCAL"))
	NakamaService.set_meta_value("race_match_id", res.get("race_match_id", "offline-race"))
	if res.has("track"):
		NakamaService.set_meta_value("track_recipe", res.get("track"))
		NakamaService.set_meta_value("track_id", res.get("track").get("id", "offline-serpentine"))
	room_code_label.text = "Room: LOCAL"
	countdown_label.text = "Offline shakedown"
	status_label.text = "Backend unavailable. Running local race."
	for child in player_list.get_children():
		child.queue_free()
	var label := Label.new()
	label.text = player_label_from_entry({"name": selected_racer, "racer_id": selected_racer})
	player_list.add_child(label)
	await get_tree().create_timer(0.35).timeout
	get_tree().change_scene_to_file("res://scenes/Race.tscn")

func _on_match_state(match_state: NakamaRTAPI.MatchData) -> void:
	if match_state.match_id != lobby_match_id:
		return
	var op := int(match_state.op_code)
	var payload := {}
	if match_state.data != "":
		payload = JSON.parse_string(match_state.data)
	match op:
		NetMessages.OP_LOBBY_STATE:
			_update_lobby_state(payload)
		NetMessages.OP_LOBBY_RACE_START:
			_start_race(payload)

func _update_lobby_state(data:Dictionary) -> void:
	var countdown : int = data.get("countdown", Config.LOBBY_COUNTDOWN_SECONDS)
	countdown_label.text = "Race in: %d" % int(ceil(countdown))
	NakamaService.set_meta_value("lobby_room_code", data.get("room_code", "----"))
	if data.has("track"):
		NakamaService.set_meta_value("track_recipe", data.get("track"))
		NakamaService.set_meta_value("track_id", data.get("track").get("id", ""))
	for child in player_list.get_children():
		child.queue_free()
	for player in data.get("players", []):
		var label := Label.new()
		label.text = player_label_from_entry(player)
		player_list.add_child(label)

func _start_race(data:Dictionary) -> void:
	var race_match_id : String = data.get("race_match_id", "")
	if race_match_id == "":
		return
	NakamaService.set_meta_value("race_match_id", race_match_id)
	NakamaService.set_meta_value("lobby_match_id", lobby_match_id)
	if data.has("track"):
		NakamaService.set_meta_value("track_recipe", data.get("track"))
		NakamaService.set_meta_value("track_id", data.get("track").get("id", ""))
	get_tree().change_scene_to_file("res://scenes/Race.tscn")

func _leave_to_menu() -> void:
	if lobby_match_id != "" and not NakamaService.offline_mode:
		NakamaService.leave_match(lobby_match_id)
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _selected_racer_id() -> String:
	return normalize_selected_racer_id(str(NakamaService.get_meta_value("selected_racer_id", RacerRoster.DEFAULT_RACER_ID)))

static func normalize_selected_racer_id(racer_id: String) -> String:
	var trimmed := racer_id.strip_edges()
	if RacerRoster.has(trimmed):
		return trimmed
	return RacerRoster.DEFAULT_RACER_ID

static func lobby_join_metadata_for_racer(racer_id: String) -> Dictionary:
	var normalized := normalize_selected_racer_id(racer_id)
	return {
		"selected_racer_id": normalized,
		"racer_display_name": normalized,
	}

static func player_label_from_entry(entry: Variant) -> String:
	if entry is Dictionary:
		var racer_id := str((entry as Dictionary).get("racer_id", "")).strip_edges()
		if RacerRoster.has(racer_id):
			return racer_id
		var name := str((entry as Dictionary).get("name", "")).strip_edges()
		return name if name != "" else "Racer"
	var label := str(entry).strip_edges()
	return label if label != "" else "Racer"
