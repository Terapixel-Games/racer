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

static func sample_route_at_distance(route_points: Array[Vector3], distance: float, closed_loop: bool = true) -> Dictionary:
	var points := _sanitize_route(route_points)
	if points.size() < 2:
		return {
			"position": Vector3.ZERO,
			"tangent": Vector3.FORWARD,
			"segment_index": 0,
			"route_ratio": 0.0,
		}
	var total := route_length(points, closed_loop)
	if total <= 0.001:
		return {
			"position": points[0],
			"tangent": Vector3.FORWARD,
			"segment_index": 0,
			"route_ratio": 0.0,
		}
	var target_distance := fposmod(distance, total) if closed_loop else clampf(distance, 0.0, total)
	var accumulated := 0.0
	var segment_count: int = points.size() if closed_loop and points.size() > 2 else points.size() - 1
	for i in range(segment_count):
		var a: Vector3 = points[i]
		var b: Vector3 = points[(i + 1) % points.size()]
		var segment := b - a
		var segment_length := segment.length()
		if segment_length <= 0.001:
			continue
		if accumulated + segment_length >= target_distance or i == segment_count - 1:
			var ratio := clampf((target_distance - accumulated) / segment_length, 0.0, 1.0)
			return {
				"position": a.lerp(b, ratio),
				"tangent": segment / segment_length,
				"segment_index": i,
				"route_ratio": target_distance / total,
			}
		accumulated += segment_length
	var fallback_tangent := points[points.size() - 1] - points[points.size() - 2]
	if fallback_tangent.length_squared() <= 0.001:
		fallback_tangent = Vector3.FORWARD
	return {
		"position": points[points.size() - 1],
		"tangent": fallback_tangent.normalized(),
		"segment_index": max(points.size() - 2, 0),
		"route_ratio": 1.0,
	}

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

static func project_route_network(
	route_points: Array[Vector3],
	alternate_routes: Array[Dictionary],
	checkpoint_indices: Array[int],
	position: Vector3,
	closed_loop: bool = true
) -> Dictionary:
	var canonical := project_position(route_points, position, closed_loop)
	canonical["route_id"] = "main"
	canonical["is_alternate"] = false
	if route_points.size() < 2:
		return canonical
	var best := canonical
	var best_distance_sq := (canonical.get("closest_point", Vector3.ZERO) as Vector3).distance_squared_to(position)
	var route_total: float = maxf(route_length(route_points, closed_loop), 0.001)
	for route in alternate_routes:
		if not bool(route.get("enabled", true)):
			continue
		var points: Array[Vector3] = _points_from_value(route.get("points", []))
		if points.size() < 2:
			continue
		var entry_checkpoint := int(route.get("entry_checkpoint_index", -1))
		var exit_checkpoint := int(route.get("exit_checkpoint_index", -1))
		if entry_checkpoint < 0 or exit_checkpoint < 0:
			continue
		if entry_checkpoint >= checkpoint_indices.size() or exit_checkpoint >= checkpoint_indices.size():
			continue
		var entry_route_index: int = checkpoint_indices[entry_checkpoint]
		var exit_route_index: int = checkpoint_indices[exit_checkpoint]
		var entry_distance: float = distance_at_route_index(route_points, entry_route_index, closed_loop)
		var exit_distance: float = distance_at_route_index(route_points, exit_route_index, closed_loop)
		if exit_distance <= entry_distance and closed_loop:
			exit_distance += route_total
		if exit_distance <= entry_distance:
			continue
		var projection: Dictionary = project_position(points, position, false)
		var closest_point := projection.get("closest_point", Vector3.ZERO) as Vector3
		var distance_sq := closest_point.distance_squared_to(position)
		if distance_sq >= best_distance_sq:
			continue
		var branch_ratio: float = clampf(float(projection.get("route_ratio", 0.0)), 0.0, 1.0)
		var mapped_distance: float = lerpf(entry_distance, exit_distance, branch_ratio)
		var normalized_distance: float = fposmod(mapped_distance, route_total)
		projection["distance"] = normalized_distance
		projection["route_ratio"] = normalized_distance / route_total
		projection["route_id"] = str(route.get("id", "alternate"))
		projection["is_alternate"] = true
		projection["entry_checkpoint_index"] = entry_checkpoint
		projection["exit_checkpoint_index"] = exit_checkpoint
		best = projection
		best_distance_sq = distance_sq
	return best

static func distance_at_route_index(route_points: Array[Vector3], route_index: int, closed_loop: bool = true) -> float:
	var points := _sanitize_route(route_points)
	if points.size() < 2:
		return 0.0
	var clamped_index := clampi(route_index, 0, points.size() - 1)
	var total := 0.0
	for i in range(clamped_index):
		total += points[i].distance_to(points[i + 1])
	return total

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

static func _points_from_value(value: Variant) -> Array[Vector3]:
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
