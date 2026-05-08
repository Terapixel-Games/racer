extends Resource
class_name RoadGridSpawn

@export var route_index := 0
@export var lateral_offset := 0.0
@export var forward_offset := 0.0
@export var y_offset := 0.8
@export var yaw_offset_degrees := 0.0

func to_layout_data() -> Dictionary:
	return {
		"route_index": route_index,
		"lateral_offset": lateral_offset,
		"forward_offset": forward_offset,
		"y_offset": y_offset,
		"yaw_offset_degrees": yaw_offset_degrees,
	}
