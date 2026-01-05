extends Node3D

@export var collision_layer: int = 1
@export var collision_mask: int = 1

func _ready() -> void:
	var walls := get_node_or_null("Walls")
	_add_wall_collisions(walls)

func _add_wall_collisions(root: Node) -> void:
	if root == null:
		return
	for child in root.get_children():
		if child is MeshInstance3D:
			_add_collision_for_mesh(child)
		else:
			_add_wall_collisions(child)

func _add_collision_for_mesh(mesh_instance: MeshInstance3D) -> void:
	if mesh_instance.has_meta("skip_auto_collision"):
		return
	var mesh: Mesh = mesh_instance.mesh
	if mesh == null:
		return
	var parent := mesh_instance.get_parent()
	if parent == null:
		return
	var body_name := "%s_Body" % mesh_instance.name
	if parent.has_node(body_name):
		return
	var shape := mesh.create_trimesh_shape()
	if shape == null:
		return
	var body := StaticBody3D.new()
	body.name = body_name
	body.transform = mesh_instance.transform
	body.collision_layer = collision_layer
	body.collision_mask = collision_mask
	var col := CollisionShape3D.new()
	col.name = "AutoCollision"
	col.shape = shape
	body.add_child(col)
	parent.add_child(body)
