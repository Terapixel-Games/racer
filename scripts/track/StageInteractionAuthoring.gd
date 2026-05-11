@tool
extends Area3D
class_name StageInteractionAuthoring

const PREVIEW_NAME := "CollisionShape3D"

@export var interaction_id := ""
@export_enum("boost", "slow", "impulse", "rumble", "trigger") var action := "boost"
@export_enum("box", "sphere") var shape := "box":
	set(value):
		shape = value
		_sync_shape()
@export var size := Vector3(16.0, 4.0, 16.0):
	set(value):
		size = Vector3(maxf(value.x, 0.1), maxf(value.y, 0.1), maxf(value.z, 0.1))
		_sync_shape()
@export var radius := 8.0:
	set(value):
		radius = maxf(value, 0.1)
		_sync_shape()
@export var duration := 0.8
@export var cooldown := 1.0
@export var boost_force := 82.0
@export_range(0.2, 2.0, 0.01) var speed_multiplier := 0.72
@export var impulse := Vector3.ZERO
@export var intensity := 1.0
@export_node_path("Node3D") var target_node_path: NodePath
@export var target_method := "trigger"
@export var note := ""

func _ready() -> void:
	monitoring = false
	monitorable = false
	_sync_shape()

func to_stage_interaction() -> Dictionary:
	return {
		"id": interaction_id if not interaction_id.strip_edges().is_empty() else str(name),
		"action": action,
		"shape": shape,
		"position": [position.x, position.y, position.z],
		"yaw_degrees": rotation_degrees.y,
		"size": [size.x, size.y, size.z],
		"radius": radius,
		"duration": duration,
		"cooldown": cooldown,
		"boost_force": boost_force,
		"speed_multiplier": speed_multiplier,
		"impulse": [impulse.x, impulse.y, impulse.z],
		"intensity": intensity,
		"target_node_path": str(target_node_path),
		"target_method": target_method,
		"note": note,
	}

func _sync_shape() -> void:
	if not is_inside_tree() and get_child_count() == 0:
		return
	var shape_node := get_node_or_null(PREVIEW_NAME) as CollisionShape3D
	if shape_node == null:
		shape_node = CollisionShape3D.new()
		shape_node.name = PREVIEW_NAME
		add_child(shape_node)
		if owner != null:
			shape_node.owner = owner
	if shape == "sphere":
		var sphere := shape_node.shape as SphereShape3D
		if sphere == null:
			sphere = SphereShape3D.new()
			sphere.resource_local_to_scene = true
			shape_node.shape = sphere
		sphere.radius = radius
	else:
		var box := shape_node.shape as BoxShape3D
		if box == null:
			box = BoxShape3D.new()
			box.resource_local_to_scene = true
			shape_node.shape = box
		box.size = size
