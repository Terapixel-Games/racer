extends Control

var route_points: Array[Vector3] = []
var racer_points: Dictionary = {}
var racer_colors: Dictionary = {}
var local_racer_id := ""

const MAP_PADDING := 14.0
const ROUTE_COLOR := Color(0.78, 0.95, 1.0, 0.82)
const ROUTE_SHADOW_COLOR := Color(0.0, 0.04, 0.08, 0.72)
const RIVAL_COLOR := Color(1.0, 0.92, 0.28, 0.95)
const LOCAL_COLOR := Color(0.0, 0.9, 1.0, 1.0)

func set_race_data(points: Array, racers: Dictionary, colors: Dictionary, local_id: String) -> void:
	route_points.clear()
	for point in points:
		if point is Vector3:
			route_points.append(point)
	racer_points = racers.duplicate()
	racer_colors = colors.duplicate()
	local_racer_id = local_id
	queue_redraw()

func _draw() -> void:
	if route_points.size() < 2:
		_draw_empty_state()
		return
	var bounds := route_bounds(route_points)
	var drawn_points: Array[Vector2] = []
	for point in route_points:
		drawn_points.append(project_world_point(point, bounds, size, MAP_PADDING))
	for i in range(drawn_points.size() - 1):
		draw_line(drawn_points[i], drawn_points[i + 1], ROUTE_SHADOW_COLOR, 7.0, true)
	for i in range(drawn_points.size() - 1):
		draw_line(drawn_points[i], drawn_points[i + 1], ROUTE_COLOR, 3.0, true)
	for rid in racer_points.keys():
		var pos = racer_points[rid]
		if not pos is Vector3:
			continue
		var marker := project_world_point(pos, bounds, size, MAP_PADDING)
		var color: Color = racer_colors.get(rid, RIVAL_COLOR)
		var radius := 6.0
		if str(rid) == local_racer_id:
			color = racer_colors.get(rid, LOCAL_COLOR)
			radius = 8.5
			draw_circle(marker, radius + 3.0, Color(0.0, 0.04, 0.07, 0.8))
		draw_circle(marker, radius, color)
		draw_arc(marker, radius + 1.5, 0.0, TAU, 24, Color(1.0, 1.0, 1.0, 0.74), 1.6, true)

func _draw_empty_state() -> void:
	var center := size * 0.5
	draw_line(Vector2(MAP_PADDING, center.y), Vector2(size.x - MAP_PADDING, center.y), ROUTE_COLOR, 3.0, true)
	draw_circle(center, 6.0, LOCAL_COLOR)

static func route_bounds(points: Array[Vector3]) -> Rect2:
	if points.is_empty():
		return Rect2(Vector2.ZERO, Vector2.ONE)
	var min_x := points[0].x
	var max_x := points[0].x
	var min_z := points[0].z
	var max_z := points[0].z
	for point in points:
		min_x = minf(min_x, point.x)
		max_x = maxf(max_x, point.x)
		min_z = minf(min_z, point.z)
		max_z = maxf(max_z, point.z)
	return Rect2(Vector2(min_x, min_z), Vector2(maxf(max_x - min_x, 0.001), maxf(max_z - min_z, 0.001)))

static func project_world_point(point: Vector3, bounds: Rect2, map_size: Vector2, padding: float) -> Vector2:
	var drawable := Vector2(maxf(map_size.x - padding * 2.0, 1.0), maxf(map_size.y - padding * 2.0, 1.0))
	var ratio := Vector2(
		clampf((point.x - bounds.position.x) / maxf(bounds.size.x, 0.001), 0.0, 1.0),
		clampf((point.z - bounds.position.y) / maxf(bounds.size.y, 0.001), 0.0, 1.0)
	)
	return Vector2(padding + ratio.x * drawable.x, padding + ratio.y * drawable.y)
