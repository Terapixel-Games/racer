extends RefCounted
class_name PlayerTrackBuildRules

const PlayerTrackBuild = preload("res://scripts/track_builder/PlayerTrackBuild.gd")
const TrackDefinition = preload("res://scripts/track/TrackDefinition.gd")
const TrackGridRoadBuilder = preload("res://scripts/track/TrackGridRoadBuilder.gd")

const PIECE_STRAIGHT := "straight"
const PIECE_CORNER := "corner"
const PIECE_RAMP := "ramp"
const PIECE_BRIDGE := "bridge"
const PIECE_LANDING := "landing"
const PIECE_GUARD := "guard"
const PIECE_CONNECTOR := "connector"
const PIECE_ENDPOINT := "endpoint"
const NAVIGATION_VALID := "navigation_valid"
const RACE_VALID := "race_valid"
const INVALID := "invalid"
const DEFAULT_HOME_MAP_ID := "home_yard_v3"
const DEFAULT_PIECE_LIBRARY_VERSION := "home_builder_v1"
const DEFAULT_CELL_SIZE := Vector3(16.0, 4.0, 16.0)
const DEFAULT_ROAD_WIDTH := 12.0
const DEFAULT_MAX_PIECES := 160
const MAX_GRID_EXTENT := 64

static func allowed_piece_ids() -> Array[String]:
	return [
		PIECE_STRAIGHT,
		PIECE_CORNER,
		PIECE_RAMP,
		PIECE_BRIDGE,
		PIECE_LANDING,
		PIECE_GUARD,
		PIECE_CONNECTOR,
		PIECE_ENDPOINT,
	]

static func piece_inventory() -> Dictionary:
	return {
		PIECE_STRAIGHT: {"limit": 64, "item": TrackGridRoadBuilder.TILE_STRAIGHT},
		PIECE_CORNER: {"limit": 48, "item": TrackGridRoadBuilder.TILE_CORNER},
		PIECE_RAMP: {"limit": 24, "item": TrackGridRoadBuilder.TILE_RAMP},
		PIECE_BRIDGE: {"limit": 24, "item": TrackGridRoadBuilder.TILE_STRAIGHT_LONG},
		PIECE_LANDING: {"limit": 32, "item": TrackGridRoadBuilder.TILE_STRAIGHT},
		PIECE_GUARD: {"limit": 64, "item": TrackGridRoadBuilder.TILE_STRAIGHT},
		PIECE_CONNECTOR: {"limit": 32, "item": TrackGridRoadBuilder.TILE_STRAIGHT},
		PIECE_ENDPOINT: {"limit": 8, "item": TrackGridRoadBuilder.TILE_START},
	}

static func empty_build(owner_user_id := "", home_map_id := DEFAULT_HOME_MAP_ID) -> PlayerTrackBuild:
	var build := PlayerTrackBuild.new()
	build.owner_user_id = owner_user_id
	build.home_map_id = home_map_id
	build.piece_library_version = DEFAULT_PIECE_LIBRARY_VERSION
	build.piece_inventory = piece_inventory()
	return build

static func normalize_piece(piece: Dictionary) -> Dictionary:
	var id := str(piece.get("id", "")).strip_edges()
	var type := str(piece.get("piece_id", piece.get("type", PIECE_STRAIGHT))).strip_edges().to_lower()
	if not allowed_piece_ids().has(type):
		type = PIECE_STRAIGHT
	var cell := _vector3i_from_value(piece.get("cell", Vector3i.ZERO))
	var yaw_steps := posmod(int(piece.get("yaw_steps", piece.get("rotation", 0))), 4)
	return {
		"id": id,
		"piece_id": type,
		"cell": cell,
		"yaw_steps": yaw_steps,
		"anchor_id": str(piece.get("anchor_id", "")),
	}

static func snapped_cell(world_position: Vector3, origin := Vector3.ZERO, cell_size := DEFAULT_CELL_SIZE) -> Vector3i:
	var local := world_position - origin
	return Vector3i(
		floori(local.x / maxf(cell_size.x, 0.001)),
		floori(local.y / maxf(cell_size.y, 0.001)),
		floori(local.z / maxf(cell_size.z, 0.001))
	)

static func add_or_replace_piece(build: PlayerTrackBuild, piece: Dictionary) -> Dictionary:
	var normalized := normalize_piece(piece)
	if str(normalized.get("id", "")).is_empty():
		normalized["id"] = "piece_%03d" % (build.pieces.size() + 1)
	var target_cell := normalized.get("cell", Vector3i.ZERO) as Vector3i
	for i in range(build.pieces.size()):
		var existing := normalize_piece(build.pieces[i])
		if (existing.get("cell", Vector3i.ZERO) as Vector3i) == target_cell:
			build.pieces[i] = normalized
			return normalized
	build.pieces.append(normalized)
	return normalized

static func remove_piece_at_cell(build: PlayerTrackBuild, cell: Vector3i) -> bool:
	for i in range(build.pieces.size()):
		var existing := normalize_piece(build.pieces[i])
		if (existing.get("cell", Vector3i.ZERO) as Vector3i) == cell:
			build.pieces.remove_at(i)
			return true
	return false

static func validate_navigation(build: PlayerTrackBuild, protected_zones: Array[Dictionary] = []) -> Dictionary:
	var errors: Array[String] = _common_build_errors(build)
	var cells := _piece_cell_set(build.pieces)
	var drivable_cells := _drivable_cells(build.pieces)
	if drivable_cells.size() < 2:
		errors.append("Build needs at least two drivable pieces for navigation.")
	if drivable_cells.size() >= 2 and not _drivable_cells_are_connected(drivable_cells):
		errors.append("Build has disconnected drivable pieces.")
	errors.append_array(_protected_zone_errors(build, protected_zones))
	var status := NAVIGATION_VALID if errors.is_empty() else INVALID
	build.navigation_status = status
	build.validation_errors = errors
	build.route_cells = _ordered_navigation_cells(build)
	build.route_points = route_points_from_cells(build.route_cells)
	return {"status": status, "errors": errors, "route_cells": build.route_cells.duplicate(), "route_points": build.route_points.duplicate()}

static func validate_race(build: PlayerTrackBuild, protected_zones: Array[Dictionary] = []) -> Dictionary:
	var navigation := validate_navigation(build, protected_zones)
	var errors: Array[String] = []
	for error in navigation.get("errors", []):
		errors.append(str(error))
	var route_cells := build.route_cells
	if route_cells.size() < 4:
		errors.append("Race promotion needs at least four ordered route cells.")
	elif not _route_is_closed_loop(route_cells):
		errors.append("Race promotion needs a closed loop.")
	if route_cells.size() >= 2 and not _start_cell_is_straight(build, route_cells[0], route_cells[1]):
		errors.append("Race promotion start must be on a straight-style piece.")
	var definition := promote_to_track_definition(build, {"skip_validation_status": true})
	if definition != null:
		for error in definition.validate():
			errors.append(error)
	else:
		errors.append("Race promotion could not create a track definition.")
	var status := RACE_VALID if errors.is_empty() else INVALID
	build.race_status = status
	build.validation_errors = errors
	build.promotion_metadata = {
		"eligible": status == RACE_VALID,
		"route_cell_count": route_cells.size(),
		"checkpoint_count": maxi(0, _checkpoint_indices(route_cells.size()).size()),
	}
	return {"status": status, "errors": errors, "promotion_metadata": build.promotion_metadata.duplicate(true)}

static func promote_to_track_definition(build: PlayerTrackBuild, options: Dictionary = {}) -> TrackDefinition:
	if build == null:
		return null
	var skip_status := bool(options.get("skip_validation_status", false))
	if not skip_status and validate_race(build).get("status", INVALID) != RACE_VALID:
		return null
	var route_cells := build.route_cells if not build.route_cells.is_empty() else _ordered_navigation_cells(build)
	if route_cells.size() < 3:
		return null
	var layout := to_grid_layout(build, route_cells)
	var route_points := TrackGridRoadBuilder.route_points_from_grid_layout(layout, true)
	var definition := TrackDefinition.new()
	definition.id = str(options.get("track_id", _promoted_track_id(build)))
	definition.display_name = str(options.get("display_name", build.display_name))
	definition.version = str(options.get("version", "%s_%s" % [build.piece_library_version, build.home_map_version])).strip_edges()
	definition.laps = int(options.get("laps", 2))
	definition.track_source_id = "road_grid_map"
	definition.road_visual_style = "kenney_gridmap"
	definition.closed_loop = true
	definition.boundary_walls_enabled = true
	definition.reset_mode = "instant_pop"
	definition.out_of_bounds_y = float(options.get("out_of_bounds_y", -20.0))
	definition.road_width = DEFAULT_ROAD_WIDTH
	definition.road_grid_layout = layout
	definition.route_points = route_points
	definition.checkpoint_indices = TrackGridRoadBuilder.checkpoint_indices_from_grid_layout(layout, route_points)
	definition.lap_gate_checkpoint_index = 0
	definition.spawn_points = TrackGridRoadBuilder.spawn_points_from_grid_layout(layout, route_points)
	definition.dressing_scene_path = str(options.get("dressing_scene_path", ""))
	definition.set_meta("player_build_id", build.build_id)
	definition.set_meta("track_map_id", build.home_map_id)
	definition.set_meta("track_mode_id", definition.id)
	return definition

static func to_grid_layout(build: PlayerTrackBuild, route_cells: Array[Vector3i] = []) -> Dictionary:
	var ordered := route_cells if not route_cells.is_empty() else _ordered_navigation_cells(build)
	var cell_data: Array[Dictionary] = []
	for piece_value in build.pieces:
		var piece := normalize_piece(piece_value)
		var cell := piece.get("cell", Vector3i.ZERO) as Vector3i
		if not ordered.has(cell):
			continue
		var item := _grid_item_for_piece(str(piece.get("piece_id", PIECE_STRAIGHT)))
		var basis := _basis_for_yaw_steps(int(piece.get("yaw_steps", 0)))
		cell_data.append({
			"cell": cell,
			"item": item,
			"orientation": 0,
			"orientation_basis": _basis_to_array(basis),
			"position": _cell_center(cell),
		})
	cell_data.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return _sort_cell(a.get("cell", Vector3i.ZERO), b.get("cell", Vector3i.ZERO))
	)
	return {
		"origin": Vector3.ZERO,
		"basis": _basis_to_array(Basis.IDENTITY),
		"cell_size": DEFAULT_CELL_SIZE,
		"mesh_library_path": TrackGridRoadBuilder.DEFAULT_MESH_LIBRARY_PATH,
		"road_width": DEFAULT_ROAD_WIDTH,
		"cells": cell_data,
		"ordered_route_cells": ordered.duplicate(),
		"ordered_route_points": route_points_from_cells(ordered),
		"checkpoint_route_indices": _checkpoint_indices(ordered.size()),
		"spawn_slots": [],
		"item_route_indices": [],
		"hazard_route_indices": [],
	}

static func build_overlay_node(build: PlayerTrackBuild) -> Node3D:
	var holder := Node3D.new()
	holder.name = "PlayerBuiltTrack"
	var validation := validate_navigation(build)
	if validation.get("status", INVALID) == NAVIGATION_VALID:
		holder.add_child(TrackGridRoadBuilder.build_grid_road(to_grid_layout(build, build.route_cells)))
	return holder

static func route_points_from_cells(cells: Array[Vector3i]) -> Array[Vector3]:
	var out: Array[Vector3] = []
	for cell in cells:
		out.append(_cell_center(cell))
	return out

static func _common_build_errors(build: PlayerTrackBuild) -> Array[String]:
	var errors: Array[String] = []
	if build == null:
		return ["Build is required."]
	if build.schema_version != PlayerTrackBuild.SCHEMA_VERSION:
		errors.append("Unsupported player build schema version.")
	if build.home_map_id.strip_edges().is_empty():
		errors.append("Home map id is required.")
	if build.piece_library_version != DEFAULT_PIECE_LIBRARY_VERSION:
		errors.append("Unsupported piece library version.")
	if build.pieces.size() > DEFAULT_MAX_PIECES:
		errors.append("Build has too many pieces.")
	var seen := {}
	var inventory := piece_inventory()
	var counts := {}
	for i in range(build.pieces.size()):
		var piece := normalize_piece(build.pieces[i])
		var piece_id := str(piece.get("piece_id", ""))
		if not inventory.has(piece_id):
			errors.append("Piece %d uses an unsupported piece id." % i)
		counts[piece_id] = int(counts.get(piece_id, 0)) + 1
		var cell := piece.get("cell", Vector3i.ZERO) as Vector3i
		if absi(cell.x) > MAX_GRID_EXTENT or absi(cell.y) > MAX_GRID_EXTENT or absi(cell.z) > MAX_GRID_EXTENT:
			errors.append("Piece %d is outside the build grid." % i)
		var key := "%s:%s:%s" % [cell.x, cell.y, cell.z]
		if seen.has(key):
			errors.append("Multiple pieces occupy cell %s." % key)
		seen[key] = true
	for piece_id in counts.keys():
		var limit := int((inventory.get(piece_id, {}) as Dictionary).get("limit", DEFAULT_MAX_PIECES))
		if int(counts[piece_id]) > limit:
			errors.append("Piece limit exceeded for %s." % piece_id)
	return errors

static func _protected_zone_errors(build: PlayerTrackBuild, protected_zones: Array[Dictionary]) -> Array[String]:
	var errors: Array[String] = []
	for piece_value in build.pieces:
		var piece := normalize_piece(piece_value)
		var center := _cell_center(piece.get("cell", Vector3i.ZERO) as Vector3i)
		for zone in protected_zones:
			var zone_id := str(zone.get("id", "protected_zone"))
			var min_point := _vector3_from_value(zone.get("min", Vector3.ZERO), Vector3.ZERO)
			var max_point := _vector3_from_value(zone.get("max", Vector3.ZERO), Vector3.ZERO)
			var expanded := AABB(min_point, max_point - min_point).abs().grow(float(zone.get("margin", 0.0)))
			if expanded.has_point(center):
				errors.append("Piece %s overlaps protected zone %s." % [str(piece.get("id", "")), zone_id])
	return errors

static func _drivable_cells(pieces: Array[Dictionary]) -> Array[Vector3i]:
	var out: Array[Vector3i] = []
	for piece_value in pieces:
		var piece := normalize_piece(piece_value)
		if str(piece.get("piece_id", "")) == PIECE_GUARD:
			continue
		out.append(piece.get("cell", Vector3i.ZERO) as Vector3i)
	return out

static func _piece_cell_set(pieces: Array[Dictionary]) -> Dictionary:
	var out := {}
	for cell in _drivable_cells(pieces):
		out[cell] = true
	return out

static func _drivable_cells_are_connected(cells: Array[Vector3i]) -> bool:
	if cells.is_empty():
		return false
	var cell_set := {}
	for cell in cells:
		cell_set[cell] = true
	var visited := {}
	var stack: Array[Vector3i] = [cells[0]]
	visited[cells[0]] = true
	while not stack.is_empty():
		var current: Vector3i = stack.pop_back()
		for direction in _cardinal_dirs():
			var next: Vector3i = current + direction
			if cell_set.has(next) and not visited.has(next):
				visited[next] = true
				stack.append(next)
	return visited.size() == cells.size()

static func _ordered_navigation_cells(build: PlayerTrackBuild) -> Array[Vector3i]:
	var cells := _drivable_cells(build.pieces)
	cells.sort_custom(func(a: Vector3i, b: Vector3i) -> bool:
		return _sort_cell(a, b)
	)
	var endpoints: Array[Vector3i] = []
	for piece_value in build.pieces:
		var piece := normalize_piece(piece_value)
		if str(piece.get("piece_id", "")) == PIECE_ENDPOINT:
			endpoints.append(piece.get("cell", Vector3i.ZERO) as Vector3i)
	if endpoints.size() > 0 and cells.has(endpoints[0]):
		return _walk_connected_route(cells, endpoints[0])
	return _walk_connected_route(cells, cells[0] if not cells.is_empty() else Vector3i.ZERO)

static func _walk_connected_route(cells: Array[Vector3i], start: Vector3i) -> Array[Vector3i]:
	if cells.is_empty():
		return []
	var cell_set := {}
	for cell in cells:
		cell_set[cell] = true
	var route: Array[Vector3i] = [start if cell_set.has(start) else cells[0]]
	var previous := Vector3i(99999, 99999, 99999)
	var current := route[0]
	while true:
		var candidates: Array[Vector3i] = []
		for direction in _cardinal_dirs():
			var next := current + direction
			if cell_set.has(next) and next != previous:
				candidates.append(next)
		candidates.sort_custom(func(a: Vector3i, b: Vector3i) -> bool:
			return _sort_cell(a, b)
		)
		var chosen := Vector3i(99999, 99999, 99999)
		for candidate in candidates:
			if candidate == route[0] and route.size() >= cells.size():
				return route
			if not route.has(candidate):
				chosen = candidate
				break
		if chosen == Vector3i(99999, 99999, 99999):
			return route
		route.append(chosen)
		previous = current
		current = chosen
	return route

static func _route_is_closed_loop(route_cells: Array[Vector3i]) -> bool:
	if route_cells.size() < 4:
		return false
	var first := route_cells[0]
	var last := route_cells[route_cells.size() - 1]
	return abs(first.x - last.x) + abs(first.z - last.z) == 1 and first.y == last.y

static func _start_cell_is_straight(build: PlayerTrackBuild, start: Vector3i, next: Vector3i) -> bool:
	for piece_value in build.pieces:
		var piece := normalize_piece(piece_value)
		if (piece.get("cell", Vector3i.ZERO) as Vector3i) != start:
			continue
		var piece_id := str(piece.get("piece_id", ""))
		return piece_id in [PIECE_STRAIGHT, PIECE_BRIDGE, PIECE_LANDING, PIECE_CONNECTOR, PIECE_ENDPOINT]
	return false

static func _checkpoint_indices(route_size: int) -> Array[int]:
	if route_size < 3:
		return []
	return [0, route_size / 3, (route_size * 2) / 3]

static func _grid_item_for_piece(piece_id: String) -> int:
	match piece_id:
		PIECE_CORNER:
			return TrackGridRoadBuilder.TILE_CORNER
		PIECE_RAMP:
			return TrackGridRoadBuilder.TILE_RAMP
		PIECE_BRIDGE:
			return TrackGridRoadBuilder.TILE_STRAIGHT_LONG
		PIECE_ENDPOINT:
			return TrackGridRoadBuilder.TILE_START
		_:
			return TrackGridRoadBuilder.TILE_STRAIGHT

static func _basis_for_yaw_steps(yaw_steps: int) -> Basis:
	return Basis(Vector3.UP, deg_to_rad(float(posmod(yaw_steps, 4)) * 90.0))

static func _cell_center(cell: Vector3i) -> Vector3:
	return Vector3(
		(float(cell.x) + 0.5) * DEFAULT_CELL_SIZE.x,
		(float(cell.y) + 0.5) * DEFAULT_CELL_SIZE.y,
		(float(cell.z) + 0.5) * DEFAULT_CELL_SIZE.z
	)

static func _cardinal_dirs() -> Array[Vector3i]:
	return [Vector3i.RIGHT, Vector3i.FORWARD, Vector3i.LEFT, Vector3i.BACK]

static func _basis_to_array(basis: Basis) -> Array:
	return [
		[basis.x.x, basis.x.y, basis.x.z],
		[basis.y.x, basis.y.y, basis.y.z],
		[basis.z.x, basis.z.y, basis.z.z],
	]

static func _sort_cell(a: Vector3i, b: Vector3i) -> bool:
	if a.y != b.y:
		return a.y < b.y
	if a.z != b.z:
		return a.z < b.z
	return a.x < b.x

static func _promoted_track_id(build: PlayerTrackBuild) -> String:
	var base := build.build_id.strip_edges().to_lower().replace("-", "_")
	if base.is_empty():
		base = "player_home_build"
	return "player_%s" % base

static func _vector3i_from_value(value: Variant) -> Vector3i:
	return PlayerTrackBuild._vector3i_from_value(value)

static func _vector3_from_value(value: Variant, fallback: Vector3) -> Vector3:
	return PlayerTrackBuild._vector3_from_value(value, fallback)
