extends RefCounted
class_name TrackSourceRules

const TrackProgressRules = preload("res://scripts/track/TrackProgressRules.gd")

const PROGRESS_ROUTE_LAP := "route_lap_progress"
const WIN_CHECKPOINT_LAPS := "checkpoint_laps"

static func canonical_progress_rule(value: String) -> String:
	var normalized := value.strip_edges().to_lower()
	return PROGRESS_ROUTE_LAP if normalized.is_empty() else normalized

static func canonical_win_condition(value: String) -> String:
	var normalized := value.strip_edges().to_lower()
	return WIN_CHECKPOINT_LAPS if normalized.is_empty() else normalized

static func apply_checkpoint_pass(
	win_condition_id: String,
	current_checkpoint: int,
	lap: int,
	lap_gate_passed: bool,
	passed_checkpoint: int,
	checkpoint_count: int,
	lap_gate_checkpoint_index: int,
	total_laps: int
) -> Dictionary:
	match canonical_win_condition(win_condition_id):
		WIN_CHECKPOINT_LAPS:
			return TrackProgressRules.apply_checkpoint_pass(
				current_checkpoint,
				lap,
				lap_gate_passed,
				passed_checkpoint,
				checkpoint_count,
				lap_gate_checkpoint_index,
				total_laps
			)
		_:
			return TrackProgressRules.apply_checkpoint_pass(
				current_checkpoint,
				lap,
				lap_gate_passed,
				passed_checkpoint,
				checkpoint_count,
				lap_gate_checkpoint_index,
				total_laps
			)

static func finished_progress_bonus(progress_rule_id: String, checkpoint_total: int) -> float:
	match canonical_progress_rule(progress_rule_id):
		PROGRESS_ROUTE_LAP:
			return float(max(checkpoint_total, 1) * 2)
		_:
			return float(max(checkpoint_total, 1) * 2)
