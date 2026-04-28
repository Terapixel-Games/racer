extends Resource
class_name TrackDefinition

const TrackProgressRules = preload("res://scripts/track/TrackProgressRules.gd")

@export var id := ""
@export var display_name := ""
@export var laps := 2
@export var road_width := 12.0
@export var wall_height := 1.6
@export var wall_thickness := 0.45
@export var closed_loop := true
@export var runtime_scene_path := ""
@export var ground_size := Vector2(160.0, 140.0)
@export var ground_color := Color(0.82, 0.86, 0.88)
@export var ground_texture_path := ""
@export var road_texture_path := ""
@export var route_points: Array[Vector3] = []
@export var checkpoint_indices: Array[int] = []
@export var lap_gate_checkpoint_index := 0
@export var spawn_points: Array[Vector4] = []
@export var item_sockets: Array[Vector4] = []
@export var hazard_sockets: Array[Vector4] = []
@export var shortcut_gates: Array[Dictionary] = []
@export var audio_ids: Dictionary = {}

func validate() -> Array[String]:
	var errors: Array[String] = []
	if id.strip_edges().is_empty():
		errors.append("Track id is required.")
	if display_name.strip_edges().is_empty():
		errors.append("Track display name is required.")
	if laps <= 0:
		errors.append("Track laps must be greater than zero.")
	if road_width <= 0.0:
		errors.append("Track road width must be greater than zero.")
	if not closed_loop:
		errors.append("Track route must be marked as a closed loop.")
	if route_points.size() < 3:
		errors.append("Track route must include at least 3 route points.")
	if TrackProgressRules.route_length(route_points, closed_loop) <= 1.0:
		errors.append("Track route length is too short.")
	_validate_checkpoints(errors)
	if spawn_points.size() < 8:
		errors.append("Track must include at least 8 spawn points.")
	_validate_spawn_points(errors)
	if item_sockets.is_empty():
		errors.append("Track must include at least one item socket.")
	if lap_gate_checkpoint_index < 0 or lap_gate_checkpoint_index >= checkpoint_indices.size():
		errors.append("Track must include exactly one valid lap gate checkpoint index.")
	return errors

func to_metadata() -> Dictionary:
	var checkpoints: Array = []
	for i in range(checkpoint_indices.size()):
		var route_index := checkpoint_indices[i]
		var point := route_points[route_index] if route_index >= 0 and route_index < route_points.size() else Vector3.ZERO
		checkpoints.append({
			"index": i,
			"route_index": route_index,
			"position": _vec3_to_array(point),
			"is_lap_gate": i == lap_gate_checkpoint_index,
		})
	return {
		"id": id,
		"display_name": display_name,
		"laps": laps,
		"road_width": road_width,
		"wall_height": wall_height,
		"wall_thickness": wall_thickness,
		"closed_loop": closed_loop,
		"route_points": _vec3_array_to_json(route_points),
		"route_length": TrackProgressRules.route_length(route_points, closed_loop),
		"checkpoint_radius": road_width * 0.65,
		"checkpoints": checkpoints,
		"lap_gate_checkpoint_index": lap_gate_checkpoint_index,
		"spawn_points": _socket_array_to_json(spawn_points),
		"item_sockets": _socket_array_to_json(item_sockets),
		"hazard_sockets": _socket_array_to_json(hazard_sockets),
		"shortcut_gates": shortcut_gates,
		"audio_ids": audio_ids,
		"runtime_scene_path": runtime_scene_path,
	}

func _validate_checkpoints(errors: Array[String]) -> void:
	if checkpoint_indices.size() < 3:
		errors.append("Track must include at least 3 checkpoints.")
		return
	var previous := -1
	for i in range(checkpoint_indices.size()):
		var route_index := checkpoint_indices[i]
		if route_index < 0 or route_index >= route_points.size():
			errors.append("Checkpoint %d route index is out of range." % i)
		if route_index <= previous:
			errors.append("Checkpoint route indices must be strictly increasing.")
		previous = route_index

func _validate_spawn_points(errors: Array[String]) -> void:
	if route_points.size() < 2 or road_width <= 0.0:
		return
	var max_distance := road_width * 0.5 + 0.1
	for i in range(spawn_points.size()):
		var socket := spawn_points[i]
		var distance := _distance_to_route_xz(Vector3(socket.x, 0.0, socket.z))
		if distance > max_distance:
			errors.append("Spawn point %d is outside the road bounds." % i)

func _distance_to_route_xz(point: Vector3) -> float:
	var best := INF
	var segment_count := route_points.size() if closed_loop else route_points.size() - 1
	for i in range(segment_count):
		var a := route_points[i]
		var b := route_points[(i + 1) % route_points.size()]
		best = minf(best, _distance_to_segment_xz(point, a, b))
	return best

func _distance_to_segment_xz(point: Vector3, a3: Vector3, b3: Vector3) -> float:
	var point_2d := Vector2(point.x, point.z)
	var a := Vector2(a3.x, a3.z)
	var b := Vector2(b3.x, b3.z)
	var ab := b - a
	var length_squared := ab.length_squared()
	if length_squared <= 0.0001:
		return point_2d.distance_to(a)
	var t := clampf((point_2d - a).dot(ab) / length_squared, 0.0, 1.0)
	return point_2d.distance_to(a + ab * t)

func _vec3_array_to_json(points: Array[Vector3]) -> Array:
	var out: Array = []
	for point in points:
		out.append(_vec3_to_array(point))
	return out

func _socket_array_to_json(sockets: Array[Vector4]) -> Array:
	var out: Array = []
	for socket in sockets:
		out.append({
			"position": [socket.x, socket.y, socket.z],
			"yaw_degrees": socket.w,
		})
	return out

func _vec3_to_array(point: Vector3) -> Array:
	return [point.x, point.y, point.z]
