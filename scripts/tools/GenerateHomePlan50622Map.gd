@tool
extends SceneTree

const TrackDefinition = preload("res://scripts/track/TrackDefinition.gd")
const TrackGridRoadBuilder = preload("res://scripts/track/TrackGridRoadBuilder.gd")
const TrackMapDefinition = preload("res://scripts/track/TrackMapDefinition.gd")
const TrackMetadataExporter = preload("res://scripts/track/TrackMetadataExporter.gd")
const TrackRuntimeScene = preload("res://scripts/track/TrackRuntimeScene.gd")
const TrackSourceRules = preload("res://scripts/track/TrackSourceRules.gd")

const MAP_ID := "home_plan50_622_v1"
const MAP_DISPLAY_NAME := "Plan 50-622 Modern Farmhouse"
const VERSION := "home_plan50_622_floorplan_v1_2026_05_17"
const BASE_DIR := "res://assets/gameplay/tracks/home_plan50_622_v1"
const MODE_DIR := "res://assets/gameplay/tracks/home_plan50_622_v1/modes"
const MAP_SCENE_PATH := "res://assets/gameplay/tracks/home_plan50_622_v1/home_plan50_622_v1_map.tscn"
const MAP_DEFINITION_PATH := "res://assets/gameplay/tracks/home_plan50_622_v1/home_plan50_622_v1_track_map.tres"
const TRACK_PACKAGES_PATH := "res://assets/gameplay/tracks/track_packages.json"
const VISIBLE_SHELL_ASSET_PATH := "res://assets/gameplay/tracks/home_plan50_622_v1/meshes/modern_farmhouse_shell.glb"
const GRID_LIBRARY := TrackGridRoadBuilder.DEFAULT_MESH_LIBRARY_PATH
const ROAD_TEXTURE := "res://assets/gameplay/materials/plastic/glossy_plastic_albedo.png"

const UNITS_PER_FOOT := 4.0
const CELL_SIZE := Vector3(16.0, 4.0, 16.0)
const ROAD_WIDTH := 16.0
const ROAD_FLOOR_CLEARANCE := 0.55
const FLOOR_Y := -1.1
const OUT_OF_BOUNDS_Y := -36.0
const MAIN_FLOOR_Y := 0.05
const ATTIC_STORAGE_Y := 18.05
const BASEMENT_FLOOR_Y := -42.0

const PLAN_CONTRACT := {
	"source": "monster_house_plans_plan_50_622_user_canvas_reference",
	"source_url": "https://www.monsterhouseplans.com/house-plans/modern-farmhouse-style/3250-sq-ft-home-1-story-4-bedroom-3-bath-house-plans-plan50-622/",
	"map_id": MAP_ID,
	"units_per_floor_plan_foot": UNITS_PER_FOOT,
	"orientation": "front/street +Z, rear patio/backyard -Z",
	"main_floor_dimensions_ft": Vector2(105.0, 61.8333),
	"main_floor_area_sqft": 3250,
	"porches_area_sqft": 717,
	"garage_area_sqft": 1086,
	"stories": 1,
	"height_ft": 30,
	"ceiling_height_main_ft": 10,
	"roof_slope_primary": "12:12",
	"roof_slope_secondary": "4:12",
	"program": {
		"main": ["split_side_entry_garages", "mudroom_service", "formal_dining", "kitchen_island", "scullery", "walk_in_pantry", "wet_bar", "great_room", "foyer", "primary_suite", "secondary_bedroom_wing", "covered_front_porch", "covered_rear_porch", "outdoor_kitchen"],
		"attic_storage": ["bonus_attic_storage_prank_space"],
		"basement": ["basement_shell", "unexcavated_zones"]
	},
	"style_reference": "Monster House Plans Plan 50-622 modern farmhouse reference: one-story, four-bedroom, 3.5-bath, 105 ft wide by 61 ft 10 in deep, side-entry three-car garage split into two left service masses, one front-facing single garage door at far left, two large left-elevation garage doors, three dominant street-facing gables, recessed front porch/foyer between center and right gables, grouped black-framed windows, dark metal shed-roof accents, 44 ft rear porch with outdoor kitchen, central great room/kitchen/scullery/pantry/wet-bar core, 12:12 primary roof and 4:12 secondary roof.",
	"elevation_contract": {
		"front": ["single_front_garage_door_far_left", "left_master_gable_window_group", "center_great_room_gable_window_group", "recessed_entry_porch", "front_dormer_window", "right_bedroom_gable_window_group"],
		"rear": ["long_rear_porch", "rear_porch_posts", "rear_door_window_groups", "right_rear_gable_window_group"],
		"left": ["two_side_entry_garage_doors", "left_service_man_doors", "left_service_window", "left_side_roof_gables"],
		"right": ["dominant_right_gable", "right_side_small_horizontal_window", "right_side_tall_window_pair"],
	},
	"reference_screenshot_urls": [
		"https://s3-us-west-2.amazonaws.com/prod.monsterhouseplans.com/uploads/images_plans/50/50-622/50-622e.webp",
		"https://s3-us-west-2.amazonaws.com/prod.monsterhouseplans.com/uploads/images_plans/50/50-622/50-622p1.webp",
		"https://s3-us-west-2.amazonaws.com/prod.monsterhouseplans.com/uploads/images_plans/50/50-622/50-622p2.webp",
		"https://s3-us-west-2.amazonaws.com/prod.monsterhouseplans.com/uploads/images_plans/50/50-622/50-622m.webp",
	],
	"production_policy": "Generator-driven modern farmhouse baseline. Visible primitives are named architectural/furnishing stand-ins only until replaced by Kenney/Meshy/toybox; no plan labels or bare floor-plan diagram markers may ship.",
}

const CHARACTER_ZONE_MAPPING := {
	"Sir Clink": "kitchen",
	"Slammo": "great_room",
	"Tuggs": "bedroom_wing",
	"Velva": "master_suite_plus_walk_in_closet",
	"Popper": "bonus_room_attic_storage_prank_space",
	"Dash": "garage_service_driveway_stunt_route",
	"Moko": "garden_patio",
	"Rexx": "sandbox_fossil_play_yard",
}

const STORY_BIBLE_PATH := "res://docs/concept_package.md"
const CHARACTER_MAPPING_PATH := "res://docs/story_bible/concepts/stages/home_plan50_622_v1_character_mapping.md"

const OUTDOOR_ZONE_CONTRACT := {
	"moko_garden_patio": {
		"owner_character": "Moko",
		"owner_zone": "garden_patio",
		"bounds_center": Vector3(-72, -0.05, -204),
		"bounds_size": Vector3(116, 1.4, 82),
		"surface_material": "mulch_grass_patio_transition",
		"scale_class": "yard_site",
		"route_clearance": "edge_landmark_outside_plan50_rear_porch_primary_line",
		"validation_camera": "MokoGardenPatioCamera",
	},
	"rexx_sandbox_fossil_play_yard": {
		"owner_character": "Rexx",
		"owner_zone": "sandbox_fossil_play_yard",
		"bounds_center": Vector3(148, 0.0, -238),
		"bounds_size": Vector3(86, 1.2, 62),
		"surface_material": "sand_with_fossil_play_edges",
		"scale_class": "yard_site",
		"route_clearance": "outside_plan50_rear_porch_loop_with_visible_landmark_clearance",
		"validation_camera": "RexxSandboxCamera",
	},
	"dash_driveway_service_stunt_route": {
		"owner_character": "Dash",
		"owner_zone": "garage_service_driveway_stunt_route",
		"bounds_center": Vector3(-120, 0.1, 88),
		"bounds_size": Vector3(104, 1.2, 118),
		"surface_material": "concrete_driveway_service_apron",
		"scale_class": "yard_site",
		"route_clearance": "connects_side_entry_garage_to_street_without_blocking_plan50_garage_start",
		"validation_camera": "DashDrivewayServiceCamera",
	},
}

const COURSES := [
	{"id": "plan50_kitchen", "display_name": "Plan 50 Kitchen", "owner_character": "Sir Clink", "owner_zone": "kitchen", "scale_class": "room_furnishing", "validation_camera": "Plan50KitchenStartPlayerCamera", "placement": Vector3(-34, MAIN_FLOOR_Y + ROAD_FLOOR_CLEARANCE, 42), "sky": "noon_clear", "color": Color(0.92, 0.78, 0.55)},
	{"id": "plan50_great_room", "display_name": "Plan 50 Great Room", "owner_character": "Slammo", "owner_zone": "great_room", "scale_class": "room_furnishing", "validation_camera": "Plan50GreatRoomStartPlayerCamera", "placement": Vector3(42, MAIN_FLOOR_Y + ROAD_FLOOR_CLEARANCE, -6), "sky": "soft_morning", "color": Color(0.76, 0.62, 0.55)},
	{"id": "plan50_garage", "display_name": "Plan 50 Garage", "owner_character": "Dash", "owner_zone": "garage_service_driveway_stunt_route", "scale_class": "room_furnishing", "validation_camera": "Plan50GarageStartPlayerCamera", "placement": Vector3(-150, MAIN_FLOOR_Y + ROAD_FLOOR_CLEARANCE, 58), "sky": "clear_afternoon", "color": Color(0.58, 0.58, 0.54)},
	{"id": "plan50_master_suite", "display_name": "Plan 50 Master Suite", "owner_character": "Velva", "owner_zone": "master_suite_plus_walk_in_closet", "scale_class": "room_furnishing", "validation_camera": "Plan50MasterSuiteStartPlayerCamera", "placement": Vector3(-116, MAIN_FLOOR_Y + ROAD_FLOOR_CLEARANCE, -42), "sky": "soft_morning", "color": Color(0.62, 0.56, 0.68)},
	{"id": "plan50_bedroom_wing", "display_name": "Plan 50 Bedroom Wing", "owner_character": "Tuggs", "owner_zone": "bedroom_wing", "scale_class": "room_furnishing", "validation_camera": "Plan50BedroomWingStartPlayerCamera", "placement": Vector3(142, MAIN_FLOOR_Y + ROAD_FLOOR_CLEARANCE, -30), "sky": "soft_morning", "color": Color(0.60, 0.56, 0.70)},
	{"id": "plan50_bonus_storage", "display_name": "Plan 50 Bonus Storage", "owner_character": "Popper", "owner_zone": "bonus_room_attic_storage_prank_space", "scale_class": "room_furnishing", "validation_camera": "Plan50BonusStorageStartPlayerCamera", "placement": Vector3(-146, ATTIC_STORAGE_Y + ROAD_FLOOR_CLEARANCE, -104), "sky": "party_evening", "color": Color(0.58, 0.50, 0.66)},
	{"id": "plan50_rear_porch", "display_name": "Plan 50 Rear Porch", "owner_character": "Moko", "owner_zone": "garden_patio", "scale_class": "yard_site", "validation_camera": "Plan50RearPorchStartPlayerCamera", "placement": Vector3(38, MAIN_FLOOR_Y + ROAD_FLOOR_CLEARANCE, -132), "sky": "clear_afternoon", "color": Color(0.64, 0.62, 0.56)},
	{"id": "plan50_sandbox_yard", "display_name": "Plan 50 Sandbox Yard", "owner_character": "Rexx", "owner_zone": "sandbox_fossil_play_yard", "scale_class": "yard_site", "validation_camera": "Plan50SandboxYardStartPlayerCamera", "placement": Vector3(148, MAIN_FLOOR_Y + ROAD_FLOOR_CLEARANCE, -238), "sky": "clear_afternoon", "color": Color(0.73, 0.63, 0.39)},
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
	root.name = "HomePlan50622Map"
	root.set_meta("floor_plan_contract", PLAN_CONTRACT)
	root.set_meta("story_bible_path", STORY_BIBLE_PATH)
	root.set_meta("character_zone_mapping_path", CHARACTER_MAPPING_PATH)
	root.set_meta("character_zone_mapping", CHARACTER_ZONE_MAPPING)
	root.set_meta("generator_phase", "phase_2_shell_site_provenance_slice")
	for holder_name in ["Site", "Foundation", "ExteriorShell", "Roof", "Openings", "MainFloor", "AtticStorage", "Basement", "PatioPool", "YardZones", "VerticalConnectors", "CourseRoutes", "ValidationCameras", "ConceptReference"]:
		var holder := Node3D.new()
		holder.name = holder_name
		root.add_child(holder)
		holder.owner = root
	_add_site(root)
	_add_foundation(root)
	_add_main_floor(root)
	_add_attic_storage(root)
	_add_basement(root)
	_add_patio_pool(root)
	_add_yard_zones(root)
	_add_exterior_shell(root)
	_add_roof(root)
	_add_vertical_connectors(root)
	_add_course_route_markers(root)
	_apply_character_zone_metadata(root)
	_add_validation_cameras(root)
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
	root.name = "%sHomePlan50622Track" % course_id.to_pascal_case()
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
	map.default_mode_id = "plan50_kitchen"
	map.sky_preset_id = "clear_afternoon"
	map.sky_weather = "clear"
	map.sky_top_color = Color(0.52, 0.74, 0.96)
	map.sky_horizon_color = Color(0.78, 0.88, 0.96)
	map.sky_cloud_amount = 0.18
	map.sky_cloud_speed = 0.015
	map.sky_haze_amount = 0.12
	map.sky_light_energy = 2.45
	map.ground_size = Vector2(420, 420)
	map.ground_color = Color(0.46, 0.55, 0.38)
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
			"owner_character": str(course["owner_character"]),
			"owner_zone": str(course["owner_zone"]),
			"scale_class": str(course["scale_class"]),
			"validation_camera": str(course["validation_camera"]),
			"laps": 3,
			"road_visual_style": "kenney_gridmap",
			"road_width": ROAD_WIDTH,
			"reset_mode": "instant_pop",
			"sky_preset_id": definition.sky_preset_id if definition != null else str(course["sky"]),
			"ground_size": Vector2(420, 420),
			"ground_color": Color(0.46, 0.55, 0.38),
		}
	ResourceSaver.save(map, MAP_DEFINITION_PATH)

func _update_manifest() -> void:
	var manifest := _load_manifest()
	if not manifest.has("maps") or not (manifest["maps"] is Dictionary):
		manifest["maps"] = {}
	var maps := manifest["maps"] as Dictionary
	maps[MAP_ID] = {
		"id": MAP_ID,
		"display_name": MAP_DISPLAY_NAME,
		"version": VERSION,
		"map_definition_path": MAP_DEFINITION_PATH,
		"map_scene_path": MAP_SCENE_PATH,
		"default_mode_id": "plan50_kitchen",
	}
	var file := FileAccess.open(TRACK_PACKAGES_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest, "\t"))
	file.store_string("\n")
	file.close()

func _make_definition(course: Dictionary, layout: Dictionary, route_points: Array[Vector3], checkpoints: Array[int], spawns: Array[Vector4]) -> TrackDefinition:
	var course_id := str(course["id"])
	var definition := TrackDefinition.new()
	definition.id = course_id
	definition.display_name = str(course["display_name"])
	definition.version = VERSION
	definition.set_meta("track_map_id", MAP_ID)
	definition.set_meta("track_mode_id", course_id)
	definition.set_meta("track_mode_kind", "race")
	definition.set_meta("road_source", "road_grid_map")
	definition.set_meta("owner_character", str(course["owner_character"]))
	definition.set_meta("owner_zone", str(course["owner_zone"]))
	definition.set_meta("scale_class", str(course["scale_class"]))
	definition.set_meta("validation_camera", str(course["validation_camera"]))
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
	definition.ground_size = Vector2(420, 420)
	definition.ground_color = Color(0.46, 0.55, 0.38)
	definition.road_texture_path = ROAD_TEXTURE
	definition.road_visual_style = "kenney_gridmap"
	definition.road_grid_layout = layout.duplicate(true)
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
	definition.stage_interactions = []
	_apply_sky_preset(definition, str(course["sky"]))
	return definition

func _add_site(root: Node3D) -> void:
	var site := root.get_node("Site") as Node3D
	_add_box(root, site, "Plan50LotGround", Vector3(0, -1.2, -20), Vector3(420, 1, 420), Color(0.42, 0.54, 0.34), true)
	_add_box(root, site, "StreetEdge", Vector3(0, -0.6, 160), Vector3(460, 1, 28), Color(0.20, 0.22, 0.22), true)
	_add_box(root, site, "Plan50CurvedFrontDrivePaverField", Vector3(0, -0.55, 126), Vector3(330, 1, 34), Color(0.54, 0.52, 0.48), true)
	_add_box(root, site, "FrontWalk", Vector3(26, -0.35, 124), Vector3(28, 1, 44), Color(0.68, 0.66, 0.60), true)
	_add_box(root, site, "RecessedEntryWalkLanding", Vector3(30, -0.30, 104), Vector3(58, 1, 22), Color(0.72, 0.70, 0.64), true)
	_add_box(root, site, "SideEntryDrivewayThreeCarApron", Vector3(-214, -0.35, 42), Vector3(84, 1, 188), Color(0.48, 0.48, 0.45), true)
	_add_box(root, site, "FrontBoxwoodHedgeRun", Vector3(60, 1.2, 146), Vector3(250, 2.4, 8), Color(0.10, 0.28, 0.12), false)

func _add_foundation(root: Node3D) -> void:
	var foundation := root.get_node("Foundation") as Node3D
	_add_box(root, foundation, "Plan50622MainFoundation", Vector3(0, 1.5, 0), Vector3(420, 3, 248), Color(0.42, 0.39, 0.34), false)
	_add_box(root, foundation, "BasementFoundationWall", Vector3(0, -22, 0), Vector3(424, 40, 252), Color(0.35, 0.35, 0.33), false)

func _add_main_floor(root: Node3D) -> void:
	var floor := root.get_node("MainFloor") as Node3D
	floor.set_meta("plan_role", "Plan 50-622 one-story split-bedroom main floor from user canvas reference")
	_add_room(root, floor, "SideEntryThreeCarGarage", Vector3(-154, MAIN_FLOOR_Y, 52), Vector3(104, 2, 110), Color(0.60, 0.60, 0.56))
	_add_room(root, floor, "SideEntryLargeGarageBay", Vector3(-154, MAIN_FLOOR_Y + 0.08, 22), Vector3(92, 2, 82), Color(0.58, 0.58, 0.54))
	_add_room(root, floor, "SideEntrySingleGarageBay", Vector3(-182, MAIN_FLOOR_Y + 0.10, 86), Vector3(56, 2, 58), Color(0.58, 0.58, 0.54))
	_add_room(root, floor, "MudroomService", Vector3(-84, MAIN_FLOOR_Y, 70), Vector3(52, 2, 48), Color(0.72, 0.67, 0.58))
	_add_room(root, floor, "Foyer", Vector3(36, MAIN_FLOOR_Y, 76), Vector3(58, 2, 54), Color(0.82, 0.74, 0.62))
	_add_room(root, floor, "FormalDiningWetBar", Vector3(-52, MAIN_FLOOR_Y, 100), Vector3(74, 2, 36), Color(0.84, 0.72, 0.54))
	_add_room(root, floor, "KitchenDining", Vector3(-34, MAIN_FLOOR_Y, 42), Vector3(82, 2, 70), Color(0.92, 0.78, 0.55))
	_add_room(root, floor, "SculleryPantry", Vector3(-78, MAIN_FLOOR_Y, 18), Vector3(42, 2, 54), Color(0.80, 0.74, 0.60))
	_add_room(root, floor, "GreatRoom", Vector3(42, MAIN_FLOOR_Y, -6), Vector3(94, 2, 94), Color(0.76, 0.62, 0.55))
	_add_room(root, floor, "MasterSuite", Vector3(-116, MAIN_FLOOR_Y, -42), Vector3(96, 2, 114), Color(0.62, 0.56, 0.68))
	_add_room(root, floor, "BedroomWing", Vector3(142, MAIN_FLOOR_Y, -30), Vector3(100, 2, 130), Color(0.60, 0.56, 0.70))
	_add_room(root, floor, "FrontCoveredPorch", Vector3(38, MAIN_FLOOR_Y, 132), Vector3(86, 2, 28), Color(0.66, 0.62, 0.55))
	_add_room(root, floor, "RearCoveredPorchOutdoorKitchen", Vector3(38, MAIN_FLOOR_Y, -132), Vector3(176, 2, 36), Color(0.66, 0.62, 0.55))
	_add_main_floor_partitions(root, floor)
	_add_main_floor_furnishings(root, floor)

func _add_attic_storage(root: Node3D) -> void:
	var attic := root.get_node("AtticStorage") as Node3D
	attic.set_meta("plan_role", "one-story attic and bonus storage volume for Popper above the side-entry garage/service wing")
	_add_room(root, attic, "BonusAtticStorage", Vector3(-146, ATTIC_STORAGE_Y, -104), Vector3(58, 2, 46), Color(0.64, 0.60, 0.55))
	_add_box(root, attic, "BonusAtticStorageTrunks", Vector3(-146, ATTIC_STORAGE_Y + 6, -104), Vector3(34, 12, 18), Color(0.32, 0.20, 0.12), false)
	_add_box(root, attic, "BonusAtticPrankShelf", Vector3(-172, ATTIC_STORAGE_Y + 8, -104), Vector3(8, 16, 36), Color(0.38, 0.26, 0.16), false)

func _add_basement(root: Node3D) -> void:
	var basement := root.get_node("Basement") as Node3D
	basement.set_meta("plan_role", "basement shell and unexcavated zones from user plan")
	_add_room(root, basement, "BasementPlayableShell", Vector3(12, BASEMENT_FLOOR_Y, 2), Vector3(190, 2, 156), Color(0.52, 0.53, 0.50))
	_add_room(root, basement, "UnexcavatedGarageZone", Vector3(-102, BASEMENT_FLOOR_Y, -62), Vector3(96, 2, 112), Color(0.32, 0.31, 0.29))
	_add_room(root, basement, "UnexcavatedMasterZone", Vector3(124, BASEMENT_FLOOR_Y, 24), Vector3(68, 2, 90), Color(0.32, 0.31, 0.29))

func _add_patio_pool(root: Node3D) -> void:
	var patio := root.get_node("PatioPool") as Node3D
	patio.set_meta("plan_role", "rear patio and non-playable pool-reference edge")
	_add_box(root, patio, "RearPatio", Vector3(52, -0.25, -154), Vector3(188, 1.2, 92), Color(0.62, 0.60, 0.56), true)
	_add_box(root, patio, "PoolNotIncludedReferenceWater", Vector3(96, -0.15, -206), Vector3(92, 0.7, 72), Color(0.20, 0.58, 0.75, 0.55), false)
	_add_box(root, patio, "PoolSafetyEdge", Vector3(96, 0.4, -165), Vector3(98, 1.2, 4), Color(0.74, 0.72, 0.66), false)

func _add_yard_zones(root: Node3D) -> void:
	var yard := root.get_node("YardZones") as Node3D
	yard.set_meta("plan_role", "story-bible outdoor owner zones tied to patio, driveway, garden, and sandbox territory")
	yard.set_meta("outdoor_zone_contract", OUTDOOR_ZONE_CONTRACT)
	var moko_zone := OUTDOOR_ZONE_CONTRACT["moko_garden_patio"] as Dictionary
	_add_zone_surface(root, yard, "MokoGardenPatioSurface", moko_zone, Color(0.30, 0.45, 0.24))
	_add_zone_surface(root, yard, "MokoGardenMulchBedNorth", {
		"owner_character": "Moko",
		"owner_zone": "garden_patio",
		"bounds_center": Vector3(-72, 0.35, -248),
		"bounds_size": Vector3(110, 0.8, 12),
		"surface_material": "mulch_planting_mass",
		"scale_class": "yard_site",
		"route_clearance": "non_colliding_edge_mass_outside_route",
		"validation_camera": "MokoGardenPatioCamera",
	}, Color(0.18, 0.12, 0.08), false)
	_add_zone_surface(root, yard, "MokoPatioPlanterRhythm", {
		"owner_character": "Moko",
		"owner_zone": "garden_patio",
		"bounds_center": Vector3(-22, 1.2, -182),
		"bounds_size": Vector3(16, 2.4, 64),
		"surface_material": "raised_planter_edge",
		"scale_class": "yard_site",
		"route_clearance": "edge_landmark_set_back_from_plan50_rear_porch_loop",
		"validation_camera": "MokoGardenPatioCamera",
	}, Color(0.33, 0.24, 0.14), false)
	var rexx_zone := OUTDOOR_ZONE_CONTRACT["rexx_sandbox_fossil_play_yard"] as Dictionary
	_add_zone_surface(root, yard, "RexxSandboxFossilPlayYardSurface", rexx_zone, Color(0.73, 0.63, 0.39))
	_add_zone_surface(root, yard, "RexxFossilDigRidge", {
		"owner_character": "Rexx",
		"owner_zone": "sandbox_fossil_play_yard",
		"bounds_center": Vector3(148, 2.4, -214),
		"bounds_size": Vector3(78, 4.8, 8),
		"surface_material": "packed_sand_ridge",
		"scale_class": "yard_site",
		"route_clearance": "visual_boundary_outside_plan50_rear_porch_loop",
		"validation_camera": "RexxSandboxCamera",
	}, Color(0.58, 0.46, 0.28), false)
	_add_zone_surface(root, yard, "RexxToyFossilMarkerCluster", {
		"owner_character": "Rexx",
		"owner_zone": "sandbox_fossil_play_yard",
		"bounds_center": Vector3(170, 1.3, -240),
		"bounds_size": Vector3(28, 2.6, 14),
		"surface_material": "toy_bone_marker_cluster",
		"scale_class": "toy_scale_racing",
		"route_clearance": "decor_only_outside_route_corridor",
		"validation_camera": "RexxSandboxCamera",
	}, Color(0.86, 0.80, 0.62), false)
	var dash_zone := OUTDOOR_ZONE_CONTRACT["dash_driveway_service_stunt_route"] as Dictionary
	_add_zone_surface(root, yard, "DashDrivewayServiceStuntRouteSurface", dash_zone, Color(0.42, 0.42, 0.39))
	_add_zone_surface(root, yard, "DashGarageApronLaunchStripe", {
		"owner_character": "Dash",
		"owner_zone": "garage_service_driveway_stunt_route",
		"bounds_center": Vector3(-104, 0.9, 136),
		"bounds_size": Vector3(92, 1.8, 6),
		"surface_material": "painted_driveway_start_stripe",
		"scale_class": "toy_scale_racing",
		"route_clearance": "flush_visual_surface_no_camera_blocker",
		"validation_camera": "DashDrivewayServiceCamera",
	}, Color(0.92, 0.88, 0.28), false)
	_add_zone_surface(root, yard, "DashServiceWorkbenchOutdoorPad", {
		"owner_character": "Dash",
		"owner_zone": "garage_service_driveway_stunt_route",
		"bounds_center": Vector3(-166, 0.7, 20),
		"bounds_size": Vector3(28, 1.4, 52),
		"surface_material": "service_side_concrete_pad",
		"scale_class": "yard_site",
		"route_clearance": "side_service_zone_outside_driveway_line",
		"validation_camera": "DashDrivewayServiceCamera",
	}, Color(0.50, 0.50, 0.47), true)

func _add_zone_surface(root: Node3D, parent: Node3D, node_name: String, zone: Dictionary, color: Color, collision := true) -> MeshInstance3D:
	var mesh := _add_box(root, parent, node_name, zone.get("bounds_center", Vector3.ZERO) as Vector3, zone.get("bounds_size", Vector3.ONE) as Vector3, color, collision)
	mesh.set_meta("owner_character", str(zone.get("owner_character", "")))
	mesh.set_meta("owner_zone", str(zone.get("owner_zone", "")))
	mesh.set_meta("scale_class", str(zone.get("scale_class", "")))
	mesh.set_meta("surface_material", str(zone.get("surface_material", "")))
	mesh.set_meta("route_clearance", str(zone.get("route_clearance", "")))
	mesh.set_meta("validation_camera", str(zone.get("validation_camera", "")))
	mesh.set_meta("landscape_role", "outdoor_zone_surface_or_edge_landmark")
	return mesh

func _add_exterior_shell(root: Node3D) -> void:
	var shell := root.get_node("ExteriorShell") as Node3D
	shell.set_meta("plan_role", "single owner of exterior walls and openings for Plan 50-622 one-story home")
	shell.set_meta("style_contract", "modern farmhouse: white siding, black framed windows, gabled roof hierarchy, covered porches, three garage doors")
	if _add_blender_visible_shell(root, shell):
		return
	var siding := Color(0.88, 0.86, 0.78)
	var stone := Color(0.50, 0.48, 0.42)
	_add_box(root, shell, "Plan50FrontLeftMasterGableWall", Vector3(-122, 23, 120), Vector3(78, 46, 6), siding, true)
	_add_box(root, shell, "Plan50FrontCenterGreatRoomGableWall", Vector3(-8, 24, 120), Vector3(92, 48, 6), siding.lightened(0.02), true)
	_add_box(root, shell, "Plan50FrontRecessedEntryBackWall", Vector3(52, 22, 106), Vector3(54, 44, 6), siding.darkened(0.02), true)
	_add_box(root, shell, "Plan50FrontRightBedroomGableWall", Vector3(142, 23, 120), Vector3(86, 46, 6), siding, true)
	_add_box(root, shell, "Plan50RearGreatRoomWall", Vector3(38, 23, -118), Vector3(176, 46, 6), siding.darkened(0.02), true)
	_add_box(root, shell, "Plan50RearBedroomWingWall", Vector3(142, 22, -96), Vector3(90, 44, 6), siding.darkened(0.03), true)
	_add_box(root, shell, "Plan50RearMasterWingWall", Vector3(-116, 22, -96), Vector3(96, 44, 6), siding.darkened(0.03), true)
	_add_box(root, shell, "Plan50LeftGarageOuterWall", Vector3(-206, 22, 42), Vector3(6, 44, 164), siding.darkened(0.06), true)
	_add_box(root, shell, "Plan50LeftGarageStreetReturnWall", Vector3(-154, 22, 122), Vector3(104, 44, 6), siding.darkened(0.04), true)
	_add_box(root, shell, "Plan50MasterGarageStepWall", Vector3(-72, 22, 18), Vector3(6, 44, 96), siding.darkened(0.04), true)
	_add_box(root, shell, "Plan50RightBedroomOuterWall", Vector3(194, 22, -20), Vector3(6, 44, 136), siding.darkened(0.03), true)
	_add_box(root, shell, "Plan50StonePlinthFrontLeft", Vector3(-122, 4, 123), Vector3(84, 8, 8), stone, false)
	_add_box(root, shell, "Plan50StonePlinthFrontCenter", Vector3(-8, 4, 123), Vector3(98, 8, 8), stone, false)
	_add_box(root, shell, "Plan50StonePlinthFrontRight", Vector3(142, 4, 123), Vector3(92, 8, 8), stone, false)
	_add_box(root, shell, "Plan50StonePlinthRearPorch", Vector3(38, 4, -121), Vector3(188, 8, 8), stone, false)
	_add_farmhouse_exterior_details(root, shell, root.get_node("Openings") as Node3D)

func _add_roof(root: Node3D) -> void:
	var roof := root.get_node("Roof") as Node3D
	roof.set_meta("plan_role", "Plan 50-622 one-story gabled roof hierarchy with 12:12 primary and 4:12 porch/secondary slopes")
	if ResourceLoader.exists(VISIBLE_SHELL_ASSET_PATH):
		roof.set_meta("visible_roof_source", VISIBLE_SHELL_ASSET_PATH)
		return
	var roof_color := Color(0.18, 0.19, 0.18)
	_add_gable_roof_z(root, roof, "Plan50PrimaryRearLongRoof", -170, 190, -122, 92, 48, 116, roof_color)
	_add_gable_roof_x(root, roof, "Plan50FrontLeftMasterStreetGable", -164, -82, 76, 132, 44, 98, roof_color.darkened(0.02))
	_add_gable_roof_x(root, roof, "Plan50FrontCenterGreatRoomStreetGable", -58, 42, 70, 132, 48, 108, roof_color)
	_add_gable_roof_x(root, roof, "Plan50FrontRightBedroomStreetGable", 98, 186, 76, 132, 44, 98, roof_color.darkened(0.02))
	_add_gable_roof_x(root, roof, "Plan50GarageSideEntryGable", -210, -98, -18, 126, 42, 90, roof_color.darkened(0.04))
	_add_gable_roof_z(root, roof, "Plan50RecessedEntryMetalShedRoof", 8, 92, 106, 138, 37, 48, Color(0.06, 0.07, 0.07))
	_add_gable_roof_x(root, roof, "Plan50RearPorchGable", -50, 126, -150, -116, 34, 46, roof_color.lightened(0.05))
	_add_gable_end_wall_x(root, roof, "Plan50LeftMasterFrontGableWall", -164, -82, 132.5, 44, 98, Color(0.88, 0.86, 0.78))
	_add_gable_end_wall_x(root, roof, "Plan50CenterGreatRoomFrontGableWall", -58, 42, 132.5, 48, 108, Color(0.90, 0.88, 0.80))
	_add_gable_end_wall_x(root, roof, "Plan50RightBedroomFrontGableWall", 98, 186, 132.5, 44, 98, Color(0.88, 0.86, 0.78))
	_add_gable_end_wall_z(root, roof, "Plan50PrimaryLeftGableWall", -170.5, -122, 92, 48, 116, Color(0.86, 0.84, 0.76).darkened(0.04))
	_add_gable_end_wall_z(root, roof, "Plan50PrimaryRightGableWall", 190.5, -122, 92, 48, 116, Color(0.86, 0.84, 0.76).darkened(0.03))
	_add_box(root, roof, "Plan50BlackMetalGutterFrontLeft", Vector3(-122, 46, 135), Vector3(88, 3, 3), Color(0.06, 0.07, 0.07), false)
	_add_box(root, roof, "Plan50BlackMetalGutterFrontCenter", Vector3(-8, 50, 135), Vector3(104, 3, 3), Color(0.06, 0.07, 0.07), false)
	_add_box(root, roof, "Plan50BlackMetalGutterFrontRight", Vector3(142, 46, 135), Vector3(94, 3, 3), Color(0.06, 0.07, 0.07), false)
	_add_box(root, roof, "Plan50BlackMetalGutterRear", Vector3(38, 48, -124), Vector3(260, 3, 3), Color(0.06, 0.07, 0.07), false)

func _add_vertical_connectors(root: Node3D) -> void:
	var vc := root.get_node("VerticalConnectors") as Node3D
	vc.set_meta("plan_role", "Plan 50-622 one-story basement stair plus attic-storage pull-down access; no full upper story")
	_add_box(root, vc, "AtticStoragePullDownAccess", Vector3(-126, 18, -82), Vector3(14, 34, 20), Color(0.56, 0.34, 0.20), false, 0, Vector3(-18, 0, 0))
	_add_box(root, vc, "MainToBasementStairRun", Vector3(-14, -20, 36), Vector3(16, 42, 52), Color(0.42, 0.28, 0.18), false, 0, Vector3(28, 0, 0))

func _add_course_route_markers(root: Node3D) -> void:
	var holder := root.get_node("CourseRoutes") as Node3D
	for course in COURSES:
		var course_id := str(course["id"])
		var route_holder := Node3D.new()
		route_holder.name = "%sRoutePreview" % course_id.to_pascal_case()
		holder.add_child(route_holder)
		route_holder.owner = root
		var envelope := _route_envelope_for_course(course)
		var audit_box := _add_box(root, route_holder, "RouteContainmentAuditBox", (envelope["min"] + envelope["max"]) * 0.5, envelope["max"] - envelope["min"], Color(0.2, 0.8, 1.0, 0.12), false)
		audit_box.visible = false
		audit_box.set_meta("visible_class", "validation_only_hidden_route_envelope")
		audit_box.set_meta("deletion_rule", "may be removed only after equivalent route-envelope metadata gate exists")

func _apply_character_zone_metadata(root: Node3D) -> void:
	for item in [
		{"path": "MainFloor/KitchenDining", "owner": "Sir Clink", "zone": "kitchen", "scale": "human_scale_shell", "camera": "Plan50KitchenStartPlayerCamera"},
		{"path": "MainFloor/KitchenIsland", "owner": "Sir Clink", "zone": "kitchen", "scale": "room_furnishing", "camera": "Plan50KitchenStartPlayerCamera"},
		{"path": "MainFloor/KitchenCabinetRunBack", "owner": "Sir Clink", "zone": "kitchen", "scale": "room_furnishing", "camera": "Plan50KitchenStartPlayerCamera"},
		{"path": "MainFloor/GreatRoom", "owner": "Slammo", "zone": "great_room", "scale": "human_scale_shell", "camera": "Plan50GreatRoomStartPlayerCamera"},
		{"path": "MainFloor/GreatRoomSofa", "owner": "Slammo", "zone": "great_room", "scale": "room_furnishing", "camera": "Plan50GreatRoomStartPlayerCamera"},
		{"path": "MainFloor/GreatRoomFireplace", "owner": "Slammo", "zone": "great_room", "scale": "room_furnishing", "camera": "Plan50GreatRoomStartPlayerCamera"},
		{"path": "MainFloor/SideEntryThreeCarGarage", "owner": "Dash", "zone": "garage_service_driveway_stunt_route", "scale": "human_scale_shell", "camera": "Plan50GarageStartPlayerCamera"},
		{"path": "MainFloor/GarageWorkbench", "owner": "Dash", "zone": "garage_service_driveway_stunt_route", "scale": "room_furnishing", "camera": "Plan50GarageStartPlayerCamera"},
		{"path": "MainFloor/MasterSuite", "owner": "Velva", "zone": "master_suite_plus_walk_in_closet", "scale": "human_scale_shell", "camera": "Plan50MasterSuiteStartPlayerCamera"},
		{"path": "MainFloor/MasterBed", "owner": "Velva", "zone": "master_suite_plus_walk_in_closet", "scale": "room_furnishing", "camera": "Plan50MasterSuiteStartPlayerCamera"},
		{"path": "MainFloor/MasterClosetBuiltIns", "owner": "Velva", "zone": "master_suite_plus_walk_in_closet", "scale": "room_furnishing", "camera": "Plan50MasterSuiteStartPlayerCamera"},
		{"path": "MainFloor/BedroomWing", "owner": "Tuggs", "zone": "bedroom_wing", "scale": "human_scale_shell", "camera": "Plan50BedroomWingStartPlayerCamera"},
		{"path": "MainFloor/BedroomWingBedA", "owner": "Tuggs", "zone": "bedroom_wing", "scale": "room_furnishing", "camera": "Plan50BedroomWingStartPlayerCamera"},
		{"path": "MainFloor/BedroomWingBedB", "owner": "Tuggs", "zone": "bedroom_wing", "scale": "room_furnishing", "camera": "Plan50BedroomWingStartPlayerCamera"},
		{"path": "AtticStorage/BonusAtticStorage", "owner": "Popper", "zone": "bonus_room_attic_storage_prank_space", "scale": "human_scale_shell", "camera": "Plan50BonusStorageStartPlayerCamera"},
		{"path": "AtticStorage/BonusAtticStorageTrunks", "owner": "Popper", "zone": "bonus_room_attic_storage_prank_space", "scale": "room_furnishing", "camera": "Plan50BonusStorageStartPlayerCamera"},
		{"path": "PatioPool/RearPatio", "owner": "Moko", "zone": "garden_patio", "scale": "yard_site", "camera": "Plan50RearPorchStartPlayerCamera"},
		{"path": "YardZones/RexxSandboxFossilPlayYardSurface", "owner": "Rexx", "zone": "sandbox_fossil_play_yard", "scale": "yard_site", "camera": "Plan50SandboxYardStartPlayerCamera"},
	]:
		var dict := item as Dictionary
		var node := root.get_node_or_null(str(dict["path"]))
		if node == null:
			push_error("Missing character-zone metadata target: %s" % str(dict["path"]))
			quit(1)
			return
		_apply_owner_zone_to_node(node, str(dict["owner"]), str(dict["zone"]), str(dict["scale"]), str(dict["camera"]))

func _apply_owner_zone_to_node(node: Node, owner_character: String, owner_zone: String, scale_class: String, validation_camera: String) -> void:
	node.set_meta("owner_character", owner_character)
	node.set_meta("owner_zone", owner_zone)
	node.set_meta("scale_class", scale_class)
	if node.has_meta("landscape_role") and node.has_meta("validation_camera") and str(node.get_meta("validation_camera", "")) != "":
		node.set_meta("course_validation_camera", validation_camera)
	else:
		node.set_meta("validation_camera", validation_camera)
	node.set_meta("character_zone_mapping_path", CHARACTER_MAPPING_PATH)

func _add_validation_cameras(root: Node3D) -> void:
	var cameras := root.get_node("ValidationCameras") as Node3D
	cameras.visible = false
	cameras.set_meta("default_visibility", "hidden_for_clean_exterior_shell_review")
	_add_camera(root, cameras, "MainFloorPlanCamera", Vector3(0, 210, 220), Vector3(-62, 0, 0), 70)
	_add_camera(root, cameras, "AtticStoragePlanCamera", Vector3(-146, 86, -34), Vector3(-62, 0, 0), 54)
	_add_camera(root, cameras, "PatioPoolCamera", Vector3(120, 70, -245), Vector3(-18, 28, 0), 58)
	_add_camera(root, cameras, "MokoGardenPatioCamera", Vector3(-96, 54, -302), Vector3(-22, -12, 0), 56)
	_add_camera(root, cameras, "RexxSandboxCamera", Vector3(184, 46, -300), Vector3(-18, 18, 0), 54)
	_add_camera(root, cameras, "DashDrivewayServiceCamera", Vector3(-196, 42, 156), Vector3(-18, -52, 0), 58)
	for course in COURSES:
		var course_id := str(course["id"])
		var pos := course["placement"] as Vector3
		_add_camera(root, cameras, "%sStartPlayerCamera" % course_id.to_pascal_case(), pos + Vector3(-42, 24, 54), Vector3(-14, -38, 0), 54)

func _add_lighting(root: Node3D) -> void:
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.light_energy = 2.4
	sun.rotation_degrees = Vector3(-44, -35, 0)
	root.add_child(sun)
	sun.owner = root

func _add_blender_visible_shell(root: Node3D, shell: Node3D) -> bool:
	if not ResourceLoader.exists(VISIBLE_SHELL_ASSET_PATH):
		return false
	var packed := load(VISIBLE_SHELL_ASSET_PATH)
	if not (packed is PackedScene):
		push_warning("Visible shell asset is not a PackedScene: %s" % VISIBLE_SHELL_ASSET_PATH)
		return false
	var instance := (packed as PackedScene).instantiate() as Node3D
	if instance == null:
		push_warning("Could not instantiate visible shell asset: %s" % VISIBLE_SHELL_ASSET_PATH)
		return false
	instance.name = "ModernFarmhouseShellAsset"
	instance.set_meta("asset_source", VISIBLE_SHELL_ASSET_PATH)
	instance.set_meta("authoring_source", "scripts/tools/create_home_plan50622_shell_blender.py")
	instance.set_meta("reference_source", "docs/concepts/home_plan50_622_v1/floor_plan_contract.md")
	instance.set_meta("collision_policy", "visual shell only; generator-owned route and boundary collision remains separate")
	_apply_generated_provenance(instance, shell, "ModernFarmhouseShellAsset", Vector3.ZERO, Vector3(324, 96, 296), "imported_visible_shell", "home_exterior_shell")
	shell.add_child(instance)
	instance.owner = root
	var scale_envelope := _add_box(root, shell, "ModernFarmhouseShellScaleEnvelope", Vector3(0, 24, 0), Vector3(324, 48, 296), Color(1, 1, 1, 0.0), false)
	scale_envelope.visible = false
	return true

func _add_main_floor_partitions(root: Node3D, floor: Node3D) -> void:
	var wall := Color(0.80, 0.77, 0.68)
	_add_wall_x(root, floor, "KitchenGarageInteriorWall", -58, -18, 84, wall, MAIN_FLOOR_Y, 34)
	_add_wall_z(root, floor, "KitchenGreatRoomCasedOpeningWallLeft", 82, -88, -24, wall, MAIN_FLOOR_Y, 34)
	_add_wall_z(root, floor, "KitchenGreatRoomCasedOpeningWallRight", 82, 6, 96, wall, MAIN_FLOOR_Y, 34)
	_add_wall_x(root, floor, "GreatRoomMasterSuiteWall", 96, -12, 82, wall, MAIN_FLOOR_Y, 34)
	_add_wall_z(root, floor, "MudOfficeKitchenWall", 78, -148, -80, wall, MAIN_FLOOR_Y, 34)
	_add_wall_z(root, floor, "KitchenFrontDiningWall", 92, -82, -8, wall, MAIN_FLOOR_Y, 28)
	_add_wall_x(root, floor, "OfficeMudPartition", -116, 40, 98, wall.darkened(0.04), MAIN_FLOOR_Y, 28)
	_add_trim_z(root, floor, "GreatRoomCeilingBeamA", 10, 10, -20, 94, Color(0.22, 0.16, 0.12))
	_add_trim_z(root, floor, "GreatRoomCeilingBeamB", 10, 44, -20, 94, Color(0.22, 0.16, 0.12))

func _add_main_floor_furnishings(root: Node3D, floor: Node3D) -> void:
	var wood := Color(0.43, 0.27, 0.16)
	_add_phase3_placeholder_furnishing(root, floor, "KitchenIsland", Vector3(-44, 6, 35), Vector3(18, 12, 42), wood)
	_add_phase3_placeholder_furnishing(root, floor, "KitchenCabinetRunBack", Vector3(-50, 7, 0), Vector3(58, 14, 10), Color(0.74, 0.70, 0.62))
	_add_phase3_placeholder_furnishing(root, floor, "KitchenRangeHood", Vector3(-34, 19, -4), Vector3(18, 16, 6), Color(0.34, 0.36, 0.35))
	_add_phase3_placeholder_furnishing(root, floor, "DiningTable", Vector3(-28, 5, 82), Vector3(34, 8, 16), wood.lightened(0.08))
	_add_phase3_placeholder_furnishing(root, floor, "GreatRoomFireplace", Vector3(96, 12, 34), Vector3(8, 24, 28), Color(0.32, 0.24, 0.20))
	_add_phase3_placeholder_furnishing(root, floor, "GreatRoomSofa", Vector3(48, 6, 52), Vector3(42, 12, 14), Color(0.38, 0.48, 0.55))
	_add_phase3_placeholder_furnishing(root, floor, "GreatRoomCoffeeTable", Vector3(48, 4, 26), Vector3(24, 6, 12), wood)
	_add_phase3_placeholder_furnishing(root, floor, "MasterBed", Vector3(-116, 6, -42), Vector3(34, 12, 48), Color(0.58, 0.62, 0.76))
	_add_phase3_placeholder_furnishing(root, floor, "MasterClosetBuiltIns", Vector3(-156, 8, -24), Vector3(8, 16, 42), Color(0.72, 0.67, 0.58))
	_add_phase3_placeholder_furnishing(root, floor, "BedroomWingBedA", Vector3(126, 6, -48), Vector3(28, 12, 34), Color(0.58, 0.62, 0.76))
	_add_phase3_placeholder_furnishing(root, floor, "BedroomWingBedB", Vector3(166, 6, -70), Vector3(28, 12, 34), Color(0.58, 0.62, 0.76))
	_add_phase3_placeholder_furnishing(root, floor, "BedroomWingSoftBarrier", Vector3(142, 5, -6), Vector3(68, 10, 8), Color(0.54, 0.50, 0.66))
	_add_phase3_placeholder_furnishing(root, floor, "GarageCarBayMarkerLeft", Vector3(-174, 1.4, 58), Vector3(22, 0.5, 90), Color(0.28, 0.30, 0.31))
	_add_phase3_placeholder_furnishing(root, floor, "GarageCarBayMarkerCenter", Vector3(-150, 1.4, 58), Vector3(22, 0.5, 90), Color(0.28, 0.30, 0.31))
	_add_phase3_placeholder_furnishing(root, floor, "GarageCarBayMarkerRight", Vector3(-126, 1.4, 58), Vector3(22, 0.5, 90), Color(0.28, 0.30, 0.31))
	_add_phase3_placeholder_furnishing(root, floor, "GarageWorkbench", Vector3(-104, 7, 18), Vector3(10, 14, 44), wood.darkened(0.08))

func _add_phase3_placeholder_furnishing(root: Node3D, parent: Node3D, node_name: String, position: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var furnishing := _add_box(root, parent, node_name, position, size, color, false)
	furnishing.visible = false
	furnishing.set_meta("visible_class", "phase3_provisional_hidden_furnishing")
	furnishing.set_meta("default_visibility", "hidden_until_sourced_phase3_asset")
	furnishing.set_meta("deletion_rule", "replace through Phase 3 sourced asset contract before production-visible review")
	return furnishing

func _add_farmhouse_exterior_details(root: Node3D, shell: Node3D, openings: Node3D) -> void:
	_add_box(root, openings, "Plan50RecessedFrontDoorBlackPanel", Vector3(52, 17, 108.5), Vector3(18, 30, 2.5), Color(0.04, 0.05, 0.05), false)
	_add_box(root, openings, "Plan50FrontDoorWarmGlass", Vector3(52, 20, 106.8), Vector3(10, 20, 1.0), Color(1.0, 0.72, 0.28, 0.68), false)
	_add_framed_window_z(root, openings, "Plan50LeftMasterFrontWindowGroup", Vector3(-122, 25, 123.5), Vector3(42, 28, 2.0))
	_add_framed_window_z(root, openings, "Plan50CenterGreatRoomTallWindowGroup", Vector3(-8, 27, 123.5), Vector3(50, 34, 2.0))
	_add_framed_window_z(root, openings, "Plan50RightBedroomFrontWindowGroup", Vector3(142, 25, 123.5), Vector3(42, 28, 2.0))
	_add_framed_window_z(root, openings, "Plan50LeftGableSlotWindow", Vector3(-122, 58, 123.8), Vector3(12, 20, 2.0))
	_add_framed_window_z(root, openings, "Plan50CenterGableSlotWindow", Vector3(-8, 64, 123.8), Vector3(12, 20, 2.0))
	_add_framed_window_z(root, openings, "Plan50RightGableSlotWindow", Vector3(142, 58, 123.8), Vector3(12, 20, 2.0))
	_add_framed_window_z(root, openings, "Plan50RearPorchLeftDoorWindowGroup", Vector3(-54, 23, -121.5), Vector3(44, 30, 2.0))
	_add_framed_window_z(root, openings, "Plan50RearPorchCenterDoorWindowGroup", Vector3(22, 23, -121.5), Vector3(64, 30, 2.0))
	_add_framed_window_z(root, openings, "Plan50RearPorchKitchenWindowGroup", Vector3(82, 22, -121.5), Vector3(38, 24, 2.0))
	_add_framed_window_z(root, openings, "Plan50RearRightBedroomGableWindowGroup", Vector3(150, 23, -99.5), Vector3(38, 28, 2.0))
	_add_framed_window_x(root, openings, "Plan50LeftServiceDoorA", Vector3(-209.5, 18, -64), Vector3(2.5, 30, 14))
	_add_framed_window_x(root, openings, "Plan50LeftServiceDoorB", Vector3(-209.5, 18, -8), Vector3(2.5, 30, 14))
	_add_framed_window_x(root, openings, "Plan50LeftServiceTallWindow", Vector3(-209.5, 22, -110), Vector3(2.0, 26, 18))
	_add_framed_window_x(root, openings, "Plan50RightSideSmallHorizontalWindow", Vector3(197.5, 30, 42), Vector3(2.0, 10, 26))
	_add_framed_window_x(root, openings, "Plan50RightSideTallWindowA", Vector3(197.5, 22, -8), Vector3(2.0, 28, 16))
	_add_framed_window_x(root, openings, "Plan50RightSideTallWindowB", Vector3(197.5, 22, -54), Vector3(2.0, 28, 16))
	_add_framed_window_x(root, openings, "Plan50MasterSideWindowStack", Vector3(-164.5, 24, -42), Vector3(2.0, 28, 40))
	_add_garage_door_z(root, openings, "Plan50FrontSingleGarageDoor", Vector3(-180, 17, 125.5), Vector3(28, 28, 2.5))
	_add_garage_door_x(root, openings, "Plan50LargeSideEntryGarageDoorA", Vector3(-209.5, 17, 10), Vector3(2.5, 28, 34))
	_add_garage_door_x(root, openings, "Plan50LargeSideEntryGarageDoorB", Vector3(-209.5, 17, 48), Vector3(2.5, 28, 34))
	_add_box(root, shell, "Plan50LeftWindowBlackMetalAwning", Vector3(-122, 40, 127), Vector3(52, 4, 8), Color(0.06, 0.07, 0.07), false)
	_add_box(root, shell, "Plan50RecessedEntryBlackMetalShedRoof", Vector3(52, 42, 124), Vector3(86, 4, 28), Color(0.06, 0.07, 0.07), false)
	for x in [16.0, 52.0, 88.0]:
		_add_box(root, shell, "FrontPorchColumn%s" % int(x), Vector3(x, 22, 122), Vector3(6, 44, 6), Color(0.88, 0.86, 0.78), true)
	_add_box(root, shell, "FrontPorchLeftReturnWall", Vector3(10, 22, 120), Vector3(4, 36, 34), Color(0.88, 0.86, 0.78), true)
	_add_box(root, shell, "FrontPorchRightReturnWall", Vector3(94, 22, 120), Vector3(4, 36, 34), Color(0.88, 0.86, 0.78), true)
	for x in [8.0, 48.0, 88.0]:
		_add_box(root, shell, "RearPorchColumn%s" % int(x), Vector3(x, 22, -124), Vector3(6, 44, 6), Color(0.88, 0.86, 0.78), true)
	for x in [-54.0, 126.0]:
		_add_box(root, shell, "RearElevationEndPost%s" % int(x), Vector3(x, 22, -124), Vector3(5, 44, 5), Color(0.88, 0.86, 0.78), true)
	_add_gable_end_wall_z(root, shell, "RightElevationDominantGableFace", 197.0, -80.0, 56.0, 44.0, 86.0, Color(0.90, 0.88, 0.80))
	_add_box(root, shell, "LeftElevationServiceDoorPorchStep", Vector3(-214, 1.2, -64), Vector3(24, 2.4, 18), Color(0.62, 0.60, 0.56), false)
	_add_box(root, shell, "BoardAndBattenFrontLeftBelt", Vector3(-122, 39, 126), Vector3(82, 4, 3), Color(0.92, 0.90, 0.84), false)
	_add_box(root, shell, "BoardAndBattenFrontCenterBelt", Vector3(-8, 42, 126), Vector3(96, 4, 3), Color(0.92, 0.90, 0.84), false)
	_add_box(root, shell, "BoardAndBattenFrontRightBelt", Vector3(142, 39, 126), Vector3(90, 4, 3), Color(0.92, 0.90, 0.84), false)
	_add_box(root, shell, "BoardAndBattenRearBelt", Vector3(38, 38, -123), Vector3(184, 4, 3), Color(0.92, 0.90, 0.84), false)
	_add_box(root, shell, "FrontEntryPorchBeam", Vector3(52, 45, 122), Vector3(94, 7, 8), Color(0.86, 0.84, 0.76), false)

func _add_gable_roof_x(root: Node3D, parent: Node3D, prefix: String, x0: float, x1: float, z0: float, z1: float, eave_y: float, ridge_y: float, color: Color) -> void:
	var ridge_x := (x0 + x1) * 0.5
	var left_vertices := PackedVector3Array([
		Vector3(x0, eave_y, z0),
		Vector3(x0, eave_y, z1),
		Vector3(ridge_x, ridge_y, z1),
		Vector3(ridge_x, ridge_y, z0),
	])
	var right_vertices := PackedVector3Array([
		Vector3(ridge_x, ridge_y, z0),
		Vector3(ridge_x, ridge_y, z1),
		Vector3(x1, eave_y, z1),
		Vector3(x1, eave_y, z0),
	])
	_add_mesh(root, parent, "%sLeftRoofPlane" % prefix, left_vertices, PackedInt32Array([0, 1, 2, 0, 2, 3]), color)
	_add_mesh(root, parent, "%sRightRoofPlane" % prefix, right_vertices, PackedInt32Array([0, 1, 2, 0, 2, 3]), color.darkened(0.04))
	_add_box(root, parent, "%sRidgeCap" % prefix, Vector3(ridge_x, ridge_y + 1.0, (z0 + z1) * 0.5), Vector3(4, 3, absf(z1 - z0)), color.darkened(0.18), false)
	_add_box(root, parent, "%sLeftFascia" % prefix, Vector3(x0, eave_y, (z0 + z1) * 0.5), Vector3(4, 5, absf(z1 - z0)), color.darkened(0.12), false)
	_add_box(root, parent, "%sRightFascia" % prefix, Vector3(x1, eave_y, (z0 + z1) * 0.5), Vector3(4, 5, absf(z1 - z0)), color.darkened(0.12), false)
	_add_box(root, parent, "%sFrontFascia" % prefix, Vector3((x0 + x1) * 0.5, eave_y, z1), Vector3(absf(x1 - x0), 5, 4), color.darkened(0.12), false)
	_add_box(root, parent, "%sRearFascia" % prefix, Vector3((x0 + x1) * 0.5, eave_y, z0), Vector3(absf(x1 - x0), 5, 4), color.darkened(0.12), false)

func _add_gable_roof_z(root: Node3D, parent: Node3D, prefix: String, x0: float, x1: float, z0: float, z1: float, eave_y: float, ridge_y: float, color: Color) -> void:
	var ridge_z := (z0 + z1) * 0.5
	var front_vertices := PackedVector3Array([
		Vector3(x0, eave_y, z1),
		Vector3(x1, eave_y, z1),
		Vector3(x1, ridge_y, ridge_z),
		Vector3(x0, ridge_y, ridge_z),
	])
	var rear_vertices := PackedVector3Array([
		Vector3(x0, ridge_y, ridge_z),
		Vector3(x1, ridge_y, ridge_z),
		Vector3(x1, eave_y, z0),
		Vector3(x0, eave_y, z0),
	])
	_add_mesh(root, parent, "%sFrontRoofPlane" % prefix, front_vertices, PackedInt32Array([0, 1, 2, 0, 2, 3]), color)
	_add_mesh(root, parent, "%sRearRoofPlane" % prefix, rear_vertices, PackedInt32Array([0, 1, 2, 0, 2, 3]), color.darkened(0.04))
	_add_box(root, parent, "%sRidgeCap" % prefix, Vector3((x0 + x1) * 0.5, ridge_y + 1.0, ridge_z), Vector3(absf(x1 - x0), 3, 4), color.darkened(0.18), false)
	_add_box(root, parent, "%sFrontFascia" % prefix, Vector3((x0 + x1) * 0.5, eave_y, z1), Vector3(absf(x1 - x0), 5, 4), color.darkened(0.12), false)
	_add_box(root, parent, "%sRearFascia" % prefix, Vector3((x0 + x1) * 0.5, eave_y, z0), Vector3(absf(x1 - x0), 5, 4), color.darkened(0.12), false)
	_add_box(root, parent, "%sLeftFascia" % prefix, Vector3(x0, eave_y, (z0 + z1) * 0.5), Vector3(4, 5, absf(z1 - z0)), color.darkened(0.12), false)
	_add_box(root, parent, "%sRightFascia" % prefix, Vector3(x1, eave_y, (z0 + z1) * 0.5), Vector3(4, 5, absf(z1 - z0)), color.darkened(0.12), false)

func _add_gable_end_wall_x(root: Node3D, parent: Node3D, node_name: String, x0: float, x1: float, z: float, eave_y: float, ridge_y: float, color: Color) -> void:
	var ridge_x := (x0 + x1) * 0.5
	var vertices := PackedVector3Array([
		Vector3(x0, eave_y, z),
		Vector3(x1, eave_y, z),
		Vector3(ridge_x, ridge_y, z),
	])
	_add_mesh(root, parent, node_name, vertices, PackedInt32Array([0, 1, 2]), color)

func _add_gable_end_wall_z(root: Node3D, parent: Node3D, node_name: String, x: float, z0: float, z1: float, eave_y: float, ridge_y: float, color: Color) -> void:
	var ridge_z := (z0 + z1) * 0.5
	var vertices := PackedVector3Array([
		Vector3(x, eave_y, z0),
		Vector3(x, eave_y, z1),
		Vector3(x, ridge_y, ridge_z),
	])
	_add_mesh(root, parent, node_name, vertices, PackedInt32Array([0, 1, 2]), color)

func _add_trim_z(root: Node3D, parent: Node3D, node_name: String, y: float, z: float, x0: float, x1: float, color: Color) -> void:
	_add_box(root, parent, node_name, Vector3((x0 + x1) * 0.5, y, z), Vector3(absf(x1 - x0), 3, 4), color, false)

func _add_room(root: Node3D, parent: Node3D, node_name: String, position: Vector3, size: Vector3, color: Color) -> void:
	var floor_mesh := _add_box(root, parent, node_name, position, size, color, true)
	floor_mesh.set_meta("plan_role", "finished_floor_surface")
	floor_mesh.set_meta("source_plan", "monster_house_plans_plan_50_622_user_canvas_reference")

func _route_cells_for_course(course_id: String) -> Array[Vector3i]:
	match course_id:
		"plan50_garage":
			return _route_from_points([Vector3i(-3, 0, -3), Vector3i(3, 0, -3), Vector3i(3, 0, 3), Vector3i(-3, 0, 3)])
		"plan50_bedroom_wing":
			return _route_from_points([Vector3i(-3, 0, -2), Vector3i(4, 0, -2), Vector3i(4, 0, 2), Vector3i(-3, 0, 2)])
		"plan50_bonus_storage":
			return _route_from_points([Vector3i(-3, 0, -2), Vector3i(3, 0, -2), Vector3i(3, 1, 2), Vector3i(-3, 1, 2)])
		"plan50_rear_porch":
			return _route_from_points([Vector3i(-5, 0, -2), Vector3i(5, 0, -2), Vector3i(5, 0, 2), Vector3i(-5, 0, 2)])
		"plan50_sandbox_yard":
			return _route_from_points([Vector3i(-3, 0, -2), Vector3i(3, 0, -2), Vector3i(4, 0, 1), Vector3i(1, 0, 3), Vector3i(-3, 0, 2)])
		_:
			return _route_from_points([Vector3i(-2, 0, -2), Vector3i(2, 0, -2), Vector3i(2, 0, 2), Vector3i(-2, 0, 2)])

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
		"owner_character": str(course["owner_character"]),
		"owner_zone": str(course["owner_zone"]),
		"scale_class": str(course["scale_class"]),
		"validation_camera": str(course["validation_camera"]),
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
		while cursor != target:
			guard += 1
			if guard > 1000:
				push_error("Route generation guard tripped.")
				break
			if cursor.x != target.x:
				cursor.x += 1 if target.x > cursor.x else -1
			elif cursor.z != target.z:
				cursor.z += 1 if target.z > cursor.z else -1
			elif cursor.y != target.y:
				cursor.y += 1 if target.y > cursor.y else -1
			if cells.is_empty() or cells[cells.size() - 1] != cursor:
				cells.append(cursor)
	cells = _rotate_route_start_to_straight(cells)
	return cells

func _tile_item_for_route_cell(cells: Array[Vector3i], index: int) -> int:
	var current := cells[index]
	var next := cells[(index + 1) % cells.size()]
	if next.y != current.y:
		return TrackGridRoadBuilder.TILE_RAMP
	var prev := cells[(index - 1 + cells.size()) % cells.size()]
	if prev.y != current.y:
		return TrackGridRoadBuilder.TILE_RAMP
	if index == 0:
		return TrackGridRoadBuilder.TILE_START
	return TrackGridRoadBuilder.TILE_CORNER if _is_horizontal_corner(prev, current, next) else TrackGridRoadBuilder.TILE_STRAIGHT

func _basis_for_route_cell(cells: Array[Vector3i], index: int, item: int) -> Basis:
	var current := cells[index]
	var next := cells[(index + 1) % cells.size()]
	var prev := cells[(index - 1 + cells.size()) % cells.size()]
	if item == TrackGridRoadBuilder.TILE_CORNER:
		var prev_dir := _horizontal_delta(current, prev)
		var next_dir := _horizontal_delta(current, next)
		if _right_of(prev_dir) == next_dir:
			return _basis_for_forward(prev_dir)
		if _right_of(next_dir) == prev_dir:
			return _basis_for_forward(next_dir)
		return _basis_for_forward(next_dir)
	if item == TrackGridRoadBuilder.TILE_RAMP:
		var target := next if next.y != current.y else prev
		return _basis_for_forward(_horizontal_delta(current, target))
	return _basis_for_forward(_horizontal_delta(current, next))

func _is_horizontal_corner(prev: Vector3i, current: Vector3i, next: Vector3i) -> bool:
	var a := _horizontal_delta(prev, current)
	var b := _horizontal_delta(current, next)
	return a != Vector3i.ZERO and b != Vector3i.ZERO and a != b

func _horizontal_delta(from_cell: Vector3i, to_cell: Vector3i) -> Vector3i:
	return Vector3i(to_cell.x - from_cell.x, 0, to_cell.z - from_cell.z)

func _right_of(direction: Vector3i) -> Vector3i:
	return Vector3i(direction.z, 0, -direction.x)

func _grid_origin(course: Dictionary) -> Vector3:
	return (course["placement"] as Vector3) - Vector3(CELL_SIZE.x * 0.5, CELL_SIZE.y * 0.5, CELL_SIZE.z * 0.5)

func _cell_center(course: Dictionary, cell: Vector3i) -> Vector3:
	return _grid_origin(course) + Vector3((float(cell.x) + 0.5) * CELL_SIZE.x, (float(cell.y) + 0.5) * CELL_SIZE.y, (float(cell.z) + 0.5) * CELL_SIZE.z)

func _route_points_for_cells(course: Dictionary, route_cells: Array[Vector3i]) -> Array[Vector3]:
	var points: Array[Vector3] = []
	for cell in route_cells:
		points.append(_cell_center(course, cell))
	return points

func _route_envelope_for_course(course: Dictionary) -> Dictionary:
	var center := course["placement"] as Vector3
	var size := Vector3(118, 24, 118)
	match str(course["id"]):
		"plan50_rear_porch":
			size = Vector3(190, 20, 100)
		"plan50_garage":
			size = Vector3(112, 20, 128)
		"plan50_bedroom_wing":
			size = Vector3(134, 22, 86)
		"plan50_sandbox_yard":
			size = Vector3(126, 20, 92)
	return {
		"min": center - size * 0.5,
		"max": center + size * 0.5,
		"owner_character": str(course["owner_character"]),
		"owner_zone": str(course["owner_zone"]),
		"scale_class": str(course["scale_class"]),
		"validation_camera": str(course["validation_camera"]),
		"route_clearance": "route_above_floor_inside_owner_zone_obstacle_and_chase_camera_clear",
	}

func _checkpoint_indices(route_size: int) -> Array[int]:
	var checkpoints: Array[int] = []
	for i in range(6):
		var index := clampi(int(round(float(i) * float(route_size) / 6.0)), 0, route_size - 1)
		if not checkpoints.has(index):
			checkpoints.append(index)
	return checkpoints

func _spawn_slot_data() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for row in range(4):
		for col in range(2):
			out.append({"route_index": 0, "lateral_offset": -2.75 if col == 0 else 2.75, "forward_offset": float(row) * 5.0, "y_offset": 0.8, "yaw_offset_degrees": 180.0})
	return out

func _basis_for_forward(direction: Vector3i) -> Basis:
	return Basis.IDENTITY if direction == Vector3i.ZERO else Basis(Vector3.UP, atan2(float(direction.x), float(direction.z)))

func _orientation_index(basis: Basis) -> int:
	var helper := GridMap.new()
	var index := helper.get_orthogonal_index_from_basis(basis)
	helper.free()
	return index

func _basis_to_array(basis: Basis) -> Array:
	return [[basis.x.x, basis.x.y, basis.x.z], [basis.y.x, basis.y.y, basis.y.z], [basis.z.x, basis.z.y, basis.z.z]]

func _rotate_route_start_to_straight(cells: Array[Vector3i]) -> Array[Vector3i]:
	for i in range(cells.size()):
		var current := cells[i]
		var prev := cells[(i - 1 + cells.size()) % cells.size()]
		var next := cells[(i + 1) % cells.size()]
		if prev.y == current.y and next.y == current.y and _horizontal_delta(current, prev) + _horizontal_delta(current, next) == Vector3i.ZERO:
			var rotated: Array[Vector3i] = []
			for offset in range(cells.size()):
				rotated.append(cells[(i + offset) % cells.size()])
			return rotated
	return cells

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

func _apply_sky_preset(definition: TrackDefinition, preset: String) -> void:
	definition.sky_preset_id = preset
	match preset:
		"noon_clear":
			definition.sky_weather = "clear"; definition.sky_top_color = Color(0.44, 0.72, 1.0); definition.sky_horizon_color = Color(0.78, 0.90, 1.0); definition.sky_cloud_amount = 0.16; definition.sky_light_energy = 2.45
		"party_evening":
			definition.sky_weather = "evening"; definition.sky_top_color = Color(0.38, 0.22, 0.58); definition.sky_horizon_color = Color(0.95, 0.48, 0.34); definition.sky_cloud_amount = 0.28; definition.sky_light_energy = 2.1
		"clear_afternoon":
			definition.sky_weather = "clear"; definition.sky_top_color = Color(0.46, 0.70, 0.96); definition.sky_horizon_color = Color(0.82, 0.92, 1.0); definition.sky_cloud_amount = 0.18; definition.sky_light_energy = 2.5
		"soft_morning":
			definition.sky_weather = "soft"; definition.sky_top_color = Color(0.72, 0.78, 0.95); definition.sky_horizon_color = Color(0.98, 0.86, 0.76); definition.sky_cloud_amount = 0.32; definition.sky_light_energy = 2.05
	definition.sky_cloud_speed = 0.014
	definition.sky_haze_amount = 0.10

func _add_wall_z(root: Node3D, parent: Node3D, node_name: String, z: float, x0: float, x1: float, color: Color, base_y := 0.0, height := 44.0) -> void:
	var center_x := (x0 + x1) * 0.5
	_add_box(root, parent, node_name, Vector3(center_x, base_y + height * 0.5, z), Vector3(absf(x1 - x0), height, 6), color, true)

func _add_wall_x(root: Node3D, parent: Node3D, node_name: String, x: float, z0: float, z1: float, color: Color, base_y := 0.0, height := 44.0) -> void:
	var center_z := (z0 + z1) * 0.5
	_add_box(root, parent, node_name, Vector3(x, base_y + height * 0.5, center_z), Vector3(6, height, absf(z1 - z0)), color, true)

func _add_roof_plane_z(root: Node3D, parent: Node3D, node_name: String, z0: float, z1: float, x0: float, x1: float, y0: float, y1: float, color: Color) -> MeshInstance3D:
	var vertices := PackedVector3Array([Vector3(x0, y0, z0), Vector3(x1, y0, z0), Vector3(x1, y1, z1), Vector3(x0, y1, z1)])
	return _add_mesh(root, parent, node_name, vertices, PackedInt32Array([0, 1, 2, 0, 2, 3]), color)

func _add_window(root: Node3D, parent: Node3D, node_name: String, position: Vector3, size: Vector3) -> void:
	_add_box(root, parent, node_name, position, size, Color(0.55, 0.77, 0.92, 0.48), false)

func _add_framed_window_z(root: Node3D, parent: Node3D, node_name: String, position: Vector3, size: Vector3) -> void:
	var glass := Color(0.10, 0.14, 0.16, 0.58)
	var frame := Color(0.03, 0.035, 0.035)
	_add_box(root, parent, "%sGlass" % node_name, position, size, glass, false)
	_add_box(root, parent, "%sTopFrame" % node_name, position + Vector3(0, size.y * 0.5 + 1.5, 0.9), Vector3(size.x + 4, 3, 3), frame, false)
	_add_box(root, parent, "%sBottomFrame" % node_name, position + Vector3(0, -size.y * 0.5 - 1.5, 0.9), Vector3(size.x + 4, 3, 3), frame, false)
	_add_box(root, parent, "%sLeftJamb" % node_name, position + Vector3(-size.x * 0.5 - 1.5, 0, 0.9), Vector3(3, size.y + 4, 3), frame, false)
	_add_box(root, parent, "%sRightJamb" % node_name, position + Vector3(size.x * 0.5 + 1.5, 0, 0.9), Vector3(3, size.y + 4, 3), frame, false)
	_add_box(root, parent, "%sCenterMullion" % node_name, position + Vector3(0, 0, 1.0), Vector3(2.2, size.y + 1, 3), frame, false)

func _add_framed_window_x(root: Node3D, parent: Node3D, node_name: String, position: Vector3, size: Vector3) -> void:
	var glass := Color(0.10, 0.14, 0.16, 0.58)
	var frame := Color(0.03, 0.035, 0.035)
	_add_box(root, parent, "%sGlass" % node_name, position, size, glass, false)
	_add_box(root, parent, "%sTopFrame" % node_name, position + Vector3(-0.9, size.y * 0.5 + 1.5, 0), Vector3(3, 3, size.z + 4), frame, false)
	_add_box(root, parent, "%sBottomFrame" % node_name, position + Vector3(-0.9, -size.y * 0.5 - 1.5, 0), Vector3(3, 3, size.z + 4), frame, false)
	_add_box(root, parent, "%sFrontJamb" % node_name, position + Vector3(-0.9, 0, size.z * 0.5 + 1.5), Vector3(3, size.y + 4, 3), frame, false)
	_add_box(root, parent, "%sRearJamb" % node_name, position + Vector3(-0.9, 0, -size.z * 0.5 - 1.5), Vector3(3, size.y + 4, 3), frame, false)
	_add_box(root, parent, "%sCenterMullion" % node_name, position + Vector3(-1.0, 0, 0), Vector3(3, size.y + 1, 2.2), frame, false)

func _add_garage_door_x(root: Node3D, parent: Node3D, node_name: String, position: Vector3, size: Vector3) -> void:
	var panel := Color(0.82, 0.82, 0.78)
	var frame := Color(0.04, 0.045, 0.045)
	_add_box(root, parent, "%sPanel" % node_name, position, size, panel, false)
	_add_box(root, parent, "%sHeaderFrame" % node_name, position + Vector3(-1.0, size.y * 0.5 + 1.5, 0), Vector3(4, 3, size.z + 4), frame, false)
	_add_box(root, parent, "%sSillShadow" % node_name, position + Vector3(-1.0, -size.y * 0.5 - 1.0, 0), Vector3(4, 2, size.z + 4), frame, false)
	_add_box(root, parent, "%sFrontJambFrame" % node_name, position + Vector3(-1.0, 0, size.z * 0.5 + 1.5), Vector3(4, size.y + 4, 3), frame, false)
	_add_box(root, parent, "%sRearJambFrame" % node_name, position + Vector3(-1.0, 0, -size.z * 0.5 - 1.5), Vector3(4, size.y + 4, 3), frame, false)

func _add_garage_door_z(root: Node3D, parent: Node3D, node_name: String, position: Vector3, size: Vector3) -> void:
	var panel := Color(0.82, 0.82, 0.78)
	var frame := Color(0.04, 0.045, 0.045)
	_add_box(root, parent, "%sPanel" % node_name, position, size, panel, false)
	_add_box(root, parent, "%sHeaderFrame" % node_name, position + Vector3(0, size.y * 0.5 + 1.5, 1.0), Vector3(size.x + 4, 3, 4), frame, false)
	_add_box(root, parent, "%sSillShadow" % node_name, position + Vector3(0, -size.y * 0.5 - 1.0, 1.0), Vector3(size.x + 4, 2, 4), frame, false)
	_add_box(root, parent, "%sLeftJambFrame" % node_name, position + Vector3(-size.x * 0.5 - 1.5, 0, 1.0), Vector3(3, size.y + 4, 4), frame, false)
	_add_box(root, parent, "%sRightJambFrame" % node_name, position + Vector3(size.x * 0.5 + 1.5, 0, 1.0), Vector3(3, size.y + 4, 4), frame, false)

func _add_camera(root: Node3D, parent: Node3D, node_name: String, position: Vector3, rotation_degrees: Vector3, fov := 60.0) -> void:
	var camera := Camera3D.new()
	camera.name = node_name
	camera.position = position
	camera.rotation_degrees = rotation_degrees
	camera.fov = fov
	parent.add_child(camera)
	camera.owner = root

func _add_label(root: Node3D, parent: Node3D, node_name: String, text: String, position: Vector3, size: int) -> void:
	var label := Label3D.new()
	label.name = node_name
	label.text = text
	label.position = position
	label.font_size = size
	label.pixel_size = 0.22
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	parent.add_child(label)
	label.owner = root

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
	_apply_generated_provenance(mesh, parent, node_name, position, size)
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
	_apply_generated_provenance(mesh_instance, parent, node_name, _mesh_center(vertices), _mesh_size(vertices))
	return mesh_instance

func _apply_generated_provenance(node: Node, parent: Node, node_name: String, position: Vector3, size: Vector3, visible_class := "generated_visible_geometry", role_override := "") -> void:
	var assembly := str(parent.name)
	var role := role_override if role_override != "" else _role_for_generated_node(assembly, node_name)
	node.set_meta("node_path", "%s/%s" % [assembly, node_name])
	node.set_meta("visible_class", visible_class)
	node.set_meta("owner_volume", _owner_volume_for_generated_node(assembly, node_name))
	node.set_meta("assembly", assembly)
	node.set_meta("role", role)
	node.set_meta("source_of_truth", _source_of_truth_for_assembly(assembly))
	node.set_meta("why_exists", _why_exists_for_generated_node(assembly, node_name, role))
	node.set_meta("support_target", _support_target_for_assembly(assembly))
	node.set_meta("contact_face", _contact_face_for_assembly(assembly))
	node.set_meta("span_axis", _span_axis_for_size(size))
	node.set_meta("start_anchor", _anchor_for_position(position, size, false))
	node.set_meta("end_anchor", _anchor_for_position(position, size, true))
	node.set_meta("allowed_intersections", _allowed_intersections_for_assembly(assembly, role))
	node.set_meta("forbidden_intersections", ["unowned_geometry", "route_camera_swept_volume", "unplanned_shell_overlap"])
	node.set_meta("deletion_rule", "delete only through GenerateHomePlan50622Map.gd when owner assembly or source contract changes")
	node.set_meta("validation_gate", _validation_gate_for_assembly(assembly))
	node.set_meta("validation_camera", _validation_camera_for_assembly(assembly))

func _role_for_generated_node(assembly: String, node_name: String) -> String:
	var lowered := node_name.to_lower()
	if lowered.contains("floor") or ["MainFloor", "AtticStorage", "Basement", "PatioPool", "Site", "YardZones"].has(assembly):
		return "floor_or_site_surface"
	if lowered.contains("wall") or lowered.contains("siding"):
		return "wall_or_closure"
	if lowered.contains("roof") or lowered.contains("gable"):
		return "roof_or_gable_closure"
	if lowered.contains("fascia") or lowered.contains("gutter") or lowered.contains("trim") or lowered.contains("belt"):
		return "trim"
	if lowered.contains("window") or lowered.contains("door"):
		return "opening_assembly"
	if lowered.contains("column") or lowered.contains("beam") or lowered.contains("rail"):
		return "support_or_guard"
	if lowered.contains("route") or lowered.contains("audit"):
		return "route_infrastructure"
	if ["Foundation", "ExteriorShell"].has(assembly):
		return "shell_structure"
	return "room_furnishing_or_landmark"

func _owner_volume_for_generated_node(assembly: String, node_name: String) -> String:
	if assembly.ends_with("RoutePreview"):
		return assembly.replace("RoutePreview", "")
	return "%s.%s" % [assembly, node_name]

func _source_of_truth_for_assembly(assembly: String) -> String:
	match assembly:
		"ExteriorShell", "Roof", "Foundation", "Openings":
			return "res://docs/concepts/home_plan50_622_v1/floor_plan_contract.md"
		"CourseRoutes":
			return "home_plan50_622_v1 mode route_envelope metadata"
		"YardZones":
			return CHARACTER_MAPPING_PATH
		_:
			return "res://docs/concepts/home_plan50_622_v1/floor_plan_contract.md"

func _why_exists_for_generated_node(assembly: String, node_name: String, role: String) -> String:
	return "%s generated as %s for %s in the home_plan50_622_v1 production scaffold." % [node_name, role, assembly]

func _support_target_for_assembly(assembly: String) -> String:
	match assembly:
		"Site":
			return "world_grade"
		"Foundation":
			return "site_grade_and_basement_contract"
		"ExteriorShell", "Openings":
			return "Foundation/MainFloor/AtticStorage shell datums"
		"Roof":
			return "ExteriorShell wall and gable support lines"
		"VerticalConnectors":
			return "MainFloor/AtticStorage/Basement landing datums"
		"CourseRoutes":
			return "mode route envelope"
		"YardZones":
			return "site grade, patio threshold, and story-bible outdoor owner zones"
		_:
			return "%s finished floor or parent room volume" % assembly

func _contact_face_for_assembly(assembly: String) -> String:
	match assembly:
		"Roof":
			return "lower eave/ridge/valley support edges"
		"Openings":
			return "exterior wall opening plane"
		"ExteriorShell":
			return "foundation top and floor perimeter faces"
		_:
			return "bottom face"

func _allowed_intersections_for_assembly(assembly: String, role: String) -> Array[String]:
	if role == "opening_assembly":
		return ["owning_wall_opening", "jamb_header_sill_returns"]
	if role == "trim":
		return ["owning_wall_or_roof_edge", "adjacent_trim_return"]
	if assembly == "CourseRoutes":
		return ["validation_camera_volume"]
	return ["support_target_contact", "declared_parent_volume"]

func _validation_gate_for_assembly(assembly: String) -> String:
	match assembly:
		"ExteriorShell", "Roof", "Foundation", "Openings":
			return "home_plan50_622_shell_provenance_and_envelope_gate"
		"CourseRoutes":
			return "route_envelope_and_camera_clearance_gate"
		"YardZones":
			return "home_plan50_622_yard_zone_owner_and_clearance_gate"
		_:
			return "home_plan50_622_generated_node_provenance_gate"

func _validation_camera_for_assembly(assembly: String) -> String:
	match assembly:
		"Site":
			return "FrontStreetReviewCamera"
		"ExteriorShell", "Foundation", "Openings":
			return "FrontStreetReviewCamera"
		"Roof":
			return "RooflineReviewCamera"
		"MainFloor":
			return "MainFloorPlanCamera"
		"AtticStorage":
			return "AtticStoragePlanCamera"
		"PatioPool":
			return "PatioPoolCamera"
		"YardZones":
			return "MokoGardenPatioCamera"
		"CourseRoutes":
			return "mode_start_player_camera"
		_:
			return "MainFloorPlanCamera"

func _span_axis_for_size(size: Vector3) -> String:
	if size.x >= size.y and size.x >= size.z:
		return "x"
	if size.z >= size.x and size.z >= size.y:
		return "z"
	return "y"

func _anchor_for_position(position: Vector3, size: Vector3, positive: bool) -> String:
	var axis := _span_axis_for_size(size)
	var half := 0.5 * (size.x if axis == "x" else size.y if axis == "y" else size.z)
	var value := (position.x if axis == "x" else position.y if axis == "y" else position.z) + (half if positive else -half)
	return "%s=%.2f" % [axis, value]

func _mesh_center(vertices: PackedVector3Array) -> Vector3:
	if vertices.is_empty():
		return Vector3.ZERO
	var min_v := vertices[0]
	var max_v := vertices[0]
	for vertex in vertices:
		min_v = min_v.min(vertex)
		max_v = max_v.max(vertex)
	return (min_v + max_v) * 0.5

func _mesh_size(vertices: PackedVector3Array) -> Vector3:
	if vertices.is_empty():
		return Vector3.ONE
	var min_v := vertices[0]
	var max_v := vertices[0]
	for vertex in vertices:
		min_v = min_v.min(vertex)
		max_v = max_v.max(vertex)
	return max_v - min_v

func _set_owner_recursive(node: Node, owner: Node) -> void:
	for child in node.get_children():
		child.owner = owner
		_set_owner_recursive(child, owner)
