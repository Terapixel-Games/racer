@tool
extends Area3D
class_name GrassZoneAuthoring

@export var zone_id := ""
@export var size := Vector2(80.0, 60.0)
@export_range(0.0, 3.0, 0.05) var density := 1.0
@export var enabled := true

func to_grass_zone() -> Dictionary:
	var bounds := _bounds_from_collision_shape()
	var zone_size: Vector2 = bounds.get("size", size)
	var zone_position: Vector3 = bounds.get("position", position)
	var zone_yaw_degrees := float(bounds.get("yaw_degrees", rotation_degrees.y))
	return {
		"id": zone_id if not zone_id.strip_edges().is_empty() else str(name),
		"position": [zone_position.x, zone_position.y, zone_position.z],
		"yaw_degrees": zone_yaw_degrees,
		"size": [zone_size.x, zone_size.y],
		"density": density,
		"enabled": enabled,
	}

func _bounds_from_collision_shape() -> Dictionary:
	var shape_node := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if shape_node == null:
		return {}
	if not (shape_node.shape is BoxShape3D):
		return {}
	var box := shape_node.shape as BoxShape3D
	var shape_scale := shape_node.transform.basis.get_scale().abs()
	var box_size := Vector3(box.size.x * shape_scale.x, box.size.y * shape_scale.y, box.size.z * shape_scale.z)
	var center := position + transform.basis * shape_node.position
	return {
		"position": center,
		"yaw_degrees": rotation_degrees.y + shape_node.rotation_degrees.y,
		"size": Vector2(box_size.x, box_size.z),
	}
