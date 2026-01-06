extends Node3D

const TrackBuilder = preload("res://scripts/TrackBuilder.gd")

@onready var camera: Camera3D = $Camera3D

var car: CarController
var spawn_points: Array = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_input_actions()
	_spawn_track()
	_spawn_car()
	camera.fov = 60.0
	camera.current = true

func _physics_process(delta: float) -> void:
	if car:
		car.set_input(_gather_input())
		var height := 1.6
		var distance := 4.0
		var behind := -car.global_transform.basis.z * distance
		var target := car.global_transform.origin + Vector3.UP * 1.5
		var desired := target + behind + Vector3.UP * height
		camera.global_transform.origin = camera.global_transform.origin.lerp(desired, delta * 4.0)
		camera.look_at(target, Vector3.UP)

func _spawn_track() -> void:
	spawn_points.clear()
	# Match the race scene: prefer the server-provided recipe, fallback to static track scene.
	var recipe = NakamaService.get_meta_value("track_recipe", null)
	if recipe is Dictionary:
		var built = TrackBuilder.build(recipe)
		var track_instance: Node = built.get("node", null)
		if track_instance:
			add_child(track_instance)
		spawn_points = built.get("spawns", [])
	else:
		var track_scene = load(Config.TRACK_SCENE)
		if track_scene:
			var track_instance = track_scene.instantiate()
			add_child(track_instance)
			var spawn_root = track_instance.get_node_or_null("SpawnPoints")
			if spawn_root:
				for child in spawn_root.get_children():
					if child is Marker3D:
						spawn_points.append(child.global_transform)

func _spawn_car() -> void:
	var car_scene = load("res://scenes/Car.tscn")
	if car_scene:
		car = car_scene.instantiate() as CarController
		add_child(car)
		car.process_mode = Node.PROCESS_MODE_ALWAYS
		car.controlled_locally = true
		var spawn_xform := Transform3D.IDENTITY
		if spawn_points.size() > 0:
			spawn_xform = spawn_points[0]
		car.global_transform = _snap_to_ground(spawn_xform)
		# Snap camera immediately behind the car to avoid one-frame lag.
		var height := 1.6
		var distance := 4.0
		var behind := -car.global_transform.basis.z * distance
		var target := car.global_transform.origin + Vector3.UP * 1.5
		var desired := target + behind + Vector3.UP * height
		camera.global_transform.origin = desired
		camera.look_at(target, Vector3.UP)

func _snap_to_ground(xform: Transform3D) -> Transform3D:
	var origin := xform.origin + Vector3(0, 6, 0)
	var target := origin + Vector3(0, -20, 0)
	var space_state = get_world_3d().direct_space_state
	var params = PhysicsRayQueryParameters3D.create(origin, target)
	var result = space_state.intersect_ray(params)
	if result.has("position"):
		xform.origin.y = result.position.y + 1.0
	return xform

func _gather_input() -> Dictionary:
	var steer := (Input.get_action_strength("steer_left") - Input.get_action_strength("steer_right"))
	var throttle := Input.get_action_strength("accelerate")
	var brake := Input.get_action_strength("brake")
	var boost := Input.is_action_pressed("boost")
	return {"steer": steer, "throttle": throttle, "brake": brake, "drift": false, "boost": boost}

func _ensure_input_actions() -> void:
	_add_action_if_missing("accelerate")
	_add_action_if_missing("brake")
	_add_action_if_missing("steer_left")
	_add_action_if_missing("steer_right")
	_add_action_if_missing("boost")
	_add_key_event("accelerate", KEY_W)
	_add_key_event("accelerate", KEY_UP)
	_add_key_event("brake", KEY_SPACE)
	_add_key_event("brake", KEY_CTRL)
	_add_key_event("brake", KEY_S)
	_add_key_event("brake", KEY_DOWN)
	_add_key_event("steer_left", KEY_A)
	_add_key_event("steer_left", KEY_LEFT)
	_add_key_event("steer_right", KEY_D)
	_add_key_event("steer_right", KEY_RIGHT)
	_add_key_event("boost", KEY_SHIFT)

func _add_action_if_missing(action:String) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)

func _add_key_event(action:String, keycode:int) -> void:
	var ev := InputEventKey.new()
	ev.keycode = keycode
	InputMap.action_add_event(action, ev)
