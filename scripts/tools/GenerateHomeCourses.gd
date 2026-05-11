@tool
extends SceneTree

const TrackDefinition = preload("res://scripts/track/TrackDefinition.gd")
const TrackGridRoadBuilder = preload("res://scripts/track/TrackGridRoadBuilder.gd")
const TrackSourceRules = preload("res://scripts/track/TrackSourceRules.gd")
const TrackMetadataExporter = preload("res://scripts/track/TrackMetadataExporter.gd")
const TrackRuntimeScene = preload("res://scripts/track/TrackRuntimeScene.gd")
const RoadGridMapAuthoring = preload("res://scripts/track/RoadGridMapAuthoring.gd")
const RoadGridSpawn = preload("res://scripts/track/RoadGridSpawn.gd")
const StagePropAuthoring = preload("res://scripts/track/StagePropAuthoring.gd")
const StageInteractionAuthoring = preload("res://scripts/track/StageInteractionAuthoring.gd")

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
const ROOM_WALL_THICKNESS := 8.0
const ROOM_SEAM_OVERLAP := 2.0
const ROOM_WALL_HEIGHT := 66.0
const ROOM_WALL_CENTER_Y := 31.0
const ROOM_CEILING_Y := 62.0
const ROOM_CEILING_THICKNESS := 4.0
const ROOM_DOOR_WIDTH := 34.0
const ROOM_DOOR_HEIGHT := 42.0
const ROOM_DOOR_TRIM := 5.0

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
	var selected_ids := _selected_course_ids()
	var selected_courses := _selected_courses(selected_ids)
	if selected_courses.is_empty():
		push_error("No matching courses for GenerateHomeCourses selection: %s" % [selected_ids])
		quit(1)
		return
	if selected_ids.is_empty():
		_save_backyard_atlas_material()
		_save_backyard_shell()
		_save_backyard_preview_shell()
	var manifest := _load_manifest()
	if not manifest.has("tracks"):
		manifest["tracks"] = {}
	for course in selected_courses:
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
	print("Generated %d GridMap-backed home-course stages." % selected_courses.size())
	quit()

func _selected_course_ids() -> Array[String]:
	var ids: Array[String] = []
	for arg in OS.get_cmdline_user_args():
		if arg == "--indoor_only=true" or arg == "--indoor-only":
			for course in COURSES:
				if not bool(course.get("backyard", false)):
					ids.append(str(course["id"]))
		elif arg.begins_with("--track_id="):
			_append_selected_ids(ids, arg.trim_prefix("--track_id="))
		elif arg.begins_with("--track_ids="):
			_append_selected_ids(ids, arg.trim_prefix("--track_ids="))
	return ids

func _append_selected_ids(ids: Array[String], raw_value: String) -> void:
	for value in raw_value.split(",", false):
		var track_id := value.strip_edges()
		if not track_id.is_empty() and not ids.has(track_id):
			ids.append(track_id)

func _selected_courses(selected_ids: Array[String]) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for course in COURSES:
		if selected_ids.is_empty() or selected_ids.has(str(course["id"])):
			out.append(course)
	return out


func _generate_course(course: Dictionary) -> void:
	var dir := "res://assets/gameplay/tracks/%s" % course["folder"]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var route_cells := _route_cells_for_course(course)
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
	definition.stage_props = _stage_props_for_course(course)
	definition.stage_interactions = _stage_interactions_for_course(course)
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
	_add_stage_interactions(root, course)
	_add_stage_lighting(root, course)
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

func _route_cells_for_course(course: Dictionary) -> Array[Vector3i]:
	match str(course["id"]):
		"attic":
			return _route_from_points([
				Vector3i(-8, 0, -5), Vector3i(1, 0, -5), Vector3i(1, 1, -2), Vector3i(-5, 1, -2),
				Vector3i(-5, 1, 1), Vector3i(-8, 0, 1), Vector3i(-8, 0, 5), Vector3i(-2, 0, 5),
				Vector3i(-2, 0, 3), Vector3i(4, 0, 3), Vector3i(4, 0, 6), Vector3i(8, 0, 6),
				Vector3i(8, 0, 0), Vector3i(5, 0, 0), Vector3i(5, 0, -4), Vector3i(8, 0, -4),
				Vector3i(8, 0, -6), Vector3i(-8, 0, -6),
			])
		"bedroom":
			return _route_from_points([
				Vector3i(-7, 0, -4), Vector3i(5, 0, -4), Vector3i(5, 1, -1), Vector3i(1, 1, -1),
				Vector3i(1, 0, 1), Vector3i(7, 0, 1), Vector3i(7, 0, 5), Vector3i(2, 0, 5),
				Vector3i(2, 0, 3), Vector3i(-4, 0, 3), Vector3i(-4, 0, 5), Vector3i(-8, 0, 5),
				Vector3i(-8, 0, 0), Vector3i(-5, 0, 0), Vector3i(-5, 0, -3), Vector3i(-8, 0, -3),
				Vector3i(-8, 0, -4),
			])
		"glam_closet":
			return _route_from_points([
				Vector3i(-8, 0, -5), Vector3i(7, 0, -5), Vector3i(7, 1, -2), Vector3i(3, 1, -2),
				Vector3i(3, 1, 1), Vector3i(8, 0, 1), Vector3i(8, 0, 5), Vector3i(1, 0, 5),
				Vector3i(1, 0, 2), Vector3i(-4, 0, 2), Vector3i(-4, 0, 5), Vector3i(-8, 0, 5),
				Vector3i(-8, 0, 1), Vector3i(-5, 0, 1), Vector3i(-5, 0, -2), Vector3i(-8, 0, -2),
				Vector3i(-8, 0, -4),
			])
		"playroom":
			return _route_from_points([
				Vector3i(-8, 0, -5), Vector3i(5, 0, -5), Vector3i(5, 1, -3), Vector3i(8, 1, -3),
				Vector3i(8, 0, 2), Vector3i(4, 0, 2), Vector3i(4, 0, 5), Vector3i(-1, 0, 5),
				Vector3i(-1, 0, 2), Vector3i(-5, 0, 2), Vector3i(-5, 0, 5), Vector3i(-8, 0, 5),
				Vector3i(-8, 0, 0), Vector3i(-4, 0, 0), Vector3i(-4, 0, -3), Vector3i(-8, 0, -3),
				Vector3i(-8, 0, -4),
			])
		"outdoor_playground":
			return _route_from_points([
				Vector3i(10, 0, 7), Vector3i(0, 0, 7), Vector3i(0, 1, 4), Vector3i(-6, 1, 4),
				Vector3i(-6, 0, 6), Vector3i(-10, 0, 6), Vector3i(-10, 0, 0), Vector3i(-7, 0, 0),
				Vector3i(-7, 0, -4), Vector3i(-9, 0, -4), Vector3i(-9, 0, -6), Vector3i(3, 0, -6),
				Vector3i(3, 0, -3), Vector3i(8, 0, -3), Vector3i(8, 0, 1), Vector3i(4, 0, 1),
				Vector3i(4, 0, 4), Vector3i(10, 0, 4),
			])
		"garden":
			return _route_from_points([
				Vector3i(-8, 0, -5), Vector3i(-2, 0, -5), Vector3i(-2, 1, -3), Vector3i(3, 1, -3),
				Vector3i(3, 0, -6), Vector3i(8, 0, -6), Vector3i(8, 0, -1), Vector3i(5, 0, -1),
				Vector3i(5, 0, 3), Vector3i(9, 0, 3), Vector3i(9, 0, 6), Vector3i(1, 0, 6),
				Vector3i(1, 0, 3), Vector3i(-4, 0, 3), Vector3i(-4, 0, 5), Vector3i(-9, 0, 5),
				Vector3i(-9, 0, 0), Vector3i(-6, 0, 0), Vector3i(-6, 0, -4), Vector3i(-8, 0, -4),
			])
		"sandbox":
			return _route_from_points([
				Vector3i(-9, 0, -6), Vector3i(6, 0, -6), Vector3i(6, 1, -3), Vector3i(9, 1, -3),
				Vector3i(9, 0, 2), Vector3i(3, 0, 2), Vector3i(3, 0, 5), Vector3i(7, 0, 5),
				Vector3i(7, 0, 7), Vector3i(-2, 0, 7), Vector3i(-2, 0, 4), Vector3i(-7, 0, 4),
				Vector3i(-7, 0, 6), Vector3i(-10, 0, 6), Vector3i(-10, 0, 0), Vector3i(-6, 0, 0),
				Vector3i(-6, 0, -4), Vector3i(-9, 0, -4), Vector3i(-9, 0, -5),
			])
	return _rect_loop_cells(int(course["half_x"]), int(course["half_z"]))

func _route_from_points(points: Array) -> Array[Vector3i]:
	var cells: Array[Vector3i] = []
	if points.is_empty():
		return cells
	var cursor := _route_waypoint_from_value(points[0])
	cells.append(cursor)
	for i in range(points.size()):
		var target := _route_waypoint_from_value(points[(i + 1) % points.size()])
		var guard := 0
		while cursor != target:
			guard += 1
			if guard > 1000:
				push_error("Route generation exceeded guard while walking from %s to %s" % [cursor, target])
				break
			var moved_horizontal := false
			if cursor.x != target.x:
				cursor.x += 1 if target.x > cursor.x else -1
				moved_horizontal = true
			elif cursor.z != target.z:
				cursor.z += 1 if target.z > cursor.z else -1
				moved_horizontal = true
			elif cursor.y != target.y:
				push_error("Route generation requires horizontal movement for vertical transition from %s to %s" % [cursor, target])
				break
			if moved_horizontal and cursor.y != target.y:
				cursor.y += 1 if target.y > cursor.y else -1
			var cell := cursor
			if i == points.size() - 1 and cell == cells[0]:
				break
			cells.append(cell)
	return _rotate_route_start_to_straight(cells)

func _route_waypoint_from_value(value: Variant) -> Vector3i:
	if value is Vector3i:
		return value as Vector3i
	if value is Vector2i:
		var point2i := value as Vector2i
		return Vector3i(point2i.x, 0, point2i.y)
	if value is Vector3:
		var point3 := value as Vector3
		return Vector3i(roundi(point3.x), roundi(point3.y), roundi(point3.z))
	if value is Vector2:
		var point2 := value as Vector2
		return Vector3i(roundi(point2.x), 0, roundi(point2.y))
	if value is Array:
		var array := value as Array
		if array.size() >= 3:
			return Vector3i(roundi(float(array[0])), roundi(float(array[1])), roundi(float(array[2])))
	if value is Dictionary:
		var data := value as Dictionary
		return Vector3i(int(data.get("x", 0)), int(data.get("y", 0)), int(data.get("z", 0)))
	push_error("Unsupported route waypoint value: %s" % [value])
	return Vector3i.ZERO

func _rotate_route_start_to_straight(cells: Array[Vector3i]) -> Array[Vector3i]:
	if cells.size() < 4:
		return cells
	for i in range(cells.size()):
		if not _is_flat_straight_route_cell(cells, i):
			continue
		var rotated: Array[Vector3i] = []
		for offset in range(cells.size()):
			rotated.append(cells[(i + offset) % cells.size()])
		return rotated
	return cells

func _is_flat_straight_route_cell(cells: Array[Vector3i], index: int) -> bool:
	var current := cells[index]
	var prev := cells[(index - 1 + cells.size()) % cells.size()]
	var next := cells[(index + 1) % cells.size()]
	if prev.y != current.y or next.y != current.y:
		return false
	return _horizontal_delta(current, prev) + _horizontal_delta(current, next) == Vector3i.ZERO

func _tile_item_for_route_cell(route_cells: Array[Vector3i], index: int) -> int:
	var current := route_cells[index]
	var prev := route_cells[(index - 1 + route_cells.size()) % route_cells.size()]
	var next := route_cells[(index + 1) % route_cells.size()]
	if next.y != current.y:
		return TrackGridRoadBuilder.TILE_RAMP
	if index == 0:
		return TrackGridRoadBuilder.TILE_START
	var prev_dir := _horizontal_delta(current, prev)
	var next_dir := _horizontal_delta(current, next)
	if prev_dir + next_dir == Vector3i.ZERO:
		return TrackGridRoadBuilder.TILE_STRAIGHT
	return TrackGridRoadBuilder.TILE_CORNER

func _basis_for_route_cell(route_cells: Array[Vector3i], index: int, item: int) -> Basis:
	var current := route_cells[index]
	var prev := route_cells[(index - 1 + route_cells.size()) % route_cells.size()]
	var next := route_cells[(index + 1) % route_cells.size()]
	var prev_dir := _horizontal_delta(current, prev)
	var next_dir := _horizontal_delta(current, next)
	if item == TrackGridRoadBuilder.TILE_RAMP:
		if next.y > current.y:
			return _basis_for_forward(Vector3i(-next_dir.x, 0, -next_dir.z))
		return _basis_for_forward(next_dir)
	if item != TrackGridRoadBuilder.TILE_CORNER and item != TrackGridRoadBuilder.TILE_CORNER_LARGE:
		return _basis_for_forward(next_dir)
	if _right_of(prev_dir) == next_dir:
		return _basis_for_forward(prev_dir)
	if _right_of(next_dir) == prev_dir:
		return _basis_for_forward(next_dir)
	return _basis_for_forward(next_dir)

func _right_of(direction: Vector3i) -> Vector3i:
	return Vector3i(direction.z, 0, -direction.x)

func _horizontal_delta(from_cell: Vector3i, to_cell: Vector3i) -> Vector3i:
	return Vector3i(to_cell.x - from_cell.x, 0, to_cell.z - from_cell.z)

func _basis_for_forward(direction: Vector3i) -> Basis:
	if direction.x == 0 and direction.z == 0:
		return Basis.IDENTITY
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
			spawn.forward_offset = float(row) * 5.0
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
	var wall_depth := ROOM_WALL_THICKNESS + ROOM_SEAM_OVERLAP
	var side_center_x := half_x + ROOM_WALL_THICKNESS * 0.5 - ROOM_SEAM_OVERLAP * 0.5
	var back_center_z := half_z + ROOM_WALL_THICKNESS * 0.5 - ROOM_SEAM_OVERLAP * 0.5
	var front_center_z := -back_center_z
	var shell_width := size.x + ROOM_WALL_THICKNESS * 2.0 + ROOM_SEAM_OVERLAP * 2.0
	var shell_depth := size.y + ROOM_WALL_THICKNESS * 2.0 + ROOM_SEAM_OVERLAP * 2.0
	var wall_top := ROOM_WALL_CENTER_Y + ROOM_WALL_HEIGHT * 0.5
	var door_half := ROOM_DOOR_WIDTH * 0.5
	var left_front_center_x := (-side_center_x + -door_half) * 0.5
	var right_front_center_x := (side_center_x + door_half) * 0.5
	var front_panel_width := side_center_x - door_half + ROOM_SEAM_OVERLAP

	_add_box(shell, "BackWall", Vector3(0, ROOM_WALL_CENTER_Y, back_center_z), Vector3(shell_width, ROOM_WALL_HEIGHT, wall_depth), color)
	_add_box(shell, "LeftWall", Vector3(-side_center_x, ROOM_WALL_CENTER_Y, 0), Vector3(wall_depth, ROOM_WALL_HEIGHT, shell_depth), color.darkened(0.08))
	_add_box(shell, "RightWall", Vector3(side_center_x, ROOM_WALL_CENTER_Y, 0), Vector3(wall_depth, ROOM_WALL_HEIGHT, shell_depth), color.darkened(0.08))
	_add_box(shell, "FrontWallLeft", Vector3(left_front_center_x, ROOM_WALL_CENTER_Y, front_center_z), Vector3(front_panel_width, ROOM_WALL_HEIGHT, wall_depth), color.darkened(0.04))
	_add_box(shell, "FrontWallRight", Vector3(right_front_center_x, ROOM_WALL_CENTER_Y, front_center_z), Vector3(front_panel_width, ROOM_WALL_HEIGHT, wall_depth), color.darkened(0.04))
	_add_box(shell, "DoorJambLeft", Vector3(-door_half - ROOM_DOOR_TRIM * 0.5, ROOM_WALL_CENTER_Y, front_center_z - 0.2), Vector3(ROOM_DOOR_TRIM, ROOM_WALL_HEIGHT, wall_depth + 0.8), color.lightened(0.04))
	_add_box(shell, "DoorJambRight", Vector3(door_half + ROOM_DOOR_TRIM * 0.5, ROOM_WALL_CENTER_Y, front_center_z - 0.2), Vector3(ROOM_DOOR_TRIM, ROOM_WALL_HEIGHT, wall_depth + 0.8), color.lightened(0.04))
	_add_box(shell, "DoorHeader", Vector3(0, (ROOM_DOOR_HEIGHT + wall_top) * 0.5, front_center_z - 0.2), Vector3(ROOM_DOOR_WIDTH + ROOM_DOOR_TRIM * 2.0, wall_top - ROOM_DOOR_HEIGHT + ROOM_SEAM_OVERLAP, wall_depth + 0.8), color.lightened(0.02))
	_add_box(shell, "DoorPanel", Vector3(0, ROOM_DOOR_HEIGHT * 0.5 - 0.8, front_center_z - wall_depth * 0.55), Vector3(ROOM_DOOR_WIDTH - 2.0, ROOM_DOOR_HEIGHT + 1.6, 1.6), color.darkened(0.18))
	_add_box(shell, "Ceiling", Vector3(0, ROOM_CEILING_Y, 0), Vector3(shell_width, ROOM_CEILING_THICKNESS, shell_depth), color.lightened(0.08))
	_add_indoor_shell_seals(shell, size, color)

func _add_indoor_shell_seals(shell: Node3D, size: Vector2, color: Color) -> void:
	var half_x := size.x * 0.5
	var half_z := size.y * 0.5
	var side_center_x := half_x + ROOM_WALL_THICKNESS * 0.5 - ROOM_SEAM_OVERLAP * 0.5
	var back_center_z := half_z + ROOM_WALL_THICKNESS * 0.5 - ROOM_SEAM_OVERLAP * 0.5
	var front_center_z := -back_center_z
	var shell_width := size.x + ROOM_WALL_THICKNESS * 2.0 + ROOM_SEAM_OVERLAP * 2.0
	var shell_depth := size.y + ROOM_WALL_THICKNESS * 2.0 + ROOM_SEAM_OVERLAP * 2.0
	var seal_color := color.lightened(0.12)
	var corner_color := color.darkened(0.02)
	var top_y := ROOM_CEILING_Y - ROOM_CEILING_THICKNESS * 0.5 + 0.6
	_add_box(shell, "CeilingBackSeal", Vector3(0, top_y, back_center_z - ROOM_WALL_THICKNESS * 0.35), Vector3(shell_width, 5.0, 4.0), seal_color)
	_add_box(shell, "CeilingFrontSeal", Vector3(0, top_y, front_center_z + ROOM_WALL_THICKNESS * 0.35), Vector3(shell_width, 5.0, 4.0), seal_color)
	_add_box(shell, "CeilingLeftSeal", Vector3(-side_center_x + ROOM_WALL_THICKNESS * 0.35, top_y, 0), Vector3(4.0, 5.0, shell_depth), seal_color.darkened(0.04))
	_add_box(shell, "CeilingRightSeal", Vector3(side_center_x - ROOM_WALL_THICKNESS * 0.35, top_y, 0), Vector3(4.0, 5.0, shell_depth), seal_color.darkened(0.04))
	_add_box(shell, "ExteriorBackCeilingFascia", Vector3(0, top_y - 1.0, back_center_z + ROOM_WALL_THICKNESS * 0.35), Vector3(shell_width, 7.0, 4.0), seal_color.darkened(0.02))
	_add_box(shell, "ExteriorFrontCeilingFascia", Vector3(0, top_y - 1.0, front_center_z - ROOM_WALL_THICKNESS * 0.35), Vector3(shell_width, 7.0, 4.0), seal_color.darkened(0.02))
	_add_box(shell, "ExteriorLeftCeilingFascia", Vector3(-side_center_x - ROOM_WALL_THICKNESS * 0.35, top_y - 1.0, 0), Vector3(4.0, 7.0, shell_depth), seal_color.darkened(0.06))
	_add_box(shell, "ExteriorRightCeilingFascia", Vector3(side_center_x + ROOM_WALL_THICKNESS * 0.35, top_y - 1.0, 0), Vector3(4.0, 7.0, shell_depth), seal_color.darkened(0.06))
	_add_box(shell, "ExteriorBackWallTopBelt", Vector3(0, top_y - 0.2, back_center_z + ROOM_WALL_THICKNESS * 0.65), Vector3(shell_width, 4.0, 1.8), seal_color.lightened(0.02))
	_add_box(shell, "ExteriorFrontWallTopBelt", Vector3(0, top_y - 0.2, front_center_z - ROOM_WALL_THICKNESS * 0.65), Vector3(shell_width, 4.0, 1.8), seal_color.lightened(0.02))
	_add_box(shell, "ExteriorLeftWallTopBelt", Vector3(-side_center_x - ROOM_WALL_THICKNESS * 0.65, top_y - 0.2, 0), Vector3(1.8, 4.0, shell_depth), seal_color)
	_add_box(shell, "ExteriorRightWallTopBelt", Vector3(side_center_x + ROOM_WALL_THICKNESS * 0.65, top_y - 0.2, 0), Vector3(1.8, 4.0, shell_depth), seal_color)
	_add_box(shell, "BackLeftCornerSeal", Vector3(-side_center_x + ROOM_WALL_THICKNESS * 0.35, ROOM_WALL_CENTER_Y, back_center_z - ROOM_WALL_THICKNESS * 0.35), Vector3(5.0, ROOM_WALL_HEIGHT, 5.0), corner_color)
	_add_box(shell, "BackRightCornerSeal", Vector3(side_center_x - ROOM_WALL_THICKNESS * 0.35, ROOM_WALL_CENTER_Y, back_center_z - ROOM_WALL_THICKNESS * 0.35), Vector3(5.0, ROOM_WALL_HEIGHT, 5.0), corner_color)
	_add_box(shell, "FrontLeftCornerSeal", Vector3(-side_center_x + ROOM_WALL_THICKNESS * 0.35, ROOM_WALL_CENTER_Y, front_center_z + ROOM_WALL_THICKNESS * 0.35), Vector3(5.0, ROOM_WALL_HEIGHT, 5.0), corner_color)
	_add_box(shell, "FrontRightCornerSeal", Vector3(side_center_x - ROOM_WALL_THICKNESS * 0.35, ROOM_WALL_CENTER_Y, front_center_z + ROOM_WALL_THICKNESS * 0.35), Vector3(5.0, ROOM_WALL_HEIGHT, 5.0), corner_color)

func _add_concept_dressing(root: Node3D, course: Dictionary) -> void:
	var holder := Node3D.new()
	holder.name = "Dressing"
	root.add_child(holder)
	for prop in _stage_props_for_course(course):
		_add_stage_prop_authoring(holder, prop)

func _stage_props_for_course(course: Dictionary) -> Array[Dictionary]:
	match str(course["concept"]):
		"attic":
			return [
				_box_prop(course, "PrankTrunkMaze", Vector3(-82, 13, -34), Vector3(56, 26, 34), Color(0.25, 0.13, 0.07), 8.0),
				_box_prop(course, "BoxStackSwitchback", Vector3(-114, 22, 52), Vector3(42, 44, 46), Color(0.58, 0.42, 0.24), -6.0),
				_box_prop(course, "SheetTunnel", Vector3(24, 19, 76), Vector3(92, 38, 24), Color(0.86, 0.84, 0.76), 0.0),
				_box_prop(course, "FalseFinishGate", Vector3(112, 22, -64), Vector3(54, 44, 8), Color(0.44, 0.18, 0.72), 0.0),
				_box_prop(course, "StringLiftShortcut", Vector3(12, 46, -28), Vector3(134, 8, 10), Color(0.72, 0.55, 0.18), 0.0),
				_box_prop(course, "MarbleTrap", Vector3(88, 5, 42), Vector3(58, 10, 36), Color(0.12, 0.10, 0.14), 14.0),
				_scene_prop(course, "PrankJackInTheBox", "res://assets/gameplay/tracks/attic/props/JackInTheBoxSetpiece.tscn", Vector3(128, 0, -12), -20.0, Vector3(5.2, 5.2, 5.2), "prank_trigger"),
				_scene_prop(course, "AtticBookPile", "res://assets/source/kenney/furniture_kit/books.glb", Vector3(-42, 0, 92), -12.0, Vector3(12, 12, 12)),
			]
		"bedroom":
			return [
				_scene_prop(course, "BedRamp", "res://assets/source/kenney/furniture_kit/bedDouble.glb", Vector3(-118, 0, 62), 0.0, Vector3(18, 18, 18)),
				_box_prop(course, "BlanketTunnel", Vector3(-36, 18, 58), Vector3(94, 36, 28), Color(0.38, 0.46, 0.78), 0.0),
				_scene_prop(course, "BedsideLampBeacon", "res://assets/source/kenney/furniture_kit/lampRoundTable.glb", Vector3(-144, 0, -70), 0.0, Vector3(16, 16, 16), "lamp_beacon"),
				_scene_prop(course, "ToyTriageCorner", "res://assets/source/kenney/furniture_kit/bear.glb", Vector3(122, 0, -42), -24.0, Vector3(18, 18, 18)),
				_box_prop(course, "WaitingLine", Vector3(112, 6, 46), Vector3(82, 12, 8), Color(0.72, 0.55, 0.36), 0.0),
				_box_prop(course, "ToyBlockBarriers", Vector3(-118, 9, -8), Vector3(76, 18, 18), Color(0.78, 0.25, 0.18), 0.0),
				_scene_prop(course, "SoftRoomRug", "res://assets/source/kenney/furniture_kit/rugRectangle.glb", Vector3(48, 0, -58), 8.0, Vector3(25, 25, 25), "soft_surface"),
			]
		"glam_closet":
			return [
				_scene_prop(course, "MirrorArch", "res://assets/source/kenney/furniture_kit/bathroomMirror.glb", Vector3(-140, 18, 8), 90.0, Vector3(22, 22, 22)),
				_box_prop(course, "VanityRunway", Vector3(0, 3, -92), Vector3(190, 6, 18), Color(0.92, 0.72, 0.88), 0.0),
				_box_prop(course, "PerfumeMistEmitter", Vector3(72, 12, -34), Vector3(24, 24, 24), Color(0.95, 0.42, 0.82), 0.0, "perfume_mist"),
				_box_prop(course, "JewelryBoxRamp", Vector3(122, 10, 58), Vector3(60, 20, 36), Color(0.62, 0.18, 0.45), -18.0),
				_box_prop(course, "DisplayPedestals", Vector3(-82, 10, 74), Vector3(88, 20, 26), Color(0.12, 0.08, 0.12), 0.0),
				_box_prop(course, "StatusGate", Vector3(118, 22, 8), Vector3(12, 44, 70), Color(0.95, 0.72, 0.18), 0.0),
				_scene_prop(course, "VanityChair", "res://assets/source/kenney/furniture_kit/chairCushion.glb", Vector3(-112, 0, 82), 20.0, Vector3(16, 16, 16)),
			]
		"playroom":
			return [
				_scene_prop(course, "ToyRingPlatform", "res://assets/source/meshy/playroom_props/boxing_ring.glb", Vector3(0, 0, 0), 0.0, Vector3(20, 20, 20), "arena_center"),
				_box_prop(course, "ChampionRamp", Vector3(42, 8, -74), Vector3(84, 16, 34), Color(0.92, 0.14, 0.12), 0.0, "champion_ramp"),
				_box_prop(course, "BlockGrandstands", Vector3(-116, 22, -54), Vector3(88, 44, 30), Color(0.1, 0.28, 0.9), 0.0),
				_box_prop(course, "MarbleMachine", Vector3(126, 24, 54), Vector3(42, 48, 42), Color(0.08, 0.18, 0.66), 0.0, "marble_machine"),
				_box_prop(course, "TrophyFinishStretch", Vector3(-12, 16, 92), Vector3(128, 32, 12), Color(0.96, 0.72, 0.16), 0.0),
				_scene_prop(course, "PlayroomHalfPipeShortcut", "res://assets/source/kenney/mini_skate/half-pipe.glb", Vector3(-112, 0, 76), 18.0, Vector3(15, 15, 15)),
				_scene_prop(course, "ToyShelfBackdrop", "res://assets/source/kenney/furniture_kit/bookcaseOpen.glb", Vector3(144, 0, 78), -90.0, Vector3(18, 18, 18)),
			]
		"outdoor_playground":
			return [
				_scene_prop(course, "SlideDrop", "res://assets/source/meshy/playground_props/rusty_playground_slide.glb", Vector3(48, 0, -48), -12.0, Vector3(8, 8, 8), "slide_drop"),
				_scene_prop(course, "SwingGate", "res://assets/gameplay/tracks/shared/backyard_optimized/swing_set_low.glb", Vector3(-116, 0, -12), -12.0, Vector3(12, 12, 12), "swing_gate"),
				_scene_prop(course, "HalfPipeBank", "res://assets/source/kenney/mini_skate/half-pipe.glb", Vector3(82, 0, 78), 22.0, Vector3(18, 18, 18)),
				_box_prop(course, "RailShortcut", Vector3(8, 5, 112), Vector3(130, 10, 16), Color(0.12, 0.42, 0.9), 0.0, "rail_shortcut"),
				_box_prop(course, "BrokenBorderGate", Vector3(-142, 18, -82), Vector3(18, 36, 70), Color(0.9, 0.12, 0.1), 0.0),
				_box_prop(course, "ChalkRouteArrows", Vector3(-52, 0.4, 28), Vector3(132, 0.8, 18), Color(0.84, 0.92, 1.0), -18.0),
			]
		"garden":
			return [
				_box_prop(course, "RootGate", Vector3(-64, 20, -28), Vector3(96, 40, 16), Color(0.26, 0.16, 0.08), 0.0),
				_scene_prop(course, "StoneBridge", "res://assets/source/kenney/nature_kit/bridge_stone.glb", Vector3(-14, 0, -88), 0.0, Vector3(16, 16, 16), "stone_bridge"),
				_box_prop(course, "HoseCrossing", Vector3(82, 3, -8), Vector3(138, 6, 8), Color(0.12, 0.46, 0.18), 8.0, "hose_crossing"),
				_scene_prop(course, "FlowerCanopy", "res://assets/source/kenney/nature_kit/flower_purpleA.glb", Vector3(118, 0, 92), 0.0, Vector3(24, 24, 24)),
				_scene_prop(course, "SurvivalMarkers", "res://assets/source/kenney/nature_kit/log_large.glb", Vector3(-102, 0, 84), 18.0, Vector3(18, 18, 18)),
				_scene_prop(course, "LogHazard", "res://assets/source/kenney/nature_kit/log.glb", Vector3(74, 0, 58), -18.0, Vector3(18, 18, 18), "log_hazard"),
			]
		"sandbox":
			return [
				_box_prop(course, "SandRidgeThrone", Vector3(0, 26, 98), Vector3(132, 52, 72), Color(0.74, 0.57, 0.34), 0.0, "sand_throne"),
				_box_prop(course, "OverturnedBucketTunnel", Vector3(-106, 24, -28), Vector3(62, 48, 62), Color(0.1, 0.38, 0.86), 0.0),
				_scene_prop(course, "FossilArch", "res://assets/source/meshy/sandbox_props/trex_skeleton.glb", Vector3(72, 0, 18), -18.0, Vector3(12, 12, 12), "fossil_arch"),
				_box_prop(course, "ShovelRamp", Vector3(100, 8, -96), Vector3(110, 16, 22), Color(0.96, 0.72, 0.16), -16.0, "shovel_ramp"),
				_box_prop(course, "TributePile", Vector3(80, 18, 86), Vector3(68, 36, 46), Color(0.74, 0.22, 0.12), 18.0),
				_box_prop(course, "BermWalls", Vector3(-96, 8, 92), Vector3(110, 16, 20), Color(0.62, 0.46, 0.25), 0.0),
			]
	return []

func _box_prop(course: Dictionary, prop_id: String, local_position: Vector3, box_size: Vector3, color: Color, yaw_degrees := 0.0, gameplay_tag := "", collision_mode := "visual") -> Dictionary:
	return {
		"id": prop_id,
		"kind": "box",
		"box_size": box_size,
		"box_color": color,
		"position": _course_position(course, local_position),
		"yaw_degrees": yaw_degrees,
		"scale": Vector3.ONE,
		"collision_mode": collision_mode,
		"audio_material_id": "",
		"gameplay_tag": gameplay_tag,
	}

func _scene_prop(course: Dictionary, prop_id: String, asset_path: String, local_position: Vector3, yaw_degrees := 0.0, scale := Vector3.ONE, gameplay_tag := "", collision_mode := "visual") -> Dictionary:
	return {
		"id": prop_id,
		"kind": "scene",
		"asset_path": asset_path,
		"box_size": Vector3.ONE,
		"box_color": Color.WHITE,
		"position": _course_position(course, local_position),
		"yaw_degrees": yaw_degrees,
		"scale": scale,
		"collision_mode": collision_mode,
		"audio_material_id": "",
		"gameplay_tag": gameplay_tag,
	}

func _add_stage_prop_authoring(parent: Node3D, prop: Dictionary) -> void:
	var marker := StagePropAuthoring.new()
	marker.name = str(prop.get("id", "StageProp"))
	marker.prop_id = marker.name
	marker.prop_kind = str(prop.get("kind", "box"))
	marker.asset_path = str(prop.get("asset_path", ""))
	marker.box_size = prop.get("box_size", Vector3.ONE) as Vector3
	marker.box_color = prop.get("box_color", Color.WHITE) as Color
	marker.collision_mode = str(prop.get("collision_mode", "visual"))
	marker.audio_material_id = str(prop.get("audio_material_id", ""))
	marker.gameplay_tag = str(prop.get("gameplay_tag", ""))
	marker.position = prop.get("position", Vector3.ZERO) as Vector3
	marker.rotation_degrees.y = float(prop.get("yaw_degrees", 0.0))
	marker.scale = prop.get("scale", Vector3.ONE) as Vector3
	parent.add_child(marker)

func _stage_interactions_for_course(course: Dictionary) -> Array[Dictionary]:
	match str(course["id"]):
		"attic":
			return [
				_interaction_at_cell(course, "PrankTriggerZone", "trigger", Vector3i(1, 1, -2), Vector3(18, 5, 18), {
					"target_node_path": "Dressing/StageProps/PrankJackInTheBox",
					"target_method": "trigger",
					"duration": 0.2,
					"cooldown": 5.0,
					"note": "Triggers the jack-in-the-box prank as racers exit the trunk maze.",
				}),
				_interaction_at_cell(course, "MarbleTrapRelease", "impulse", Vector3i(4, 0, 3), Vector3(18, 5, 18), {
					"impulse": Vector3(3.0, 0.0, 0.0),
					"duration": 0.15,
					"cooldown": 1.2,
					"note": "Small deterministic nudge through the marble trap beat.",
				}),
			]
		"bedroom":
			return [
				_interaction_at_cell(course, "LampBeaconBoostZone", "boost", Vector3i(-5, 0, -3), Vector3(20, 5, 20), {
					"boost_force": 72.0,
					"duration": 0.7,
					"cooldown": 1.0,
					"note": "Warm lamp beacon rewards the safe line.",
				}),
				_interaction_at_cell(course, "RugGripSlowZone", "slow", Vector3i(5, 1, -1), Vector3(48, 5, 24), {
					"speed_multiplier": 0.82,
					"duration": 0.3,
					"note": "Soft rug adds tactile drag without becoming a grind.",
				}),
			]
		"glam_closet":
			return [
				_interaction_at_cell(course, "PerfumeMistZone", "slow", Vector3i(3, 1, 1), Vector3(42, 5, 28), {
					"speed_multiplier": 0.76,
					"duration": 0.35,
					"note": "Readable perfume cloud pressure before the mirror turn.",
				}),
				_interaction_at_cell(course, "JewelryRampBoostZone", "boost", Vector3i(8, 0, 5), Vector3(20, 5, 20), {
					"boost_force": 88.0,
					"duration": 0.7,
					"cooldown": 1.0,
					"note": "Status ramp burst out of the display sequence.",
				}),
			]
		"playroom":
			return [
				_interaction_at_cell(course, "ChampionRampBurst", "boost", Vector3i(5, 1, -3), Vector3(22, 5, 20), {
					"boost_force": 92.0,
					"duration": 0.75,
					"cooldown": 1.0,
					"note": "Launches the arena spectacle without adding a new road contract.",
				}),
				_interaction_at_cell(course, "MarbleMachineRumble", "rumble", Vector3i(8, 0, 2), Vector3(24, 5, 24), {
					"intensity": 1.2,
					"duration": 0.22,
					"cooldown": 0.45,
					"note": "Deterministic toy-marble pressure near the machine.",
				}),
			]
		"outdoor_playground":
			return [
				_interaction_at_cell(course, "SlideDropBoostZone", "boost", Vector3i(0, 1, 4), Vector3(22, 5, 22), {
					"boost_force": 105.0,
					"duration": 0.85,
					"cooldown": 1.0,
					"note": "Speed payoff after committing to the slide line.",
				}),
				_interaction_at_cell(course, "SwingGatePressure", "impulse", Vector3i(-7, 0, 0), Vector3(22, 5, 22), {
					"impulse": Vector3(4.0, 0.0, 0.0),
					"cooldown": 0.75,
					"note": "Forgiving deterministic swing nudge.",
				}),
			]
		"garden":
			return [
				_interaction_at_cell(course, "HoseSplashZone", "slow", Vector3i(5, 0, -1), Vector3(46, 5, 20), {
					"speed_multiplier": 0.78,
					"duration": 0.35,
					"note": "Water crossing adds a short slick beat.",
				}),
				_interaction_at_cell(course, "StoneBridgeExitBoost", "boost", Vector3i(-2, 1, -3), Vector3(18, 5, 18), {
					"boost_force": 74.0,
					"duration": 0.55,
					"cooldown": 1.0,
					"note": "Small reward for the bridge exit line.",
				}),
			]
		"sandbox":
			return [
				_interaction_at_cell(course, "ShovelRampBoostZone", "boost", Vector3i(6, 1, -3), Vector3(22, 5, 22), {
					"boost_force": 96.0,
					"duration": 0.8,
					"cooldown": 1.0,
					"note": "Fast shove into the Rexx stunt beat.",
				}),
				_interaction_at_cell(course, "SandBurstSlowZone", "slow", Vector3i(-2, 0, 4), Vector3(48, 5, 24), {
					"speed_multiplier": 0.74,
					"duration": 0.35,
					"note": "Short sand drag near the throne ridge.",
				}),
			]
	return []

func _interaction_at_cell(course: Dictionary, interaction_id: String, action: String, cell: Vector3i, size: Vector3, options := {}) -> Dictionary:
	var out := {
		"id": interaction_id,
		"action": action,
		"shape": "box",
		"position": _cell_center(course, cell) + Vector3.UP * 1.5,
		"yaw_degrees": float(options.get("yaw_degrees", 0.0)),
		"size": size,
		"radius": float(options.get("radius", 8.0)),
		"duration": float(options.get("duration", 0.8)),
		"cooldown": float(options.get("cooldown", 1.0)),
		"boost_force": float(options.get("boost_force", 82.0)),
		"speed_multiplier": float(options.get("speed_multiplier", 0.75)),
		"impulse": options.get("impulse", Vector3.ZERO),
		"intensity": float(options.get("intensity", 1.0)),
		"target_node_path": str(options.get("target_node_path", "")),
		"target_method": str(options.get("target_method", "trigger")),
		"note": str(options.get("note", "")),
	}
	return out

func _add_stage_interactions(root: Node3D, course: Dictionary) -> void:
	var interactions := _stage_interactions_for_course(course)
	if interactions.is_empty():
		return
	var holder := Node3D.new()
	holder.name = "StageInteractions"
	root.add_child(holder)
	for interaction in interactions:
		var marker := StageInteractionAuthoring.new()
		marker.name = str(interaction.get("id", "StageInteraction"))
		marker.interaction_id = marker.name
		marker.action = str(interaction.get("action", "boost"))
		marker.shape = str(interaction.get("shape", "box"))
		marker.position = interaction.get("position", Vector3.ZERO) as Vector3
		marker.rotation_degrees.y = float(interaction.get("yaw_degrees", 0.0))
		marker.size = interaction.get("size", Vector3(16, 4, 16)) as Vector3
		marker.radius = float(interaction.get("radius", 8.0))
		marker.duration = float(interaction.get("duration", 0.8))
		marker.cooldown = float(interaction.get("cooldown", 1.0))
		marker.boost_force = float(interaction.get("boost_force", 82.0))
		marker.speed_multiplier = float(interaction.get("speed_multiplier", 0.75))
		marker.impulse = interaction.get("impulse", Vector3.ZERO) as Vector3
		marker.intensity = float(interaction.get("intensity", 1.0))
		marker.target_node_path = NodePath(str(interaction.get("target_node_path", "")))
		marker.target_method = str(interaction.get("target_method", "trigger"))
		marker.note = str(interaction.get("note", ""))
		holder.add_child(marker)

func _add_stage_lighting(root: Node3D, course: Dictionary) -> void:
	var holder := Node3D.new()
	holder.name = "Lighting"
	root.add_child(holder)
	var stage_id := str(course["id"])
	if bool(course.get("backyard", false)):
		_add_omni_light(holder, "HeroLandmarkFill", _course_position(course, Vector3(0, 34, 0)), Color(1.0, 0.88, 0.62), 1.25, 180.0)
		_add_omni_light(holder, "RouteReadFill", _course_position(course, Vector3(88, 24, -76)), Color(0.72, 0.86, 1.0), 0.65, 140.0)
		return
	var warm := Color(1.0, 0.78, 0.54)
	var cool := Color(0.62, 0.72, 1.0)
	if stage_id == "glam_closet":
		warm = Color(1.0, 0.52, 0.86)
		cool = Color(0.78, 0.86, 1.0)
	elif stage_id == "playroom":
		warm = Color(1.0, 0.55, 0.32)
		cool = Color(0.42, 0.64, 1.0)
	elif stage_id == "bedroom":
		warm = Color(1.0, 0.74, 0.46)
		cool = Color(0.62, 0.62, 0.88)
	_add_omni_light(holder, "StartReadLight", _course_position(course, Vector3(-84, 34, -72)), warm, 1.2, 150.0)
	_add_omni_light(holder, "HeroLandmarkLight", _course_position(course, Vector3(32, 42, 18)), cool, 0.8, 160.0)
	_add_omni_light(holder, "ReturnLegFill", _course_position(course, Vector3(100, 30, 78)), warm.lightened(0.12), 0.55, 140.0)

func _add_omni_light(parent: Node3D, light_name: String, position: Vector3, color: Color, energy: float, range: float) -> void:
	var light := OmniLight3D.new()
	light.name = light_name
	light.position = position
	light.light_color = color
	light.light_energy = energy
	light.omni_range = range
	light.shadow_enabled = false
	parent.add_child(light)

func _course_position(course: Dictionary, local_position: Vector3) -> Vector3:
	return (course["placement"] as Vector3) + local_position

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
