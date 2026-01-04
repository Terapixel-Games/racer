extends Node

const RETRY_ATTEMPTS := 3
const RETRY_DELAY := 1.5

var client : NakamaClient
var session : NakamaSession
var socket : NakamaSocket
var metadata := {}
const DEVICE_ID_FILE := "user://device_id.txt"

signal socket_connected
signal socket_closed

func _ready() -> void:
	Nakama.logger._level = NakamaLogger.LOG_LEVEL.INFO
	client = Nakama.create_client(Config.NAKAMA_SERVER_KEY, Config.get_host(), Config.get_port(), Config.get_scheme())

func ensure_connected() -> void:
	if session and session.is_expired() == false and socket and socket.is_connected_to_host():
		return
	await _authenticate()
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
		await get_tree().create_timer(RETRY_DELAY * retries).timeout
	push_error("Failed to authenticate with Nakama after retries.")

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
		await get_tree().create_timer(RETRY_DELAY * retries).timeout
	push_error("Failed to connect Nakama socket after retries.")

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

func join_match(match_id:String) -> NakamaRTAPI.Match:
	return await socket.join_match_async(match_id)

func leave_match(match_id:String) -> void:
	if socket:
		await socket.leave_match_async(match_id)

func set_meta_value(key:String, value) -> void:
	metadata[key] = value

func get_meta_value(key:String, default_value=null):
	return metadata.get(key, default_value)
