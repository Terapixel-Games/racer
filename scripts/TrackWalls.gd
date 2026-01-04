extends Node3D
class_name TrackWalls

# Robust wall builder from a track centerline. Offsets left/right using per-point frames and mitered joins.
# Cross order note: In Godot's left-handed system, right = up.cross(tangent). Using tan.cross(up) gives LEFT.
# The previous code used tan.cross(up), which inverted side offsets; this is corrected here.

const WALL_BASE_CLEARANCE := 0.1

@export var enable_debug_preview: bool = false
@export var debug_tick_size: float = 0.8
@export var debug_miter_limit: float = 3.0
@export var default_wall_height: float = 2.5

static func sanitize_points(points: PackedVector3Array, min_seg_len: float = 0.05) -> PackedVector3Array:
	var out := PackedVector3Array()
	if points.size() < 2:
		return out
	out.append(points[0])
	for i in range(1, points.size()):
		if points[i].distance_to(out[out.size() - 1]) >= min_seg_len:
			out.append(points[i])
	if out.size() > 2 and out[0].distance_to(out[out.size() - 1]) < min_seg_len:
		out[out.size() - 1] = out[0]
	return out

static func _safe_up(tangent: Vector3, prev_up: Vector3) -> Vector3:
	var up := prev_up
	if abs(tangent.dot(up)) > 0.99:
		up = Vector3.UP
	if abs(tangent.dot(up)) > 0.99:
		up = Vector3.FORWARD
	return up

static func compute_frames(points: PackedVector3Array, closed_loop: bool) -> Array:
	var n := points.size()
	var frames: Array = []
	if n == 0:
		return frames
	var prev_up := Vector3.UP
	var prev_right := Vector3.RIGHT
	for i in range(n):
		var i_prev := (i - 1 + n) % n
		var i_next := (i + 1) % n
		if (not closed_loop and i == 0):
			i_prev = i
		if (not closed_loop and i == n - 1):
			i_next = i
		var tan := (points[i_next] - points[i_prev]).normalized()
		if tan == Vector3.ZERO:
			tan = Vector3.FORWARD
		var up := _safe_up(tan, prev_up).normalized()
		var right := up.cross(tan) # correct for Godot; tan.cross(up) would point left
		if right.length() < 1e-4:
			right = prev_right
		right = right.normalized()
		# Keep continuity: flip if it suddenly turns inward.
		if right.dot(prev_right) < 0.0:
			right = -right
		up = right.cross(tan).normalized()
		# Final orientation fix: ensure up truly points upward.
		if up.dot(Vector3.UP) < 0.0:
			up = -up
			right = -right
		frames.append({"t": tan, "r": right, "u": up})
		prev_up = up
		prev_right = right
	return frames

# Intersect two lines projected onto the plane with normal 'up'
static func _line_intersect(p: Vector3, d: Vector3, q: Vector3, e: Vector3, up: Vector3) -> Vector3:
	var u: Vector3 = up.normalized()
	var d_proj: Vector3 = (d - u * d.dot(u))
	var e_proj: Vector3 = (e - u * e.dot(u))
	if d_proj.length() < 1e-5:
		d_proj = d
	if e_proj.length() < 1e-5:
		e_proj = e
	var y_axis: Vector3 = d_proj.normalized()
	var x_axis: Vector3 = u.cross(y_axis)
	if x_axis.length() < 1e-5:
		x_axis = u.cross(Vector3.FORWARD).normalized()
	if x_axis.length() < 1e-5:
		x_axis = u.cross(Vector3.RIGHT).normalized()

	var p2 := Vector2(p.dot(x_axis), p.dot(y_axis))
	var q2 := Vector2(q.dot(x_axis), q.dot(y_axis))
	var d2 := Vector2(d_proj.dot(x_axis), d_proj.dot(y_axis)).normalized()
	var e2 := Vector2(e_proj.dot(x_axis), e_proj.dot(y_axis)).normalized()

	var denom := d2.x * e2.y - d2.y * e2.x
	if abs(denom) < 1e-6:
		return p
	var t := ((q2.x - p2.x) * e2.y - (q2.y - p2.y) * e2.x) / denom
	var hit2 := p2 + d2 * t
	return x_axis * hit2.x + y_axis * hit2.y

static func compute_offset_polyline(points: PackedVector3Array, frames: Array, offset: float, closed_loop: bool, miter_limit: float = 3.0) -> PackedVector3Array:
	var n: int = points.size()
	var out := PackedVector3Array()
	if n == 0:
		return out
	var seg_dirs: Array = []
	for i in range(n - 1):
		var d: Vector3 = (points[i + 1] - points[i]).normalized()
		if d == Vector3.ZERO:
			d = frames[i]["t"]
		seg_dirs.append(d)
	if closed_loop:
		seg_dirs.append((points[0] - points[n - 1]).normalized())
	else:
		seg_dirs.append(seg_dirs[seg_dirs.size() - 1])

	for i in range(n):
		var i_prev: int = i - 1
		if i_prev < 0:
			i_prev = n - 1 if closed_loop else 0
		var dir_prev: Vector3 = seg_dirs[i_prev]
		var dir_next: Vector3 = seg_dirs[i] if i < seg_dirs.size() else dir_prev
		var n_prev: Vector3 = frames[i_prev]["r"] * offset
		var n_curr: Vector3 = frames[i]["r"] * offset
		var p_prev: Vector3 = points[i_prev]
		var p_curr: Vector3 = points[i]

		if not closed_loop and (i == 0 or i == n - 1):
			out.append(p_curr + n_curr)
			continue

		var line1_origin: Vector3 = p_prev + n_prev
		var line2_origin: Vector3 = p_curr + n_curr
		var up: Vector3 = frames[i]["u"]
		var intersect: Vector3 = _line_intersect(line1_origin, dir_prev, line2_origin, dir_next, up)
		var miter_vec: Vector3 = intersect - (p_curr + n_curr)
		var max_len: float = abs(offset) * miter_limit
		if miter_vec.length() > max_len:
			intersect = (p_curr + n_curr) + miter_vec.normalized() * max_len
		out.append(intersect)
	return out

static func build_wall_mesh(polyline: PackedVector3Array, frames: Array, height: float, thickness: float, closed_loop: bool, smooth_normals: bool, side_sign: float) -> ArrayMesh:
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	var n := polyline.size()
	if n < 2:
		return ArrayMesh.new()
	var accum := 0.0
	var base_clearance := WALL_BASE_CLEARANCE # lift so walls sit above the road surface without floating too high
	for i in range(n):
		if i > 0:
			accum += polyline[i].distance_to(polyline[i - 1])
		var up: Vector3 = frames[i]["u"]
		var outward: Vector3 = frames[i]["r"] * side_sign
		# Ensure outward stays perpendicular to the local up (handles banked/angled roads)
		outward = outward - up * outward.dot(up)
		if outward.length() < 1e-4:
			outward = frames[i]["r"] * side_sign
		outward = outward.normalized()
		var bottom: Vector3 = polyline[i] + outward * (thickness * 0.5) + up * base_clearance
		var top: Vector3 = bottom + up * height
		verts.append(bottom)
		verts.append(top)
		var s_norm: Vector3 = outward if not smooth_normals else (polyline[(i + 1) % n] - polyline[(i - 1 + n) % n]).normalized().cross(up).normalized()
		normals.append(s_norm)
		normals.append(s_norm)
		uvs.append(Vector2(accum, 0))
		uvs.append(Vector2(accum, 1))
	var segs := n if closed_loop else n - 1
	for i in range(segs):
		var i0 := i * 2
		var i1 := ((i + 1) % n) * 2
		indices.append_array([i0, i0 + 1, i1, i1, i0 + 1, i1 + 1])
	var mesh := ArrayMesh.new()
	var arr: Array = []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_NORMAL] = normals
	arr[Mesh.ARRAY_TEX_UV] = uvs
	arr[Mesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return mesh

static func mesh_to_concave_shape(mesh: Mesh) -> Shape3D:
	return mesh.create_trimesh_shape()

# Main entry: builds wall nodes under parent. Returns {left, right}
static func build_walls(parent: Node3D, points: PackedVector3Array, track_half_width: float, wall_height: float, wall_thickness: float, smooth_normals: bool, closed_loop: bool, enable_collision: bool = true) -> Dictionary:
	var cfg := TrackWalls.new()
	var dbg_preview := cfg.enable_debug_preview
	var dbg_tick := cfg.debug_tick_size
	var dbg_miter := cfg.debug_miter_limit
	if wall_height <= 0.0:
		wall_height = cfg.default_wall_height
	var side_mult := 1.0
	var pts := sanitize_points(points)
	if pts.size() < 2:
		return {}
	var frames := compute_frames(pts, closed_loop)
	var offset := track_half_width + (wall_thickness * 0.5)
	var left_poly := compute_offset_polyline(pts, frames, -offset * side_mult, closed_loop, dbg_miter)
	var right_poly := compute_offset_polyline(pts, frames, offset * side_mult, closed_loop, dbg_miter)

	var left_mesh := build_wall_mesh(left_poly, frames, wall_height, wall_thickness, closed_loop, smooth_normals, -1.0)
	var right_mesh := build_wall_mesh(right_poly, frames, wall_height, wall_thickness, closed_loop, smooth_normals, 1.0)

	var wall_mat := StandardMaterial3D.new()
	# Bright, double-sided, unshaded so walls are easy to see in editor and runtime.
	wall_mat.albedo_color = Color(0.8, 0.8, 0.1)
	wall_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	wall_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	# Compute average up/right for collision offset.
	var avg_up := Vector3.ZERO
	var avg_right := Vector3.ZERO
	for f in frames:
		avg_up += f["u"]
		avg_right += f["r"]
	if frames.size() > 0:
		avg_up = avg_up.normalized()
		avg_right = avg_right.normalized()

	var left_node := MeshInstance3D.new()
	left_node.name = "WallLeft"
	left_node.mesh = left_mesh
	left_node.material_override = wall_mat
	var right_node := MeshInstance3D.new()
	right_node.name = "WallRight"
	right_node.mesh = right_mesh
	right_node.material_override = wall_mat

	parent.add_child(left_node)
	parent.add_child(right_node)

	if enable_collision:
		var l_body := StaticBody3D.new()
		l_body.collision_layer = 1
		l_body.collision_mask = 1
		l_body.transform.origin = avg_up * WALL_BASE_CLEARANCE + avg_right * (-wall_thickness * 0.1)
		var l_shape := CollisionShape3D.new()
		l_shape.shape = mesh_to_concave_shape(left_mesh)
		l_body.add_child(l_shape)
		left_node.add_child(l_body)

		var r_body := StaticBody3D.new()
		r_body.collision_layer = 1
		r_body.collision_mask = 1
		r_body.transform.origin = avg_up * WALL_BASE_CLEARANCE + avg_right * (wall_thickness * 0.1)
		var r_shape := CollisionShape3D.new()
		r_shape.shape = mesh_to_concave_shape(right_mesh)
		r_body.add_child(r_shape)
		right_node.add_child(r_body)

	if dbg_preview:
		var dbg := ImmediateMesh.new()
		dbg.surface_begin(Mesh.PRIMITIVE_LINES)
		# center in yellow
		for i in range(pts.size() - 1):
			dbg.surface_set_color(Color(1, 1, 0))
			dbg.surface_add_vertex(pts[i])
			dbg.surface_add_vertex(pts[i + 1])
		# left in red
		for i in range(left_poly.size() - 1):
			dbg.surface_set_color(Color(1, 0, 0))
			dbg.surface_add_vertex(left_poly[i])
			dbg.surface_add_vertex(left_poly[i + 1])
		# right in blue
		for i in range(right_poly.size() - 1):
			dbg.surface_set_color(Color(0, 0, 1))
			dbg.surface_add_vertex(right_poly[i])
			dbg.surface_add_vertex(right_poly[i + 1])
		# right vector ticks
		for i in range(pts.size()):
			var p := pts[i]
			var r: Vector3 = frames[i]["r"]
			dbg.surface_set_color(Color(0, 0.7, 1))
			dbg.surface_add_vertex(p)
			dbg.surface_add_vertex(p + r * dbg_tick)
		dbg.surface_end()
		var dbg_node := MeshInstance3D.new()
		dbg_node.mesh = dbg
		parent.add_child(dbg_node)

	return {"left": left_node, "right": right_node}

# Simple test helper: rectangle plus a sloped segment
static func generate_test_points() -> PackedVector3Array:
	var pts := PackedVector3Array()
	pts.append(Vector3(-20, 0, -20))
	pts.append(Vector3(20, 0, -20))
	pts.append(Vector3(20, 5, 20))
	pts.append(Vector3(-20, 5, 20))
	pts.append(Vector3(-20, 0, 0))
	return pts

# Example usage snippet (call from your builder after road mesh):
# var walls = TrackWalls.build_walls(self, waypoint_array, track_half_width, 1.5, 0.3, false, closed_loop, true)
