extends Node
class_name TrackBuilder

const Config = preload("res://scripts/Config.gd")
const COLLISION_SCRIPT := preload("res://scripts/TrackCollisionBuilder.gd")
const ROAD_TEXTURE_PATH := "res://assets/materials/road.jpg"
const ROAD_SCRIPT := preload("res://scripts/RoadMesh.gd")
const TrackWalls := preload("res://scripts/TrackWalls.gd")

const ASSET_MAP := {
	"track_piece": "res://assets/models/track/track.glb",
	"track_wall": "res://assets/models/track/track_wall.glb",
}

static func build(recipe:Dictionary) -> Dictionary:
	var root: Node3D = Node3D.new()
	root.name = "Track"
	# Attach collision helper script so walls get trimesh collisions on _ready.
	root.set_script(COLLISION_SCRIPT)

	_build_environment(root, recipe.get("env", {}))
	_build_ground(root, recipe.get("ground", {}))
	_build_road(root, recipe)
	var tiles_var = recipe.get("tiles", [])
	if tiles_var is Array:
		_build_tiles(root, tiles_var)
	var walls_var = recipe.get("walls", [])
	if walls_var is Array and walls_var.size() > 0:
		_build_walls(root, walls_var)
	else:
		_build_runtime_walls(root, recipe)
	var bounds_var = recipe.get("bounds", [])
	if bounds_var is Array:
		_build_bounds(root, bounds_var)
	var spawns: Array = _build_spawns(root, recipe.get("spawn_points", []))
	if spawns.is_empty():
		# Fallback spawn so a car always appears.
		spawns.append(Transform3D(Basis(), Vector3(0, 0.5, 0)))
	var waypoints: Array = _build_waypoints(root, recipe.get("waypoints", []))
	if waypoints.is_empty():
		waypoints.append(Vector3.ZERO)
	var laps: int = int(recipe.get("laps", Config.LAPS))

	return {
		"node": root,
		"spawns": spawns,
		"waypoints": waypoints,
		"laps": laps,
	}

static func _build_environment(root:Node3D, env:Dictionary) -> void:
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_horizon_color = Color(0.6, 0.75, 0.9)
	sky_material.ground_horizon_color = Color(0.55, 0.6, 0.65)
	var sky := Sky.new()
	sky.sky_material = sky_material
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_sky_contribution = 0.8
	environment.ambient_light_energy = 1.1
	environment.glow_enabled = true
	environment.glow_intensity = 0.05
	var env_node := WorldEnvironment.new()
	env_node.environment = environment
	root.add_child(env_node)

	var sun := DirectionalLight3D.new()
	var dir: Array = env.get("light_dir", [0.939693, -0.34202, 0.0])
	var dir_vec := Vector3(
		dir[0] if dir.size() > 0 else 0.939693,
		dir[1] if dir.size() > 1 else -0.34202,
		dir[2] if dir.size() > 2 else 0.0
	)
	sun.transform.basis = Basis().looking_at(dir_vec, Vector3.UP)
	sun.light_energy = float(env.get("light_energy", 2.5))
	sun.shadow_enabled = true
	sun.shadow_bias = 0.05
	root.add_child(sun)

static func _build_ground(root:Node3D, ground:Dictionary) -> void:
	var ground_size: Array = ground.get("size", [220, 0.2, 220])
	var color_arr: Array = ground.get("color", [0.2, 0.21, 0.24])
	var ground_body := StaticBody3D.new()
	ground_body.name = "Ground"
	var col_shape := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(ground_size[0], ground_size[1], ground_size[2])
	col_shape.shape = shape
	ground_body.add_child(col_shape)
	root.add_child(ground_body)

	var mesh_instance := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(ground_size[0], ground_size[2])
	mesh_instance.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(color_arr[0], color_arr[1], color_arr[2])
	mat.roughness = 0.8
	mesh_instance.material_override = mat
	mesh_instance.transform.origin = Vector3(0, -0.1, 0)
	root.add_child(mesh_instance)

static func _build_road(root: Node3D, recipe: Dictionary) -> void:
	var pts_variant = recipe.get("waypoints", [])
	if not (pts_variant is Array):
		return
	var pts: Array = pts_variant
	if pts.size() < 2:
		return
	# Convert to Vector3 array
	var path: Array[Vector3] = []
	for p in pts:
		if p is Array and p.size() >= 3:
			path.append(Vector3(p[0], p[1], p[2]))
		elif p is Vector3:
			path.append(p)
	if path.size() < 2:
		return
	var road := MeshInstance3D.new()
	road.name = "Road"
	road.set_script(ROAD_SCRIPT)
	road.set("points", path)
	road.set("width", float(recipe.get("road_width", 12.0)))
	var tex := load(ROAD_TEXTURE_PATH)
	if tex:
		road.set("road_texture", tex)
	# Collision child expected by RoadMesh.gd
	var body := StaticBody3D.new()
	body.name = "CollisionBody"
	var col := CollisionShape3D.new()
	col.name = "CollisionShape3D"
	body.add_child(col)
	road.add_child(body)
	root.add_child(road)

static func _build_tiles(root:Node3D, tiles:Array) -> void:
	if tiles.is_empty():
		return
	var holder := Node3D.new()
	holder.name = "TrackSegments"
	root.add_child(holder)
	for t in tiles:
		var packed:PackedScene = _get_scene(t.get("asset", ""))
		if packed == null:
			continue
		var inst := packed.instantiate()
		if inst is Node3D:
			_apply_transform(inst as Node3D, t)
			holder.add_child(inst)

static func _build_walls(root:Node3D, walls:Array) -> void:
	var holder := Node3D.new()
	holder.name = "Walls"
	root.add_child(holder)
	for w in walls:
		var packed:PackedScene = _get_scene(w.get("asset", ""))
		if packed == null:
			continue
		var inst := packed.instantiate()
		if inst is Node3D:
			_apply_transform(inst as Node3D, w)
			holder.add_child(inst)

static func _build_bounds(root:Node3D, bounds:Array) -> void:
	if bounds.is_empty():
		return
	var holder := Node3D.new()
	holder.name = "Bounds"
	root.add_child(holder)
	for b in bounds:
		if b.get("type", "") != "box":
			continue
		var size_arr: Array = b.get("size", [1,1,1])
		var body := StaticBody3D.new()
		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(size_arr[0], size_arr[1], size_arr[2])
		col.shape = shape
		_apply_transform(body, b)
		body.add_child(col)
		holder.add_child(body)

static func _build_auto_walls(root: Node3D, recipe: Dictionary) -> void:
	var pts_variant = recipe.get("waypoints", [])
	if not (pts_variant is Array) or pts_variant.size() < 2:
		return
	var path: Array[Vector3] = []
	for p in pts_variant:
		if p is Array and p.size() >= 3:
			path.append(Vector3(p[0], p[1], p[2]))
		elif p is Vector3:
			path.append(p)
	if path.size() < 2:
		return
	var half_width := float(recipe.get("road_width", 12.0)) * 0.5
	var wall_thickness := float(recipe.get("wall_thickness", 0.4))
	var wall_height := float(recipe.get("wall_height", 1.5))
	var shoulder_width := float(recipe.get("shoulder_width", 0.3)) # extra space outside the paved edge
	var wall_side := float(recipe.get("wall_side", -1.0)) # flip if walls land on the wrong side
	var wall_left := bool(recipe.get("wall_left", false))
	var wall_right := bool(recipe.get("wall_right", true))
	var holder := Node3D.new()
	holder.name = "Walls"
	root.add_child(holder)
	var offset_dist := half_width + shoulder_width + (wall_thickness * 0.5)
	var close_threshold := half_width * 1.2
	var is_closed := path[0].distance_to(path[path.size() - 1]) <= close_threshold
	var offset_pts := _compute_offset_points(path, offset_dist * wall_side, is_closed, wall_side)
	var left_pts: Array[Vector3] = offset_pts.left
	var right_pts: Array[Vector3] = offset_pts.right

	var seg_count := left_pts.size() - 1
	for i in range(seg_count):
		if wall_left:
			_add_wall_segment(holder, left_pts[i], left_pts[i + 1], wall_thickness, wall_height)
		if wall_right:
			_add_wall_segment(holder, right_pts[i], right_pts[i + 1], wall_thickness, wall_height)
	if is_closed:
		if wall_left:
			_add_wall_segment(holder, left_pts[left_pts.size() - 1], left_pts[0], wall_thickness, wall_height)
		if wall_right:
			_add_wall_segment(holder, right_pts[right_pts.size() - 1], right_pts[0], wall_thickness, wall_height)

static func _add_wall_segment(parent: Node3D, a: Vector3, b: Vector3, thickness: float, height: float) -> void:
	var length := a.distance_to(b)
	if length <= 0.01:
		return
	var mid := (a + b) * 0.5
	var dir := (b - a).normalized()
	var wall := StaticBody3D.new()
	wall.name = "AutoWall"
	var shape_node := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(thickness, height, length)
	shape_node.shape = shape
	wall.add_child(shape_node)
	var basis := Basis().looking_at(mid + dir, Vector3.UP)
	wall.transform = Transform3D(basis, mid + Vector3.UP * (height * 0.5))
	# Visual mesh for editor clarity and color (grey).
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(thickness, height, length)
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.45, 0.45, 0.45)
	mesh.material_override = mat
	wall.add_child(mesh)
	parent.add_child(wall)

static func _build_spawns(root:Node3D, spawns:Array) -> Array:
	var holder := Node3D.new()
	holder.name = "SpawnPoints"
	root.add_child(holder)
	var out: Array = []
	for i in range(spawns.size()):
		var s = spawns[i]
		if not (s is Array) or s.size() < 3:
			continue
		var marker := Marker3D.new()
		marker.name = "Start%02d" % (i + 1)
		var xform := _apply_transform(marker, {"pos": s, "rot": [0, s[3] if s.size() > 3 else 0, 0]})
		holder.add_child(marker)
		out.append(xform)
	return out

static func _compute_offset_points(poly: Array[Vector3], offset: float, is_closed: bool, side: float) -> Dictionary:
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

static func _build_runtime_walls(root: Node3D, recipe: Dictionary) -> void:
	var pts_variant = recipe.get("waypoints", [])
	if not (pts_variant is Array) or pts_variant.size() < 2:
		return
	var pts := PackedVector3Array()
	for p in pts_variant:
		if p is Array and p.size() >= 3:
			pts.append(Vector3(p[0], p[1], p[2]))
		elif p is Vector3:
			pts.append(p)
	if pts.size() < 2:
		return
	var closed_loop := bool(recipe.get("closed_loop", false))
	if not closed_loop and pts.size() > 2 and pts[0].distance_to(pts[pts.size() - 1]) < 0.5:
		closed_loop = true
	var track_half_width := float(recipe.get("road_width", 12.0)) * 0.5
	var wall_height := float(recipe.get("wall_height", 1.5))
	var wall_thickness := float(recipe.get("wall_thickness", 0.4))
	var smooth_normals := bool(recipe.get("wall_smooth_normals", false))
	var holder := Node3D.new()
	holder.name = "Walls"
	root.add_child(holder)
	TrackWalls.build_walls(holder, pts, track_half_width, wall_height, wall_thickness, smooth_normals, closed_loop, true)

static func _build_waypoints(root:Node3D, waypoints:Array) -> Array:
	var holder := Node3D.new()
	holder.name = "Waypoints"
	root.add_child(holder)
	var out: Array = []
	for i in range(waypoints.size()):
		var w = waypoints[i]
		if not (w is Array) or w.size() < 3:
			continue
		var marker := Marker3D.new()
		marker.name = "Waypoint%02d" % (i + 1)
		var xform := _apply_transform(marker, {"pos": w, "rot": [0,0,0]})
		holder.add_child(marker)
		out.append(xform.origin)
	return out

static func _apply_transform(node:Node3D, data:Dictionary) -> Transform3D:
	var pos_arr: Array = data.get("pos", data.get("position", [0,0,0]))
	var rot_arr: Array = data.get("rot", data.get("rotation", [0,0,0]))
	var scale_arr: Array = data.get("scale", [1,1,1])
	var basis := Basis()
	basis = basis.rotated(Vector3.RIGHT, deg_to_rad(rot_arr[0]))
	basis = basis.rotated(Vector3.UP, deg_to_rad(rot_arr[1]))
	basis = basis.rotated(Vector3.BACK, deg_to_rad(rot_arr[2]))
	var xform := Transform3D.IDENTITY
	xform.basis = basis.scaled(Vector3(scale_arr[0], scale_arr[1], scale_arr[2]))
	xform.origin = Vector3(pos_arr[0], pos_arr[1], pos_arr[2])
	node.transform = xform
	return xform

static func _get_scene(key:String) -> PackedScene:
	var path : String = ASSET_MAP.get(key, "")
	if path == "":
		return null
	return load(path)
