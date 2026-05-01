@tool
extends Marker3D
class_name GrassZoneAuthoring

@export var zone_id := ""
@export var size := Vector2(80.0, 60.0)
@export_range(0.0, 3.0, 0.05) var density := 1.0
@export var enabled := true

func to_grass_zone() -> Dictionary:
	return {
		"id": zone_id if not zone_id.strip_edges().is_empty() else str(name),
		"position": [position.x, position.y, position.z],
		"yaw_degrees": rotation_degrees.y,
		"size": [size.x, size.y],
		"density": density,
		"enabled": enabled,
	}
