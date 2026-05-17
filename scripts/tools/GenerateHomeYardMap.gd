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
const FLOOR_PLAN_PATH := "res://docs/story_bible/concepts/floor_plans/racer_house_yard_concept_floor_plan.png"
const TRACK_PACKAGES_PATH := "res://assets/gameplay/tracks/track_packages.json"
const GRID_LIBRARY := TrackGridRoadBuilder.DEFAULT_MESH_LIBRARY_PATH
const ROAD_TEXTURE := "res://assets/gameplay/materials/plastic/glossy_plastic_albedo.png"
const CELL_SIZE := Vector3(16.0, 4.0, 16.0)
const ROAD_WIDTH := 16.0
const ROAD_FLOOR_CLEARANCE := 0.55
const FLOOR_Y := -1.1
const OUT_OF_BOUNDS_Y := -28.0
const PLAN_CONTRACT := {
	"source": "racer_house_yard_concept_floor_plan.png",
	"selected_alternative": "Architecture-First",
	"site_orientation": "front/street south, backyard north",
	"style_contract": "toy-scale craftsman suburban house with legible porch, garage/service edge, patio-to-yard hinge, upper bedroom/glam inset, and gabled attic/storage volume",
	"world_scale": "1 floor-plan foot ~= 4 Godot units; RoadGridMap cell is 16 x 16 units",
	"floor_heights": {"main": 0.0, "upper": 64.0, "attic": 116.0},
	"shell_ownership": "ExteriorShell/Roof/Foundation/Openings/PorchesDecks/GarageService own exterior assemblies; floor holders own interior partitions, room finishes, props, lighting, route aids, and localized collision only.",
	"route_contract": "Each course declares zone bounds, route bounds, road-surface elevation, and obstacle exclusion before decor placement.",
}

const INTERIOR_WALL_SCHEDULE := [
	{"id": "DiningLivingDivider", "floor": "main", "owner": "interior_partition", "axis": "x", "x": -95.0, "start": 16.0, "end": 106.0, "base_y": 0.0, "height": 46.0, "connected_zones": ["dining_hall", "living_room"], "opening_span": Vector2.ZERO, "threshold_datum": 0.05, "owner_skill": "floor-plan-architect", "confidence": "inferred_from_existing_home_yard_contract"},
	{"id": "LivingEntryDivider", "floor": "main", "owner": "interior_partition", "axis": "x", "x": 18.0, "start": 16.0, "end": 106.0, "base_y": 0.0, "height": 46.0, "connected_zones": ["living_room", "entry_stairs"], "opening_span": Vector2.ZERO, "threshold_datum": 0.05, "owner_skill": "floor-plan-architect", "confidence": "inferred_from_existing_home_yard_contract"},
	{"id": "KitchenPlayroomDivider", "floor": "main", "owner": "interior_partition", "axis": "x", "x": -92.0, "start": -86.0, "end": 16.0, "base_y": 0.0, "height": 46.0, "connected_zones": ["kitchen_pantry", "playroom"], "opening_span": Vector2.ZERO, "threshold_datum": 0.05, "owner_skill": "floor-plan-architect", "confidence": "inferred_from_existing_home_yard_contract"},
	{"id": "PlayroomGarageDivider", "floor": "main", "owner": "interior_partition", "axis": "x", "x": 62.0, "start": -86.0, "end": 106.0, "base_y": 0.0, "height": 46.0, "connected_zones": ["playroom", "garage_service"], "opening_span": Vector2(44.0, 64.0), "threshold_datum": 0.05, "owner_skill": "floor-plan-architect", "confidence": "inferred_from_existing_home_yard_contract"},
	{"id": "KitchenDiningCasedOpening", "floor": "main", "owner": "interior_partition", "axis": "z", "z": 16.0, "start": -214.0, "end": -40.0, "base_y": 0.0, "height": 46.0, "connected_zones": ["kitchen_pantry", "dining_hall"], "opening_span": Vector2(-168.0, -122.0), "threshold_datum": 0.05, "owner_skill": "floor-plan-architect", "confidence": "inferred_from_existing_home_yard_contract"},
	{"id": "PlayroomLivingCasedOpening", "floor": "main", "owner": "interior_partition", "axis": "z", "z": 16.0, "start": -40.0, "end": 62.0, "base_y": 0.0, "height": 46.0, "connected_zones": ["playroom", "living_room"], "opening_span": Vector2(-8.0, 32.0), "threshold_datum": 0.05, "owner_skill": "floor-plan-architect", "confidence": "inferred_from_existing_home_yard_contract"},
	{"id": "GarageInteriorBackWall", "floor": "main", "owner": "interior_partition", "axis": "z", "z": -18.0, "start": 62.0, "end": 214.0, "base_y": 0.0, "height": 46.0, "connected_zones": ["garage_service", "house_service_threshold"], "opening_span": Vector2.ZERO, "threshold_datum": 0.05, "owner_skill": "floor-plan-architect", "confidence": "inferred_from_existing_home_yard_contract"},
	{"id": "BedroomGlamCasedOpening", "floor": "upper", "owner": "interior_partition", "axis": "x", "x": 62.0, "start": 8.0, "end": 124.0, "base_y": 64.0, "height": 48.0, "connected_zones": ["bedroom_zone", "glam_closet_zone"], "opening_span": Vector2(52.0, 82.0), "threshold_datum": 64.60, "owner_skill": "floor-plan-architect", "confidence": "inferred_from_existing_home_yard_contract"},
	{"id": "AtticWestKneePartition", "floor": "attic", "owner": "interior_partition", "axis": "x", "x": -56.0, "start": -36.0, "end": 72.0, "base_y": 116.0, "height": 18.0, "connected_zones": ["attic_storage_zone", "west_knee_storage"], "opening_span": Vector2.ZERO, "threshold_datum": 116.60, "owner_skill": "floor-plan-architect", "confidence": "aligned_to_upper_attic_roof_contract"},
	{"id": "AtticEastKneePartition", "floor": "attic", "owner": "interior_partition", "axis": "x", "x": 176.0, "start": -36.0, "end": 72.0, "base_y": 116.0, "height": 18.0, "connected_zones": ["attic_storage_zone", "east_knee_storage"], "opening_span": Vector2.ZERO, "threshold_datum": 116.60, "owner_skill": "floor-plan-architect", "confidence": "aligned_to_upper_attic_roof_contract"},
	{"id": "AtticStorageBackPartition", "floor": "attic", "owner": "interior_partition", "axis": "z", "z": -18.0, "start": 84.0, "end": 148.0, "base_y": 116.0, "height": 24.0, "connected_zones": ["attic_storage_zone", "attic_access_storage"], "opening_span": Vector2.ZERO, "threshold_datum": 116.60, "owner_skill": "floor-plan-architect", "confidence": "aligned_to_upper_attic_roof_contract"},
]

const BACKYARD_PLAYGROUND_PATH := "res://assets/gameplay/tracks/shared/backyard_optimized/playground_structure_low.glb"
const BACKYARD_SWING_PATH := "res://assets/gameplay/tracks/shared/backyard_optimized/swing_set_low.glb"
const BACKYARD_FOSSIL_PATH := "res://assets/gameplay/tracks/shared/backyard_optimized/sandbox_fossil_low.glb"
const BACKYARD_GARDEN_PATH := "res://assets/gameplay/tracks/shared/backyard_optimized/garden_log_bush_low.glb"
const TOYBOX_TREE_SWING_PATH := "res://assets/gameplay/tracks/home_yard/props/toybox_tree_swing/stylized_realistic_tree_tire_swing.glb"

const COURSES := [
	{"id": "kitchen", "display_name": "Kitchen / Sir Clink", "sky": "noon_clear", "placement": Vector3(-150, 0.60, -38), "floor": 0, "color": Color(0.92, 0.78, 0.55), "texture": "res://assets/gameplay/materials/tile/kitchen_tile_albedo.png"},
	{"id": "playroom", "display_name": "Playroom / Slammo", "sky": "party_evening", "placement": Vector3(-32, 0.60, -38), "floor": 0, "color": Color(0.92, 0.70, 0.38), "texture": "res://assets/gameplay/materials/plastic/glossy_plastic_albedo.png"},
	{"id": "outdoor_playground", "display_name": "Outdoor Playground / Dash", "sky": "clear_afternoon", "placement": Vector3(-45, 0.90, -176), "floor": 0, "color": Color(0.36, 0.18, 0.08), "texture": "res://assets/gameplay/materials/playground/outdoor_playground_floor_albedo.png", "shader": "res://assets/gameplay/materials/grass/playground_grass.gdshader"},
	{"id": "garden", "display_name": "Garden / Moko", "sky": "fresh_morning", "placement": Vector3(-164, 0.90, -270), "floor": 0, "color": Color(0.32, 0.43, 0.24), "texture": "res://assets/gameplay/materials/garden/garden_dirt_mud_albedo.png"},
	{"id": "sandbox", "display_name": "Sandbox / Rexx", "sky": "hot_afternoon", "placement": Vector3(156, 0.90, -270), "floor": 0, "color": Color(0.82, 0.66, 0.42), "texture": "res://assets/gameplay/materials/sand/sandbox_sand_albedo.png"},
	{"id": "bedroom", "display_name": "Bedroom / Tuggs", "sky": "soft_morning", "placement": Vector3(0, 65.20, 66), "floor": 1, "color": Color(0.55, 0.50, 0.66), "texture": "res://assets/gameplay/materials/fabric/plush_fabric_albedo.png"},
	{"id": "glam_closet", "display_name": "Glam Closet / Velva", "sky": "night_city_glow", "placement": Vector3(122, 65.20, 66), "floor": 1, "color": Color(0.74, 0.42, 0.63), "texture": "res://assets/gameplay/materials/glam/glam_mirror_glitter_albedo.png"},
	{"id": "attic", "display_name": "Attic Mayhem", "sky": "stormy_moonlight_night", "placement": Vector3(60, 117.20, 18), "floor": 2, "color": Color(0.45, 0.35, 0.25), "texture": "res://assets/gameplay/materials/attic/attic_cardboard_wood_albedo.png"},
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
	root.set_meta("floor_plan_contract", PLAN_CONTRACT)
	root.set_meta("interior_wall_schedule", INTERIOR_WALL_SCHEDULE)
	root.set_meta("route_envelopes", _all_route_envelopes())
	root.set_meta("clearance_conflicts", [])
	var holders := {}
	for holder_name in ["Site", "Foundation", "ExteriorShell", "Roof", "Openings", "PorchesDecks", "GarageService", "MainFloor", "UpperFloor", "Attic", "Yard", "VerticalConnectors", "CourseRoutes", "Collision", "ValidationCameras", "ConceptReference"]:
		var holder := Node3D.new()
		holder.name = holder_name
		root.add_child(holder)
		holders[holder_name] = holder

	_add_site_base(root, holders)
	_add_foundation(root, holders["Foundation"])
	_add_floor_plan_zones(root, holders)
	_add_exterior_architecture(root, holders["ExteriorShell"])
	_add_exterior_wall_system(root, holders["ExteriorShell"])
	_add_opening_assemblies(root, holders["Openings"])
	_add_porch_deck_system(root, holders["PorchesDecks"])
	_add_garage_service_system(root, holders["GarageService"])
	_add_roof_system(root, holders["Roof"])
	_add_main_floor_interior(root, holders["MainFloor"])
	_add_upper_floor_interior(root, holders["UpperFloor"])
	_add_attic_interior(root, holders["Attic"])
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
	_add_box(root, site, "WholeSiteGround", Vector3(0, -1.15, -85), Vector3(520, 1, 610), Color(0.36, 0.48, 0.30), true)
	_add_box(root, site, "StreetFrontYardEdge", Vector3(0, -0.65, 190), Vector3(520, 1, 34), Color(0.20, 0.22, 0.22), true)
	_add_box(root, site, "ConcreteStreetCurb", Vector3(0, 0.1, 170), Vector3(520, 2.2, 4), Color(0.66, 0.66, 0.60), false)
	_add_box(root, site, "PublicSidewalk", Vector3(0, -0.30, 158), Vector3(480, 1.0, 10), Color(0.62, 0.62, 0.57), true)
	_add_box(root, site, "FrontWalkArrivalGarden", Vector3(-50, -0.55, 142), Vector3(170, 1, 18), Color(0.74, 0.74, 0.66), true)
	_add_box(root, site, "FrontEntryWalk", Vector3(-50, -0.45, 114), Vector3(28, 1.1, 72), Color(0.68, 0.66, 0.60), true)
	_add_box(root, site, "FrontWalkSteppingStoneA", Vector3(-50, 0.05, 132), Vector3(20, 0.4, 8), Color(0.52, 0.52, 0.48), false)
	_add_box(root, site, "FrontWalkSteppingStoneB", Vector3(-50, 0.05, 106), Vector3(20, 0.4, 8), Color(0.54, 0.54, 0.49), false)
	_add_box(root, site, "Driveway", Vector3(158, -0.45, 118), Vector3(112, 1.1, 126), Color(0.46, 0.46, 0.43), true)
	_add_box(root, site, "DrivewayExpansionJointA", Vector3(158, 0.2, 92), Vector3(112, 0.14, 1.2), Color(0.27, 0.27, 0.25), false)
	_add_box(root, site, "DrivewayExpansionJointB", Vector3(158, 0.2, 142), Vector3(112, 0.14, 1.2), Color(0.27, 0.27, 0.25), false)
	_add_box(root, site, "FrontFoundationPlantingLeft", Vector3(-130, -0.35, 103), Vector3(120, 1.2, 14), Color(0.22, 0.42, 0.18), true)
	_add_box(root, site, "FrontFoundationPlantingRight", Vector3(28, -0.35, 103), Vector3(72, 1.2, 14), Color(0.24, 0.44, 0.20), true)
	_add_box(root, site, "MailboxPost", Vector3(104, 6, 154), Vector3(4, 12, 4), Color(0.20, 0.12, 0.08), false)
	_add_box(root, site, "MailboxBox", Vector3(104, 14, 151), Vector3(14, 8, 8), Color(0.25, 0.27, 0.29), false)
	_add_box(root, site, "ServiceTrashBinA", Vector3(222, 8, 46), Vector3(12, 16, 14), Color(0.12, 0.22, 0.18), false)
	_add_box(root, site, "ServiceTrashBinB", Vector3(238, 8, 46), Vector3(12, 16, 14), Color(0.10, 0.16, 0.22), false)
	_add_box(root, site, "NorthBackFence", Vector3(0, 12, -374), Vector3(500, 24, 7), Color(0.28, 0.20, 0.13), true)
	_add_box(root, site, "SouthFrontFence", Vector3(0, 12, 206), Vector3(500, 24, 7), Color(0.28, 0.20, 0.13), true)
	_add_box(root, site, "WestSideFence", Vector3(-250, 12, -84), Vector3(7, 24, 580), Color(0.28, 0.20, 0.13), true)
	_add_box(root, site, "EastSideFence", Vector3(250, 12, -84), Vector3(7, 24, 580), Color(0.28, 0.20, 0.13), true)
	for i in range(7):
		var x := -210.0 + float(i) * 42.0
		_add_box(root, site, "FrontShrubMass%02d" % i, Vector3(x, 2.2, 130 + float(i % 2) * 5.0), Vector3(20, 5, 12), Color(0.18, 0.38, 0.18).lightened(float(i % 3) * 0.04), false)

func _add_floor_plan_zones(root: Node3D, holders: Dictionary) -> void:
	var yard := holders["Yard"] as Node3D
	_add_yard_plan(root, yard)

func _add_foundation(root: Node3D, parent: Node3D) -> void:
	parent.set_meta("plan_role", "foundation/plinth and grade contact from floor-plan contract")
	var stone := Color(0.42, 0.39, 0.34)
	_add_box(root, parent, "HouseContinuousFoundationPlinth", Vector3(0, 2.8, 10), Vector3(448, 7, 214), stone, false)
	_add_box(root, parent, "GarageSlabApron", Vector3(154, 0.6, 124), Vector3(116, 2.0, 36), Color(0.52, 0.51, 0.47), true)
	_add_box(root, parent, "FrontPorchPierLeft", Vector3(-96, 5, 130), Vector3(14, 10, 14), stone.darkened(0.04), false)
	_add_box(root, parent, "FrontPorchPierRight", Vector3(-2, 5, 130), Vector3(14, 10, 14), stone.darkened(0.04), false)
	_add_box(root, parent, "BackDeckPierWest", Vector3(-104, 5, -114), Vector3(10, 10, 10), stone.darkened(0.08), false)
	_add_box(root, parent, "BackDeckPierEast", Vector3(20, 5, -114), Vector3(10, 10, 10), stone.darkened(0.08), false)

func _add_main_floor_interior(root: Node3D, parent: Node3D) -> void:
	parent.set_meta("plan_role", "main floor interior only; exterior shell is owned by ExteriorShell/Openings/Roof/Foundation")
	var finishes := _add_child_holder(root, parent, "RoomFinishes", "main floor floors, baseboards, interior finishes, and route-facing room set dressing")
	var walls := _add_child_holder(root, parent, "InteriorWalls", "contract-generated main floor interior partitions only")
	var wall := Color(0.64, 0.58, 0.50)
	_add_room_floor(root, finishes, "DiningHall", Vector3(-152, -0.55, 58), Vector3(114, 1.2, 92), Color(0.62, 0.48, 0.35))
	_add_room_floor(root, finishes, "LivingRoom", Vector3(-38, -0.55, 58), Vector3(114, 1.2, 92), Color(0.50, 0.43, 0.36))
	_add_room_floor(root, finishes, "EntryStairs", Vector3(52, -0.55, 58), Vector3(66, 1.2, 92), Color(0.58, 0.53, 0.45))
	_add_room_floor(root, finishes, "GarageService", Vector3(146, -0.55, 18), Vector3(124, 1.2, 172), Color(0.42, 0.42, 0.39))
	_add_room_floor(root, finishes, "KitchenPantry", Vector3(-150, -0.55, -38), Vector3(118, 1.2, 96), Color(0.78, 0.68, 0.50))
	_add_room_floor(root, finishes, "Playroom", Vector3(-32, -0.55, -38), Vector3(118, 1.2, 96), Color(0.76, 0.58, 0.30))
	_add_interior_partitions_from_schedule(root, walls, "main", wall)
	_add_box(root, finishes, "KitchenPatioThresholdInterior", Vector3(-46, 1.0, -86), Vector3(56, 2.0, 8), Color(0.16, 0.24, 0.24), false)
	_add_box(root, finishes, "PlayroomPatioThresholdInterior", Vector3(20, 1.0, -86), Vector3(42, 2.0, 8), Color(0.16, 0.24, 0.24), false)
	_add_box(root, finishes, "KitchenCabinetRunBack", Vector3(-150, 4, -82), Vector3(105, 8, 10), Color(0.38, 0.20, 0.10), false)
	_add_box(root, finishes, "KitchenIsland", Vector3(-150, 4, -22), Vector3(62, 8, 30), Color(0.52, 0.34, 0.18), false)
	_add_kitchen_readability_system(root, parent)
	_add_box(root, finishes, "LivingSofa", Vector3(-34, 5, 76), Vector3(66, 10, 16), Color(0.28, 0.34, 0.42), false)
	_add_box(root, finishes, "EntryStairBlockout", Vector3(50, 8, 70), Vector3(42, 16, 46), Color(0.42, 0.30, 0.20), false)

func _add_kitchen_readability_system(root: Node3D, parent: Node3D) -> void:
	var holder := Node3D.new()
	holder.name = "KitchenRaceReadabilityKit"
	holder.set_meta("player_readability_contract", {
		"course_id": "kitchen",
		"surface": "blue taped toy-track mat over warm kitchen tile",
		"edge_treatment": "yellow curb stripes and low red/cream boundary blocks",
		"landmarks": ["fridge wall", "sink island", "pantry boxes", "finish banner"],
		"first_seconds": "start grid faces a high-contrast straight with arrows and a visible first corner",
	})
	parent.add_child(holder)
	holder.owner = root
	var course := _course_by_id("kitchen")
	var cells := _route_cells_for_course("kitchen")
	var points: Array[Vector3] = []
	for cell in cells:
		points.append(_cell_center(course, cell))
	var mat_color := Color(0.06, 0.42, 0.86)
	var edge_color := Color(1.00, 0.78, 0.12)
	for i in range(points.size()):
		var a := points[i]
		var b := points[(i + 1) % points.size()]
		_add_readable_route_segment(root, holder, "KitchenReadableRoute%02d" % i, a, b, mat_color, edge_color)
	for i in range(points.size()):
		var point := points[i]
		_add_box(root, holder, "KitchenCornerCurb%02d" % i, point + Vector3(0, 0.92, 0), Vector3(18, 1.2, 18), Color(0.92, 0.18, 0.08), false)
		_add_box(root, holder, "KitchenCornerArrow%02d" % i, point + Vector3(0, 1.55, -7), Vector3(12, 0.8, 3), edge_color, false, 20.0 * float((i % 2) * 2 - 1))
	var start := points[0]
	_add_box(root, holder, "KitchenStartFinishFloorBand", start + Vector3(0, 1.35, 0), Vector3(28, 0.7, 4), Color(1.0, 0.95, 0.72), false, 90)
	_add_box(root, holder, "KitchenStartFinishLeftPost", start + Vector3(-12, 8, -9), Vector3(3, 14, 3), Color(0.70, 0.08, 0.06), false)
	_add_box(root, holder, "KitchenStartFinishRightPost", start + Vector3(12, 8, -9), Vector3(3, 14, 3), Color(0.70, 0.08, 0.06), false)
	_add_box(root, holder, "KitchenStartFinishBanner", start + Vector3(0, 16, -9), Vector3(32, 6, 3), Color(1.0, 0.78, 0.18), false)
	_add_box(root, holder, "KitchenFirstTurnBillboard", points[1] + Vector3(10, 8, 0), Vector3(4, 12, 22), Color(0.10, 0.24, 0.62), false)
	_add_box(root, holder, "KitchenPantryStackLandmarkA", Vector3(-107, 6, -66), Vector3(12, 12, 10), Color(0.86, 0.35, 0.16), false)
	_add_box(root, holder, "KitchenPantryStackLandmarkB", Vector3(-108, 16, -66), Vector3(10, 8, 8), Color(0.95, 0.68, 0.20), false)
	_add_box(root, holder, "KitchenSinkIslandInfieldEdge", Vector3(-150, 9, -22), Vector3(66, 3, 34), Color(0.25, 0.14, 0.08), false)
	_add_box(root, holder, "KitchenFridgeLandmarkPanel", Vector3(-204, 16, -62), Vector3(4, 26, 28), Color(0.86, 0.92, 0.95), false)
	_add_box(root, holder, "KitchenWarmUndercabinetGlow", Vector3(-150, 11, -75), Vector3(98, 2, 2), Color(1.0, 0.76, 0.32), false)

func _add_readable_route_segment(root: Node3D, parent: Node3D, node_name: String, a: Vector3, b: Vector3, mat_color: Color, edge_color: Color) -> void:
	var delta := b - a
	delta.y = 0
	var length := maxf(delta.length(), 1.0)
	var yaw := rad_to_deg(atan2(delta.x, delta.z))
	var mid := (a + b) * 0.5
	var forward := delta.normalized()
	var right := Vector3(forward.z, 0, -forward.x)
	_add_box(root, parent, "%sMat" % node_name, mid + Vector3(0, 0.72, 0), Vector3(15.0, 0.34, length), mat_color, false, yaw)
	_add_box(root, parent, "%sLeftEdge" % node_name, mid + right * 8.8 + Vector3(0, 1.05, 0), Vector3(1.8, 1.1, length), edge_color, false, yaw)
	_add_box(root, parent, "%sRightEdge" % node_name, mid - right * 8.8 + Vector3(0, 1.05, 0), Vector3(1.8, 1.1, length), edge_color, false, yaw)
	_add_box(root, parent, "%sDirectionTickA" % node_name, mid + forward * (length * 0.18) + Vector3(0, 1.42, 0), Vector3(6.0, 0.7, 2.0), Color(1.0, 1.0, 0.86), false, yaw)
	_add_box(root, parent, "%sDirectionTickB" % node_name, mid + forward * (length * 0.34) + Vector3(0, 1.42, 0), Vector3(3.4, 0.7, 2.0), Color(1.0, 1.0, 0.86), false, yaw)

func _add_upper_floor_interior(root: Node3D, parent: Node3D) -> void:
	parent.set_meta("plan_role", "upper floor interior only; exterior dormer shell and roof are owned by ExteriorShell/Roof/Openings")
	var finishes := _add_child_holder(root, parent, "RoomFinishes", "upper floor floors, baseboards, interior finishes, and course dressing")
	var walls := _add_child_holder(root, parent, "InteriorWalls", "contract-generated upper floor interior partitions only")
	var wall := Color(0.57, 0.51, 0.43)
	_add_room_floor(root, finishes, "UpperFloorDeck", Vector3(62, 63, 66), Vector3(250, 2, 118), Color(0.46, 0.40, 0.34))
	_add_room_floor(root, finishes, "BedroomZone", Vector3(0, 64, 66), Vector3(116, 1.2, 92), Color(0.58, 0.52, 0.43))
	_add_room_floor(root, finishes, "GlamClosetZone", Vector3(122, 64, 66), Vector3(112, 1.2, 92), Color(0.60, 0.52, 0.45))
	_add_interior_partitions_from_schedule(root, walls, "upper", wall)
	_add_box(root, finishes, "BedroomClosetBuiltIn", Vector3(-48, 72, 22), Vector3(22, 16, 28), Color(0.32, 0.24, 0.18), false)
	_add_box(root, finishes, "BedroomDeskNook", Vector3(38, 69, 24), Vector3(34, 10, 16), Color(0.40, 0.28, 0.18), false)
	_add_box(root, finishes, "GlamWardrobeRun", Vector3(166, 72, 66), Vector3(28, 16, 78), Color(0.34, 0.20, 0.28), false)
	_add_box(root, finishes, "GlamMirrorWall", Vector3(122, 76, 12), Vector3(54, 24, 1.0), Color(0.60, 0.72, 0.82, 0.55), false)

func _add_attic_interior(root: Node3D, parent: Node3D) -> void:
	parent.set_meta("plan_role", "attic/storage interior partitions under measured upper gable roof; exterior gables and roof are owned by Roof")
	var finishes := _add_child_holder(root, parent, "RoomFinishes", "attic deck, storage floor, rafters, and storage dressing")
	var walls := _add_child_holder(root, parent, "InteriorPartitions", "contract-generated attic knee/storage partitions only")
	_add_room_floor(root, finishes, "AtticDeck", Vector3(60, 115, 18), Vector3(230, 2, 104), Color(0.45, 0.33, 0.22))
	_add_room_floor(root, finishes, "AtticStorageZone", Vector3(60, 116, 18), Vector3(202, 1.2, 80), Color(0.48, 0.36, 0.24))
	_add_interior_partitions_from_schedule(root, walls, "attic", Color(0.34, 0.27, 0.21))
	_add_box(root, finishes, "AtticRafterLeftA", Vector3(2, 124, 18), Vector3(3, 4, 90), Color(0.20, 0.14, 0.10), false, 0, Vector3(0, 0, -14))
	_add_box(root, finishes, "AtticRafterRightA", Vector3(118, 124, 18), Vector3(3, 4, 90), Color(0.20, 0.14, 0.10), false, 0, Vector3(0, 0, 14))
	_add_box(root, finishes, "AtticRidgeBeamInterior", Vector3(60, 125, 18), Vector3(176, 4, 5), Color(0.18, 0.12, 0.08), false)
	_add_box(root, finishes, "AtticTrunkStack", Vector3(18, 122, 48), Vector3(44, 12, 18), Color(0.30, 0.18, 0.10), false)
	_add_box(root, finishes, "AtticBoxWall", Vector3(116, 123, -18), Vector3(62, 14, 20), Color(0.58, 0.42, 0.24), false)

func _add_interior_partitions_from_schedule(root: Node3D, parent: Node3D, floor_id: String, color: Color) -> void:
	parent.set_meta("wall_schedule", INTERIOR_WALL_SCHEDULE.filter(func(wall: Dictionary) -> bool:
		return str(wall.get("floor", "")) == floor_id
	))
	for wall in INTERIOR_WALL_SCHEDULE:
		if str(wall.get("floor", "")) != floor_id:
			continue
		_add_scheduled_wall(root, parent, wall, color)

func _add_scheduled_wall(root: Node3D, parent: Node3D, wall: Dictionary, color: Color) -> void:
	var wall_id := str(wall["id"])
	var axis := str(wall["axis"])
	var start := float(wall["start"])
	var end := float(wall["end"])
	var base_y := float(wall["base_y"])
	var height := float(wall["height"])
	var opening := wall.get("opening_span", Vector2.ZERO) as Vector2
	if opening != Vector2.ZERO:
		var a := minf(opening.x, opening.y)
		var b := maxf(opening.x, opening.y)
		_add_scheduled_wall_segment(root, parent, wall, "%sLower" % wall_id, start, a, color)
		_add_scheduled_wall_segment(root, parent, wall, "%sUpper" % wall_id, b, end, color)
		if axis == "x":
			_add_box(root, parent, "%sOpeningHeader" % wall_id, Vector3(float(wall["x"]), base_y + height - 6.0, (a + b) * 0.5), Vector3(8.0, 10.0, absf(b - a)), color.darkened(0.08), false)
			_add_box(root, parent, "%sThreshold" % wall_id, Vector3(float(wall["x"]), float(wall["threshold_datum"]) + 0.6, (a + b) * 0.5), Vector3(7.0, 1.2, absf(b - a)), color.darkened(0.32), false)
		else:
			_add_box(root, parent, "%sOpeningHeader" % wall_id, Vector3((a + b) * 0.5, base_y + height - 6.0, float(wall["z"])), Vector3(absf(b - a), 10.0, 8.0), color.darkened(0.08), false)
			_add_box(root, parent, "%sThreshold" % wall_id, Vector3((a + b) * 0.5, float(wall["threshold_datum"]) + 0.6, float(wall["z"])), Vector3(absf(b - a), 1.2, 7.0), color.darkened(0.32), false)
	else:
		_add_scheduled_wall_segment(root, parent, wall, wall_id, start, end, color)

func _add_scheduled_wall_segment(root: Node3D, parent: Node3D, wall: Dictionary, node_name: String, start: float, end: float, color: Color) -> void:
	if is_equal_approx(start, end):
		return
	var axis := str(wall["axis"])
	if axis == "x":
		_add_wall_x(root, parent, node_name, float(wall["x"]), start, end, color, true, float(wall["base_y"]), float(wall["height"]))
	else:
		_add_wall_z(root, parent, node_name, float(wall["z"]), start, end, color, true, float(wall["base_y"]), float(wall["height"]))

func _add_exterior_architecture(root: Node3D, parent: Node3D) -> void:
	parent.set_meta("style_contract", "toy-scale craftsman suburban house: low porch, visible foundation, gabled roof hierarchy, warm siding, cream trim, practical garage and service side")
	parent.set_meta("shell_ownership", "single authoritative exterior shell; stage/floor holders may not create exterior walls, gables, roof planes, fascia, exterior openings, or foundation collision")
	var siding := Color(0.55, 0.48, 0.39)
	var siding_shadow := Color(0.43, 0.37, 0.31)
	var trim := Color(0.88, 0.82, 0.67)
	var stone := Color(0.42, 0.39, 0.34)
	_add_box(root, parent, "ContinuousStoneFoundationPlinth", Vector3(0, 3.0, 9), Vector3(448, 6, 212), stone, false)
	for column in [{"name": "Left", "x": -88.0}, {"name": "Right", "x": -8.0}]:
		var column_x := float(column["x"])
		var column_name := str(column["name"])
		_add_box(root, parent, "FrontPorchTaperedColumn%sBase" % column_name, Vector3(column_x, 8, 123), Vector3(10, 16, 10), stone, false)
		_add_box(root, parent, "FrontPorchTaperedColumn%sShaft" % column_name, Vector3(column_x, 26, 123), Vector3(6, 30, 6), trim, false)
	_add_box(root, parent, "FrontPorchBeam", Vector3(-48, 42, 123), Vector3(106, 8, 10), trim.darkened(0.08), false)
	_add_box(root, parent, "FrontPorchRailLeft", Vector3(-98, 15, 126), Vector3(4, 18, 28), trim, false)
	_add_box(root, parent, "FrontPorchRailRight", Vector3(2, 15, 126), Vector3(4, 18, 28), trim, false)
	_add_box(root, parent, "FrontDoorDeepJambLeft", Vector3(-69, 18, 110), Vector3(5, 34, 8), trim, false)
	_add_box(root, parent, "FrontDoorDeepJambRight", Vector3(-27, 18, 110), Vector3(5, 34, 8), trim, false)
	_add_box(root, parent, "FrontDoorLintelHeader", Vector3(-48, 36, 110), Vector3(48, 6, 8), trim, false)
	_add_box(root, parent, "FrontGableSidingField", Vector3(-48, 57, 112), Vector3(112, 24, 6), siding, false)
	_add_box(root, parent, "GarageFrontSidingField", Vector3(154, 36, 112), Vector3(126, 58, 6), siding_shadow, false)
	_add_box(root, parent, "GarageDoorTrimHeader", Vector3(154, 31, 112), Vector3(96, 6, 8), trim, false)
	_add_box(root, parent, "GarageDoorTrimLeft", Vector3(108, 16, 112), Vector3(5, 30, 8), trim, false)
	_add_box(root, parent, "GarageDoorTrimRight", Vector3(200, 16, 112), Vector3(5, 30, 8), trim, false)
	for i in range(4):
		_add_box(root, parent, "GarageDoorHorizontalPanel%02d" % i, Vector3(154, 7 + i * 6, 113.4), Vector3(78, 1.2, 1), Color(0.18, 0.17, 0.15), false)
	_add_window(root, parent, "UpperFrontBedroomWindow", Vector3(2, 88, 127), Vector3(38, 22, 1.0))
	_add_window(root, parent, "UpperFrontGlamWindow", Vector3(132, 88, 127), Vector3(40, 22, 1.0))
	_add_box(root, parent, "FrontGutterRun", Vector3(0, 47, 124), Vector3(452, 3, 4), Color(0.12, 0.12, 0.11), false)
	_add_box(root, parent, "BackGutterRun", Vector3(0, 47, -104), Vector3(452, 3, 4), Color(0.12, 0.12, 0.11), false)
	_add_box(root, parent, "ChimneyMasonryStack", Vector3(-168, 78, -12), Vector3(20, 52, 18), Color(0.35, 0.20, 0.15), false)
	_add_box(root, parent, "ChimneyCap", Vector3(-168, 106, -12), Vector3(26, 6, 24), Color(0.16, 0.13, 0.12), false)
	_add_box(root, parent, "ServiceElectricMeter", Vector3(218, 22, 22), Vector3(1.2, 14, 10), Color(0.14, 0.16, 0.16), false)
	_add_box(root, parent, "ServiceUtilityPanel", Vector3(218, 16, -10), Vector3(1.2, 18, 14), Color(0.22, 0.24, 0.23), false)

func _add_exterior_wall_system(root: Node3D, parent: Node3D) -> void:
	var exterior := Color(0.54, 0.49, 0.42)
	_add_wall_z(root, parent, "ExteriorFrontWallLeft", 106, -214, -70, exterior, true)
	_add_wall_z(root, parent, "ExteriorFrontWallEntryHeader", 106, -28, 94, exterior, true)
	_add_wall_z(root, parent, "ExteriorFrontGarageWall", 106, 94, 214, exterior, true)
	_add_wall_z(root, parent, "ExteriorBackWallWest", -86, -214, -75, exterior, true)
	_add_wall_z(root, parent, "ExteriorBackPatioHeader", -86, -15, 62, exterior, true)
	_add_wall_z(root, parent, "ExteriorBackGarageWall", -86, 62, 214, exterior, true)
	_add_wall_x(root, parent, "ExteriorWestWall", -214, -86, 106, exterior, true)
	_add_wall_x(root, parent, "ExteriorEastGarageWall", 214, -86, 106, exterior, true)
	_add_box(root, parent, "MainRoofSoffitClosure", Vector3(0, 48.5, 10), Vector3(432, 4, 202), exterior.darkened(0.10), false)

func _add_opening_assemblies(root: Node3D, parent: Node3D) -> void:
	parent.set_meta("plan_role", "door/window/threshold schedule from floor-plan contract")
	var trim := Color(0.88, 0.82, 0.67)
	_add_box(root, parent, "FrontDoorPanel", Vector3(-48, 12, 107.5), Vector3(36, 24, 2.4), Color(0.24, 0.13, 0.07), false)
	_add_box(root, parent, "FrontDoorGlass", Vector3(-48, 17, 108.9), Vector3(22, 10, 0.6), Color(0.45, 0.72, 0.88, 0.45), false)
	_add_box(root, parent, "FrontEntryThresholdStone", Vector3(-48, 2, 112), Vector3(48, 4, 10), Color(0.46, 0.43, 0.37), false)
	_add_box(root, parent, "FrontEntrySidelightLeft", Vector3(-74, 20, 110), Vector3(8, 24, 2), Color(0.50, 0.75, 0.88, 0.55), false)
	_add_box(root, parent, "FrontEntrySidelightRight", Vector3(-22, 20, 110), Vector3(8, 24, 2), Color(0.50, 0.75, 0.88, 0.55), false)
	_add_window(root, parent, "DiningFrontWindow", Vector3(-150, 23, 108), Vector3(48, 22, 1.0))
	_add_window(root, parent, "LivingFrontWindow", Vector3(-18, 23, 108), Vector3(46, 22, 1.0))
	_add_window(root, parent, "KitchenGardenWindow", Vector3(-214.5, 22, -30), Vector3(1.0, 22, 46))
	_add_box(root, parent, "KitchenPatioDoorFrame", Vector3(-48, 20, -91), Vector3(62, 40, 5), trim, false)
	_add_box(root, parent, "KitchenPatioDoorGlass", Vector3(-48, 20, -94), Vector3(48, 30, 1.2), Color(0.48, 0.72, 0.86, 0.45), false)
	_add_box(root, parent, "PlayroomPatioDoorFrame", Vector3(22, 20, -91), Vector3(48, 40, 5), trim, false)
	_add_box(root, parent, "PlayroomPatioDoorGlass", Vector3(22, 20, -94), Vector3(34, 30, 1.2), Color(0.48, 0.72, 0.86, 0.45), false)
	_add_box(root, parent, "GarageDoorPanel", Vector3(154, 14, 108), Vector3(86, 28, 2.0), Color(0.32, 0.30, 0.27), false)
	_add_box(root, parent, "GarageHouseServiceDoor", Vector3(62, 14, 54), Vector3(4, 28, 20), Color(0.22, 0.16, 0.10), false)
	_add_box(root, parent, "AtticAccessHatchFrame", Vector3(94, 118, -16), Vector3(52, 5, 30), trim.darkened(0.20), false)

func _add_porch_deck_system(root: Node3D, parent: Node3D) -> void:
	parent.set_meta("plan_role", "front porch and backyard deck threshold system")
	_add_box(root, parent, "FrontPorchDeck", Vector3(-48, 1.2, 124), Vector3(100, 3.0, 30), Color(0.44, 0.35, 0.26), true)
	_add_box(root, parent, "FrontPorchStepLower", Vector3(-48, 0.2, 146), Vector3(112, 1.5, 12), Color(0.50, 0.45, 0.38), true)
	_add_box(root, parent, "FrontPorchStepUpper", Vector3(-48, 1.8, 137), Vector3(98, 1.8, 10), Color(0.56, 0.50, 0.42), true)
	_add_box(root, parent, "BackDeckLanding", Vector3(-42, 1.5, -104), Vector3(126, 3, 22), Color(0.46, 0.35, 0.24), true)
	_add_box(root, parent, "BackDeckStairRun", Vector3(-42, 0.4, -126), Vector3(94, 1.6, 20), Color(0.54, 0.43, 0.30), true)
	for i in range(5):
		_add_box(root, parent, "BackDeckBoard%02d" % i, Vector3(-94 + i * 26, 3.2, -104), Vector3(2, 1, 22), Color(0.28, 0.20, 0.14), false)

func _add_garage_service_system(root: Node3D, parent: Node3D) -> void:
	parent.set_meta("plan_role", "garage/service zone connected to driveway and house")
	_add_box(root, parent, "GarageToolBench", Vector3(196, 8, -22), Vector3(28, 16, 14), Color(0.28, 0.20, 0.13), false)
	_add_box(root, parent, "GarageStorageShelves", Vector3(104, 12, -54), Vector3(42, 24, 12), Color(0.24, 0.22, 0.20), false)
	_add_box(root, parent, "GarageWaterHeater", Vector3(198, 16, 34), Vector3(16, 32, 16), Color(0.38, 0.42, 0.44), false)
	_add_box(root, parent, "ServiceHvacPad", Vector3(232, 1, 8), Vector3(26, 2, 26), Color(0.44, 0.44, 0.40), false)
	_add_box(root, parent, "ServiceHvacUnit", Vector3(232, 12, 8), Vector3(22, 22, 22), Color(0.24, 0.28, 0.28), false)

func _add_roof_system(root: Node3D, parent: Node3D) -> void:
	parent.set_meta("plan_role", "measured roof/attic companion plan")
	parent.set_meta("massing_contract", "single craftsman primary gable with subordinate garage cross-gable, lower porch gable, and integrated upper dormer; no layer-cake exposed boxes or floating ridge strips")
	parent.set_meta("roof_contract", {
		"main_lower": {"span_axis": "x", "eave_y": 50.0, "ridge_y": 82.0, "ridge_x": 0.0, "overhang": 12.0},
		"upper_dormer": {"span_axis": "x", "eave_y": 108.0, "ridge_y": 128.0, "ridge_x": 60.0, "overhang": 10.0},
		"garage_cross_gable": {"span_axis": "z", "eave_y": 50.0, "ridge_y": 70.0, "ridge_z": 92.0, "overhang": 8.0},
		"porch_gable": {"span_axis": "z", "eave_y": 47.0, "ridge_y": 62.0, "ridge_z": 130.0, "overhang": 7.0},
	})
	var roof := Color(0.23, 0.18, 0.15)
	var shadow := Color(0.16, 0.13, 0.12)
	var siding := Color(0.55, 0.49, 0.40)
	_add_roof_plane_x(root, parent, "MainRoofLeftPlane", -236, 0, -116, 138, 50, 82, roof)
	_add_roof_plane_x(root, parent, "MainRoofRightPlane", 0, 236, -116, 138, 82, 50, roof)
	_add_box(root, parent, "MainRoofRidgeCap", Vector3(0, 83, 11), Vector3(8, 5, 248), shadow, false)
	_add_gable_wall_z(root, parent, "MainFrontGableWall", 126, -224, 224, 44, 50, 82, siding)
	_add_gable_wall_z(root, parent, "MainBackGableWall", -104, -224, 224, 44, 50, 82, siding.darkened(0.06))
	_add_roof_plane_z(root, parent, "GarageCrossGableFrontPlane", 92, 138, 94, 222, 70, 50, roof.darkened(0.02))
	_add_roof_plane_z(root, parent, "GarageCrossGableBackPlane", 46, 92, 94, 222, 50, 70, roof.darkened(0.02))
	_add_box(root, parent, "GarageCrossGableRidge", Vector3(158, 71, 92), Vector3(124, 5, 7), shadow, false)
	_add_box(root, parent, "GarageValleyCoverFront", Vector3(104, 58, 122), Vector3(4, 5, 52), shadow.lightened(0.06), false, -22)
	_add_box(root, parent, "GarageValleyCoverBack", Vector3(104, 58, 62), Vector3(4, 5, 52), shadow.lightened(0.06), false, 22)
	_add_roof_plane_z(root, parent, "FrontPorchGableFrontPlane", 130, 156, -104, 8, 62, 47, roof.darkened(0.04))
	_add_roof_plane_z(root, parent, "FrontPorchGableBackPlane", 104, 130, -104, 8, 47, 62, roof.darkened(0.04))
	_add_box(root, parent, "FrontPorchGableRidge", Vector3(-48, 63, 130), Vector3(108, 5, 6), shadow, false)
	_add_box(root, parent, "FrontPorchRoofFascia", Vector3(-48, 48, 158), Vector3(118, 5, 5), shadow, false)
	_add_box(root, parent, "UpperDormerCheekLeft", Vector3(-76, 91, 68), Vector3(6, 36, 128), siding.darkened(0.04), false)
	_add_box(root, parent, "UpperDormerCheekRight", Vector3(196, 91, 68), Vector3(6, 36, 128), siding.darkened(0.04), false)
	_add_box(root, parent, "UpperDormerLowerFrontWall", Vector3(60, 75, 132), Vector3(260, 42, 7), siding.lightened(0.02), false)
	_add_box(root, parent, "UpperDormerLowerBackWall", Vector3(60, 75, 4), Vector3(260, 42, 7), siding.darkened(0.04), false)
	_add_box(root, parent, "UpperDormerLowerLeftWall", Vector3(-72, 75, 68), Vector3(7, 42, 128), siding.darkened(0.05), false)
	_add_box(root, parent, "UpperDormerLowerRightWall", Vector3(192, 75, 68), Vector3(7, 42, 128), siding.darkened(0.02), false)
	_add_box(root, parent, "UpperDormerStoryBeltCourseFront", Vector3(60, 88, 136), Vector3(270, 5, 8), shadow.lightened(0.18), false)
	_add_box(root, parent, "UpperDormerStoryBeltCourseBack", Vector3(60, 88, 0), Vector3(270, 5, 8), shadow.lightened(0.12), false)
	_add_box(root, parent, "UpperDormerStoryBeltCourseLeft", Vector3(-76, 88, 68), Vector3(8, 5, 134), shadow.lightened(0.12), false)
	_add_box(root, parent, "UpperDormerStoryBeltCourseRight", Vector3(196, 88, 68), Vector3(8, 5, 134), shadow.lightened(0.12), false)
	_add_gable_wall_z(root, parent, "UpperDormerFrontGableWall", 128, -66, 186, 86, 108, 128, siding.lightened(0.04))
	_add_gable_wall_z(root, parent, "UpperDormerBackGableWall", 6, -66, 186, 86, 108, 128, siding.darkened(0.03))
	_add_roof_plane_x(root, parent, "UpperAtticRoofLeftPlane", -76, 60, -2, 138, 108, 128, roof.darkened(0.03))
	_add_roof_plane_x(root, parent, "UpperAtticRoofRightPlane", 60, 196, -2, 138, 128, 108, roof.darkened(0.03))
	_add_box(root, parent, "UpperAtticRoofRidgeCap", Vector3(60, 129, 68), Vector3(7, 4, 132), shadow, false)
	_add_box(root, parent, "UpperRoofFrontFascia", Vector3(60, 109, 138), Vector3(278, 4, 4), shadow.lightened(0.08), false)
	_add_box(root, parent, "UpperRoofBackFascia", Vector3(60, 109, -2), Vector3(278, 4, 4), shadow.lightened(0.08), false)
	_add_box(root, parent, "UpperDormerValleyCoverLeft", Vector3(-50, 78, 123), Vector3(56, 4, 5), shadow.lightened(0.05), false, -10)
	_add_box(root, parent, "UpperDormerValleyCoverRight", Vector3(170, 78, 123), Vector3(56, 4, 5), shadow.lightened(0.05), false, 10)
	_add_box(root, parent, "MainRoofFrontFascia", Vector3(0, 51, 138), Vector3(468, 7, 6), shadow, false)
	_add_box(root, parent, "MainRoofBackFascia", Vector3(0, 51, -116), Vector3(468, 7, 6), shadow, false)
	_add_box(root, parent, "MainRoofWestRakeFascia", Vector3(-236, 57, 11), Vector3(6, 7, 250), shadow, false)
	_add_box(root, parent, "MainRoofEastRakeFascia", Vector3(236, 57, 11), Vector3(6, 7, 250), shadow, false)

func _add_vertical_connectors(root: Node3D, parent: Node3D) -> void:
	_add_box(root, parent, "MainToUpperToyRamp", Vector3(28, 31, 104), Vector3(24, 4, 130), Color(0.14, 0.36, 0.70), true, -28.0)
	_add_box(root, parent, "UpperRampLanding", Vector3(48, 64, 112), Vector3(52, 3, 28), Color(0.16, 0.42, 0.75), true)
	_add_box(root, parent, "UpperToAtticToyRamp", Vector3(92, 89, 34), Vector3(22, 4, 104), Color(0.65, 0.22, 0.18), true, -26.0)
	_add_box(root, parent, "AtticRampLanding", Vector3(94, 116, -16), Vector3(48, 3, 26), Color(0.70, 0.25, 0.20), true)
	_add_box(root, parent, "MainRampSideRailLeft", Vector3(12, 35, 104), Vector3(4, 8, 128), Color(0.08, 0.12, 0.18), false, -28.0)
	_add_box(root, parent, "MainRampSideRailRight", Vector3(44, 35, 104), Vector3(4, 8, 128), Color(0.08, 0.12, 0.18), false, -28.0)
	_add_box(root, parent, "AtticRampSideRailLeft", Vector3(78, 93, 34), Vector3(4, 8, 104), Color(0.18, 0.06, 0.04), false, -26.0)
	_add_box(root, parent, "AtticRampSideRailRight", Vector3(106, 93, 34), Vector3(4, 8, 104), Color(0.18, 0.06, 0.04), false, -26.0)

func _add_yard_plan(root: Node3D, parent: Node3D) -> void:
	_add_box(root, parent, "PatioDeckTransition", Vector3(-36, -0.45, -110), Vector3(350, 1.2, 46), Color(0.48, 0.44, 0.38), true)
	_add_box(root, parent, "PatioBoardLineA", Vector3(-36, 0.25, -122), Vector3(350, 0.12, 1.0), Color(0.27, 0.23, 0.18), false)
	_add_box(root, parent, "PatioBoardLineB", Vector3(-36, 0.25, -98), Vector3(350, 0.12, 1.0), Color(0.27, 0.23, 0.18), false)
	for i in range(6):
		_add_box(root, parent, "PatioDeckBoardSeam%02d" % i, Vector3(-184 + i * 58, 0.30, -110), Vector3(1.0, 0.16, 44), Color(0.25, 0.21, 0.16), false)
	_add_box(root, parent, "OutdoorPlaygroundSetpieceZone", Vector3(-45, -0.45, -176), Vector3(300, 1.2, 90), Color(0.56, 0.42, 0.22), true)
	_add_box(root, parent, "PlaygroundMulchBorderFront", Vector3(-45, 1.0, -130), Vector3(308, 3, 4), Color(0.22, 0.12, 0.06), false)
	_add_box(root, parent, "PlaygroundMulchBorderBack", Vector3(-45, 1.0, -222), Vector3(308, 3, 4), Color(0.22, 0.12, 0.06), false)
	_add_box(root, parent, "PlaygroundMulchBorderWest", Vector3(-201, 1.0, -176), Vector3(4, 3, 94), Color(0.22, 0.12, 0.06), false)
	_add_box(root, parent, "PlaygroundMulchBorderEast", Vector3(111, 1.0, -176), Vector3(4, 3, 94), Color(0.22, 0.12, 0.06), false)
	_add_box(root, parent, "GardenZone", Vector3(-164, -0.35, -270), Vector3(136, 1.4, 126), Color(0.24, 0.36, 0.18), true)
	_add_box(root, parent, "GardenRaisedBedA", Vector3(-194, 3, -270), Vector3(46, 6, 88), Color(0.20, 0.12, 0.07), false)
	_add_box(root, parent, "GardenRaisedBedB", Vector3(-138, 3, -270), Vector3(46, 6, 88), Color(0.20, 0.12, 0.07), false)
	for i in range(5):
		_add_box(root, parent, "GardenVegetableRow%02d" % i, Vector3(-194 + (i % 2) * 56, 7, -306 + i * 18), Vector3(34, 5, 6), Color(0.18, 0.44, 0.18).lightened(float(i) * 0.025), false)
	_add_box(root, parent, "GardenPath", Vector3(-166, 0.05, -270), Vector3(16, 0.5, 116), Color(0.64, 0.56, 0.42), false)
	_add_box(root, parent, "LawnRouteBuffer", Vector3(4, -0.55, -270), Vector3(190, 1.1, 126), Color(0.48, 0.62, 0.34), true)
	_add_box(root, parent, "ToyboxTreeSwingLandingPatch", Vector3(28, -0.30, -286), Vector3(86, 1.2, 70), Color(0.34, 0.56, 0.28), true)
	for i in range(12):
		_add_box(root, parent, "MixedGrassHeightClump%02d" % i, Vector3(-70 + i * 14, 1.4 + float(i % 3), -236 - float((i * 11) % 72)), Vector3(5, 3 + float(i % 4), 4), Color(0.22, 0.48, 0.18).lightened(float(i % 3) * 0.05), false)
	_add_box(root, parent, "Sandbox", Vector3(156, -0.35, -270), Vector3(112, 1.4, 116), Color(0.82, 0.66, 0.42), true)
	_add_box(root, parent, "SandboxTimberNorth", Vector3(156, 3, -329), Vector3(120, 6, 6), Color(0.30, 0.18, 0.08), false)
	_add_box(root, parent, "SandboxTimberSouth", Vector3(156, 3, -216), Vector3(120, 6, 6), Color(0.30, 0.18, 0.08), false)
	_add_box(root, parent, "SandboxTimberWest", Vector3(94, 3, -270), Vector3(6, 6, 122), Color(0.30, 0.18, 0.08), false)
	_add_box(root, parent, "SandboxTimberEast", Vector3(218, 3, -270), Vector3(6, 6, 122), Color(0.30, 0.18, 0.08), false)
	_add_box(root, parent, "TreeShrubScreen", Vector3(0, 2, -346), Vector3(430, 6, 18), Color(0.19, 0.36, 0.14), false)
	_add_box(root, parent, "BackServiceGate", Vector3(218, 9, -346), Vector3(28, 18, 4), Color(0.22, 0.12, 0.06), false)
	for i in range(8):
		_add_box(root, parent, "BackFenceShrubMass%02d" % i, Vector3(-190 + i * 54, 5, -334 + float(i % 2) * 8), Vector3(26, 10, 18), Color(0.16, 0.34, 0.14).lightened(float(i % 4) * 0.035), false)

func _add_decor(root: Node3D, holders: Dictionary) -> void:
	var main := holders["MainFloor"] as Node3D
	var upper := holders["UpperFloor"] as Node3D
	var attic := holders["Attic"] as Node3D
	var yard := holders["Yard"] as Node3D
	_add_scene(root, yard, BACKYARD_PLAYGROUND_PATH, Vector3(-85, 0, -120), 10, Vector3(10, 10, 10), "PlaygroundStructure")
	_add_scene(root, yard, TOYBOX_TREE_SWING_PATH, Vector3(42, 0, -286), 7, Vector3(15, 15, 15), "ToyboxTreeTireSwing")
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
		route_holder.set_meta("route_envelope", _route_envelope_for_course(course))
		parent.add_child(route_holder)
		route_holder.owner = root
		var cells := _route_cells_for_course(str(course["id"]))
		var envelope := _route_envelope_for_course(course)
		var route_bounds := envelope["route_world_bounds"] as Dictionary
		var min_bound := route_bounds["min"] as Vector3
		var max_bound := route_bounds["max"] as Vector3
		_add_box(
			root,
			route_holder,
			"RouteContainmentAuditBox",
			(min_bound + max_bound) * 0.5,
			Vector3(max_bound.x - min_bound.x, 0.18, max_bound.z - min_bound.z),
			(course["color"] as Color).lightened(0.38),
			false
		)
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
	_add_camera(root, parent, "ExteriorRooflineCamera", Vector3(-260, 118, 210), Vector3(-22, -42, 0), 58)
	_add_camera(root, parent, "AtticGableProfileCamera", Vector3(242, 146, 70), Vector3(-8, 88, 0), 50)
	_add_camera(root, parent, "FrontPorchCloseupCamera", Vector3(-118, 34, 168), Vector3(-8, -25, 0), 48)
	_add_camera(root, parent, "GarageServiceSideCamera", Vector3(286, 50, 88), Vector3(-11, 84, 0), 58)
	_add_camera(root, parent, "ToyboxTreeSwingCamera", Vector3(-116, 48, -324), Vector3(-7, -63, 0), 54)
	_add_camera(root, parent, "MainFloorRouteCamera", Vector3(-245, 54, 122), Vector3(-14, -62, 0), 70)
	_add_camera(root, parent, "KitchenStartPlayerCamera", Vector3(-166, 12, -91), Vector3(-6, 0, 0), 64)
	_add_camera(root, parent, "KitchenFirstTurnPlayerCamera", Vector3(-106, 15, -68), Vector3(-8, -44, 0), 58)
	_add_camera(root, parent, "KitchenDiningSeamCamera", Vector3(-182, 22, 42), Vector3(-14, -22, 0), 54)
	_add_camera(root, parent, "KitchenPlayroomSeamCamera", Vector3(-92, 20, -104), Vector3(-10, 0, 0), 54)
	_add_camera(root, parent, "PlayroomLivingSeamCamera", Vector3(-12, 22, 42), Vector3(-14, -18, 0), 54)
	_add_camera(root, parent, "GarageServiceSeamCamera", Vector3(104, 24, -38), Vector3(-12, 36, 0), 54)
	_add_camera(root, parent, "UpperFloorRouteCamera", Vector3(-100, 118, 158), Vector3(-20, -42, 0), 70)
	_add_camera(root, parent, "BedroomGlamSeamCamera", Vector3(62, 92, 144), Vector3(-15, 0, 0), 54)
	_add_camera(root, parent, "AtticRouteCamera", Vector3(-45, 166, 92), Vector3(-18, -42, 0), 70)
	_add_camera(root, parent, "AtticStorageSeamCamera", Vector3(124, 146, -48), Vector3(-16, 34, 0), 54)
	_add_camera(root, parent, "RampSideProfileCamera", Vector3(-75, 84, 104), Vector3(-8, -90, 0), 70)

func _add_concept_reference(root: Node3D, parent: Node3D) -> void:
	parent.set_meta("concept_source", FLOOR_PLAN_PATH)

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

func _all_route_envelopes() -> Dictionary:
	var envelopes := {}
	for course in COURSES:
		envelopes[str(course["id"])] = _route_envelope_for_course(course)
	return envelopes

func _route_envelope_for_course(course: Dictionary) -> Dictionary:
	var course_id := str(course["id"])
	var route_cells := _route_cells_for_course(course_id)
	var min_cell := Vector3i(999999, 999999, 999999)
	var max_cell := Vector3i(-999999, -999999, -999999)
	for cell in route_cells:
		min_cell.x = mini(min_cell.x, cell.x)
		min_cell.y = mini(min_cell.y, cell.y)
		min_cell.z = mini(min_cell.z, cell.z)
		max_cell.x = maxi(max_cell.x, cell.x)
		max_cell.y = maxi(max_cell.y, cell.y)
		max_cell.z = maxi(max_cell.z, cell.z)
	var origin := _grid_origin(course)
	var route_min := origin + Vector3(float(min_cell.x) * CELL_SIZE.x, float(min_cell.y) * CELL_SIZE.y, float(min_cell.z) * CELL_SIZE.z)
	var route_max := origin + Vector3(float(max_cell.x + 1) * CELL_SIZE.x, float(max_cell.y + 1) * CELL_SIZE.y, float(max_cell.z + 1) * CELL_SIZE.z)
	var zone := _zone_contract_for_course(course_id)
	var floor_top_y := float(zone["floor_top_y"])
	return {
		"course_id": course_id,
		"zone_id": str(zone["zone_id"]),
		"zone_center": zone["center"],
		"zone_size": zone["size"],
		"zone_world_bounds": _bounds_from_center_size(zone["center"] as Vector3, zone["size"] as Vector3),
		"cell_size": CELL_SIZE,
		"route_local_bounds": {"min": min_cell, "max": max_cell},
		"route_world_bounds": {"min": route_min, "max": route_max},
		"corridor_width": ROAD_WIDTH,
		"floor_top_y": floor_top_y,
		"road_surface_y": float((course["placement"] as Vector3).y),
		"minimum_clearance_y": ROAD_FLOOR_CLEARANCE,
		"forbidden_overlap": ["walls", "furniture", "fixtures", "plants", "porch_posts", "service_props", "collision_blockers"],
		"confidence": "inferred_from_floor_plan_and_route_cell_budget",
		"gate": "spatial_audit_%s_route_inside_%s" % [course_id, str(zone["zone_id"])],
	}

func _zone_contract_for_course(course_id: String) -> Dictionary:
	match course_id:
		"kitchen":
			return {"zone_id": "kitchen_pantry", "center": Vector3(-150, 0, -38), "size": Vector3(118, 46, 96), "floor_top_y": 0.05}
		"playroom":
			return {"zone_id": "playroom", "center": Vector3(-32, 0, -38), "size": Vector3(118, 46, 96), "floor_top_y": 0.05}
		"outdoor_playground":
			return {"zone_id": "outdoor_playground_setpiece_zone", "center": Vector3(-45, 0, -176), "size": Vector3(300, 28, 90), "floor_top_y": 0.15}
		"garden":
			return {"zone_id": "garden_zone", "center": Vector3(-164, 0, -270), "size": Vector3(136, 24, 126), "floor_top_y": 0.35}
		"sandbox":
			return {"zone_id": "sandbox", "center": Vector3(156, 0, -270), "size": Vector3(112, 24, 116), "floor_top_y": 0.35}
		"bedroom":
			return {"zone_id": "bedroom_zone", "center": Vector3(0, 64, 66), "size": Vector3(116, 48, 92), "floor_top_y": 64.60}
		"glam_closet":
			return {"zone_id": "glam_closet_zone", "center": Vector3(122, 64, 66), "size": Vector3(112, 48, 92), "floor_top_y": 64.60}
		"attic":
			return {"zone_id": "attic_storage_zone", "center": Vector3(60, 116, 18), "size": Vector3(202, 50, 80), "floor_top_y": 116.60}
	return {"zone_id": course_id, "center": Vector3.ZERO, "size": Vector3.ONE, "floor_top_y": 0.0}

func _bounds_from_center_size(center: Vector3, size: Vector3) -> Dictionary:
	var half := size * 0.5
	return {"min": center - half, "max": center + half}

func _route_cells_for_course(course_id: String) -> Array[Vector3i]:
	match course_id:
		"kitchen":
			return _route_from_points([Vector3i(-2, 0, -2), Vector3i(2, 0, -2), Vector3i(2, 0, 2), Vector3i(-2, 0, 2)])
		"playroom":
			return _compact_vertical_route()
		"outdoor_playground":
			return _route_from_points([Vector3i(-6, 0, -2), Vector3i(6, 0, -2), Vector3i(6, 1, 2), Vector3i(-6, 1, 2)])
		"garden":
			return _route_from_points([Vector3i(-3, 0, -3), Vector3i(3, 0, -3), Vector3i(3, 1, 2), Vector3i(-3, 1, 2)])
		"sandbox":
			return _route_from_points([Vector3i(-2, 0, -3), Vector3i(3, 0, -3), Vector3i(3, 1, 2), Vector3i(-2, 1, 2)])
		"bedroom":
			return _compact_vertical_route()
		"glam_closet":
			return _compact_vertical_route()
		"attic":
			return _route_from_points([Vector3i(-4, 0, -2), Vector3i(4, 0, -2), Vector3i(4, 1, 2), Vector3i(-4, 1, 2)])
	return []

func _course_by_id(course_id: String) -> Dictionary:
	for course in COURSES:
		if str(course["id"]) == course_id:
			return course
	return COURSES[0]

func _compact_vertical_route() -> Array[Vector3i]:
	return _route_from_points([Vector3i(-2, 0, -2), Vector3i(2, 0, -2), Vector3i(2, 1, 2), Vector3i(-2, 1, 2)])

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
		"route_envelope": _route_envelope_for_course(course),
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

func _add_roof_plane_x(root: Node3D, parent: Node3D, node_name: String, x0: float, x1: float, z0: float, z1: float, y0: float, y1: float, color: Color) -> MeshInstance3D:
	var vertices := PackedVector3Array([
		Vector3(x0, y0, z0),
		Vector3(x0, y0, z1),
		Vector3(x1, y1, z1),
		Vector3(x1, y1, z0),
	])
	var mesh := _add_mesh(root, parent, node_name, vertices, PackedInt32Array([0, 1, 2, 0, 2, 3]), color)
	mesh.set_meta("span_axis", "x")
	mesh.set_meta("eave_y", minf(y0, y1))
	mesh.set_meta("ridge_y", maxf(y0, y1))
	mesh.set_meta("slope_delta_y", absf(y1 - y0))
	return mesh

func _add_roof_plane_z(root: Node3D, parent: Node3D, node_name: String, z0: float, z1: float, x0: float, x1: float, y0: float, y1: float, color: Color) -> MeshInstance3D:
	var vertices := PackedVector3Array([
		Vector3(x0, y0, z0),
		Vector3(x1, y0, z0),
		Vector3(x1, y1, z1),
		Vector3(x0, y1, z1),
	])
	var mesh := _add_mesh(root, parent, node_name, vertices, PackedInt32Array([0, 1, 2, 0, 2, 3]), color)
	mesh.set_meta("span_axis", "z")
	mesh.set_meta("eave_y", minf(y0, y1))
	mesh.set_meta("ridge_y", maxf(y0, y1))
	mesh.set_meta("slope_delta_y", absf(y1 - y0))
	return mesh

func _add_gable_wall_z(root: Node3D, parent: Node3D, node_name: String, z: float, x0: float, x1: float, base_y: float, eave_y: float, ridge_y: float, color: Color) -> Node3D:
	var holder := Node3D.new()
	holder.name = node_name
	holder.set_meta("gable_axis", "x")
	holder.set_meta("base_y", base_y)
	holder.set_meta("eave_y", eave_y)
	holder.set_meta("ridge_y", ridge_y)
	parent.add_child(holder)
	holder.owner = root
	_add_box(root, holder, "RectangularWallBelowEave", Vector3((x0 + x1) * 0.5, (base_y + eave_y) * 0.5, z), Vector3(absf(x1 - x0), eave_y - base_y, 6), color, false)
	var vertices := PackedVector3Array([
		Vector3(x0, eave_y, z),
		Vector3(x1, eave_y, z),
		Vector3((x0 + x1) * 0.5, ridge_y, z),
	])
	_add_mesh(root, holder, "TriangularGableAboveEave", vertices, PackedInt32Array([0, 1, 2]), color.darkened(0.06))
	return holder

func _add_mesh(root: Node3D, parent: Node3D, node_name: String, vertices: PackedVector3Array, indices: PackedInt32Array, color: Color) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh_instance.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.82
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh_instance.material_override = material
	parent.add_child(mesh_instance)
	mesh_instance.owner = root
	return mesh_instance

func _add_child_holder(root: Node3D, parent: Node3D, node_name: String, plan_role: String) -> Node3D:
	var holder := Node3D.new()
	holder.name = node_name
	holder.set_meta("plan_role", plan_role)
	parent.add_child(holder)
	holder.owner = root
	return holder

func _add_room_floor(root: Node3D, parent: Node3D, node_name: String, position: Vector3, size: Vector3, color: Color) -> void:
	_add_box(root, parent, node_name, position, size, color, true)
	var trim_color := color.darkened(0.32)
	_add_box(root, parent, "%sBaseboardNorth" % node_name, position + Vector3(0, 2.0, -size.z * 0.5), Vector3(size.x, 4.0, 2.0), trim_color, false)
	_add_box(root, parent, "%sBaseboardSouth" % node_name, position + Vector3(0, 2.0, size.z * 0.5), Vector3(size.x, 4.0, 2.0), trim_color, false)
	_add_box(root, parent, "%sBaseboardWest" % node_name, position + Vector3(-size.x * 0.5, 2.0, 0), Vector3(2.0, 4.0, size.z), trim_color, false)
	_add_box(root, parent, "%sBaseboardEast" % node_name, position + Vector3(size.x * 0.5, 2.0, 0), Vector3(2.0, 4.0, size.z), trim_color, false)

func _add_wall_z(
	root: Node3D,
	parent: Node3D,
	node_name: String,
	z: float,
	x0: float,
	x1: float,
	color: Color,
	collision: bool,
	base_y := 0.0,
	height := 46.0
) -> void:
	var center_x := (x0 + x1) * 0.5
	var width := absf(x1 - x0)
	_add_box(root, parent, node_name, Vector3(center_x, base_y + height * 0.5, z), Vector3(width, height, 6.0), color, collision)
	_add_box(root, parent, "%sTopTrim" % node_name, Vector3(center_x, base_y + height + 2.0, z), Vector3(width + 2.0, 4.0, 8.0), color.darkened(0.20), false)

func _add_wall_x(
	root: Node3D,
	parent: Node3D,
	node_name: String,
	x: float,
	z0: float,
	z1: float,
	color: Color,
	collision: bool,
	base_y := 0.0,
	height := 46.0
) -> void:
	var center_z := (z0 + z1) * 0.5
	var depth := absf(z1 - z0)
	_add_box(root, parent, node_name, Vector3(x, base_y + height * 0.5, center_z), Vector3(6.0, height, depth), color, collision)
	_add_box(root, parent, "%sTopTrim" % node_name, Vector3(x, base_y + height + 2.0, center_z), Vector3(8.0, 4.0, depth + 2.0), color.darkened(0.20), false)

func _add_window(root: Node3D, parent: Node3D, node_name: String, position: Vector3, size: Vector3) -> void:
	_add_box(root, parent, node_name, position, size, Color(0.55, 0.77, 0.92, 0.48), false)
	var trim_color := Color(0.92, 0.86, 0.72)
	if size.x >= size.z:
		_add_box(root, parent, "%sHeader" % node_name, position + Vector3(0, size.y * 0.5 + 2.0, 0), Vector3(size.x + 8.0, 4.0, 3.0), trim_color, false)
		_add_box(root, parent, "%sSill" % node_name, position + Vector3(0, -size.y * 0.5 - 2.0, 0), Vector3(size.x + 10.0, 4.0, 4.0), trim_color, false)
		_add_box(root, parent, "%sLeftJamb" % node_name, position + Vector3(-size.x * 0.5 - 2.0, 0, 0), Vector3(4.0, size.y + 4.0, 3.0), trim_color, false)
		_add_box(root, parent, "%sRightJamb" % node_name, position + Vector3(size.x * 0.5 + 2.0, 0, 0), Vector3(4.0, size.y + 4.0, 3.0), trim_color, false)
	else:
		_add_box(root, parent, "%sHeader" % node_name, position + Vector3(0, size.y * 0.5 + 2.0, 0), Vector3(3.0, 4.0, size.z + 8.0), trim_color, false)
		_add_box(root, parent, "%sSill" % node_name, position + Vector3(0, -size.y * 0.5 - 2.0, 0), Vector3(4.0, 4.0, size.z + 10.0), trim_color, false)
		_add_box(root, parent, "%sLeftJamb" % node_name, position + Vector3(0, 0, -size.z * 0.5 - 2.0), Vector3(3.0, size.y + 4.0, 4.0), trim_color, false)
		_add_box(root, parent, "%sRightJamb" % node_name, position + Vector3(0, 0, size.z * 0.5 + 2.0), Vector3(3.0, size.y + 4.0, 4.0), trim_color, false)

func _add_box(root: Node3D, parent: Node3D, node_name: String, position: Vector3, size: Vector3, color: Color, collision: bool, yaw_degrees := 0.0, rotation_degrees := Vector3.ZERO) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.name = node_name
	var basis := Basis.from_euler(Vector3(deg_to_rad(rotation_degrees.x), deg_to_rad(rotation_degrees.y + yaw_degrees), deg_to_rad(rotation_degrees.z)))
	mesh.transform = Transform3D(basis, position)
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
