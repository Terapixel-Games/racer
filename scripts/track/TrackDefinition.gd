extends Resource
class_name TrackDefinition

const TrackProgressRules = preload("res://scripts/track/TrackProgressRules.gd")
const TrackSourceRules = preload("res://scripts/track/TrackSourceRules.gd")

@export var id := ""
@export var display_name := ""
@export var version := ""
@export var laps := 2
@export var track_source_id := ""
@export var progress_rule_id := TrackSourceRules.PROGRESS_ROUTE_LAP
@export var win_condition_id := TrackSourceRules.WIN_CHECKPOINT_LAPS
@export var road_width := 12.0
@export var wall_height := 3.0
@export var wall_thickness := 0.6
@export var rails_enabled := false
@export var boundary_walls_enabled := true
@export var boundary_wall_debug_visible := false
@export var closed_loop := true
@export var out_of_bounds_y := -50.0
@export var reset_mode := ""
@export var floor_visual_y := 0.0
@export var runtime_scene_path := ""
@export_file("*.tscn") var dressing_scene_path := ""
@export_file("*.tscn") var preview_dressing_scene_path := ""
@export var ground_size := Vector2(160.0, 140.0)
@export var ground_color := Color(0.82, 0.86, 0.88)
@export var ground_texture_path := ""
@export var ground_shader_path := ""
@export var road_texture_path := ""
@export_enum("kenney_segments", "kenney_gridmap", "procedural") var road_visual_style := "kenney_segments"
@export var road_segment_profile := "kenney_racing_kit"
@export var road_segment_material_style := "toy_plastic"
@export var road_segment_layout: Array[Dictionary] = []
@export var road_grid_layout: Dictionary = {}
@export var rail_texture_path := ""
@export var rail_texture_uv_scale := 1.0
@export var track_body_depth := 0.38
@export var track_body_color := Color(0.08, 0.08, 0.1)
@export var sky_preset_id := ""
@export_range(0.0, 1.0, 0.01) var sky_time_of_day := 0.5
@export var sky_weather := ""
@export var sky_top_color := Color(0.58, 0.72, 0.9)
@export var sky_horizon_color := Color(0.64, 0.72, 0.82)
@export_range(0.0, 1.0, 0.01) var sky_cloud_amount := 0.25
@export var sky_cloud_speed := 0.02
@export_range(0.0, 1.0, 0.01) var sky_haze_amount := 0.18
@export var sky_light_energy := 2.4
@export var route_points: Array[Vector3] = []
@export var checkpoint_indices: Array[int] = []
@export var lap_gate_checkpoint_index := 0
@export var spawn_points: Array[Vector4] = []
@export var item_sockets: Array[Vector4] = []
@export var hazard_sockets: Array[Vector4] = []
@export var shortcut_gates: Array[Dictionary] = []
@export var alternate_routes: Array[Dictionary] = []
@export var stage_props: Array[Dictionary] = []
@export var surface_segments: Array[Dictionary] = []
@export var audio_zones: Array[Dictionary] = []
@export var grass_zones: Array[Dictionary] = []
@export var dressing_overrides: Dictionary = {}
@export var audio_ids: Dictionary = {}

func validate() -> Array[String]:
	var errors: Array[String] = []
	if has_meta("track_source_validation_errors"):
		for error in get_meta("track_source_validation_errors", []):
			errors.append(str(error))
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
	if road_visual_style.strip_edges().is_empty():
		errors.append("Track road visual style is required.")
	if track_source_id.strip_edges().is_empty() and road_grid_layout.is_empty():
		errors.append("Track must resolve a RoadGridMap source.")
	if track_source_id.strip_edges() != "" and track_source_id != "road_grid_map":
		errors.append("Track source must be road_grid_map for MVP racing.")
	if road_visual_style != "kenney_gridmap":
		errors.append("Track road visual style must be kenney_gridmap for MVP racing.")
	if road_grid_layout.is_empty():
		errors.append("Track must include RoadGridMap layout metadata.")
	_validate_checkpoints(errors)
	_validate_alternate_routes(errors)
	if spawn_points.size() < 8:
		errors.append("Track must include at least 8 spawn points.")
	_validate_spawn_points(errors)
	if lap_gate_checkpoint_index < 0 or lap_gate_checkpoint_index >= checkpoint_indices.size():
		errors.append("Track must include exactly one valid lap gate checkpoint index.")
	if not dressing_scene_path.strip_edges().is_empty() and not ResourceLoader.exists(dressing_scene_path):
		errors.append("Track dressing scene path does not exist: %s" % dressing_scene_path)
	if not preview_dressing_scene_path.strip_edges().is_empty() and not ResourceLoader.exists(preview_dressing_scene_path):
		errors.append("Track preview dressing scene path does not exist: %s" % preview_dressing_scene_path)
	_validate_stage_props(errors)
	_validate_surface_segments(errors)
	_validate_audio_zones(errors)
	_validate_grass_zones(errors)
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
		"track_source_id": track_source_id,
		"progress_rule_id": TrackSourceRules.canonical_progress_rule(progress_rule_id),
		"win_condition_id": TrackSourceRules.canonical_win_condition(win_condition_id),
		"road_width": road_width,
		"wall_height": wall_height,
		"wall_thickness": wall_thickness,
		"rails_enabled": rails_enabled,
		"boundary_walls_enabled": boundary_walls_enabled,
		"boundary_wall_debug_visible": boundary_wall_debug_visible,
		"closed_loop": closed_loop,
		"out_of_bounds_y": out_of_bounds_y,
		"reset_mode": reset_mode,
		"floor_visual_y": floor_visual_y,
		"ground_texture_path": ground_texture_path,
		"ground_shader_path": ground_shader_path,
		"road_visual_style": road_visual_style,
		"road_segment_profile": road_segment_profile,
		"road_segment_material_style": road_segment_material_style,
		"road_segment_layout": _road_segment_layout_to_json(road_segment_layout),
		"road_grid_layout": _road_grid_layout_to_json(road_grid_layout),
		"rail_texture_path": rail_texture_path,
		"rail_texture_uv_scale": rail_texture_uv_scale,
		"sky_preset_id": sky_preset_id,
		"sky_time_of_day": sky_time_of_day,
		"sky_weather": sky_weather,
		"sky_top_color": _color_value_to_array(sky_top_color),
		"sky_horizon_color": _color_value_to_array(sky_horizon_color),
		"sky_cloud_amount": sky_cloud_amount,
		"sky_cloud_speed": sky_cloud_speed,
		"sky_haze_amount": sky_haze_amount,
		"sky_light_energy": sky_light_energy,
		"route_points": _vec3_array_to_json(route_points),
		"route_length": TrackProgressRules.route_length(route_points, closed_loop),
		"checkpoint_radius": road_width * 0.65,
		"checkpoints": checkpoints,
		"lap_gate_checkpoint_index": lap_gate_checkpoint_index,
		"spawn_points": _socket_array_to_json(spawn_points),
		"item_sockets": _socket_array_to_json(item_sockets),
		"hazard_sockets": _socket_array_to_json(hazard_sockets),
		"shortcut_gates": _shortcut_gates_to_json(shortcut_gates),
		"alternate_routes": _alternate_routes_to_json(alternate_routes),
		"stage_props": _stage_props_to_json(stage_props),
		"surface_segments": _surface_segments_to_json(surface_segments),
		"audio_zones": _audio_zones_to_json(audio_zones),
		"grass_zones": _grass_zones_to_json(grass_zones),
		"audio_ids": audio_ids,
		"runtime_scene_path": runtime_scene_path,
		"dressing_scene_path": dressing_scene_path,
		"preview_dressing_scene_path": preview_dressing_scene_path,
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

func _validate_alternate_routes(errors: Array[String]) -> void:
	for i in range(alternate_routes.size()):
		var route := alternate_routes[i]
		if not bool(route.get("enabled", true)):
			continue
		var route_id := str(route.get("id", "")).strip_edges()
		if route_id.is_empty():
			errors.append("Alternate route %d id is required." % i)
		var points := _vector3_array_from_value(route.get("points", []))
		if points.size() < 2:
			errors.append("Alternate route %s must include at least 2 points." % route_id)
		var entry_checkpoint := int(route.get("entry_checkpoint_index", -1))
		var exit_checkpoint := int(route.get("exit_checkpoint_index", -1))
		if entry_checkpoint < 0 or entry_checkpoint >= checkpoint_indices.size():
			errors.append("Alternate route %s entry checkpoint index is out of range." % route_id)
		if exit_checkpoint < 0 or exit_checkpoint >= checkpoint_indices.size():
			errors.append("Alternate route %s exit checkpoint index is out of range." % route_id)
		if entry_checkpoint >= 0 and exit_checkpoint >= 0 and exit_checkpoint <= entry_checkpoint:
			errors.append("Alternate route %s exit checkpoint must be after entry checkpoint." % route_id)
		if float(route.get("road_width", road_width)) <= 0.0:
			errors.append("Alternate route %s road width must be greater than zero." % route_id)

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

func _validate_grass_zones(errors: Array[String]) -> void:
	for i in range(grass_zones.size()):
		var zone := grass_zones[i]
		if not bool(zone.get("enabled", true)):
			continue
		var zone_id := str(zone.get("id", "")).strip_edges()
		var size := _vector2_from_value(zone.get("size", Vector2.ZERO), Vector2.ZERO)
		if zone_id.is_empty():
			errors.append("Grass zone %d id is required." % i)
		if size.x <= 0.0 or size.y <= 0.0:
			errors.append("Grass zone %s size must be positive." % zone_id)
		if float(zone.get("density", 1.0)) < 0.0:
			errors.append("Grass zone %s density must be non-negative." % zone_id)

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

func _road_segment_layout_to_json(layout: Array[Dictionary]) -> Array:
	var out: Array = []
	for segment in layout:
		out.append({
			"segment_id": str(segment.get("segment_id", "straight_long")),
			"position": _point_value_to_array(segment.get("position", Vector3.ZERO)),
			"yaw_degrees": float(segment.get("yaw_degrees", 0.0)),
			"pitch_degrees": float(segment.get("pitch_degrees", 0.0)),
			"length": float(segment.get("length", 0.0)),
		})
	return out

func _road_grid_layout_to_json(layout: Dictionary) -> Dictionary:
	if layout.is_empty():
		return {}
	var out := layout.duplicate(true)
	if out.has("origin"):
		out["origin"] = _point_value_to_array(out.get("origin", Vector3.ZERO))
	if out.has("cell_size"):
		out["cell_size"] = _point_value_to_array(out.get("cell_size", Vector3.ZERO))
	for point_key in ["ordered_route_points"]:
		if out.has(point_key):
			var points: Array = []
			for value in out.get(point_key, []):
				points.append(_point_value_to_array(value))
			out[point_key] = points
	if out.has("ordered_route_cells"):
		var ordered: Array = []
		for value in out.get("ordered_route_cells", []):
			ordered.append(_vector3i_value_to_array(value))
		out["ordered_route_cells"] = ordered
	if out.has("cells"):
		var cells: Array = []
		for value in out.get("cells", []):
			if not (value is Dictionary):
				continue
			var cell := (value as Dictionary).duplicate(true)
			cell["cell"] = _vector3i_value_to_array(cell.get("cell", Vector3i.ZERO))
			if cell.has("position"):
				cell["position"] = _point_value_to_array(cell.get("position", Vector3.ZERO))
			cells.append(cell)
		out["cells"] = cells
	return out

func _vector3i_value_to_array(value: Variant) -> Array:
	if value is Vector3i:
		return [value.x, value.y, value.z]
	if value is Vector3:
		return [roundi(value.x), roundi(value.y), roundi(value.z)]
	if value is Array and value.size() >= 3:
		return [int(value[0]), int(value[1]), int(value[2])]
	if value is Dictionary:
		return [int(value.get("x", 0)), int(value.get("y", 0)), int(value.get("z", 0))]
	return [0, 0, 0]

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

func _grass_zones_to_json(zones: Array[Dictionary]) -> Array:
	var out: Array = []
	for zone in zones:
		out.append({
			"id": str(zone.get("id", "")),
			"position": _point_value_to_array(zone.get("position", Vector3.ZERO)),
			"yaw_degrees": float(zone.get("yaw_degrees", 0.0)),
			"size": _vector2_value_to_array(zone.get("size", Vector2.ZERO)),
			"density": float(zone.get("density", 1.0)),
			"enabled": bool(zone.get("enabled", true)),
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

func _alternate_routes_to_json(routes: Array[Dictionary]) -> Array:
	var out: Array = []
	for route in routes:
		out.append({
			"id": str(route.get("id", "")),
			"points": _vec3_array_to_json(_vector3_array_from_value(route.get("points", []))),
			"entry_checkpoint_index": int(route.get("entry_checkpoint_index", 0)),
			"exit_checkpoint_index": int(route.get("exit_checkpoint_index", 0)),
			"road_width": float(route.get("road_width", road_width)),
			"enabled": bool(route.get("enabled", true)),
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

func _vector2_value_to_array(value: Variant) -> Array:
	var vector := _vector2_from_value(value, Vector2.ZERO)
	return [vector.x, vector.y]

func _vector2_from_value(value: Variant, fallback: Vector2) -> Vector2:
	if value is Vector2:
		return value
	if value is Array and value.size() >= 2:
		return Vector2(float(value[0]), float(value[1]))
	return fallback

func _vector3_from_value(value: Variant, fallback: Vector3) -> Vector3:
	if value is Vector3:
		return value
	if value is Array and value.size() >= 3:
		return Vector3(float(value[0]), float(value[1]), float(value[2]))
	return fallback

func _vector3_array_from_value(value: Variant) -> Array[Vector3]:
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

func _vec3_to_array(point: Vector3) -> Array:
	return [point.x, point.y, point.z]
