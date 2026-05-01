extends Node3D

const TrackBuilder = preload("res://scripts/TrackBuilder.gd")
const TrackCatalog = preload("res://scripts/track/TrackCatalog.gd")
const TrackProgressRules = preload("res://scripts/track/TrackProgressRules.gd")
const TrackRuntimeBuilder = preload("res://scripts/track/TrackRuntimeBuilder.gd")
const TrackRuntimeScene = preload("res://scripts/track/TrackRuntimeScene.gd")
const ItemRules = preload("res://scripts/logic/ItemRules.gd")
const OutOfBoundsRules = preload("res://scripts/logic/OutOfBoundsRules.gd")

@onready var ui_speed: Label = %SpeedLabel
@onready var ui_speed_bar: ProgressBar = get_node_or_null("%SpeedBar") as ProgressBar
@onready var ui_lap: Label = %LapLabel
@onready var ui_position: Label = %PositionLabel
@onready var ui_net: Label = %NetLabel
@onready var ui_item: Label = %ItemLabel
@onready var ui_drift: Label = %DriftLabel
@onready var top_left_panel: Control = $UI/HUD/TopLeftPanel
@onready var lap_pill: Control = $UI/HUD/LapPill
@onready var top_right_panel: Control = $UI/HUD/TopRightPanel
@onready var speed_ui: Control = $UI/HUD/SpeedUI
@onready var checkpoint_system: Node = %CheckpointSystem
@onready var camera: Camera3D = %FollowCamera
@onready var mobile_controls: Control = %MobileControls
@onready var accel_btn: Button = %AccelButton
@onready var brake_btn: Button = %BrakeButton
@onready var drift_btn: Button = %DriftButton
@onready var boost_btn: Button = %BoostButton
@onready var item_btn: Button = %ItemButton
@onready var return_btn: Button = %ReturnButton
@onready var ui_message: Label = %MessageLabel
@onready var steer_joystick_area: Control = %SteerJoystickArea
@onready var steer_joystick_knob: Control = %SteerJoystickKnob
@onready var heat_distortion: ColorRect = %HeatDistortion
@onready var water_drops: ColorRect = %WaterDrops

var match_id: String = ""
var local_user_id: String = ""
var cars: Dictionary = {}
var input_accum: float = 0.0
var snapshot_timer: float = 0.0
var roster: Array = []
var race_started: bool = false
var lap_map: Dictionary = {}
var spawn_points: Array = []
var track_laps: int = Config.LAPS
var track_checkpoint_total: int = 0
var racer_states: Dictionary = {}
var checkpoint_points: Array = []
var track_waypoints: Array = []
var track_checkpoint_indices: Array[int] = []
var track_alternate_routes: Array[Dictionary] = []
var finish_announced: bool = false
var track_out_of_bounds_y := -50.0
var track_reset_mode := ""
var track_road_width := 12.0
var track_closed_loop := true
var local_respawn_transform := Transform3D.IDENTITY
var has_local_respawn_transform := false
var last_on_track_center_transform := Transform3D.IDENTITY
var has_last_on_track_center_transform := false
var local_car_off_course := false
const CAMERA_DISTANCE := 5.2
const CAMERA_HEIGHT := 1.8
const CAMERA_LOOK_HEIGHT := 0.85
const CAMERA_FOLLOW_SPEED := 8.0
const CAMERA_OCCLUDED_FOLLOW_SPEED := 18.0
const CAMERA_FOV := 68.0
const CAMERA_NEAR := 0.05
const CAMERA_OCCLUSION_MASK := 1
const CAMERA_OCCLUSION_CLEARANCE := 0.7
const CAMERA_OCCLUSION_MIN_DISTANCE := 1.1

const INPUT_INTERVAL := 1.0 / Config.INPUT_TICK_HZ
const MESSAGE_DURATION := 3.0
var message_timer: float = 0.0
var local_item_slot := ""
var item_roll_timer := 0.0
var item_rng := RandomNumberGenerator.new()
var mobile_steer_value := 0.0
var mobile_steer_touch_id := -1
var mobile_action_touches: Dictionary = {}
var heat_source_positions: Array[Vector3] = []
var heat_distortion_intensity := 0.0
var sink_water_zones: Array[Dictionary] = []
var appliance_rumble_positions: Array[Vector3] = []
var water_drop_intensity := 0.0
var track_audio_ids: Dictionary = {}
var track_audio_zones: Array = []
var audio_zone_players: Dictionary = {}
var audio_zone_active: Dictionary = {}
var music_player: AudioStreamPlayer
var previous_boost_pressed := false
var previous_drift_pressed := false
var sfx_boost: AudioStream
var sfx_drift: AudioStream
var sfx_item_pickup: AudioStream

const HEAT_DISTORTION_RADIUS := 38.0
const HEAT_DISTORTION_INNER_RADIUS := 12.0
const HEAT_DISTORTION_FADE_SPEED := 5.0
const SINK_WATER_DROPS_FADE_IN_SPEED := 6.5
const SINK_WATER_DROPS_DRY_SPEED := 0.55
const APPLIANCE_RUMBLE_RADIUS := 34.0
const APPLIANCE_RUMBLE_INNER_RADIUS := 13.0
const CAMERA_SHAKE_MAX_OFFSET := 0.34
const BOOST_SFX_PATH := "res://assets/source/audio/canva/driving/boost/boost_burst_canva_01.wav"
const DRIFT_SFX_PATH := "res://assets/source/audio/canva/driving/drift/drift_release_canva_01.wav"
const ITEM_PICKUP_SFX_PATH := "res://assets/source/audio/canva/items/pickup/item_pickup_canva_01.wav"
const MOBILE_BASE_VIEWPORT := Vector2(1920.0, 1080.0)
const MOBILE_TOUCH_SCALE := 2.0
const MOBILE_SAFE_MARGIN := 28.0

func _ready() -> void:
	item_rng.randomize()
	_setup_audio_players()
	camera.fov = CAMERA_FOV
	camera.near = CAMERA_NEAR
	mobile_controls.visible = OS.has_feature("mobile")
	_setup_mobile_controls()
	_ensure_input_actions()
	await NakamaService.ensure_connected()
	local_user_id = NakamaService.get_user_id()
	match_id = NakamaService.get_meta_value("race_match_id", "")
	if match_id == "":
		get_tree().call_deferred("change_scene_to_file", "res://scenes/MainMenu.tscn")
		return
	if NakamaService.offline_mode:
		_start_offline_race()
		return
	_connect_socket()
	await NakamaService.join_match(match_id)
	_spawn_track()
	_setup_checkpoints()

func _start_offline_race() -> void:
	_spawn_track()
	_setup_checkpoints()
	var car := _spawn_car(local_user_id)
	car.controlled_locally = true
	lap_map[local_user_id] = 1
	racer_states[local_user_id] = {
		"lap": 1,
		"checkpoint": 0,
		"finished": false,
		"wasted": false,
		"pos": car.global_transform.origin,
		"progress": 0.0,
		"finish_time": -1.0,
	}
	race_started = true
	ui_net.text = "Net: LOCAL"
	_show_message("Local shakedown")

func _connect_socket() -> void:
	if not NakamaService.socket.received_match_state.is_connected(_on_match_state):
		NakamaService.socket.received_match_state.connect(_on_match_state)

func _setup_audio_players() -> void:
	_ensure_audio_bus("Music")
	_ensure_audio_bus("SFX")
	music_player = AudioStreamPlayer.new()
	music_player.name = "RaceMusic"
	music_player.bus = "Music"
	music_player.volume_db = -9.0
	add_child(music_player)
	sfx_boost = load(BOOST_SFX_PATH) as AudioStream
	sfx_drift = load(DRIFT_SFX_PATH) as AudioStream
	sfx_item_pickup = load(ITEM_PICKUP_SFX_PATH) as AudioStream

func _ensure_audio_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	var index := AudioServer.get_bus_count()
	AudioServer.add_bus(index)
	AudioServer.set_bus_name(index, bus_name)

func _spawn_track() -> void:
	var track_id := str(NakamaService.get_meta_value("track_id", TrackCatalog.get_default_track_id()))
	var definition = TrackCatalog.get_definition(track_id)
	if definition != null:
		var built := _instantiate_track_package(track_id, definition)
		var track_instance: Node = built.get("node", null)
		if track_instance:
			add_child(track_instance)
			_cache_heat_sources(track_instance)
			var built_checkpoint_system := track_instance.get_node_or_null("CheckpointSystem")
			if built_checkpoint_system == null:
				built_checkpoint_system = track_instance.get_node_or_null("BuiltTrack/CheckpointSystem")
			if built_checkpoint_system != null:
				checkpoint_system = built_checkpoint_system
		spawn_points = built.get("spawns", [])
		track_laps = built.get("laps", Config.LAPS)
		track_waypoints = built.get("waypoints", [])
		track_checkpoint_total = int(built.get("checkpoints", 0))
		_apply_track_reset_metadata(built.get("metadata", {}))
		if track_checkpoint_total <= 0 and track_waypoints is Array and track_waypoints.size() > 0:
			track_checkpoint_total = track_waypoints.size()
		return

	var recipe = NakamaService.get_meta_value("track_recipe", null)
	if recipe is Dictionary:
		var built = TrackBuilder.build(recipe)
		var track_instance: Node = built.get("node", null)
		if track_instance:
			add_child(track_instance)
			_cache_heat_sources(track_instance)
		spawn_points = built.get("spawns", [])
		track_laps = built.get("laps", Config.LAPS)
		track_waypoints = built.get("waypoints", [])
		_apply_track_reset_metadata(recipe)
		if track_waypoints is Array and track_waypoints.size() > 0:
			track_checkpoint_total = track_waypoints.size()
	else:
		var track_scene = load(Config.TRACK_SCENE)
		if track_scene:
			var track_instance = track_scene.instantiate()
			add_child(track_instance)
			_cache_heat_sources(track_instance)
			var spawn_root = track_instance.get_node_or_null("SpawnPoints")
			spawn_points = []
			if spawn_root:
				for child in spawn_root.get_children():
					if child is Marker3D:
						spawn_points.append(child.global_transform)
		track_checkpoint_total = checkpoint_system.checkpoint_count

func _instantiate_track_package(track_id: String, definition) -> Dictionary:
	var scene_path := TrackCatalog.get_scene_path(track_id)
	if not scene_path.is_empty():
		var packed := load(scene_path)
		if packed is PackedScene:
			var scene_root: Node = packed.instantiate()
			if scene_root != null:
				if scene_root is TrackRuntimeScene:
					scene_root.definition = definition
					scene_root.rebuild_on_ready = false
					var package_build = scene_root.rebuild()
					if package_build is Dictionary:
						package_build["node"] = scene_root
						return package_build
	return TrackRuntimeBuilder.build(definition)

func _setup_checkpoints() -> void:
	if checkpoint_system and checkpoint_system.has_signal("checkpoint_valid"):
		checkpoint_system.connect("checkpoint_valid", Callable(self, "_on_checkpoint_valid"))
	_cache_checkpoint_points()
	if track_checkpoint_total <= 0 and checkpoint_system:
		track_checkpoint_total = checkpoint_system.checkpoint_count

func _cache_heat_sources(track_instance: Node) -> void:
	heat_source_positions.clear()
	sink_water_zones.clear()
	appliance_rumble_positions.clear()
	_collect_heat_source_positions(track_instance)

func _collect_heat_source_positions(node: Node) -> void:
	if node == null:
		return
	if node is Node3D:
		var node_3d := node as Node3D
		var name_lower := node.name.to_lower()
		if name_lower == "kitchenstove":
			heat_source_positions.append(node_3d.global_transform.origin)
		elif name_lower == "washer" or name_lower == "dryer":
			appliance_rumble_positions.append(node_3d.global_transform.origin)
		elif name_lower == "sinksplashzone":
			sink_water_zones.append({
				"position": node_3d.global_transform.origin,
				"radius": _area_sphere_radius(node, 18.0),
			})
	for child in node.get_children():
		_collect_heat_source_positions(child)

func _area_sphere_radius(node: Node, fallback: float) -> float:
	for child in node.get_children():
		if child is CollisionShape3D:
			var collision_shape := child as CollisionShape3D
			if collision_shape.shape is SphereShape3D:
				return maxf((collision_shape.shape as SphereShape3D).radius, 0.1)
	return fallback

func _physics_process(delta: float) -> void:
	if not race_started:
		return
	input_accum += delta
	while input_accum >= INPUT_INTERVAL:
		_send_input()
		input_accum -= INPUT_INTERVAL
	_update_local_track_return_point()
	_handle_manual_return_to_track()
	_handle_local_out_of_bounds()
	_tick_local_item_slot(delta)
	_update_ui()
	_update_camera(delta)
	_update_heat_distortion(delta)
	_update_water_drops(delta)
	_update_audio_zone_players()
	_update_game_sounds()
	_tick_message(delta)

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
		var euler := car.global_transform.basis.get_euler()
		state["position"] = [
			car.global_transform.origin.x,
			car.global_transform.origin.y,
			car.global_transform.origin.z,
		]
		state["rotation"] = [euler.x, euler.y, euler.z]
		if bool(state.get("item_use", false)):
			_consume_local_item(car)
		if NakamaService.offline_mode:
			racer_states[local_user_id] = {
				"lap": lap_map.get(local_user_id, 1),
				"checkpoint": 0,
				"finished": false,
				"wasted": false,
				"pos": car.global_transform.origin,
				"progress": car.global_transform.origin.length(),
				"finish_time": -1.0,
			}
			return
	var msg := {"input": state}
	var json := JSON.stringify(msg)
	NakamaService.socket.send_match_state_async(match_id, NetMessages.OP_RACE_INPUT, json)

func _gather_input() -> Dictionary:
	var steer := (Input.get_action_strength("steer_left") - Input.get_action_strength("steer_right"))
	if mobile_controls.visible and absf(mobile_steer_value) > 0.02:
		steer = mobile_steer_value
	var throttle := Input.get_action_strength("accelerate")
	var brake := Input.get_action_strength("brake")
	var boost := Input.is_action_pressed("boost")
	var drift := Input.is_action_pressed("drift")
	var item_use := Input.is_action_just_pressed("use_item")
	return {"steer": steer, "throttle": throttle, "brake": brake, "drift": drift, "boost": boost, "item_use": item_use}

func _input(event: InputEvent) -> void:
	if not mobile_controls.visible:
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if not touch.pressed:
			_release_mobile_touch(touch.index)
	elif event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		if not (event as InputEventMouseButton).pressed:
			_release_mobile_touch(-1)
			if mobile_steer_touch_id == -2:
				mobile_steer_touch_id = -1
				_reset_steer_joystick()

func _apply_snapshot(data:Dictionary) -> void:
	race_started = true
	var snapshot_checkpoints: int = int(data.get("checkpoints", 0))
	if snapshot_checkpoints > 0:
		track_checkpoint_total = snapshot_checkpoints
	var racers: Array = data.get("racers", [])
	var previous_local_lap: int = lap_map.get(local_user_id, 0)
	var new_local_lap := previous_local_lap
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
		var checkpoint: int = racer.get("checkpoint", 0)
		var finished: bool = racer.get("finished", false)
		var wasted: bool = racer.get("wasted", false)
		var server_progress: float = float(racer.get("progress", -1.0))
		var finish_time: float = float(racer.get("finish_time", -1.0))
		racer_states[rid] = {
			"lap": lap_map[rid],
			"checkpoint": checkpoint,
			"finished": finished,
			"wasted": wasted,
			"pos": position,
			"progress": server_progress,
			"finish_time": finish_time,
		}
		if rid == local_user_id:
			new_local_lap = lap_map[rid]
			if finished and not finish_announced:
				_show_message("Course complete!")
				finish_announced = true
	_update_positions()
	if new_local_lap > previous_local_lap and previous_local_lap > 0 and not finish_announced:
		_show_message("Lap %d complete" % (new_local_lap - 1))

func _spawn_car(racer_id:String) -> CarController:
	var car_scene := load("res://scenes/Car.tscn")
	var car := car_scene.instantiate() as CarController
	add_child(car)
	cars[racer_id] = car
	var spawn_index := cars.size() - 1
	var spawn_xform := Transform3D.IDENTITY
	if spawn_index < spawn_points.size():
		spawn_xform = spawn_points[spawn_index]
	else:
		spawn_xform.origin = Vector3(spawn_index * 2.0, 1.0, spawn_index * 1.5)
	car.global_transform = _snap_to_ground(spawn_xform)
	if racer_id == local_user_id:
		local_respawn_transform = car.global_transform
		has_local_respawn_transform = true
		last_on_track_center_transform = car.global_transform
		has_last_on_track_center_transform = true
	return car

func _snap_to_ground(xform: Transform3D) -> Transform3D:
	# Raycast from above and place the car slightly above the hit so the collider clears the road.
	var origin := xform.origin + Vector3(0, 6, 0)
	var target := origin + Vector3(0, -20, 0)
	var space_state = get_world_3d().direct_space_state
	var params = PhysicsRayQueryParameters3D.create(origin, target)
	var result = space_state.intersect_ray(params)
	if result.has("position"):
		xform.origin.y = result.position.y + 1.0
	return xform

func _update_positions() -> void:
	if racer_states.is_empty():
		ui_position.text = "--/--"
		return
	var checkpoint_total := _get_checkpoint_total()
	var entries: Array = []
	for rid in racer_states.keys():
		var info: Dictionary = racer_states[rid]
		var lap: int = int(info.get("lap", 0))
		var checkpoint: int = int(info.get("checkpoint", 0))
		var pos: Vector3 = info.get("pos", Vector3.ZERO)
		var finished: bool = info.get("finished", false)
		var wasted: bool = info.get("wasted", false)
		var server_progress: float = float(info.get("progress", -1.0))
		var progress := _compute_progress(lap, checkpoint, pos, checkpoint_total, finished, server_progress)
		entries.append({
			"id": rid,
			"finished": finished,
			"wasted": wasted,
			"progress": progress,
			"finish_time": float(info.get("finish_time", -1.0)),
		})
	entries.sort_custom(func(a, b):
		if a["finished"] != b["finished"]:
			return a["finished"] and not b["finished"]
		if a["wasted"] != b["wasted"]:
			return (not a["wasted"]) and b["wasted"]
		var a_ft := float(a.get("finish_time", -1.0))
		var b_ft := float(b.get("finish_time", -1.0))
		if a["finished"] and b["finished"] and a_ft >= 0.0 and b_ft >= 0.0 and a_ft != b_ft:
			return a_ft < b_ft
		if a["progress"] == b["progress"]:
			return String(a["id"]) < String(b["id"])
		return a["progress"] > b["progress"]
	)
	var placement_entry = null
	for e in entries:
		if e["id"] == local_user_id:
			placement_entry = e
			break
	var pos_index := entries.find(placement_entry)
	var total := entries.size()
	if placement_entry == null or pos_index == -1:
		ui_position.text = "--/--"
	else:
		ui_position.text = "%d/%d" % [pos_index + 1, total]

func _handle_reset(data:Dictionary) -> void:
	var target: String = data.get("player_id", "")
	if target != local_user_id:
		return
	var pos: Array = data.get("position", [0,0,0])
	var rot: Array = data.get("rotation", [0,0,0])
	var car: CarController = cars.get(local_user_id, null)
	if car:
		var basis := Basis().rotated(Vector3.RIGHT, rot[0]).rotated(Vector3.UP, rot[1]).rotated(Vector3.BACK, rot[2])
		apply_instant_reset(car, Transform3D(basis, Vector3(pos[0], pos[1], pos[2])))
		local_respawn_transform = car.global_transform
		has_local_respawn_transform = true

func _handle_wasted(data:Dictionary) -> void:
	var target: String = data.get("player_id", "")
	if target == local_user_id:
		get_tree().change_scene_to_file("res://scenes/Wasted.tscn")

func _handle_finish(data:Dictionary) -> void:
	ui_net.text = "Finished!"
	_show_message("Course complete!")
	finish_announced = true

func _handle_match_end(data:Dictionary) -> void:
	NakamaService.set_meta_value("race_results", data.get("results", []))
	get_tree().change_scene_to_file("res://scenes/PostRace.tscn")

func _on_checkpoint_valid(body:Node, checkpoint_index:int, transform:Transform3D) -> void:
	if body is CarController and cars.get(local_user_id, null) == body:
		# Client-side hint; authoritative validation handled server-side
		local_respawn_transform = transform
		has_local_respawn_transform = true

func _update_ui() -> void:
	var car : CarController = cars.get(local_user_id, null)
	if car:
		var speed: float = car.velocity.length()
		ui_speed.text = "%03d KM/H" % int(speed)
		if ui_speed_bar:
			ui_speed_bar.value = clampf(speed, 0.0, float(ui_speed_bar.max_value))
		var lap: int = lap_map.get(local_user_id, 1 if race_started else 0)
		ui_lap.text = "LAP %d/%d" % [lap, track_laps]
		ui_drift.text = "DRIFT T%d  %d%%" % [car.get_drift_tier(), int(round(car.get_drift_charge_ratio() * 100.0))]
	ui_item.text = "ITEM %s" % (local_item_slot if local_item_slot != "" else "--")
	ui_net.text = "LOCAL" if NakamaService.offline_mode else ("NET OK" if NakamaService.is_online_socket_ready() else "NET ...")
	_update_positions()

func _update_camera(delta:float) -> void:
	var car : CarController = cars.get(local_user_id, null)
	if not car:
		return
	var behind := -car.global_transform.basis.z * CAMERA_DISTANCE
	var look_target := car.global_transform.origin + Vector3.UP * CAMERA_LOOK_HEIGHT
	var desired := car.global_transform.origin + behind + Vector3.UP * CAMERA_HEIGHT
	var resolved := _resolve_camera_occlusion(look_target, desired)
	var follow_speed := CAMERA_OCCLUDED_FOLLOW_SPEED if resolved.distance_squared_to(desired) > 0.01 else CAMERA_FOLLOW_SPEED
	var shake_intensity := appliance_rumble_target_intensity(
		car.global_transform.origin,
		appliance_rumble_positions,
		APPLIANCE_RUMBLE_RADIUS,
		APPLIANCE_RUMBLE_INNER_RADIUS
	)
	var shake_offset := camera_shake_offset(shake_intensity, CAMERA_SHAKE_MAX_OFFSET)
	camera.global_transform.origin = camera.global_transform.origin.lerp(resolved + shake_offset, clampf(delta * follow_speed, 0.0, 1.0))
	camera.look_at(look_target + shake_offset * 0.25, Vector3.UP)

func _resolve_camera_occlusion(look_target: Vector3, desired: Vector3) -> Vector3:
	var space_state := get_world_3d().direct_space_state
	var params := PhysicsRayQueryParameters3D.create(look_target, desired, CAMERA_OCCLUSION_MASK)
	params.collide_with_areas = false
	params.collide_with_bodies = true
	params.hit_from_inside = true
	var result := space_state.intersect_ray(params)
	if not result.has("position"):
		return desired
	return camera_position_before_occluder(
		look_target,
		desired,
		result.position,
		CAMERA_OCCLUSION_CLEARANCE,
		CAMERA_OCCLUSION_MIN_DISTANCE
	)

static func camera_position_before_occluder(look_target: Vector3, desired: Vector3, hit_position: Vector3, clearance: float, min_distance: float) -> Vector3:
	var desired_offset := desired - look_target
	var desired_distance := desired_offset.length()
	if desired_distance <= 0.001:
		return desired
	var direction := desired_offset / desired_distance
	var hit_distance := look_target.distance_to(hit_position)
	var safe_distance := maxf(hit_distance - clearance, 0.2)
	if hit_distance > min_distance + clearance:
		safe_distance = maxf(safe_distance, min_distance)
	safe_distance = minf(safe_distance, desired_distance)
	return look_target + direction * safe_distance

static func camera_shake_offset(intensity: float, max_offset: float) -> Vector3:
	var amount := clampf(intensity, 0.0, 1.0) * max_offset
	if amount <= 0.0:
		return Vector3.ZERO
	var t := Time.get_ticks_msec() * 0.001
	return Vector3(
		sin(t * 41.0) * amount,
		cos(t * 53.0) * amount * 0.62,
		sin(t * 37.0 + 1.7) * amount * 0.45
	)

func _ensure_input_actions() -> void:
	_add_action_if_missing("accelerate")
	_add_action_if_missing("brake")
	_add_action_if_missing("steer_left")
	_add_action_if_missing("steer_right")
	_add_action_if_missing("drift")
	_add_action_if_missing("boost")
	_add_action_if_missing("use_item")
	_add_action_if_missing("return_to_track")
	_add_key_event("accelerate", KEY_W)
	_add_key_event("accelerate", KEY_UP)
	_add_key_event("brake", KEY_CTRL)
	_add_key_event("brake", KEY_S)
	_add_key_event("brake", KEY_DOWN)
	_add_key_event("steer_left", KEY_A)
	_add_key_event("steer_left", KEY_LEFT)
	_add_key_event("steer_right", KEY_D)
	_add_key_event("steer_right", KEY_RIGHT)
	_add_key_event("drift", KEY_SPACE)
	_add_key_event("boost", KEY_SHIFT)
	_add_key_event("use_item", KEY_E)
	_add_key_event("return_to_track", KEY_R)

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
	_layout_mobile_hud()
	if not get_viewport().size_changed.is_connected(_layout_mobile_hud):
		get_viewport().size_changed.connect(_layout_mobile_hud)
	_connect_button(accel_btn, "accelerate")
	_connect_button(brake_btn, "brake")
	_connect_button(drift_btn, "drift")
	_connect_button(boost_btn, "boost")
	_connect_button(item_btn, "use_item")
	_connect_button(return_btn, "return_to_track")
	steer_joystick_area.gui_input.connect(_on_steer_joystick_input)
	_reset_steer_joystick.call_deferred()

func _layout_mobile_hud() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var viewport_scale := minf(viewport_size.x / MOBILE_BASE_VIEWPORT.x, viewport_size.y / MOBILE_BASE_VIEWPORT.y)
	var touch_scale := maxf(viewport_scale * MOBILE_TOUCH_SCALE, 1.0)
	var info_scale := clampf(viewport_scale * 1.35, 1.0, 1.35)
	var margin := MOBILE_SAFE_MARGIN * viewport_scale
	var bottom_margin := maxf(42.0 * viewport_scale, 24.0)

	_set_control_rect(top_left_panel, Vector2(margin, margin), Vector2(254.0, 196.0) * info_scale)
	_set_center_top_rect(lap_pill, Vector2(236.0, 52.0) * info_scale, margin)
	_set_control_rect(top_right_panel, Vector2(viewport_size.x - margin - 270.0 * info_scale, margin), Vector2(270.0, 196.0) * info_scale)
	_set_center_bottom_rect(speed_ui, Vector2(376.0, 84.0) * info_scale, maxf(bottom_margin, 22.0 * touch_scale))

	var left_width := 272.0 * touch_scale
	var drift_size := Vector2(168.0, 168.0) * touch_scale
	var joystick_size := Vector2(272.0, 272.0) * touch_scale
	var knob_size := Vector2(124.0, 124.0) * touch_scale
	var left_gap := 30.0 * viewport_scale
	var left_height := drift_size.y + left_gap + joystick_size.y
	_set_bottom_left_rect(steer_joystick_area.get_parent() as Control, Vector2(margin, bottom_margin), Vector2(left_width, left_height))
	_set_control_rect(drift_btn, Vector2((left_width - drift_size.x) * 0.5, 0.0), drift_size)
	_set_control_rect(steer_joystick_area, Vector2(0.0, drift_size.y + left_gap), joystick_size)
	_set_control_rect(steer_joystick_area.get_node("SteerJoystickBase") as Control, Vector2.ZERO, joystick_size)
	_set_control_rect(steer_joystick_knob, (joystick_size - knob_size) * 0.5, knob_size)

	var accel_size := Vector2(224.0, 224.0) * touch_scale
	var brake_size := Vector2(170.0, 170.0) * touch_scale
	var boost_size := Vector2(172.0, 172.0) * touch_scale
	var item_size := Vector2(146.0, 146.0) * touch_scale
	var return_size := Vector2(132.0, 132.0) * touch_scale
	var right_gap := 24.0 * viewport_scale
	var right_width := accel_size.x + brake_size.x + right_gap
	var right_height := accel_size.y + boost_size.y + right_gap
	_set_bottom_right_rect(accel_btn.get_parent() as Control, Vector2(margin, bottom_margin), Vector2(right_width, right_height))
	_set_control_rect(boost_btn, Vector2(right_width - boost_size.x, 0.0), boost_size)
	_set_control_rect(accel_btn, Vector2(right_width - accel_size.x, right_height - accel_size.y), accel_size)
	_set_control_rect(brake_btn, Vector2(0.0, right_height - brake_size.y), brake_size)
	_set_control_rect(item_btn, Vector2(0.0, maxf(0.0, boost_size.y * 0.36)), item_size)
	_set_control_rect(return_btn, Vector2(item_size.x + right_gap, maxf(0.0, boost_size.y * 0.44)), return_size)
	_reset_steer_joystick()

func _set_control_rect(control: Control, position: Vector2, rect_size: Vector2) -> void:
	if control == null:
		return
	control.custom_minimum_size = rect_size
	control.position = position
	control.size = rect_size
	control.pivot_offset = rect_size * 0.5

func _set_bottom_left_rect(control: Control, inset: Vector2, rect_size: Vector2) -> void:
	if control == null:
		return
	control.anchor_left = 0.0
	control.anchor_top = 1.0
	control.anchor_right = 0.0
	control.anchor_bottom = 1.0
	control.offset_left = inset.x
	control.offset_top = -inset.y - rect_size.y
	control.offset_right = inset.x + rect_size.x
	control.offset_bottom = -inset.y
	control.pivot_offset = rect_size * 0.5

func _set_bottom_right_rect(control: Control, inset: Vector2, rect_size: Vector2) -> void:
	if control == null:
		return
	control.anchor_left = 1.0
	control.anchor_top = 1.0
	control.anchor_right = 1.0
	control.anchor_bottom = 1.0
	control.offset_left = -inset.x - rect_size.x
	control.offset_top = -inset.y - rect_size.y
	control.offset_right = -inset.x
	control.offset_bottom = -inset.y
	control.pivot_offset = rect_size * 0.5

func _set_center_top_rect(control: Control, rect_size: Vector2, top: float) -> void:
	if control == null:
		return
	control.anchor_left = 0.5
	control.anchor_top = 0.0
	control.anchor_right = 0.5
	control.anchor_bottom = 0.0
	control.offset_left = -rect_size.x * 0.5
	control.offset_top = top
	control.offset_right = rect_size.x * 0.5
	control.offset_bottom = top + rect_size.y
	control.pivot_offset = rect_size * 0.5

func _set_center_bottom_rect(control: Control, rect_size: Vector2, bottom: float) -> void:
	if control == null:
		return
	control.anchor_left = 0.5
	control.anchor_top = 1.0
	control.anchor_right = 0.5
	control.anchor_bottom = 1.0
	control.offset_left = -rect_size.x * 0.5
	control.offset_top = -bottom - rect_size.y
	control.offset_right = rect_size.x * 0.5
	control.offset_bottom = -bottom
	control.pivot_offset = rect_size * 0.5

func _connect_button(btn:Button, action:String) -> void:
	if btn == null:
		return
	btn.pivot_offset = btn.size * 0.5
	btn.resized.connect(func(): btn.pivot_offset = btn.size * 0.5)
	btn.gui_input.connect(func(event: InputEvent): _handle_mobile_button_input(event, btn, action))

func _handle_mobile_button_input(event: InputEvent, btn: Button, action: String) -> void:
	var touch_id := -999
	var pressed := false
	var released := false
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		touch_id = touch.index
		pressed = touch.pressed
		released = not touch.pressed
	elif event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		touch_id = -1
		pressed = (event as InputEventMouseButton).pressed
		released = not (event as InputEventMouseButton).pressed
	else:
		return
	var touches: Array = mobile_action_touches.get(action, [])
	if pressed and not touches.has(touch_id):
		touches.append(touch_id)
	elif released:
		touches.erase(touch_id)
	mobile_action_touches[action] = touches
	_set_mobile_button_state(btn, action, not touches.is_empty())
	btn.accept_event()

func _release_mobile_touch(touch_id: int) -> void:
	if touch_id == mobile_steer_touch_id:
		mobile_steer_touch_id = -1
		_reset_steer_joystick()
	for action in mobile_action_touches.keys():
		var action_name := str(action)
		var touches: Array = mobile_action_touches.get(action_name, [])
		if not touches.has(touch_id):
			continue
		touches.erase(touch_id)
		mobile_action_touches[action_name] = touches
		_set_mobile_button_state(_button_for_mobile_action(action_name), action_name, not touches.is_empty())

func _set_mobile_button_state(btn: Button, action: String, active: bool) -> void:
	if active:
		if btn != null:
			btn.scale = Vector2(1.06, 1.06)
		Input.action_press(action)
	else:
		if btn != null:
			btn.scale = Vector2.ONE
		Input.action_release(action)

func _button_for_mobile_action(action: String) -> Button:
	match action:
		"accelerate":
			return accel_btn
		"brake":
			return brake_btn
		"drift":
			return drift_btn
		"boost":
			return boost_btn
		"use_item":
			return item_btn
		"return_to_track":
			return return_btn
	return null

func _on_steer_joystick_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed and mobile_steer_touch_id == -1:
			mobile_steer_touch_id = touch.index
			_update_steer_joystick(touch.position)
			steer_joystick_area.accept_event()
		elif not touch.pressed and touch.index == mobile_steer_touch_id:
			mobile_steer_touch_id = -1
			_reset_steer_joystick()
			steer_joystick_area.accept_event()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == mobile_steer_touch_id:
			_update_steer_joystick(drag.position)
			steer_joystick_area.accept_event()
	elif event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		if (event as InputEventMouseButton).pressed:
			mobile_steer_touch_id = -2
			_update_steer_joystick((event as InputEventMouseButton).position)
		else:
			mobile_steer_touch_id = -1
			_reset_steer_joystick()
		steer_joystick_area.accept_event()
	elif event is InputEventMouseMotion and mobile_steer_touch_id == -2:
		_update_steer_joystick((event as InputEventMouseMotion).position)
		steer_joystick_area.accept_event()

func _update_steer_joystick(local_position: Vector2) -> void:
	var center := steer_joystick_area.size * 0.5
	var radius := maxf(minf(steer_joystick_area.size.x, steer_joystick_area.size.y) * 0.38, 1.0)
	var offset := local_position - center
	if offset.length() > radius:
		offset = offset.normalized() * radius
	# Existing steering maps left to positive and right to negative.
	mobile_steer_value = clampf(-offset.x / radius, -1.0, 1.0)
	steer_joystick_knob.position = center + offset - steer_joystick_knob.size * 0.5

func _reset_steer_joystick() -> void:
	mobile_steer_value = 0.0
	if steer_joystick_area == null or steer_joystick_knob == null:
		return
	steer_joystick_knob.position = steer_joystick_area.size * 0.5 - steer_joystick_knob.size * 0.5

func _get_checkpoint_total() -> int:
	if track_checkpoint_total > 0:
		return track_checkpoint_total
	if checkpoint_system:
		var total := int(checkpoint_system.checkpoint_count)
		if total > 0:
			return total
	return max(checkpoint_points.size(), 1)

func _compute_progress(lap: int, checkpoint: int, pos: Vector3, checkpoint_total: int, finished: bool, server_progress: float = -1.0) -> float:
	if server_progress >= 0.0:
		return server_progress
	var clamped_total : int = max(checkpoint_total, 1)
	var laps_done : int = max(lap, 0) - 1
	var base := float(laps_done * clamped_total + clamp(checkpoint, 0, clamped_total))
	if track_waypoints.size() >= 2:
		var projection := TrackProgressRules.project_route_network(
			_typed_waypoints(),
			track_alternate_routes,
			track_checkpoint_indices,
			pos,
			track_closed_loop
		)
		base += clampf(float(projection.get("route_ratio", 0.0)), 0.0, 0.999)
		if finished:
			base += clamped_total * 2
		return base
	var next_idx : int = clamp(checkpoint % clamped_total, 0, clamped_total - 1)
	if checkpoint_points.size() > next_idx:
		var next_pos: Vector3 = checkpoint_points[next_idx]
		var dist := pos.distance_to(next_pos)
		# Closer to the next checkpoint increases progress slightly for tie-breaking.
		base += max(0.0, 1000.0 - dist) * 0.0001
	elif track_waypoints.size() > next_idx:
		var next_pos: Vector3 = track_waypoints[next_idx]
		var dist := pos.distance_to(next_pos)
		base += max(0.0, 1000.0 - dist) * 0.0001
	if finished:
		base += clamped_total * 2
	return base

func _cache_checkpoint_points() -> void:
	checkpoint_points.clear()
	if checkpoint_system == null:
		return
	var list: Array = []
	for child in checkpoint_system.get_children():
		if child is CheckpointArea:
			list.append({"idx": child.checkpoint_index, "pos": child.global_transform.origin})
	list.sort_custom(func(a, b): return a["idx"] < b["idx"])
	for item in list:
		checkpoint_points.append(item["pos"])

func _show_message(text: String) -> void:
	if ui_message == null:
		return
	ui_message.text = text
	message_timer = MESSAGE_DURATION

func _apply_track_reset_metadata(metadata: Variant) -> void:
	if not (metadata is Dictionary):
		return
	var data := metadata as Dictionary
	track_out_of_bounds_y = float(data.get("out_of_bounds_y", track_out_of_bounds_y))
	track_reset_mode = str(data.get("reset_mode", track_reset_mode))
	track_road_width = float(data.get("road_width", track_road_width))
	track_closed_loop = bool(data.get("closed_loop", track_closed_loop))
	track_alternate_routes = _alternate_routes_from_metadata(data.get("alternate_routes", []))
	track_checkpoint_indices = _checkpoint_indices_from_metadata(data.get("checkpoints", []))
	track_audio_ids = data.get("audio_ids", {}) if data.get("audio_ids", {}) is Dictionary else {}
	track_audio_zones = data.get("audio_zones", []) if data.get("audio_zones", []) is Array else []
	_start_track_music()
	_prepare_audio_zone_players()

func _update_local_track_return_point() -> void:
	var car: CarController = cars.get(local_user_id, null)
	if car == null or track_waypoints.size() < 2:
		return
	var projection := TrackProgressRules.project_route_network(
		_typed_waypoints(),
		track_alternate_routes,
		track_checkpoint_indices,
		car.global_transform.origin,
		track_closed_loop
	)
	var closest_point: Vector3 = projection.get("closest_point", car.global_transform.origin)
	var off_course := car.global_transform.origin.distance_to(closest_point) > track_road_width * 0.5 + 0.75
	if not off_course:
		last_on_track_center_transform = centered_track_return_transform(
			_typed_waypoints(),
			car.global_transform.origin,
			track_closed_loop,
			track_alternate_routes,
			track_checkpoint_indices
		)
		has_last_on_track_center_transform = true
	local_car_off_course = off_course

func _update_heat_distortion(delta: float) -> void:
	if heat_distortion == null:
		return
	var car: CarController = cars.get(local_user_id, null)
	var target := 0.0
	if car != null:
		target = heat_distortion_target_intensity(
			car.global_transform.origin,
			heat_source_positions,
			HEAT_DISTORTION_RADIUS,
			HEAT_DISTORTION_INNER_RADIUS
		)
	heat_distortion_intensity = move_toward(heat_distortion_intensity, target, delta * HEAT_DISTORTION_FADE_SPEED)
	heat_distortion.visible = heat_distortion_intensity > 0.01
	if heat_distortion.material is ShaderMaterial:
		(heat_distortion.material as ShaderMaterial).set_shader_parameter("intensity", heat_distortion_intensity)

func _update_water_drops(delta: float) -> void:
	if water_drops == null:
		return
	var car: CarController = cars.get(local_user_id, null)
	var target := 0.0
	if car != null:
		target = sink_water_drop_target_intensity(car.global_transform.origin, sink_water_zones)
	var speed := SINK_WATER_DROPS_FADE_IN_SPEED if target > water_drop_intensity else SINK_WATER_DROPS_DRY_SPEED
	water_drop_intensity = move_toward(water_drop_intensity, target, delta * speed)
	water_drops.visible = water_drop_intensity > 0.01
	if water_drops.material is ShaderMaterial:
		(water_drops.material as ShaderMaterial).set_shader_parameter("intensity", water_drop_intensity)

func _start_track_music() -> void:
	if music_player == null:
		return
	var music_path := str(track_audio_ids.get("music", ""))
	if music_path.is_empty():
		return
	var stream := load(music_path) as AudioStream
	if stream == null:
		return
	_enable_audio_loop(stream)
	music_player.stream = stream
	music_player.play()

func _prepare_audio_zone_players() -> void:
	for player in audio_zone_players.values():
		if player is AudioStreamPlayer:
			(player as AudioStreamPlayer).queue_free()
	audio_zone_players.clear()
	audio_zone_active.clear()
	for zone_value in track_audio_zones:
		if not (zone_value is Dictionary):
			continue
		var zone := zone_value as Dictionary
		var zone_id := str(zone.get("id", ""))
		var stream := _stream_for_audio_zone(zone)
		if zone_id.is_empty() or stream == null:
			continue
		_enable_audio_loop(stream)
		var player := AudioStreamPlayer.new()
		player.name = "%sAudio" % zone_id
		player.bus = "SFX"
		player.stream = stream
		player.volume_db = float(zone.get("volume_db", 0.0))
		add_child(player)
		audio_zone_players[zone_id] = player
		audio_zone_active[zone_id] = false

func _stream_for_audio_zone(zone: Dictionary) -> AudioStream:
	var audio_path := str(zone.get("audio_path", "")).strip_edges()
	if audio_path.is_empty():
		var audio_id := str(zone.get("audio_id", "")).strip_edges()
		audio_path = str(track_audio_ids.get(audio_id, ""))
	if audio_path.is_empty():
		return null
	return load(audio_path) as AudioStream

func _update_audio_zone_players() -> void:
	var car: CarController = cars.get(local_user_id, null)
	for zone_value in track_audio_zones:
		if not (zone_value is Dictionary):
			continue
		var zone := zone_value as Dictionary
		var zone_id := str(zone.get("id", ""))
		var player := audio_zone_players.get(zone_id, null) as AudioStreamPlayer
		if player == null:
			continue
		var active := false
		if car != null:
			var zone_position := _vector3_from_metadata(zone.get("position", []), Vector3.ZERO)
			var radius := maxf(float(zone.get("radius", 0.0)), 0.1)
			active = Vector2(car.global_transform.origin.x, car.global_transform.origin.z).distance_to(Vector2(zone_position.x, zone_position.z)) <= radius
		var was_active := bool(audio_zone_active.get(zone_id, false))
		audio_zone_active[zone_id] = active
		if active:
			if not player.playing:
				player.play()
		elif was_active and player.playing:
			player.stop()

func _update_game_sounds() -> void:
	var boost_pressed := Input.is_action_pressed("boost")
	if boost_pressed and not previous_boost_pressed:
		_play_game_sfx(sfx_boost, -2.0, randf_range(0.96, 1.04))
	previous_boost_pressed = boost_pressed
	var drift_pressed := Input.is_action_pressed("drift")
	if previous_drift_pressed and not drift_pressed:
		_play_game_sfx(sfx_drift, -4.0, randf_range(0.98, 1.06))
	previous_drift_pressed = drift_pressed

func _play_game_sfx(stream: AudioStream, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	if stream == null:
		return
	if has_node("/root/AudioManager"):
		var manager := get_node("/root/AudioManager")
		if manager != null and manager.has_method("play_sfx"):
			manager.call("play_sfx", stream, volume_db, pitch)

func _enable_audio_loop(stream: AudioStream) -> void:
	if stream == null:
		return
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	elif stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true

static func _vector3_from_metadata(value: Variant, fallback: Vector3) -> Vector3:
	if value is Vector3:
		return value
	if value is Array and (value as Array).size() >= 3:
		return Vector3(float(value[0]), float(value[1]), float(value[2]))
	return fallback

static func heat_distortion_target_intensity(position: Vector3, heat_sources: Array[Vector3], radius: float, inner_radius: float) -> float:
	return proximity_target_intensity(position, heat_sources, radius, inner_radius)

static func appliance_rumble_target_intensity(position: Vector3, appliances: Array[Vector3], radius: float, inner_radius: float) -> float:
	return proximity_target_intensity(position, appliances, radius, inner_radius)

static func sink_water_drop_target_intensity(position: Vector3, sink_zones: Array[Dictionary]) -> float:
	var strongest := 0.0
	var point_2d := Vector2(position.x, position.z)
	for zone in sink_zones:
		var zone_position: Vector3 = zone.get("position", Vector3.ZERO)
		var radius := maxf(float(zone.get("radius", 0.0)), 0.1)
		var inner_radius := radius * 0.35
		var distance := point_2d.distance_to(Vector2(zone_position.x, zone_position.z))
		var intensity := 1.0
		if distance > inner_radius:
			intensity = 1.0 - clampf((distance - inner_radius) / maxf(radius - inner_radius, 0.001), 0.0, 1.0)
		strongest = maxf(strongest, intensity)
	return strongest

static func proximity_target_intensity(position: Vector3, sources: Array[Vector3], radius: float, inner_radius: float) -> float:
	if sources.is_empty() or radius <= 0.0:
		return 0.0
	var inner := clampf(inner_radius, 0.0, radius)
	var strongest := 0.0
	var point_2d := Vector2(position.x, position.z)
	for source in sources:
		var distance := point_2d.distance_to(Vector2(source.x, source.z))
		var intensity := 1.0
		if distance > inner:
			intensity = 1.0 - clampf((distance - inner) / maxf(radius - inner, 0.001), 0.0, 1.0)
		strongest = maxf(strongest, intensity)
	return strongest

func _handle_manual_return_to_track() -> void:
	if not Input.is_action_just_pressed("return_to_track"):
		return
	var car: CarController = cars.get(local_user_id, null)
	if car == null or not has_last_on_track_center_transform:
		return
	if not local_car_off_course:
		_show_message("Still on the road")
		return
	apply_instant_reset(car, _snap_to_ground(last_on_track_center_transform))
	local_respawn_transform = car.global_transform
	has_local_respawn_transform = true
	local_car_off_course = false
	_show_message("Returned to track")

func _handle_local_out_of_bounds() -> void:
	var car: CarController = cars.get(local_user_id, null)
	if car == null:
		return
	if not OutOfBoundsRules.should_reset(car.global_transform.origin.y, track_out_of_bounds_y, track_reset_mode):
		return
	var reset_transform := local_respawn_transform if has_local_respawn_transform else Transform3D.IDENTITY
	apply_instant_reset(car, _snap_to_ground(reset_transform))
	_show_message("Dropped! Back on the counter")

static func apply_instant_reset(car: CharacterBody3D, reset_transform: Transform3D) -> void:
	if car == null:
		return
	car.global_transform = reset_transform
	car.velocity = Vector3.ZERO
	if car.has_method("apply_network_state"):
		car.call("apply_network_state", reset_transform.origin, reset_transform.basis)

static func centered_track_return_transform(
	route_points: Array[Vector3],
	position: Vector3,
	closed_loop: bool = true,
	alternate_routes: Array[Dictionary] = [],
	checkpoint_indices: Array[int] = []
) -> Transform3D:
	var projection := TrackProgressRules.project_route_network(route_points, alternate_routes, checkpoint_indices, position, closed_loop)
	var segment_index := int(projection.get("segment_index", 0))
	var closest_point: Vector3 = projection.get("closest_point", position)
	var forward := Vector3.FORWARD
	var projected_points := route_points
	var projected_closed_loop := closed_loop
	if bool(projection.get("is_alternate", false)):
		projected_points = _alternate_route_points(alternate_routes, str(projection.get("route_id", "")))
		projected_closed_loop = false
	if projected_points.size() >= 2:
		var next_index := (segment_index + 1) % projected_points.size()
		if not projected_closed_loop:
			next_index = mini(segment_index + 1, projected_points.size() - 1)
		forward = projected_points[next_index] - projected_points[clamp(segment_index, 0, projected_points.size() - 1)]
		forward.y = 0.0
		if forward.length_squared() <= 0.001:
			forward = Vector3.FORWARD
		forward = forward.normalized()
	var yaw := atan2(forward.x, forward.z)
	return Transform3D(Basis(Vector3.UP, yaw), closest_point + Vector3.UP * 1.0)

static func _alternate_route_points(routes: Array[Dictionary], route_id: String) -> Array[Vector3]:
	for route in routes:
		if str(route.get("id", "")) == route_id:
			return _vector3_array_from_value(route.get("points", []))
	return []

func _typed_waypoints() -> Array[Vector3]:
	var points: Array[Vector3] = []
	for point in track_waypoints:
		if point is Vector3:
			points.append(point)
	return points

func _alternate_routes_from_metadata(value: Variant) -> Array[Dictionary]:
	var routes: Array[Dictionary] = []
	if not (value is Array):
		return routes
	for route in value:
		if not (route is Dictionary):
			continue
		var data := route as Dictionary
		routes.append({
			"id": str(data.get("id", "")),
			"points": _vector3_array_from_value(data.get("points", [])),
			"entry_checkpoint_index": int(data.get("entry_checkpoint_index", 0)),
			"exit_checkpoint_index": int(data.get("exit_checkpoint_index", 0)),
			"road_width": float(data.get("road_width", track_road_width)),
			"enabled": bool(data.get("enabled", true)),
		})
	return routes

func _checkpoint_indices_from_metadata(value: Variant) -> Array[int]:
	var indices: Array[int] = []
	if not (value is Array):
		return indices
	for item in value:
		if item is Dictionary:
			indices.append(int((item as Dictionary).get("route_index", indices.size())))
	return indices

static func _vector3_array_from_value(value: Variant) -> Array[Vector3]:
	var points: Array[Vector3] = []
	if not (value is Array):
		return points
	for item in value:
		if item is Vector3:
			points.append(item)
		elif item is Array and item.size() >= 3:
			points.append(Vector3(float(item[0]), float(item[1]), float(item[2])))
		elif item is Dictionary:
			points.append(Vector3(float(item.get("x", 0.0)), float(item.get("y", 0.0)), float(item.get("z", 0.0))))
	return points

func _tick_message(delta: float) -> void:
	if ui_message == null:
		return
	if message_timer <= 0.0:
		return
	message_timer -= delta
	if message_timer <= 0.0:
		ui_message.text = ""

func _tick_local_item_slot(delta: float) -> void:
	item_roll_timer = max(item_roll_timer - delta, 0.0)
	if local_item_slot != "" or item_roll_timer > 0.0:
		return
	var total_racers : int = max(racer_states.size(), 1)
	var position : Variant = _local_position()
	local_item_slot = ItemRules.roll_for_position(position, total_racers, item_rng)
	_play_game_sfx(sfx_item_pickup, -3.0, randf_range(0.96, 1.08))
	item_roll_timer = 2.0

func _local_position() -> int:
	if ui_position == null:
		return 1
	var car_count : int = max(racer_states.size(), 1)
	var entries: Array = []
	for rid in racer_states.keys():
		var info: Dictionary = racer_states[rid]
		entries.append({
			"id": rid,
			"finished": bool(info.get("finished", false)),
			"wasted": bool(info.get("wasted", false)),
			"progress": _compute_progress(
				int(info.get("lap", 0)),
				int(info.get("checkpoint", 0)),
				info.get("pos", Vector3.ZERO),
				_get_checkpoint_total(),
				bool(info.get("finished", false)),
				float(info.get("progress", -1.0))
			),
			"finish_time": float(info.get("finish_time", -1.0)),
		})
	entries.sort_custom(func(a, b):
		if a["finished"] != b["finished"]:
			return a["finished"] and not b["finished"]
		if a["wasted"] != b["wasted"]:
			return (not a["wasted"]) and b["wasted"]
		if a["progress"] == b["progress"]:
			return String(a["id"]) < String(b["id"])
		return a["progress"] > b["progress"]
	)
	for i in range(entries.size()):
		if String(entries[i]["id"]) == local_user_id:
			return i + 1
	return min(1, car_count)

func _consume_local_item(car: CarController) -> void:
	if local_item_slot == "":
		return
	match local_item_slot:
		ItemRules.ITEM_BOOST:
			car.trigger_item_boost(0.9, 85.0)
			_show_message("Boost item: ram through traffic")
		ItemRules.ITEM_INVINCIBILITY:
			car.trigger_item_boost(1.4, 118.0)
			_show_message("Invincibility prototype: revenge mode")
		ItemRules.ITEM_SIGNATURE:
			car.trigger_item_boost(1.1, 98.0)
			_show_message("Signature prototype: %s" % local_user_id)
		ItemRules.ITEM_JACKS:
			_show_message("Jacks prototype armed")
		ItemRules.ITEM_MARBLE:
			_show_message("Marble prototype fired")
		ItemRules.ITEM_BUBBLE:
			_show_message("Bubble prototype raised")
	local_item_slot = ""
	item_roll_timer = 1.5
