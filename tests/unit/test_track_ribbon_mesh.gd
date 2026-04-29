extends "res://tests/framework/TestCase.gd"

const TrackRibbonMesh = preload("res://scripts/track/TrackRibbonMesh.gd")

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
