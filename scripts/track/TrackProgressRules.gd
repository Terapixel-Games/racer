extends RefCounted
class_name TrackProgressRules

static func route_length(route_points: Array[Vector3], closed_loop: bool = true) -> float:
	var points := _sanitize_route(route_points)
	if points.size() < 2:
		return 0.0
	var total := 0.0
	for i in range(points.size() - 1):
		total += points[i].distance_to(points[i + 1])
	if closed_loop and points.size() > 2:
		total += points[points.size() - 1].distance_to(points[0])
	return total

static func project_position(route_points: Array[Vector3], position: Vector3, closed_loop: bool = true) -> Dictionary:
	var points := _sanitize_route(route_points)
	if points.size() < 2:
		return {
			"distance": 0.0,
			"segment_index": 0,
			"segment_ratio": 0.0,
			"route_ratio": 0.0,
			"closest_point": Vector3.ZERO,
		}

	var best_distance_sq: float = INF
	var best_along := 0.0
	var best_segment := 0
	var best_ratio := 0.0
	var best_point := points[0]
	var accumulated := 0.0
	var segment_count: int = points.size() if closed_loop and points.size() > 2 else points.size() - 1
	for i in range(segment_count):
		var a: Vector3 = points[i]
		var b: Vector3 = points[(i + 1) % points.size()]
		var ab: Vector3 = b - a
		var seg_len: float = ab.length()
		if seg_len <= 0.001:
			continue
		var ratio: float = clamp((position - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
		var projected: Vector3 = a + ab * ratio
		var distance_sq: float = projected.distance_squared_to(position)
		if distance_sq < best_distance_sq:
			best_distance_sq = distance_sq
			best_along = accumulated + seg_len * ratio
			best_segment = i
			best_ratio = ratio
			best_point = projected
		accumulated += seg_len

	var total: float = max(route_length(points, closed_loop), 0.001)
	return {
		"distance": best_along,
		"segment_index": best_segment,
		"segment_ratio": best_ratio,
		"route_ratio": best_along / total,
		"closest_point": best_point,
	}

static func is_checkpoint_hit(route_points: Array[Vector3], checkpoint_route_index: int, position: Vector3, radius: float) -> bool:
	if checkpoint_route_index < 0 or checkpoint_route_index >= route_points.size():
		return false
	return route_points[checkpoint_route_index].distance_to(position) <= radius

static func advance_checkpoint(current_checkpoint: int, checkpoint_count: int) -> int:
	if checkpoint_count <= 0:
		return 0
	return (current_checkpoint + 1) % checkpoint_count

static func apply_checkpoint_pass(
	current_checkpoint: int,
	lap: int,
	lap_gate_passed: bool,
	passed_checkpoint: int,
	checkpoint_count: int,
	lap_gate_checkpoint_index: int,
	total_laps: int
) -> Dictionary:
	if checkpoint_count <= 0 or passed_checkpoint != current_checkpoint:
		return {
			"accepted": false,
			"checkpoint": current_checkpoint,
			"lap": lap,
			"lap_gate_passed": lap_gate_passed,
			"finished": false,
		}
	var next_checkpoint := advance_checkpoint(current_checkpoint, checkpoint_count)
	var next_lap_gate_passed := lap_gate_passed or current_checkpoint == lap_gate_checkpoint_index
	var next_lap := lap
	if next_checkpoint == 0 and next_lap_gate_passed:
		next_lap += 1
		next_lap_gate_passed = false
	return {
		"accepted": true,
		"checkpoint": next_checkpoint,
		"lap": next_lap,
		"lap_gate_passed": next_lap_gate_passed,
		"finished": next_lap > total_laps,
	}

static func progress_value(lap: int, checkpoint_index: int, checkpoint_count: int, route_ratio: float, finished: bool = false) -> float:
	var safe_checkpoint_count: int = max(checkpoint_count, 1)
	var laps_done: int = max(lap, 1) - 1
	var value := float(laps_done * safe_checkpoint_count + clamp(checkpoint_index, 0, safe_checkpoint_count - 1))
	value += clamp(route_ratio, 0.0, 0.999)
	if finished:
		value += safe_checkpoint_count * 2.0
	return value

static func _sanitize_route(route_points: Array[Vector3]) -> Array[Vector3]:
	var out: Array[Vector3] = []
	for point in route_points:
		if point is Vector3:
			if out.is_empty() or point.distance_to(out[out.size() - 1]) > 0.01:
				out.append(point)
	return out
