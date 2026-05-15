@tool
extends SceneTree

const TrackDefinition = preload("res://scripts/track/TrackDefinition.gd")
const TrackGridRoadBuilder = preload("res://scripts/track/TrackGridRoadBuilder.gd")
const TrackMapDefinition = preload("res://scripts/track/TrackMapDefinition.gd")
const TrackMetadataExporter = preload("res://scripts/track/TrackMetadataExporter.gd")
const TrackRuntimeScene = preload("res://scripts/track/TrackRuntimeScene.gd")
const TrackSourceRules = preload("res://scripts/track/TrackSourceRules.gd")

const MAP_ID := "home_yard_v3"
const MAP_DISPLAY_NAME := "Racer House + Yard"
const VERSION := "home_yard_residential_openworld_v3_2026_05_12"
const BASE_DIR := "res://assets/gameplay/tracks/home_yard_v3"
const MODE_DIR := "res://assets/gameplay/tracks/home_yard_v3/modes"
const MAP_SCENE_PATH := "res://assets/gameplay/tracks/home_yard_v3/home_yard_v3_map.tscn"
const MAP_DEFINITION_PATH := "res://assets/gameplay/tracks/home_yard_v3/home_yard_v3_track_map.tres"
const FLOOR_PLAN_PATH := "res://docs/concepts/floor_plans/racer_house_yard_concept_floor_plan.png"
const TRACK_PACKAGES_PATH := "res://assets/gameplay/tracks/track_packages.json"
const GRID_LIBRARY := TrackGridRoadBuilder.DEFAULT_MESH_LIBRARY_PATH
const ROAD_TEXTURE := "res://assets/gameplay/materials/plastic/glossy_plastic_albedo.png"
const CELL_SIZE := Vector3(16.0, 4.0, 16.0)
const ROAD_WIDTH := 16.0
const ROAD_FLOOR_CLEARANCE := 0.55
const FLOOR_Y := -1.1
const OUT_OF_BOUNDS_Y := -28.0
const MAIN_FLOOR_TOP_Y := 0.05
const UPPER_ROOM_FLOOR_TOP_Y := 52.60
const ATTIC_ROOM_FLOOR_TOP_Y := 104.60
const MAIN_STAIR_X := 72.0
const MAIN_STAIR_LOWER_Z := 118.0
const MAIN_STAIR_UPPER_Z := 138.0
const MAIN_STAIR_LANDING_Z := 126.0
const MAIN_STAIR_SHAFT_MIN := Vector3(54, 39.5, 106)
const MAIN_STAIR_SHAFT_MAX := Vector3(90, 53.6, 146)
const UNITS_PER_FOOT := 4.0
const SCALE_CONTRACT_ID := "home_yard_v3_human_house_toy_racer_scale_v1"
const SCALE_CONTRACT := {
	"id": SCALE_CONTRACT_ID,
	"units": "Godot units",
	"units_per_floor_plan_foot": UNITS_PER_FOOT,
	"human_house_scale": {
		"reference_height_ft": 6.25,
		"reference_height_units": 25.0,
		"clearance_proxy_height_ft": 8.0,
		"clearance_proxy_height_units": 32.0,
		"door_height_ft": 7.0,
		"door_height_units": 28.0,
		"counter_height_ft": 3.0,
		"counter_height_units": 12.0,
		"occupied_ceiling_clearance_ft": 10.0,
		"occupied_ceiling_clearance_units": 40.0,
	},
	"toy_racer_scale": {
		"runtime_asset_profile": "mobile_detail_phase1",
		"observed_visual_height_units_min": 1.05,
		"observed_visual_height_units_max": 1.40,
		"observed_visual_height_ft_min": 0.2625,
		"observed_visual_height_ft_max": 0.35,
		"nominal_visual_height_units": 1.25,
		"nominal_visual_height_ft": 0.3125,
		"nominal_length_units": 1.90,
		"nominal_width_units": 1.90,
		"route_swept_width_units": 6.0,
		"drift_margin_units": 5.0,
		"chase_camera_clearance_height_units": 12.0,
		"chase_camera_clearance_width_units": 14.0,
	},
	"road_scale": {
		"cell_size_units": CELL_SIZE,
		"cell_size_ft": Vector3(4.0, 1.0, 4.0),
		"road_width_units": ROAD_WIDTH,
		"road_width_ft": ROAD_WIDTH / UNITS_PER_FOOT,
		"road_floor_clearance_units": ROAD_FLOOR_CLEARANCE,
	},
	"asset_policy": "House shell, stairs, windows, doors, counters, furniture, and yards use human residential scale. Racers, plastic road, cones, gates, and toy-route cues use toy scale inside that house. Imported Kenney/Meshy/toybox assets must declare intended scale class and target dimensions before production acceptance.",
}
const GENERATED_PROVENANCE_REQUIRED_FIELDS := [
	"node_path",
	"visible_class",
	"owner_volume",
	"assembly",
	"role",
	"source_of_truth",
	"why_exists",
	"support_target",
	"contact_face",
	"span_axis",
	"start_anchor",
	"end_anchor",
	"allowed_intersections",
	"forbidden_intersections",
	"deletion_rule",
	"validation_gate",
	"validation_camera",
]
const PLAN_CONTRACT := {
	"source": "racer_house_yard_concept_floor_plan.png",
	"selected_alternative": "Residential Open World V3",
	"site_orientation": "front/street +Z, backyard -Z",
	"style_contract": "large residential Dutch Colonial suburban house on a bigger but residential lot; tracks are plastic toy overlays on finished rooms and yard zones, not room-defining shells",
	"world_scale": "1 floor-plan foot = 4 Godot units; RoadGridMap cell is 16 x 16 units / 4 ft x 4 ft; house, doors, counters, ceilings, windows, and furnishings must read as human residential scale, with toy racers and plastic track scaled as small objects inside that human space",
	"scale_contract_id": SCALE_CONTRACT_ID,
	"human_scale_reference": "C:/code/Kenney Game Assets All-in-1 3.3.0/3D assets/Animated Characters Bundle/Models/Source/characterLargeMale.blend",
	"human_scale_reference_role": "Kenney large male character is the standing human proportion reference for door height, counter height, ceiling clearance, furniture scale, and camera critique; do not scale the home down to toy-house proportions",
	"lot_bounds": {"min": Vector3(-360, -2, -460), "max": Vector3(360, 60, 220)},
	"house_footprint": {"main_house": {"min": Vector3(-200, 0, -130), "max": Vector3(90, 104, 145)}, "garage": {"min": Vector3(90, 0, -60), "max": Vector3(220, 52, 145)}, "front_porch": {"min": Vector3(-155, 0, 145), "max": Vector3(55, 18, 180)}, "back_deck": {"min": Vector3(-170, 0, -175), "max": Vector3(75, 18, -130)}},
	"floor_heights": {"main": 0.0, "upper": 52.0, "attic": 104.0},
	"ceiling_clear_height": 40.0,
	"shell_ownership": "ExteriorShell/Roof/Foundation/Openings/PorchesDecks/GarageService own exterior assemblies; floor holders own interior partitions, room finishes, props, lighting, route aids, and localized collision only.",
	"route_contract": "Each race is a plastic toy-track overlay with declared zone bounds, route bounds, road-surface elevation above finished floors, obstacle exclusions, and clear start/finish language.",
	"roof_contract": "Dutch gambrel roof: lower steep roof planes spring from the attic floor plate, upper shallow planes meet at one ridge, central attic has 7.5 ft walkable clearance, and no rectangular attic story may be visible above the roof.",
	"free_drive_contract": "Free-drive circulation is laid out through entry, dining/living, stair hall, back deck, and oversized doggie door, but races still start in separate area courses for this pass.",
	"vertical_circulation_contract": "The floor plan includes architectural vertical circulation: a main stair from the entry/stair hall to the upper hall, plus an attic pull-down stair/ladder from the upper hall into the gambrel attic. Toy ramp boxes are not valid house circulation.",
	"beta_visual_contract": "Whole-unit beta review requires clean runtime/cinematic screenshots without editor camera icons or selected-node overlays; front/back/side/elevated/roofline/underside/player-route views must identify out-of-place pieces before metadata is accepted. Generated route decks and ramps are allowed only as classified route_infrastructure with non-placeholder materials, edge treatment, route clearance, and validation cameras.",
	"vertical_links": [
		{"id": "MainStairEntryToUpperHall", "type": "switchback_residential_stair", "from_floor": "main", "to_floor": "upper", "lower_zone": "entry_stair_hall", "upper_zone": "upper_front_hall", "lower_landing_center": Vector3(MAIN_STAIR_X, 0.05, MAIN_STAIR_LANDING_Z), "upper_landing_center": Vector3(MAIN_STAIR_X, 52.60, MAIN_STAIR_LANDING_Z), "stairwell_bounds": {"min": MAIN_STAIR_SHAFT_MIN, "max": MAIN_STAIR_SHAFT_MAX}, "opening_required": "upper_floor_stairwell_opening", "path_segments": ["lower_landing", "lower_flight", "switchback_landing", "upper_flight", "upper_landing"], "continuity_gate": "segments must connect landing-to-landing from main floor datum to upper floor datum within 1 unit tolerance and must stay outside bedroom/glam route envelopes while remaining in the entry/upper hall, not the garage", "source_asset": "res://assets/source/kenney/mini_skate/steps.glb", "collision_policy": "visual_reference_no_gameplay_collision", "validation_gate": "must not intersect route corridors, room walls, human reference clearance, garage parking volume, or third-person camera views"},
		{"id": "AtticPullDownStairUpperHallToAttic", "type": "pull_down_attic_stair", "from_floor": "upper", "to_floor": "attic", "lower_zone": "upper_hall", "upper_zone": "attic_toy_course", "lower_landing_center": Vector3(24, 52.60, -54), "upper_landing_center": Vector3(24, 104.60, -54), "stairwell_bounds": {"min": Vector3(2, 52, -82), "max": Vector3(48, 105, -28)}, "opening_required": "attic_access_hatch", "path_segments": ["lower_landing", "pull_down_ladder", "attic_hatch_landing"], "continuity_gate": "ladder rungs and rails must span upper hall floor datum to attic floor datum and overlap the hatch opening", "source_asset": "res://assets/source/kenney/mini_skate/steps.glb", "collision_policy": "visual_reference_no_gameplay_collision", "validation_gate": "must not intersect attic route corridor, roof planes, upper hall walls, or third-person camera views"},
	],
}

const INTERIOR_WALL_SCHEDULE := [
	{"id": "KitchenPlayroomDivider", "floor": "main", "owner": "interior_partition", "axis": "x", "x": -55.0, "start": -130.0, "end": 15.0, "base_y": 0.0, "height": 40.0, "connected_zones": ["kitchen_breakfast", "playroom_family"], "opening_span": Vector2(-42.0, -12.0), "threshold_datum": 0.05, "owner_skill": "floor-plan-architect", "confidence": "inferred_from_v3_numeric_plan"},
	{"id": "KitchenDiningCasedOpening", "floor": "main", "owner": "interior_partition", "axis": "z", "z": 15.0, "start": -200.0, "end": -55.0, "base_y": 0.0, "height": 40.0, "connected_zones": ["kitchen_breakfast", "dining_living"], "opening_span": Vector2(-166.0, -94.0), "threshold_datum": 0.05, "owner_skill": "floor-plan-architect", "confidence": "inferred_from_v3_numeric_plan"},
	{"id": "PlayroomLivingCasedOpening", "floor": "main", "owner": "interior_partition", "axis": "z", "z": 15.0, "start": -55.0, "end": 90.0, "base_y": 0.0, "height": 40.0, "connected_zones": ["playroom_family", "dining_living"], "opening_span": Vector2(-28.0, 45.0), "threshold_datum": 0.05, "owner_skill": "floor-plan-architect", "confidence": "inferred_from_v3_numeric_plan"},
	{"id": "LivingEntryDivider", "floor": "main", "owner": "interior_partition", "axis": "x", "x": 35.0, "start": 15.0, "end": 145.0, "base_y": 0.0, "height": 40.0, "connected_zones": ["dining_living", "entry_stair_hall"], "opening_span": Vector2(54.0, 96.0), "threshold_datum": 0.05, "owner_skill": "floor-plan-architect", "confidence": "inferred_from_v3_numeric_plan"},
	{"id": "GarageInteriorBackWall", "floor": "main", "owner": "interior_partition", "axis": "x", "x": 90.0, "start": -60.0, "end": 145.0, "base_y": 0.0, "height": 40.0, "connected_zones": ["entry_stair_hall", "garage_service"], "opening_span": Vector2(58.0, 82.0), "threshold_datum": 0.05, "owner_skill": "floor-plan-architect", "confidence": "inferred_from_v3_numeric_plan"},
	{"id": "DoggieDoorInteriorThreshold", "floor": "main", "owner": "interior_partition", "axis": "z", "z": -130.0, "start": -55.0, "end": 30.0, "base_y": 0.0, "height": 20.0, "connected_zones": ["playroom_family", "back_deck_free_drive"], "opening_span": Vector2(-18.0, 26.0), "threshold_datum": 0.05, "owner_skill": "floor-plan-architect", "confidence": "inferred_from_v3_numeric_plan"},
	{"id": "BedroomGlamCasedOpening", "floor": "upper", "owner": "interior_partition", "axis": "x", "x": -15.0, "start": -130.0, "end": 106.0, "base_y": 52.0, "height": 40.0, "connected_zones": ["bedroom_suite", "glam_dressing"], "opening_span": Vector2(24.0, 72.0), "threshold_datum": 52.60, "owner_skill": "floor-plan-architect", "confidence": "inferred_from_v3_numeric_plan"},
	{"id": "UpperHallBedroomDivider", "floor": "upper", "owner": "interior_partition", "axis": "z", "z": 106.0, "start": -180.0, "end": 90.0, "base_y": 52.0, "height": 40.0, "connected_zones": ["upper_front_hall", "bedroom_glam_suite"], "opening_span": Vector2(-120.0, 66.0), "threshold_datum": 52.60, "owner_skill": "floor-plan-architect", "confidence": "inferred_from_v3_numeric_plan"},
	{"id": "AtticWestKneePartition", "floor": "attic", "owner": "interior_partition", "axis": "x", "x": -160.0, "start": -95.0, "end": 120.0, "base_y": 104.0, "height": 20.0, "connected_zones": ["attic_toy_course", "west_knee_storage"], "opening_span": Vector2.ZERO, "threshold_datum": 104.60, "owner_skill": "floor-plan-architect", "confidence": "inboard_and_below_v3_gambrel_roof_contract"},
	{"id": "AtticEastKneePartition", "floor": "attic", "owner": "interior_partition", "axis": "x", "x": 50.0, "start": -95.0, "end": 120.0, "base_y": 104.0, "height": 20.0, "connected_zones": ["attic_toy_course", "east_knee_storage"], "opening_span": Vector2.ZERO, "threshold_datum": 104.60, "owner_skill": "floor-plan-architect", "confidence": "inboard_and_below_v3_gambrel_roof_contract"},
	{"id": "AtticStorageBackPartition", "floor": "attic", "owner": "interior_partition", "axis": "z", "z": 120.0, "start": -150.0, "end": 50.0, "base_y": 104.0, "height": 20.0, "connected_zones": ["attic_toy_course", "front_attic_storage"], "opening_span": Vector2(-42.0, 18.0), "threshold_datum": 104.60, "owner_skill": "floor-plan-architect", "confidence": "inboard_and_below_v3_gambrel_roof_contract"},
]

const BACKYARD_PLAYGROUND_PATH := "res://assets/gameplay/tracks/shared/backyard_optimized/playground_structure_low.glb"
const BACKYARD_SWING_PATH := "res://assets/gameplay/tracks/shared/backyard_optimized/swing_set_low.glb"
const BACKYARD_FOSSIL_PATH := "res://assets/gameplay/tracks/shared/backyard_optimized/sandbox_fossil_low.glb"
const BACKYARD_GARDEN_PATH := "res://assets/gameplay/tracks/shared/backyard_optimized/garden_log_bush_low.glb"
const TOYBOX_TREE_SWING_PATH := "res://assets/gameplay/tracks/home_yard/props/toybox_tree_swing/stylized_realistic_tree_tire_swing.glb"
const KENNEY_START_GATE_PATH := "res://assets/source/kenney/toy_car_kit/gate.glb"
const KENNEY_FINISH_GATE_PATH := "res://assets/source/kenney/toy_car_kit/gate-finish.glb"
const KENNEY_ROUTE_CONE_PATH := "res://assets/source/kenney/toy_car_kit/item-cone.glb"
const KENNEY_FLAG_PATH := "res://assets/source/kenney/racing_kit/flagCheckersSmall.glb"
const KENNEY_HUMAN_SCALE_REFERENCE_PATH := "res://assets/source/kenney/animated_characters/characterLargeMale.fbx"
const KENNEY_STEPS_PATH := "res://assets/source/kenney/mini_skate/steps.glb"
const KENNEY_KITCHEN_FRIDGE_PATH := "res://assets/source/kenney/furniture_kit/kitchenFridge.glb"
const KENNEY_KITCHEN_SINK_PATH := "res://assets/source/kenney/furniture_kit/kitchenSink.glb"
const PLAYROOM_MESHY_PLUSH_PATH := "res://assets/source/meshy/home_yard_v3/playroom/low_poly_playroom_plush_landmark/low_poly_playroom_plush_landmark.glb"
const PLAYROOM_MESHY_BLOCK_TOWER_PATH := "res://assets/source/meshy/home_yard_v3/playroom/low_poly_playroom_toy_block_tower/low_poly_playroom_toy_block_tower.glb"
const PLAYROOM_MESHY_TOY_BINS_PATH := "res://assets/source/meshy/home_yard_v3/playroom/low_poly_playroom_ramp_side_toy_bins/low_poly_playroom_ramp_side_toy_bins.glb"
const KENNEY_BED_PATH := "res://assets/source/kenney/furniture_kit/bedSingle.glb"
const KENNEY_BEDROOM_LAMP_PATH := "res://assets/source/kenney/furniture_kit/lampRoundTable.glb"
const KENNEY_GLAM_MIRROR_PATH := "res://assets/source/kenney/furniture_kit/bathroomMirror.glb"
const KENNEY_GLAM_RUG_PATH := "res://assets/source/kenney/furniture_kit/rugRound.glb"
const KENNEY_GARDEN_BUSH_PATH := "res://assets/source/kenney/nature_kit/plant_bushLarge.glb"
const KENNEY_GARDEN_LOG_PATH := "res://assets/source/kenney/nature_kit/log_large.glb"
const ATTIC_MESHY_TRUNK_PATH := "res://assets/source/meshy/home_yard_v3/attic/low_poly_dusty_attic_trunk/low_poly_dusty_attic_trunk.glb"
const ATTIC_MESHY_JACK_PATH := "res://assets/source/meshy/home_yard_v3/attic/low_poly_attic_jack_in_the_box_setpiece/low_poly_attic_jack_in_the_box_setpiece.glb"
const ATTIC_MESHY_SHEET_TUNNEL_PATH := "res://assets/source/meshy/home_yard_v3/attic/low_poly_attic_sheet_tunnel/low_poly_attic_sheet_tunnel.glb"
const PLAYGROUND_SWING_MESHY_PATH := "res://assets/source/meshy/playground_wooden_set/wooden_playground_set_swing.glb"
const SANDBOX_TREX_MESHY_PATH := "res://assets/source/meshy/sandbox_props/trex_skeleton.glb"

const COURSES := [
	{"id": "kitchen", "display_name": "Kitchen / Sir Clink", "sky": "noon_clear", "placement": Vector3(-128, 0.60, -57), "floor": 0, "color": Color(0.92, 0.78, 0.55), "texture": "res://assets/gameplay/materials/tile/kitchen_tile_albedo.png"},
	{"id": "playroom", "display_name": "Playroom / Slammo", "sky": "party_evening", "placement": Vector3(17, 0.60, -57), "floor": 0, "color": Color(0.92, 0.70, 0.38), "texture": "res://assets/gameplay/materials/plastic/glossy_plastic_albedo.png"},
	{"id": "outdoor_playground", "display_name": "Outdoor Playground / Dash", "sky": "clear_afternoon", "placement": Vector3(-52, 0.90, -217), "floor": 0, "color": Color(0.36, 0.18, 0.08), "texture": "res://assets/gameplay/materials/playground/outdoor_playground_floor_albedo.png", "shader": "res://assets/gameplay/materials/grass/playground_grass.gdshader"},
	{"id": "garden", "display_name": "Garden / Moko", "sky": "fresh_morning", "placement": Vector3(-250, 0.90, -307), "floor": 0, "color": Color(0.32, 0.43, 0.24), "texture": "res://assets/gameplay/materials/garden/garden_dirt_mud_albedo.png"},
	{"id": "sandbox", "display_name": "Sandbox / Rexx", "sky": "hot_afternoon", "placement": Vector3(217, 0.90, -318), "floor": 0, "color": Color(0.82, 0.66, 0.42), "texture": "res://assets/gameplay/materials/sand/sandbox_sand_albedo.png"},
	{"id": "bedroom", "display_name": "Bedroom / Tuggs", "sky": "soft_morning", "placement": Vector3(-98, UPPER_ROOM_FLOOR_TOP_Y + ROAD_FLOOR_CLEARANCE, -12), "floor": 1, "color": Color(0.55, 0.50, 0.66), "texture": "res://assets/gameplay/materials/fabric/plush_fabric_albedo.png"},
	{"id": "glam_closet", "display_name": "Glam Closet / Velva", "sky": "night_city_glow", "placement": Vector3(37, UPPER_ROOM_FLOOR_TOP_Y + ROAD_FLOOR_CLEARANCE, -12), "floor": 1, "color": Color(0.74, 0.42, 0.63), "texture": "res://assets/gameplay/materials/glam/glam_mirror_glitter_albedo.png"},
	{"id": "attic", "display_name": "Attic Mayhem", "sky": "stormy_moonlight_night", "placement": Vector3(-50, ATTIC_ROOM_FLOOR_TOP_Y + ROAD_FLOOR_CLEARANCE, 13), "floor": 2, "color": Color(0.45, 0.35, 0.25), "texture": "res://assets/gameplay/materials/attic/attic_cardboard_wood_albedo.png"},
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
	root.set_meta("scale_contract", SCALE_CONTRACT)
	root.set_meta("interior_wall_schedule", INTERIOR_WALL_SCHEDULE)
	root.set_meta("vertical_circulation_contract", _vertical_circulation_contract())
	root.set_meta("whole_unit_visual_review_contract", _whole_unit_visual_review_contract())
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
	map.ground_size = Vector2(720, 680)
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
			"ground_size": Vector2(720, 680),
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
	maps.erase("home_yard")
	maps.erase("home_yard_v2")
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
	definition.ground_size = Vector2(720, 680)
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
	_add_box(root, site, "WholeSiteGround", Vector3(0, -1.15, -120), Vector3(720, 1, 680), Color(0.36, 0.48, 0.30), true)
	_add_box(root, site, "StreetFrontYardEdge", Vector3(0, -0.65, 206), Vector3(720, 1, 28), Color(0.20, 0.22, 0.22), true)
	_add_box(root, site, "ConcreteStreetCurb", Vector3(0, 0.1, 190), Vector3(720, 2.2, 4), Color(0.66, 0.66, 0.60), false)
	_add_box(root, site, "PublicSidewalk", Vector3(0, -0.30, 176), Vector3(640, 1.0, 10), Color(0.62, 0.62, 0.57), true)
	_add_box(root, site, "FrontWalkArrivalGarden", Vector3(-50, -0.55, 160), Vector3(210, 1, 18), Color(0.74, 0.74, 0.66), true)
	_add_box(root, site, "FrontEntryWalk", Vector3(-50, -0.45, 126), Vector3(30, 1.1, 74), Color(0.68, 0.66, 0.60), true)
	_add_box(root, site, "FrontWalkSteppingStoneA", Vector3(-50, 0.05, 145), Vector3(22, 0.4, 8), Color(0.52, 0.52, 0.48), false)
	_add_box(root, site, "FrontWalkSteppingStoneB", Vector3(-50, 0.05, 114), Vector3(22, 0.4, 8), Color(0.54, 0.54, 0.49), false)
	_add_box(root, site, "Driveway", Vector3(155, -0.45, 118), Vector3(118, 1.1, 160), Color(0.46, 0.46, 0.43), true)
	_add_box(root, site, "DrivewayExpansionJointA", Vector3(155, 0.2, 82), Vector3(118, 0.14, 1.2), Color(0.27, 0.27, 0.25), false)
	_add_box(root, site, "DrivewayExpansionJointB", Vector3(155, 0.2, 142), Vector3(118, 0.14, 1.2), Color(0.27, 0.27, 0.25), false)
	_add_box(root, site, "FrontFoundationPlantingLeft", Vector3(-130, -0.35, 135), Vector3(118, 1.2, 16), Color(0.22, 0.42, 0.18), true)
	_add_box(root, site, "FrontFoundationPlantingRight", Vector3(24, -0.35, 135), Vector3(78, 1.2, 16), Color(0.24, 0.44, 0.20), true)
	_add_box(root, site, "MailboxPost", Vector3(104, 6, 178), Vector3(4, 12, 4), Color(0.20, 0.12, 0.08), false)
	_add_box(root, site, "MailboxBox", Vector3(104, 14, 175), Vector3(14, 8, 8), Color(0.25, 0.27, 0.29), false)
	_add_box(root, site, "ServiceTrashBinA", Vector3(238, 8, 54), Vector3(12, 16, 14), Color(0.12, 0.22, 0.18), false)
	_add_box(root, site, "ServiceTrashBinB", Vector3(254, 8, 54), Vector3(12, 16, 14), Color(0.10, 0.16, 0.22), false)
	_add_box(root, site, "ServiceTrashBinALid", Vector3(238, 16.6, 53), Vector3(13, 1.4, 15), Color(0.06, 0.09, 0.08), false)
	_add_box(root, site, "ServiceTrashBinBLid", Vector3(254, 16.6, 53), Vector3(13, 1.4, 15), Color(0.05, 0.07, 0.10), false)
	for i in range(4):
		var wheel_x := 232.5 if i < 2 else 243.5
		var wheel_z := 47.5 if i % 2 == 0 else 60.5
		_add_box(root, site, "ServiceTrashBinAWheel%02d" % i, Vector3(wheel_x, 1.4, wheel_z), Vector3(2.2, 2.8, 2.2), Color(0.02, 0.02, 0.02), false)
		_add_box(root, site, "ServiceTrashBinBWheel%02d" % i, Vector3(wheel_x + 16.0, 1.4, wheel_z), Vector3(2.2, 2.8, 2.2), Color(0.02, 0.02, 0.02), false)
	_add_box(root, site, "ServiceTrashBinAHandle", Vector3(238, 12, 46.6), Vector3(8, 1.4, 1.4), Color(0.03, 0.03, 0.03), false)
	_add_box(root, site, "ServiceTrashBinBHandle", Vector3(254, 12, 46.6), Vector3(8, 1.4, 1.4), Color(0.03, 0.03, 0.03), false)
	_add_box(root, site, "NorthBackFence", Vector3(0, 12, -460), Vector3(720, 24, 7), Color(0.28, 0.20, 0.13), true)
	_add_box(root, site, "SouthFrontFence", Vector3(0, 12, 220), Vector3(720, 24, 7), Color(0.28, 0.20, 0.13), true)
	_add_box(root, site, "WestSideFence", Vector3(-360, 12, -120), Vector3(7, 24, 680), Color(0.28, 0.20, 0.13), true)
	_add_box(root, site, "EastSideFence", Vector3(360, 12, -120), Vector3(7, 24, 680), Color(0.28, 0.20, 0.13), true)
	for i in range(7):
		var x := -210.0 + float(i) * 42.0
		_add_box(root, site, "FrontShrubMass%02d" % i, Vector3(x, 2.2, 130 + float(i % 2) * 5.0), Vector3(20, 5, 12), Color(0.18, 0.38, 0.18).lightened(float(i % 3) * 0.04), false)

func _add_floor_plan_zones(root: Node3D, holders: Dictionary) -> void:
	var yard := holders["Yard"] as Node3D
	_add_yard_plan(root, yard)

func _add_foundation(root: Node3D, parent: Node3D) -> void:
	parent.set_meta("plan_role", "foundation/plinth and grade contact from floor-plan contract")
	parent.set_meta("foundation_footprint_contract", "plinth segments are clipped to owning wall runs; main rear plinth spans only kitchen/playroom back wall and garage has its own side/front returns")
	var stone := Color(0.42, 0.39, 0.34)
	_add_box(root, parent, "HouseFoundationFrontPlinth", Vector3(10, 2.8, 145), Vector3(430, 7, 8), stone, false)
	_add_box(root, parent, "HouseFoundationBackPlinth", Vector3(-55, 2.8, -130), Vector3(300, 7, 8), stone, false)
	_add_box(root, parent, "HouseFoundationWestPlinth", Vector3(-200, 2.8, 7.5), Vector3(8, 7, 285), stone, false)
	_add_box(root, parent, "HouseFoundationEastPlinth", Vector3(220, 2.8, 42.5), Vector3(8, 7, 205), stone, false)
	_add_box(root, parent, "GarageStepFoundationPlinth", Vector3(90, 2.8, -95), Vector3(8, 7, 70), stone.darkened(0.04), false)
	_add_box(root, parent, "GarageSlabApron", Vector3(155, 0.6, 150), Vector3(118, 2.0, 54), Color(0.52, 0.51, 0.47), true)
	_add_box(root, parent, "FrontPorchPierLeft", Vector3(-120, 5, 160), Vector3(14, 10, 14), stone.darkened(0.04), false)
	_add_box(root, parent, "FrontPorchPierRight", Vector3(20, 5, 160), Vector3(14, 10, 14), stone.darkened(0.04), false)
	_add_box(root, parent, "BackDeckPierWest", Vector3(-150, 5, -152), Vector3(10, 10, 10), stone.darkened(0.08), false)
	_add_box(root, parent, "BackDeckPierEast", Vector3(58, 5, -152), Vector3(10, 10, 10), stone.darkened(0.08), false)

func _add_main_floor_interior(root: Node3D, parent: Node3D) -> void:
	parent.set_meta("plan_role", "main floor interior only; exterior shell is owned by ExteriorShell/Openings/Roof/Foundation")
	var finishes := _add_child_holder(root, parent, "RoomFinishes", "main floor floors, baseboards, interior finishes, and route-facing room set dressing")
	var walls := _add_child_holder(root, parent, "InteriorWalls", "contract-generated main floor interior partitions only")
	var wall := Color(0.64, 0.58, 0.50)
	_add_room_floor(root, finishes, "DiningLiving", Vector3(-82.5, -0.55, 80), Vector3(235, 1.2, 130), Color(0.62, 0.48, 0.35))
	_add_room_floor(root, finishes, "EntryStairHall", Vector3(62.5, -0.55, 80), Vector3(55, 1.2, 130), Color(0.58, 0.53, 0.45))
	_add_room_floor(root, finishes, "GarageService", Vector3(155, -0.55, 42.5), Vector3(130, 1.2, 205), Color(0.42, 0.42, 0.39))
	_add_room_floor(root, finishes, "KitchenBreakfast", Vector3(-127.5, -0.55, -57.5), Vector3(145, 1.2, 145), Color(0.78, 0.68, 0.50))
	_add_room_floor(root, finishes, "PlayroomFamily", Vector3(17.5, -0.55, -57.5), Vector3(145, 1.2, 145), Color(0.76, 0.58, 0.30))
	_add_main_floor_ceiling_with_stairwell_shaft(root, finishes)
	_add_box(root, finishes, "GarageTenFootCeilingPlane", Vector3(155, 40.8, 42.5), Vector3(130, 1.6, 205), Color(0.58, 0.56, 0.50), false)
	_add_interior_partitions_from_schedule(root, walls, "main", wall)
	_add_box(root, finishes, "KitchenPatioThresholdInterior", Vector3(-128, 1.0, -130), Vector3(72, 2.0, 8), Color(0.16, 0.24, 0.24), false)
	_add_box(root, finishes, "PlayroomDoggieDoorThresholdInterior", Vector3(4, 1.0, -130), Vector3(56, 2.0, 8), Color(0.16, 0.24, 0.24), false)
	_add_box(root, finishes, "KitchenCabinetRunBack", Vector3(-128, 4, -123), Vector3(130, 8, 10), Color(0.38, 0.20, 0.10), false)
	_add_box(root, finishes, "KitchenIsland", Vector3(-128, 4, -57), Vector3(66, 8, 34), Color(0.52, 0.34, 0.18), false)
	_add_kitchen_readability_system(root, parent)
	_add_box(root, finishes, "LivingSofa", Vector3(-46, 5, 90), Vector3(74, 10, 18), Color(0.28, 0.34, 0.42), false)
	_add_box(root, finishes, "DiningTableAnchor", Vector3(-142, 4, 86), Vector3(48, 8, 34), Color(0.36, 0.22, 0.12), false)
	_add_box(root, finishes, "PlayroomBlockMountain", Vector3(50, 6, -28), Vector3(38, 12, 30), Color(0.18, 0.32, 0.76), false)
	_add_box(root, finishes, "PlayroomLowTable", Vector3(18, 5, -92), Vector3(54, 10, 24), Color(0.80, 0.24, 0.20), false)

func _add_main_floor_ceiling_with_stairwell_shaft(root: Node3D, parent: Node3D) -> void:
	var ceiling := _add_child_holder(root, parent, "MainFloorTenFootCeilingPlane", "split first-floor ceiling plane; stairwell shaft remains clear through the interstitial floor assembly")
	ceiling.set_meta("stairwell_shaft_void_bounds", {"min": MAIN_STAIR_SHAFT_MIN, "max": MAIN_STAIR_SHAFT_MAX})
	ceiling.set_meta("opening_required_for_vertical_link", "MainStairEntryToUpperHall")
	ceiling.set_meta("ceiling_footprint_contract", "main-floor ceiling pieces are clipped to occupied interior zones west/north/south of the stairwell; garage ceiling is owned by GarageTenFootCeilingPlane and no east-of-shaft broad patch is allowed")
	var color := Color(0.79, 0.75, 0.66)
	_add_box(root, ceiling, "MainCeilingWestOfStairShaft", Vector3(-73, 40.8, 7.5), Vector3(254, 1.6, 275), color, false)
	_add_box(root, ceiling, "MainCeilingNorthOfStairShaft", Vector3(MAIN_STAIR_X, 40.8, -12), Vector3(36, 1.6, 236), color, false)
	_add_box(root, ceiling, "MainCeilingSouthOfStairShaft", Vector3(MAIN_STAIR_X, 40.8, 147.5), Vector3(36, 1.6, 3), color, false)
	_add_stairwell_soffit_return(root, ceiling, "MainStairShaftReturnNorth", Vector3(MAIN_STAIR_X, 46.4, MAIN_STAIR_SHAFT_MIN.z), Vector3(36, 11.2, 2.0), color.darkened(0.15))
	_add_stairwell_soffit_return(root, ceiling, "MainStairShaftReturnSouth", Vector3(MAIN_STAIR_X, 46.4, MAIN_STAIR_SHAFT_MAX.z), Vector3(36, 11.2, 2.0), color.darkened(0.15))
	_add_stairwell_soffit_return(root, ceiling, "MainStairShaftReturnWest", Vector3(MAIN_STAIR_SHAFT_MIN.x, 46.4, 126), Vector3(2.0, 11.2, 40), color.darkened(0.15))
	_add_stairwell_soffit_return(root, ceiling, "MainStairShaftReturnEast", Vector3(MAIN_STAIR_SHAFT_MAX.x, 46.4, 126), Vector3(2.0, 11.2, 40), color.darkened(0.15))

func _add_stairwell_soffit_return(root: Node3D, parent: Node3D, node_name: String, position: Vector3, size: Vector3, color: Color) -> void:
	var return_piece := _add_box(root, parent, node_name, position, size, color, false)
	return_piece.set_meta("stairwell_shaft_return", true)
	return_piece.set_meta("vertical_link_id", "MainStairEntryToUpperHall")
	return_piece.set_meta("asset_role", "floor_assembly_cutout_return")
	return_piece.set_meta("collision_policy", "visual_trim_no_gameplay_collision")
	return_piece.set_meta("route_clearance", "outside_route_corridor")
	return_piece.set_meta("scale_contract_id", SCALE_CONTRACT_ID)

func _add_kitchen_readability_system(root: Node3D, parent: Node3D) -> void:
	var holder := Node3D.new()
	holder.name = "KitchenRaceReadabilityKit"
	holder.set_meta("player_readability_contract", {
		"course_id": "kitchen",
		"surface": "shared-map readability comes from the active kitchen GridMap route and room landmarks, not a second slab overlay",
		"edge_treatment": "route contrast must come from the active mode road tiles and room landmarks only",
		"landmarks": ["kitchen island", "fridge bank", "pantry run"],
		"first_seconds": "start grid faces the active kitchen GridMap straight; shared-scene helper blockers are forbidden in the spawn lane or first-turn sightline",
	})
	parent.add_child(holder)
	holder.owner = root

func _add_upper_floor_interior(root: Node3D, parent: Node3D) -> void:
	parent.set_meta("plan_role", "upper floor interior only; exterior dormer shell and roof are owned by ExteriorShell/Roof/Openings")
	var finishes := _add_child_holder(root, parent, "RoomFinishes", "upper floor floors, baseboards, interior finishes, and course dressing")
	var walls := _add_child_holder(root, parent, "InteriorWalls", "contract-generated upper floor interior partitions only")
	var wall := Color(0.57, 0.51, 0.43)
	var upper_deck := _add_child_holder(root, finishes, "UpperFloorDeck", "split upper floor deck; the main stairwell opening is intentionally clear")
	upper_deck.set_meta("stairwell_opening_bounds", {"min": MAIN_STAIR_SHAFT_MIN, "max": MAIN_STAIR_SHAFT_MAX})
	upper_deck.set_meta("opening_required_for_vertical_link", "MainStairEntryToUpperHall")
	_add_room_floor(root, upper_deck, "UpperFloorDeckBedroomBack", Vector3(-97.5, 51, -12), Vector3(165, 2, 236), Color(0.46, 0.40, 0.34))
	_add_room_floor(root, upper_deck, "UpperFloorDeckGlamBack", Vector3(37.5, 51, -12), Vector3(105, 2, 236), Color(0.46, 0.40, 0.34), false)
	_add_room_floor(root, upper_deck, "UpperFloorDeckUpperHallWest", Vector3(19.5, 51, 126), Vector3(69, 2, 40), Color(0.46, 0.40, 0.34), false)
	_add_room_floor(root, finishes, "BedroomSuite", Vector3(-97.5, 52, -12), Vector3(165, 1.2, 236), Color(0.58, 0.52, 0.43))
	var glam_floor := _add_child_holder(root, finishes, "GlamDressing", "glam dressing finish floor split around the front-hall stairwell opening")
	glam_floor.set_meta("stairwell_opening_bounds", {"min": MAIN_STAIR_SHAFT_MIN, "max": MAIN_STAIR_SHAFT_MAX})
	_add_room_floor(root, glam_floor, "GlamDressingBackFloor", Vector3(37.5, 52, -12), Vector3(105, 1.2, 236), Color(0.60, 0.52, 0.45), false)
	_add_stairwell_guardrail(root, finishes)
	_add_box(root, finishes, "UpperFloorTenFootCeilingPlane", Vector3(-45, 92.8, 17.5), Vector3(270, 1.6, 215), Color(0.73, 0.68, 0.62), false)
	_add_interior_partitions_from_schedule(root, walls, "upper", wall)
	_add_box(root, finishes, "BedroomClosetBuiltIn", Vector3(-166, 60, 10), Vector3(20, 16, 74), Color(0.32, 0.24, 0.18), false)
	_add_box(root, finishes, "BedroomDeskNook", Vector3(-52, 57, 74), Vector3(42, 10, 18), Color(0.40, 0.28, 0.18), false)
	_add_box(root, finishes, "BedroomBedPlatform", Vector3(-128, 58, 26), Vector3(44, 12, 58), Color(0.28, 0.26, 0.34), false)
	_add_box(root, finishes, "GlamWardrobeRun", Vector3(78, 60, -12), Vector3(22, 16, 190), Color(0.34, 0.20, 0.28), false)
	_add_box(root, finishes, "GlamVanityIsland", Vector3(36, 57, -54), Vector3(48, 10, 20), Color(0.54, 0.30, 0.45), false)
	_add_box(root, finishes, "GlamMirrorWall", Vector3(36, 64, 96), Vector3(62, 24, 1.0), Color(0.60, 0.72, 0.82, 0.55), false)

func _add_stairwell_guardrail(root: Node3D, parent: Node3D) -> void:
	var rail_color := Color(0.38, 0.30, 0.22)
	_add_guardrail_segment(root, parent, "MainStairOpeningRailNorth", Vector3(MAIN_STAIR_X, UPPER_ROOM_FLOOR_TOP_Y + 7.2, MAIN_STAIR_SHAFT_MIN.z), Vector3(36, 2.2, 2.2), rail_color)
	_add_guardrail_segment(root, parent, "MainStairOpeningRailSouth", Vector3(MAIN_STAIR_X, UPPER_ROOM_FLOOR_TOP_Y + 7.2, MAIN_STAIR_SHAFT_MAX.z), Vector3(36, 2.2, 2.2), rail_color)
	_add_guardrail_segment(root, parent, "MainStairOpeningRailWest", Vector3(MAIN_STAIR_SHAFT_MIN.x, UPPER_ROOM_FLOOR_TOP_Y + 7.2, 126), Vector3(2.2, 2.2, 40), rail_color)
	var post_positions := [
		Vector3(MAIN_STAIR_SHAFT_MIN.x, UPPER_ROOM_FLOOR_TOP_Y + 4.0, MAIN_STAIR_SHAFT_MIN.z),
		Vector3(MAIN_STAIR_SHAFT_MAX.x, UPPER_ROOM_FLOOR_TOP_Y + 4.0, MAIN_STAIR_SHAFT_MIN.z),
		Vector3(MAIN_STAIR_SHAFT_MIN.x, UPPER_ROOM_FLOOR_TOP_Y + 4.0, MAIN_STAIR_SHAFT_MAX.z),
		Vector3(MAIN_STAIR_SHAFT_MAX.x, UPPER_ROOM_FLOOR_TOP_Y + 4.0, MAIN_STAIR_SHAFT_MAX.z),
		Vector3(MAIN_STAIR_SHAFT_MIN.x, UPPER_ROOM_FLOOR_TOP_Y + 4.0, 126),
	]
	for i in range(post_positions.size()):
		var post := _add_box(root, parent, "MainStairOpeningRailPost%02d" % i, post_positions[i], Vector3(2.6, 8.0, 2.6), rail_color.darkened(0.08), false)
		_tag_stairwell_opening_piece(post)

func _add_guardrail_segment(root: Node3D, parent: Node3D, node_name: String, position: Vector3, size: Vector3, color: Color) -> void:
	var rail := _add_box(root, parent, node_name, position, size, color, false)
	_tag_stairwell_opening_piece(rail)

func _tag_stairwell_opening_piece(node: Node) -> void:
	if node == null:
		return
	node.set_meta("stairwell_opening_part", true)
	node.set_meta("vertical_link_id", "MainStairEntryToUpperHall")
	node.set_meta("asset_role", "upper_floor_stairwell_guardrail")
	node.set_meta("collision_policy", "visual_guardrail_no_gameplay_collision")
	node.set_meta("route_clearance", "outside_route_corridor")
	node.set_meta("scale_contract_id", SCALE_CONTRACT_ID)

func _add_attic_interior(root: Node3D, parent: Node3D) -> void:
	parent.set_meta("plan_role", "Popper toy-built attic route inside measured Dutch gambrel roof volume; exterior gables and roof are owned by Roof")
	var finishes := _add_child_holder(root, parent, "RoomFinishes", "attic deck, high-ramp staging, rafters, and Popper storage dressing")
	var walls := _add_child_holder(root, parent, "InteriorPartitions", "contract-generated attic knee/storage partitions only")
	_add_room_floor(root, finishes, "AtticDeck", Vector3(-50, 103, 12.5), Vector3(230, 2, 215), Color(0.45, 0.33, 0.22))
	_add_room_floor(root, finishes, "AtticStorageZone", Vector3(-50, 104, 12.5), Vector3(202, 1.2, 190), Color(0.48, 0.36, 0.24))
	_add_interior_partitions_from_schedule(root, walls, "attic", Color(0.34, 0.27, 0.21))
	var clearance_marker := Node3D.new()
	clearance_marker.name = "AtticHumanClearanceMarker"
	clearance_marker.transform.origin = Vector3(-50, 119, 12)
	clearance_marker.set_meta("validation_only", true)
	clearance_marker.set_meta("shape", "box")
	clearance_marker.set_meta("size", Vector3(82, 30, 6))
	clearance_marker.set_meta("human_walkable_clearance_ft", 7.5)
	clearance_marker.set_meta("reason", "attic central clearance audit helper; should not render as visible attic geometry")
	finishes.add_child(clearance_marker)
	clearance_marker.owner = root
	_add_box(root, finishes, "AtticRafterLeftA", Vector3(-150, 124, 12), Vector3(3, 4, 218), Color(0.20, 0.14, 0.10), false, 0, Vector3(0, 0, -26))
	_add_box(root, finishes, "AtticRafterRightA", Vector3(50, 124, 12), Vector3(3, 4, 218), Color(0.20, 0.14, 0.10), false, 0, Vector3(0, 0, 26))
	_add_box(root, finishes, "AtticRidgeBeamInterior", Vector3(-55, 154, 12), Vector3(5, 4, 218), Color(0.18, 0.12, 0.08), false)
	_add_box(root, finishes, "PopperHighRampLaunchDeck", Vector3(-122, 108, -50), Vector3(50, 7, 30), Color(0.42, 0.22, 0.10), false, 0.0, Vector3.ZERO, _route_infrastructure_provenance("Attic", "popper_high_ramp", "PopperHighRampLaunchDeck", "launch deck beside the Popper attic high-ramp route", "ValidationCameras/AtticRampSideProfileCamera"))
	_add_box(root, finishes, "PopperHighRampLaunchDeckEdgeLeft", Vector3(-122, 112.2, -65), Vector3(52, 2.2, 2.2), Color(0.18, 0.10, 0.06), false, 0.0, Vector3.ZERO, _route_infrastructure_provenance("Attic", "popper_high_ramp", "PopperHighRampLaunchDeckEdgeLeft", "dark edge strip makes the launch deck read as authored toy-racing infrastructure", "ValidationCameras/AtticRampSideProfileCamera"))
	_add_box(root, finishes, "PopperHighRampLaunchDeckEdgeRight", Vector3(-122, 112.2, -35), Vector3(52, 2.2, 2.2), Color(0.18, 0.10, 0.06), false, 0.0, Vector3.ZERO, _route_infrastructure_provenance("Attic", "popper_high_ramp", "PopperHighRampLaunchDeckEdgeRight", "dark edge strip makes the launch deck read as authored toy-racing infrastructure", "ValidationCameras/AtticRampSideProfileCamera"))
	_add_box(root, finishes, "PopperHighRampLandingDeck", Vector3(28, 116, 46), Vector3(54, 9, 34), Color(0.46, 0.26, 0.12), false, 0.0, Vector3.ZERO, _route_infrastructure_provenance("Attic", "popper_high_ramp", "PopperHighRampLandingDeck", "landing deck beside the Popper attic high-ramp route", "ValidationCameras/AtticRampSideProfileCamera"))
	_add_box(root, finishes, "PopperHighRampLandingDeckEdgeLeft", Vector3(28, 121.2, 29), Vector3(56, 2.4, 2.4), Color(0.18, 0.10, 0.06), false, 0.0, Vector3.ZERO, _route_infrastructure_provenance("Attic", "popper_high_ramp", "PopperHighRampLandingDeckEdgeLeft", "dark edge strip makes the landing deck read as authored toy-racing infrastructure", "ValidationCameras/AtticRampSideProfileCamera"))
	_add_box(root, finishes, "PopperHighRampLandingDeckEdgeRight", Vector3(28, 121.2, 63), Vector3(56, 2.4, 2.4), Color(0.18, 0.10, 0.06), false, 0.0, Vector3.ZERO, _route_infrastructure_provenance("Attic", "popper_high_ramp", "PopperHighRampLandingDeckEdgeRight", "dark edge strip makes the landing deck read as authored toy-racing infrastructure", "ValidationCameras/AtticRampSideProfileCamera"))
	_add_box(root, finishes, "PopperBankedCardboardRamp", Vector3(-46, 112, -2), Vector3(128, 4, 24), Color(0.72, 0.42, 0.18), false, 26.0, Vector3.ZERO, _route_infrastructure_provenance("Attic", "popper_high_ramp", "PopperBankedCardboardRamp", "banked cardboard ramp is toy-racing route infrastructure, not a house circulation stair", "ValidationCameras/AtticRampSideProfileCamera"))
	_add_box(root, finishes, "PopperRafterGateA", Vector3(-142, 122, 68), Vector3(6, 28, 6), Color(0.16, 0.10, 0.06), false)
	_add_box(root, finishes, "PopperRafterGateB", Vector3(36, 120, -34), Vector3(6, 20, 6), Color(0.16, 0.10, 0.06), false)
	_add_box(root, finishes, "AtticTrunkStack", Vector3(-84, 110, 84), Vector3(44, 12, 18), Color(0.30, 0.18, 0.10), false)
	_add_box(root, finishes, "PopperCardboardGuardWall", Vector3(22, 111, -72), Vector3(62, 14, 20), Color(0.58, 0.42, 0.24), false, 0.0, Vector3.ZERO, _route_infrastructure_provenance("Attic", "popper_high_ramp", "PopperCardboardGuardWall", "cardboard guard wall blocks the non-playable side of the attic ramp corridor without entering the route swept volume", "ValidationCameras/AtticRampSideProfileCamera"))

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
	parent.set_meta("style_contract", "large residential Dutch Colonial suburban house: broad gambrel roof, 10 ft floor clearances, ordered front windows, strong porch entry, practical garage/service side, warm siding, cream trim, and toy-racer-scaled doggie door at the rear deck")
	parent.set_meta("shell_ownership", "single authoritative exterior shell; stage/floor holders may not create exterior walls, gables, roof planes, fascia, exterior openings, or foundation collision")
	var siding := Color(0.55, 0.48, 0.39)
	var siding_shadow := Color(0.43, 0.37, 0.31)
	var trim := Color(0.88, 0.82, 0.67)
	var stone := Color(0.42, 0.39, 0.34)
	_add_box(root, parent, "ExteriorFoundationFrontSkirt", Vector3(10, 3.0, 145), Vector3(430, 6, 8), stone, false)
	_add_box(root, parent, "ExteriorFoundationBackSkirt", Vector3(-55, 3.0, -130), Vector3(290, 6, 8), stone, false, 0.0, Vector3.ZERO, _provenance("ExteriorShell", "foundation_perimeter", "back_foundation_skirt", "PLAN_CONTRACT.house_footprint.primary_back_wall", "back foundation skirt is clipped to the actual main-house rear wall run instead of the whole-house bounding box", "ExteriorBackWallWest/ExteriorBackPatioHeader", "back foundation face z=-130", "x", Vector3(-200, 0, -130), Vector3(90, 0, -130), ["rear wall foundation contact", "corner overlap tolerance"], ["garage void", "yard/deck void", "overlong broad bar"], "resize or split when the rear wall footprint changes", "test_home_yard_exterior_long_members_are_clipped_to_owner_runs", "ValidationCameras/BackyardDoggieDoorCamera"))
	_add_box(root, parent, "ExteriorFoundationWestSkirt", Vector3(-200, 3.0, 7.5), Vector3(8, 6, 285), stone, false)
	_add_box(root, parent, "ExteriorFoundationEastSkirt", Vector3(220, 3.0, 42.5), Vector3(8, 6, 205), stone, false)
	for column in [{"name": "Left", "x": -120.0}, {"name": "Right", "x": 20.0}]:
		var column_x := float(column["x"])
		var column_name := str(column["name"])
		_add_box(root, parent, "FrontPorchTaperedColumn%sBase" % column_name, Vector3(column_x, 8, 160), Vector3(12, 16, 12), stone, false)
		_add_box(root, parent, "FrontPorchTaperedColumn%sShaft" % column_name, Vector3(column_x, 27, 160), Vector3(7, 32, 7), trim, false)
	_add_box(root, parent, "FrontPorchBeam", Vector3(-50, 44, 160), Vector3(190, 8, 10), trim.darkened(0.08), false)
	_add_box(root, parent, "FrontPorchRailLeft", Vector3(-150, 15, 162), Vector3(4, 18, 32), trim, false)
	_add_box(root, parent, "FrontPorchRailRight", Vector3(50, 15, 162), Vector3(4, 18, 32), trim, false)
	_add_box(root, parent, "FrontDoorDeepJambLeft", Vector3(-86, 20, 146), Vector3(5, 40, 8), trim, false)
	_add_box(root, parent, "FrontDoorDeepJambRight", Vector3(-14, 20, 146), Vector3(5, 40, 8), trim, false)
	_add_box(root, parent, "FrontDoorCenterMullionLeft", Vector3(-66, 20, 147.4), Vector3(3, 38, 4), trim.darkened(0.06), false)
	_add_box(root, parent, "FrontDoorCenterMullionRight", Vector3(-34, 20, 147.4), Vector3(3, 38, 4), trim.darkened(0.06), false)
	_add_box(root, parent, "FrontDoorLintelHeader", Vector3(-50, 42, 146), Vector3(78, 6, 8), trim, false)
	_add_box(root, parent, "FrontEntryPorchLightLeft", Vector3(-82, 30, 150), Vector3(4, 8, 3), Color(1.0, 0.82, 0.42), false)
	_add_box(root, parent, "FrontEntryPorchLightRight", Vector3(-18, 30, 150), Vector3(4, 8, 3), Color(1.0, 0.82, 0.42), false)
	_add_box(root, parent, "FrontEntryHouseNumberPlaque", Vector3(-50, 48, 149), Vector3(28, 5, 2), Color(0.12, 0.10, 0.08), false)
	_add_box(root, parent, "DutchFrontEntrySidingField", Vector3(-50, 53, 148.7), Vector3(78, 18, 1.6), siding, false, 0.0, Vector3.ZERO, _front_facade_provenance("DutchFrontEntrySidingField", "front entry siding field fills the bay between the door header and upper-window band without leaving a daylight hole into the house"))
	_add_front_facade_battens(root, parent, trim.darkened(0.08))
	_add_box(root, parent, "GarageFrontSidingField", Vector3(155, 43, 148.7), Vector3(126, 14, 1.6), siding_shadow, false, 0.0, Vector3.ZERO, _front_facade_provenance("GarageFrontSidingField", "garage front siding field is clipped to the wall band above the garage door so it cannot cover the door opening"))
	_add_garage_facade_battens(root, parent, trim.darkened(0.10))
	_add_box(root, parent, "GarageDoorTrimHeader", Vector3(155, 31, 147), Vector3(98, 6, 8), trim, false)
	_add_box(root, parent, "GarageDoorTrimLeft", Vector3(109, 16, 147), Vector3(5, 30, 8), trim, false)
	_add_box(root, parent, "GarageDoorTrimRight", Vector3(201, 16, 147), Vector3(5, 30, 8), trim, false)
	for i in range(4):
		_add_box(root, parent, "GarageDoorHorizontalPanel%02d" % i, Vector3(155, 7 + i * 6, 148.4), Vector3(78, 1.2, 1), Color(0.18, 0.17, 0.15), false)
	_add_window(root, parent, "UpperFrontBedroomWindow", Vector3(-120, 75, 148.6), Vector3(40, 22, 1.0))
	_add_window(root, parent, "UpperFrontGlamWindow", Vector3(42, 75, 148.6), Vector3(40, 22, 1.0))
	_add_window(root, parent, "GambrelAtticFrontVentWindow", Vector3(-50, 140, 148.6), Vector3(34, 18, 1.0))
	_add_box(root, parent, "FrontGutterRun", Vector3(-55, 103, 159), Vector3(328, 3, 4), Color(0.12, 0.12, 0.11), false)
	_add_box(root, parent, "BackGutterRun", Vector3(-55, 103, -144), Vector3(328, 3, 4), Color(0.12, 0.12, 0.11), false)
	_add_box(root, parent, "FrontDownspoutWest", Vector3(-202, 51, 158), Vector3(3, 102, 3), Color(0.10, 0.10, 0.10), false)
	_add_box(root, parent, "FrontDownspoutEast", Vector3(88, 51, 158), Vector3(3, 102, 3), Color(0.10, 0.10, 0.10), false)
	_add_box(root, parent, "BackDownspoutWest", Vector3(-202, 51, -143), Vector3(3, 102, 3), Color(0.10, 0.10, 0.10), false)
	_add_box(root, parent, "BackDownspoutEast", Vector3(88, 51, -143), Vector3(3, 102, 3), Color(0.10, 0.10, 0.10), false)
	_add_box(root, parent, "ChimneyMasonryStack", Vector3(-174, 111, -28), Vector3(20, 54, 18), Color(0.35, 0.20, 0.15), false)
	_add_box(root, parent, "ChimneyCap", Vector3(-174, 141, -28), Vector3(26, 6, 24), Color(0.16, 0.13, 0.12), false)
	_add_box(root, parent, "ServiceElectricMeter", Vector3(222, 22, 22), Vector3(1.2, 14, 10), Color(0.14, 0.16, 0.16), false)
	_add_box(root, parent, "ServiceUtilityPanel", Vector3(222, 16, -10), Vector3(1.2, 18, 14), Color(0.22, 0.24, 0.23), false)

func _add_exterior_wall_system(root: Node3D, parent: Node3D) -> void:
	var exterior := Color(0.54, 0.49, 0.42)
	_add_wall_z(root, parent, "ExteriorFrontWallLeft", 145, -200, -90, exterior, true, 0.0, 104.0)
	_add_wall_z(root, parent, "ExteriorFrontWallEntryHeader", 145, -10, 90, exterior, true, 0.0, 104.0)
	_add_wall_z(root, parent, "ExteriorFrontGarageWall", 145, 90, 220, exterior, true, 0.0, 52.0)
	_add_wall_z(root, parent, "ExteriorBackWallWest", -130, -200, -55, exterior, true, 0.0, 104.0)
	_add_wall_z(root, parent, "ExteriorBackPatioHeader", -130, -55, 90, exterior, true, 22.0, 82.0)
	_add_rear_patio_lower_infill(root, parent, exterior)
	_add_wall_z(root, parent, "ExteriorBackGarageWall", -60, 90, 220, exterior, true, 0.0, 52.0)
	_add_wall_x(root, parent, "ExteriorWestWall", -200, -130, 145, exterior, true, 0.0, 104.0)
	_add_wall_x(root, parent, "ExteriorEastUpperWallOverGarage", 90, -60, 145, exterior, true, 52.0, 52.0)
	_add_wall_x(root, parent, "ExteriorEastGarageWall", 220, -60, 145, exterior, true, 0.0, 52.0, _provenance("ExteriorShell", "garage_exterior_wall", "bearing_exterior_wall", "PLAN_CONTRACT.house_footprint.garage", "east garage wall defines the garage/service exterior side and supports the lower garage roof eave", "HouseFoundationEastPlinth and GarageCrossGable roof", "east exterior wall plane", "z", Vector3(220, 0, -60), Vector3(220, 52, 145), ["ExteriorEastGarageGableInfill", "windows/opening trim"], ["interior upper-floor deck", "unowned roof closure"], "delete only if garage footprint changes and replacement wall/infill is generated", "test_home_yard_exterior_garage_side_infill", "ValidationCameras/GarageServiceSeamCamera"))
	_add_gable_wall_x(root, parent, "ExteriorEastGarageGableInfill", 220, -68, 159, 52, garage_center_z(), 76, exterior.lightened(0.04), _provenance("ExteriorShell", "garage_exterior_wall", "gable_cheek_infill", "PLAN_CONTRACT.house_footprint.garage + roof_contract.garage_cross_gable", "gable infill closes the visible siding above ExteriorEastGarageWall up to the garage cross-gable roof instead of leaving the service-side wall open", "ExteriorEastGarageWall and GarageCrossGableFrontPlane/GarageCrossGableBackPlane", "east garage gable end plane", "z", Vector3(220, 52, -68), Vector3(220, 52, 159), ["ExteriorEastGarageWall top edge", "garage roof planes"], ["attic route", "main-house side wall"], "delete if a sourced garage gable wall asset replaces it", "test_home_yard_exterior_garage_side_infill", "ValidationCameras/GarageServiceSeamCamera"))
	_add_wall_x(root, parent, "ExteriorMainGarageStepWall", 90, -130, -60, exterior.darkened(0.04), true, 0.0, 104.0)

func _front_facade_provenance(node_name: String, why_exists: String) -> Dictionary:
	return _provenance(
		"ExteriorShell",
		"front_facade_board_and_batten",
		"facade_detail",
		"PLAN_CONTRACT.front_facade_opening_schedule + whole_unit_visual_review_contract",
		why_exists,
		"ExteriorFrontWallLeft/ExteriorFrontWallEntryHeader/ExteriorFrontGarageWall",
		"front exterior wall face z=148.7",
		"x",
		"%s opening-safe start anchor" % node_name,
		"%s opening-safe end anchor" % node_name,
		["front wall face", "opening trim returns", "siding reveal offset"],
		["window glass AABB", "door/sidelight AABB", "garage door AABB", "floating proud wall patch"],
		"delete or split if it intersects an opening or no longer aligns to the front wall face",
		"test_home_yard_front_facade_details_respect_openings_and_wall_plane",
		"ValidationCameras/FrontPorchCloseupCamera"
	)

func _add_front_facade_battens(root: Node3D, parent: Node3D, color: Color) -> void:
	var specs := [
		{"name": "FrontFacadeBatten00", "position": Vector3(-198, 52, 148.9), "size": Vector3(2.2, 104, 2.0), "why": "left front corner batten is outside all front openings and closes the main wall corner board rhythm"},
		{"name": "FrontFacadeBatten01", "position": Vector3(-94, 58, 148.9), "size": Vector3(2.2, 32, 2.0), "why": "short entry-side batten sits outside the widened front entry assembly without crossing glass"},
		{"name": "FrontFacadeBatten02", "position": Vector3(-70, 82, 148.9), "size": Vector3(2.2, 18, 2.0), "why": "upper entry batten is clipped above the sidelight/header zone so it reads as siding rhythm rather than a window blocker"},
		{"name": "FrontFacadeBatten03", "position": Vector3(-30, 82, 148.9), "size": Vector3(2.2, 18, 2.0), "why": "upper entry batten is clipped above the right sidelight/header zone and below the porch eave"},
		{"name": "FrontFacadeBatten04", "position": Vector3(78, 58, 148.9), "size": Vector3(2.2, 32, 2.0), "why": "right entry batten stays between the upper glam window and garage transition"},
		{"name": "FrontFacadeBatten05", "position": Vector3(90, 52, 148.9), "size": Vector3(2.2, 104, 2.0), "why": "front facade batten marks the transition from main house wall to garage wall without crossing an opening"},
		{"name": "FrontFacadeBatten06", "position": Vector3(-50, 94, 148.9), "size": Vector3(2.2, 18, 2.0), "why": "short center batten fills the wall field above the entry and between upper windows"},
		{"name": "FrontFacadeBatten07", "position": Vector3(104, 38, 148.9), "size": Vector3(2.2, 28, 2.0), "why": "garage-left batten terminates above the garage door trim instead of crossing the garage opening"},
	]
	for spec in specs:
		_add_box(root, parent, str(spec["name"]), spec["position"], spec["size"], color, false, 0.0, Vector3.ZERO, _front_facade_provenance(str(spec["name"]), str(spec["why"])))

func _add_garage_facade_battens(root: Node3D, parent: Node3D, color: Color) -> void:
	var specs := [
		{"name": "GarageFacadeBattenLeft", "position": Vector3(96, 28, 148.9), "size": Vector3(2.2, 48, 2.0), "why": "garage left corner batten is outside the overhead door opening and flush to the front garage wall"},
		{"name": "GarageFacadeBattenRight", "position": Vector3(214, 28, 148.9), "size": Vector3(2.2, 48, 2.0), "why": "garage right corner batten is outside the overhead door opening and closes the garage facade rhythm"},
		{"name": "GarageFacadeBattenUpperLeft", "position": Vector3(126, 43, 148.9), "size": Vector3(2.2, 14, 2.0), "why": "short garage upper batten sits above the garage door header and does not cross the moving door panels"},
		{"name": "GarageFacadeBattenUpperCenter", "position": Vector3(155, 43, 148.9), "size": Vector3(2.2, 14, 2.0), "why": "short garage upper batten adds board-and-batten rhythm only in the wall field above the garage door"},
		{"name": "GarageFacadeBattenUpperRight", "position": Vector3(184, 43, 148.9), "size": Vector3(2.2, 14, 2.0), "why": "short garage upper batten stops above the garage door trim and remains on the wall field"},
	]
	for spec in specs:
		_add_box(root, parent, str(spec["name"]), spec["position"], spec["size"], color, false, 0.0, Vector3.ZERO, _front_facade_provenance(str(spec["name"]), str(spec["why"])))

func _rear_facade_provenance(node_name: String, why_exists: String) -> Dictionary:
	return _provenance(
		"ExteriorShell",
		"rear_deck_opening_assembly",
		"rear_facade_infill_or_opening_detail",
		"PLAN_CONTRACT.back_deck_free_drive + generated-scene-provenance-auditor screenshot review",
		why_exists,
		"ExteriorBackPatioHeader and back deck threshold system",
		"back exterior wall face z=-133.0",
		"x",
		"%s rear opening-safe start anchor" % node_name,
		"%s rear opening-safe end anchor" % node_name,
		["back wall face", "patio door return", "doggie door return", "deck threshold"],
		["patio door AABB", "doggie door AABB", "floating loose panel", "yellow interior leak"],
		"delete or split if it overlaps a rear opening or leaves the lower rear wall band visually open",
		"test_home_yard_back_facade_openings_are_provenance_audited",
		"ValidationCameras/BackyardDoggieDoorCamera"
	)

func _add_rear_patio_lower_infill(root: Node3D, parent: Node3D, color: Color) -> void:
	var specs := [
		{"name": "RearPatioLowerWallLeftInfill", "position": Vector3(-34, 11, -130), "size": Vector3(42, 22, 6), "why": "lower rear wall infill closes the broad yellow leak left of the playroom patio door"},
		{"name": "RearPatioLowerWallBetweenDoorAndDoggie", "position": Vector3(51, 11, -130), "size": Vector3(10, 22, 6), "why": "narrow rear wall post separates the playroom patio door from the doggie-door opening"},
		{"name": "RearPatioLowerWallRightInfill", "position": Vector3(85.5, 11, -130), "size": Vector3(9, 22, 6), "why": "right rear wall return closes the doggie-door bay before the garage/service wall step"},
	]
	for spec in specs:
		_add_box(root, parent, str(spec["name"]), spec["position"], spec["size"], color, true, 0.0, Vector3.ZERO, _rear_facade_provenance(str(spec["name"]), str(spec["why"])))

func _add_opening_assemblies(root: Node3D, parent: Node3D) -> void:
	parent.set_meta("plan_role", "door/window/threshold schedule from floor-plan contract")
	var trim := Color(0.88, 0.82, 0.67)
	_add_box(root, parent, "FrontDoorPanel", Vector3(-50, 17, 146.6), Vector3(28, 34, 2.4), Color(0.24, 0.13, 0.07), false)
	_add_box(root, parent, "FrontDoorGlass", Vector3(-50, 24, 147.9), Vector3(16, 14, 0.6), Color(0.45, 0.72, 0.88, 0.45), false)
	_add_box(root, parent, "FrontEntryThresholdStone", Vector3(-50, 2, 151), Vector3(82, 4, 10), Color(0.46, 0.43, 0.37), false)
	_add_box(root, parent, "FrontEntrySidelightLeft", Vector3(-76, 20, 148), Vector3(10, 32, 2), Color(0.50, 0.75, 0.88, 0.55), false)
	_add_box(root, parent, "FrontEntrySidelightRight", Vector3(-24, 20, 148), Vector3(10, 32, 2), Color(0.50, 0.75, 0.88, 0.55), false)
	_add_window(root, parent, "DiningFrontWindow", Vector3(-152, 25, 148), Vector3(48, 22, 1.0))
	_add_window(root, parent, "LivingFrontWindow", Vector3(50, 25, 148.6), Vector3(46, 22, 1.0))
	_add_window(root, parent, "KitchenGardenWindow", Vector3(-200.5, 24, -58), Vector3(1.0, 22, 52))
	_add_box(root, parent, "KitchenPatioDoorFrame", Vector3(-128, 22, -132), Vector3(66, 42, 5), trim, false)
	_add_box(root, parent, "KitchenPatioDoorGlass", Vector3(-128, 22, -135), Vector3(50, 32, 1.2), Color(0.48, 0.72, 0.86, 0.45), false)
	_add_box(root, parent, "PlayroomPatioDoorFrame", Vector3(20, 22, -132), Vector3(48, 42, 5), trim, false, 0.0, Vector3.ZERO, _rear_facade_provenance("PlayroomPatioDoorFrame", "playroom patio door frame fills its own rear opening and must not share space with the doggie door"))
	_add_box(root, parent, "PlayroomPatioDoorGlass", Vector3(20, 22, -135), Vector3(36, 32, 1.2), Color(0.48, 0.72, 0.86, 0.45), false, 0.0, Vector3.ZERO, _rear_facade_provenance("PlayroomPatioDoorGlass", "playroom patio glass is contained inside the patio frame and backed by a real rear opening"))
	_add_box(root, parent, "OversizedDoggieDoorFrame", Vector3(68, 10, -132), Vector3(24, 20, 5), trim.darkened(0.05), false, 0.0, Vector3.ZERO, _rear_facade_provenance("OversizedDoggieDoorFrame", "oversized toy-racer doggie door has its own small bay beside the playroom patio door instead of overlapping it"))
	_add_box(root, parent, "OversizedDoggieDoorFlap", Vector3(68, 9, -135), Vector3(16, 14, 1.2), Color(0.10, 0.08, 0.07, 0.62), false, 0.0, Vector3.ZERO, _rear_facade_provenance("OversizedDoggieDoorFlap", "dark flap sits within the doggie-door frame and reads as a route/freedrive portal instead of a loose exterior panel"))
	_add_box(root, parent, "GarageDoorPanel", Vector3(155, 14, 148), Vector3(86, 28, 2.0), Color(0.32, 0.30, 0.27), false)
	_add_box(root, parent, "GarageHouseServiceDoor", Vector3(92, 14, 68), Vector3(4, 28, 20), Color(0.22, 0.16, 0.10), false)
	_add_box(root, parent, "AtticAccessHatchFrame", Vector3(18, 106, -72), Vector3(52, 5, 30), trim.darkened(0.20), false)

func _add_porch_deck_system(root: Node3D, parent: Node3D) -> void:
	parent.set_meta("plan_role", "front porch and backyard deck threshold system")
	_add_box(root, parent, "FrontPorchDeck", Vector3(-50, 1.2, 162.5), Vector3(210, 3.0, 35), Color(0.44, 0.35, 0.26), true)
	_add_box(root, parent, "FrontPorchWelcomeMat", Vector3(-50, 3.0, 150), Vector3(38, 0.6, 16), Color(0.18, 0.12, 0.08), false)
	_add_box(root, parent, "FrontPorchStepLower", Vector3(-50, 0.2, 184), Vector3(220, 1.5, 12), Color(0.50, 0.45, 0.38), true)
	_add_box(root, parent, "FrontPorchStepUpper", Vector3(-50, 1.8, 174), Vector3(204, 1.8, 10), Color(0.56, 0.50, 0.42), true)
	_add_box(root, parent, "BackDeckLanding", Vector3(-47.5, 1.5, -152.5), Vector3(245, 3, 45), Color(0.46, 0.35, 0.24), true)
	_add_box(root, parent, "BackDeckStairRun", Vector3(-47.5, 0.4, -184), Vector3(190, 1.6, 24), Color(0.54, 0.43, 0.30), true)
	for i in range(5):
		_add_box(root, parent, "BackDeckBoard%02d" % i, Vector3(-145 + i * 48, 3.2, -152.5), Vector3(2, 1, 45), Color(0.28, 0.20, 0.14), false)

func _add_garage_service_system(root: Node3D, parent: Node3D) -> void:
	parent.set_meta("plan_role", "garage/service zone connected to driveway and house")
	_add_box(root, parent, "GarageToolBench", Vector3(196, 8, -28), Vector3(28, 16, 14), Color(0.28, 0.20, 0.13), false)
	_add_box(root, parent, "GarageStorageShelves", Vector3(106, 12, -48), Vector3(32, 24, 12), Color(0.24, 0.22, 0.20), false)
	_add_box(root, parent, "GarageWaterHeater", Vector3(198, 16, 34), Vector3(16, 32, 16), Color(0.38, 0.42, 0.44), false)
	_add_box(root, parent, "ServiceHvacPad", Vector3(242, 1, 8), Vector3(26, 2, 26), Color(0.44, 0.44, 0.40), false)
	_add_box(root, parent, "ServiceHvacUnit", Vector3(242, 12, 8), Vector3(22, 22, 22), Color(0.24, 0.28, 0.28), false)

func _add_roof_system(root: Node3D, parent: Node3D) -> void:
	parent.set_meta("plan_role", "measured roof/attic companion plan")
	parent.set_meta("massing_contract", "single Dutch Colonial gambrel roof over the primary house body with subordinate one-story garage cross-gable and porch hood; Popper attic is inside the gambrel envelope with 7.5 ft human-walkable central clearance and no stacked attic box")
	var garage_roof_z0 := -68.0
	var garage_roof_z1 := 159.0
	var garage_ridge_z := (garage_roof_z0 + garage_roof_z1) * 0.5
	parent.set_meta("roof_contract", {
		"dutch_gambrel": {"span_axis": "x", "eave_y": 104.0, "break_y": 136.0, "ridge_y": 164.0, "left_break_x": -155.0, "right_break_x": 45.0, "ridge_x": -55.0, "overhang": 14.0, "attic_floor_y": 104.0, "attic_route_max_y": 116.0, "human_walkable_clearance": 30.0},
		"garage_cross_gable": {"span_axis": "z", "eave_y": 52.0, "ridge_y": 76.0, "ridge_z": garage_ridge_z, "footprint_min": Vector3(90.0, 0.0, garage_roof_z0), "footprint_max": Vector3(228.0, 76.0, garage_roof_z1), "overhang": 8.0},
		"porch_gable": {"span_axis": "z", "eave_y": 44.0, "ridge_y": 60.0, "ridge_z": 164.0, "overhang": 7.0},
	})
	var roof := Color(0.23, 0.18, 0.15)
	var shadow := Color(0.16, 0.13, 0.12)
	var siding := Color(0.55, 0.49, 0.40)
	_add_roof_plane_x(root, parent, "DutchGambrelLowerLeftPlane", -214, -155, -144, 159, 104, 136, roof.darkened(0.02))
	_add_roof_plane_x(root, parent, "DutchGambrelUpperLeftPlane", -155, -55, -144, 159, 136, 164, roof)
	_add_roof_plane_x(root, parent, "DutchGambrelUpperRightPlane", -55, 45, -144, 159, 164, 136, roof)
	_add_roof_plane_x(root, parent, "DutchGambrelLowerRightPlane", 45, 104, -144, 159, 136, 104, roof.darkened(0.02))
	_add_box(root, parent, "DutchGambrelRidgeCap", Vector3(-55, 165, 7.5), Vector3(8, 5, 303), shadow, false)
	_add_box(root, parent, "DutchGambrelLeftBreakCap", Vector3(-155, 137, 7.5), Vector3(8, 4, 303), shadow.lightened(0.04), false)
	_add_box(root, parent, "DutchGambrelRightBreakCap", Vector3(45, 137, 7.5), Vector3(8, 4, 303), shadow.lightened(0.04), false)
	_add_gambrel_gable_wall_z(root, parent, "DutchGambrelFrontGableWall", 148.0, -200, 90, 92, 104, 136, 164, siding.lightened(0.02))
	_add_gambrel_gable_wall_z(root, parent, "DutchGambrelBackGableWall", -133.0, -200, 90, 92, 104, 136, 164, siding.darkened(0.06))
	_add_roof_plane_z(root, parent, "GarageCrossGableFrontPlane", garage_ridge_z, garage_roof_z1, 90, 228, 76, 52, roof.darkened(0.02), _provenance("Roof", "garage_cross_gable", "roof_plane", "PLAN_CONTRACT.roof_contract.garage_cross_gable", "front garage roof plane slopes from the centered garage ridge to the front eave and terminates directly into the upper garage side wall without a visible helper bar", "ExteriorEastUpperWallOverGarage, ExteriorFrontGarageWall, and ExteriorEastGarageWall", "front/east garage wall top plates and upper sidewall edge", "z", Vector3(90, 76, garage_ridge_z), Vector3(228, 52, garage_roof_z1), ["GarageCrossGableRidge", "ExteriorEastUpperWallOverGarage sidewall contact"], ["main attic playable volume", "unowned wall closure", "floating sidewall flashing bar"], "delete if garage roof footprint or centered ridge contract changes", "test_home_yard_garage_roof_sidewall_contact", "ValidationCameras/GarageServiceSeamCamera"))
	_add_roof_plane_z(root, parent, "GarageCrossGableBackPlane", garage_roof_z0, garage_ridge_z, 90, 228, 52, 76, roof.darkened(0.02), _provenance("Roof", "garage_cross_gable", "roof_plane", "PLAN_CONTRACT.roof_contract.garage_cross_gable", "back garage roof plane slopes from the back eave to the centered garage ridge and terminates directly into the upper garage side wall without a visible helper bar", "ExteriorEastUpperWallOverGarage, ExteriorMainGarageStepWall, ExteriorBackGarageWall, and ExteriorEastGarageWall", "back/east garage wall top plates and upper sidewall edge", "z", Vector3(90, 52, garage_roof_z0), Vector3(228, 76, garage_ridge_z), ["GarageCrossGableRidge", "ExteriorEastUpperWallOverGarage sidewall contact", "ExteriorMainGarageStepWall short return"], ["main attic playable volume", "unowned wall closure", "floating sidewall flashing bar"], "delete if garage roof footprint or centered ridge contract changes", "test_home_yard_garage_roof_sidewall_contact", "ValidationCameras/GarageServiceSeamCamera"))
	_add_box(root, parent, "GarageCrossGableRidge", Vector3(159, 77, garage_ridge_z), Vector3(138, 5, 7), shadow, false, 0.0, Vector3.ZERO, _provenance("Roof", "garage_cross_gable", "ridge_cap", "PLAN_CONTRACT.roof_contract.garage_cross_gable", "ridge cap marks the centered high line of the garage cross gable", "GarageCrossGableFrontPlane and GarageCrossGableBackPlane", "shared ridge edge", "x", Vector3(90, 77, garage_ridge_z), Vector3(228, 77, garage_ridge_z), ["front/back garage roof planes"], ["main gambrel roof plane AABB", "garage wall interior"], "delete if the roof module is removed; recenter if garage footprint changes", "test_home_yard_garage_roof_ridge_centering", "ValidationCameras/GarageServiceSeamCamera"))
	_add_roof_plane_z(root, parent, "FrontPorchGableFrontPlane", 164, 187, -162, 62, 60, 44, roof.darkened(0.04))
	_add_roof_plane_z(root, parent, "FrontPorchGableBackPlane", 145, 164, -162, 62, 44, 60, roof.darkened(0.04))
	_add_box(root, parent, "FrontPorchGableRidge", Vector3(-50, 61, 164), Vector3(224, 5, 6), shadow, false)
	_add_box(root, parent, "FrontPorchRoofFascia", Vector3(-50, 45, 187), Vector3(232, 5, 5), shadow, false)
	_add_box(root, parent, "GambrelFrontEaveFascia", Vector3(-55, 105, 159), Vector3(328, 6, 6), shadow, false)
	_add_box(root, parent, "GambrelBackEaveFascia", Vector3(-55, 105, -144), Vector3(328, 6, 6), shadow, false)
	_add_box(root, parent, "GambrelWestRakeFascia", Vector3(-214, 105, 7.5), Vector3(6, 7, 303), shadow, false)
	_add_box(root, parent, "GambrelEastRakeFascia", Vector3(104, 105, 7.5), Vector3(6, 7, 303), shadow, false)
	_add_box(root, parent, "GambrelSoffitFront", Vector3(-55, 102, 154), Vector3(320, 4, 12), shadow.lightened(0.18), false)
	_add_box(root, parent, "GambrelSoffitBack", Vector3(-55, 102, -139), Vector3(320, 4, 12), shadow.lightened(0.12), false)

func _add_vertical_connectors(root: Node3D, parent: Node3D) -> void:
	parent.set_meta("plan_role", "architectural vertical circulation generated from floor_plan_contract.vertical_links")
	parent.set_meta("visible_asset_policy", "Measured floor-to-floor stair and ladder continuity is required; sourced stair props alone are visual references, not circulation proof.")
	parent.set_meta("vertical_circulation_contract", _vertical_circulation_contract())
	_add_main_stair_continuity_geometry(root, parent)
	_add_scene(root, parent, KENNEY_STEPS_PATH, Vector3(MAIN_STAIR_X, 0.10, MAIN_STAIR_LANDING_Z), 0.0, Vector3(20.0, 20.0, 20.0), "MainStairLowerFlightKenneySteps")
	_tag_vertical_link(parent.get_node_or_null("MainStairLowerFlightKenneySteps"), "MainStairEntryToUpperHall", "lower_flight", "main", "upper")
	_add_scene(root, parent, KENNEY_STEPS_PATH, Vector3(MAIN_STAIR_X, 26.10, MAIN_STAIR_LANDING_Z), 180.0, Vector3(20.0, 20.0, 20.0), "MainStairUpperFlightKenneySteps")
	_tag_vertical_link(parent.get_node_or_null("MainStairUpperFlightKenneySteps"), "MainStairEntryToUpperHall", "upper_flight", "main", "upper")
	_add_vertical_link_marker(root, parent, "MainStairUpperFloorOpening", "MainStairEntryToUpperHall", Vector3(MAIN_STAIR_X, 52.65, MAIN_STAIR_LANDING_Z), Vector3(36, 2, 40))
	_add_attic_ladder_continuity_geometry(root, parent)
	_add_scene(root, parent, KENNEY_STEPS_PATH, Vector3(24, 52.70, -54), -90.0, Vector3(14.0, 14.0, 14.0), "AtticPullDownStairKenneySteps")
	_tag_vertical_link(parent.get_node_or_null("AtticPullDownStairKenneySteps"), "AtticPullDownStairUpperHallToAttic", "pull_down_stair", "upper", "attic")
	_add_vertical_link_marker(root, parent, "AtticAccessHatchOpening", "AtticPullDownStairUpperHallToAttic", Vector3(24, 104.65, -54), Vector3(46, 2, 54))

func _vertical_circulation_contract() -> Dictionary:
	return {
		"scale_contract_id": SCALE_CONTRACT_ID,
		"continuity_required": true,
		"tolerance_units": 1.0,
		"main_stair": {
			"id": "MainStairEntryToUpperHall",
			"type": "switchback_residential_stair",
			"lower_floor_datum_y": MAIN_FLOOR_TOP_Y,
			"upper_floor_datum_y": UPPER_ROOM_FLOOR_TOP_Y,
			"total_rise_units": UPPER_ROOM_FLOOR_TOP_Y - MAIN_FLOOR_TOP_Y,
			"width_units": 24.0,
			"riser_height_units": (UPPER_ROOM_FLOOR_TOP_Y - MAIN_FLOOR_TOP_Y - 0.60) / 22.0,
			"tread_depth_units": 50.0 / 11.0,
			"route_exclusion": ["bedroom", "glam_closet"],
			"path_segments": [
				{"id": "lower_landing", "node": "MainStairLowerLandingSurface", "center": Vector3(MAIN_STAIR_X, MAIN_FLOOR_TOP_Y + 0.30, MAIN_STAIR_LANDING_Z), "size": Vector3(34, 0.6, 18)},
				{"id": "lower_flight", "node_prefix": "MainStairLowerFlightTread", "start": Vector3(MAIN_STAIR_X, MAIN_FLOOR_TOP_Y + 0.60, MAIN_STAIR_LOWER_Z), "end": Vector3(MAIN_STAIR_X, 26.625, MAIN_STAIR_UPPER_Z), "tread_count": 11},
				{"id": "switchback_landing", "node": "MainStairSwitchbackLandingSurface", "center": Vector3(MAIN_STAIR_X, 26.325, 116), "size": Vector3(34, 0.6, 24)},
				{"id": "upper_flight", "node_prefix": "MainStairUpperFlightTread", "start": Vector3(MAIN_STAIR_X, 26.625, MAIN_STAIR_UPPER_Z), "end": Vector3(MAIN_STAIR_X, UPPER_ROOM_FLOOR_TOP_Y, MAIN_STAIR_LOWER_Z), "tread_count": 11},
				{"id": "upper_landing", "node": "MainStairUpperLandingSurface", "center": Vector3(MAIN_STAIR_X, UPPER_ROOM_FLOOR_TOP_Y - 0.30, MAIN_STAIR_LANDING_Z), "size": Vector3(34, 0.6, 18)},
			],
			"opening_node": "MainStairUpperFloorOpening",
			"floor_assembly_shaft_void_bounds": {"min": MAIN_STAIR_SHAFT_MIN, "max": MAIN_STAIR_SHAFT_MAX},
			"floor_assembly_layers_cut": ["MainFloorTenFootCeilingPlane", "interstitial_gap", "UpperFloorDeck", "GlamDressing"],
			"opening_overlap_required": true,
			"continuous_path_verified": true,
			"validation_cameras": ["ValidationCameras/MainStairContinuityCamera", "ValidationCameras/UpperHallStairOpeningCamera"],
		},
		"attic_ladder": {
			"id": "AtticPullDownStairUpperHallToAttic",
			"type": "pull_down_ladder",
			"lower_floor_datum_y": UPPER_ROOM_FLOOR_TOP_Y,
			"upper_floor_datum_y": ATTIC_ROOM_FLOOR_TOP_Y,
			"total_rise_units": ATTIC_ROOM_FLOOR_TOP_Y - UPPER_ROOM_FLOOR_TOP_Y,
			"rung_spacing_units": 4.0,
			"path_segments": [
				{"id": "lower_landing", "node": "AtticPullDownLowerLandingSurface", "center": Vector3(24, UPPER_ROOM_FLOOR_TOP_Y - 0.30, -54), "size": Vector3(34, 0.6, 30)},
				{"id": "pull_down_ladder", "node_prefix": "AtticPullDownLadder", "start": Vector3(24, UPPER_ROOM_FLOOR_TOP_Y, -54), "end": Vector3(24, ATTIC_ROOM_FLOOR_TOP_Y, -54)},
				{"id": "attic_hatch_landing", "node": "AtticPullDownUpperLandingSurface", "center": Vector3(24, ATTIC_ROOM_FLOOR_TOP_Y - 0.30, -54), "size": Vector3(40, 0.6, 34)},
			],
			"opening_node": "AtticAccessHatchOpening",
			"opening_overlap_required": true,
			"continuous_path_verified": true,
			"validation_cameras": ["ValidationCameras/AtticPullDownContinuityCamera"],
		},
	}

func _add_main_stair_continuity_geometry(root: Node3D, parent: Node3D) -> void:
	var wood := Color(0.62, 0.42, 0.25)
	_add_stair_landing(root, parent, "MainStairLowerLandingSurface", "MainStairEntryToUpperHall", "lower_landing", "main", "upper", Vector3(MAIN_STAIR_X, MAIN_FLOOR_TOP_Y + 0.30, MAIN_STAIR_LANDING_Z), Vector3(34, 0.6, 18), wood.darkened(0.05))
	_add_stair_flight(root, parent, "MainStairLowerFlightTread", "MainStairEntryToUpperHall", Vector3(MAIN_STAIR_X, MAIN_FLOOR_TOP_Y + 0.60, MAIN_STAIR_LOWER_Z), Vector3(MAIN_STAIR_X, 26.625, MAIN_STAIR_UPPER_Z), 24.0, 11, wood)
	_add_stair_landing(root, parent, "MainStairSwitchbackLandingSurface", "MainStairEntryToUpperHall", "switchback_landing", "main", "upper", Vector3(MAIN_STAIR_X, 26.325, 116), Vector3(34, 0.6, 24), wood.darkened(0.08))
	_add_stair_flight(root, parent, "MainStairUpperFlightTread", "MainStairEntryToUpperHall", Vector3(MAIN_STAIR_X, 26.625, MAIN_STAIR_UPPER_Z), Vector3(MAIN_STAIR_X, UPPER_ROOM_FLOOR_TOP_Y, MAIN_STAIR_LOWER_Z), 24.0, 11, wood.lightened(0.03))
	_add_stair_landing(root, parent, "MainStairUpperLandingSurface", "MainStairEntryToUpperHall", "upper_landing", "main", "upper", Vector3(MAIN_STAIR_X, UPPER_ROOM_FLOOR_TOP_Y - 0.30, MAIN_STAIR_LANDING_Z), Vector3(34, 0.6, 18), wood.darkened(0.05))

func _add_stair_landing(root: Node3D, parent: Node3D, node_name: String, link_id: String, part: String, from_floor: String, to_floor: String, position: Vector3, size: Vector3, color: Color) -> void:
	var landing := _add_box(root, parent, node_name, position, size, color, false)
	_tag_vertical_link(landing, link_id, part, from_floor, to_floor)
	_tag_temporary_vertical_asset(landing, "Meshy 6 GLB residential switchback stair asset")
	landing.set_meta("vertical_path_continuity", "connects_main_floor_to_upper_floor")
	landing.set_meta("support_surface_top_y", position.y + size.y * 0.5)
	landing.set_meta("target_dimensions_units", size)

func _add_stair_flight(root: Node3D, parent: Node3D, prefix: String, link_id: String, start: Vector3, end: Vector3, width: float, tread_count: int, color: Color) -> void:
	var horizontal := Vector3(end.x - start.x, 0.0, end.z - start.z)
	var run_length := horizontal.length()
	if run_length <= 0.01 or tread_count <= 0:
		return
	var direction := horizontal.normalized()
	var yaw := rad_to_deg(atan2(direction.x, direction.z))
	var tread_depth := run_length / float(tread_count)
	var rise := (end.y - start.y) / float(tread_count)
	for i in range(tread_count):
		var top_y := start.y + rise * float(i + 1)
		var t := (float(i) + 0.5) / float(tread_count)
		var center := start.lerp(end, t)
		center.y = top_y - 0.35
		var tread := _add_box(root, parent, "%s%02d" % [prefix, i], center, Vector3(width, 0.7, tread_depth + 0.4), color.lightened(float(i % 3) * 0.025), false, yaw)
		_tag_vertical_link(tread, link_id, "measured_tread", "main", "upper")
		_tag_temporary_vertical_asset(tread, "Meshy 6 GLB residential switchback stair asset")
		tread.set_meta("vertical_path_continuity", "connects_main_floor_to_upper_floor")
		tread.set_meta("tread_index", i)
		tread.set_meta("tread_count", tread_count)
		tread.set_meta("riser_height_units", rise)
		tread.set_meta("tread_depth_units", tread_depth)
		tread.set_meta("target_dimensions_units", Vector3(width, 0.7, tread_depth + 0.4))

func _add_attic_ladder_continuity_geometry(root: Node3D, parent: Node3D) -> void:
	var ladder_color := Color(0.50, 0.36, 0.22)
	_add_stair_landing(root, parent, "AtticPullDownLowerLandingSurface", "AtticPullDownStairUpperHallToAttic", "lower_landing", "upper", "attic", Vector3(24, UPPER_ROOM_FLOOR_TOP_Y - 0.30, -54), Vector3(34, 0.6, 30), ladder_color.darkened(0.04))
	_add_stair_landing(root, parent, "AtticPullDownUpperLandingSurface", "AtticPullDownStairUpperHallToAttic", "attic_hatch_landing", "upper", "attic", Vector3(24, ATTIC_ROOM_FLOOR_TOP_Y - 0.30, -54), Vector3(40, 0.6, 34), ladder_color.darkened(0.08))
	for x_offset in [-5.0, 5.0]:
		var rail := _add_box(root, parent, "AtticPullDownLadderRail%s" % ("Left" if x_offset < 0.0 else "Right"), Vector3(24 + x_offset, (UPPER_ROOM_FLOOR_TOP_Y + ATTIC_ROOM_FLOOR_TOP_Y) * 0.5, -54), Vector3(1.0, ATTIC_ROOM_FLOOR_TOP_Y - UPPER_ROOM_FLOOR_TOP_Y, 1.0), ladder_color, false)
		_tag_vertical_link(rail, "AtticPullDownStairUpperHallToAttic", "ladder_rail", "upper", "attic")
		_tag_temporary_vertical_asset(rail, "Meshy 6 GLB residential attic pull-down ladder asset")
		rail.set_meta("vertical_path_continuity", "connects_upper_floor_to_attic_floor")
	for i in range(12):
		var rung_y := UPPER_ROOM_FLOOR_TOP_Y + 4.0 + float(i) * 4.0
		var rung := _add_box(root, parent, "AtticPullDownLadderRung%02d" % i, Vector3(24, rung_y, -54), Vector3(12, 0.7, 1.2), ladder_color.lightened(float(i % 2) * 0.04), false)
		_tag_vertical_link(rung, "AtticPullDownStairUpperHallToAttic", "ladder_rung", "upper", "attic")
		_tag_temporary_vertical_asset(rung, "Meshy 6 GLB residential attic pull-down ladder asset")
		rung.set_meta("vertical_path_continuity", "connects_upper_floor_to_attic_floor")
		rung.set_meta("rung_index", i)
		rung.set_meta("rung_spacing_units", 4.0)

func _tag_temporary_vertical_asset(node: Node, replacement_source: String) -> void:
	if node == null:
		return
	node.set_meta("temporary_stand_in", true)
	node.set_meta("replacement_source", replacement_source)
	node.set_meta("asset_lifecycle_blocker", "functional measured vertical circulation restored before final Meshy/Kenney/toybox stair asset is generated and validated")
	node.set_meta("scale_contract_id", SCALE_CONTRACT_ID)
	node.set_meta("scale_validation_status", "measured_floor_to_floor_continuity_pass_pending_final_asset_replacement")

func _tag_vertical_link(node: Node, link_id: String, link_part: String, from_floor: String, to_floor: String) -> void:
	if node == null:
		return
	node.set_meta("vertical_link_id", link_id)
	node.set_meta("vertical_link_part", link_part)
	node.set_meta("from_floor", from_floor)
	node.set_meta("to_floor", to_floor)
	node.set_meta("asset_source", KENNEY_STEPS_PATH)
	node.set_meta("license_origin", "CC0/Kenney")
	node.set_meta("collision_policy", "visual_reference_no_gameplay_collision")
	node.set_meta("route_clearance", "outside_route_corridor")

func _add_vertical_link_marker(root: Node3D, parent: Node3D, node_name: String, link_id: String, position: Vector3, clearance_size: Vector3) -> void:
	var marker := Node3D.new()
	marker.name = node_name
	marker.position = position
	marker.set_meta("vertical_link_id", link_id)
	marker.set_meta("validation_only", true)
	marker.set_meta("opening_marker", true)
	marker.set_meta("clearance_size", clearance_size)
	marker.set_meta("validation_gate", "floor opening must align with sourced stair asset and remain clear of active route/camera corridors")
	parent.add_child(marker)
	marker.owner = root

func _add_yard_plan(root: Node3D, parent: Node3D) -> void:
	_add_box(root, parent, "PatioDeckTransition", Vector3(-47.5, -0.45, -152.5), Vector3(245, 1.2, 45), Color(0.48, 0.44, 0.38), true)
	_add_box(root, parent, "PatioBoardLineA", Vector3(-47.5, 0.25, -164), Vector3(245, 0.12, 1.0), Color(0.27, 0.23, 0.18), false)
	_add_box(root, parent, "PatioBoardLineB", Vector3(-47.5, 0.25, -141), Vector3(245, 0.12, 1.0), Color(0.27, 0.23, 0.18), false)
	for i in range(6):
		_add_box(root, parent, "PatioDeckBoardSeam%02d" % i, Vector3(-150 + i * 44, 0.30, -152.5), Vector3(1.0, 0.16, 43), Color(0.25, 0.21, 0.16), false)
	_add_box(root, parent, "OutdoorPlaygroundSetpieceZone", Vector3(-52.5, -0.45, -217.5), Vector3(235, 1.2, 135), Color(0.56, 0.42, 0.22), true)
	_add_box(root, parent, "PlaygroundMulchBorderFront", Vector3(-52.5, 1.0, -150), Vector3(243, 3, 4), Color(0.22, 0.12, 0.06), false)
	_add_box(root, parent, "PlaygroundMulchBorderBack", Vector3(-52.5, 1.0, -285), Vector3(243, 3, 4), Color(0.22, 0.12, 0.06), false)
	_add_box(root, parent, "PlaygroundMulchBorderWest", Vector3(-170, 1.0, -217.5), Vector3(4, 3, 139), Color(0.22, 0.12, 0.06), false)
	_add_box(root, parent, "PlaygroundMulchBorderEast", Vector3(65, 1.0, -217.5), Vector3(4, 3, 139), Color(0.22, 0.12, 0.06), false)
	_add_box(root, parent, "GardenZone", Vector3(-250, -0.35, -307.5), Vector3(160, 1.4, 225), Color(0.24, 0.36, 0.18), true)
	_add_box(root, parent, "GardenRaisedBedA", Vector3(-282, 3, -308), Vector3(32, 6, 132), Color(0.20, 0.12, 0.07), false)
	_add_box(root, parent, "GardenRaisedBedB", Vector3(-218, 3, -308), Vector3(32, 6, 132), Color(0.20, 0.12, 0.07), false)
	for i in range(5):
		_add_box(root, parent, "GardenVegetableRow%02d" % i, Vector3(-282 + (i % 2) * 64, 7, -368 + i * 30), Vector3(24, 5, 8), Color(0.18, 0.44, 0.18).lightened(float(i) * 0.025), false)
	_add_box(root, parent, "GardenPath", Vector3(-250, 0.05, -308), Vector3(18, 0.5, 210), Color(0.64, 0.56, 0.42), false)
	_add_box(root, parent, "LawnRouteBuffer", Vector3(0, -0.55, -326), Vector3(210, 1.1, 190), Color(0.48, 0.62, 0.34), true)
	_add_box(root, parent, "ToyboxTreeSwingLandingPatch", Vector3(42, -0.30, -308), Vector3(86, 1.2, 78), Color(0.34, 0.56, 0.28), true)
	for i in range(12):
		_add_box(root, parent, "MixedGrassHeightClump%02d" % i, Vector3(-70 + i * 18, 1.4 + float(i % 3), -250 - float((i * 17) % 150)), Vector3(5, 3 + float(i % 4), 4), Color(0.22, 0.48, 0.18).lightened(float(i % 3) * 0.05), false)
	_add_box(root, parent, "Sandbox", Vector3(217.5, -0.35, -320), Vector3(185, 1.4, 200), Color(0.82, 0.66, 0.42), true)
	_add_box(root, parent, "SandboxTimberNorth", Vector3(217.5, 3, -420), Vector3(193, 6, 6), Color(0.30, 0.18, 0.08), false)
	_add_box(root, parent, "SandboxTimberSouth", Vector3(217.5, 3, -220), Vector3(193, 6, 6), Color(0.30, 0.18, 0.08), false)
	_add_box(root, parent, "SandboxTimberWest", Vector3(125, 3, -320), Vector3(6, 6, 206), Color(0.30, 0.18, 0.08), false)
	_add_box(root, parent, "SandboxTimberEast", Vector3(310, 3, -320), Vector3(6, 6, 206), Color(0.30, 0.18, 0.08), false)
	_add_box(root, parent, "TreeShrubScreen", Vector3(0, 2, -446), Vector3(650, 6, 18), Color(0.19, 0.36, 0.14), false)
	_add_box(root, parent, "BackServiceGate", Vector3(238, 9, -446), Vector3(28, 18, 4), Color(0.22, 0.12, 0.06), false)
	_add_box(root, parent, "BackyardStonePathToGarden", Vector3(-152, 0.0, -258), Vector3(78, 0.45, 10), Color(0.56, 0.55, 0.48), false, 12.0)
	_add_box(root, parent, "BackyardPatioPaverGridA", Vector3(-92, 0.1, -180), Vector3(54, 0.35, 42), Color(0.50, 0.47, 0.40), false)
	_add_box(root, parent, "BackyardPatioPaverGridB", Vector3(-20, 0.1, -180), Vector3(54, 0.35, 42), Color(0.54, 0.50, 0.43), false)
	for i in range(8):
		_add_box(root, parent, "BackFenceShrubMass%02d" % i, Vector3(-300 + i * 84, 5, -434 + float(i % 2) * 8), Vector3(34, 10, 18), Color(0.16, 0.34, 0.14).lightened(float(i % 4) * 0.035), false)

func _add_decor(root: Node3D, holders: Dictionary) -> void:
	var main := holders["MainFloor"] as Node3D
	var upper := holders["UpperFloor"] as Node3D
	var attic := holders["Attic"] as Node3D
	var yard := holders["Yard"] as Node3D
	_add_scene(root, yard, BACKYARD_PLAYGROUND_PATH, Vector3(-118, 0, -188), 10, Vector3(10, 10, 10), "PlaygroundStructure")
	_add_scene(root, yard, TOYBOX_TREE_SWING_PATH, Vector3(42, 0, -308), 7, Vector3(15, 15, 15), "ToyboxTreeTireSwing")
	_add_scene(root, yard, BACKYARD_FOSSIL_PATH, Vector3(217, 0, -320), -18, Vector3(11, 11, 11), "SandboxFossil")
	_add_scene(root, yard, BACKYARD_GARDEN_PATH, Vector3(-300, 0, -226), 24, Vector3(12, 12, 12), "GardenLogBush")
	_add_scene(root, main, "res://assets/source/kenney/furniture_kit/kitchenFridge.glb", Vector3(-194, 2.5, -10), 90, Vector3(8, 8, 8), "KitchenFridge")
	_add_scene(root, main, "res://assets/source/kenney/furniture_kit/kitchenSink.glb", Vector3(-170, 2.5, -122), 0, Vector3(8, 8, 8), "KitchenSink")
	_add_scene(root, main, "res://assets/source/kenney/furniture_kit/table.glb", Vector3(-142, 1.5, 86), 0, Vector3(10, 10, 10), "DiningTable")
	_add_scene(root, main, PLAYROOM_MESHY_PLUSH_PATH, Vector3(66, 1.5, -106), -20, Vector3(6.0, 6.0, 6.0), "PlayroomPlushLandmark")
	_add_scene(root, main, PLAYROOM_MESHY_BLOCK_TOWER_PATH, Vector3(44, 1.5, -18), 12, Vector3(5.0, 5.0, 5.0), "PlayroomBlockTower")
	_add_scene(root, main, PLAYROOM_MESHY_TOY_BINS_PATH, Vector3(-30, 1.5, -28), -18, Vector3(5.5, 5.5, 5.5), "PlayroomToyBins")
	_add_scene(root, upper, "res://assets/source/kenney/furniture_kit/bedSingle.glb", Vector3(-128, 54, 26), 90, Vector3(10, 10, 10), "BedroomBed")
	_add_scene(root, upper, "res://assets/source/kenney/furniture_kit/rugRound.glb", Vector3(36, 53, 70), 0, Vector3(12, 12, 12), "GlamRug")
	_add_scene(root, attic, ATTIC_MESHY_TRUNK_PATH, Vector3(-84, 105, 84), 18, Vector3(7, 7, 7), "AtticChest")
	_add_scene(root, attic, ATTIC_MESHY_JACK_PATH, Vector3(28, 105, 92), -12, Vector3(1.8, 1.8, 1.8), "AtticJackSetpiece")
	_add_scene(root, attic, ATTIC_MESHY_SHEET_TUNNEL_PATH, Vector3(-36, 105, 116), 8, Vector3(2.4, 2.4, 2.4), "AtticSheetTunnelSetpiece")

func _add_course_route_markers(root: Node3D, parent: Node3D) -> void:
	for course in COURSES:
		var route_holder := Node3D.new()
		route_holder.name = "%sRoutePreview" % str(course["id"]).capitalize().replace("_", "")
		route_holder.set_meta("route_envelope", _route_envelope_for_course(course))
		route_holder.set_meta("player_readability_contract", {
			"surface": "RoadGridMap course surface with glossy plastic texture assignment",
			"edge_treatment": "GridMap tiles and side-dressed start/finish language keep the player camera corridor clear",
			"placement_rule": "shared scene exports route envelopes and validation holders only; rendered course tiles come from the active mode definition",
		})
		parent.add_child(route_holder)
		route_holder.owner = root
		var envelope := _route_envelope_for_course(course)
		var route_bounds := envelope["route_world_bounds"] as Dictionary
		var min_bound := route_bounds["min"] as Vector3
		var max_bound := route_bounds["max"] as Vector3
		var audit_marker := Node3D.new()
		audit_marker.name = "RouteContainmentAuditBox"
		audit_marker.set_meta("visual_state", "metadata_only_non_rendered")
		audit_marker.set_meta("world_bounds", {"min": min_bound, "max": max_bound})
		route_holder.add_child(audit_marker)
		audit_marker.owner = root

func _add_validation_cameras(root: Node3D, parent: Node3D) -> void:
	_add_camera(root, parent, "OverheadPlanCamera", Vector3(0, 620, -120), Vector3(-90, 0, 0), 115)
	_add_camera(root, parent, "FrontArrivalCamera", Vector3(0, 118, 300), Vector3(-24, 0, 0), 70)
	_add_camera(root, parent, "BackyardCamera", Vector3(-260, 92, -360), Vector3(-16, -38, 0), 72)
	_add_camera(root, parent, "BackyardDoggieDoorCamera", Vector3(92, 32, -205), Vector3(-8, 28, 0), 54)
	_add_camera(root, parent, "ExteriorRooflineCamera", Vector3(-285, 156, 238), Vector3(-22, -42, 0), 58)
	_add_camera(root, parent, "RoofGambrelSideProfileCamera", Vector3(176, 160, 48), Vector3(-8, 88, 0), 50)
	_add_camera(root, parent, "AtticGableProfileCamera", Vector3(176, 160, 48), Vector3(-8, 88, 0), 50)
	_add_camera(root, parent, "FrontPorchCloseupCamera", Vector3(-154, 36, 202), Vector3(-8, -25, 0), 48)
	_add_camera(root, parent, "GarageServiceSideCamera", Vector3(286, 54, 88), Vector3(-11, 84, 0), 58)
	_add_camera(root, parent, "ToyboxTreeSwingCamera", Vector3(-124, 54, -372), Vector3(-7, -63, 0), 54)
	_add_camera(root, parent, "MainFloorRouteCamera", Vector3(-260, 58, 132), Vector3(-14, -62, 0), 70)
	_add_camera(root, parent, "MainFloorRouteStartsCamera", Vector3(-196, 32, -116), Vector3(-10, 36, 0), 64)
	_add_camera(root, parent, "KitchenStartPlayerCamera", Vector3(-190, 18, -105), Vector3(-14, -90, 0), 78)
	_add_camera(root, parent, "KitchenFirstTurnPlayerCamera", Vector3(-74, 16, -106), Vector3(-8, -44, 0), 58)
	_add_camera(root, parent, "KitchenMidpointRouteCamera", Vector3(-24, 22, 34), Vector3(-10, -36, 0), 62)
	_add_camera(root, parent, "KitchenChaseReadabilityCamera", Vector3(-118, 16, -72), Vector3(-8, -64, 0), 70)
	_add_camera(root, parent, "PlayroomStartPlayerCamera", Vector3(-62, 18, -105), Vector3(-12, -90, 0), 74)
	_add_camera(root, parent, "PlayroomFirstTurnPlayerCamera", Vector3(18, 18, -102), Vector3(-10, -42, 0), 62)
	_add_camera(root, parent, "PlayroomMidpointRouteCamera", Vector3(58, 22, -42), Vector3(-10, 18, 0), 62)
	_add_camera(root, parent, "PlayroomChaseReadabilityCamera", Vector3(-18, 16, -92), Vector3(-8, -58, 0), 70)
	_add_camera(root, parent, "PlayroomRouteCamera", Vector3(36, 24, -128), Vector3(-10, 38, 0), 58)
	_add_camera(root, parent, "PlayroomAssetCloseupCamera", Vector3(72, 21, -52), Vector3(-11, 28, 0), 46)
	_add_camera(root, parent, "OutdoorPlaygroundStartPlayerCamera", Vector3(-180, 18, -249), Vector3(-12, -90, 0), 74)
	_add_camera(root, parent, "OutdoorPlaygroundFirstTurnPlayerCamera", Vector3(-82, 18, -250), Vector3(-10, -44, 0), 62)
	_add_camera(root, parent, "OutdoorPlaygroundMidpointRouteCamera", Vector3(-20, 26, -215), Vector3(-14, 22, 0), 62)
	_add_camera(root, parent, "OutdoorPlaygroundChaseReadabilityCamera", Vector3(-144, 18, -244), Vector3(-8, -62, 0), 70)
	_add_camera(root, parent, "GardenStartPlayerCamera", Vector3(-346, 18, -403), Vector3(-12, -90, 0), 74)
	_add_camera(root, parent, "GardenFirstTurnPlayerCamera", Vector3(-300, 18, -352), Vector3(-9, -34, 0), 62)
	_add_camera(root, parent, "GardenMidpointRouteCamera", Vector3(-242, 24, -306), Vector3(-12, 20, 0), 62)
	_add_camera(root, parent, "GardenChaseReadabilityCamera", Vector3(-326, 18, -386), Vector3(-7, -56, 0), 70)
	_add_camera(root, parent, "SandboxStartPlayerCamera", Vector3(121, 18, -398), Vector3(-12, -90, 0), 74)
	_add_camera(root, parent, "SandboxFirstTurnPlayerCamera", Vector3(172, 18, -352), Vector3(-9, -36, 0), 62)
	_add_camera(root, parent, "SandboxMidpointRouteCamera", Vector3(232, 24, -306), Vector3(-12, 18, 0), 62)
	_add_camera(root, parent, "SandboxChaseReadabilityCamera", Vector3(142, 18, -384), Vector3(-7, -54, 0), 70)
	_add_camera(root, parent, "BedroomStartPlayerCamera", Vector3(-162, 70, -94), Vector3(-12, -90, 0), 74)
	_add_camera(root, parent, "BedroomFirstTurnPlayerCamera", Vector3(-114, 70, -48), Vector3(-9, -42, 0), 62)
	_add_camera(root, parent, "BedroomMidpointRouteCamera", Vector3(-120, 78, 52), Vector3(-12, 16, 0), 62)
	_add_camera(root, parent, "BedroomChaseReadabilityCamera", Vector3(-146, 70, -78), Vector3(-7, -58, 0), 70)
	_add_camera(root, parent, "GlamClosetStartPlayerCamera", Vector3(-26, 70, -62), Vector3(-12, -90, 0), 74)
	_add_camera(root, parent, "GlamClosetFirstTurnPlayerCamera", Vector3(28, 70, -22), Vector3(-9, -36, 0), 62)
	_add_camera(root, parent, "GlamClosetMidpointRouteCamera", Vector3(42, 78, 68), Vector3(-12, 14, 0), 62)
	_add_camera(root, parent, "GlamClosetChaseReadabilityCamera", Vector3(-8, 70, -50), Vector3(-7, -54, 0), 70)
	_add_camera(root, parent, "KitchenDiningSeamCamera", Vector3(-170, 24, 30), Vector3(-14, -22, 0), 54)
	_add_camera(root, parent, "KitchenPlayroomSeamCamera", Vector3(-55, 22, -104), Vector3(-10, 0, 0), 54)
	_add_camera(root, parent, "PlayroomLivingSeamCamera", Vector3(18, 24, 34), Vector3(-14, -18, 0), 54)
	_add_camera(root, parent, "GarageServiceSeamCamera", Vector3(104, 24, -38), Vector3(-12, 36, 0), 54)
	_add_camera(root, parent, "UpperFloorRouteCamera", Vector3(-154, 112, 154), Vector3(-20, -42, 0), 70)
	_add_camera(root, parent, "UpperFloorRouteStartsCamera", Vector3(-160, 76, -72), Vector3(-10, 34, 0), 64)
	_add_camera(root, parent, "BedroomGlamSeamCamera", Vector3(-15, 80, 126), Vector3(-15, 0, 0), 54)
	_add_camera(root, parent, "AtticStartPlayerCamera", Vector3(-162, 122, -68), Vector3(-10, -90, 0), 72)
	_add_camera(root, parent, "AtticFirstTurnPlayerCamera", Vector3(-102, 124, -40), Vector3(-8, -38, 0), 62)
	_add_camera(root, parent, "AtticMidpointRouteCamera", Vector3(-24, 130, 18), Vector3(-12, 20, 0), 62)
	_add_camera(root, parent, "AtticChaseReadabilityCamera", Vector3(-142, 122, -58), Vector3(-7, -56, 0), 70)
	_add_camera(root, parent, "AtticRouteCamera", Vector3(-120, 156, 112), Vector3(-18, -42, 0), 70)
	_add_camera(root, parent, "AtticStorageSeamCamera", Vector3(52, 136, 130), Vector3(-16, 34, 0), 54)
	_add_camera(root, parent, "AtticAssetCloseupCamera", Vector3(8, 124, 132), Vector3(-15, -28, 0), 44)
	_add_camera(root, parent, "AtticRampSideProfileCamera", Vector3(-170, 124, -8), Vector3(-8, -90, 0), 70)
	_add_camera(root, parent, "RampSideProfileCamera", Vector3(-170, 124, -8), Vector3(-8, -90, 0), 70)
	_add_camera(root, parent, "YardCourseOverviewCamera", Vector3(0, 240, -360), Vector3(-58, 0, 0), 88)

func _add_concept_reference(root: Node3D, parent: Node3D) -> void:
	parent.set_meta("concept_source", FLOOR_PLAN_PATH)
	parent.set_meta("human_scale_reference_path", KENNEY_HUMAN_SCALE_REFERENCE_PATH)
	_add_human_scale_reference(root, parent)

func _whole_unit_visual_review_contract() -> Dictionary:
	return {
		"evidence_mode": "clean_runtime_or_cinematic_no_editor_overlays",
		"diagnostic_only_overlays": ["editor_camera_icons", "selected_node_outlines", "transform_gizmos", "validation_helper_meshes"],
		"whole_unit_views": ["FrontArrivalCamera", "BackyardCamera", "ExteriorRooflineCamera", "RoofGambrelSideProfileCamera", "GarageServiceSideCamera", "FrontPorchCloseupCamera", "YardCourseOverviewCamera"],
		"course_view_requirements": ["start_player", "first_turn_player", "midpoint_route", "chase_readability"],
		"beta_blockers": ["flat tray yard", "weak window assembly", "weak porch hierarchy", "underscaled sourced asset", "unclassified placeholder box", "route infrastructure without material/edge treatment", "camera evidence dominated by editor helpers"],
	}

func _add_human_scale_reference(root: Node3D, parent: Node3D) -> void:
	_add_scene(root, parent, KENNEY_HUMAN_SCALE_REFERENCE_PATH, Vector3(-92, 0.05, 40), 180.0, Vector3(4.0, 4.0, 4.0), "HumanScaleReference")
	var human := parent.get_node_or_null("HumanScaleReference") as Node3D
	if human == null:
		return
	human.set_meta("reference_role", "human_scale")
	human.set_meta("source_blend", "C:/code/Kenney Game Assets All-in-1 3.3.0/3D assets/Animated Characters Bundle/Models/Source/characterLargeMale.blend")
	human.set_meta("source_fbx", KENNEY_HUMAN_SCALE_REFERENCE_PATH)
	human.set_meta("placement_note", "Standing human reference in main-floor living/dining zone for door, counter, ceiling, furniture, and toy-track proportion checks.")
	human.set_meta("collision_policy", "visual_reference_no_gameplay_collision")
	human.set_meta("scale_contract_id", SCALE_CONTRACT_ID)
	human.set_meta("declared_human_height_units", 25.0)
	human.set_meta("declared_human_height_ft", 6.25)
	human.set_meta("clearance_proxy_size", Vector3(16.0, 32.0, 16.0))
	human.set_meta("clearance_proxy_height_ft", 8.0)
	human.set_meta("clearance_gate", "must not intersect first-floor walls, furnishings, ramps, or route dressing in source scene; hidden from race runtime as authoring reference")

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
		"scale_contract_id": SCALE_CONTRACT_ID,
		"toy_racer_visual_height_units_max": 1.40,
		"toy_racer_route_swept_width_units": 6.0,
		"toy_racer_drift_margin_units": 5.0,
		"third_person_camera_clearance_height_units": 12.0,
		"third_person_camera_clearance_width_units": 14.0,
		"floor_top_y": floor_top_y,
		"road_surface_y": float((course["placement"] as Vector3).y),
		"minimum_clearance_y": ROAD_FLOOR_CLEARANCE,
		"usable_inset": float(zone.get("usable_inset", 0.0)),
		"roof_clearance_max_y": float(zone.get("roof_clearance_max_y", 9999.0)),
		"forbidden_overlap": ["walls", "furniture", "fixtures", "plants", "porch_posts", "service_props", "collision_blockers"],
		"confidence": "inferred_from_floor_plan_and_route_cell_budget",
		"gate": "spatial_audit_%s_route_inside_%s" % [course_id, str(zone["zone_id"])],
	}

func _zone_contract_for_course(course_id: String) -> Dictionary:
	match course_id:
		"kitchen":
			return {"zone_id": "kitchen_breakfast", "center": Vector3(-127.5, 0, -57.5), "size": Vector3(145, 40, 145), "floor_top_y": MAIN_FLOOR_TOP_Y, "usable_inset": 14.0}
		"playroom":
			return {"zone_id": "playroom_family", "center": Vector3(17.5, 0, -57.5), "size": Vector3(145, 40, 145), "floor_top_y": MAIN_FLOOR_TOP_Y, "usable_inset": 14.0}
		"outdoor_playground":
			return {"zone_id": "outdoor_playground_setpiece_zone", "center": Vector3(-52.5, 0, -217.5), "size": Vector3(235, 28, 135), "floor_top_y": 0.15, "usable_inset": 12.0}
		"garden":
			return {"zone_id": "garden_zone", "center": Vector3(-250, 0, -307.5), "size": Vector3(160, 24, 225), "floor_top_y": 0.35, "usable_inset": 8.0}
		"sandbox":
			return {"zone_id": "sandbox", "center": Vector3(217.5, 0, -320), "size": Vector3(185, 24, 200), "floor_top_y": 0.35, "usable_inset": 10.0}
		"bedroom":
			return {"zone_id": "bedroom_suite", "center": Vector3(-97.5, 52, -12), "size": Vector3(165, 40, 236), "floor_top_y": UPPER_ROOM_FLOOR_TOP_Y, "usable_inset": 10.0}
		"glam_closet":
			return {"zone_id": "glam_dressing", "center": Vector3(37.5, 52, -12), "size": Vector3(105, 40, 236), "floor_top_y": UPPER_ROOM_FLOOR_TOP_Y, "usable_inset": 10.0}
		"attic":
			return {"zone_id": "gambrel_attic_toy_build_course", "center": Vector3(-50, 104, 12.5), "size": Vector3(230, 60, 215), "floor_top_y": ATTIC_ROOM_FLOOR_TOP_Y, "roof_clearance_max_y": 164.0, "usable_inset": 11.0}
	return {"zone_id": course_id, "center": Vector3.ZERO, "size": Vector3.ONE, "floor_top_y": 0.0}

func _bounds_from_center_size(center: Vector3, size: Vector3) -> Dictionary:
	var half := size * 0.5
	return {"min": center - half, "max": center + half}

func _route_cells_for_course(course_id: String) -> Array[Vector3i]:
	match course_id:
		"kitchen":
			return _route_from_points([Vector3i(-3, 0, -3), Vector3i(3, 0, -3), Vector3i(3, 0, 3), Vector3i(-3, 0, 3)])
		"playroom":
			return _route_from_points([Vector3i(-3, 0, -3), Vector3i(3, 0, -3), Vector3i(3, 1, 3), Vector3i(-3, 1, 3)])
		"outdoor_playground":
			return _route_from_points([Vector3i(-6, 0, -2), Vector3i(6, 0, -2), Vector3i(6, 1, 2), Vector3i(-6, 1, 2)])
		"garden":
			return _route_from_points([Vector3i(-4, 0, -6), Vector3i(4, 0, -6), Vector3i(4, 1, 6), Vector3i(-4, 1, 6)])
		"sandbox":
			return _route_from_points([Vector3i(-4, 0, -5), Vector3i(4, 0, -5), Vector3i(4, 1, 5), Vector3i(-4, 1, 5)])
		"bedroom":
			return _route_from_points([Vector3i(-4, 0, -5), Vector3i(4, 0, -5), Vector3i(4, 1, 5), Vector3i(-4, 1, 5)])
		"glam_closet":
			return _route_from_points([Vector3i(-2, 0, -5), Vector3i(2, 0, -5), Vector3i(2, 1, 5), Vector3i(-2, 1, 5)])
		"attic":
			return _route_from_points([Vector3i(-6, 0, -5), Vector3i(6, 0, -5), Vector3i(6, 1, 5), Vector3i(-6, 1, 5)])
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
	var start := _cell_center(course, cells[0])
	var first_straight := (_cell_center(course, cells[min(2, cells.size() - 1)]) - start).normalized()
	var side := Vector3(-first_straight.z, 0.0, first_straight.x)
	return _stage_asset_props_for_course(course, id, placement, color, cells, start, side)

func _stage_asset_props_for_course(course: Dictionary, id: String, placement: Vector3, color: Color, cells: Array[Vector3i], start: Vector3, side: Vector3) -> Array[Dictionary]:
	var route_a := _cell_center(course, cells[clampi(cells.size() / 3, 0, cells.size() - 1)])
	var route_b := _cell_center(course, cells[clampi((cells.size() * 2) / 3, 0, cells.size() - 1)])
	var props: Array[Dictionary] = [
		_stage_scene_prop(id, "start_gate", KENNEY_START_GATE_PATH, start + side * 25.0 + Vector3(0, 3.2, 0), 0.0, _gate_scale_for_course(id), "start_finish", "Kenney Toy Car Kit", "CC0/Kenney", "outside_route_corridor", _start_camera_for_course(id)),
		_stage_scene_prop(id, "finish_language_panel", KENNEY_FINISH_GATE_PATH, _cell_center(course, cells[1]) + side * 25.0 + Vector3(0, 3.2, 0), 0.0, _gate_scale_for_course(id), "start_finish", "Kenney Toy Car Kit", "CC0/Kenney", "outside_route_corridor", _start_camera_for_course(id)),
		_stage_scene_prop(id, "route_cone_left", KENNEY_ROUTE_CONE_PATH, route_a + side * 18.0 + Vector3(0, 1.1, 0), 20.0, _cone_scale_for_course(id), "direction", "Kenney Toy Car Kit", "CC0/Kenney", "outside_route_corridor", _start_camera_for_course(id)),
		_stage_scene_prop(id, "route_cone_right", KENNEY_ROUTE_CONE_PATH, route_b + side * 18.0 + Vector3(0, 1.1, 0), -20.0, _cone_scale_for_course(id), "direction", "Kenney Toy Car Kit", "CC0/Kenney", "outside_route_corridor", _start_camera_for_course(id)),
	]
	props.append_array(_themed_asset_props_for_course(id, placement, color))
	return props

func _themed_asset_props_for_course(id: String, placement: Vector3, color: Color) -> Array[Dictionary]:
	match id:
		"kitchen":
			return [
				_stage_scene_prop(id, "fridge_landmark", KENNEY_KITCHEN_FRIDGE_PATH, placement + Vector3(34, 2.6, 44), 90.0, Vector3(9.0, 9.0, 9.0), "landmark", "Kenney Furniture Kit", "CC0/Kenney", "outside_route_corridor", _start_camera_for_course(id)),
				_stage_scene_prop(id, "sink_landmark", KENNEY_KITCHEN_SINK_PATH, placement + Vector3(-42, 2.4, 36), 180.0, Vector3(8.0, 8.0, 8.0), "landmark", "Kenney Furniture Kit", "CC0/Kenney", "outside_route_corridor", _start_camera_for_course(id)),
				_stage_scene_prop(id, "checkered_flag", KENNEY_FLAG_PATH, placement + Vector3(48, 4.0, -42), 35.0, Vector3(5.0, 5.0, 5.0), "landmark", "Kenney Racing Kit", "CC0/Kenney", "outside_route_corridor", _start_camera_for_course(id)),
			]
		"playroom":
			return [
				_stage_scene_prop(id, "plush_landmark", PLAYROOM_MESHY_PLUSH_PATH, placement + Vector3(34, 4.2, 44), -18.0, Vector3(3.4, 3.4, 3.4), "landmark", "Meshy 6 preview home_yard_v3 playroom batch", "project-generated Meshy asset", "outside_route_corridor", _start_camera_for_course(id)),
				_stage_scene_prop(id, "toy_block_tower_landmark", PLAYROOM_MESHY_BLOCK_TOWER_PATH, placement + Vector3(-38, 3.6, 42), -35.0, Vector3(3.0, 3.0, 3.0), "landmark", "Meshy 6 preview home_yard_v3 playroom batch", "project-generated Meshy asset", "outside_route_corridor", _start_camera_for_course(id)),
				_stage_scene_prop(id, "ramp_side_toy_bins_landmark", PLAYROOM_MESHY_TOY_BINS_PATH, placement + Vector3(48, 3.0, -36), 22.0, Vector3(3.2, 3.2, 3.2), "landmark", "Meshy 6 preview home_yard_v3 playroom batch; non-playable route-side dressing only", "project-generated Meshy asset", "outside_route_corridor", _start_camera_for_course(id)),
				_stage_scene_prop(id, "toy_flag_landmark", KENNEY_FLAG_PATH, placement + Vector3(-18, 4.0, -42), -18.0, Vector3(5.0, 5.0, 5.0), "landmark", "Kenney Racing Kit", "CC0/Kenney", "outside_route_corridor", _start_camera_for_course(id)),
			]
		"bedroom":
			return [
				_stage_scene_prop(id, "bed_landmark", KENNEY_BED_PATH, placement + Vector3(34, 4.2, 44), 90.0, Vector3(10.5, 10.5, 10.5), "landmark", "Kenney Furniture Kit", "CC0/Kenney", "outside_route_corridor", _start_camera_for_course(id)),
				_stage_scene_prop(id, "lamp_landmark", KENNEY_BEDROOM_LAMP_PATH, placement + Vector3(-42, 4.0, 38), -20.0, Vector3(8.5, 8.5, 8.5), "landmark", "Kenney Furniture Kit", "CC0/Kenney", "outside_route_corridor", _start_camera_for_course(id)),
				_stage_scene_prop(id, "soft_flag_landmark", KENNEY_FLAG_PATH, placement + Vector3(46, 4.0, -44), 30.0, Vector3(5.0, 5.0, 5.0), "landmark", "Kenney Racing Kit", "CC0/Kenney", "outside_route_corridor", _start_camera_for_course(id)),
			]
		"glam_closet":
			return [
				_stage_scene_prop(id, "mirror_landmark", KENNEY_GLAM_MIRROR_PATH, placement + Vector3(26, 4.2, 44), 180.0, Vector3(10.0, 10.0, 10.0), "landmark", "Kenney Furniture Kit", "CC0/Kenney", "outside_route_corridor", _start_camera_for_course(id)),
				_stage_scene_prop(id, "round_rug_landmark", KENNEY_GLAM_RUG_PATH, placement + Vector3(-42, 1.0, 38), 0.0, Vector3(11.0, 11.0, 11.0), "landmark", "Kenney Furniture Kit", "CC0/Kenney", "outside_route_corridor", _start_camera_for_course(id)),
				_stage_scene_prop(id, "sparkle_flag_landmark", KENNEY_FLAG_PATH, placement + Vector3(44, 4.0, -38), 24.0, Vector3(5.0, 5.0, 5.0), "landmark", "Kenney Racing Kit", "CC0/Kenney", "outside_route_corridor", _start_camera_for_course(id)),
			]
		"attic":
			return [
				_stage_scene_prop(id, "dusty_trunk_landmark", ATTIC_MESHY_TRUNK_PATH, placement + Vector3(34, 4.2, 44), 18.0, Vector3(3.3, 3.3, 3.3), "landmark", "Meshy 6 preview home_yard_v3 attic batch", "project-generated Meshy asset", "outside_route_corridor", _start_camera_for_course(id)),
				_stage_scene_prop(id, "jack_in_box_landmark", ATTIC_MESHY_JACK_PATH, placement + Vector3(-44, 3.6, 36), -28.0, Vector3(2.0, 2.0, 2.0), "landmark", "Meshy 6 refined home_yard_v3 attic batch", "project-generated Meshy asset", "outside_route_corridor", _start_camera_for_course(id)),
				_stage_scene_prop(id, "sheet_tunnel_visual_hook", ATTIC_MESHY_SHEET_TUNNEL_PATH, placement + Vector3(-8, 4.0, 58), 8.0, Vector3(2.2, 2.2, 2.2), "landmark", "Meshy 6 preview home_yard_v3 attic batch; non-playable shortcut visual hook only", "project-generated Meshy asset", "outside_route_corridor", _start_camera_for_course(id)),
				_stage_scene_prop(id, "attic_flag_landmark", KENNEY_FLAG_PATH, placement + Vector3(46, 4.0, -40), 30.0, Vector3(5.0, 5.0, 5.0), "landmark", "Kenney Racing Kit", "CC0/Kenney", "outside_route_corridor", _start_camera_for_course(id)),
			]
		"outdoor_playground":
			return [
				_stage_scene_prop(id, "playground_structure_landmark", BACKYARD_PLAYGROUND_PATH, placement + Vector3(46, 4.2, 44), 0.0, Vector3(4.5, 4.5, 4.5), "landmark", "existing optimized backyard asset", "repo-tracked asset", "outside_route_corridor", _start_camera_for_course(id)),
				_stage_scene_prop(id, "swing_landmark", PLAYGROUND_SWING_MESHY_PATH, placement + Vector3(-54, 3.5, 46), -20.0, Vector3(3.2, 3.2, 3.2), "landmark", "Meshy batch, existing repo asset", "project-generated asset", "outside_route_corridor", _start_camera_for_course(id)),
				_stage_scene_prop(id, "tire_swing_landmark", TOYBOX_TREE_SWING_PATH, placement + Vector3(54, 4.0, -48), 28.0, Vector3(4.0, 4.0, 4.0), "landmark", "toybox existing repo asset", "project-generated asset", "outside_route_corridor", _start_camera_for_course(id)),
			]
		"garden":
			return [
				_stage_scene_prop(id, "garden_log_bush_landmark", BACKYARD_GARDEN_PATH, placement + Vector3(42, 4.2, 50), 8.0, Vector3(4.5, 4.5, 4.5), "landmark", "existing optimized backyard asset", "repo-tracked asset", "outside_route_corridor", _start_camera_for_course(id)),
				_stage_scene_prop(id, "large_bush_landmark", KENNEY_GARDEN_BUSH_PATH, placement + Vector3(-44, 3.0, 36), -18.0, Vector3(8.5, 8.5, 8.5), "landmark", "Kenney Nature Kit", "CC0/Kenney", "outside_route_corridor", _start_camera_for_course(id)),
				_stage_scene_prop(id, "log_landmark", KENNEY_GARDEN_LOG_PATH, placement + Vector3(46, 2.8, -42), 44.0, Vector3(7.5, 7.5, 7.5), "landmark", "Kenney Nature Kit", "CC0/Kenney", "outside_route_corridor", _start_camera_for_course(id)),
			]
		"sandbox":
			return [
				_stage_scene_prop(id, "sandbox_fossil_landmark", BACKYARD_FOSSIL_PATH, placement + Vector3(42, 4.2, 46), -18.0, Vector3(4.5, 4.5, 4.5), "landmark", "existing optimized backyard asset", "repo-tracked asset", "outside_route_corridor", _start_camera_for_course(id)),
				_stage_scene_prop(id, "trex_skeleton_landmark", SANDBOX_TREX_MESHY_PATH, placement + Vector3(-48, 3.5, 38), 22.0, Vector3(4.0, 4.0, 4.0), "landmark", "Meshy batch, existing repo asset", "project-generated asset", "outside_route_corridor", _start_camera_for_course(id)),
				_stage_scene_prop(id, "sand_cone_landmark", KENNEY_ROUTE_CONE_PATH, placement + Vector3(48, 2.5, -40), 35.0, Vector3(5.5, 5.5, 5.5), "landmark", "Kenney Toy Car Kit", "CC0/Kenney", "outside_route_corridor", _start_camera_for_course(id)),
			]
	return [
		_stage_scene_prop(id, "fallback_flag_landmark", KENNEY_FLAG_PATH, placement + Vector3(18, 4.0, 18), 0.0, Vector3(5.0, 5.0, 5.0), "landmark", "Kenney Racing Kit", "CC0/Kenney", "outside_route_corridor", _start_camera_for_course(id)),
	]

func _stage_scene_prop(course_id: String, suffix: String, asset_path: String, position: Vector3, yaw_degrees: float, scale: Vector3, gameplay_tag: String, source: String, license_origin: String, route_clearance: String, validation_camera: String) -> Dictionary:
	var scale_class := _stage_prop_scale_class(asset_path, gameplay_tag)
	return {
		"id": "%s_%s" % [course_id, suffix],
		"kind": "scene",
		"asset_path": asset_path,
		"position": position,
		"yaw_degrees": yaw_degrees,
		"scale": scale,
		"scale_contract_id": SCALE_CONTRACT_ID,
		"scale_class": scale_class,
		"target_dimensions_units": _stage_prop_target_dimensions(scale_class),
		"scale_validation_status": "declared_pending_import_aabb_review",
		"collision_mode": "visual",
		"audio_material_id": "",
		"gameplay_tag": gameplay_tag,
		"asset_source": source,
		"license_origin": license_origin,
		"route_clearance": route_clearance,
		"validation_camera": validation_camera,
	}

func _stage_prop_scale_class(asset_path: String, gameplay_tag: String) -> String:
	if asset_path.contains("/toy_car_kit/") or asset_path.contains("/racing_kit/"):
		return "toy_route_cue"
	if gameplay_tag == "landmark" and asset_path.contains("/meshy/"):
		return "toy_scale_landmark"
	if asset_path.contains("/furniture_kit/"):
		return "human_room_furnishing"
	if asset_path.contains("/nature_kit/") or asset_path.contains("backyard") or asset_path.contains("playground"):
		return "yard_landmark"
	return "review_required"

func _stage_prop_target_dimensions(scale_class: String) -> Vector3:
	match scale_class:
		"toy_route_cue":
			return Vector3(6.0, 6.0, 6.0)
		"toy_scale_landmark":
			return Vector3(10.0, 8.0, 10.0)
		"human_room_furnishing":
			return Vector3(24.0, 16.0, 24.0)
		"yard_landmark":
			return Vector3(24.0, 18.0, 24.0)
		_:
			return Vector3.ZERO

func _gate_scale_for_course(course_id: String) -> Vector3:
	var s := 7.0 if course_id == "kitchen" else 9.0
	return Vector3(s, s, s)

func _cone_scale_for_course(course_id: String) -> Vector3:
	var s := 4.2 if course_id == "kitchen" else 5.3
	return Vector3(s, s, s)

func _start_camera_for_course(course_id: String) -> String:
	return "ValidationCameras/%sStartPlayerCamera" % course_id.to_pascal_case()

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
			out.append({"route_index": 0, "lateral_offset": -2.75 if col == 0 else 2.75, "forward_offset": float(row) * 5.0, "y_offset": 0.8, "yaw_offset_degrees": 180.0})
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

func _add_roof_plane_x(root: Node3D, parent: Node3D, node_name: String, x0: float, x1: float, z0: float, z1: float, y0: float, y1: float, color: Color, provenance := {}) -> MeshInstance3D:
	var vertices := PackedVector3Array([
		Vector3(x0, y0, z0),
		Vector3(x0, y0, z1),
		Vector3(x1, y1, z1),
		Vector3(x1, y1, z0),
	])
	var mesh := _add_mesh(root, parent, node_name, vertices, PackedInt32Array([0, 1, 2, 0, 2, 3]), color, provenance)
	mesh.set_meta("span_axis", "x")
	mesh.set_meta("eave_y", minf(y0, y1))
	mesh.set_meta("ridge_y", maxf(y0, y1))
	mesh.set_meta("slope_delta_y", absf(y1 - y0))
	return mesh

func _add_roof_plane_z(root: Node3D, parent: Node3D, node_name: String, z0: float, z1: float, x0: float, x1: float, y0: float, y1: float, color: Color, provenance := {}) -> MeshInstance3D:
	var vertices := PackedVector3Array([
		Vector3(x0, y0, z0),
		Vector3(x1, y0, z0),
		Vector3(x1, y1, z1),
		Vector3(x0, y1, z1),
	])
	var mesh := _add_mesh(root, parent, node_name, vertices, PackedInt32Array([0, 1, 2, 0, 2, 3]), color, provenance)
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

func garage_center_z() -> float:
	return (-68.0 + 159.0) * 0.5

func _add_gable_wall_x(root: Node3D, parent: Node3D, node_name: String, x: float, z0: float, z1: float, eave_y: float, ridge_z: float, ridge_y: float, color: Color, provenance := {}) -> MeshInstance3D:
	var vertices := PackedVector3Array([
		Vector3(x, eave_y, z0),
		Vector3(x, ridge_y, ridge_z),
		Vector3(x, eave_y, z1),
	])
	var mesh := _add_mesh(root, parent, node_name, vertices, PackedInt32Array([0, 1, 2]), color.darkened(0.04), provenance)
	mesh.set_meta("gable_axis", "z")
	mesh.set_meta("eave_y", eave_y)
	mesh.set_meta("ridge_y", ridge_y)
	mesh.set_meta("ridge_z", ridge_z)
	return mesh

func _add_gambrel_gable_wall_z(root: Node3D, parent: Node3D, node_name: String, z: float, x0: float, x1: float, base_y: float, eave_y: float, break_y: float, ridge_y: float, color: Color) -> Node3D:
	var holder := Node3D.new()
	holder.name = node_name
	holder.set_meta("gable_axis", "x")
	holder.set_meta("roof_form", "dutch_gambrel")
	holder.set_meta("base_y", base_y)
	holder.set_meta("eave_y", eave_y)
	holder.set_meta("break_y", break_y)
	holder.set_meta("ridge_y", ridge_y)
	holder.set_meta("owner_volume", "Roof")
	holder.set_meta("assembly", "dutch_gambrel_gable_infill")
	holder.set_meta("deletion_rule", "this holder owns only upper gable infill and rake trim; below-eave wall surfaces are owned by ExteriorShell")
	parent.add_child(holder)
	holder.owner = root
	var center_x := (x0 + x1) * 0.5
	var half_width := absf(x1 - x0) * 0.5
	var left_break := center_x - half_width * 0.64
	var right_break := center_x + half_width * 0.64
	var vertices := PackedVector3Array([
		Vector3(x0, eave_y, z),
		Vector3(left_break, break_y, z),
		Vector3(center_x, ridge_y, z),
		Vector3(right_break, break_y, z),
		Vector3(x1, eave_y, z),
	])
	_add_mesh(root, holder, "GambrelGableUpperWall", vertices, PackedInt32Array([0, 1, 2, 0, 2, 4, 2, 3, 4]), color.darkened(0.06), _provenance("Roof", "dutch_gambrel_gable_infill", "upper_gable_wall", "PLAN_CONTRACT.roof_contract.dutch_gambrel", "upper gable wall closes only the triangular/gambrel roof end above the eave; the exterior wall owns the below-eave surface", "DutchGambrel roof planes and ExteriorShell wall below", "gable plane at z=%0.2f" % z, "x", Vector3(x0, eave_y, z), Vector3(x1, eave_y, z), ["DutchGambrel roof planes", "ExteriorShell wall top edge"], ["duplicate below-eave wall ownership", "attic playable clearance"], "delete or split if the roof end changes; never emit WallBelowGambrelEave here", "test_home_yard_no_duplicate_gambrel_below_eave_walls", "ValidationCameras/RoofGambrelSideProfileCamera"))
	_add_box(root, holder, "GambrelLeftRakeTrim", Vector3((x0 + left_break) * 0.5, (eave_y + break_y) * 0.5, z + 0.4), Vector3(5, 4, 7), color.lightened(0.16), false, 0, Vector3(0, 0, -28), _provenance("Roof", "dutch_gambrel_gable_infill", "rake_trim", "PLAN_CONTRACT.roof_contract.dutch_gambrel", "left rake trim covers the left lower gambrel edge at the gable end", "GambrelGableUpperWall and DutchGambrelLowerLeftPlane", "left rake edge", "x", Vector3(x0, eave_y, z), Vector3(left_break, break_y, z), ["gable wall", "roof plane edge"], ["floating support block", "below-eave wall duplicate"], "delete if edge is superseded by a mitred rake asset", "test_home_yard_generated_scene_provenance_contract", "ValidationCameras/RoofGambrelSideProfileCamera"))
	_add_box(root, holder, "GambrelRightRakeTrim", Vector3((x1 + right_break) * 0.5, (eave_y + break_y) * 0.5, z + 0.4), Vector3(5, 4, 7), color.lightened(0.16), false, 0, Vector3(0, 0, 28), _provenance("Roof", "dutch_gambrel_gable_infill", "rake_trim", "PLAN_CONTRACT.roof_contract.dutch_gambrel", "right rake trim covers the right lower gambrel edge at the gable end", "GambrelGableUpperWall and DutchGambrelLowerRightPlane", "right rake edge", "x", Vector3(right_break, break_y, z), Vector3(x1, eave_y, z), ["gable wall", "roof plane edge"], ["floating support block", "below-eave wall duplicate"], "delete if edge is superseded by a mitred rake asset", "test_home_yard_generated_scene_provenance_contract", "ValidationCameras/RoofGambrelSideProfileCamera"))
	return holder

func _add_mesh(root: Node3D, parent: Node3D, node_name: String, vertices: PackedVector3Array, indices: PackedInt32Array, color: Color, provenance := {}) -> MeshInstance3D:
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
	_apply_generated_provenance(root, parent, mesh_instance, provenance)
	return mesh_instance

func _add_child_holder(root: Node3D, parent: Node3D, node_name: String, plan_role: String) -> Node3D:
	var holder := Node3D.new()
	holder.name = node_name
	holder.set_meta("plan_role", plan_role)
	parent.add_child(holder)
	holder.owner = root
	return holder

func _provenance(
	owner_volume: String,
	assembly: String,
	role: String,
	source_of_truth: String,
	why_exists: String,
	support_target: String,
	contact_face: String,
	span_axis: String,
	start_anchor,
	end_anchor,
	allowed_intersections,
	forbidden_intersections,
	deletion_rule: String,
	validation_gate: String,
	validation_camera: String,
	visible_class := "architectural_mesh"
) -> Dictionary:
	return {
		"visible_class": visible_class,
		"owner_volume": owner_volume,
		"assembly": assembly,
		"role": role,
		"source_of_truth": source_of_truth,
		"why_exists": why_exists,
		"support_target": support_target,
		"contact_face": contact_face,
		"span_axis": span_axis,
		"start_anchor": start_anchor,
		"end_anchor": end_anchor,
		"allowed_intersections": allowed_intersections,
		"forbidden_intersections": forbidden_intersections,
		"deletion_rule": deletion_rule,
		"validation_gate": validation_gate,
		"validation_camera": validation_camera,
	}

func _route_infrastructure_provenance(owner_volume: String, assembly: String, node_name: String, why_exists: String, validation_camera: String) -> Dictionary:
	return _provenance(
		owner_volume,
		assembly,
		"route infrastructure with dressed material edges and route/camera clearance metadata",
		"home_yard_v3 course concept and shared route envelope contract",
		why_exists,
		"authored route corridor support surface",
		"top/support face clear of racer swept volume",
		"xz route span",
		"%s declared route start anchor" % node_name,
		"%s declared route end anchor" % node_name,
		["route surface support overlap", "non-colliding edge trim overlap", "intentional toy-racing guard contact"],
		["racer swept volume", "third-person chase camera frustum", "house circulation stair", "unclassified placeholder box"],
		"delete or replace when it reads as stale blockout, lacks edge treatment, blocks the route, or has no clean validation camera",
		"test_home_yard_route_infrastructure_is_classified_and_dressed",
		validation_camera,
		"route_infrastructure"
	)

func _default_generated_provenance(root: Node3D, parent: Node3D, node: Node) -> Dictionary:
	var owner_volume := str(parent.name)
	var cursor: Node = parent
	while cursor != null and cursor.get_parent() != root:
		cursor = cursor.get_parent()
	if cursor != null:
		owner_volume = str(cursor.name)
	var assembly := "%s_generated_assembly" % owner_volume.to_lower()
	return _provenance(
		owner_volume,
		assembly,
		"generated_visible_part",
		"home_yard_v3 scratch generator contract",
		"%s is emitted by the home_yard_v3 generator as part of %s and must be validated by provenance coverage gates." % [str(node.name), owner_volume],
		str(parent.name),
		"owner_volume_local_face_or_support_surface",
		"inherited_from_node_transform",
		"generated_transform_start",
		"generated_transform_end",
		["declared owner-volume contact", "small trim/foundation/fixture overlap"],
		["unowned helper geometry", "route corridor", "camera blocker", "unexplained exterior/interior clash"],
		"delete when the node has no declared owner/support target or when a more specific assembly replaces it",
		"test_home_yard_generated_scene_provenance_contract",
		"ValidationCameras/ExteriorRooflineCamera"
	)

func _apply_generated_provenance(root: Node3D, parent: Node3D, node: Node, provenance) -> void:
	if not (node is Node3D):
		return
	var data := {}
	if provenance is Dictionary and not (provenance as Dictionary).is_empty():
		data = (provenance as Dictionary).duplicate(true)
	else:
		data = _default_generated_provenance(root, parent, node)
	data["node_path"] = str(root.get_path_to(node))
	for field in GENERATED_PROVENANCE_REQUIRED_FIELDS:
		if not data.has(field):
			data[field] = "unspecified"
	node.set_meta("generated_scene_provenance", data)
	for key in data.keys():
		node.set_meta(str(key), data[key])

func _add_room_floor(root: Node3D, parent: Node3D, node_name: String, position: Vector3, size: Vector3, color: Color, include_baseboards := true) -> void:
	_add_box(root, parent, node_name, position, size, color, true)
	if not include_baseboards:
		return
	var trim_color := color.darkened(0.32)
	_add_box(root, parent, "%sBaseboardNorth" % node_name, position + Vector3(0, 2.0, -size.z * 0.5), Vector3(size.x, 4.0, 2.0), trim_color, false)
	_add_box(root, parent, "%sBaseboardSouth" % node_name, position + Vector3(0, 2.0, size.z * 0.5), Vector3(size.x, 4.0, 2.0), trim_color, false)
	_add_box(root, parent, "%sBaseboardWest" % node_name, position + Vector3(-size.x * 0.5, 2.0, 0), Vector3(2.0, 4.0, size.z), trim_color, false)
	_add_box(root, parent, "%sBaseboardEast" % node_name, position + Vector3(size.x * 0.5, 2.0, 0), Vector3(2.0, 4.0, size.z), trim_color, false)

func _wall_trim_provenance(wall_id: String, wall_axis: String, span: Vector2, fixed_coord: float, top_y: float) -> Dictionary:
	return _provenance(
		"ExteriorShell",
		"exterior_wall_top_trim",
		"wall_top_trim",
		"home_yard_v3 shell contract and generated-scene-provenance-auditor",
		"%sTopTrim caps the top edge of %s and must terminate at that wall run instead of clipping through roof planes." % [wall_id, wall_id],
		wall_id,
		"top edge at y=%0.2f" % top_y,
		wall_axis,
		{"axis": wall_axis, "fixed": fixed_coord, "span_start": span.x},
		{"axis": wall_axis, "fixed": fixed_coord, "span_end": span.y},
		["same wall run", "small trim overlap at corners"],
		["roof plane AABB except declared flashing tolerance", "unowned helper closure"],
		"delete or split when the wall run changes or if the trim intersects a roof plane",
		"test_home_yard_wall_top_trim_roof_non_clipping",
		"ValidationCameras/ExteriorRooflineCamera"
	)

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
	height := 46.0,
	provenance := {}
) -> void:
	var center_x := (x0 + x1) * 0.5
	var width := absf(x1 - x0)
	_add_box(root, parent, node_name, Vector3(center_x, base_y + height * 0.5, z), Vector3(width, height, 6.0), color, collision, 0.0, Vector3.ZERO, provenance)
	_add_box(root, parent, "%sTopTrim" % node_name, Vector3(center_x, base_y + height + 2.0, z), Vector3(width + 2.0, 4.0, 8.0), color.darkened(0.20), false, 0.0, Vector3.ZERO, _wall_trim_provenance(node_name, "z", Vector2(x0, x1), z, base_y + height))

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
	height := 46.0,
	provenance := {}
) -> void:
	var center_z := (z0 + z1) * 0.5
	var depth := absf(z1 - z0)
	_add_box(root, parent, node_name, Vector3(x, base_y + height * 0.5, center_z), Vector3(6.0, height, depth), color, collision, 0.0, Vector3.ZERO, provenance)
	_add_box(root, parent, "%sTopTrim" % node_name, Vector3(x, base_y + height + 2.0, center_z), Vector3(8.0, 4.0, depth + 2.0), color.darkened(0.20), false, 0.0, Vector3.ZERO, _wall_trim_provenance(node_name, "x", Vector2(z0, z1), x, base_y + height))

func _add_window(root: Node3D, parent: Node3D, node_name: String, position: Vector3, size: Vector3) -> void:
	var trim_color := Color(0.92, 0.86, 0.72)
	if size.x >= size.z:
		var outward_z := 1.0 if position.z >= 0.0 else -1.0
		var normal := Vector3(0, 0, outward_z)
		var glass_pos := position + normal * 0.60
		var trim_pos := position + normal * 0.45
		var backing_pos := position - normal * 0.15
		_add_box(root, parent, node_name, glass_pos, size, Color(0.55, 0.77, 0.92, 0.48), false)
		_add_box(root, parent, "%sHeader" % node_name, trim_pos + Vector3(0, size.y * 0.5 + 2.0, 0), Vector3(size.x + 8.0, 4.0, 3.0), trim_color, false)
		_add_box(root, parent, "%sSill" % node_name, trim_pos + Vector3(0, -size.y * 0.5 - 2.0, 0), Vector3(size.x + 10.0, 4.0, 4.0), trim_color, false)
		_add_box(root, parent, "%sLeftJamb" % node_name, trim_pos + Vector3(-size.x * 0.5 - 2.0, 0, 0), Vector3(4.0, size.y + 4.0, 3.0), trim_color, false)
		_add_box(root, parent, "%sRightJamb" % node_name, trim_pos + Vector3(size.x * 0.5 + 2.0, 0, 0), Vector3(4.0, size.y + 4.0, 3.0), trim_color, false)
		_add_box(root, parent, "%sCenterMuntinVertical" % node_name, glass_pos + normal * 0.15, Vector3(2.2, size.y + 1.0, 2.6), trim_color.darkened(0.08), false)
		_add_box(root, parent, "%sCenterMuntinHorizontal" % node_name, glass_pos + normal * 0.15, Vector3(size.x + 2.0, 2.2, 2.6), trim_color.darkened(0.08), false)
		_add_box(root, parent, "%sInteriorShadowBacking" % node_name, backing_pos, Vector3(size.x * 0.82, size.y * 0.70, 1.4), Color(0.07, 0.12, 0.16, 0.55), false)
	else:
		var outward_x := 1.0 if position.x >= 0.0 else -1.0
		var normal := Vector3(outward_x, 0, 0)
		var glass_pos := position + normal * 0.60
		var trim_pos := position + normal * 0.45
		var backing_pos := position - normal * 0.15
		_add_box(root, parent, node_name, glass_pos, size, Color(0.55, 0.77, 0.92, 0.48), false)
		_add_box(root, parent, "%sHeader" % node_name, trim_pos + Vector3(0, size.y * 0.5 + 2.0, 0), Vector3(3.0, 4.0, size.z + 8.0), trim_color, false)
		_add_box(root, parent, "%sSill" % node_name, trim_pos + Vector3(0, -size.y * 0.5 - 2.0, 0), Vector3(4.0, 4.0, size.z + 10.0), trim_color, false)
		_add_box(root, parent, "%sLeftJamb" % node_name, trim_pos + Vector3(0, 0, -size.z * 0.5 - 2.0), Vector3(3.0, size.y + 4.0, 4.0), trim_color, false)
		_add_box(root, parent, "%sRightJamb" % node_name, trim_pos + Vector3(0, 0, size.z * 0.5 + 2.0), Vector3(3.0, size.y + 4.0, 4.0), trim_color, false)
		_add_box(root, parent, "%sCenterMuntinVertical" % node_name, glass_pos + normal * 0.15, Vector3(2.6, size.y + 1.0, 2.2), trim_color.darkened(0.08), false)
		_add_box(root, parent, "%sCenterMuntinHorizontal" % node_name, glass_pos + normal * 0.15, Vector3(2.6, 2.2, size.z + 2.0), trim_color.darkened(0.08), false)
		_add_box(root, parent, "%sInteriorShadowBacking" % node_name, backing_pos, Vector3(1.4, size.y * 0.70, size.z * 0.82), Color(0.07, 0.12, 0.16, 0.55), false)

func _add_box(root: Node3D, parent: Node3D, node_name: String, position: Vector3, size: Vector3, color: Color, collision: bool, yaw_degrees := 0.0, rotation_degrees := Vector3.ZERO, provenance := {}) -> MeshInstance3D:
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
	_apply_generated_provenance(root, parent, mesh, provenance)
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
	node.set_meta("external_scene_instance", path)
	parent.add_child(node)
	node.owner = root

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
	camera.set_meta("visual_evidence_mode", "clean_runtime_or_cinematic_no_editor_overlays")
	camera.set_meta("validation_subject", node_name)
	camera.set_meta("review_contract", "Final proof must render from this Camera3D path, not from an editor viewport with camera icons or transform gizmos.")
	parent.add_child(camera)
	camera.owner = root

func _set_owner_recursive(node: Node, owner: Node) -> void:
	for child in node.get_children():
		child.owner = owner
		if not str(child.get_meta("external_scene_instance", "")).is_empty():
			_clear_descendant_owners(child)
			continue
		_set_owner_recursive(child, owner)

func _clear_descendant_owners(node: Node) -> void:
	for child in node.get_children():
		child.owner = null
		_clear_descendant_owners(child)
