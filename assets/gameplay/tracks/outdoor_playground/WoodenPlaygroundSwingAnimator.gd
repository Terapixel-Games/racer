extends Node3D

@export var swing_pivot_path: NodePath = ^"SwingPivot"
@export_range(0.0, 45.0, 0.5) var amplitude_degrees := 13.0
@export_range(0.05, 2.0, 0.05) var cycles_per_second := 0.32
@export var phase_offset := 0.0

var _time := 0.0
@onready var _swing_pivot := get_node_or_null(swing_pivot_path) as Node3D

func _process(delta: float) -> void:
	if _swing_pivot == null:
		return
	_time += delta
	var phase := (_time * cycles_per_second * TAU) + phase_offset
	_swing_pivot.rotation_degrees.x = sin(phase) * amplitude_degrees
