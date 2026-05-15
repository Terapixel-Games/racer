@tool
extends SceneTree

const TrackDefinition = preload("res://scripts/track/TrackDefinition.gd")
const TrackGridRoadBuilder = preload("res://scripts/track/TrackGridRoadBuilder.gd")
const TrackMapDefinition = preload("res://scripts/track/TrackMapDefinition.gd")
const TrackMetadataExporter = preload("res://scripts/track/TrackMetadataExporter.gd")
const TrackRuntimeScene = preload("res://scripts/track/TrackRuntimeScene.gd")
const TrackSourceRules = preload("res://scripts/track/TrackSourceRules.gd")

const MAP_ID := "home_estate_v1"
const MAP_DISPLAY_NAME := "Modern Farmhouse Estate"
const VERSION := "home_estate_floorplan_v1_2026_05_13"
const BASE_DIR := "res://assets/gameplay/tracks/home_estate_v1"
const MODE_DIR := "res://assets/gameplay/tracks/home_estate_v1/modes"
const MAP_SCENE_PATH := "res://assets/gameplay/tracks/home_estate_v1/home_estate_v1_map.tscn"
const MAP_DEFINITION_PATH := "res://assets/gameplay/tracks/home_estate_v1/home_estate_v1_track_map.tres"
const TRACK_PACKAGES_PATH := "res://assets/gameplay/tracks/track_packages.json"
const VISIBLE_SHELL_ASSET_PATH := "res://assets/gameplay/tracks/home_estate_v1/meshes/modern_farmhouse_shell.glb"
const GRID_LIBRARY := TrackGridRoadBuilder.DEFAULT_MESH_LIBRARY_PATH
const ROAD_TEXTURE := "res://assets/gameplay/materials/plastic/glossy_plastic_albedo.png"

const UNITS_PER_FOOT := 4.0
const CELL_SIZE := Vector3(16.0, 4.0, 16.0)
const ROAD_WIDTH := 16.0
const ROAD_FLOOR_CLEARANCE := 0.55
const FLOOR_Y := -1.1
const OUT_OF_BOUNDS_Y := -36.0
const MAIN_FLOOR_Y := 0.05
const UPPER_FLOOR_Y := 46.05
const BASEMENT_FLOOR_Y := -42.0

const PLAN_CONTRACT := {
	"source": "user_provided_estate_plan_three_sheets",
	"map_id": MAP_ID,
	"units_per_floor_plan_foot": UNITS_PER_FOOT,
	"orientation": "front/street +Z, rear patio/backyard -Z",
	"main_floor_dimensions_ft": Vector2(72.0, 69.1667),
	"main_floor_area_sqft": 1800,
	"upper_floor_area_sqft": 1086,
	"program": {
		"main": ["three_car_garage", "mud_office_service", "kitchen_dining", "great_room", "master_suite", "covered_porch_front", "covered_porch_rear", "rear_patio_pool_edge"],
		"upper": ["upper_loft", "upper_bedrooms", "upper_bath_laundry", "future_bonus_room"],
		"basement": ["basement_shell", "unexcavated_zones"]
	},
	"style_reference": "Monster House Plans Plan 38-526 modern farmhouse reference: two-story, four-bedroom, three-car garage, broad porches, gabled roof hierarchy.",
	"production_policy": "Generator-driven modern farmhouse baseline. Visible primitives are named architectural/furnishing stand-ins only until replaced by Kenney/Meshy/toybox; no plan labels or bare floor-plan diagram markers may ship.",
}

const COURSES := [
	{"id": "estate_kitchen", "display_name": "Estate Kitchen", "placement": Vector3(-54, MAIN_FLOOR_Y + ROAD_FLOOR_CLEARANCE, 20), "sky": "noon_clear", "color": Color(0.92, 0.78, 0.55)},
	{"id": "estate_great_room", "display_name": "Estate Great Room", "placement": Vector3(50, MAIN_FLOOR_Y + ROAD_FLOOR_CLEARANCE, 28), "sky": "soft_morning", "color": Color(0.76, 0.62, 0.55)},
	{"id": "estate_garage", "display_name": "Estate Garage", "placement": Vector3(-102, MAIN_FLOOR_Y + ROAD_FLOOR_CLEARANCE, -66), "sky": "clear_afternoon", "color": Color(0.58, 0.58, 0.54)},
	{"id": "estate_master_suite", "display_name": "Estate Master Suite", "placement": Vector3(118, MAIN_FLOOR_Y + ROAD_FLOOR_CLEARANCE, 34), "sky": "soft_morning", "color": Color(0.62, 0.56, 0.68)},
	{"id": "estate_upper_loft", "display_name": "Estate Upper Loft", "placement": Vector3(-24, UPPER_FLOOR_Y + ROAD_FLOOR_CLEARANCE, 0), "sky": "party_evening", "color": Color(0.58, 0.50, 0.66)},
	{"id": "estate_patio", "display_name": "Estate Patio", "placement": Vector3(54, MAIN_FLOOR_Y + ROAD_FLOOR_CLEARANCE, -158), "sky": "clear_afternoon", "color": Color(0.64, 0.62, 0.56)},
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
	root.name = "HomeEstateV1Map"
	root.set_meta("floor_plan_contract", PLAN_CONTRACT)
	for holder_name in ["Site", "Foundation", "ExteriorShell", "Roof", "Openings", "MainFloor", "UpperFloor", "Basement", "PatioPool", "VerticalConnectors", "CourseRoutes", "ValidationCameras", "ConceptReference"]:
		var holder := Node3D.new()
		holder.name = holder_name
		root.add_child(holder)
		holder.owner = root
	_add_site(root)
	_add_foundation(root)
	_add_main_floor(root)
	_add_upper_floor(root)
	_add_basement(root)
	_add_patio_pool(root)
	_add_exterior_shell(root)
	_add_roof(root)
	_add_vertical_connectors(root)
	_add_course_route_markers(root)
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
	root.name = "%sHomeEstateTrack" % course_id.to_pascal_case()
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
	map.default_mode_id = "estate_kitchen"
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
		"default_mode_id": "estate_kitchen",
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
	_add_box(root, site, "EstateLotGround", Vector3(0, -1.2, -20), Vector3(420, 1, 420), Color(0.42, 0.54, 0.34), true)
	_add_box(root, site, "StreetEdge", Vector3(0, -0.6, 168), Vector3(420, 1, 28), Color(0.20, 0.22, 0.22), true)
	_add_box(root, site, "FrontWalk", Vector3(-20, -0.35, 130), Vector3(42, 1, 72), Color(0.68, 0.66, 0.60), true)
	_add_box(root, site, "DrivewayThreeCarApron", Vector3(-116, -0.35, 112), Vector3(98, 1, 92), Color(0.48, 0.48, 0.45), true)

func _add_foundation(root: Node3D) -> void:
	var foundation := root.get_node("Foundation") as Node3D
	_add_box(root, foundation, "MainFoundation", Vector3(0, 1.5, 0), Vector3(288, 3, 276), Color(0.42, 0.39, 0.34), false)
	_add_box(root, foundation, "BasementFoundationWall", Vector3(0, -22, 0), Vector3(292, 40, 280), Color(0.35, 0.35, 0.33), false)

func _add_main_floor(root: Node3D) -> void:
	var floor := root.get_node("MainFloor") as Node3D
	floor.set_meta("plan_role", "main-floor rooms from user estate plan")
	_add_room(root, floor, "ThreeCarGarage", Vector3(-104, MAIN_FLOOR_Y, -60), Vector3(96, 2, 122), Color(0.60, 0.60, 0.56))
	_add_room(root, floor, "MudOfficeService", Vector3(-116, MAIN_FLOOR_Y, 68), Vector3(72, 2, 64), Color(0.72, 0.67, 0.58))
	_add_room(root, floor, "KitchenDining", Vector3(-44, MAIN_FLOOR_Y, 40), Vector3(86, 2, 84), Color(0.92, 0.78, 0.55))
	_add_room(root, floor, "GreatRoom", Vector3(52, MAIN_FLOOR_Y, 28), Vector3(84, 2, 92), Color(0.76, 0.62, 0.55))
	_add_room(root, floor, "MasterSuite", Vector3(128, MAIN_FLOOR_Y, 34), Vector3(62, 2, 96), Color(0.62, 0.56, 0.68))
	_add_room(root, floor, "FrontCoveredPorch", Vector3(22, MAIN_FLOOR_Y, 126), Vector3(104, 2, 40), Color(0.66, 0.62, 0.55))
	_add_room(root, floor, "RearCoveredPorch", Vector3(52, MAIN_FLOOR_Y, -110), Vector3(104, 2, 40), Color(0.66, 0.62, 0.55))
	_add_main_floor_partitions(root, floor)
	_add_main_floor_furnishings(root, floor)

func _add_upper_floor(root: Node3D) -> void:
	var upper := root.get_node("UpperFloor") as Node3D
	upper.set_meta("plan_role", "upper bedrooms, loft, laundry, and future bonus from user estate plan")
	_add_room(root, upper, "UpperLoft", Vector3(-34, UPPER_FLOOR_Y, 0), Vector3(66, 2, 72), Color(0.58, 0.50, 0.66))
	_add_room(root, upper, "UpperBedroomWest", Vector3(-78, UPPER_FLOOR_Y, 48), Vector3(52, 2, 52), Color(0.60, 0.56, 0.70))
	_add_room(root, upper, "UpperBedroomEast", Vector3(36, UPPER_FLOOR_Y, 48), Vector3(58, 2, 56), Color(0.60, 0.56, 0.70))
	_add_room(root, upper, "UpperBedroomRear", Vector3(12, UPPER_FLOOR_Y, -64), Vector3(56, 2, 56), Color(0.60, 0.56, 0.70))
	_add_room(root, upper, "UpperBathLaundry", Vector3(-96, UPPER_FLOOR_Y, -24), Vector3(44, 2, 54), Color(0.68, 0.72, 0.72))
	_add_room(root, upper, "FutureBonusRoom", Vector3(-104, UPPER_FLOOR_Y, -104), Vector3(48, 2, 80), Color(0.64, 0.60, 0.55))
	_add_upper_floor_partitions(root, upper)
	_add_upper_floor_furnishings(root, upper)

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

func _add_exterior_shell(root: Node3D) -> void:
	var shell := root.get_node("ExteriorShell") as Node3D
	shell.set_meta("plan_role", "single owner of exterior walls and openings for home_estate_v1")
	shell.set_meta("style_contract", "modern farmhouse: white siding, black framed windows, gabled roof hierarchy, covered porches, three garage doors")
	if _add_blender_visible_shell(root, shell):
		return
	var siding := Color(0.88, 0.86, 0.78)
	var stone := Color(0.50, 0.48, 0.42)
	_add_box(root, shell, "MainHouseLowerFrontSiding", Vector3(28, 24, 140), Vector3(174, 48, 6), siding, true)
	_add_box(root, shell, "MainHouseLowerRearSiding", Vector3(28, 24, -140), Vector3(174, 48, 6), siding.darkened(0.02), true)
	_add_box(root, shell, "MainHouseLeftSiding", Vector3(-58, 24, 0), Vector3(6, 48, 278), siding.darkened(0.03), true)
	_add_box(root, shell, "MainHouseRightSiding", Vector3(144, 24, 0), Vector3(6, 48, 278), siding.darkened(0.03), true)
	_add_box(root, shell, "MainHouseUpperFrontSiding", Vector3(18, 62, 138), Vector3(132, 38, 6), siding.lightened(0.03), true)
	_add_box(root, shell, "GarageWingFrontSiding", Vector3(-104, 22, 140), Vector3(104, 44, 6), siding.darkened(0.02), true)
	_add_box(root, shell, "GarageWingRearSiding", Vector3(-104, 22, -132), Vector3(104, 44, 6), siding.darkened(0.04), true)
	_add_box(root, shell, "GarageWingWestSiding", Vector3(-156, 22, 4), Vector3(6, 44, 272), siding.darkened(0.06), true)
	_add_box(root, shell, "GarageHousePartyWall", Vector3(-56, 22, -52), Vector3(6, 44, 164), siding.darkened(0.07), true)
	_add_box(root, shell, "MasterWingRightSiding", Vector3(150, 24, 58), Vector3(6, 48, 122), siding.darkened(0.04), true)
	_add_box(root, shell, "StonePlinthFront", Vector3(0, 4, 143), Vector3(310, 8, 8), stone, false)
	_add_box(root, shell, "StonePlinthRear", Vector3(12, 4, -143), Vector3(286, 8, 8), stone, false)
	_add_farmhouse_exterior_details(root, shell, root.get_node("Openings") as Node3D)

func _add_roof(root: Node3D) -> void:
	var roof := root.get_node("Roof") as Node3D
	roof.set_meta("plan_role", "modern farmhouse gabled roof hierarchy; no attic route in this pass")
	if ResourceLoader.exists(VISIBLE_SHELL_ASSET_PATH):
		roof.set_meta("visible_roof_source", VISIBLE_SHELL_ASSET_PATH)
		return
	var roof_color := Color(0.18, 0.19, 0.18)
	_add_gable_roof_x(root, roof, "MainHouse", -58, 132, -144, 146, 76, 108, roof_color)
	_add_gable_roof_x(root, roof, "GarageCrossWing", -160, -48, -134, 146, 50, 78, roof_color.darkened(0.04))
	_add_gable_roof_x(root, roof, "MasterSideWing", 92, 154, -20, 142, 56, 84, roof_color.lightened(0.02))
	_add_gable_roof_x(root, roof, "FrontPorch", -28, 44, 104, 156, 42, 58, roof_color.lightened(0.05))
	_add_gable_roof_x(root, roof, "RearPorch", -28, 112, -156, -98, 42, 58, roof_color.lightened(0.05))
	_add_gable_end_wall_x(root, roof, "MainFrontGableWall", -58, 132, 146.5, 76, 108, Color(0.88, 0.86, 0.78))
	_add_gable_end_wall_x(root, roof, "GarageFrontGableWall", -160, -48, 146.5, 50, 78, Color(0.88, 0.86, 0.78).darkened(0.02))
	_add_gable_end_wall_x(root, roof, "FrontPorchStreetGableWall", -28, 44, 156.5, 42, 58, Color(0.88, 0.86, 0.78).lightened(0.03))
	_add_gable_end_wall_x(root, roof, "FrontPorchTieInGableWall", -28, 44, 104.5, 42, 58, Color(0.88, 0.86, 0.78).darkened(0.03))
	_add_box(root, roof, "BlackMetalGutterFront", Vector3(16, 74, 148), Vector3(258, 3, 3), Color(0.06, 0.07, 0.07), false)
	_add_box(root, roof, "BlackMetalGutterGarageFront", Vector3(-104, 48, 148), Vector3(116, 3, 3), Color(0.06, 0.07, 0.07), false)

func _add_vertical_connectors(root: Node3D) -> void:
	var vc := root.get_node("VerticalConnectors") as Node3D
	vc.set_meta("plan_role", "stair stack from main great-room hall to upper loft and basement")
	_add_box(root, vc, "MainToUpperStairRun", Vector3(-2, 24, 42), Vector3(16, 48, 56), Color(0.56, 0.34, 0.20), false, 0, Vector3(-28, 0, 0))
	_add_box(root, vc, "MainToBasementStairRun", Vector3(-14, -20, 36), Vector3(16, 42, 52), Color(0.42, 0.28, 0.18), false, 0, Vector3(28, 0, 0))
	_add_box(root, vc, "UpperLandingGuardRail", Vector3(-2, 56, 16), Vector3(60, 8, 4), Color(0.35, 0.22, 0.14), false)

func _add_course_route_markers(root: Node3D) -> void:
	var holder := root.get_node("CourseRoutes") as Node3D
	for course in COURSES:
		var course_id := str(course["id"])
		var route_holder := Node3D.new()
		route_holder.name = "%sRoutePreview" % course_id.to_pascal_case()
		holder.add_child(route_holder)
		route_holder.owner = root
		var envelope := _route_envelope_for_course(course)
		_add_box(root, route_holder, "RouteContainmentAuditBox", (envelope["min"] + envelope["max"]) * 0.5, envelope["max"] - envelope["min"], Color(0.2, 0.8, 1.0, 0.12), false)

func _add_validation_cameras(root: Node3D) -> void:
	var cameras := root.get_node("ValidationCameras") as Node3D
	_add_camera(root, cameras, "MainFloorPlanCamera", Vector3(0, 210, 220), Vector3(-62, 0, 0), 70)
	_add_camera(root, cameras, "UpperFloorPlanCamera", Vector3(0, 190, 120), Vector3(-62, 0, 0), 70)
	_add_camera(root, cameras, "PatioPoolCamera", Vector3(120, 70, -245), Vector3(-18, 28, 0), 58)
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
	instance.set_meta("authoring_source", "scripts/tools/create_home_estate_shell_blender.py")
	instance.set_meta("reference_source", "docs/concepts/home_estate_v1/reference_frames/modern_farmhouse_38_526/reference_notes.md")
	instance.set_meta("collision_policy", "visual shell only; generator-owned route and boundary collision remains separate")
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
	_add_box(root, floor, "KitchenIsland", Vector3(-44, 6, 35), Vector3(18, 12, 42), wood, false)
	_add_box(root, floor, "KitchenCabinetRunBack", Vector3(-50, 7, 0), Vector3(58, 14, 10), Color(0.74, 0.70, 0.62), false)
	_add_box(root, floor, "KitchenRangeHood", Vector3(-34, 19, -4), Vector3(18, 16, 6), Color(0.34, 0.36, 0.35), false)
	_add_box(root, floor, "DiningTable", Vector3(-28, 5, 82), Vector3(34, 8, 16), wood.lightened(0.08), false)
	_add_box(root, floor, "GreatRoomFireplace", Vector3(96, 12, 34), Vector3(8, 24, 28), Color(0.32, 0.24, 0.20), false)
	_add_box(root, floor, "GreatRoomSofa", Vector3(48, 6, 52), Vector3(42, 12, 14), Color(0.38, 0.48, 0.55), false)
	_add_box(root, floor, "GreatRoomCoffeeTable", Vector3(48, 4, 26), Vector3(24, 6, 12), wood, false)
	_add_box(root, floor, "MasterBed", Vector3(126, 6, 42), Vector3(34, 12, 48), Color(0.58, 0.62, 0.76), false)
	_add_box(root, floor, "MasterClosetBuiltIns", Vector3(146, 8, 76), Vector3(8, 16, 36), Color(0.72, 0.67, 0.58), false)
	_add_box(root, floor, "GarageCarBayMarkerLeft", Vector3(-132, 1.4, -60), Vector3(22, 0.5, 98), Color(0.28, 0.30, 0.31), false)
	_add_box(root, floor, "GarageCarBayMarkerCenter", Vector3(-104, 1.4, -60), Vector3(22, 0.5, 98), Color(0.28, 0.30, 0.31), false)
	_add_box(root, floor, "GarageCarBayMarkerRight", Vector3(-76, 1.4, -60), Vector3(22, 0.5, 98), Color(0.28, 0.30, 0.31), false)
	_add_box(root, floor, "GarageWorkbench", Vector3(-58, 7, -110), Vector3(10, 14, 44), wood.darkened(0.08), false)

func _add_upper_floor_partitions(root: Node3D, upper: Node3D) -> void:
	var wall := Color(0.78, 0.75, 0.68)
	_add_wall_z(root, upper, "UpperHallBedroomRearWall", -36, -120, 50, wall, UPPER_FLOOR_Y, 30)
	_add_wall_x(root, upper, "UpperLoftWestWall", -66, -36, 68, wall, UPPER_FLOOR_Y, 30)
	_add_wall_x(root, upper, "UpperLoftEastWall", 2, -36, 68, wall, UPPER_FLOOR_Y, 30)
	_add_wall_z(root, upper, "UpperFrontBedroomWall", 28, -106, 70, wall, UPPER_FLOOR_Y, 30)
	_add_wall_x(root, upper, "UpperBathLaundryPartition", -78, -48, 4, wall.darkened(0.05), UPPER_FLOOR_Y, 28)
	_add_box(root, upper, "UpperStairOpeningGuardRailNorth", Vector3(-8, UPPER_FLOOR_Y + 8, 18), Vector3(54, 8, 4), Color(0.34, 0.22, 0.14), false)
	_add_box(root, upper, "UpperStairOpeningGuardRailSouth", Vector3(-8, UPPER_FLOOR_Y + 8, -10), Vector3(54, 8, 4), Color(0.34, 0.22, 0.14), false)

func _add_upper_floor_furnishings(root: Node3D, upper: Node3D) -> void:
	var wood := Color(0.42, 0.27, 0.16)
	_add_box(root, upper, "UpperLoftSofa", Vector3(-34, UPPER_FLOOR_Y + 6, 10), Vector3(34, 12, 14), Color(0.48, 0.42, 0.56), false)
	_add_box(root, upper, "UpperLoftBuiltInShelves", Vector3(-62, UPPER_FLOOR_Y + 10, 0), Vector3(7, 20, 50), wood, false)
	_add_box(root, upper, "UpperBedroomWestBed", Vector3(-78, UPPER_FLOOR_Y + 6, 50), Vector3(28, 12, 34), Color(0.58, 0.62, 0.76), false)
	_add_box(root, upper, "UpperBedroomEastBed", Vector3(36, UPPER_FLOOR_Y + 6, 50), Vector3(28, 12, 34), Color(0.58, 0.62, 0.76), false)
	_add_box(root, upper, "UpperBedroomRearBed", Vector3(12, UPPER_FLOOR_Y + 6, -64), Vector3(28, 12, 34), Color(0.58, 0.62, 0.76), false)
	_add_box(root, upper, "FutureBonusStorageTrunks", Vector3(-104, UPPER_FLOOR_Y + 6, -104), Vector3(34, 12, 18), wood.darkened(0.1), false)

func _add_farmhouse_exterior_details(root: Node3D, shell: Node3D, openings: Node3D) -> void:
	_add_box(root, openings, "FrontDoorBlackPanel", Vector3(-6, 17, 141.5), Vector3(18, 30, 2.5), Color(0.06, 0.07, 0.07), false)
	_add_window(root, openings, "GreatRoomWindowWall", Vector3(52, 24, 139), Vector3(66, 26, 1.0))
	_add_window(root, openings, "KitchenFrontWindowPair", Vector3(-54, 23, 139), Vector3(34, 22, 1.0))
	_add_window(root, openings, "UpperFrontBlackFrameWindow", Vector3(18, 66, 141), Vector3(32, 24, 1.0))
	_add_window(root, openings, "MasterSuiteSideWindow", Vector3(145, 22, 38), Vector3(1.0, 22, 34))
	_add_window(root, openings, "GarageRearSeatingDoor", Vector3(-104, 18, -139), Vector3(42, 30, 1.0))
	var garage_suffixes := ["A", "B", "C"]
	for i in range(3):
		var x := -132.0 + float(i) * 28.0
		var suffix := str(garage_suffixes[i])
		_add_box(root, openings, "GarageDoorSingle%s" % suffix, Vector3(x, 17, 141.5), Vector3(22, 28, 2.5), Color(0.82, 0.82, 0.78), false)
		_add_box(root, openings, "GarageDoorSingle%sBlackTrim" % suffix, Vector3(x, 31, 143), Vector3(24, 3, 3), Color(0.06, 0.07, 0.07), false)
	for x in [-30.0, 28.0, 74.0]:
		_add_box(root, shell, "FrontPorchColumn%s" % int(x), Vector3(x, 22, 122), Vector3(6, 44, 6), Color(0.88, 0.86, 0.78), true)
	_add_box(root, shell, "FrontPorchLeftReturnWall", Vector3(-31, 22, 130), Vector3(4, 36, 52), Color(0.88, 0.86, 0.78), true)
	_add_box(root, shell, "FrontPorchRightReturnWall", Vector3(47, 22, 130), Vector3(4, 36, 52), Color(0.88, 0.86, 0.78), true)
	for x in [8.0, 48.0, 88.0]:
		_add_box(root, shell, "RearPorchColumn%s" % int(x), Vector3(x, 22, -124), Vector3(6, 44, 6), Color(0.88, 0.86, 0.78), true)
	_add_box(root, shell, "BoardAndBattenFrontBelt", Vector3(0, 38, 142.5), Vector3(284, 4, 3), Color(0.92, 0.90, 0.84), false)
	_add_box(root, shell, "BoardAndBattenRearBelt", Vector3(0, 38, -142.5), Vector3(284, 4, 3), Color(0.92, 0.90, 0.84), false)
	_add_box(root, shell, "FrontEntryPorchBeam", Vector3(36, 45, 122), Vector3(152, 7, 8), Color(0.86, 0.84, 0.76), false)
	_add_box(root, shell, "GarageBlackAwningTrim", Vector3(-104, 35, 144), Vector3(92, 4, 5), Color(0.06, 0.07, 0.07), false)

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

func _add_gable_end_wall_x(root: Node3D, parent: Node3D, node_name: String, x0: float, x1: float, z: float, eave_y: float, ridge_y: float, color: Color) -> void:
	var ridge_x := (x0 + x1) * 0.5
	var vertices := PackedVector3Array([
		Vector3(x0, eave_y, z),
		Vector3(x1, eave_y, z),
		Vector3(ridge_x, ridge_y, z),
	])
	_add_mesh(root, parent, node_name, vertices, PackedInt32Array([0, 1, 2]), color)

func _add_trim_z(root: Node3D, parent: Node3D, node_name: String, y: float, z: float, x0: float, x1: float, color: Color) -> void:
	_add_box(root, parent, node_name, Vector3((x0 + x1) * 0.5, y, z), Vector3(absf(x1 - x0), 3, 4), color, false)

func _add_room(root: Node3D, parent: Node3D, node_name: String, position: Vector3, size: Vector3, color: Color) -> void:
	var floor_mesh := _add_box(root, parent, node_name, position, size, color, true)
	floor_mesh.set_meta("plan_role", "finished_floor_surface")
	floor_mesh.set_meta("source_plan", "user_provided_estate_plan_three_sheets")

func _route_cells_for_course(course_id: String) -> Array[Vector3i]:
	match course_id:
		"estate_garage":
			return _route_from_points([Vector3i(-3, 0, -3), Vector3i(3, 0, -3), Vector3i(3, 0, 3), Vector3i(-3, 0, 3)])
		"estate_upper_loft":
			return _route_from_points([Vector3i(-3, 0, -2), Vector3i(3, 0, -2), Vector3i(3, 1, 2), Vector3i(-3, 1, 2)])
		"estate_patio":
			return _route_from_points([Vector3i(-5, 0, -2), Vector3i(5, 0, -2), Vector3i(5, 0, 2), Vector3i(-5, 0, 2)])
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
	if str(course["id"]) == "estate_patio":
		size = Vector3(190, 20, 100)
	elif str(course["id"]) == "estate_garage":
		size = Vector3(112, 20, 128)
	return {"min": center - size * 0.5, "max": center + size * 0.5}

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
	return mesh_instance

func _set_owner_recursive(node: Node, owner: Node) -> void:
	for child in node.get_children():
		child.owner = owner
		_set_owner_recursive(child, owner)
