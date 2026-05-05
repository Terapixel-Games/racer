extends "res://tests/framework/TestCase.gd"

const TrackRibbonMesh = preload("res://scripts/track/TrackRibbonMesh.gd")
const RoadMeshScript = preload("res://scripts/RoadMesh.gd")

func test_track_body_has_no_solid_underside_ceiling() -> void:
	var surface_y := 3.0
	var body_depth := 0.5
	var mesh := TrackRibbonMesh.build_slab_mesh([
		Vector3(-10, surface_y, -10),
		Vector3(10, surface_y, -10),
		Vector3(10, surface_y, 10),
		Vector3(-10, surface_y, 10),
	], 6.0, body_depth, true)
	assert_true(mesh.get_surface_count() == 1, "Track body should generate one mesh surface")
	var arrays := mesh.surface_get_arrays(0)
	var vertices := arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
	var indices := arrays[Mesh.ARRAY_INDEX] as PackedInt32Array
	var underside_y := surface_y - body_depth
	for i in range(0, indices.size(), 3):
		var a := vertices[indices[i]]
		var b := vertices[indices[i + 1]]
		var c := vertices[indices[i + 2]]
		var triangle_is_underside := (
			is_equal_approx(a.y, underside_y)
			and is_equal_approx(b.y, underside_y)
			and is_equal_approx(c.y, underside_y)
		)
		assert_true(not triangle_is_underside, "Track body should not render horizontal underside triangles that hide racers under overpasses")

func test_track_body_side_faces_align_to_road_edges() -> void:
	var points: Array[Vector3] = [
		Vector3(-20, 3.0, -6),
		Vector3(-2, 4.2, -16),
		Vector3(18, 3.5, -5),
		Vector3(12, 3.2, 17),
		Vector3(-14, 3.8, 14),
	]
	var width := 12.0
	var body_depth := 0.45
	var body_mesh := TrackRibbonMesh.build_slab_mesh(points, width, body_depth, true)
	var road := RoadMeshScript.new()
	road.points = points
	road.width = width
	road.force_close = true
	var road_mesh := road.call("_build_mesh") as ArrayMesh
	var body_top_vertices := _unique_top_vertices(body_mesh, 3.0)
	var road_vertices := _unique_vertices(road_mesh)
	for vertex in road_vertices:
		assert_true(_has_matching_vertex(vertex, body_top_vertices), "Track body side face should sit exactly under the road edge")
	road.queue_free()

func test_road_mesh_adds_invisible_support_collision_under_surface() -> void:
	var road := RoadMeshScript.new()
	road.points = [
		Vector3(-10, 3.0, 0),
		Vector3(0, 3.8, 12),
		Vector3(12, 3.2, 18),
	]
	road.width = 10.0
	road.force_close = false
	var collision_body := StaticBody3D.new()
	collision_body.name = "CollisionBody"
	var collision_shape := CollisionShape3D.new()
	collision_shape.name = "CollisionShape3D"
	collision_body.add_child(collision_shape)
	road.add_child(collision_body)
	add_child(road)
	road.call("_rebuild")
	var support := road.get_node_or_null("RoadSupportCollision")
	assert_true(support != null, "Road mesh should build invisible support collision under the thin trimesh road")
	if support != null:
		assert_equal(support.get_child_count(), 2, "Open road support should add one support slab per road segment")
		var support_body := support.get_child(0) as StaticBody3D
		assert_true(support_body != null, "Support slab should be a static collision body")
		if support_body != null:
			assert_equal(support_body.collision_layer, 1, "Support slab should collide on the world layer")
			assert_equal(support_body.collision_mask, 2, "Support slab should only need to scan for kart bodies")
			var support_shape := support_body.get_node_or_null("CollisionShape3D") as CollisionShape3D
			assert_true(support_shape != null and support_shape.shape is BoxShape3D, "Support slab should use a box shape with physical thickness")
	road.queue_free()

func test_road_support_collision_basis_keeps_surface_normal_upward() -> void:
	var basis := RoadMeshScript.support_collision_basis(Vector3(4.0, 1.0, 8.0))
	assert_true(basis.y.dot(Vector3.UP) > 0.9, "Support slab local up should stay close to world up on normal road slopes")
	assert_true(absf(basis.z.normalized().dot(Vector3(4.0, 1.0, 8.0).normalized())) > 0.99, "Support slab local depth should follow the route segment")

func _unique_top_vertices(mesh: ArrayMesh, min_y: float) -> Array[Vector3]:
	var out: Array[Vector3] = []
	var arrays := mesh.surface_get_arrays(0)
	var vertices := arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
	for vertex in vertices:
		if vertex.y >= min_y:
			_add_unique_vertex(out, vertex)
	return out

func _unique_vertices(mesh: ArrayMesh) -> Array[Vector3]:
	var out: Array[Vector3] = []
	var arrays := mesh.surface_get_arrays(0)
	var vertices := arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
	for vertex in vertices:
		_add_unique_vertex(out, vertex)
	return out

func _add_unique_vertex(vertices: Array[Vector3], candidate: Vector3) -> void:
	for vertex in vertices:
		if vertex.distance_to(candidate) <= 0.001:
			return
	vertices.append(candidate)

func _has_matching_vertex(candidate: Vector3, vertices: Array[Vector3]) -> bool:
	for vertex in vertices:
		if vertex.distance_to(candidate) <= 0.001:
			return true
	return false
