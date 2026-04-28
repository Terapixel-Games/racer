extends "res://tests/framework/TestCase.gd"

const TrackWalls = preload("res://scripts/TrackWalls.gd")

func test_wall_collision_matches_visible_wall_meshes() -> void:
	var holder := Node3D.new()
	scene_tree.root.add_child(holder)
	var points := PackedVector3Array([
		Vector3(0, 0.55, -20),
		Vector3(20, 0.55, 0),
		Vector3(0, 0.55, 20),
		Vector3(-20, 0.55, 0),
	])
	var walls := TrackWalls.build_walls(holder, points, 6.0, 1.6, 0.45, false, true, true)
	for side in ["left", "right"]:
		var wall := walls.get(side, null) as MeshInstance3D
		assert_true(wall != null, "%s wall mesh should exist" % side)
		if wall == null:
			continue
		assert_true(wall.find_child("CollisionStrip00", true, false) == null, "%s wall should not use hidden box strip collisions" % side)
		var body := wall.get_node_or_null("CollisionBody") as StaticBody3D
		assert_true(body != null, "%s wall should have collision body tied to the visible mesh" % side)
		if body == null:
			continue
		var shape_node := body.get_node_or_null("CollisionShape3D") as CollisionShape3D
		assert_true(shape_node != null, "%s wall should have a collision shape" % side)
		if shape_node != null:
			assert_true(shape_node.shape is ConcavePolygonShape3D, "%s wall collision should be visible mesh collision" % side)
			if shape_node.shape is ConcavePolygonShape3D:
				assert_true((shape_node.shape as ConcavePolygonShape3D).backface_collision, "%s wall collision should work from the road side" % side)
	holder.queue_free()

func test_grade_separated_crossings_open_wall_gaps() -> void:
	var points := PackedVector3Array([
		Vector3(-10, 0.0, 0),
		Vector3(10, 0.0, 0),
		Vector3(10, 2.4, 10),
		Vector3(-10, 2.4, -10),
	])
	var gaps := TrackWalls.detect_grade_separated_crossing_segments(points, true, 1.8)
	assert_equal(gaps, [0, 2], "Grade-separated XZ crossings should open the involved rail segments")

	var holder := Node3D.new()
	scene_tree.root.add_child(holder)
	var walls := TrackWalls.build_walls(holder, points, 3.0, 1.4, 0.4, false, true, false, gaps)
	var wall := walls.get("left", null) as MeshInstance3D
	assert_true(wall != null, "Wall mesh should still be created when gaps are present")
	if wall != null and wall.mesh != null:
		var arrays := wall.mesh.surface_get_arrays(0)
		var indices := arrays[Mesh.ARRAY_INDEX] as PackedInt32Array
		assert_equal(indices.size(), 12, "Closed four-segment wall with two gaps should only render two segments")
	holder.queue_free()
