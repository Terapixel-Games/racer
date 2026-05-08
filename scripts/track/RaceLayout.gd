extends RefCounted
class_name RaceLayout

var source := ""
var road_visual_style := ""
var road_grid_layout: Dictionary = {}
var road_segment_layout: Array[Dictionary] = []
var route_points: Array[Vector3] = []
var checkpoint_indices: Array[int] = []
var lap_gate_checkpoint_index := 0
var spawn_points: Array[Vector4] = []
var item_sockets: Array[Vector4] = []
var hazard_sockets: Array[Vector4] = []

func is_valid() -> bool:
	return route_points.size() >= 3

func has_grid() -> bool:
	return not road_grid_layout.is_empty()

func has_segments() -> bool:
	return not road_segment_layout.is_empty()

