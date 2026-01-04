@tool
extends MeshInstance3D
class_name RoadMesh

const TrackWalls = preload("res://scripts/TrackWalls.gd")

@export var points: Array[Vector3] = []
@export var width: float = 10.0
@export var road_material: Material
@export var road_texture: Texture2D
@export var show_wall_preview: bool = true
@export var show_left_wall: bool = false
@export var show_right_wall: bool = true
@export var show_wall_preview_runtime: bool = false
@export var generate_walls_runtime: bool = false
@export var wall_height: float = 2.5
@export var wall_thickness: float = 0.4
@export var shoulder_width: float = 0.3
@export var force_close: bool = true
@export var wall_side_multiplier: float = 1.0 # 1 = outward along frame right, -1 = flip sides

var _last_sig := ""

func _ready() -> void:
	set_process(Engine.is_editor_hint())
	if Engine.is_editor_hint():
		_try_gather_waypoints()
		_maybe_rebuild(true)
	else:
		_rebuild()

func _process(_delta) -> void:
	if not Engine.is_editor_hint() and not show_wall_preview_runtime:
		return
	if Engine.is_editor_hint():
		_try_gather_waypoints()
	_maybe_rebuild(false)

func _maybe_rebuild(force: bool) -> void:
	var sig := _points_signature()
	if not force and sig == _last_sig:
		return
	_last_sig = sig
	_rebuild()

func _rebuild() -> void:
	var mesh: ArrayMesh = _build_mesh()
	self.mesh = mesh
	if road_material == null:
		var mat := StandardMaterial3D.new()
		if road_texture:
			mat.albedo_texture = road_texture
			mat.uv1_scale = Vector3(1, 1, 1)
		road_material = mat
	if road_material:
		material_override = road_material
	_update_collision(mesh)
	if Engine.is_editor_hint() or show_wall_preview_runtime:
		_clear_wall_preview()
		_update_wall_preview()
	else:
		_clear_wall_preview()
	if generate_walls_runtime and not Engine.is_editor_hint():
		_generate_runtime_walls()

func _build_mesh() -> ArrayMesh:
	# If no points set manually, try to pull them from a sibling Waypoints node (editor friendly).
	if points.is_empty():
		_try_gather_waypoints()
	var verts := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()

	if points.size() < 2:
		return ArrayMesh.new()

	var n := points.size()
	var is_closed := force_close or (n > 2 and points[0].distance_to(points[n - 1]) <= width * 0.75)

	var offset_pts := _compute_offset_points(points, width * 0.5, is_closed, 1.0)
	var left_pts: Array[Vector3] = offset_pts.left
	var right_pts: Array[Vector3] = offset_pts.right

	# compute lengths for UV
	var total_len := 0.0
	var seg_lengths: Array[float] = []
	for i in range(n - 1):
		var seg_len := points[i].distance_to(points[i + 1])
		seg_lengths.append(seg_len)
		total_len += seg_len
	if is_closed:
		var closing_len := points[n - 1].distance_to(points[0])
		seg_lengths.append(closing_len)
		total_len += closing_len
	if total_len <= 0.001:
		return ArrayMesh.new()

	var accum_len := 0.0
	var seg_count := seg_lengths.size()
	for i in range(seg_count):
		var i0 := i
		var i1 := (i + 1) % n
		var l0 := left_pts[i0]
		var r0 := right_pts[i0]
		var l1 := left_pts[i1]
		var r1 := right_pts[i1]
		var base_idx: int = verts.size()
		verts.append(l0)
		verts.append(r0)
		verts.append(l1)
		verts.append(r1)
		var v0 := accum_len / total_len
		var v1 := (accum_len + seg_lengths[i]) / total_len
		uvs.append(Vector2(0, v0))
		uvs.append(Vector2(1, v0))
		uvs.append(Vector2(0, v1))
		uvs.append(Vector2(1, v1))
		indices.append(base_idx + 0)
		indices.append(base_idx + 1)
		indices.append(base_idx + 2)
		indices.append(base_idx + 2)
		indices.append(base_idx + 1)
		indices.append(base_idx + 3)
		accum_len += seg_lengths[i]

	var mesh := ArrayMesh.new()
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func _update_collision(mesh: Mesh) -> void:
	var body := get_node_or_null("CollisionBody") as StaticBody3D
	if body == null:
		return
	var shape_node := body.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if shape_node == null:
		return
	var shape := mesh.create_trimesh_shape()
	if shape:
		shape_node.shape = shape

func _try_gather_waypoints() -> void:
	var root := get_parent()
	if root == null:
		return
	var wp_holder := root.get_node_or_null("Waypoints")
	if wp_holder == null:
		return
	var collected: Array[Vector3] = []
	for child in wp_holder.get_children():
		if child is Marker3D:
			collected.append(child.global_transform.origin)
	if collected.size() >= 2:
		points = collected

func _points_signature() -> String:
	var parts: Array[String] = []
	parts.append("%0.3f" % width)
	parts.append("%0.3f" % shoulder_width)
	parts.append("%0.3f" % wall_thickness)
	parts.append("%0.3f" % wall_height)
	parts.append("%0.3f" % wall_side_multiplier)
	parts.append(str(force_close))
	parts.append(str(show_left_wall))
	parts.append(str(show_right_wall))
	for p in points:
		if p is Vector3:
			parts.append("%0.3f,%0.3f,%0.3f" % [p.x, p.y, p.z])
	return "|".join(parts)

func _update_wall_preview() -> void:
	_clear_wall_preview()
	if not show_wall_preview:
		return
	_clear_wall_preview()
	if points.size() < 2:
		return
	var holder := Node3D.new()
	holder.name = "WallPreview"
	var target_parent := get_parent()
	if target_parent:
		target_parent.add_child(holder)
	else:
		add_child(holder)
	# Use world space for preview so world-space points align without double transforms.
	holder.top_level = true
	holder.transform = Transform3D.IDENTITY
	var is_closed := force_close or (points.size() > 2 and points[0].distance_to(points[points.size() - 1]) <= width * 0.75)
	# Use the same wall generator as runtime for consistency.
	var walls := TrackWalls.build_walls(holder, PackedVector3Array(points), width * 0.5, wall_height, wall_thickness, false, is_closed, false)
	# Respect preview toggles.
	if not show_left_wall and walls.has("left") and walls["left"]:
		walls["left"].queue_free()
	if not show_right_wall and walls.has("right") and walls["right"]:
		walls["right"].queue_free()
	# Apply a bright unshaded preview material so walls are visible in the editor.
	var preview_mat := StandardMaterial3D.new()
	preview_mat.albedo_color = Color(0.9, 0.9, 0.1, 0.35)
	preview_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	preview_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	preview_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if walls.has("left") and walls["left"]:
		walls["left"].material_override = preview_mat
	if walls.has("right") and walls["right"]:
		walls["right"].material_override = preview_mat

func _add_preview_segment(parent: Node3D, a: Vector3, b: Vector3) -> void:
	var length := a.distance_to(b)
	if length <= 0.01:
		return
	var mid := (a + b) * 0.5
	var dir := (b - a).normalized()
	if dir == Vector3.ZERO:
		return
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(wall_thickness, wall_height, length)
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.45, 0.45, 0.45)
	mesh.material_override = mat
	var basis := Basis().looking_at(mid + dir, Vector3.UP)
	mesh.transform = Transform3D(basis, mid + Vector3.UP * (wall_height * 0.5))
	mesh.visible = true
	parent.add_child(mesh)

func _clear_wall_preview() -> void:
	var existing := get_node_or_null("WallPreview")
	if existing:
		existing.queue_free()
	else:
		var p := get_parent()
		if p:
			var sibling := p.get_node_or_null("WallPreview")
			if sibling:
				sibling.queue_free()
	# Also remove any auto-generated runtime walls when in editor to keep scenes clean.
	if Engine.is_editor_hint():
		var parent := get_parent()
		if parent:
			var auto := parent.get_node_or_null("AutoWalls")
			if auto:
				auto.queue_free()

func _generate_runtime_walls() -> void:
	var parent := get_parent()
	if parent == null:
		return
	var existing := parent.get_node_or_null("AutoWalls")
	if existing:
		existing.queue_free()
	var holder := Node3D.new()
	holder.name = "AutoWalls"
	holder.top_level = true
	holder.transform = Transform3D.IDENTITY
	var pts := PackedVector3Array(points)
	var closed := force_close or (pts.size() > 2 and pts[0].distance_to(pts[pts.size() - 1]) <= 0.1)
	# Defer add + build together to ensure correct order.
	call_deferred("_add_and_build_walls", parent, holder, pts, closed, width * 0.5, wall_height, wall_thickness)

func _add_and_build_walls(parent: Node, holder: Node3D, pts: PackedVector3Array, closed: bool, half_width: float, h: float, t: float) -> void:
	if not is_instance_valid(parent):
		return
	parent.add_child(holder)
	TrackWalls.build_walls(holder, pts, half_width, h, t, false, closed, true)

func _compute_offset_points(poly: Array[Vector3], offset: float, is_closed: bool, side: float) -> Dictionary:
	var n := poly.size()
	var normals: Array[Vector3] = []
	var seg_count := n - 1
	for i in range(seg_count):
		var dir := (poly[i + 1] - poly[i]).normalized()
		if dir == Vector3.ZERO:
			dir = Vector3(0, 0, 1)
		normals.append(Vector3(dir.z, 0, -dir.x) * side)
	if is_closed:
		var dir := (poly[0] - poly[n - 1]).normalized()
		if dir == Vector3.ZERO:
			dir = Vector3(0, 0, 1)
		normals.append(Vector3(dir.z, 0, -dir.x) * side)

	var left_pts: Array[Vector3] = []
	var right_pts: Array[Vector3] = []
	for i in range(n):
		var prev_normal: Vector3
		var next_normal: Vector3
		if is_closed:
			prev_normal = normals[(i - 1 + normals.size()) % normals.size()]
			next_normal = normals[i % normals.size()]
		else:
			prev_normal = normals[i - 1] if i > 0 else normals[0]
			next_normal = normals[i] if i < normals.size() else normals[normals.size() - 1]

		var miter_right := (prev_normal + next_normal)
		if miter_right.length() < 0.001:
			miter_right = prev_normal
		miter_right = miter_right.normalized()
		var denom_r := miter_right.dot(prev_normal.normalized())
		if abs(denom_r) < 0.001:
			denom_r = 0.001 * (1 if denom_r >= 0 else -1)
		var right_pt: Vector3 = poly[i] + miter_right * (abs(offset) / denom_r)
		right_pts.append(right_pt)

		var miter_left := -(prev_normal + next_normal)
		if miter_left.length() < 0.001:
			miter_left = -prev_normal
		miter_left = miter_left.normalized()
		var denom_l := miter_left.dot((-prev_normal).normalized())
		if abs(denom_l) < 0.001:
			denom_l = 0.001 * (1 if denom_l >= 0 else -1)
		var left_pt: Vector3 = poly[i] + miter_left * (abs(offset) / denom_l)
		left_pts.append(left_pt)

	return {"left": left_pts, "right": right_pts}
