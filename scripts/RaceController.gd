extends Node3D

@onready var ui_speed: Label = %SpeedLabel
@onready var ui_lap: Label = %LapLabel
@onready var ui_position: Label = %PositionLabel
@onready var ui_net: Label = %NetLabel
@onready var checkpoint_system: Node = %CheckpointSystem
@onready var camera: Camera3D = %FollowCamera
@onready var mobile_controls: Control = %MobileControls
@onready var accel_btn: Button = %AccelButton
@onready var brake_btn: Button = %BrakeButton
@onready var left_btn: Button = %LeftButton
@onready var right_btn: Button = %RightButton
@onready var drift_btn: Button = %DriftButton
@onready var boost_btn: Button = %BoostButton

var match_id: String = ""
var local_user_id: String = ""
var cars: Dictionary = {}
var input_accum: float = 0.0
var snapshot_timer: float = 0.0
var roster: Array = []
var race_started: bool = false
var lap_map: Dictionary = {}
var spawn_points: Array = []

const INPUT_INTERVAL := 1.0 / Config.INPUT_TICK_HZ

func _ready() -> void:
	mobile_controls.visible = OS.has_feature("mobile")
	_setup_mobile_controls()
	_ensure_input_actions()
	await NakamaService.ensure_connected()
	local_user_id = NakamaService.session.user_id
	match_id = NakamaService.get_meta_value("race_match_id", "")
	if match_id == "":
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
		return
	_connect_socket()
	await NakamaService.join_match(match_id)
	_spawn_track()
	_setup_checkpoints()

func _connect_socket() -> void:
	if not NakamaService.socket.received_match_state.is_connected(_on_match_state):
		NakamaService.socket.received_match_state.connect(_on_match_state)

func _spawn_track() -> void:
	var track_scene = load(Config.TRACK_SCENE)
	if track_scene:
		var track_instance = track_scene.instantiate()
		add_child(track_instance)
		var spawn_root = track_instance.get_node_or_null("SpawnPoints")
		spawn_points = []
		if spawn_root:
			for child in spawn_root.get_children():
				if child is Marker3D:
					spawn_points.append(child.global_transform)

func _setup_checkpoints() -> void:
	if checkpoint_system and checkpoint_system.has_signal("checkpoint_valid"):
		checkpoint_system.connect("checkpoint_valid", Callable(self, "_on_checkpoint_valid"))

func _physics_process(delta: float) -> void:
	if not race_started:
		return
	input_accum += delta
	while input_accum >= INPUT_INTERVAL:
		_send_input()
		input_accum -= INPUT_INTERVAL
	_update_ui()
	_update_camera(delta)

func _on_match_state(match_state: NakamaRTAPI.MatchData) -> void:
	if match_state.match_id != match_id:
		return
	if match_state.data == "":
		return
	var parsed = JSON.parse_string(match_state.data)
	var payload: Dictionary = parsed if typeof(parsed) == TYPE_DICTIONARY else {}
	var op := int(match_state.op_code)
	match op:
		NetMessages.OP_RACE_SNAPSHOT:
			_apply_snapshot(payload)
		NetMessages.OP_RACE_RESET:
			_handle_reset(payload)
		NetMessages.OP_RACE_WASTED:
			_handle_wasted(payload)
		NetMessages.OP_RACE_FINISH:
			_handle_finish(payload)
		NetMessages.OP_RACE_MATCH_END:
			_handle_match_end(payload)

func _send_input() -> void:
	var state := _gather_input()
	var car : CarController = cars.get(local_user_id, null)
	if car:
		car.controlled_locally = true
		car.set_input(state)
	var msg := {"input": state}
	var json := JSON.stringify(msg)
	NakamaService.socket.send_match_state_async(match_id, NetMessages.OP_RACE_INPUT, json)

func _gather_input() -> Dictionary:
	var steer := (Input.get_action_strength("steer_right") - Input.get_action_strength("steer_left"))
	var throttle := Input.get_action_strength("accelerate")
	var brake := Input.get_action_strength("brake")
	var drift := Input.is_action_pressed("drift")
	var boost := Input.is_action_pressed("boost")
	return {"steer": steer, "throttle": throttle, "brake": brake, "drift": drift, "boost": boost}

func _apply_snapshot(data:Dictionary) -> void:
	race_started = true
	var racers: Array = data.get("racers", [])
	for racer in racers:
		var rid: String = str(racer.get("id", ""))
		var pos_arr: Array = racer.get("pos", [0,0,0])
		var rot_arr: Array = racer.get("rot", [0,0,0])
		var position: Vector3 = Vector3(pos_arr[0], pos_arr[1], pos_arr[2])
		var basis: Basis = Basis().rotated(Vector3.RIGHT, rot_arr[0])
		basis = basis.rotated(Vector3.UP, rot_arr[1])
		basis = basis.rotated(Vector3.BACK, rot_arr[2])
		var car: CarController = cars.get(rid, null)
		if car == null:
			car = _spawn_car(rid)
		car.apply_network_state(position, basis)
		lap_map[rid] = racer.get("lap", 0)
	_update_positions()

func _spawn_car(racer_id:String) -> CarController:
	var car_scene := load("res://scenes/Car.tscn")
	var car := car_scene.instantiate() as CarController
	add_child(car)
	cars[racer_id] = car
	var spawn_index := cars.size() - 1
	if spawn_index < spawn_points.size():
		var t: Transform3D = spawn_points[spawn_index]
		car.global_transform = t
	else:
		car.global_transform.origin = Vector3(spawn_index * 2.0, 0.5, spawn_index * 1.5)
	return car

func _update_positions() -> void:
	var sorted := cars.keys()
	ui_position.text = "Racers: %d" % sorted.size()

func _handle_reset(data:Dictionary) -> void:
	var target: String = data.get("player_id", "")
	if target != local_user_id:
		return
	var pos: Array = data.get("position", [0,0,0])
	var rot: Array = data.get("rotation", [0,0,0])
	var car: CarController = cars.get(local_user_id, null)
	if car:
		car.global_transform.origin = Vector3(pos[0], pos[1], pos[2])
		var basis := Basis().rotated(Vector3.RIGHT, rot[0]).rotated(Vector3.UP, rot[1]).rotated(Vector3.BACK, rot[2])
		car.global_transform.basis = basis
		car.velocity = Vector3.ZERO

func _handle_wasted(data:Dictionary) -> void:
	var target: String = data.get("player_id", "")
	if target == local_user_id:
		get_tree().change_scene_to_file("res://scenes/Wasted.tscn")

func _handle_finish(data:Dictionary) -> void:
	# Placeholder UI hook
	ui_net.text = "Finished!"

func _handle_match_end(data:Dictionary) -> void:
	NakamaService.set_meta_value("race_results", data.get("results", []))
	get_tree().change_scene_to_file("res://scenes/PostRace.tscn")

func _on_checkpoint_valid(body:Node, checkpoint_index:int, transform:Transform3D) -> void:
	if body is CarController and cars.get(local_user_id, null) == body:
		# Client-side hint; authoritative validation handled server-side
		pass

func _update_ui() -> void:
	var car : CarController = cars.get(local_user_id, null)
	if car:
		var speed: float = car.velocity.length()
		ui_speed.text = "Speed: %02d" % int(speed)
		var lap: int = lap_map.get(local_user_id, 1 if race_started else 0)
		ui_lap.text = "Lap: %d/%d" % [lap, Config.LAPS]
	ui_net.text = "Net: %s" % ("OK" if NakamaService.socket and NakamaService.socket.is_connected_to_host() else "...")

func _update_camera(delta:float) -> void:
	var car : CarController = cars.get(local_user_id, null)
	if not car:
		return
	var target_pos: Vector3 = car.global_transform.origin + Vector3(0, 2.5, 6)
	camera.global_transform.origin = camera.global_transform.origin.lerp(target_pos, delta * 5.0)
	camera.look_at(car.global_transform.origin + Vector3(0,1,0), Vector3.UP)

func _ensure_input_actions() -> void:
	_add_action_if_missing("accelerate")
	_add_action_if_missing("brake")
	_add_action_if_missing("steer_left")
	_add_action_if_missing("steer_right")
	_add_action_if_missing("drift")
	_add_action_if_missing("boost")
	_add_key_event("accelerate", KEY_W)
	_add_key_event("accelerate", KEY_UP)
	_add_key_event("brake", KEY_S)
	_add_key_event("brake", KEY_DOWN)
	_add_key_event("steer_left", KEY_A)
	_add_key_event("steer_left", KEY_LEFT)
	_add_key_event("steer_right", KEY_D)
	_add_key_event("steer_right", KEY_RIGHT)
	_add_key_event("drift", KEY_SPACE)
	_add_key_event("boost", KEY_SHIFT)

func _add_action_if_missing(action:String) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)

func _add_key_event(action:String, keycode:int) -> void:
	var ev := InputEventKey.new()
	ev.keycode = keycode
	InputMap.action_add_event(action, ev)

func _setup_mobile_controls() -> void:
	if not OS.has_feature("mobile"):
		return
	_connect_button(accel_btn, "accelerate")
	_connect_button(brake_btn, "brake")
	_connect_button(left_btn, "steer_left")
	_connect_button(right_btn, "steer_right")
	_connect_button(drift_btn, "drift")
	_connect_button(boost_btn, "boost")

func _connect_button(btn:Button, action:String) -> void:
	if btn == null:
		return
	btn.pressed.connect(func(): Input.action_press(action))
	btn.button_up.connect(func(): Input.action_release(action))
