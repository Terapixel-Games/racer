extends Node

const TrackCatalog = preload("res://scripts/track/TrackCatalog.gd")
const OnlineRaceRules = preload("res://scripts/logic/OnlineRaceRules.gd")

const RETRY_ATTEMPTS := 3
const RETRY_DELAY := 1.5

var client : NakamaClient
var session : NakamaSession
var socket : NakamaSocket
var metadata := {}
var offline_mode := false
var offline_user_id := "local-racer"
const DEVICE_ID_FILE := "user://device_id.txt"

signal socket_connected
signal socket_closed

func _ready() -> void:
	Nakama.logger._level = NakamaLogger.LOG_LEVEL.INFO
	client = Nakama.create_client(Config.NAKAMA_SERVER_KEY, Config.get_host(), Config.get_port(), Config.get_scheme())

func ensure_connected() -> void:
	if offline_mode:
		return
	if _should_force_offline():
		_enter_offline_mode("Using local fallback for automated capture.")
		return
	if session and session.is_expired() == false and socket and socket.is_connected_to_host():
		return
	await _authenticate()
	if offline_mode:
		return
	await _connect_socket()

func _authenticate() -> void:
	var device_id := _get_device_id()
	var retries := 0
	while retries < RETRY_ATTEMPTS:
		var result = await client.authenticate_device_async(device_id, "", true, {"game_id": Config.GAME_ID, "game_version": Config.GAME_VERSION})
		if result is NakamaSession:
			session = result
			return
		retries += 1
		if Config.LOCAL_FALLBACK_ENABLED:
			_enter_offline_mode("Authentication failed; using local fallback.")
			return
		await get_tree().create_timer(RETRY_DELAY * retries).timeout
	push_error("Failed to authenticate with Nakama after retries.")
	if Config.LOCAL_FALLBACK_ENABLED:
		_enter_offline_mode("Authentication retries exhausted; using local fallback.")

func _connect_socket() -> void:
	socket = Nakama.create_socket_from(client)
	socket.connected.connect(func(): emit_signal("socket_connected"))
	socket.closed.connect(func(): emit_signal("socket_closed"))
	var retries := 0
	while retries < RETRY_ATTEMPTS:
		var result = await socket.connect_async(session, true, 30000)
		if result is NakamaAsyncResult and result.is_exception() == false:
			return
		retries += 1
		if Config.LOCAL_FALLBACK_ENABLED:
			_enter_offline_mode("Socket connection failed; using local fallback.")
			return
		await get_tree().create_timer(RETRY_DELAY * retries).timeout
	push_error("Failed to connect Nakama socket after retries.")
	if Config.LOCAL_FALLBACK_ENABLED:
		_enter_offline_mode("Socket retries exhausted; using local fallback.")

func _get_device_id() -> String:
	if not Engine.has_singleton("OS"):
		return ""
	var device_id := ""
	if FileAccess.file_exists(DEVICE_ID_FILE):
		var f = FileAccess.open(DEVICE_ID_FILE, FileAccess.READ)
		if f:
			device_id = f.get_as_text().strip_edges()
			f.close()
	if device_id == "":
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		device_id = "%s-%s" % [Time.get_unix_time_from_system(), rng.randi()]
		var f_out = FileAccess.open(DEVICE_ID_FILE, FileAccess.WRITE)
		if f_out:
			f_out.store_string(device_id)
			f_out.flush()
			f_out.close()
	return device_id

func call_rpc(name:String, payload:Dictionary) -> Dictionary:
	if offline_mode:
		return _offline_rpc(name, payload)
	payload["game_id"] = Config.GAME_ID
	payload["game_version"] = Config.GAME_VERSION
	var res = await client.rpc_async(session, name, JSON.stringify(payload))
	if res is NakamaAPI.ApiRpc:
		var parsed = JSON.parse_string(res.payload)
		return parsed if typeof(parsed) == TYPE_DICTIONARY else {}
	if typeof(res) == TYPE_DICTIONARY and res.has("payload"):
		var parsed_dict = res["payload"]
		return parsed_dict if typeof(parsed_dict) == TYPE_DICTIONARY else JSON.parse_string(parsed_dict)
	if typeof(res) == TYPE_STRING:
		var parsed_str = JSON.parse_string(res)
		return parsed_str if typeof(parsed_str) == TYPE_DICTIONARY else {}
	return {}

func join_match(match_id:String, match_metadata: Dictionary = {}) -> NakamaRTAPI.Match:
	if offline_mode:
		return null
	return await socket.join_match_async(match_id, match_metadata)

func leave_match(match_id:String) -> void:
	if offline_mode:
		return
	if socket:
		await socket.leave_match_async(match_id)

func set_meta_value(key:String, value) -> void:
	metadata[key] = value

func get_meta_value(key:String, default_value=null):
	return metadata.get(key, default_value)

func get_user_id() -> String:
	if offline_mode:
		return offline_user_id
	if session:
		return session.user_id
	return ""

func is_online_socket_ready() -> bool:
	return not offline_mode and socket != null and socket.is_connected_to_host()

func _enter_offline_mode(reason: String) -> void:
	if offline_mode:
		return
	offline_mode = true
	offline_user_id = "local-%s" % _get_device_id().substr(0, 8)
	push_warning(reason)

func _offline_rpc(name: String, payload: Dictionary) -> Dictionary:
	match name:
		"racer_online_join_or_create":
			var mode := OnlineRaceRules.normalize_mode(str(payload.get("mode", OnlineRaceRules.MODE_SINGLE_RACE)))
			var track_ids := OnlineRaceRules.select_track_ids(TrackCatalog.list_tracks(), mode, str(payload.get("track_id", "")))
			var track_id := track_ids[0] if not track_ids.is_empty() else TrackCatalog.get_default_track_id()
			var track := _offline_track_recipe(track_id)
			var selected_racer := str(payload.get("selected_racer_id", "Racer"))
			var race_mode := OnlineRaceRules.race_mode_for_online_mode(mode)
			return {
				"match_id": "offline-lobby",
				"race_match_id": "offline-race",
				"session_id": "offline-session",
				"room_code": "LOCAL",
				"mode": mode,
				"round_index": 0,
				"track_ids": track_ids,
				"players": [{"name": selected_racer, "racer_id": selected_racer}],
				"track": track,
				"race_mode": race_mode
			}
		_:
			return {}

func _offline_track_recipe(track_id: String = "") -> Dictionary:
	var resolved := track_id if TrackCatalog.has_track(track_id) else TrackCatalog.get_default_track_id()
	return TrackCatalog.get_metadata(resolved)

func _should_force_offline() -> bool:
	if not Config.LOCAL_FALLBACK_ENABLED:
		return false
	if OS.has_feature("debug") and Config.get_host() == Config.NAKAMA_HOST:
		return true
	for arg in OS.get_cmdline_args():
		var arg_text := str(arg)
		if arg_text.find("--write-movie") >= 0 or arg_text.find("ScenarioDriver.gd") >= 0:
			return true
	for arg in OS.get_cmdline_user_args():
		var arg_text := str(arg)
		if arg_text.find("--write-movie") >= 0 or arg_text.find("ScenarioDriver.gd") >= 0:
			return true
	return false
