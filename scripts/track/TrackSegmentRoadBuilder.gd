extends RefCounted
class_name TrackSegmentRoadBuilder

const RoadSegmentProfile = preload("res://scripts/track/RoadSegmentProfile.gd")
const RaceLayout = preload("res://scripts/track/RaceLayout.gd")

const CORNER_ANGLE_THRESHOLD := deg_to_rad(18.0)
const RAMP_SLOPE_THRESHOLD := 0.08
const MIN_SEGMENT_LENGTH := 2.0

static func race_layout_from_segment_layout(segment_layout: Array[Dictionary], road_width: float, closed_loop: bool) -> RaceLayout:
	var race_layout := RaceLayout.new()
	race_layout.source = "track_authoring_preview"
	race_layout.road_visual_style = "kenney_segments"
	race_layout.road_grid_layout = {}
	race_layout.road_segment_layout = segment_layout.duplicate(true)
	race_layout.route_points = route_points_from_layout(segment_layout, closed_loop)
	if race_layout.route_points.size() >= 3:
		race_layout.checkpoint_indices = checkpoint_indices_from_layout(segment_layout, race_layout.route_points, closed_loop)
		race_layout.lap_gate_checkpoint_index = 0
		race_layout.spawn_points = start_grid_from_layout(segment_layout, road_width)
		var generated_items := sockets_from_layout(segment_layout, "item", 10, road_width)
		if not generated_items.is_empty():
			race_layout.item_sockets = generated_items
		var generated_hazards := sockets_from_layout(segment_layout, "hazard", 8, road_width)
		if not generated_hazards.is_empty():
			race_layout.hazard_sockets = generated_hazards
	return race_layout

static func build_segment_road(
	route_points: Array[Vector3],
	road_width: float,
	closed_loop: bool,
	segment_layout: Array = [],
	profile: RoadSegmentProfile = null
) -> Node3D:
	var resolved_profile := profile if profile != null else RoadSegmentProfile.default_profile()
	var holder := Node3D.new()
	holder.name = "SegmentRoad"
	holder.set_meta("road_visual_style", "kenney_segments")
	holder.set_meta("segment_profile", resolved_profile.id)
	holder.set_meta("source", "explicit_layout" if not segment_layout.is_empty() else "route_generated")
	var material := resolved_profile.road_material()
	if segment_layout.is_empty():
		_build_from_route(holder, route_points, road_width, closed_loop, resolved_profile, material)
	else:
		_build_from_layout(holder, segment_layout, road_width, resolved_profile, material)
	return holder

static func route_points_from_layout(segment_layout: Array, closed_loop: bool) -> Array[Vector3]:
	var route: Array[Vector3] = []
	for i in range(segment_layout.size()):
		var segment := _segment_dict(segment_layout[i])
		if segment.is_empty():
			continue
		var endpoints := segment_endpoints(segment)
		var start := endpoints.get("start", Vector3.ZERO) as Vector3
		var end := endpoints.get("end", Vector3.ZERO) as Vector3
		if route.is_empty() or route.back().distance_to(start) > 0.05:
			route.append(start)
		if route.is_empty() or route.back().distance_to(end) > 0.05:
			route.append(end)
	if closed_loop and route.size() > 2 and route.front().distance_to(route.back()) <= 0.05:
		route.remove_at(route.size() - 1)
	return route

static func checkpoint_indices_from_layout(segment_layout: Array, route_points: Array[Vector3], closed_loop: bool) -> Array[int]:
	var indices: Array[int] = []
	for i in range(segment_layout.size()):
		var segment := _segment_dict(segment_layout[i])
		if segment.is_empty():
			continue
		var roles := _roles_from_segment(segment)
		if not roles.has("checkpoint") and not roles.has("start"):
			continue
		var endpoints := segment_endpoints(segment)
		var index := _nearest_route_index(endpoints.get("start", Vector3.ZERO) as Vector3, route_points)
		if index >= 0 and not indices.has(index):
			indices.append(index)
	if indices.size() < 3 and route_points.size() >= 3:
		indices = []
		var desired := 6 if route_points.size() >= 6 else route_points.size()
		for i in range(desired):
			indices.append(clampi(roundi(float(i) * float(route_points.size()) / float(desired)), 0, route_points.size() - 1))
	indices.sort()
	return indices

static func sockets_from_layout(segment_layout: Array, role: String, fallback_count: int, road_width: float) -> Array[Vector4]:
	var sockets: Array[Vector4] = []
	for value in segment_layout:
		var segment := _segment_dict(value)
		if segment.is_empty() or not _roles_from_segment(segment).has(role):
			continue
		var socket := _socket_from_segment(segment)
		sockets.append(socket)
	if sockets.is_empty() and fallback_count > 0:
		var route := route_points_from_layout(segment_layout, true)
		if route.size() >= 2:
			var step := maxi(1, floori(float(route.size()) / float(fallback_count)))
			for i in range(fallback_count):
				var index := (i * step + step / 2) % route.size()
				var next := (index + 1) % route.size()
				sockets.append(_socket_from_points(route[index], route[next]))
	return sockets

static func start_grid_from_layout(segment_layout: Array, road_width: float) -> Array[Vector4]:
	var route := route_points_from_layout(segment_layout, true)
	if route.size() < 2:
		return []
	return _start_grid_from_route(route, road_width)

static func segment_endpoints(segment: Dictionary) -> Dictionary:
	var center := _vector3_from_value(segment.get("position", Vector3.ZERO), Vector3.ZERO)
	var yaw := deg_to_rad(float(segment.get("yaw_degrees", 0.0)))
	var pitch := deg_to_rad(float(segment.get("pitch_degrees", 0.0)))
	var length := maxf(float(segment.get("length", RoadSegmentProfile.DEFAULT_SEGMENT_LENGTH)), MIN_SEGMENT_LENGTH)
	var forward := Basis(Vector3.UP, yaw) * (Basis(Vector3.RIGHT, pitch) * Vector3.BACK)
	forward = forward.normalized()
	var half := forward * (length * 0.5)
	return {"start": center - half, "end": center + half}

static func generated_route_points(route_points: Array[Vector3], closed_loop: bool, profile: RoadSegmentProfile = null) -> Array[Vector3]:
	var resolved_profile := profile if profile != null else RoadSegmentProfile.default_profile()
	var points := _sanitize_route(route_points)
	if points.size() < 2:
		return points
	var out: Array[Vector3] = []
	var segment_count := points.size() if closed_loop else points.size() - 1
	for i in range(segment_count):
		var a := points[i]
		var b := points[(i + 1) % points.size()]
		var segment := b - a
		var length := segment.length()
		if length < MIN_SEGMENT_LENGTH:
			continue
		var pieces := maxi(1, roundi(length / resolved_profile.segment_length))
		for piece_index in range(pieces):
			if i > 0 or piece_index > 0:
				out.append(a.lerp(b, float(piece_index) / float(pieces)))
			elif out.is_empty():
				out.append(a)
	if not closed_loop and not points.is_empty():
		out.append(points.back())
	return out

static func _build_from_route(
	holder: Node3D,
	route_points: Array[Vector3],
	road_width: float,
	closed_loop: bool,
	profile: RoadSegmentProfile,
	material: Material
) -> void:
	var points := _sanitize_route(route_points)
	if points.size() < 2:
		return
	var segment_count := points.size() if closed_loop else points.size() - 1
	for i in range(segment_count):
		var a := points[i]
		var b := points[(i + 1) % points.size()]
		_add_route_segment_pieces(holder, a, b, i, road_width, profile, material)
		if _should_add_corner(points, i, closed_loop):
			_add_corner_piece(holder, points[i], _corner_yaw(points, i, closed_loop), i, road_width, profile, material)

static func _build_from_layout(
	holder: Node3D,
	segment_layout: Array,
	road_width: float,
	profile: RoadSegmentProfile,
	material: Material
) -> void:
	for i in range(segment_layout.size()):
		var value: Variant = segment_layout[i]
		if not (value is Dictionary):
			continue
		var segment: Dictionary = value
		var segment_id := str(segment.get("segment_id", "straight_long"))
		var position := _vector3_from_value(segment.get("position", Vector3.ZERO), Vector3.ZERO)
		var yaw_degrees := float(segment.get("yaw_degrees", 0.0))
		var length := float(segment.get("length", profile.segment_length))
		var slope_degrees := float(segment.get("pitch_degrees", 0.0))
		_add_segment_instance(holder, segment_id, "RoadSegment_%03d_%s" % [i, segment_id], position, deg_to_rad(yaw_degrees), deg_to_rad(slope_degrees), length, road_width, profile, material)

static func _add_route_segment_pieces(
	holder: Node3D,
	a: Vector3,
	b: Vector3,
	segment_index: int,
	road_width: float,
	profile: RoadSegmentProfile,
	material: Material
) -> void:
	var delta := b - a
	var flat := Vector3(delta.x, 0.0, delta.z)
	var length := delta.length()
	if length < MIN_SEGMENT_LENGTH or flat.length() < 0.05:
		return
	var pieces := maxi(1, roundi(length / profile.segment_length))
	var piece_length := length / float(pieces)
	var yaw := atan2(flat.x, flat.z)
	var pitch := atan2(delta.y, flat.length())
	var segment_id := "ramp_long" if absf(delta.y / maxf(flat.length(), 0.001)) >= RAMP_SLOPE_THRESHOLD else "straight_long"
	for piece_index in range(pieces):
		var t0 := float(piece_index) / float(pieces)
		var t1 := float(piece_index + 1) / float(pieces)
		var center := a.lerp(b, (t0 + t1) * 0.5) + Vector3.UP * profile.y_offset
		_add_segment_instance(
			holder,
			segment_id,
			"RoadSegment_%03d_%02d_%s" % [segment_index, piece_index, segment_id],
			center,
			yaw,
			pitch,
			piece_length,
			road_width,
			profile,
			material
		)

static func _add_corner_piece(
	holder: Node3D,
	position: Vector3,
	yaw: float,
	segment_index: int,
	road_width: float,
	profile: RoadSegmentProfile,
	material: Material
) -> void:
	_add_segment_instance(
		holder,
		"corner_large",
		"RoadCorner_%03d" % segment_index,
		position + Vector3.UP * (profile.y_offset + 0.01),
		yaw,
		0.0,
		profile.segment_length,
		road_width,
		profile,
		material
	)

static func _add_segment_instance(
	holder: Node3D,
	segment_id: String,
	node_name: String,
	position: Vector3,
	yaw: float,
	pitch: float,
	length: float,
	road_width: float,
	profile: RoadSegmentProfile,
	material: Material
) -> void:
	var path := profile.segment_path(segment_id)
	var scene := load(path) as PackedScene
	if scene == null:
		_add_fallback_box(holder, node_name, position, yaw, pitch, length, road_width)
		return
	var instance := scene.instantiate()
	if not (instance is Node3D):
		if instance != null:
			instance.queue_free()
		_add_fallback_box(holder, node_name, position, yaw, pitch, length, road_width)
		return
	var node := instance as Node3D
	node.name = node_name
	var width_scale := road_width / profile.model_width
	var length_scale := maxf(length, MIN_SEGMENT_LENGTH) / profile.model_length
	var basis := Basis(Vector3.RIGHT, pitch) * Basis(Vector3.UP, yaw)
	var scaled_basis := Basis(basis.x * width_scale, basis.y, basis.z * length_scale)
	node.transform = Transform3D(scaled_basis, position - scaled_basis * profile.model_center)
	if material != null:
		_apply_material_override(node, material)
	_disable_gameplay_collision(node)
	holder.add_child(node)

static func _add_fallback_box(holder: Node3D, node_name: String, position: Vector3, yaw: float, pitch: float, length: float, road_width: float) -> void:
	var mesh := MeshInstance3D.new()
	mesh.name = node_name
	var box := BoxMesh.new()
	box.size = Vector3(road_width, 0.12, maxf(length, MIN_SEGMENT_LENGTH))
	mesh.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = RoadSegmentProfile.DEFAULT_TOY_ROAD_COLOR
	material.roughness = 0.46
	mesh.material_override = material
	mesh.transform = Transform3D(Basis(Vector3.RIGHT, pitch) * Basis(Vector3.UP, yaw), position)
	holder.add_child(mesh)

static func _should_add_corner(points: Array[Vector3], index: int, closed_loop: bool) -> bool:
	if points.size() < 3:
		return false
	if not closed_loop and (index <= 0 or index >= points.size() - 1):
		return false
	var prev := points[(index - 1 + points.size()) % points.size()]
	var current := points[index]
	var next := points[(index + 1) % points.size()]
	var a := Vector2(current.x - prev.x, current.z - prev.z).normalized()
	var b := Vector2(next.x - current.x, next.z - current.z).normalized()
	if a.length_squared() <= 0.0001 or b.length_squared() <= 0.0001:
		return false
	return absf(a.angle_to(b)) >= CORNER_ANGLE_THRESHOLD

static func _corner_yaw(points: Array[Vector3], index: int, closed_loop: bool) -> float:
	var prev := points[(index - 1 + points.size()) % points.size()]
	var next := points[(index + 1) % points.size()]
	var direction := Vector3(next.x - prev.x, 0.0, next.z - prev.z).normalized()
	if direction.length_squared() <= 0.0001:
		direction = Vector3.FORWARD
	return atan2(direction.x, direction.z)

static func _sanitize_route(route_points: Array[Vector3]) -> Array[Vector3]:
	var out: Array[Vector3] = []
	for point in route_points:
		if out.is_empty() or out.back().distance_to(point) > 0.05:
			out.append(point)
	return out

static func _vector3_from_value(value: Variant, fallback: Vector3) -> Vector3:
	if value is Vector3:
		return value
	if value is Array and value.size() >= 3:
		return Vector3(float(value[0]), float(value[1]), float(value[2]))
	if value is Dictionary:
		return Vector3(float(value.get("x", fallback.x)), float(value.get("y", fallback.y)), float(value.get("z", fallback.z)))
	return fallback

static func _apply_material_override(node: Node, material: Material) -> void:
	if node is MeshInstance3D:
		(node as MeshInstance3D).material_override = material
	for child in node.get_children():
		_apply_material_override(child, material)

static func _disable_gameplay_collision(node: Node) -> void:
	if node is CollisionObject3D:
		var collision := node as CollisionObject3D
		collision.collision_layer = 0
		collision.collision_mask = 0
	for child in node.get_children():
		_disable_gameplay_collision(child)

static func _segment_dict(value: Variant) -> Dictionary:
	return value if value is Dictionary else {}

static func _roles_from_segment(segment: Dictionary) -> Array[String]:
	var roles: Array[String] = []
	var raw = segment.get("roles", segment.get("role_tags", []))
	if raw is Array:
		for role in raw:
			var normalized := str(role).strip_edges().to_lower()
			if not normalized.is_empty():
				roles.append(normalized)
	elif raw is String:
		for role in str(raw).split(",", false):
			var normalized := role.strip_edges().to_lower()
			if not normalized.is_empty():
				roles.append(normalized)
	return roles

static func _nearest_route_index(point: Vector3, route_points: Array[Vector3]) -> int:
	if route_points.is_empty():
		return -1
	var best_index := 0
	var best_distance := INF
	for i in range(route_points.size()):
		var distance := point.distance_squared_to(route_points[i])
		if distance < best_distance:
			best_distance = distance
			best_index = i
	return best_index

static func _socket_from_segment(segment: Dictionary) -> Vector4:
	var endpoints := segment_endpoints(segment)
	return _socket_from_points(endpoints.get("start", Vector3.ZERO) as Vector3, endpoints.get("end", Vector3.FORWARD) as Vector3)

static func _socket_from_points(a: Vector3, b: Vector3) -> Vector4:
	var forward := b - a
	forward.y = 0.0
	if forward.length_squared() <= 0.001:
		forward = Vector3.FORWARD
	forward = forward.normalized()
	var yaw := rad_to_deg(atan2(forward.x, forward.z))
	var position := a.lerp(b, 0.5) + Vector3.UP * 0.8
	return Vector4(position.x, position.y, position.z, yaw)

static func _start_grid_from_route(route_points: Array[Vector3], road_width: float) -> Array[Vector4]:
	var spawns: Array[Vector4] = []
	if route_points.size() < 2:
		return spawns
	var origin := route_points[0]
	var forward := route_points[1] - route_points[0]
	forward.y = 0.0
	if forward.length_squared() <= 0.001:
		forward = Vector3.FORWARD
	forward = forward.normalized()
	var right := Vector3(forward.z, 0.0, -forward.x).normalized()
	var yaw := rad_to_deg(atan2(forward.x, forward.z))
	var lane_gap := minf(road_width * 0.28, 3.0)
	var row_gap := 5.0
	for row in range(4):
		for col in range(2):
			var lateral := (-0.5 if col == 0 else 0.5) * lane_gap
			var forward_offset := float(row) * row_gap
			var position := origin + forward * forward_offset + right * lateral + Vector3.UP * 0.8
			spawns.append(Vector4(position.x, position.y, position.z, yaw))
	return spawns
