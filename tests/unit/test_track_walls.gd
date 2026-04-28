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
