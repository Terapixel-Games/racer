@tool
extends SceneTree

const TrackDefinition = preload("res://scripts/track/TrackDefinition.gd")
const TrackGridRoadBuilder = preload("res://scripts/track/TrackGridRoadBuilder.gd")
const TrackSourceRules = preload("res://scripts/track/TrackSourceRules.gd")
const TrackMetadataExporter = preload("res://scripts/track/TrackMetadataExporter.gd")
const TrackRuntimeScene = preload("res://scripts/track/TrackRuntimeScene.gd")
const RoadGridMapAuthoring = preload("res://scripts/track/RoadGridMapAuthoring.gd")
const RoadGridSpawn = preload("res://scripts/track/RoadGridSpawn.gd")

const CELL_SIZE := Vector3(16.0, 4.0, 16.0)
const ROAD_WIDTH := 16.0
const ROAD_Y := 0.0
const FLOOR_Y := -1.1
const OUT_OF_BOUNDS_Y := -28.0
const ROAD_TEXTURE := "res://assets/gameplay/materials/plastic/glossy_plastic_albedo.png"
const GRID_LIBRARY := TrackGridRoadBuilder.DEFAULT_MESH_LIBRARY_PATH
const BACKYARD_SHELL_PATH := "res://assets/gameplay/tracks/shared/backyard/backyard_shell.tscn"
const BACKYARD_PREVIEW_SHELL_PATH := "res://assets/gameplay/tracks/shared/backyard_optimized/backyard_preview_shell.tscn"
const BACKYARD_ATLAS_PATH := "res://assets/gameplay/tracks/shared/backyard_optimized/backyard_atlas.png"
const BACKYARD_ATLAS_MATERIAL_PATH := "res://assets/gameplay/tracks/shared/backyard_optimized/backyard_atlas_material.tres"
const BACKYARD_PLAYGROUND_PATH := "res://assets/gameplay/tracks/shared/backyard_optimized/playground_structure_low.glb"
const BACKYARD_SWING_PATH := "res://assets/gameplay/tracks/shared/backyard_optimized/swing_set_low.glb"
const BACKYARD_FOSSIL_PATH := "res://assets/gameplay/tracks/shared/backyard_optimized/sandbox_fossil_low.glb"
const BACKYARD_GARDEN_PATH := "res://assets/gameplay/tracks/shared/backyard_optimized/garden_log_bush_low.glb"

const INDOOR_FLOOR_SIZE := Vector2(360.0, 240.0)
const BACKYARD_FLOOR_SIZE := Vector2(900.0, 720.0)

const COURSES := [
	{
		"id": "attic",
		"display_name": "Attic Mayhem",
		"folder": "attic",
		"root": "AtticEditableRoom",
		"runtime": "AtticTrack",
		"version": "attic_gridmap_v1_2026_05_09",
		"placement": Vector3.ZERO,
		"half_x": 6,
		"half_z": 4,
		"floor_size": INDOOR_FLOOR_SIZE,
		"ground_color": Color(0.45, 0.35, 0.25, 1.0),
		"ground_texture": "res://assets/gameplay/materials/attic/attic_cardboard_wood_albedo.png",
		"sky": "stormy_moonlight_night",
		"concept": "attic",
	},
	{
		"id": "bedroom",
		"display_name": "Bedroom / Tuggs",
		"folder": "bedroom",
		"root": "BedroomEditableRoom",
		"runtime": "BedroomTrack",
		"version": "bedroom_gridmap_v1_2026_05_09",
		"placement": Vector3.ZERO,
		"half_x": 6,
		"half_z": 4,
		"floor_size": INDOOR_FLOOR_SIZE,
		"ground_color": Color(0.55, 0.50, 0.66, 1.0),
		"ground_texture": "res://assets/gameplay/materials/fabric/plush_fabric_albedo.png",
		"sky": "soft_morning",
		"concept": "bedroom",
	},
	{
		"id": "glam_closet",
		"display_name": "Glam Closet / Velva",
		"folder": "glam_closet",
		"root": "GlamClosetEditableRoom",
		"runtime": "GlamClosetTrack",
		"version": "glam_closet_gridmap_v1_2026_05_09",
		"placement": Vector3.ZERO,
		"half_x": 6,
		"half_z": 4,
		"floor_size": INDOOR_FLOOR_SIZE,
		"ground_color": Color(0.74, 0.42, 0.63, 1.0),
		"ground_texture": "res://assets/gameplay/materials/glam/glam_mirror_glitter_albedo.png",
		"sky": "night_city_glow",
		"concept": "glam_closet",
	},
	{
		"id": "playroom",
		"display_name": "Playroom / Slammo",
		"folder": "playroom",
		"root": "PlayroomEditableRoom",
		"runtime": "PlayroomTrack",
		"version": "playroom_gridmap_v1_2026_05_09",
		"placement": Vector3.ZERO,
		"half_x": 6,
		"half_z": 4,
		"floor_size": INDOOR_FLOOR_SIZE,
		"ground_color": Color(0.25, 0.48, 0.82, 1.0),
		"ground_texture": "res://assets/gameplay/materials/plastic/glossy_plastic_albedo.png",
		"sky": "party_evening",
		"concept": "playroom",
	},
	{
		"id": "outdoor_playground",
		"display_name": "Outdoor Playground / Dash",
		"folder": "outdoor_playground",
		"root": "OutdoorPlaygroundEditableRoom",
		"runtime": "OutdoorPlaygroundTrack",
		"version": "outdoor_playground_gridmap_v1_2026_05_09",
		"placement": Vector3(-230.0, 0.0, -150.0),
		"half_x": 7,
		"half_z": 5,
		"floor_size": BACKYARD_FLOOR_SIZE,
		"ground_color": Color(0.22, 0.38, 0.18, 1.0),
		"ground_texture": "res://assets/gameplay/materials/playground/outdoor_playground_floor_albedo.png",
		"ground_shader": "res://assets/gameplay/materials/grass/playground_grass.gdshader",
		"sky": "clear_afternoon",
		"concept": "outdoor_playground",
		"backyard": true,
	},
	{
		"id": "garden",
		"display_name": "Garden / Moko",
		"folder": "garden",
		"root": "GardenEditableRoom",
		"runtime": "GardenTrack",
		"version": "garden_gridmap_v1_2026_05_09",
		"placement": Vector3(210.0, 0.0, -95.0),
		"half_x": 7,
		"half_z": 5,
		"floor_size": BACKYARD_FLOOR_SIZE,
		"ground_color": Color(0.32, 0.43, 0.24, 1.0),
		"ground_texture": "res://assets/gameplay/materials/garden/garden_dirt_mud_albedo.png",
		"sky": "fresh_morning",
		"concept": "garden",
		"backyard": true,
	},
	{
		"id": "sandbox",
		"display_name": "Sandbox / Rexx",
		"folder": "sandbox",
		"root": "SandboxEditableRoom",
		"runtime": "SandboxTrack",
		"version": "sandbox_gridmap_v1_2026_05_09",
		"placement": Vector3(40.0, 0.0, 205.0),
		"half_x": 7,
		"half_z": 5,
		"floor_size": BACKYARD_FLOOR_SIZE,
		"ground_color": Color(0.82, 0.66, 0.42, 1.0),
		"ground_texture": "res://assets/gameplay/materials/sand/sandbox_sand_albedo.png",
		"sky": "hot_afternoon",
		"concept": "sandbox",
		"backyard": true,
	},
]

func _initialize() -> void:
	_save_backyard_atlas_material()
	_save_backyard_shell()
	_save_backyard_preview_shell()
	var manifest := _load_manifest()
	if not manifest.has("tracks"):
		manifest["tracks"] = {}
	for course in COURSES:
		_generate_course(course)
		manifest["tracks"][course["id"]] = {
			"id": course["id"],
			"display_name": course["display_name"],
			"version": course["version"],
			"scene_path": _runtime_scene_path(course),
			"definition_path": _definition_path(course),
			"metadata_path": _metadata_path(course),
		}
	_save_manifest(manifest)
	print("Generated %d GridMap-backed home-course stages." % COURSES.size())
	quit()

func _generate_course(course: Dictionary) -> void:
	var dir := "res://assets/gameplay/tracks/%s" % course["folder"]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var route_cells := _rect_loop_cells(int(course["half_x"]), int(course["half_z"]))
	var layout := _grid_layout_for_course(course, route_cells)
	var race_layout = TrackGridRoadBuilder.race_layout_from_grid_layout(layout, true)
	var definition := _make_definition(course, layout, race_layout.route_points, race_layout.checkpoint_indices, race_layout.spawn_points)
	_save_editable_scene(course, route_cells)
	ResourceSaver.save(definition, _definition_path(course))
	_save_runtime_scene(course)
	var export_error := TrackMetadataExporter.save_json(definition, _metadata_path(course))
	if export_error != OK:
		push_error("Metadata export failed for %s: %s" % [course["id"], error_string(export_error)])

func _make_definition(course: Dictionary, layout: Dictionary, route_points: Array[Vector3], checkpoints: Array[int], spawns: Array[Vector4]) -> TrackDefinition:
	var old_definition := load(_definition_path(course)) as TrackDefinition
	var definition := TrackDefinition.new()
	definition.id = str(course["id"])
	definition.display_name = str(course["display_name"])
	definition.version = str(course["version"])
	definition.laps = 3
	definition.track_source_id = "road_grid_map"
	definition.progress_rule_id = TrackSourceRules.PROGRESS_ROUTE_LAP
	definition.win_condition_id = "checkpoint_laps"
	definition.road_width = ROAD_WIDTH
	definition.wall_height = 3.0
	definition.wall_thickness = 0.6
	definition.rails_enabled = false
	definition.boundary_walls_enabled = true
	definition.boundary_wall_debug_visible = false
	definition.closed_loop = true
	definition.out_of_bounds_y = OUT_OF_BOUNDS_Y
	definition.reset_mode = "instant_pop"
	definition.floor_visual_y = FLOOR_Y
	definition.runtime_scene_path = _runtime_scene_path(course)
	definition.dressing_scene_path = _editable_scene_path(course)
	if bool(course.get("backyard", false)):
		definition.preview_dressing_scene_path = BACKYARD_PREVIEW_SHELL_PATH
	definition.ground_size = course["floor_size"]
	definition.ground_color = course["ground_color"]
	definition.ground_texture_path = str(course.get("ground_texture", ""))
	definition.ground_shader_path = str(course.get("ground_shader", ""))
	definition.road_texture_path = ROAD_TEXTURE
	definition.road_visual_style = "kenney_gridmap"
	definition.road_grid_layout = layout.duplicate(true)
	definition.road_segment_layout = []
	definition.route_points = route_points.duplicate()
	definition.checkpoint_indices = checkpoints.duplicate()
	definition.lap_gate_checkpoint_index = 0
	definition.spawn_points = spawns.duplicate()
	definition.item_sockets = []
	definition.hazard_sockets = []
	definition.shortcut_gates = []
	definition.alternate_routes = []
	definition.surface_segments = []
	definition.stage_props = []
	if old_definition != null:
		definition.audio_ids = old_definition.audio_ids.duplicate(true)
		definition.audio_zones = old_definition.audio_zones.duplicate(true)
		definition.grass_zones = old_definition.grass_zones.duplicate(true)
	_apply_sky_preset(definition, str(course["sky"]))
	return definition

func _save_editable_scene(course: Dictionary, route_cells: Array[Vector3i]) -> void:
	var root := Node3D.new()
	root.name = str(course["root"])
	if bool(course.get("backyard", false)):
		_add_backyard_shell_instance(root)
	else:
		_add_floor(root, course)
		_add_indoor_shell(root, course)
	_add_concept_dressing(root, course)
	_add_road_grid_map(root, course, route_cells)
	_set_owner_recursive(root, root)
	var packed := PackedScene.new()
	packed.pack(root)
	ResourceSaver.save(packed, _editable_scene_path(course))
	root.free()

func _save_runtime_scene(course: Dictionary) -> void:
	var root := Node3D.new()
	root.name = str(course["runtime"])
	root.set_script(TrackRuntimeScene)
	root.set("definition", load(_definition_path(course)))
	var packed := PackedScene.new()
	packed.pack(root)
	ResourceSaver.save(packed, _runtime_scene_path(course))
	root.free()

func _save_backyard_shell() -> void:
	var path := ProjectSettings.globalize_path(BACKYARD_SHELL_PATH.get_base_dir())
	DirAccess.make_dir_recursive_absolute(path)
	var root := Node3D.new()
	root.name = "SharedBackyardShell"
	var course := {
		"floor_size": BACKYARD_FLOOR_SIZE,
		"ground_color": Color(0.24, 0.42, 0.2, 1.0),
		"ground_texture": "res://assets/gameplay/materials/playground/outdoor_playground_floor_albedo.png",
		"ground_shader": "res://assets/gameplay/materials/grass/playground_grass.gdshader",
	}
	_add_floor(root, course)
	_add_box(root, "BackFence", Vector3(0, 13, 365), Vector3(920, 26, 8), Color(0.55, 0.37, 0.18))
	_add_box(root, "LeftFence", Vector3(-460, 13, 0), Vector3(8, 26, 720), Color(0.48, 0.32, 0.16))
	_add_box(root, "RightFence", Vector3(460, 13, 0), Vector3(8, 26, 720), Color(0.48, 0.32, 0.16))
	_add_box(root, "SandboxBase", Vector3(40, -0.85, 205), Vector3(300, 1.2, 230), Color(0.76, 0.61, 0.38))
	_add_box(root, "GardenBed", Vector3(210, -0.8, -95), Vector3(300, 1.0, 220), Color(0.24, 0.34, 0.16))
	_add_box(root, "PlaygroundMulch", Vector3(-230, -0.75, -150), Vector3(300, 1.0, 220), Color(0.36, 0.18, 0.08))
	_add_optimized_scene_instance(root, BACKYARD_PLAYGROUND_PATH, Vector3(-310, 0, -248), 18.0, Vector3(16, 16, 16), "PlaygroundSet")
	_add_optimized_scene_instance(root, BACKYARD_SWING_PATH, Vector3(-124, 0, -210), -12.0, Vector3(14, 14, 14), "SwingSet")
	_add_optimized_scene_instance(root, BACKYARD_FOSSIL_PATH, Vector3(-72, 0, 260), -18.0, Vector3(18, 18, 18), "SandboxFossil")
	_add_optimized_scene_instance(root, BACKYARD_GARDEN_PATH, Vector3(322, 0, -98), 24.0, Vector3(22, 22, 22), "GardenLogBush")
	_set_owner_recursive(root, root)
	var packed := PackedScene.new()
	packed.pack(root)
	ResourceSaver.save(packed, BACKYARD_SHELL_PATH)
	root.free()

func _save_backyard_preview_shell() -> void:
	var path := ProjectSettings.globalize_path(BACKYARD_PREVIEW_SHELL_PATH.get_base_dir())
	DirAccess.make_dir_recursive_absolute(path)
	var root := Node3D.new()
	root.name = "BackyardPreviewShell"
	_add_box(root, "BackFence", Vector3(0, 13, 365), Vector3(920, 26, 8), Color(0.55, 0.37, 0.18))
	_add_box(root, "LeftFence", Vector3(-460, 13, 0), Vector3(8, 26, 720), Color(0.48, 0.32, 0.16))
	_add_box(root, "RightFence", Vector3(460, 13, 0), Vector3(8, 26, 720), Color(0.48, 0.32, 0.16))
	_add_box(root, "SandboxBase", Vector3(40, -0.82, 205), Vector3(300, 0.8, 230), Color(0.76, 0.61, 0.38))
	_add_box(root, "GardenBed", Vector3(210, -0.78, -95), Vector3(300, 0.7, 220), Color(0.24, 0.34, 0.16))
	_add_box(root, "PlaygroundMulch", Vector3(-230, -0.74, -150), Vector3(300, 0.7, 220), Color(0.36, 0.18, 0.08))
	_add_optimized_scene_instance(root, BACKYARD_PLAYGROUND_PATH, Vector3(-310, 0, -248), 18.0, Vector3(16, 16, 16), "PlaygroundSet")
	_add_optimized_scene_instance(root, BACKYARD_SWING_PATH, Vector3(-124, 0, -210), -12.0, Vector3(14, 14, 14), "SwingSet")
	_add_optimized_scene_instance(root, BACKYARD_FOSSIL_PATH, Vector3(-72, 0, 260), -18.0, Vector3(18, 18, 18), "SandboxFossil")
	_add_optimized_scene_instance(root, BACKYARD_GARDEN_PATH, Vector3(322, 0, -98), 24.0, Vector3(22, 22, 22), "GardenLogBush")
	_set_owner_recursive(root, root)
	var packed := PackedScene.new()
	packed.pack(root)
	ResourceSaver.save(packed, BACKYARD_PREVIEW_SHELL_PATH)
	root.free()

func _save_backyard_atlas_material() -> void:
	var path := ProjectSettings.globalize_path(BACKYARD_ATLAS_MATERIAL_PATH.get_base_dir())
	DirAccess.make_dir_recursive_absolute(path)
	var material := StandardMaterial3D.new()
	material.resource_name = "BackyardAtlasMaterial"
	material.roughness = 0.78
	material.metallic = 0.0
	var texture := load(BACKYARD_ATLAS_PATH) as Texture2D
	if texture != null:
		material.albedo_texture = texture
	ResourceSaver.save(material, BACKYARD_ATLAS_MATERIAL_PATH)

func _add_backyard_shell_instance(root: Node3D) -> void:
	var packed := load(BACKYARD_SHELL_PATH) as PackedScene
	if packed == null:
		return
	var instance := packed.instantiate() as Node3D
	if instance == null:
		return
	instance.name = "BackyardShell"
	root.add_child(instance)

func _add_road_grid_map(root: Node3D, course: Dictionary, route_cells: Array[Vector3i]) -> void:
	var grid := GridMap.new()
	grid.name = "RoadGridMap"
	grid.set_script(RoadGridMapAuthoring)
	grid.mesh_library = load(GRID_LIBRARY) as MeshLibrary
	grid.cell_size = CELL_SIZE
	grid.transform.origin = _grid_origin(course)
	grid.set("ordered_route_cells", route_cells)
	grid.set("checkpoint_route_indices", _checkpoint_indices(route_cells.size()))
	grid.set("item_route_indices", [])
	grid.set("hazard_route_indices", [])
	grid.set("spawn_slots", _spawn_slots())
	grid.set("road_width_override", ROAD_WIDTH)
	grid.set("regenerate_route_from_painted_track", false)
	for i in range(route_cells.size()):
		var cell := route_cells[i]
		var item := _tile_item_for_route_cell(route_cells, i)
		var basis := _basis_for_route_cell(route_cells, i, item)
		grid.set_cell_item(cell, item, _orientation_index(basis))
	root.add_child(grid)

func _grid_layout_for_course(course: Dictionary, route_cells: Array[Vector3i]) -> Dictionary:
	var cells: Array[Dictionary] = []
	for i in range(route_cells.size()):
		var cell := route_cells[i]
		var item := _tile_item_for_route_cell(route_cells, i)
		var basis := _basis_for_route_cell(route_cells, i, item)
		cells.append({
			"cell": cell,
			"item": item,
			"orientation": _orientation_index(basis),
			"orientation_basis": _basis_to_array(basis),
			"position": _cell_center(course, cell),
		})
	return {
		"mesh_library_path": GRID_LIBRARY,
		"origin": _grid_origin(course),
		"basis": _basis_to_array(Basis.IDENTITY),
		"cell_size": CELL_SIZE,
		"road_width": ROAD_WIDTH,
		"cells": cells,
		"ordered_route_cells": route_cells,
		"ordered_route_points": _route_points_for_cells(course, route_cells),
		"checkpoint_route_indices": _checkpoint_indices(route_cells.size()),
		"spawn_slots": _spawn_slot_data(),
		"item_route_indices": [],
		"hazard_route_indices": [],
	}

func _rect_loop_cells(half_x: int, half_z: int) -> Array[Vector3i]:
	var cells: Array[Vector3i] = []
	for x in range(-half_x, half_x + 1):
		cells.append(Vector3i(x, 0, -half_z))
	for z in range(-half_z + 1, half_z + 1):
		cells.append(Vector3i(half_x, 0, z))
	for x in range(half_x - 1, -half_x - 1, -1):
		cells.append(Vector3i(x, 0, half_z))
	for z in range(half_z - 1, -half_z, -1):
		cells.append(Vector3i(-half_x, 0, z))
	var first_straight := 0
	for i in range(cells.size()):
		var prev := cells[(i - 1 + cells.size()) % cells.size()] - cells[i]
		var next := cells[(i + 1) % cells.size()] - cells[i]
		if prev + next == Vector3i.ZERO:
			first_straight = i
			break
	var rotated: Array[Vector3i] = []
	for i in range(cells.size()):
		rotated.append(cells[(first_straight + i) % cells.size()])
	return rotated

func _tile_item_for_route_cell(route_cells: Array[Vector3i], index: int) -> int:
	var current := route_cells[index]
	var prev := route_cells[(index - 1 + route_cells.size()) % route_cells.size()]
	var next := route_cells[(index + 1) % route_cells.size()]
	var prev_dir := prev - current
	var next_dir := next - current
	if prev_dir + next_dir == Vector3i.ZERO:
		return TrackGridRoadBuilder.TILE_STRAIGHT
	return TrackGridRoadBuilder.TILE_CORNER

func _basis_for_route_cell(route_cells: Array[Vector3i], index: int, item: int) -> Basis:
	var current := route_cells[index]
	var prev := route_cells[(index - 1 + route_cells.size()) % route_cells.size()]
	var next := route_cells[(index + 1) % route_cells.size()]
	var prev_dir := prev - current
	var next_dir := next - current
	if item == TrackGridRoadBuilder.TILE_STRAIGHT:
		return _basis_for_forward(next_dir)
	if _right_of(prev_dir) == next_dir:
		return _basis_for_forward(prev_dir)
	if _right_of(next_dir) == prev_dir:
		return _basis_for_forward(next_dir)
	return _basis_for_forward(next_dir)

func _right_of(direction: Vector3i) -> Vector3i:
	return Vector3i(direction.z, 0, -direction.x)

func _basis_for_forward(direction: Vector3i) -> Basis:
	var yaw := atan2(float(direction.x), float(direction.z))
	return Basis(Vector3.UP, yaw)

func _orientation_index(basis: Basis) -> int:
	var helper := GridMap.new()
	var index := helper.get_orthogonal_index_from_basis(basis)
	helper.free()
	return index

func _grid_origin(course: Dictionary) -> Vector3:
	var placement := course["placement"] as Vector3
	return placement - Vector3(CELL_SIZE.x * 0.5, CELL_SIZE.y * 0.5, CELL_SIZE.z * 0.5)

func _cell_center(course: Dictionary, cell: Vector3i) -> Vector3:
	return _grid_origin(course) + Vector3(
		(float(cell.x) + 0.5) * CELL_SIZE.x,
		(float(cell.y) + 0.5) * CELL_SIZE.y,
		(float(cell.z) + 0.5) * CELL_SIZE.z
	)

func _route_points_for_cells(course: Dictionary, route_cells: Array[Vector3i]) -> Array[Vector3]:
	var points: Array[Vector3] = []
	for cell in route_cells:
		points.append(_cell_center(course, cell))
	return points

func _checkpoint_indices(route_size: int) -> Array[int]:
	var checkpoints: Array[int] = []
	for i in range(6):
		var index := int(round(float(i) * float(route_size) / 6.0))
		index = clampi(index, 0, route_size - 1)
		if not checkpoints.has(index):
			checkpoints.append(index)
	return checkpoints

func _spawn_slots() -> Array[RoadGridSpawn]:
	var slots: Array[RoadGridSpawn] = []
	for row in range(4):
		for col in range(2):
			var spawn := RoadGridSpawn.new()
			spawn.route_index = 0
			spawn.lateral_offset = (-2.75 if col == 0 else 2.75)
			spawn.forward_offset = 5.0 + float(row) * 5.25
			spawn.y_offset = 0.8
			spawn.yaw_offset_degrees = 0.0
			slots.append(spawn)
	return slots

func _spawn_slot_data() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for spawn in _spawn_slots():
		out.append(spawn.to_layout_data())
	return out

func _add_floor(root: Node3D, course: Dictionary) -> void:
	var floor := Node3D.new()
	floor.name = "floor"
	floor.position.y = FLOOR_Y
	root.add_child(floor)
	var mesh := MeshInstance3D.new()
	mesh.name = "MeshInstance3D"
	var plane := PlaneMesh.new()
	plane.size = course["floor_size"]
	mesh.mesh = plane
	mesh.material_override = _floor_material(course)
	floor.add_child(mesh)

func _floor_material(course: Dictionary) -> Material:
	var shader_path := str(course.get("ground_shader", "")).strip_edges()
	if not shader_path.is_empty():
		var shader := load(shader_path)
		if shader is Shader:
			var material := ShaderMaterial.new()
			material.shader = shader
			material.set_shader_parameter("base_color", course["ground_color"])
			return material
	var material := StandardMaterial3D.new()
	material.albedo_color = course["ground_color"]
	material.roughness = 0.82
	material.uv1_scale = Vector3(22, 22, 1)
	var texture := load(str(course.get("ground_texture", "")))
	if texture is Texture2D:
		material.albedo_texture = texture
	return material

func _add_indoor_shell(root: Node3D, course: Dictionary) -> void:
	var shell := Node3D.new()
	shell.name = "RoomShell"
	root.add_child(shell)
	var size := course["floor_size"] as Vector2
	var half_x := size.x * 0.5
	var half_z := size.y * 0.5
	var color := _stage_wall_color(str(course["id"]))
	_add_box(shell, "BackWall", Vector3(0, 30, half_z + 4), Vector3(size.x + 12, 62, 8), color)
	_add_box(shell, "LeftWall", Vector3(-half_x - 4, 30, 0), Vector3(8, 62, size.y + 8), color.darkened(0.08))
	_add_box(shell, "RightWall", Vector3(half_x + 4, 30, 0), Vector3(8, 62, size.y + 8), color.darkened(0.08))
	_add_box(shell, "Ceiling", Vector3(0, 62, 0), Vector3(size.x + 16, 2, size.y + 16), color.lightened(0.08))

func _add_concept_dressing(root: Node3D, course: Dictionary) -> void:
	var holder := Node3D.new()
	holder.name = "Dressing"
	root.add_child(holder)
	match str(course["concept"]):
		"attic":
			_add_box(holder, "CardboardBoxStackA", Vector3(-125, 13, -42), Vector3(42, 26, 34), Color(0.58, 0.42, 0.24))
			_add_box(holder, "OldTrunk", Vector3(102, 10, 64), Vector3(56, 20, 28), Color(0.24, 0.14, 0.08))
			_add_box(holder, "SheetGhost", Vector3(118, 22, -56), Vector3(28, 44, 18), Color(0.82, 0.8, 0.72))
			_add_box(holder, "RafterBeam", Vector3(0, 44, 0), Vector3(270, 8, 10), Color(0.28, 0.16, 0.08))
			_add_scene_instance(holder, "res://assets/source/kenney/furniture_kit/books.glb", Vector3(-58, 0, 78), -12, Vector3(12, 12, 12), "BookPile")
		"bedroom":
			_add_scene_instance(holder, "res://assets/source/kenney/furniture_kit/bedDouble.glb", Vector3(-104, 0, 58), 0, Vector3(18, 18, 18), "BedLandmark")
			_add_scene_instance(holder, "res://assets/source/kenney/furniture_kit/rugRectangle.glb", Vector3(40, 0, -62), 8, Vector3(24, 24, 24), "RugLandmark")
			_add_scene_instance(holder, "res://assets/source/kenney/furniture_kit/bear.glb", Vector3(120, 0, -44), -24, Vector3(18, 18, 18), "BearLandmark")
			_add_scene_instance(holder, "res://assets/source/kenney/furniture_kit/lampRoundTable.glb", Vector3(-138, 0, -66), 0, Vector3(14, 14, 14), "LampLandmark")
			_add_box(holder, "BlanketFold", Vector3(95, 1, 54), Vector3(54, 2, 30), Color(0.25, 0.36, 0.8))
		"glam_closet":
			_add_scene_instance(holder, "res://assets/source/kenney/furniture_kit/bathroomMirror.glb", Vector3(-142, 20, 0), 90, Vector3(20, 20, 20), "VanityMirror")
			_add_box(holder, "RunwayLightA", Vector3(-80, 5, -92), Vector3(14, 10, 14), Color(1.0, 0.76, 0.92))
			_add_box(holder, "RunwayLightB", Vector3(80, 5, -92), Vector3(14, 10, 14), Color(0.72, 0.88, 1.0))
			_add_box(holder, "ShoePedestal", Vector3(126, 9, 52), Vector3(34, 18, 34), Color(0.18, 0.12, 0.1))
			_add_scene_instance(holder, "res://assets/source/kenney/furniture_kit/chairCushion.glb", Vector3(-104, 0, 76), 20, Vector3(16, 16, 16), "VanityChair")
		"playroom":
			_add_scene_instance(holder, "res://assets/source/meshy/playroom_props/boxing_ring.glb", Vector3(0, 0, 0), 0, Vector3(20, 20, 20), "ChampionRing")
			_add_box(holder, "BlockTowerRed", Vector3(-132, 18, -66), Vector3(28, 36, 28), Color(0.9, 0.14, 0.12))
			_add_box(holder, "BlockTowerBlue", Vector3(132, 18, -56), Vector3(28, 36, 28), Color(0.12, 0.28, 0.9))
			_add_scene_instance(holder, "res://assets/source/kenney/mini_skate/half-pipe.glb", Vector3(-112, 0, 72), 18, Vector3(15, 15, 15), "HalfPipe")
			_add_scene_instance(holder, "res://assets/source/kenney/furniture_kit/bookcaseOpen.glb", Vector3(138, 0, 76), -90, Vector3(18, 18, 18), "ToyShelf")
		"outdoor_playground":
			_add_scene_instance(holder, "res://assets/source/kenney/mini_skate/half-pipe.glb", Vector3(-72, 0, -42), 20, Vector3(18, 18, 18), "PlaygroundHalfPipe")
			_add_box(holder, "DashBanner", Vector3(-345, 18, -44), Vector3(64, 16, 4), Color(0.1, 0.58, 1.0))
			_add_box(holder, "SlideBeat", Vector3(-132, 4, -276), Vector3(70, 8, 24), Color(0.95, 0.16, 0.12))
		"garden":
			_add_scene_instance(holder, "res://assets/source/kenney/nature_kit/flower_yellowA.glb", Vector3(88, 0, -206), 0, Vector3(18, 18, 18), "YellowFlowers")
			_add_scene_instance(holder, "res://assets/source/kenney/nature_kit/flower_purpleA.glb", Vector3(326, 0, -206), 0, Vector3(18, 18, 18), "PurpleFlowers")
			_add_scene_instance(holder, "res://assets/source/kenney/nature_kit/path_stoneCircle.glb", Vector3(210, 0, -236), 0, Vector3(18, 18, 18), "StoneCircle")
			_add_box(holder, "GardenHose", Vector3(76, 0.8, 26), Vector3(140, 1.6, 6), Color(0.12, 0.46, 0.18))
		"sandbox":
			_add_box(holder, "BucketLandmark", Vector3(170, 24, 90), Vector3(44, 48, 44), Color(0.9, 0.18, 0.12))
			_add_box(holder, "ShovelLandmark", Vector3(-112, 2, 132), Vector3(96, 4, 18), Color(0.1, 0.36, 0.86))
			_add_box(holder, "SandRidge", Vector3(42, 2, 328), Vector3(220, 4, 30), Color(0.68, 0.52, 0.3))
			_add_scene_instance(holder, "res://assets/source/kenney/nature_kit/path_stone.glb", Vector3(-92, 0, 268), 12, Vector3(18, 18, 18), "BuriedStone")

func _add_box(parent: Node3D, node_name: String, position: Vector3, size: Vector3, color: Color) -> void:
	var mesh := MeshInstance3D.new()
	mesh.name = node_name
	mesh.position = position
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.72
	mesh.material_override = material
	parent.add_child(mesh)

func _add_scene_instance(parent: Node3D, path: String, position: Vector3, yaw_degrees: float, scale: Vector3, node_name: String) -> void:
	var packed := load(path) as PackedScene
	if packed == null:
		_add_box(parent, node_name, position + Vector3.UP * 6.0, Vector3(18, 12, 18), Color(0.7, 0.7, 0.72))
		return
	var instance := packed.instantiate() as Node3D
	if instance == null:
		return
	instance.name = node_name
	instance.transform = Transform3D(Basis(Vector3.UP, deg_to_rad(yaw_degrees)).scaled(scale), position)
	parent.add_child(instance)

func _add_optimized_scene_instance(parent: Node3D, path: String, position: Vector3, yaw_degrees: float, scale: Vector3, node_name: String) -> void:
	_add_scene_instance(parent, path, position, yaw_degrees, scale, node_name)
	var instance := parent.get_node_or_null(NodePath(node_name))
	if instance != null:
		_apply_material_override_recursive(instance, load(BACKYARD_ATLAS_MATERIAL_PATH) as Material)

func _apply_material_override_recursive(node: Node, material: Material) -> void:
	if material == null:
		return
	if node is MeshInstance3D:
		(node as MeshInstance3D).material_override = material
	for child in node.get_children():
		_apply_material_override_recursive(child, material)

func _apply_sky_preset(definition: TrackDefinition, preset_id: String) -> void:
	var preset := _sky_preset(preset_id)
	definition.sky_preset_id = preset_id
	definition.sky_time_of_day = float(preset["time_of_day"])
	definition.sky_weather = str(preset["weather"])
	definition.sky_top_color = preset["top_color"]
	definition.sky_horizon_color = preset["horizon_color"]
	definition.sky_cloud_amount = float(preset["cloud_amount"])
	definition.sky_cloud_speed = float(preset["cloud_speed"])
	definition.sky_haze_amount = float(preset["haze_amount"])
	definition.sky_light_energy = float(preset["light_energy"])

func _sky_preset(preset_id: String) -> Dictionary:
	match preset_id:
		"hot_afternoon":
			return {"time_of_day": 0.46, "weather": "clear_hot", "top_color": Color(0.48, 0.72, 0.98), "horizon_color": Color(0.92, 0.82, 0.62), "cloud_amount": 0.18, "cloud_speed": 0.018, "haze_amount": 0.24, "light_energy": 2.8}
		"fresh_morning":
			return {"time_of_day": 0.28, "weather": "fresh_morning", "top_color": Color(0.54, 0.76, 0.92), "horizon_color": Color(0.78, 0.9, 0.78), "cloud_amount": 0.34, "cloud_speed": 0.014, "haze_amount": 0.2, "light_energy": 2.1}
		"soft_morning":
			return {"time_of_day": 0.3, "weather": "soft_morning", "top_color": Color(0.64, 0.76, 0.92), "horizon_color": Color(0.92, 0.84, 0.78), "cloud_amount": 0.28, "cloud_speed": 0.01, "haze_amount": 0.22, "light_energy": 1.9}
		"stormy_moonlight_night":
			return {"time_of_day": 0.86, "weather": "storm_moonlight", "top_color": Color(0.03, 0.06, 0.14), "horizon_color": Color(0.16, 0.18, 0.28), "cloud_amount": 0.82, "cloud_speed": 0.036, "haze_amount": 0.36, "light_energy": 0.82}
		"party_evening":
			return {"time_of_day": 0.68, "weather": "warm_evening", "top_color": Color(0.32, 0.34, 0.68), "horizon_color": Color(1.0, 0.52, 0.34), "cloud_amount": 0.42, "cloud_speed": 0.02, "haze_amount": 0.26, "light_energy": 1.75}
		"night_city_glow":
			return {"time_of_day": 0.82, "weather": "city_night", "top_color": Color(0.02, 0.04, 0.12), "horizon_color": Color(0.42, 0.18, 0.58), "cloud_amount": 0.22, "cloud_speed": 0.012, "haze_amount": 0.32, "light_energy": 1.05}
		"clear_afternoon":
			return {"time_of_day": 0.5, "weather": "clear", "top_color": Color(0.42, 0.68, 1.0), "horizon_color": Color(0.74, 0.88, 1.0), "cloud_amount": 0.24, "cloud_speed": 0.018, "haze_amount": 0.12, "light_energy": 2.55}
	return {"time_of_day": 0.5, "weather": "clear", "top_color": Color(0.58, 0.72, 0.9), "horizon_color": Color(0.64, 0.72, 0.82), "cloud_amount": 0.25, "cloud_speed": 0.02, "haze_amount": 0.18, "light_energy": 2.4}

func _stage_wall_color(stage_id: String) -> Color:
	match stage_id:
		"attic":
			return Color(0.42, 0.33, 0.24)
		"bedroom":
			return Color(0.54, 0.48, 0.6)
		"glam_closet":
			return Color(0.72, 0.48, 0.66)
		"playroom":
			return Color(0.42, 0.58, 0.82)
	return Color(0.6, 0.58, 0.52)

func _basis_to_array(basis: Basis) -> Array:
	return [
		[basis.x.x, basis.x.y, basis.x.z],
		[basis.y.x, basis.y.y, basis.y.z],
		[basis.z.x, basis.z.y, basis.z.z],
	]

func _definition_path(course: Dictionary) -> String:
	return "res://assets/gameplay/tracks/%s/%s_track_definition.tres" % [course["folder"], course["folder"]]

func _editable_scene_path(course: Dictionary) -> String:
	return "res://assets/gameplay/tracks/%s/%s_editable_room.tscn" % [course["folder"], course["folder"]]

func _runtime_scene_path(course: Dictionary) -> String:
	return "res://assets/gameplay/tracks/%s/%s_track.tscn" % [course["folder"], course["folder"]]

func _metadata_path(course: Dictionary) -> String:
	return "res://assets/gameplay/tracks/%s/%s_track_metadata.json" % [course["folder"], course["folder"]]

func _load_manifest() -> Dictionary:
	var path := "res://assets/gameplay/tracks/track_packages.json"
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"default_track_id": "kitchen", "tracks": {}}
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary:
		return parsed
	return {"default_track_id": "kitchen", "tracks": {}}

func _save_manifest(manifest: Dictionary) -> void:
	var file := FileAccess.open("res://assets/gameplay/tracks/track_packages.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest, "\t"))
	file.store_string("\n")
	file.close()

func _set_owner_recursive(node: Node, scene_owner: Node) -> void:
	for child in node.get_children():
		child.owner = scene_owner
		_set_owner_recursive(child, scene_owner)
