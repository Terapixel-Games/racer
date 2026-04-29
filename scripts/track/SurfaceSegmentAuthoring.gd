@tool
extends Marker3D
class_name SurfaceSegmentAuthoring

@export var segment_id := ""
@export var start_route_index := 0
@export var end_route_index := 0
@export var surface_audio_id := ""
@export var surface_material_id := ""

func to_surface_segment() -> Dictionary:
	return {
		"id": segment_id if not segment_id.strip_edges().is_empty() else str(name),
		"start_route_index": start_route_index,
		"end_route_index": end_route_index,
		"surface_audio_id": surface_audio_id,
		"surface_material_id": surface_material_id,
		"position": [position.x, position.y, position.z],
	}
