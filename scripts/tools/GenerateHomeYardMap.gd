@tool
extends SceneTree

const TrackDefinition = preload("res://scripts/track/TrackDefinition.gd")
const TrackGridRoadBuilder = preload("res://scripts/track/TrackGridRoadBuilder.gd")
const TrackMapDefinition = preload("res://scripts/track/TrackMapDefinition.gd")
const TrackMetadataExporter = preload("res://scripts/track/TrackMetadataExporter.gd")
const TrackRuntimeScene = preload("res://scripts/track/TrackRuntimeScene.gd")
const TrackSourceRules = preload("res://scripts/track/TrackSourceRules.gd")

const MAP_ID := "home_yard"
const MAP_DISPLAY_NAME := "Racer House + Yard"
const VERSION := "home_yard_open_world_v1_2026_05_11"
const BASE_DIR := "res://assets/gameplay/tracks/home_yard"
const MODE_DIR := "res://assets/gameplay/tracks/home_yard/modes"
const MAP_SCENE_PATH := "res://assets/gameplay/tracks/home_yard/home_yard_map.tscn"
const MAP_DEFINITION_PATH := "res://assets/gameplay/tracks/home_yard/home_yard_track_map.tres"
const FLOOR_PLAN_PATH := "res://docs/concepts/floor_plans/racer_house_yard_concept_floor_plan.png"
const TRACK_PACKAGES_PATH := "res://assets/gameplay/tracks/track_packages.json"
const GRID_LIBRARY := TrackGridRoadBuilder.DEFAULT_MESH_LIBRARY_PATH
const ROAD_TEXTURE := "res://assets/gameplay/materials/plastic/glossy_plastic_albedo.png"
const CELL_SIZE := Vector3(16.0, 4.0, 16.0)
const ROAD_WIDTH := 16.0
const FLOOR_Y := -1.1
const OUT_OF_BOUNDS_Y := -28.0

const BACKYARD_PLAYGROUND_PATH := "res://assets/gameplay/tracks/shared/backyard_optimized/playground_structure_low.glb"
const BACKYARD_SWING_PATH := "res://assets/gameplay/tracks/shared/backyard_optimized/swing_set_low.glb"
const BACKYARD_FOSSIL_PATH := "res://assets/gameplay/tracks/shared/backyard_optimized/sandbox_fossil_low.glb"
const BACKYARD_GARDEN_PATH := "res://assets/gameplay/tracks/shared/backyard_optimized/garden_log_bush_low.glb"

const COURSES := [
	{"id": "kitchen", "display_name": "Kitchen / Sir Clink", "sky": "noon_clear", "placement": Vector3(-125, 0, 10), "floor": 0, "color": Color(0.92, 0.78, 0.55), "texture": "res://assets/gameplay/materials/tile/kitchen_tile_albedo.png"},
	{"id": "playroom", "display_name": "Playroom / Slammo", "sky": "party_evening", "placement": Vector3(-10, 0, 10), "floor": 0, "color": Color(0.92, 0.70, 0.38), "texture": "res://assets/gameplay/materials/plastic/glossy_plastic_albedo.png"},
	{"id": "outdoor_playground", "display_name": "Outdoor Playground / Dash", "sky": "clear_afternoon", "placement": Vector3(-85, 0, -120), "floor": 0, "color": Color(0.36, 0.18, 0.08), "texture": "res://assets/gameplay/materials/playground/outdoor_playground_floor_albedo.png", "shader": "res://assets/gameplay/materials/grass/playground_grass.gdshader"},
	{"id": "garden", "display_name": "Garden / Moko", "sky": "fresh_morning", "placement": Vector3(-155, 0, -235), "floor": 0, "color": Color(0.32, 0.43, 0.24), "texture": "res://assets/gameplay/materials/garden/garden_dirt_mud_albedo.png"},
	{"id": "sandbox", "display_name": "Sandbox / Rexx", "sky": "hot_afternoon", "placement": Vector3(150, 0, -235), "floor": 0, "color": Color(0.82, 0.66, 0.42), "texture": "res://assets/gameplay/materials/sand/sandbox_sand_albedo.png"},
	{"id": "bedroom", "display_name": "Bedroom / Tuggs", "sky": "soft_morning", "placement": Vector3(0, 64, 66), "floor": 1, "color": Color(0.55, 0.50, 0.66), "texture": "res://assets/gameplay/materials/fabric/plush_fabric_albedo.png"},
	{"id": "glam_closet", "display_name": "Glam Closet / Velva", "sky": "night_city_glow", "placement": Vector3(120, 64, 66), "floor": 1, "color": Color(0.74, 0.42, 0.63), "texture": "res://assets/gameplay/materials/glam/glam_mirror_glitter_albedo.png"},
	{"id": "attic", "display_name": "Attic Mayhem", "sky": "stormy_moonlight_night", "placement": Vector3(60, 116, 18), "floor": 2, "color": Color(0.45, 0.35, 0.25), "texture": "res://assets/gameplay/materials/attic/attic_cardboard_wood_albedo.png"},
]

const MAIN_ZONE_RECTS := [
	{"holder": "Site", "name": "StreetFrontYardEdge", "label": "Street / Front Yard Edge", "pos": Vector3(0, -0.8, 175), "size": Vector3(470, 1, 20), "color": Color(0.24, 0.28, 0.27)},
	{"holder": "Site", "name": "FrontWalkArrivalGarden", "label": "Front Walk / Arrival Garden", "pos": Vector3(-40, -0.8, 140), "size": Vector3(330, 1, 42), "color": Color(0.57, 0.70, 0.42)},
	{"holder": "Site", "name": "Driveway", "label": "Driveway", "pos": Vector3(165, -0.8, 135), "size": Vector3(110, 1, 52), "color": Color(0.55, 0.54, 0.48)},
	{"holder": "MainFloor", "name": "DiningHall", "label": "Dining / Hall", "pos": Vector3(-155, -0.7, 70), "size": Vector3(110, 1, 60), "color": Color(0.78, 0.65, 0.54)},
	{"holder": "MainFloor", "name": "LivingRoom", "label": "Living Room", "pos": Vector3(-35, -0.7, 70), "size": Vector3(130, 1, 60), "color": Color(0.76, 0.62, 0.55)},
	{"holder": "MainFloor", "name": "EntryStairs", "label": "Entry / Stairs", "pos": Vector3(95, -0.7, 70), "size": Vector3(110, 1, 60), "color": Color(0.72, 0.66, 0.56)},
	{"holder": "MainFloor", "name": "KitchenPantry", "label": "Kitchen + Pantry", "pos": Vector3(-150, -0.7, 10), "size": Vector3(120, 1, 58), "color": Color(0.92, 0.78, 0.55)},
	{"holder": "MainFloor", "name": "Playroom", "label": "Playroom", "pos": Vector3(-25, -0.7, 10), "size": Vector3(115, 1, 58), "color": Color(0.92, 0.70, 0.38)},
	{"holder": "MainFloor", "name": "GarageService", "label": "Garage / Service", "pos": Vector3(150, -0.7, 25), "size": Vector3(120, 1, 145), "color": Color(0.63, 0.61, 0.54)},
	{"holder": "Yard", "name": "PatioDeckTransition", "label": "Patio / Deck Transition", "pos": Vector3(-35, -0.75, -55), "size": Vector3(350, 1, 38), "color": Color(0.66, 0.63, 0.57)},
	{"holder": "Yard", "name": "OutdoorPlaygroundSetpieceZone", "label": "Outdoor Playground / Setpiece Zone", "pos": Vector3(0, -0.75, -115), "size": Vector3(420, 1, 58), "color": Color(0.79, 0.56, 0.22)},
	{"holder": "Yard", "name": "GardenZone", "label": "Garden Zone", "pos": Vector3(-155, -0.75, -230), "size": Vector3(120, 1, 130), "color": Color(0.58, 0.72, 0.45)},
	{"holder": "Yard", "name": "LawnRouteBuffer", "label": "Lawn + Route Buffer", "pos": Vector3(10, -0.75, -230), "size": Vector3(210, 1, 130), "color": Color(0.68, 0.78, 0.56)},
	{"holder": "Yard", "name": "Sandbox", "label": "Sandbox", "pos": Vector3(165, -0.75, -230), "size": Vector3(110, 1, 130), "color": Color(0.84, 0.72, 0.43)},
	{"holder": "Yard", "name": "TreeShrubScreen", "label": "Tree / Shrub Screen", "pos": Vector3(0, -0.75, -330), "size": Vector3(420, 1, 38), "color": Color(0.37, 0.59, 0.29)},
]

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(BASE_DIR))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(MODE_DIR))
	_save_map_scene()
	_save_modes()
	_save_map_definition()
	_update_manifest()
	print("Generated %s with %d modes." % [MAP_ID, COURSES.size()])
	quit()

func _save_map_scene() -> void:
	var root := Node3D.new()
	root.name = "HomeYardMap"
	var holders := {}
	for holder_name in ["Site", "MainFloor", "UpperFloor", "Attic", "Yard", "VerticalConnectors", "CourseRoutes", "ValidationCameras", "ConceptReference"]:
		var holder := Node3D.new()
		holder.name = holder_name
		root.add_child(holder)
		holders[holder_name] = holder

	_add_site_base(root, holders)
	_add_floor_plan_zones(root, holders)
	_add_main_floor_shell(root, holders["MainFloor"])
	_add_upper_floor(root, holders["UpperFloor"])
	_add_attic(root, holders["Attic"])
	_add_vertical_connectors(root, holders["VerticalConnectors"])
	_add_decor(root, holders)
	_add_course_route_markers(root, holders["CourseRoutes"])
	_add_validation_cameras(root, holders["ValidationCameras"])
	_add_concept_reference(root, holders["ConceptReference"])
	_add_lighting(root)
	_set_owner_recursive(root, root)
	var packed := PackedScene.new()
	var pack_error := packed.pack(root)
	if pack_error != OK:
		push_error("Could not pack %s: %s" % [MAP_SCENE_PATH, error_string(pack_error)])
		quit(1)
		return
	var save_error := ResourceSaver.save(packed, MAP_SCENE_PATH)
	if save_error != OK:
		push_error("Could not save %s: %s" % [MAP_SCENE_PATH, error_string(save_error)])
		quit(1)
	root.free()

func _save_modes() -> void:
	for course in COURSES:
		var route_cells := _route_cells_for_course(str(course["id"]))
		var layout := _grid_layout_for_course(course, route_cells)
		var race_layout := TrackGridRoadBuilder.race_layout_from_grid_layout(layout, true)
		var definition := _make_definition(course, layout, race_layout.route_points, race_layout.checkpoint_indices, race_layout.spawn_points)
		ResourceSaver.save(definition, _definition_path(str(course["id"])))
		_save_runtime_scene(str(course["id"]))
		var export_error := TrackMetadataExporter.save_json(definition, _metadata_path(str(course["id"])))
		if export_error != OK:
			push_error("Metadata export failed for %s: %s" % [course["id"], error_string(export_error)])
			quit(1)
			return

func _save_runtime_scene(course_id: String) -> void:
	var root := Node3D.new()
	root.name = "%sHomeYardTrack" % course_id.capitalize().replace("_", "")
	root.set_script(TrackRuntimeScene)
	root.set("definition", load(_definition_path(course_id)))
	var packed := PackedScene.new()
	packed.pack(root)
	ResourceSaver.save(packed, _runtime_scene_path(course_id))
	root.free()

func _save_map_definition() -> void:
	var map := TrackMapDefinition.new()
	map.id = MAP_ID
	map.display_name = MAP_DISPLAY_NAME
	map.version = VERSION
	map.map_scene_path = MAP_SCENE_PATH
	map.default_mode_id = "kitchen"
	map.sky_preset_id = "clear_afternoon"
	map.sky_weather = "clear"
	map.sky_top_color = Color(0.52, 0.74, 0.96)
	map.sky_horizon_color = Color(0.78, 0.88, 0.96)
	map.sky_cloud_amount = 0.18
	map.sky_cloud_speed = 0.015
	map.sky_haze_amount = 0.12
	map.sky_light_energy = 2.45
	map.ground_size = Vector2(520, 620)
	map.ground_color = Color(0.48, 0.58, 0.38)
	map.mode_configs = {}
	for course in COURSES:
		var course_id := str(course["id"])
		var definition := load(_definition_path(course_id)) as TrackDefinition
		map.mode_configs[course_id] = {
			"id": course_id,
			"display_name": str(course["display_name"]),
			"version": VERSION,
			"kind": "race",
			"road_source": "road_grid_map",
			"definition_path": _definition_path(course_id),
			"runtime_scene_path": _runtime_scene_path(course_id),
			"metadata_path": _metadata_path(course_id),
			"map_scene_path": MAP_SCENE_PATH,
			"laps": 3,
			"road_visual_style": "kenney_gridmap",
			"road_width": ROAD_WIDTH,
			"reset_mode": "instant_pop",
			"sky_preset_id": definition.sky_preset_id if definition != null else str(course["sky"]),
			"sky_time_of_day": definition.sky_time_of_day if definition != null else 0.5,
			"sky_weather": definition.sky_weather if definition != null else "",
			"sky_top_color": definition.sky_top_color if definition != null else Color(0.58, 0.72, 0.9),
			"sky_horizon_color": definition.sky_horizon_color if definition != null else Color(0.64, 0.72, 0.82),
			"sky_cloud_amount": definition.sky_cloud_amount if definition != null else 0.25,
			"sky_cloud_speed": definition.sky_cloud_speed if definition != null else 0.02,
			"sky_haze_amount": definition.sky_haze_amount if definition != null else 0.18,
			"sky_light_energy": definition.sky_light_energy if definition != null else 2.4,
			"ground_size": Vector2(520, 620),
			"ground_color": definition.ground_color if definition != null else Color(0.48, 0.58, 0.38),
			"ground_texture_path": definition.ground_texture_path if definition != null else str(course.get("texture", "")),
			"ground_shader_path": definition.ground_shader_path if definition != null else str(course.get("shader", "")),
		}
	ResourceSaver.save(map, MAP_DEFINITION_PATH)

func _update_manifest() -> void:
	var manifest := _load_manifest()
	manifest["default_track_id"] = "kitchen"
	if not manifest.has("maps") or not (manifest["maps"] is Dictionary):
		manifest["maps"] = {}
	if not manifest.has("tracks") or not (manifest["tracks"] is Dictionary):
		manifest["tracks"] = {}
	var maps := manifest["maps"] as Dictionary
	maps[MAP_ID] = {
		"id": MAP_ID,
		"display_name": MAP_DISPLAY_NAME,
		"version": VERSION,
		"map_definition_path": MAP_DEFINITION_PATH,
		"map_scene_path": MAP_SCENE_PATH,
		"default_mode_id": "kitchen",
	}
	var tracks := manifest["tracks"] as Dictionary
	for course in COURSES:
		var course_id := str(course["id"])
		tracks[course_id] = {
			"id": course_id,
			"display_name": str(course["display_name"]),
			"version": VERSION,
			"map_id": MAP_ID,
			"mode_id": course_id,
			"scene_path": _runtime_scene_path(course_id),
			"definition_path": _definition_path(course_id),
			"metadata_path": _metadata_path(course_id),
		}
	var file := FileAccess.open(TRACK_PACKAGES_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest, "\t"))
	file.store_string("\n")
	file.close()

func _make_definition(course: Dictionary, layout: Dictionary, route_points: Array[Vector3], checkpoints: Array[int], spawns: Array[Vector4]) -> TrackDefinition:
	var course_id := str(course["id"])
	var old_definition := load("res://assets/gameplay/tracks/%s/%s_track_definition.tres" % [course_id, course_id]) as TrackDefinition
	var definition := TrackDefinition.new()
	definition.id = course_id
	definition.display_name = str(course["display_name"])
	definition.version = VERSION
	definition.set_meta("track_map_id", MAP_ID)
	definition.set_meta("track_mode_id", course_id)
	definition.set_meta("track_mode_kind", course_id)
	definition.set_meta("road_source", "road_grid_map")
	definition.laps = 3
	definition.track_source_id = "road_grid_map"
	definition.progress_rule_id = TrackSourceRules.PROGRESS_ROUTE_LAP
	definition.win_condition_id = TrackSourceRules.WIN_CHECKPOINT_LAPS
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
	definition.runtime_scene_path = _runtime_scene_path(course_id)
	definition.dressing_scene_path = MAP_SCENE_PATH
	definition.preview_dressing_scene_path = MAP_SCENE_PATH
	definition.ground_size = Vector2(520, 620)
	definition.ground_color = Color(0.48, 0.58, 0.38)
	definition.ground_texture_path = str(course.get("texture", ""))
	definition.ground_shader_path = str(course.get("shader", ""))
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
	definition.set_meta("track_map_id", MAP_ID)
	definition.set_meta("track_mode_id", course_id)
	definition.set_meta("track_mode_kind", "race")
	definition.set_meta("road_source", "road_grid_map")
	return definition

func _add_site_base(root: Node3D, holders: Dictionary) -> void:
	var site := holders["Site"] as Node3D
	_add_box(root, site, "WholeSiteGround", Vector3(0, -1.0, -80), Vector3(500, 1, 590), Color(0.42, 0.52, 0.34), true)
	_add_box(root, site, "NorthBackFence", Vector3(0, 12, -365), Vector3(480, 24, 7), Color(0.28, 0.20, 0.13), true)
	_add_box(root, site, "SouthFrontFence", Vector3(0, 12, 190), Vector3(480, 24, 7), Color(0.28, 0.20, 0.13), true)
	_add_box(root, site, "WestSideFence", Vector3(-240, 12, -85), Vector3(7, 24, 555), Color(0.28, 0.20, 0.13), true)
	_add_box(root, site, "EastSideFence", Vector3(240, 12, -85), Vector3(7, 24, 555), Color(0.28, 0.20, 0.13), true)

func _add_floor_plan_zones(root: Node3D, holders: Dictionary) -> void:
	for zone in MAIN_ZONE_RECTS:
		var holder := holders[str(zone["holder"])] as Node3D
		_add_box(root, holder, str(zone["name"]), zone["pos"], zone["size"], zone["color"], true)
		_add_label(root, holder, "%sLabel" % zone["name"], str(zone["label"]), (zone["pos"] as Vector3) + Vector3(0, 3.2, 0), 9.0)

func _add_main_floor_shell(root: Node3D, parent: Node3D) -> void:
	_add_box(root, parent, "ExteriorBackWall", Vector3(-35, 22, -78), Vector3(360, 46, 5), Color(0.56, 0.50, 0.42), true)
	_add_box(root, parent, "ExteriorFrontWall", Vector3(-35, 22, 112), Vector3(360, 46, 5), Color(0.56, 0.50, 0.42), true)
	_add_box(root, parent, "ExteriorWestWall", Vector3(-215, 22, 18), Vector3(5, 46, 190), Color(0.52, 0.47, 0.40), true)
	_add_box(root, parent, "ExteriorEastGarageWall", Vector3(215, 22, 18), Vector3(5, 46, 190), Color(0.52, 0.47, 0.40), true)
	_add_box(root, parent, "RoofMassPlaceholder", Vector3(-35, 48, 18), Vector3(360, 7, 190), Color(0.36, 0.30, 0.25), false)
	_add_box(root, parent, "DiningLivingDivider", Vector3(-95, 22, 70), Vector3(5, 46, 58), Color(0.62, 0.57, 0.50), true)
	_add_box(root, parent, "LivingEntryDivider", Vector3(35, 22, 70), Vector3(5, 46, 58), Color(0.62, 0.57, 0.50), true)
	_add_box(root, parent, "KitchenPlayroomDivider", Vector3(-90, 22, 10), Vector3(5, 46, 58), Color(0.62, 0.57, 0.50), true)
	_add_box(root, parent, "PlayroomGarageDivider", Vector3(35, 22, 10), Vector3(5, 46, 58), Color(0.62, 0.57, 0.50), true)
	_add_box(root, parent, "KitchenPatioThreshold", Vector3(-92, 2, -38), Vector3(110, 4, 5), Color(0.12, 0.36, 0.44), false)
	_add_box(root, parent, "PlayroomPatioThreshold", Vector3(0, 2, -38), Vector3(72, 4, 5), Color(0.12, 0.36, 0.44), false)

func _add_upper_floor(root: Node3D, parent: Node3D) -> void:
	_add_box(root, parent, "UpperFloorDeck", Vector3(60, 63, 66), Vector3(245, 2, 112), Color(0.46, 0.40, 0.48), true)
	_add_box(root, parent, "BedroomZone", Vector3(0, 64, 66), Vector3(110, 1, 90), Color(0.55, 0.50, 0.66), true)
	_add_box(root, parent, "GlamClosetZone", Vector3(120, 64, 66), Vector3(110, 1, 90), Color(0.74, 0.42, 0.63), true)
	_add_box(root, parent, "UpperBackWall", Vector3(60, 88, 8), Vector3(245, 48, 5), Color(0.46, 0.38, 0.43), true)
	_add_box(root, parent, "UpperFrontWall", Vector3(60, 88, 124), Vector3(245, 48, 5), Color(0.46, 0.38, 0.43), true)
	_add_box(root, parent, "UpperLeftWall", Vector3(-65, 88, 66), Vector3(5, 48, 112), Color(0.42, 0.35, 0.40), true)
	_add_box(root, parent, "UpperRightWall", Vector3(185, 88, 66), Vector3(5, 48, 112), Color(0.42, 0.35, 0.40), true)
	_add_box(root, parent, "BedroomGlamDivider", Vector3(60, 88, 66), Vector3(5, 48, 112), Color(0.50, 0.42, 0.48), true)
	_add_label(root, parent, "BedroomLabel", "Bedroom", Vector3(0, 68, 66), 9.0)
	_add_label(root, parent, "GlamClosetLabel", "Glam Closet", Vector3(120, 68, 66), 9.0)

func _add_attic(root: Node3D, parent: Node3D) -> void:
	_add_box(root, parent, "AtticDeck", Vector3(60, 115, 18), Vector3(225, 2, 100), Color(0.48, 0.36, 0.24), true)
	_add_box(root, parent, "AtticStorageZone", Vector3(60, 116, 18), Vector3(205, 1, 82), Color(0.45, 0.35, 0.25), true)
	_add_box(root, parent, "AtticBackWall", Vector3(60, 137, -35), Vector3(225, 42, 5), Color(0.34, 0.27, 0.21), true)
	_add_box(root, parent, "AtticFrontWall", Vector3(60, 137, 72), Vector3(225, 42, 5), Color(0.34, 0.27, 0.21), true)
	_add_box(root, parent, "AtticRoofRidge", Vector3(60, 160, 18), Vector3(230, 8, 20), Color(0.26, 0.21, 0.18), false)
	_add_label(root, parent, "AtticLabel", "Attic / Storage", Vector3(60, 121, 18), 9.0)

func _add_vertical_connectors(root: Node3D, parent: Node3D) -> void:
	_add_box(root, parent, "MainToUpperToyRamp", Vector3(28, 31, 104), Vector3(24, 4, 130), Color(0.14, 0.36, 0.70), true, -28.0)
	_add_box(root, parent, "UpperRampLanding", Vector3(48, 64, 112), Vector3(52, 3, 28), Color(0.16, 0.42, 0.75), true)
	_add_box(root, parent, "UpperToAtticToyRamp", Vector3(92, 89, 34), Vector3(22, 4, 104), Color(0.65, 0.22, 0.18), true, -26.0)
	_add_box(root, parent, "AtticRampLanding", Vector3(94, 116, -16), Vector3(48, 3, 26), Color(0.70, 0.25, 0.20), true)
	_add_label(root, parent, "ToyRampLabel", "Toy ramps connect all floors", Vector3(42, 38, 130), 8.0)

func _add_decor(root: Node3D, holders: Dictionary) -> void:
	var main := holders["MainFloor"] as Node3D
	var upper := holders["UpperFloor"] as Node3D
	var attic := holders["Attic"] as Node3D
	var yard := holders["Yard"] as Node3D
	_add_scene(root, yard, BACKYARD_PLAYGROUND_PATH, Vector3(-85, 0, -120), 10, Vector3(10, 10, 10), "PlaygroundStructure")
	_add_scene(root, yard, BACKYARD_SWING_PATH, Vector3(35, 0, -125), -12, Vector3(9, 9, 9), "SwingSet")
	_add_scene(root, yard, BACKYARD_FOSSIL_PATH, Vector3(150, 0, -235), -18, Vector3(11, 11, 11), "SandboxFossil")
	_add_scene(root, yard, BACKYARD_GARDEN_PATH, Vector3(-155, 0, -235), 24, Vector3(12, 12, 12), "GardenLogBush")
	_add_scene(root, main, "res://assets/source/kenney/furniture_kit/kitchenFridge.glb", Vector3(-196, 2.5, 18), 90, Vector3(8, 8, 8), "KitchenFridge")
	_add_scene(root, main, "res://assets/source/kenney/furniture_kit/kitchenSink.glb", Vector3(-150, 2.5, -20), 0, Vector3(8, 8, 8), "KitchenSink")
	_add_scene(root, main, "res://assets/source/kenney/furniture_kit/table.glb", Vector3(-140, 1.5, 72), 0, Vector3(10, 10, 10), "DiningTable")
	_add_scene(root, main, "res://assets/source/kenney/furniture_kit/bear.glb", Vector3(-22, 1.5, 10), -20, Vector3(9, 9, 9), "PlayroomToyBear")
	_add_scene(root, upper, "res://assets/source/kenney/furniture_kit/bedSingle.glb", Vector3(-20, 66, 68), 90, Vector3(10, 10, 10), "BedroomBed")
	_add_scene(root, upper, "res://assets/source/kenney/furniture_kit/rugRound.glb", Vector3(120, 65, 70), 0, Vector3(12, 12, 12), "GlamRug")
	_add_scene(root, attic, "res://assets/gameplay/tracks/attic/props/old_chest.glb", Vector3(20, 117, 18), 18, Vector3(8, 8, 8), "AtticChest")
	_add_scene(root, attic, "res://assets/gameplay/tracks/attic/props/JackInTheBoxSetpiece.tscn", Vector3(94, 117, 28), -12, Vector3(1.0, 1.0, 1.0), "AtticJackSetpiece")

func _add_course_route_markers(root: Node3D, parent: Node3D) -> void:
	for course in COURSES:
		var route_holder := Node3D.new()
		route_holder.name = "%sRoutePreview" % str(course["id"]).capitalize().replace("_", "")
		parent.add_child(route_holder)
		route_holder.owner = root
		var cells := _route_cells_for_course(str(course["id"]))
		var previous := Vector3.ZERO
		for i in range(cells.size()):
			var point := _cell_center(course, cells[i])
			if i > 0:
				var mid := (previous + point) * 0.5
				var delta := point - previous
				delta.y = 0
				var length := maxf(delta.length(), 1.0)
				var yaw := rad_to_deg(atan2(delta.x, delta.z))
				_add_box(root, route_holder, "RoutePreview%02d" % i, mid + Vector3.UP * 0.08, Vector3(3.2, 0.16, length), (course["color"] as Color).lightened(0.18), false, yaw)
			previous = point

func _add_validation_cameras(root: Node3D, parent: Node3D) -> void:
	_add_camera(root, parent, "OverheadPlanCamera", Vector3(0, 520, -70), Vector3(-90, 0, 0), 115)
	_add_camera(root, parent, "FrontArrivalCamera", Vector3(0, 95, 260), Vector3(-24, 0, 0), 70)
	_add_camera(root, parent, "BackyardCamera", Vector3(-210, 80, -285), Vector3(-18, -38, 0), 72)
	_add_camera(root, parent, "MainFloorRouteCamera", Vector3(-245, 54, 122), Vector3(-14, -62, 0), 70)
	_add_camera(root, parent, "UpperFloorRouteCamera", Vector3(-100, 118, 158), Vector3(-20, -42, 0), 70)
	_add_camera(root, parent, "AtticRouteCamera", Vector3(-45, 166, 92), Vector3(-18, -42, 0), 70)
	_add_camera(root, parent, "RampSideProfileCamera", Vector3(-75, 84, 104), Vector3(-8, -90, 0), 70)

func _add_concept_reference(root: Node3D, parent: Node3D) -> void:
	_add_label(root, parent, "FloorPlanReferenceLabel", "Concept source: docs/concepts/floor_plans/racer_house_yard_concept_floor_plan.png", Vector3(0, 42, 210), 8.0)

func _add_lighting(root: Node3D) -> void:
	var sun := DirectionalLight3D.new()
	sun.name = "HomeYardSun"
	sun.rotation_degrees = Vector3(-45, -35, 0)
	sun.light_energy = 2.3
	root.add_child(sun)
	var world := WorldEnvironment.new()
	world.name = "WorldEnvironment"
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.67, 0.80, 0.94)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.74, 0.78, 0.80)
	env.ambient_light_energy = 0.9
	world.environment = env
	root.add_child(world)

func _route_cells_for_course(course_id: String) -> Array[Vector3i]:
	match course_id:
		"kitchen":
			return _route_from_points([Vector3i(-4, 0, -2), Vector3i(3, 0, -2), Vector3i(3, 0, 2), Vector3i(-2, 0, 2), Vector3i(-2, 0, 4), Vector3i(-5, 0, 4), Vector3i(-5, 0, -1), Vector3i(-4, 0, -1)])
		"playroom":
			return _route_from_points([Vector3i(-4, 0, -2), Vector3i(4, 0, -2), Vector3i(4, 1, 1), Vector3i(1, 1, 1), Vector3i(1, 0, 4), Vector3i(-4, 0, 4), Vector3i(-4, 0, 1), Vector3i(-6, 0, 1), Vector3i(-6, 0, -2)])
		"outdoor_playground":
			return _route_from_points([Vector3i(-8, 0, -4), Vector3i(7, 0, -4), Vector3i(7, 1, -1), Vector3i(3, 1, -1), Vector3i(3, 0, 4), Vector3i(-7, 0, 4), Vector3i(-7, 0, 0), Vector3i(-9, 0, 0), Vector3i(-9, 0, -4)])
		"garden":
			return _route_from_points([Vector3i(-5, 0, -4), Vector3i(4, 0, -4), Vector3i(4, 1, -1), Vector3i(0, 1, -1), Vector3i(0, 0, 5), Vector3i(-6, 0, 5), Vector3i(-6, 0, 1), Vector3i(-8, 0, 1), Vector3i(-8, 0, -4)])
		"sandbox":
			return _route_from_points([Vector3i(-6, 0, -5), Vector3i(7, 0, -5), Vector3i(7, 1, -2), Vector3i(3, 1, -2), Vector3i(3, 0, 5), Vector3i(-7, 0, 5), Vector3i(-7, 0, 1), Vector3i(-9, 0, 1), Vector3i(-9, 0, -5)])
		"bedroom":
			return _route_from_points([Vector3i(-4, 0, -3), Vector3i(4, 0, -3), Vector3i(4, 1, 0), Vector3i(1, 1, 0), Vector3i(1, 0, 3), Vector3i(-5, 0, 3), Vector3i(-5, 0, -1), Vector3i(-6, 0, -1), Vector3i(-6, 0, -3)])
		"glam_closet":
			return _route_from_points([Vector3i(-4, 0, -3), Vector3i(5, 0, -3), Vector3i(5, 1, 0), Vector3i(2, 1, 0), Vector3i(2, 0, 3), Vector3i(-4, 0, 3), Vector3i(-4, 0, 1), Vector3i(-6, 0, 1), Vector3i(-6, 0, -3)])
		"attic":
			return _route_from_points([Vector3i(-6, 0, -3), Vector3i(5, 0, -3), Vector3i(5, 1, 0), Vector3i(1, 1, 0), Vector3i(1, 0, 3), Vector3i(-5, 0, 3), Vector3i(-5, 0, 1), Vector3i(-7, 0, 1), Vector3i(-7, 0, -3)])
	return []

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

func _route_from_points(points: Array) -> Array[Vector3i]:
	var cells: Array[Vector3i] = []
	if points.is_empty():
		return cells
	var cursor := points[0] as Vector3i
	cells.append(cursor)
	for i in range(points.size()):
		var target := points[(i + 1) % points.size()] as Vector3i
		var guard := 0
		var step_index := 0
		var entering_corner := _segment_enters_corner(points, i, cursor, target)
		while cursor != target:
			guard += 1
			if guard > 1000:
				push_error("Route generation exceeded guard walking from %s to %s" % [cursor, target])
				break
			var direction_before_move := _horizontal_direction_to_target(cursor, target)
			var previous_direction := _previous_route_direction(cells)
			var leaving_corner := previous_direction != Vector3i.ZERO and direction_before_move != Vector3i.ZERO and previous_direction != direction_before_move
			var moved_horizontal := false
			if cursor.x != target.x:
				cursor.x += 1 if target.x > cursor.x else -1
				moved_horizontal = true
			elif cursor.z != target.z:
				cursor.z += 1 if target.z > cursor.z else -1
				moved_horizontal = true
			elif cursor.y != target.y:
				push_error("Route needs horizontal movement for vertical transition from %s to %s" % [cursor, target])
				break
			var landing_on_corner := cursor == target and entering_corner
			if moved_horizontal and cursor.y != target.y and not (step_index == 0 and leaving_corner) and not landing_on_corner:
				cursor.y += 1 if target.y > cursor.y else -1
			if i == points.size() - 1 and cursor == cells[0]:
				break
			cells.append(cursor)
			step_index += 1
	return _rotate_route_start_to_straight(cells)

func _tile_item_for_route_cell(route_cells: Array[Vector3i], index: int) -> int:
	var current := route_cells[index]
	var prev := route_cells[(index - 1 + route_cells.size()) % route_cells.size()]
	var next := route_cells[(index + 1) % route_cells.size()]
	if next.y > current.y or prev.y > current.y:
		return TrackGridRoadBuilder.TILE_RAMP
	if index == 0:
		return TrackGridRoadBuilder.TILE_START
	var prev_dir := _horizontal_delta(current, prev)
	var next_dir := _horizontal_delta(current, next)
	return TrackGridRoadBuilder.TILE_STRAIGHT if prev_dir + next_dir == Vector3i.ZERO else TrackGridRoadBuilder.TILE_CORNER

func _basis_for_route_cell(route_cells: Array[Vector3i], index: int, item: int) -> Basis:
	var current := route_cells[index]
	var prev := route_cells[(index - 1 + route_cells.size()) % route_cells.size()]
	var next := route_cells[(index + 1) % route_cells.size()]
	var prev_dir := _horizontal_delta(current, prev)
	var next_dir := _horizontal_delta(current, next)
	if item == TrackGridRoadBuilder.TILE_RAMP:
		var high_dir := next_dir if next.y > current.y else prev_dir
		return _basis_for_forward(Vector3i(-high_dir.x, 0, -high_dir.z))
	if item != TrackGridRoadBuilder.TILE_CORNER and item != TrackGridRoadBuilder.TILE_CORNER_LARGE:
		return _basis_for_forward(next_dir)
	if _right_of(prev_dir) == next_dir:
		return _basis_for_forward(prev_dir)
	if _right_of(next_dir) == prev_dir:
		return _basis_for_forward(next_dir)
	return _basis_for_forward(next_dir)

func _stage_props_for_course(course: Dictionary) -> Array[Dictionary]:
	var id := str(course["id"])
	var placement := course["placement"] as Vector3
	var color := course["color"] as Color
	var cells := _route_cells_for_course(id)
	return [
		{"id": "%s_start_gate" % id, "kind": "scene", "asset_path": "res://assets/source/kenney/toy_car_kit/gate.glb", "position": _cell_center(course, cells[0]) + Vector3(0, 2, 0), "yaw_degrees": 0.0, "scale": Vector3(5, 5, 5), "collision_mode": "visual", "gameplay_tag": "landmark"},
		{"id": "%s_finish_language_panel" % id, "kind": "box", "box_size": Vector3(18, 9, 2), "box_color": color.lightened(0.22), "position": _cell_center(course, cells[1]) + Vector3(0, 5, -9), "yaw_degrees": 0.0, "scale": Vector3.ONE, "collision_mode": "visual", "gameplay_tag": "start_finish"},
		{"id": "%s_landmark_box" % id, "kind": "box", "box_size": Vector3(12, 8, 12), "box_color": color, "position": placement + Vector3(18, 4, 18), "yaw_degrees": 0.0, "scale": Vector3.ONE, "collision_mode": "visual", "gameplay_tag": "landmark"},
		{"id": "%s_route_arrow_left" % id, "kind": "box", "box_size": Vector3(6, 5, 18), "box_color": color.darkened(0.24), "position": _cell_center(course, cells[clampi(cells.size() / 3, 0, cells.size() - 1)]) + Vector3(-10, 3, 0), "yaw_degrees": 20.0, "scale": Vector3.ONE, "collision_mode": "visual", "gameplay_tag": "direction"},
		{"id": "%s_route_arrow_right" % id, "kind": "box", "box_size": Vector3(6, 5, 18), "box_color": color.lightened(0.14), "position": _cell_center(course, cells[clampi((cells.size() * 2) / 3, 0, cells.size() - 1)]) + Vector3(10, 3, 0), "yaw_degrees": -20.0, "scale": Vector3.ONE, "collision_mode": "visual", "gameplay_tag": "direction"},
	]

func _stage_interactions_for_course(course: Dictionary) -> Array[Dictionary]:
	var course_id := str(course["id"])
	var cells := _route_cells_for_course(course_id)
	var boost_index := clampi(cells.size() / 4, 0, cells.size() - 1)
	var rumble_index := clampi(cells.size() / 2, 0, cells.size() - 1)
	return [
		{"id": "%s_boost_pad" % course_id, "action": "boost", "shape": "box", "position": _cell_center(course, cells[boost_index]) + Vector3.UP, "yaw_degrees": 0.0, "size": Vector3(12, 3, 12), "duration": 0.25, "cooldown": 1.0, "boost_force": 24.0, "note": "Home-yard mode boost beat."},
		{"id": "%s_rumble_zone" % course_id, "action": "rumble", "shape": "box", "position": _cell_center(course, cells[rumble_index]) + Vector3.UP, "yaw_degrees": 0.0, "size": Vector3(14, 3, 14), "duration": 0.4, "cooldown": 1.2, "intensity": 0.45, "note": "Home-yard mode texture beat."},
	]

func _apply_sky_preset(definition: TrackDefinition, preset: String) -> void:
	definition.sky_preset_id = preset
	match preset:
		"noon_clear":
			definition.sky_weather = "clear"; definition.sky_top_color = Color(0.44, 0.72, 1.0); definition.sky_horizon_color = Color(0.78, 0.90, 1.0); definition.sky_cloud_amount = 0.16; definition.sky_light_energy = 2.45
		"party_evening":
			definition.sky_weather = "evening"; definition.sky_top_color = Color(0.38, 0.22, 0.58); definition.sky_horizon_color = Color(0.95, 0.48, 0.34); definition.sky_cloud_amount = 0.28; definition.sky_light_energy = 2.1
		"clear_afternoon":
			definition.sky_weather = "clear"; definition.sky_top_color = Color(0.46, 0.70, 0.96); definition.sky_horizon_color = Color(0.82, 0.92, 1.0); definition.sky_cloud_amount = 0.18; definition.sky_light_energy = 2.5
		"fresh_morning":
			definition.sky_weather = "morning"; definition.sky_top_color = Color(0.62, 0.80, 0.95); definition.sky_horizon_color = Color(0.88, 0.94, 0.84); definition.sky_cloud_amount = 0.22; definition.sky_light_energy = 2.3
		"hot_afternoon":
			definition.sky_weather = "hot"; definition.sky_top_color = Color(0.58, 0.74, 0.96); definition.sky_horizon_color = Color(1.0, 0.86, 0.58); definition.sky_cloud_amount = 0.08; definition.sky_light_energy = 2.65
		"soft_morning":
			definition.sky_weather = "soft"; definition.sky_top_color = Color(0.72, 0.78, 0.95); definition.sky_horizon_color = Color(0.98, 0.86, 0.76); definition.sky_cloud_amount = 0.32; definition.sky_light_energy = 2.05
		"night_city_glow":
			definition.sky_weather = "night"; definition.sky_top_color = Color(0.08, 0.07, 0.16); definition.sky_horizon_color = Color(0.36, 0.16, 0.46); definition.sky_cloud_amount = 0.12; definition.sky_light_energy = 1.35
		"stormy_moonlight_night":
			definition.sky_weather = "storm"; definition.sky_top_color = Color(0.08, 0.09, 0.12); definition.sky_horizon_color = Color(0.20, 0.22, 0.28); definition.sky_cloud_amount = 0.62; definition.sky_light_energy = 1.25
	definition.sky_cloud_speed = 0.014
	definition.sky_haze_amount = 0.10

func _checkpoint_indices(route_size: int) -> Array[int]:
	var checkpoints: Array[int] = []
	for i in range(6):
		var index := int(round(float(i) * float(route_size) / 6.0))
		index = clampi(index, 0, route_size - 1)
		if not checkpoints.has(index):
			checkpoints.append(index)
	return checkpoints

func _spawn_slot_data() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for row in range(4):
		for col in range(2):
			out.append({"route_index": 0, "lateral_offset": -2.75 if col == 0 else 2.75, "forward_offset": float(row) * 5.0, "y_offset": 0.8, "yaw_offset_degrees": 0.0})
	return out

func _route_points_for_cells(course: Dictionary, route_cells: Array[Vector3i]) -> Array[Vector3]:
	var points: Array[Vector3] = []
	for cell in route_cells:
		points.append(_cell_center(course, cell))
	return points

func _grid_origin(course: Dictionary) -> Vector3:
	return (course["placement"] as Vector3) - Vector3(CELL_SIZE.x * 0.5, CELL_SIZE.y * 0.5, CELL_SIZE.z * 0.5)

func _cell_center(course: Dictionary, cell: Vector3i) -> Vector3:
	return _grid_origin(course) + Vector3((float(cell.x) + 0.5) * CELL_SIZE.x, (float(cell.y) + 0.5) * CELL_SIZE.y, (float(cell.z) + 0.5) * CELL_SIZE.z)

func _definition_path(course_id: String) -> String:
	return "%s/%s_track_definition.tres" % [MODE_DIR, course_id]

func _runtime_scene_path(course_id: String) -> String:
	return "%s/%s_track.tscn" % [MODE_DIR, course_id]

func _metadata_path(course_id: String) -> String:
	return "%s/%s_track_metadata.json" % [MODE_DIR, course_id]

func _load_manifest() -> Dictionary:
	if not FileAccess.file_exists(TRACK_PACKAGES_PATH):
		return {"default_track_id": "kitchen", "maps": {}, "tracks": {}}
	var file := FileAccess.open(TRACK_PACKAGES_PATH, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed if parsed is Dictionary else {"default_track_id": "kitchen", "maps": {}, "tracks": {}}

func _rotate_route_start_to_straight(cells: Array[Vector3i]) -> Array[Vector3i]:
	for i in range(cells.size()):
		if _is_flat_straight_route_cell(cells, i):
			var rotated: Array[Vector3i] = []
			for offset in range(cells.size()):
				rotated.append(cells[(i + offset) % cells.size()])
			return rotated
	return cells

func _is_flat_straight_route_cell(cells: Array[Vector3i], index: int) -> bool:
	var current := cells[index]
	var prev := cells[(index - 1 + cells.size()) % cells.size()]
	var next := cells[(index + 1) % cells.size()]
	return prev.y == current.y and next.y == current.y and _horizontal_delta(current, prev) + _horizontal_delta(current, next) == Vector3i.ZERO

func _horizontal_direction_to_target(from_cell: Vector3i, target: Vector3i) -> Vector3i:
	if from_cell.x != target.x:
		return Vector3i(1 if target.x > from_cell.x else -1, 0, 0)
	if from_cell.z != target.z:
		return Vector3i(0, 0, 1 if target.z > from_cell.z else -1)
	return Vector3i.ZERO

func _previous_route_direction(cells: Array[Vector3i]) -> Vector3i:
	return Vector3i.ZERO if cells.size() < 2 else _horizontal_delta(cells[cells.size() - 2], cells[cells.size() - 1])

func _segment_enters_corner(points: Array, index: int, segment_start: Vector3i, target: Vector3i) -> bool:
	var direction := _horizontal_direction_to_target(segment_start, target)
	var next_target := points[(index + 2) % points.size()] as Vector3i
	var next_direction := _horizontal_direction_to_target(target, next_target)
	return direction != Vector3i.ZERO and next_direction != Vector3i.ZERO and direction != next_direction

func _horizontal_delta(from_cell: Vector3i, to_cell: Vector3i) -> Vector3i:
	return Vector3i(to_cell.x - from_cell.x, 0, to_cell.z - from_cell.z)

func _right_of(direction: Vector3i) -> Vector3i:
	return Vector3i(direction.z, 0, -direction.x)

func _basis_for_forward(direction: Vector3i) -> Basis:
	return Basis.IDENTITY if direction == Vector3i.ZERO else Basis(Vector3.UP, atan2(float(direction.x), float(direction.z)))

func _orientation_index(basis: Basis) -> int:
	var helper := GridMap.new()
	var index := helper.get_orthogonal_index_from_basis(basis)
	helper.free()
	return index

func _basis_to_array(basis: Basis) -> Array:
	return [[basis.x.x, basis.x.y, basis.x.z], [basis.y.x, basis.y.y, basis.y.z], [basis.z.x, basis.z.y, basis.z.z]]

func _add_box(root: Node3D, parent: Node3D, node_name: String, position: Vector3, size: Vector3, color: Color, collision: bool, yaw_degrees := 0.0) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.name = node_name
	mesh.transform = Transform3D(Basis(Vector3.UP, deg_to_rad(yaw_degrees)), position)
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.72
	if color.a < 1.0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh.material_override = material
	parent.add_child(mesh)
	mesh.owner = root
	if collision:
		var body := StaticBody3D.new()
		body.name = "%sCollision" % node_name
		var shape_node := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		shape_node.shape = shape
		body.add_child(shape_node)
		mesh.add_child(body)
		body.owner = root
		shape_node.owner = root
	return mesh

func _add_scene(root: Node3D, parent: Node3D, path: String, position: Vector3, yaw_degrees: float, scale: Vector3, node_name: String) -> void:
	var packed := load(path)
	if not (packed is PackedScene):
		return
	var instance := (packed as PackedScene).instantiate()
	if not (instance is Node3D):
		instance.queue_free()
		return
	var node := instance as Node3D
	node.name = node_name
	node.transform = Transform3D(Basis(Vector3.UP, deg_to_rad(yaw_degrees)).scaled(scale), position)
	parent.add_child(node)
	_set_owner_recursive(node, root)

func _add_label(root: Node3D, parent: Node3D, node_name: String, text: String, position: Vector3, size: float) -> void:
	var label := Label3D.new()
	label.name = node_name
	label.text = text
	label.position = position
	label.font_size = size
	label.pixel_size = 0.32
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color(0.08, 0.07, 0.05)
	parent.add_child(label)
	label.owner = root

func _add_camera(root: Node3D, parent: Node3D, node_name: String, position: Vector3, rotation_degrees: Vector3, fov: float) -> void:
	var camera := Camera3D.new()
	camera.name = node_name
	camera.position = position
	camera.rotation_degrees = rotation_degrees
	camera.fov = fov
	parent.add_child(camera)
	camera.owner = root

func _set_owner_recursive(node: Node, owner: Node) -> void:
	for child in node.get_children():
		child.owner = owner
		_set_owner_recursive(child, owner)
