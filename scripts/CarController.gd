extends CharacterBody3D
class_name CarController

@export var acceleration := 28.0
@export var brake_force := 32.0
@export var max_speed := 42.0
@export var steer_speed := 2.8
@export var drift_grip := 0.35
@export var boost_force := 70.0
@export var boost_meter_max := 100.0
@export var boost_gain_drift := 18.0
@export var boost_drain := 28.0
@export var correction_speed := 6.0
@export var auto_accelerate := false
@export var coast_drag := 12.0
@export var brake_drag := 18.0

var boost_meter := 0.0
var input_state := {"throttle": 0.0, "brake": 0.0, "steer": 0.0, "drift": false, "boost": false}
var controlled_locally := false
var target_basis : Basis
var target_position : Vector3
var gravity : float = ProjectSettings.get_setting("physics/3d/default_gravity") as float

func _ready() -> void:
	target_basis = global_transform.basis
	target_position = global_transform.origin
	velocity = Vector3.ZERO

func _physics_process(delta: float) -> void:
	if controlled_locally:
		_apply_input(delta)
	else:
		_apply_remote_correction(delta)
	move_and_slide()

func set_input(state:Dictionary) -> void:
	input_state = state

func _apply_input(delta: float) -> void:
	var forward := global_transform.basis.z
	var lateral := global_transform.basis.x
	var vertical_vel := velocity.y
	var horiz_vel := velocity
	horiz_vel.y = 0
	var throttle_input : float = 1.0 if auto_accelerate else input_state.get("throttle", 0.0)
	var brake_input : float = input_state.get("brake", 0.0)
	var accel := 0.0
	if throttle_input > 0.1:
		accel += acceleration * throttle_input
	if brake_input > 0.1:
		accel -= brake_force * brake_input
	var drifting : bool = input_state.get("drift", false)
	if drifting:
		boost_meter = min(boost_meter_max, boost_meter + boost_gain_drift * delta)
	if input_state.get("boost", false) and boost_meter > 1.0:
		boost_meter = max(0.0, boost_meter - boost_drain * delta)
		accel += boost_force
	var steering_input : float = input_state.get("steer", 0.0)
	var steer_amount : float = steering_input * steer_speed * delta
	if drifting:
		steer_amount *= 1.5
	horiz_vel += forward * accel * delta
	var grip := drift_grip if drifting else 1.0
	var lateral_speed := horiz_vel.dot(lateral)
	horiz_vel -= lateral * lateral_speed * (1.0 - grip)
	horiz_vel = horiz_vel.limit_length(max_speed + (boost_force * 0.5 if input_state.get("boost", false) else 0.0))
	# natural drag and braking drag
	var drag_force := coast_drag
	if brake_input > 0.1:
		drag_force += brake_drag * brake_input
	horiz_vel = horiz_vel.move_toward(Vector3.ZERO, drag_force * delta)
	velocity = horiz_vel
	velocity.y = vertical_vel
	if is_on_floor():
		velocity.y = 0
	else:
		velocity.y -= gravity * delta
	rotate_y(steer_amount)

func _apply_remote_correction(delta:float) -> void:
	global_transform.origin = global_transform.origin.lerp(target_position, delta * correction_speed)
	var current_quat := global_transform.basis.get_rotation_quaternion()
	var target_quat := target_basis.get_rotation_quaternion()
	var blended := current_quat.slerp(target_quat, clamp(delta * correction_speed, 0.0, 1.0))
	global_transform.basis = Basis(blended)
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0

func apply_network_state(position:Vector3, basis:Basis) -> void:
	target_position = position
	target_basis = basis

func capture_state() -> Dictionary:
	return {
		"position": global_transform.origin,
		"basis": global_transform.basis,
		"boost": boost_meter
	}
