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

func test_road_collision_uses_layered_road_surfaces_without_support_boxes() -> void:
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
	assert_true(road.get_node_or_null("RoadSupportCollision") == null, "Road collision should not add invisible support boxes that can catch karts at seams")
	var shape := collision_shape.shape as ConcavePolygonShape3D
	assert_true(shape != null, "Road collision should still use generated trimesh collision")
	if shape != null:
		assert_true(shape.backface_collision, "Layered road collision should still catch probes from below")
		var collision_mesh := RoadMeshScript.build_layered_collision_mesh(road.call("_build_mesh") as Mesh, 3, 0.16)
		assert_equal(_vertex_count(collision_mesh), _vertex_count(road.call("_build_mesh") as Mesh) * 3, "Layered road collision should add backup road planes without box end caps")
	assert_true(collision_body.physics_material_override != null, "Road collision should apply a physics material")
	if collision_body.physics_material_override != null:
		assert_true(collision_body.physics_material_override.friction <= 0.1, "Road collision should stay slick enough to avoid snagging karts on high-contact seams")
	road.queue_free()

func test_layered_collision_mesh_offsets_backup_layers_downward() -> void:
	var road := RoadMeshScript.new()
	road.points = [Vector3(0, 3.0, 0), Vector3(0, 4.0, 12)]
	road.width = 8.0
	road.force_close = false
	var source_mesh := road.call("_build_mesh") as Mesh
	var collision_mesh := RoadMeshScript.build_layered_collision_mesh(source_mesh, 3, 0.16)
	var source_vertices := source_mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array
	var collision_vertices := collision_mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array
	assert_true(absf(collision_vertices[source_vertices.size()].y - (source_vertices[0].y - 0.16)) <= 0.001, "Second collision layer should sit just below the visual road")
	assert_true(absf(collision_vertices[source_vertices.size() * 2].y - (source_vertices[0].y - 0.32)) <= 0.001, "Third collision layer should sit below the second backup layer")
	road.queue_free()

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

func _vertex_count(mesh: Mesh) -> int:
	if mesh == null or mesh.get_surface_count() <= 0:
		return 0
	var arrays := mesh.surface_get_arrays(0)
	var vertices := arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
	return vertices.size()

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
