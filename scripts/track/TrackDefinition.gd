extends Resource
class_name TrackDefinition

const TrackProgressRules = preload("res://scripts/track/TrackProgressRules.gd")

@export var id := ""
@export var display_name := ""
@export var version := ""
@export var laps := 2
@export var road_width := 12.0
@export var wall_height := 1.6
@export var wall_thickness := 0.45
@export var closed_loop := true
@export var out_of_bounds_y := -50.0
@export var reset_mode := ""
@export var floor_visual_y := 0.0
@export var runtime_scene_path := ""
@export_file("*.tscn") var dressing_scene_path := ""
@export var ground_size := Vector2(160.0, 140.0)
@export var ground_color := Color(0.82, 0.86, 0.88)
@export var ground_texture_path := ""
@export var road_texture_path := ""
@export var track_body_depth := 0.38
@export var track_body_color := Color(0.08, 0.08, 0.1)
@export var route_points: Array[Vector3] = []
@export var checkpoint_indices: Array[int] = []
@export var lap_gate_checkpoint_index := 0
@export var spawn_points: Array[Vector4] = []
@export var item_sockets: Array[Vector4] = []
@export var hazard_sockets: Array[Vector4] = []
@export var shortcut_gates: Array[Dictionary] = []
@export var stage_props: Array[Dictionary] = []
@export var surface_segments: Array[Dictionary] = []
@export var audio_zones: Array[Dictionary] = []
@export var dressing_overrides: Dictionary = {}
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
	if not dressing_scene_path.strip_edges().is_empty() and not ResourceLoader.exists(dressing_scene_path):
		errors.append("Track dressing scene path does not exist: %s" % dressing_scene_path)
	_validate_stage_props(errors)
	_validate_surface_segments(errors)
	_validate_audio_zones(errors)
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
		"track_id": id,
		"display_name": display_name,
		"version": version,
		"laps": laps,
		"road_width": road_width,
		"wall_height": wall_height,
		"wall_thickness": wall_thickness,
		"closed_loop": closed_loop,
		"out_of_bounds_y": out_of_bounds_y,
		"reset_mode": reset_mode,
		"floor_visual_y": floor_visual_y,
		"route_points": _vec3_array_to_json(route_points),
		"route_length": TrackProgressRules.route_length(route_points, closed_loop),
		"checkpoint_radius": road_width * 0.65,
		"checkpoints": checkpoints,
		"lap_gate_checkpoint_index": lap_gate_checkpoint_index,
		"spawn_points": _socket_array_to_json(spawn_points),
		"item_sockets": _socket_array_to_json(item_sockets),
		"hazard_sockets": _socket_array_to_json(hazard_sockets),
		"shortcut_gates": _shortcut_gates_to_json(shortcut_gates),
		"stage_props": _stage_props_to_json(stage_props),
		"surface_segments": _surface_segments_to_json(surface_segments),
		"audio_zones": _audio_zones_to_json(audio_zones),
		"audio_ids": audio_ids,
		"runtime_scene_path": runtime_scene_path,
		"dressing_scene_path": dressing_scene_path,
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

func _validate_stage_props(errors: Array[String]) -> void:
	for i in range(stage_props.size()):
		var prop := stage_props[i]
		var prop_id := str(prop.get("id", "")).strip_edges()
		var kind := str(prop.get("kind", "box"))
		if prop_id.is_empty():
			errors.append("Stage prop %d id is required." % i)
		if kind == "scene":
			var path := str(prop.get("asset_path", ""))
			if path.strip_edges().is_empty():
				errors.append("Stage prop %s scene asset path is required." % prop_id)
			elif not ResourceLoader.exists(path):
				errors.append("Stage prop %s scene asset path does not exist: %s" % [prop_id, path])
		elif kind == "box":
			var size := _vector3_from_value(prop.get("box_size", Vector3.ONE), Vector3.ONE)
			if size.x <= 0.0 or size.y <= 0.0 or size.z <= 0.0:
				errors.append("Stage prop %s box size must be positive." % prop_id)

func _validate_surface_segments(errors: Array[String]) -> void:
	for i in range(surface_segments.size()):
		var segment := surface_segments[i]
		var segment_id := str(segment.get("id", "")).strip_edges()
		var start_index := int(segment.get("start_route_index", -1))
		var end_index := int(segment.get("end_route_index", -1))
		if segment_id.is_empty():
			errors.append("Surface segment %d id is required." % i)
		if start_index < 0 or start_index >= route_points.size():
			errors.append("Surface segment %s start route index is out of range." % segment_id)
		if end_index < 0 or end_index >= route_points.size():
			errors.append("Surface segment %s end route index is out of range." % segment_id)
		if end_index < start_index:
			errors.append("Surface segment %s end route index must be >= start route index." % segment_id)

func _validate_audio_zones(errors: Array[String]) -> void:
	for i in range(audio_zones.size()):
		var zone := audio_zones[i]
		var zone_id := str(zone.get("id", "")).strip_edges()
		var audio_id := str(zone.get("audio_id", "")).strip_edges()
		var audio_path := str(zone.get("audio_path", "")).strip_edges()
		if zone_id.is_empty():
			errors.append("Audio zone %d id is required." % i)
		if audio_id.is_empty() and audio_path.is_empty():
			errors.append("Audio zone %s must reference audio_id or audio_path." % zone_id)
		if not audio_id.is_empty() and not audio_ids.has(audio_id):
			errors.append("Audio zone %s references unknown audio id: %s" % [zone_id, audio_id])
		if not audio_path.is_empty() and not ResourceLoader.exists(audio_path):
			errors.append("Audio zone %s audio path does not exist: %s" % [zone_id, audio_path])
		if float(zone.get("radius", 0.0)) <= 0.0:
			errors.append("Audio zone %s radius must be greater than zero." % zone_id)

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

func _stage_props_to_json(props: Array[Dictionary]) -> Array:
	var out: Array = []
	for prop in props:
		out.append({
			"id": str(prop.get("id", "")),
			"kind": str(prop.get("kind", "box")),
			"asset_path": str(prop.get("asset_path", "")),
			"box_size": _point_value_to_array(prop.get("box_size", Vector3.ONE)),
			"box_color": _color_value_to_array(prop.get("box_color", Color.WHITE)),
			"position": _point_value_to_array(prop.get("position", Vector3.ZERO)),
			"yaw_degrees": float(prop.get("yaw_degrees", 0.0)),
			"scale": _point_value_to_array(prop.get("scale", Vector3.ONE)),
			"collision_mode": str(prop.get("collision_mode", "visual")),
			"audio_material_id": str(prop.get("audio_material_id", "")),
			"gameplay_tag": str(prop.get("gameplay_tag", "")),
		})
	return out

func _surface_segments_to_json(segments: Array[Dictionary]) -> Array:
	var out: Array = []
	for segment in segments:
		out.append({
			"id": str(segment.get("id", "")),
			"start_route_index": int(segment.get("start_route_index", 0)),
			"end_route_index": int(segment.get("end_route_index", 0)),
			"surface_audio_id": str(segment.get("surface_audio_id", "")),
			"surface_material_id": str(segment.get("surface_material_id", "")),
			"position": _point_value_to_array(segment.get("position", Vector3.ZERO)),
		})
	return out

func _audio_zones_to_json(zones: Array[Dictionary]) -> Array:
	var out: Array = []
	for zone in zones:
		out.append({
			"id": str(zone.get("id", "")),
			"audio_id": str(zone.get("audio_id", "")),
			"audio_path": str(zone.get("audio_path", "")),
			"zone_kind": str(zone.get("zone_kind", "ambient")),
			"radius": float(zone.get("radius", 0.0)),
			"volume_db": float(zone.get("volume_db", 0.0)),
			"position": _point_value_to_array(zone.get("position", Vector3.ZERO)),
		})
	return out

func _shortcut_gates_to_json(gates: Array[Dictionary]) -> Array:
	var out: Array = []
	for gate in gates:
		var entry = gate.get("entry", [])
		var exit = gate.get("exit", [])
		out.append({
			"id": str(gate.get("id", "")),
			"kind": str(gate.get("kind", "shortcut")),
			"entry": _point_value_to_array(entry),
			"exit": _point_value_to_array(exit),
			"width": float(gate.get("width", 0.0)),
			"surface_enabled": bool(gate.get("surface_enabled", true)),
		})
	return out

func _point_value_to_array(value: Variant) -> Array:
	if value is Vector3:
		return _vec3_to_array(value)
	if value is Array and value.size() >= 3:
		return [float(value[0]), float(value[1]), float(value[2])]
	return [0.0, 0.0, 0.0]

func _color_value_to_array(value: Variant) -> Array:
	if value is Color:
		var color := value as Color
		return [color.r, color.g, color.b, color.a]
	if value is Array and value.size() >= 4:
		return [float(value[0]), float(value[1]), float(value[2]), float(value[3])]
	return [1.0, 1.0, 1.0, 1.0]

func _vector3_from_value(value: Variant, fallback: Vector3) -> Vector3:
	if value is Vector3:
		return value
	if value is Array and value.size() >= 3:
		return Vector3(float(value[0]), float(value[1]), float(value[2]))
	return fallback

func _vec3_to_array(point: Vector3) -> Array:
	return [point.x, point.y, point.z]
