@tool
extends SceneTree

const TrackCatalog = preload("res://scripts/track/TrackCatalog.gd")
const TrackMetadataExporter = preload("res://scripts/track/TrackMetadataExporter.gd")
const TrackSceneAuthoringData = preload("res://scripts/track/TrackSceneAuthoringData.gd")
const RoadGridMapAuthoring = preload("res://scripts/track/RoadGridMapAuthoring.gd")
const TrackGridRoadBuilder = preload("res://scripts/track/TrackGridRoadBuilder.gd")

const MESH_LIBRARY_PATH := "res://assets/source/kenney/racing_kit/racer_road_mesh_library.tres"
const KITCHEN_SCENE_PATH := "res://assets/gameplay/tracks/kitchen/kitchen_editable_room.tscn"
const GRID_CELL_SIZE := Vector3(16.0, 4.0, 16.0)
const GRID_ROAD_WIDTH := 12.0

func _init() -> void:
	var mesh_error := _ensure_mesh_library()
	if mesh_error != OK:
		printerr("[KitchenGridRoad] failed to save mesh library: %s" % mesh_error)
		quit(1)
		return
	var scene_errors := _build_kitchen_grid_scene()
	if not scene_errors.is_empty():
		for error in scene_errors:
			printerr("[KitchenGridRoad] %s" % error)
		quit(1)
		return
	var export_error := _export_kitchen_definition()
	if export_error != OK:
		printerr("[KitchenGridRoad] failed to export Kitchen definition/metadata: %s" % export_error)
		quit(1)
		return
	print("[KitchenGridRoad] Kitchen RoadGridMap pilot created")
	quit()

func _ensure_mesh_library() -> Error:
	var library := MeshLibrary.new()
	_add_mesh_item(library, TrackGridRoadBuilder.TILE_STRAIGHT, "roadStraight", "res://assets/source/kenney/racing_kit/roadStraight.glb")
	_add_mesh_item(library, TrackGridRoadBuilder.TILE_CORNER, "roadCornerSmall", "res://assets/source/kenney/racing_kit/roadCornerSmall.glb")
	_add_mesh_item(library, TrackGridRoadBuilder.TILE_START, "roadStart", "res://assets/source/kenney/racing_kit/roadStart.glb")
	_add_mesh_item(library, TrackGridRoadBuilder.TILE_STRAIGHT_LONG, "roadStraightLong", "res://assets/source/kenney/racing_kit/roadStraightLong.glb")
	_add_mesh_item(library, TrackGridRoadBuilder.TILE_CORNER_LARGE, "roadCornerLarge", "res://assets/source/kenney/racing_kit/roadCornerLarge.glb")
	return ResourceSaver.save(library, MESH_LIBRARY_PATH)

func _add_mesh_item(library: MeshLibrary, id: int, item_name: String, scene_path: String) -> void:
	var packed := load(scene_path) as PackedScene
	if packed == null:
		push_error("Missing Kenney road scene: %s" % scene_path)
		return
	var root := packed.instantiate()
	var mesh := _first_mesh(root)
	if mesh == null:
		push_error("Kenney road scene has no mesh: %s" % scene_path)
		root.queue_free()
		return
	library.create_item(id)
	library.set_item_name(id, item_name)
	library.set_item_mesh(id, mesh)
	var bounds := _combined_bounds(root)
	var scale := Vector3(
		GRID_ROAD_WIDTH / maxf(bounds.size.x, 0.001),
		1.0,
		GRID_CELL_SIZE.z / maxf(bounds.size.z, 0.001)
	)
	if item_name == "roadCornerSmall":
		scale = Vector3(
			GRID_CELL_SIZE.x / maxf(bounds.size.x, 0.001),
			1.0,
			GRID_CELL_SIZE.z / maxf(bounds.size.z, 0.001)
		)
	elif item_name == "roadCornerLarge":
		scale = Vector3(
			(GRID_CELL_SIZE.x * 2.0) / maxf(bounds.size.x, 0.001),
			1.0,
			(GRID_CELL_SIZE.z * 2.0) / maxf(bounds.size.z, 0.001)
		)
	elif item_name == "roadStraightLong" or item_name == "roadStart":
		scale = Vector3(
			GRID_ROAD_WIDTH / maxf(bounds.size.x, 0.001),
			1.0,
			(GRID_CELL_SIZE.z * 2.0) / maxf(bounds.size.z, 0.001)
		)
	var basis := Basis.from_scale(scale)
	library.set_item_mesh_transform(id, Transform3D(basis, _center_offset_for_item(id) - basis * bounds.get_center()))
	root.queue_free()

func _first_mesh(node: Node) -> Mesh:
	if node is MeshInstance3D:
		return (node as MeshInstance3D).mesh
	for child in node.get_children():
		var found := _first_mesh(child)
		if found != null:
			return found
	return null

func _combined_bounds(node: Node) -> AABB:
	var found := false
	var out := AABB()
	for child in node.find_children("*", "MeshInstance3D", true, false):
		var mesh_node := child as MeshInstance3D
		var local_aabb := mesh_node.get_aabb()
		var corners := [
			local_aabb.position,
			local_aabb.position + Vector3(local_aabb.size.x, 0.0, 0.0),
			local_aabb.position + Vector3(0.0, local_aabb.size.y, 0.0),
			local_aabb.position + Vector3(0.0, 0.0, local_aabb.size.z),
			local_aabb.position + Vector3(local_aabb.size.x, local_aabb.size.y, 0.0),
			local_aabb.position + Vector3(local_aabb.size.x, 0.0, local_aabb.size.z),
			local_aabb.position + Vector3(0.0, local_aabb.size.y, local_aabb.size.z),
			local_aabb.end,
		]
		for corner in corners:
			var point: Vector3 = mesh_node.transform * corner
			if not found:
				out = AABB(point, Vector3.ZERO)
				found = true
			else:
				out = out.expand(point)
	return out

func _build_kitchen_grid_scene() -> Array[String]:
	var packed := load(KITCHEN_SCENE_PATH) as PackedScene
	if packed == null:
		return ["Could not load %s" % KITCHEN_SCENE_PATH]
	var root := packed.instantiate() as Node3D
	if root == null:
		return ["Kitchen scene root is not Node3D"]
	var track := _get_or_create_track_node(root)
	var existing := _find_node(root, "RoadGridMap")
	if existing != null:
		existing.get_parent().remove_child(existing)
		existing.queue_free()
	var grid := RoadGridMapAuthoring.new()
	grid.name = "RoadGridMap"
	grid.mesh_library = load(MESH_LIBRARY_PATH) as MeshLibrary
	grid.cell_size = GRID_CELL_SIZE
	grid.position = Vector3(0.0, 12.25, 0.0)
	grid.road_width_override = GRID_ROAD_WIDTH
	var route := _kitchen_loop_cells()
	grid.ordered_route_cells = route
	grid.checkpoint_route_indices = [0, 8, 16, 24, 32, 40]
	grid.item_route_indices = [4, 8, 12, 16, 20, 24, 28, 32, 36, 44]
	grid.hazard_route_indices = [6, 14, 22, 26, 30, 34, 38, 42]
	var skip_next := false
	for i in range(route.size()):
		if skip_next:
			skip_next = false
			continue
		var cell := route[i]
		var tile := _visual_tile_for_route_index(route, i)
		grid.set_cell_item(cell, tile, _orientation_for_route_index(route, i))
		skip_next = tile == TrackGridRoadBuilder.TILE_STRAIGHT_LONG or tile == TrackGridRoadBuilder.TILE_START
	track.add_child(grid)
	grid.owner = root
	var new_packed := PackedScene.new()
	var pack_error := new_packed.pack(root)
	if pack_error != OK:
		root.queue_free()
		return ["Could not pack Kitchen scene: %s" % pack_error]
	var save_error := ResourceSaver.save(new_packed, KITCHEN_SCENE_PATH)
	root.queue_free()
	if save_error != OK:
		return ["Could not save Kitchen scene: %s" % save_error]
	return []

func _get_or_create_track_node(root: Node3D) -> Node3D:
	var track := root.get_node_or_null("Track") as Node3D
	if track != null:
		return track
	track = Node3D.new()
	track.name = "Track"
	root.add_child(track)
	track.owner = root
	return track

func _find_node(root: Node, node_name: String) -> Node:
	var direct := root.get_node_or_null(node_name)
	if direct != null:
		return direct
	return root.find_child(node_name, true, false)

func _export_kitchen_definition() -> Error:
	var definition_path := TrackCatalog.get_definition_path("kitchen")
	var source := TrackCatalog.get_definition("kitchen")
	if source == null:
		return ERR_CANT_OPEN
	var generated := TrackSceneAuthoringData.apply_to_definition(source)
	var errors := generated.validate()
	if not errors.is_empty():
		push_error("Generated Kitchen grid definition is invalid: %s" % "; ".join(errors))
		return ERR_INVALID_DATA
	var save_error := ResourceSaver.save(generated, definition_path)
	if save_error != OK:
		return save_error
	return TrackMetadataExporter.save_json(generated, TrackCatalog.get_metadata_path("kitchen"))

func _kitchen_loop_cells() -> Array[Vector3i]:
	var cells: Array[Vector3i] = []
	for x in range(-7, 8):
		cells.append(Vector3i(x, 0, -5))
	for z in range(-4, 6):
		cells.append(Vector3i(7, 0, z))
	for x in range(6, -8, -1):
		cells.append(Vector3i(x, 0, 5))
	for z in range(4, -5, -1):
		cells.append(Vector3i(-7, 0, z))
	return cells

func _tile_for_route_index(route: Array[Vector3i], index: int) -> int:
	var previous := route[(index - 1 + route.size()) % route.size()]
	var current := route[index]
	var next := route[(index + 1) % route.size()]
	var incoming := current - previous
	var outgoing := next - current
	return TrackGridRoadBuilder.TILE_CORNER if incoming != outgoing else TrackGridRoadBuilder.TILE_STRAIGHT

func _visual_tile_for_route_index(route: Array[Vector3i], index: int) -> int:
	var route_tile := _tile_for_route_index(route, index)
	if route_tile == TrackGridRoadBuilder.TILE_CORNER:
		return TrackGridRoadBuilder.TILE_CORNER
	if index == 1 and _can_place_long_straight(route, index):
		return TrackGridRoadBuilder.TILE_START
	if _can_place_long_straight(route, index):
		return TrackGridRoadBuilder.TILE_STRAIGHT_LONG
	return TrackGridRoadBuilder.TILE_STRAIGHT

func _can_place_long_straight(route: Array[Vector3i], index: int) -> bool:
	if _tile_for_route_index(route, index) != TrackGridRoadBuilder.TILE_STRAIGHT:
		return false
	var next_index := (index + 1) % route.size()
	if _tile_for_route_index(route, next_index) != TrackGridRoadBuilder.TILE_STRAIGHT:
		return false
	var current := route[index]
	var next := route[next_index]
	var after := route[(index + 2) % route.size()]
	return next - current == after - next

func _orientation_for_route_index(route: Array[Vector3i], index: int) -> int:
	if _tile_for_route_index(route, index) == TrackGridRoadBuilder.TILE_CORNER:
		return _corner_orientation_for_route_index(route, index)
	var current := route[index]
	var next := route[(index + 1) % route.size()]
	var outgoing := next - current
	return _orientation_for_direction(outgoing)

func _corner_orientation_for_route_index(route: Array[Vector3i], index: int) -> int:
	var previous := route[(index - 1 + route.size()) % route.size()]
	var current := route[index]
	var next := route[(index + 1) % route.size()]
	var incoming := current - previous
	var outgoing := next - current
	var yaw := 0.0
	if incoming.x > 0 and outgoing.z > 0:
		yaw = 0.0
	elif incoming.z > 0 and outgoing.x < 0:
		yaw = 270.0
	elif incoming.x < 0 and outgoing.z < 0:
		yaw = 180.0
	elif incoming.z < 0 and outgoing.x > 0:
		yaw = 90.0
	else:
		return _orientation_for_direction(outgoing)
	return _orthogonal_orientation_for_yaw(yaw)

func _orientation_for_direction(direction: Vector3i) -> int:
	var yaw := 0.0
	if abs(direction.x) > abs(direction.z):
		yaw = 90.0 if direction.x > 0 else 270.0
	else:
		yaw = 0.0 if direction.z > 0 else 180.0
	return _orthogonal_orientation_for_yaw(yaw)

func _orthogonal_orientation_for_yaw(yaw: float) -> int:
	var grid := GridMap.new()
	var orientation := grid.get_orthogonal_index_from_basis(Basis(Vector3.UP, deg_to_rad(yaw)))
	grid.free()
	return orientation

func _center_offset_for_item(item: int) -> Vector3:
	if item == TrackGridRoadBuilder.TILE_STRAIGHT_LONG or item == TrackGridRoadBuilder.TILE_START:
		return Vector3(0.0, 0.0, GRID_CELL_SIZE.z * 0.5)
	if item == TrackGridRoadBuilder.TILE_CORNER_LARGE:
		return Vector3(GRID_CELL_SIZE.x * 0.5, 0.0, GRID_CELL_SIZE.z * 0.5)
	return Vector3.ZERO
