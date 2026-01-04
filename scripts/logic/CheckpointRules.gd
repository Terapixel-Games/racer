extends Resource

class_name CheckpointRules

var total_checkpoints : int
var lap_gate_index : int
var current_index : int = 0
var lap : int = 0
var lap_gate_passed : bool = false

func _init(total:int = 1, lap_gate:int = 0, laps:int = 2) -> void:
	total_checkpoints = max(1, total)
	lap_gate_index = clamp(lap_gate, 0, total_checkpoints - 1)

func next_expected_checkpoint_index() -> int:
	return current_index

func on_checkpoint_passed(index:int) -> bool:
	if index == current_index:
		current_index = (current_index + 1) % total_checkpoints
		if index == lap_gate_index:
			lap_gate_passed = true
		return true
	return false

func on_finish_line_crossed() -> int:
	if lap_gate_passed and current_index == 0:
		lap += 1
		lap_gate_passed = false
	return lap
