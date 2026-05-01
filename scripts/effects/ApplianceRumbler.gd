extends Node3D

@export var rumble_amplitude := 0.08
@export var rumble_rotation_degrees := 0.9
@export var rumble_frequency := 12.0

var _base_transform := Transform3D.IDENTITY
var _phase := 0.0

func _ready() -> void:
	_base_transform = transform
	_phase = randf() * TAU

func _process(_delta: float) -> void:
	var t := Time.get_ticks_msec() * 0.001 * rumble_frequency + _phase
	var offset := Vector3(sin(t) * rumble_amplitude, sin(t * 1.71) * rumble_amplitude * 0.35, cos(t * 1.31) * rumble_amplitude)
	var basis := _base_transform.basis.rotated(Vector3.UP, deg_to_rad(sin(t * 0.83) * rumble_rotation_degrees))
	basis = basis.rotated(Vector3.FORWARD, deg_to_rad(cos(t * 1.17) * rumble_rotation_degrees * 0.45))
	transform = Transform3D(basis, _base_transform.origin + offset)
