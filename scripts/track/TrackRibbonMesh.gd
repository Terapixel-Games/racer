extends RefCounted
class_name TrackRibbonMesh

const TrackWalls = preload("res://scripts/TrackWalls.gd")

static func build_slab_mesh(route_points: Array[Vector3], road_width: float, body_depth: float, closed_loop: bool) -> ArrayMesh:
	var points := PackedVector3Array()
	for point in route_points:
		points.append(point)
	points = TrackWalls.sanitize_points(points)
	if points.size() < 2 or road_width <= 0.0 or body_depth <= 0.0:
		return ArrayMesh.new()

	var half_width := road_width * 0.5
	var edges := _road_edge_points(points, half_width, closed_loop)
	var left := edges.get("left", PackedVector3Array()) as PackedVector3Array
	var right := edges.get("right", PackedVector3Array()) as PackedVector3Array
	if left.size() != points.size() or right.size() != points.size():
		return ArrayMesh.new()

	var vertices := PackedVector3Array()
	var indices := PackedInt32Array()
	var segment_count := points.size() if closed_loop else points.size() - 1
	for i in range(segment_count):
		var next := (i + 1) % points.size()
		_add_slab_segment(vertices, indices, left[i], right[i], left[next], right[next], body_depth)

	if not closed_loop:
		_add_end_cap(vertices, indices, left[0], right[0], body_depth)
		var last := points.size() - 1
		_add_end_cap(vertices, indices, right[last], left[last], body_depth)

	var mesh := ArrayMesh.new()
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

static func _road_edge_points(points: PackedVector3Array, offset: float, closed_loop: bool) -> Dictionary:
	var normals: Array[Vector3] = []
	var segment_count := points.size() - 1
	for i in range(segment_count):
		var direction := (points[i + 1] - points[i]).normalized()
		if direction == Vector3.ZERO:
			direction = Vector3.FORWARD
		normals.append(Vector3(direction.z, 0.0, -direction.x))
	if closed_loop:
		var direction := (points[0] - points[points.size() - 1]).normalized()
		if direction == Vector3.ZERO:
			direction = Vector3.FORWARD
		normals.append(Vector3(direction.z, 0.0, -direction.x))

	var left := PackedVector3Array()
	var right := PackedVector3Array()
	for i in range(points.size()):
		var previous_normal: Vector3
		var next_normal: Vector3
		if closed_loop:
			previous_normal = normals[(i - 1 + normals.size()) % normals.size()]
			next_normal = normals[i % normals.size()]
		else:
			previous_normal = normals[i - 1] if i > 0 else normals[0]
			next_normal = normals[i] if i < normals.size() else normals[normals.size() - 1]
		right.append(_road_miter_point(points[i], previous_normal, next_normal, offset))
		left.append(_road_miter_point(points[i], -previous_normal, -next_normal, offset))
	return {"left": left, "right": right}

static func _road_miter_point(point: Vector3, previous_normal: Vector3, next_normal: Vector3, offset: float) -> Vector3:
	var miter := previous_normal + next_normal
	if miter.length() < 0.001:
		miter = previous_normal
	miter = miter.normalized()
	var denom := miter.dot(previous_normal.normalized())
	if abs(denom) < 0.001:
		denom = 0.001 * (1.0 if denom >= 0.0 else -1.0)
	return point + miter * (abs(offset) / denom)

static func _add_slab_segment(vertices: PackedVector3Array, indices: PackedInt32Array, left_0: Vector3, right_0: Vector3, left_1: Vector3, right_1: Vector3, body_depth: float) -> void:
	var left_0_bottom := left_0 - Vector3.UP * body_depth
	var right_0_bottom := right_0 - Vector3.UP * body_depth
	var left_1_bottom := left_1 - Vector3.UP * body_depth
	var right_1_bottom := right_1 - Vector3.UP * body_depth
	_add_quad(vertices, indices, left_0, left_1, left_0_bottom, left_1_bottom)
	_add_quad(vertices, indices, right_1, right_0, right_1_bottom, right_0_bottom)

static func _add_end_cap(vertices: PackedVector3Array, indices: PackedInt32Array, left: Vector3, right: Vector3, body_depth: float) -> void:
	_add_quad(vertices, indices, left, right, left - Vector3.UP * body_depth, right - Vector3.UP * body_depth)

static func _add_quad(vertices: PackedVector3Array, indices: PackedInt32Array, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	var base := vertices.size()
	vertices.append(a)
	vertices.append(b)
	vertices.append(c)
	vertices.append(d)
	indices.append_array([base, base + 1, base + 2, base + 2, base + 1, base + 3])
