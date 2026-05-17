extends "res://tests/framework/TestCase.gd"

const TrackCatalog = preload("res://scripts/track/TrackCatalog.gd")
const TrackDefinition = preload("res://scripts/track/TrackDefinition.gd")
const TrackMapDefinition = preload("res://scripts/track/TrackMapDefinition.gd")
const TrackSceneAuthoringData = preload("res://scripts/track/TrackSceneAuthoringData.gd")
const TrackRuntimeBuilder = preload("res://scripts/track/TrackRuntimeBuilder.gd")
const TrackGridRoadBuilder = preload("res://scripts/track/TrackGridRoadBuilder.gd")

const HOME_YARD_MODE_IDS := [
	"attic",
	"bedroom",
	"garden",
	"glam_closet",
	"kitchen",
	"outdoor_playground",
	"playroom",
	"sandbox",
]
const HOME_YARD_MAP_ID := "home_yard_v3"
const OLD_HOME_YARD_MAP_ID := "home_yard"
const OLD_HOME_YARD_V2_MAP_ID := "home_yard_v2"
const HOME_YARD_MAP_SCENE := "res://assets/gameplay/tracks/home_yard_v3/home_yard_v3_map.tscn"
const HOME_ESTATE_MAP_ID := "home_estate_v1"
const HOME_ESTATE_MAP_SCENE := "res://assets/gameplay/tracks/home_estate_v1/home_estate_v1_map.tscn"
const HOME_ESTATE_VISIBLE_SHELL := "res://assets/gameplay/tracks/home_estate_v1/meshes/modern_farmhouse_shell.glb"
const HOME_PLAN50_MAP_ID := "home_plan50_622_v1"
const HOME_PLAN50_MAP_SCENE := "res://assets/gameplay/tracks/home_plan50_622_v1/home_plan50_622_v1_map.tscn"
const HOME_ESTATE_SHELL_REVIEW_DIR := "res://docs/concepts/home_estate_v1/reference_frames/modern_farmhouse_38_526/blender_shell_angles"
const HOME_ESTATE_ROOF_TRIM_AUDIT := "%s/roof_trim_seam_audit.json" % HOME_ESTATE_SHELL_REVIEW_DIR
const HOME_ESTATE_GABLE_POINT_AUDIT := "%s/gable_rake_point_closure_audit.json" % HOME_ESTATE_SHELL_REVIEW_DIR
const HOME_ESTATE_ROOF_AXIS_AUDIT := "%s/roof_axis_orientation_audit.json" % HOME_ESTATE_SHELL_REVIEW_DIR
const HOME_ESTATE_ROOF_INTERSECTION_AUDIT := "%s/roof_intersection_closure_audit.json" % HOME_ESTATE_SHELL_REVIEW_DIR
const HOME_ESTATE_WALL_FLUSH_AUDIT := "%s/wall_plane_flush_audit.json" % HOME_ESTATE_SHELL_REVIEW_DIR
const HOME_ESTATE_ROOF_WALL_EDGE_AUDIT := "%s/roof_wall_corner_edge_audit.json" % HOME_ESTATE_SHELL_REVIEW_DIR
const HOME_ESTATE_ENVELOPE_CLASH_AUDIT := "%s/envelope_clearance_clash_audit.json" % HOME_ESTATE_SHELL_REVIEW_DIR
const HOME_ESTATE_CLOSE_SEAM_REVIEW_RENDERS := [
	"FrontLeftEaveSeamCamera.png",
	"FrontRightEaveSeamCamera.png",
	"RearLeftEaveSeamCamera.png",
	"RearRightEaveSeamCamera.png",
	"UndersideLeftEaveSeamCamera.png",
	"UndersideRightEaveSeamCamera.png",
]
const HOME_ESTATE_GABLE_POINT_REVIEW_RENDERS := [
	"MainFrontGableApexCamera.png",
	"MainRearGableApexCamera.png",
	"GarageFrontGableApexCamera.png",
	"GarageRearGableApexCamera.png",
	"MasterFrontGableApexCamera.png",
	"MasterRearGableApexCamera.png",
	"FrontPorchStreetGableApexCamera.png",
	"FrontPorchTieInGableApexCamera.png",
]
const HOME_ESTATE_ROOF_INTERSECTION_REVIEW_RENDERS := [
	"RearMasterWingRoofClosureCamera.png",
	"RearPorchRoofTieInClosureCamera.png",
	"GarageRearRoofClosureCamera.png",
	"FrontPorchRoofTieInClosureCamera.png",
]
const HOME_ESTATE_WALL_FLUSH_REVIEW_RENDERS := [
	"RightWallFlushCloseCamera.png",
	"MasterWingFrontReturnFlushCamera.png",
	"GarageSideReturnFlushCamera.png",
]
const HOME_ESTATE_ROOF_WALL_EDGE_REVIEW_RENDERS := [
	"RightFrontRoofWallEdgeCamera.png",
	"RightRearRoofWallEdgeCamera.png",
	"MasterWingOuterRoofWallEdgeCamera.png",
	"GarageOuterRoofWallEdgeCamera.png",
	"PorchRoofWallEdgeCamera.png",
]
const HOME_ESTATE_ENVELOPE_CLASH_REVIEW_RENDERS := [
	"MainRightInteriorCeilingClashCamera.png",
	"MasterWingInteriorCeilingClashCamera.png",
	"GarageInteriorCeilingClashCamera.png",
	"UpperEaveUndersideClashCamera.png",
]
const HOME_ESTATE_MODE_IDS := [
	"estate_bedroom_wing",
	"estate_garage",
	"estate_great_room",
	"estate_kitchen",
	"estate_master_suite",
	"estate_patio",
	"estate_sandbox_yard",
	"estate_upper_loft",
]

const HOME_ESTATE_MODE_OWNERS := {
	"estate_bedroom_wing": {"owner": "Tuggs", "zone": "bedroom_wing", "scale": "room_furnishing", "camera": "EstateBedroomWingStartPlayerCamera"},
	"estate_garage": {"owner": "Dash", "zone": "garage_service_driveway_stunt_route", "scale": "room_furnishing", "camera": "EstateGarageStartPlayerCamera"},
	"estate_great_room": {"owner": "Slammo", "zone": "great_room", "scale": "room_furnishing", "camera": "EstateGreatRoomStartPlayerCamera"},
	"estate_kitchen": {"owner": "Sir Clink", "zone": "kitchen", "scale": "room_furnishing", "camera": "EstateKitchenStartPlayerCamera"},
	"estate_master_suite": {"owner": "Velva", "zone": "master_suite_plus_walk_in_closet", "scale": "room_furnishing", "camera": "EstateMasterSuiteStartPlayerCamera"},
	"estate_patio": {"owner": "Moko", "zone": "garden_patio", "scale": "yard_site", "camera": "EstatePatioStartPlayerCamera"},
	"estate_sandbox_yard": {"owner": "Rexx", "zone": "sandbox_fossil_play_yard", "scale": "yard_site", "camera": "EstateSandboxYardStartPlayerCamera"},
	"estate_upper_loft": {"owner": "Popper", "zone": "bonus_room_attic_storage_prank_space", "scale": "room_furnishing", "camera": "EstateUpperLoftStartPlayerCamera"},
}

const HOME_PLAN50_MODE_IDS := [
	"plan50_bedroom_wing",
	"plan50_bonus_storage",
	"plan50_garage",
	"plan50_great_room",
	"plan50_kitchen",
	"plan50_master_suite",
	"plan50_rear_porch",
	"plan50_sandbox_yard",
]

func test_kitchen_map_definition_exposes_race_mode() -> void:
	var map_definition := TrackCatalog.get_map_definition("kitchen")
	assert_true(map_definition is TrackMapDefinition, "Kitchen should load as a track map definition")
	assert_equal(map_definition.id, "kitchen", "Kitchen map should keep the existing map id")
	assert_equal(map_definition.map_scene_path, "res://assets/gameplay/tracks/kitchen/kitchen_editable_room.tscn", "Kitchen map should own the reusable editable room scene")
	assert_true(map_definition.has_mode("race"), "Kitchen map should expose a race mode")
	var modes := TrackCatalog.list_modes("kitchen")
	assert_equal(modes.size(), 1, "Kitchen should expose one implemented mode in this pass")
	assert_equal(str(modes[0].get("id", "")), "race", "Kitchen's implemented mode should be race")
	assert_equal(str(modes[0].get("road_source", "")), "road_grid_map", "Kitchen race mode should use RoadGridMap as its source")

func test_home_yard_map_exposes_all_concept_course_modes() -> void:
	var map_definition := TrackCatalog.get_map_definition(HOME_YARD_MAP_ID)
	assert_true(map_definition is TrackMapDefinition, "Home Yard should load as a track map definition")
	assert_equal(map_definition.id, HOME_YARD_MAP_ID, "Home Yard v3 map id should be stable")
	assert_equal(map_definition.map_scene_path, HOME_YARD_MAP_SCENE, "Home Yard should own the shared floor-plan scene")
	var mode_ids := map_definition.list_mode_ids()
	assert_equal(mode_ids, HOME_YARD_MODE_IDS, "Home Yard should expose the eight concept course modes")
	for mode_id in HOME_YARD_MODE_IDS:
		var mode_summary := map_definition.mode_summary(mode_id)
		assert_equal(str(mode_summary.get("map_id", "")), HOME_YARD_MAP_ID, "%s should belong to the Home Yard v3 map" % mode_id)
		assert_equal(str(mode_summary.get("road_source", "")), "road_grid_map", "%s should use RoadGridMap mode metadata" % mode_id)

func test_home_estate_map_uses_user_floor_plan_scaffold() -> void:
	var map_definition := TrackCatalog.get_map_definition(HOME_ESTATE_MAP_ID)
	assert_true(map_definition is TrackMapDefinition, "Home Estate should load as a track map definition")
	if map_definition == null:
		return
	assert_equal(map_definition.id, HOME_ESTATE_MAP_ID, "Home Estate map id should be stable")
	assert_equal(map_definition.map_scene_path, HOME_ESTATE_MAP_SCENE, "Home Estate should own its generated floor-plan scene")
	assert_equal(map_definition.default_mode_id, "estate_kitchen", "Home Estate should default to the kitchen scaffold mode")
	assert_equal(map_definition.list_mode_ids(), HOME_ESTATE_MODE_IDS, "Home Estate should expose the first-pass plan-derived course modes")
	assert_true(ResourceLoader.exists(HOME_ESTATE_VISIBLE_SHELL), "Home Estate should have a Blender-authored visible shell GLB")
	var packed := load(HOME_ESTATE_MAP_SCENE) as PackedScene
	assert_true(packed != null, "Home Estate generated map scene should load")
	if packed == null:
		return
	var root := packed.instantiate()
	assert_true(root != null, "Home Estate generated map scene should instantiate")
	if root == null:
		return
	for holder_name in ["Site", "Foundation", "ExteriorShell", "Roof", "Openings", "MainFloor", "UpperFloor", "Basement", "PatioPool", "YardZones", "VerticalConnectors", "CourseRoutes", "ValidationCameras"]:
		assert_true(root.get_node_or_null(holder_name) != null, "Home Estate scene should include holder %s" % holder_name)
	for room_path in [
		"MainFloor/ThreeCarGarage",
		"MainFloor/KitchenDining",
		"MainFloor/GreatRoom",
		"MainFloor/MasterSuite",
		"UpperFloor/UpperLoft",
		"UpperFloor/FutureBonusRoom",
		"Basement/BasementPlayableShell",
		"PatioPool/RearPatio",
		"YardZones/MokoGardenPatioSurface",
		"YardZones/RexxSandboxFossilPlayYardSurface",
		"YardZones/DashDrivewayServiceStuntRouteSurface",
	]:
		assert_true(root.get_node_or_null(room_path) != null, "Home Estate scene should include floor-plan node %s" % room_path)
	var contract: Dictionary = root.get_meta("floor_plan_contract", {})
	assert_equal(str(contract.get("source", "")), "user_provided_estate_plan_three_sheets", "Home Estate should record the user-provided plan source")
	assert_true(str(contract.get("style_reference", "")).contains("modern farmhouse"), "Home Estate should record the modern farmhouse style source")
	assert_true(str(contract.get("production_policy", "")).contains("no plan labels"), "Home Estate should reject visible floor-plan labels")
	assert_equal(str(root.get_meta("story_bible_path", "")), "res://docs/concept_package.md", "Home Estate should reference the story bible as concept canon")
	assert_equal(str(root.get_meta("character_zone_mapping_path", "")), "res://docs/story_bible/concepts/home_estate_v1_character_mapping.md", "Home Estate should reference the consolidated character-zone mapping")
	var character_mapping: Dictionary = root.get_meta("character_zone_mapping", {})
	assert_equal(str(character_mapping.get("Sir Clink", "")), "kitchen", "Sir Clink should own the kitchen zone")
	assert_equal(str(character_mapping.get("Slammo", "")), "great_room", "Slammo should own the great-room zone")
	assert_equal(str(character_mapping.get("Tuggs", "")), "bedroom_wing", "Tuggs should own the bedroom wing")
	assert_equal(str(character_mapping.get("Velva", "")), "master_suite_plus_walk_in_closet", "Velva should own the master suite and walk-in closet")
	assert_equal(str(character_mapping.get("Popper", "")), "bonus_room_attic_storage_prank_space", "Popper should own the bonus/prank storage zone")
	assert_equal(str(character_mapping.get("Dash", "")), "garage_service_driveway_stunt_route", "Dash should own garage/service/driveway stunt routing")
	assert_equal(str(character_mapping.get("Moko", "")), "garden_patio", "Moko should own the garden/patio zone")
	assert_equal(str(character_mapping.get("Rexx", "")), "sandbox_fossil_play_yard", "Rexx should own the sandbox/fossil play-yard")
	var yard := root.get_node_or_null("YardZones")
	assert_true(yard != null, "Home Estate should generate a yard zone holder")
	if yard != null:
		var outdoor_contract: Dictionary = yard.get_meta("outdoor_zone_contract", {})
		assert_true(outdoor_contract.has("moko_garden_patio"), "Outdoor contract should include Moko's garden/patio zone")
		assert_true(outdoor_contract.has("rexx_sandbox_fossil_play_yard"), "Outdoor contract should include Rexx's sandbox/fossil play-yard zone")
		assert_true(outdoor_contract.has("dash_driveway_service_stunt_route"), "Outdoor contract should include Dash's driveway/service stunt zone")
	for zone_expectation in [
		{"path": "YardZones/MokoGardenPatioSurface", "owner": "Moko", "zone": "garden_patio", "camera": "MokoGardenPatioCamera"},
		{"path": "YardZones/RexxSandboxFossilPlayYardSurface", "owner": "Rexx", "zone": "sandbox_fossil_play_yard", "camera": "RexxSandboxCamera"},
		{"path": "YardZones/DashDrivewayServiceStuntRouteSurface", "owner": "Dash", "zone": "garage_service_driveway_stunt_route", "camera": "DashDrivewayServiceCamera"},
	]:
		var zone_node := root.get_node_or_null(str((zone_expectation as Dictionary).get("path", "")))
		assert_true(zone_node != null, "Home Estate should include outdoor zone %s" % str((zone_expectation as Dictionary).get("path", "")))
		if zone_node == null:
			continue
		assert_equal(str(zone_node.get_meta("owner_character", "")), str((zone_expectation as Dictionary).get("owner", "")), "Outdoor zone should record its story-bible owner")
		assert_equal(str(zone_node.get_meta("owner_zone", "")), str((zone_expectation as Dictionary).get("zone", "")), "Outdoor zone should record its owner zone")
		assert_equal(str(zone_node.get_meta("scale_class", "")), "yard_site", "Outdoor zone should use yard_site scale")
		assert_equal(str(zone_node.get_meta("validation_camera", "")), str((zone_expectation as Dictionary).get("camera", "")), "Outdoor zone should name its validation camera")
		assert_true(root.get_node_or_null("ValidationCameras/%s" % str((zone_expectation as Dictionary).get("camera", ""))) != null, "Outdoor zone validation camera should exist")
	for territory_expectation in [
		{"path": "MainFloor/KitchenDining", "owner": "Sir Clink", "zone": "kitchen", "scale": "human_scale_shell", "camera": "EstateKitchenStartPlayerCamera"},
		{"path": "MainFloor/GreatRoom", "owner": "Slammo", "zone": "great_room", "scale": "human_scale_shell", "camera": "EstateGreatRoomStartPlayerCamera"},
		{"path": "UpperFloor/UpperBedroomWest", "owner": "Tuggs", "zone": "bedroom_wing", "scale": "human_scale_shell", "camera": "EstateBedroomWingStartPlayerCamera"},
		{"path": "MainFloor/MasterSuite", "owner": "Velva", "zone": "master_suite_plus_walk_in_closet", "scale": "human_scale_shell", "camera": "EstateMasterSuiteStartPlayerCamera"},
		{"path": "UpperFloor/FutureBonusRoom", "owner": "Popper", "zone": "bonus_room_attic_storage_prank_space", "scale": "human_scale_shell", "camera": "EstateUpperLoftStartPlayerCamera"},
		{"path": "MainFloor/ThreeCarGarage", "owner": "Dash", "zone": "garage_service_driveway_stunt_route", "scale": "human_scale_shell", "camera": "EstateGarageStartPlayerCamera"},
		{"path": "PatioPool/RearPatio", "owner": "Moko", "zone": "garden_patio", "scale": "yard_site", "camera": "EstatePatioStartPlayerCamera"},
		{"path": "YardZones/RexxSandboxFossilPlayYardSurface", "owner": "Rexx", "zone": "sandbox_fossil_play_yard", "scale": "yard_site", "camera": "RexxSandboxCamera"},
	]:
		var territory_node := root.get_node_or_null(str((territory_expectation as Dictionary).get("path", "")))
		assert_true(territory_node != null, "Home Estate should include character territory node %s" % str((territory_expectation as Dictionary).get("path", "")))
		if territory_node == null:
			continue
		assert_equal(str(territory_node.get_meta("owner_character", "")), str((territory_expectation as Dictionary).get("owner", "")), "Character territory should record its story-bible owner")
		assert_equal(str(territory_node.get_meta("owner_zone", "")), str((territory_expectation as Dictionary).get("zone", "")), "Character territory should record its story-bible zone")
		assert_equal(str(territory_node.get_meta("scale_class", "")), str((territory_expectation as Dictionary).get("scale", "")), "Character territory should record scale class")
		assert_equal(str(territory_node.get_meta("validation_camera", "")), str((territory_expectation as Dictionary).get("camera", "")), "Character territory should name its validation camera")
		assert_true(root.get_node_or_null("ValidationCameras/%s" % str((territory_expectation as Dictionary).get("camera", ""))) != null, "Character territory validation camera should exist")
	for production_path in [
		"ExteriorShell/ModernFarmhouseShellAsset",
		"ExteriorShell/ModernFarmhouseShellScaleEnvelope",
		"MainFloor/KitchenCabinetRunBack",
		"MainFloor/GreatRoomSofa",
		"MainFloor/MasterBed",
		"UpperFloor/UpperLoftSofa",
		"UpperFloor/FutureBonusStorageTrunks",
	]:
		assert_true(root.get_node_or_null(production_path) != null, "Home Estate should include production world node %s" % production_path)
	var shell_asset := root.get_node_or_null("ExteriorShell/ModernFarmhouseShellAsset")
	assert_equal(str(shell_asset.get_meta("asset_source", "")) if shell_asset != null else "", HOME_ESTATE_VISIBLE_SHELL, "Home Estate visible shell should come from the Blender GLB")
	assert_true(_has_required_home_estate_provenance(shell_asset), "Home Estate shell asset should carry generated-scene provenance metadata")
	assert_equal((root.get_node_or_null("Roof") as Node).get_child_count(), 0, "Home Estate should not layer primitive roof slabs over the Blender shell")
	assert_equal(_visible_label3d_count(root), 0, "Home Estate should not render literal floor-plan labels in the stage scene")
	assert_equal(_visible_route_audit_box_count(root), 0, "Home Estate should not render route containment audit boxes as production geometry")
	for mesh in _generated_visible_meshes(root):
		assert_true(_has_required_home_estate_provenance(mesh), "Visible generated mesh %s should carry provenance metadata" % str(root.get_path_to(mesh)))
	for review_name in [
		"FrontStreetReviewCamera.png",
		"RearYardReviewCamera.png",
		"LeftSideReviewCamera.png",
		"RightSideReviewCamera.png",
		"FrontThreeQuarterReviewCamera.png",
		"RearThreeQuarterReviewCamera.png",
		"RooflineReviewCamera.png",
		"UndersideOverhangReviewCamera.png",
	]:
		assert_true(FileAccess.file_exists("%s/%s" % [HOME_ESTATE_SHELL_REVIEW_DIR, review_name]), "Home Estate shell should keep all-angle review render %s" % review_name)
	for review_name in HOME_ESTATE_CLOSE_SEAM_REVIEW_RENDERS:
		assert_true(FileAccess.file_exists("%s/%s" % [HOME_ESTATE_SHELL_REVIEW_DIR, review_name]), "Home Estate shell should keep close roof-seam review render %s" % review_name)
	for review_name in HOME_ESTATE_GABLE_POINT_REVIEW_RENDERS:
		assert_true(FileAccess.file_exists("%s/%s" % [HOME_ESTATE_SHELL_REVIEW_DIR, review_name]), "Home Estate shell should keep close gable-point review render %s" % review_name)
	for review_name in HOME_ESTATE_ROOF_INTERSECTION_REVIEW_RENDERS:
		assert_true(FileAccess.file_exists("%s/%s" % [HOME_ESTATE_SHELL_REVIEW_DIR, review_name]), "Home Estate shell should keep roof-intersection review render %s" % review_name)
	for review_name in HOME_ESTATE_WALL_FLUSH_REVIEW_RENDERS:
		assert_true(FileAccess.file_exists("%s/%s" % [HOME_ESTATE_SHELL_REVIEW_DIR, review_name]), "Home Estate shell should keep wall-flush review render %s" % review_name)
	for review_name in HOME_ESTATE_ROOF_WALL_EDGE_REVIEW_RENDERS:
		assert_true(FileAccess.file_exists("%s/%s" % [HOME_ESTATE_SHELL_REVIEW_DIR, review_name]), "Home Estate shell should keep roof-wall edge review render %s" % review_name)
	for review_name in HOME_ESTATE_ENVELOPE_CLASH_REVIEW_RENDERS:
		assert_true(FileAccess.file_exists("%s/%s" % [HOME_ESTATE_SHELL_REVIEW_DIR, review_name]), "Home Estate shell should keep envelope clash review render %s" % review_name)

func test_home_plan50_map_uses_separate_one_story_canvas_reference() -> void:
	var map_definition := TrackCatalog.get_map_definition(HOME_PLAN50_MAP_ID)
	assert_true(map_definition is TrackMapDefinition, "Plan 50-622 map should load as a separate track map definition")
	if map_definition == null:
		return
	assert_equal(map_definition.id, HOME_PLAN50_MAP_ID, "Plan 50-622 map id should be stable")
	assert_equal(map_definition.map_scene_path, HOME_PLAN50_MAP_SCENE, "Plan 50-622 should own a separate generated scene")
	assert_equal(map_definition.default_mode_id, "plan50_kitchen", "Plan 50-622 should default to its own kitchen mode")
	assert_equal(map_definition.list_mode_ids(), HOME_PLAN50_MODE_IDS, "Plan 50-622 should expose its own eight territory modes")
	var packed := load(HOME_PLAN50_MAP_SCENE) as PackedScene
	assert_true(packed != null, "Plan 50-622 generated map scene should load")
	if packed == null:
		return
	var root := packed.instantiate()
	assert_true(root != null, "Plan 50-622 generated map scene should instantiate")
	if root == null:
		return
	var contract: Dictionary = root.get_meta("floor_plan_contract", {})
	assert_equal(str(contract.get("source", "")), "monster_house_plans_plan_50_622_user_canvas_reference", "Plan 50-622 should record the Monster/canvas source")
	assert_equal(int(contract.get("stories", 0)), 1, "Plan 50-622 should stay a one-story home")
	assert_equal(int(contract.get("main_floor_area_sqft", 0)), 3250, "Plan 50-622 should record 3250 sq ft")
	assert_equal(str(contract.get("source_url", "")), "https://www.monsterhouseplans.com/house-plans/modern-farmhouse-style/3250-sq-ft-home-1-story-4-bedroom-3-bath-house-plans-plan50-622/", "Plan 50-622 should record the supplied source URL")
	assert_true(str(contract.get("style_reference", "")).contains("Plan 50-622"), "Plan 50-622 should not inherit the old 38-526 reference")
	assert_true((contract.get("reference_screenshot_urls", []) as Array).size() >= 4, "Plan 50-622 should retain URL references to the page screenshot evidence without vendoring copyrighted images")
	var elevation_contract: Dictionary = contract.get("elevation_contract", {})
	for elevation_name in ["front", "rear", "left", "right"]:
		assert_true((elevation_contract.get(elevation_name, []) as Array).size() > 0, "Plan 50-622 should record a %s elevation contract" % elevation_name)
	assert_equal(str(root.get_meta("character_zone_mapping_path", "")), "res://docs/story_bible/concepts/stages/home_plan50_622_v1_character_mapping.md", "Plan 50-622 should use its own stage mapping path")
	assert_true(root.get_node_or_null("UpperFloor") == null, "Plan 50-622 should not generate the old two-story UpperFloor holder")
	for holder_name in ["Site", "Foundation", "ExteriorShell", "Roof", "Openings", "MainFloor", "AtticStorage", "Basement", "PatioPool", "YardZones", "VerticalConnectors", "CourseRoutes", "ValidationCameras"]:
		assert_true(root.get_node_or_null(holder_name) != null, "Plan 50-622 scene should include holder %s" % holder_name)
	for room_path in [
		"MainFloor/SideEntryThreeCarGarage",
		"MainFloor/SideEntryLargeGarageBay",
		"MainFloor/SideEntrySingleGarageBay",
		"MainFloor/Foyer",
		"MainFloor/FormalDiningWetBar",
		"MainFloor/KitchenDining",
		"MainFloor/SculleryPantry",
		"MainFloor/GreatRoom",
		"MainFloor/BedroomWing",
		"MainFloor/MasterSuite",
		"MainFloor/RearCoveredPorchOutdoorKitchen",
		"AtticStorage/BonusAtticStorage",
	]:
		assert_true(root.get_node_or_null(room_path) != null, "Plan 50-622 scene should include floor-plan node %s" % room_path)
	for facade_path in [
		"ExteriorShell/Plan50FrontLeftMasterGableWall",
		"ExteriorShell/Plan50FrontCenterGreatRoomGableWall",
		"ExteriorShell/Plan50FrontRecessedEntryBackWall",
		"ExteriorShell/Plan50FrontRightBedroomGableWall",
		"Openings/Plan50LeftMasterFrontWindowGroupGlass",
		"Openings/Plan50CenterGreatRoomTallWindowGroupGlass",
		"Openings/Plan50RightBedroomFrontWindowGroupGlass",
		"Openings/Plan50RecessedFrontDoorBlackPanel",
		"Openings/Plan50FrontSingleGarageDoorPanel",
		"Openings/Plan50LargeSideEntryGarageDoorAPanel",
		"Openings/Plan50LargeSideEntryGarageDoorBPanel",
		"Roof/Plan50FrontLeftMasterStreetGableLeftRoofPlane",
		"Roof/Plan50FrontCenterGreatRoomStreetGableLeftRoofPlane",
		"Roof/Plan50FrontRightBedroomStreetGableLeftRoofPlane",
		"Roof/Plan50RecessedEntryMetalShedRoofFrontRoofPlane",
		"Openings/Plan50RearPorchLeftDoorWindowGroupGlass",
		"Openings/Plan50RearPorchCenterDoorWindowGroupGlass",
		"Openings/Plan50RearPorchKitchenWindowGroupGlass",
		"Openings/Plan50RearRightBedroomGableWindowGroupGlass",
		"ExteriorShell/RearElevationEndPost-54",
		"ExteriorShell/RearElevationEndPost126",
		"Openings/Plan50LeftServiceDoorAGlass",
		"Openings/Plan50LeftServiceDoorBGlass",
		"Openings/Plan50LeftServiceTallWindowGlass",
		"Openings/Plan50RightSideSmallHorizontalWindowGlass",
		"Openings/Plan50RightSideTallWindowAGlass",
		"Openings/Plan50RightSideTallWindowBGlass",
		"ExteriorShell/RightElevationDominantGableFace",
	]:
		assert_true(root.get_node_or_null(facade_path) != null, "Plan 50-622 scene should include reference-critical facade node %s" % facade_path)
	assert_true(root.get_node_or_null("Site/LeftOakCanopyReference") == null, "Plan 50-622 should not ship visible tree-canopy placeholder boxes in shell review screenshots")
	assert_true(root.get_node_or_null("Site/RightOakCanopyReference") == null, "Plan 50-622 should not ship visible tree-canopy placeholder boxes in shell review screenshots")
	var right_gable := root.get_node_or_null("ExteriorShell/RightElevationDominantGableFace") as MeshInstance3D
	assert_true(right_gable != null and right_gable.mesh is ArrayMesh, "Plan 50-622 right elevation gable face should be triangular mesh geometry, not a rectangular patch box")
	var visible_meshes: Array[MeshInstance3D] = []
	_collect_generated_visible_meshes(root, visible_meshes)
	assert_true(visible_meshes.size() > 0, "Plan 50-622 should expose visible generated meshes for provenance audit")
	for mesh in visible_meshes:
		assert_true(_has_required_home_estate_provenance(mesh), "Plan 50-622 visible generated mesh %s should carry provenance metadata" % str(root.get_path_to(mesh)))
	for mode_id in HOME_PLAN50_MODE_IDS:
		var definition := TrackCatalog.get_mode_definition(HOME_PLAN50_MAP_ID, mode_id)
		assert_true(definition is TrackDefinition, "%s should load through the Plan 50-622 map" % mode_id)
		if definition == null:
			continue
		assert_equal(str(definition.get_meta("track_map_id", "")), HOME_PLAN50_MAP_ID, "%s should resolve through home_plan50_622_v1" % mode_id)
		assert_equal(definition.dressing_scene_path, HOME_PLAN50_MAP_SCENE, "%s should use the separate Plan 50-622 scene" % mode_id)
		assert_equal(definition.validate(), [], "%s Plan 50-622 definition should validate" % mode_id)
	root.queue_free()

func test_home_estate_roof_trim_seam_audit_blocks_uncontracted_edges() -> void:
	assert_true(FileAccess.file_exists(HOME_ESTATE_ROOF_TRIM_AUDIT), "Home Estate shell should emit a roof trim seam audit artifact")
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(HOME_ESTATE_ROOF_TRIM_AUDIT))
	assert_true(parsed is Dictionary, "Roof trim seam audit should be parseable JSON")
	if not (parsed is Dictionary):
		return
	var audit := parsed as Dictionary
	assert_equal(str(audit.get("gate", "")), "roof_trim_seam_audit", "Roof seam audit should identify the seam gate")
	assert_equal(str(audit.get("status", "")), "pass", "Roof seam audit should pass before the generated shell is accepted")
	var close_cameras: Array = audit.get("close_seam_review_cameras", [])
	for review_name in HOME_ESTATE_CLOSE_SEAM_REVIEW_RENDERS:
		assert_true(close_cameras.has(review_name), "Roof seam audit should require close camera %s" % review_name)
	var entries: Array = audit.get("trim_entries", [])
	assert_true(entries.size() > 0, "Roof seam audit should include trim entries")
	for raw_entry in entries:
		var entry: Dictionary = raw_entry
		assert_true(str(entry.get("id", "")) != "", "Each trim audit entry should have an id")
		assert_true(str(entry.get("support_edge_id", "")) != "", "%s should declare its support edge" % str(entry.get("id", "")))
		assert_true((entry.get("neighbor_ids", []) as Array).size() > 0, "%s should declare neighboring trim or wall targets" % str(entry.get("id", "")))
		assert_true(str(entry.get("mitre_rule", "")) != "", "%s should declare a mitre or return rule" % str(entry.get("id", "")))
		assert_true(float(entry.get("minimum_neighbor_overlap", 0.0)) > 0.0, "%s should declare a positive overlap budget" % str(entry.get("id", "")))
		assert_equal(str(entry.get("status", "")), "pass", "%s should pass the numeric seam contract" % str(entry.get("id", "")))

func test_home_estate_gable_rake_point_closure_audit_blocks_flat_apexes() -> void:
	assert_true(FileAccess.file_exists(HOME_ESTATE_GABLE_POINT_AUDIT), "Home Estate shell should emit a gable/rake point-closure audit artifact")
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(HOME_ESTATE_GABLE_POINT_AUDIT))
	assert_true(parsed is Dictionary, "Gable/rake point-closure audit should be parseable JSON")
	if not (parsed is Dictionary):
		return
	var audit := parsed as Dictionary
	assert_equal(str(audit.get("gate", "")), "gable_rake_point_closure_audit", "Gable point audit should identify the point-closure gate")
	assert_equal(str(audit.get("status", "")), "pass", "Gable/rake point-closure audit should pass before the generated shell is accepted")
	var close_cameras: Array = audit.get("close_apex_review_cameras", [])
	for review_name in HOME_ESTATE_GABLE_POINT_REVIEW_RENDERS:
		assert_true(close_cameras.has(review_name), "Gable point audit should require close camera %s" % review_name)
	var apexes: Array = audit.get("gable_apexes", [])
	assert_true(apexes.size() > 0, "Gable point audit should include gable apex entries")
	for raw_entry in apexes:
		var entry: Dictionary = raw_entry
		assert_true(str(entry.get("id", "")) != "", "Each gable point entry should have an id")
		assert_true(str(entry.get("roof_id", "")) != "", "%s should declare its roof id" % str(entry.get("id", "")))
		assert_true((entry.get("rake_ids", []) as Array).size() == 2, "%s should declare two rake ids" % str(entry.get("id", "")))
		assert_true(str(entry.get("ridge_cap_id", "")) != "", "%s should declare a ridge cap id" % str(entry.get("id", "")))
		assert_true(str(entry.get("apex_cap_id", "")) != "", "%s should declare an apex cap or mitre mesh id" % str(entry.get("id", "")))
		assert_true(float(entry.get("endpoint_convergence_tolerance", 999.0)) <= 0.1, "%s should use a strict endpoint convergence tolerance" % str(entry.get("id", "")))
		assert_true(float(entry.get("measured_rake_endpoint_spread", 999.0)) <= float(entry.get("endpoint_convergence_tolerance", 0.0)), "%s rake endpoints should converge at the apex" % str(entry.get("id", "")))
		assert_equal(str(entry.get("status", "")), "pass", "%s should pass the gable/rake point-closure contract" % str(entry.get("id", "")))

func test_home_estate_roof_axis_audit_blocks_wrong_porch_gable_direction() -> void:
	assert_true(FileAccess.file_exists(HOME_ESTATE_ROOF_AXIS_AUDIT), "Home Estate shell should emit a roof-axis orientation audit artifact")
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(HOME_ESTATE_ROOF_AXIS_AUDIT))
	assert_true(parsed is Dictionary, "Roof-axis orientation audit should be parseable JSON")
	if not (parsed is Dictionary):
		return
	var audit := parsed as Dictionary
	assert_equal(str(audit.get("gate", "")), "roof_axis_orientation_audit", "Roof-axis audit should identify the orientation gate")
	assert_equal(str(audit.get("status", "")), "pass", "Roof-axis orientation audit should pass before the generated shell is accepted")
	var modules: Array = audit.get("roof_modules", [])
	assert_true(modules.size() >= 5, "Roof-axis audit should include all major roof modules")
	var front_porch_seen := false
	for raw_entry in modules:
		var entry: Dictionary = raw_entry
		assert_true(str(entry.get("id", "")) != "", "Each roof-axis entry should have an id")
		assert_true(str(entry.get("expected_ridge_axis", "")) != "", "%s should declare expected ridge axis" % str(entry.get("id", "")))
		assert_true(str(entry.get("expected_span_axis", "")) != "", "%s should declare expected span axis" % str(entry.get("id", "")))
		assert_equal(str(entry.get("measured_ridge_axis", "")), str(entry.get("expected_ridge_axis", "")), "%s should match the expected ridge axis" % str(entry.get("id", "")))
		assert_equal(str(entry.get("measured_span_axis", "")), str(entry.get("expected_span_axis", "")), "%s should match the expected span axis" % str(entry.get("id", "")))
		assert_true((entry.get("review_camera_ids", []) as Array).size() > 0, "%s should declare roof-axis review cameras" % str(entry.get("id", "")))
		assert_equal(str(entry.get("status", "")), "pass", "%s should pass the roof-axis contract" % str(entry.get("id", "")))
		if str(entry.get("id", "")) == "FrontPorchGableRoof":
			front_porch_seen = true
			assert_equal(str(entry.get("expected_ridge_axis", "")), "y", "Front porch entry gable should face the street and project front/back for the selected farmhouse reference")
			assert_equal(str(entry.get("expected_span_axis", "")), "x", "Front porch entry gable should span across the entry bay, not stretch as a long lateral porch roof")
			assert_equal(str(entry.get("module_role", "")), "front_entry_gable", "Front porch roof audit should classify the module as the entry gable, not a broad porch cover")
			assert_true(float(entry.get("measured_width", 999.0)) <= float(entry.get("max_span_width", 0.0)), "Front porch entry gable should stay entry-bay sized instead of stretching across the porch facade")
	assert_true(front_porch_seen, "Roof-axis audit should explicitly cover the front porch roof")

func test_home_estate_roof_intersection_closure_audit_blocks_missing_backside_envelope() -> void:
	assert_true(FileAccess.file_exists(HOME_ESTATE_ROOF_INTERSECTION_AUDIT), "Home Estate shell should emit a roof intersection closure audit artifact")
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(HOME_ESTATE_ROOF_INTERSECTION_AUDIT))
	assert_true(parsed is Dictionary, "Roof intersection closure audit should be parseable JSON")
	if not (parsed is Dictionary):
		return
	var audit := parsed as Dictionary
	assert_equal(str(audit.get("gate", "")), "roof_intersection_closure_audit", "Roof intersection audit should identify the closure gate")
	assert_equal(str(audit.get("status", "")), "pass", "Roof intersection closure audit should pass before the generated shell is accepted")
	var close_cameras: Array = audit.get("close_intersection_review_cameras", [])
	for review_name in HOME_ESTATE_ROOF_INTERSECTION_REVIEW_RENDERS:
		assert_true(close_cameras.has(review_name), "Roof intersection audit should require close camera %s" % review_name)
	var intersections: Array = audit.get("intersections", [])
	assert_true(intersections.size() > 0, "Roof intersection audit should include required roof tie-ins")
	for raw_entry in intersections:
		var entry: Dictionary = raw_entry
		assert_true(str(entry.get("id", "")) != "", "Each roof intersection entry should have an id")
		assert_true((entry.get("owner_roof_ids", []) as Array).size() >= 2, "%s should declare owner roof ids" % str(entry.get("id", "")))
		assert_true(str(entry.get("intersection_type", "")) != "", "%s should declare the intersection type" % str(entry.get("id", "")))
		assert_true((entry.get("closure_mesh_ids", []) as Array).size() > 0, "%s should declare closure mesh ids" % str(entry.get("id", "")))
		if str(entry.get("id", "")) == "front_porch_roof_tie_in_closure":
			var closure_mesh_ids: Array = entry.get("closure_mesh_ids", [])
			assert_true(closure_mesh_ids.has("FrontPorchOuterGableWall"), "Front porch closure should include the street-facing gable infill")
			assert_true(closure_mesh_ids.has("FrontPorchTieInGableWall"), "Front porch closure should include the tie-in gable infill")
			assert_true(closure_mesh_ids.has("FrontPorchRightReturnWall"), "Front porch closure should include the right return wall that seals the side void")
			assert_true(closure_mesh_ids.has("FrontPorchLeftReturnWall"), "Front porch closure should include the left return wall that seals the side void")
		assert_true((entry.get("review_camera_ids", []) as Array).size() > 0, "%s should declare close review cameras" % str(entry.get("id", "")))
		assert_equal(str(entry.get("status", "")), "pass", "%s should pass the roof intersection closure contract" % str(entry.get("id", "")))

func test_home_estate_wall_plane_flush_audit_blocks_proud_or_recessed_walls() -> void:
	assert_true(FileAccess.file_exists(HOME_ESTATE_WALL_FLUSH_AUDIT), "Home Estate shell should emit a wall-plane flush audit artifact")
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(HOME_ESTATE_WALL_FLUSH_AUDIT))
	assert_true(parsed is Dictionary, "Wall-plane flush audit should be parseable JSON")
	if not (parsed is Dictionary):
		return
	var audit := parsed as Dictionary
	assert_equal(str(audit.get("gate", "")), "wall_plane_flush_audit", "Wall-plane audit should identify the flush gate")
	assert_equal(str(audit.get("status", "")), "pass", "Wall-plane flush audit should pass before the generated shell is accepted")
	var close_cameras: Array = audit.get("close_flush_review_cameras", [])
	for review_name in HOME_ESTATE_WALL_FLUSH_REVIEW_RENDERS:
		assert_true(close_cameras.has(review_name), "Wall-plane flush audit should require close camera %s" % review_name)
	var wall_planes: Array = audit.get("wall_planes", [])
	assert_true(wall_planes.size() > 0, "Wall-plane flush audit should include exterior wall planes")
	for raw_entry in wall_planes:
		var entry: Dictionary = raw_entry
		assert_true(str(entry.get("id", "")) != "", "Each wall-plane entry should have an id")
		assert_true(str(entry.get("owner_wall_id", "")) != "", "%s should declare owner wall id" % str(entry.get("id", "")))
		assert_true(str(entry.get("axis", "")) != "", "%s should declare the measured axis" % str(entry.get("id", "")))
		assert_true(str(entry.get("face", "")) != "", "%s should declare the measured face" % str(entry.get("id", "")))
		assert_true((entry.get("flush_member_ids", []) as Array).size() > 0, "%s should declare flush member meshes" % str(entry.get("id", "")))
		assert_true((entry.get("cover_mesh_ids", []) as Array).size() > 0, "%s should declare corner/return cover meshes" % str(entry.get("id", "")))
		assert_true((entry.get("review_camera_ids", []) as Array).size() > 0, "%s should declare close review cameras" % str(entry.get("id", "")))
		assert_true((entry.get("measured_faces", {}) as Dictionary).size() > 0, "%s should record measured mesh faces" % str(entry.get("id", "")))
		assert_true(float(entry.get("tolerance", 999.0)) <= 0.1, "%s should use a strict flush tolerance" % str(entry.get("id", "")))
		assert_equal(str(entry.get("status", "")), "pass", "%s should pass the wall-plane flush contract" % str(entry.get("id", "")))

func test_home_estate_roof_wall_corner_edge_audit_blocks_exposed_eave_slits() -> void:
	assert_true(FileAccess.file_exists(HOME_ESTATE_ROOF_WALL_EDGE_AUDIT), "Home Estate shell should emit a roof-wall corner edge audit artifact")
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(HOME_ESTATE_ROOF_WALL_EDGE_AUDIT))
	assert_true(parsed is Dictionary, "Roof-wall corner edge audit should be parseable JSON")
	if not (parsed is Dictionary):
		return
	var audit := parsed as Dictionary
	assert_equal(str(audit.get("gate", "")), "roof_wall_corner_edge_audit", "Roof-wall edge audit should identify the corner/edge gate")
	assert_equal(str(audit.get("status", "")), "pass", "Roof-wall corner edge audit should pass before the generated shell is accepted")
	var close_cameras: Array = audit.get("close_edge_review_cameras", [])
	for review_name in HOME_ESTATE_ROOF_WALL_EDGE_REVIEW_RENDERS:
		assert_true(close_cameras.has(review_name), "Roof-wall edge audit should require close camera %s" % review_name)
	var edges: Array = audit.get("roof_wall_edges", [])
	assert_true(edges.size() > 0, "Roof-wall edge audit should include exposed perimeter edges")
	for raw_entry in edges:
		var entry: Dictionary = raw_entry
		assert_true(str(entry.get("id", "")) != "", "Each roof-wall edge entry should have an id")
		assert_true(str(entry.get("wall_plane_id", "")) != "", "%s should declare wall plane id" % str(entry.get("id", "")))
		assert_true(str(entry.get("roof_edge_id", "")) != "", "%s should declare roof edge id" % str(entry.get("id", "")))
		assert_true((entry.get("fascia_or_rake_ids", []) as Array).size() > 0, "%s should declare fascia or rake meshes" % str(entry.get("id", "")))
		assert_true((entry.get("soffit_or_backer_ids", []) as Array).size() > 0, "%s should declare soffit or backer return meshes" % str(entry.get("id", "")))
		assert_true((entry.get("review_camera_ids", []) as Array).size() > 0, "%s should declare close review cameras" % str(entry.get("id", "")))
		assert_true(float(entry.get("minimum_overlap", 0.0)) > 0.0, "%s should declare a positive overlap budget" % str(entry.get("id", "")))
		assert_true(float(entry.get("endpoint_tolerance", 999.0)) <= 0.1, "%s should use a strict endpoint tolerance" % str(entry.get("id", "")))
		assert_equal(str(entry.get("status", "")), "pass", "%s should pass the roof-wall edge contract" % str(entry.get("id", "")))

func test_home_estate_envelope_clearance_audit_blocks_interior_clashes() -> void:
	assert_true(FileAccess.file_exists(HOME_ESTATE_ENVELOPE_CLASH_AUDIT), "Home Estate shell should emit an envelope clearance clash audit artifact")
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(HOME_ESTATE_ENVELOPE_CLASH_AUDIT))
	assert_true(parsed is Dictionary, "Envelope clearance clash audit should be parseable JSON")
	if not (parsed is Dictionary):
		return
	var audit := parsed as Dictionary
	assert_equal(str(audit.get("gate", "")), "envelope_clearance_clash_audit", "Envelope clash audit should identify the clearance gate")
	assert_equal(str(audit.get("status", "")), "pass", "Envelope clearance clash audit should pass before the generated shell is accepted")
	var close_cameras: Array = audit.get("close_clash_review_cameras", [])
	for review_name in HOME_ESTATE_ENVELOPE_CLASH_REVIEW_RENDERS:
		assert_true(close_cameras.has(review_name), "Envelope clash audit should require close camera %s" % review_name)
	var clearance_volumes: Array = audit.get("clearance_volumes", [])
	assert_true(clearance_volumes.size() >= 3, "Envelope clash audit should declare named interior and camera clearance volumes")
	var shell_pieces: Array = audit.get("audited_shell_pieces", [])
	assert_true(shell_pieces.size() > 0, "Envelope clash audit should include clearance-classified shell pieces")
	for raw_entry in shell_pieces:
		var entry: Dictionary = raw_entry
		assert_true(str(entry.get("id", "")) != "", "Each shell clash audit entry should have an id")
		assert_true(str(entry.get("clearance_class", "")) != "", "%s should declare a clearance class" % str(entry.get("id", "")))
		assert_true((entry.get("bounds_min", []) as Array).size() == 3, "%s should record a world-space bounds_min" % str(entry.get("id", "")))
		assert_true((entry.get("bounds_max", []) as Array).size() == 3, "%s should record a world-space bounds_max" % str(entry.get("id", "")))
		assert_true((entry.get("checked_clearance_volume_ids", []) as Array).size() > 0, "%s should record checked clearance volumes" % str(entry.get("id", "")))
		if str(entry.get("clearance_class", "")) == "exterior_only":
			assert_equal((entry.get("overlapping_clearance_volume_ids", []) as Array).size(), 0, "%s should not overlap interior or route/camera clearance volumes" % str(entry.get("id", "")))
		assert_equal(str(entry.get("status", "")), "pass", "%s should pass the envelope clearance clash contract" % str(entry.get("id", "")))

func test_home_estate_modes_are_gridmap_definitions_without_public_track_remap() -> void:
	var listed_ids: Array[String] = []
	for summary in TrackCatalog.list_tracks():
		listed_ids.append(str(summary.get("id", "")))
	for mode_id in HOME_ESTATE_MODE_IDS:
		assert_true(not listed_ids.has(mode_id), "%s should not become a public track id in the scaffold pass" % mode_id)
		var definition := TrackCatalog.get_mode_definition(HOME_ESTATE_MAP_ID, mode_id)
		assert_true(definition is TrackDefinition, "%s should load through the Home Estate map" % mode_id)
		if definition == null:
			continue
		assert_equal(str(definition.get_meta("track_map_id", "")), HOME_ESTATE_MAP_ID, "%s should resolve through home_estate_v1" % mode_id)
		assert_equal(str(definition.get_meta("track_mode_id", "")), mode_id, "%s should preserve its mode id" % mode_id)
		var owner_contract: Dictionary = HOME_ESTATE_MODE_OWNERS.get(mode_id, {})
		assert_equal(str(definition.get_meta("owner_character", "")), str(owner_contract.get("owner", "")), "%s should record its story-bible character owner" % mode_id)
		assert_equal(str(definition.get_meta("owner_zone", "")), str(owner_contract.get("zone", "")), "%s should record its story-bible owner zone" % mode_id)
		assert_equal(str(definition.get_meta("scale_class", "")), str(owner_contract.get("scale", "")), "%s should record its scale class" % mode_id)
		assert_equal(str(definition.get_meta("validation_camera", "")), str(owner_contract.get("camera", "")), "%s should record its validation camera" % mode_id)
		assert_equal(definition.dressing_scene_path, HOME_ESTATE_MAP_SCENE, "%s should use the shared Home Estate scene" % mode_id)
		assert_true(not definition.road_grid_layout.is_empty(), "%s should expose RoadGridMap layout metadata" % mode_id)
		assert_equal(str(definition.road_grid_layout.get("owner_character", "")), str(owner_contract.get("owner", "")), "%s grid layout should carry owner character metadata" % mode_id)
		assert_equal(str(definition.road_grid_layout.get("owner_zone", "")), str(owner_contract.get("zone", "")), "%s grid layout should carry owner zone metadata" % mode_id)
		assert_equal(str(definition.road_grid_layout.get("scale_class", "")), str(owner_contract.get("scale", "")), "%s grid layout should carry scale class metadata" % mode_id)
		assert_equal(str(definition.road_grid_layout.get("validation_camera", "")), str(owner_contract.get("camera", "")), "%s grid layout should carry validation camera metadata" % mode_id)
		var envelope: Dictionary = definition.road_grid_layout.get("route_envelope", {})
		assert_equal(str(envelope.get("owner_character", "")), str(owner_contract.get("owner", "")), "%s route envelope should carry owner character metadata" % mode_id)
		assert_equal(str(envelope.get("owner_zone", "")), str(owner_contract.get("zone", "")), "%s route envelope should carry owner zone metadata" % mode_id)
		assert_equal(str(envelope.get("scale_class", "")), str(owner_contract.get("scale", "")), "%s route envelope should carry scale class metadata" % mode_id)
		assert_equal(str(envelope.get("validation_camera", "")), str(owner_contract.get("camera", "")), "%s route envelope should carry validation camera metadata" % mode_id)
		assert_equal(str(envelope.get("route_clearance", "")), "route_above_floor_inside_owner_zone_obstacle_and_chase_camera_clear", "%s route envelope should name the Phase 2 clearance gate" % mode_id)
		assert_equal((definition.road_grid_layout.get("spawn_slots", []) as Array).size(), 8, "%s should export eight spawn slots" % mode_id)
		assert_equal(definition.validate(), [], "%s Home Estate definition should validate" % mode_id)

func test_public_home_course_ids_resolve_to_home_yard_modes() -> void:
	for mode_id in HOME_YARD_MODE_IDS:
		var definition := TrackCatalog.get_definition(mode_id)
		assert_true(definition is TrackDefinition, "%s public course id should resolve to a definition" % mode_id)
		assert_equal(str(definition.get_meta("track_map_id", "")), HOME_YARD_MAP_ID, "%s should resolve through the Home Yard v3 map" % mode_id)
		assert_equal(str(definition.get_meta("track_mode_id", "")), mode_id, "%s should resolve to its matching Home Yard mode" % mode_id)
		assert_equal(definition.dressing_scene_path, HOME_YARD_MAP_SCENE, "%s should use the shared Home Yard scene" % mode_id)
		assert_true(not definition.road_grid_layout.is_empty(), "%s should keep mode-specific RoadGridMap metadata" % mode_id)
		assert_equal(definition.validate(), [], "%s Home Yard mode definition should validate" % mode_id)

func test_old_home_yard_map_is_hidden_from_catalog() -> void:
	assert_true(TrackCatalog.get_map_definition(OLD_HOME_YARD_MAP_ID) == null, "Old home_yard generated map should stay hidden from the runtime catalog")
	assert_true(TrackCatalog.get_map_definition(OLD_HOME_YARD_V2_MAP_ID) == null, "Old home_yard_v2 generated map should stay hidden from the runtime catalog")
	assert_true(ResourceLoader.exists("res://assets/gameplay/tracks/home_yard/home_yard_map.tscn"), "Old home_yard scene should remain loadable by path for fallback/reference")
	assert_true(ResourceLoader.exists("res://assets/gameplay/tracks/home_yard_v2/home_yard_v2_map.tscn"), "Old home_yard_v2 scene should remain loadable by path for fallback/reference")

func test_legacy_kitchen_definition_adapter_returns_race_definition() -> void:
	var definition := TrackCatalog.get_definition("kitchen")
	assert_true(definition is TrackDefinition, "Legacy get_definition should still return a TrackDefinition")
	assert_equal(definition.id, "kitchen", "Legacy adapter should preserve the Kitchen track id")
	assert_equal(str(definition.get_meta("track_map_id", "")), HOME_YARD_MAP_ID, "Adapted Kitchen definition should resolve through the shared Home Yard v3 map")
	assert_equal(str(definition.get_meta("track_mode_id", "")), "kitchen", "Adapted Kitchen definition should remember its Home Yard mode")
	assert_equal(str(definition.get_meta("road_source", "")), "road_grid_map", "Adapted Kitchen race should use grid road authoring")
	assert_equal(definition.validate(), [], "Adapted Kitchen race definition should validate")

func test_kitchen_race_mode_uses_grid_without_segments() -> void:
	var definition := TrackSceneAuthoringData.apply_to_definition(TrackCatalog.get_definition("kitchen"))
	assert_equal(definition.road_visual_style, "kenney_gridmap", "Kitchen race mode should build grid road visuals")
	assert_equal(str(definition.get_meta("resolved_race_layout_source", "")), "road_grid_map", "Kitchen race mode should resolve RoadGridMap as the gameplay layout source")
	assert_equal(definition.track_source_id, "road_grid_map", "Kitchen resolved track source should be canonical")
	assert_equal(definition.progress_rule_id, "route_lap_progress", "Kitchen source should own route lap progress rules")
	assert_equal(definition.win_condition_id, "checkpoint_laps", "Kitchen source should own checkpoint lap finish rules")
	assert_true(not definition.road_grid_layout.is_empty(), "Kitchen race mode should collect RoadGridMap data")
	assert_true(definition.road_segment_layout.is_empty(), "Kitchen race mode should not co-enable segment road layout")
	assert_true(definition.route_points.size() >= (definition.road_grid_layout.get("ordered_route_cells", []) as Array).size(), "Kitchen route should be generated from grid cells")
	assert_equal((definition.road_grid_layout.get("spawn_slots", []) as Array).size(), 8, "Kitchen Home Yard mode should export authored start slots")
	assert_equal(definition.spawn_points.size(), 8, "Kitchen grid race layout should expose eight runtime spawn points")
	assert_true(_spawn_grid_starts_at_route_origin(definition.spawn_points, definition.route_points), "Kitchen start grid should align to route_points[0] from ordered_route_cells[0]")

func test_non_grid_source_request_does_not_synthesize_gridmap() -> void:
	var definition := TrackDefinition.new()
	definition.id = "kitchen_route_fixture"
	definition.display_name = "Kitchen Route Fixture"
	definition.laps = 1
	definition.road_visual_style = "procedural"
	definition.route_points = [
		Vector3(0, 0.5, 0),
		Vector3(10, 0.5, 0),
		Vector3(10, 0.5, 10),
	]
	definition.checkpoint_indices = [0, 1, 2]
	definition.spawn_points = [
		Vector4(0, 0.8, 0, 0),
		Vector4(1, 0.8, 0, 0),
		Vector4(2, 0.8, 0, 0),
		Vector4(3, 0.8, 0, 0),
		Vector4(4, 0.8, 0, 0),
		Vector4(5, 0.8, 0, 0),
		Vector4(6, 0.8, 0, 0),
		Vector4(7, 0.8, 0, 0),
	]
	var authored := TrackSceneAuthoringData.apply_to_definition(definition, {"road_source": "route"})
	assert_equal(str(authored.get_meta("resolved_race_layout_source", "")), "", "Legacy source requests should not resolve a race layout")
	assert_true(authored.road_grid_layout.is_empty(), "MVP racing should require real RoadGridMap metadata")
	assert_true(authored.road_segment_layout.is_empty(), "MVP racing should not keep segment layout data")
	assert_true(authored.validate().has("Track must include RoadGridMap layout metadata."), "Fixture tracks without RoadGridMap metadata should fail validation")

func test_road_source_aliases_resolve_to_canonical_track_sources() -> void:
	assert_equal(TrackSceneAuthoringData.canonical_road_source("grid"), "road_grid_map", "grid should remain a RoadGridMap alias")
	assert_equal(TrackSceneAuthoringData.canonical_road_source("kenney_gridmap"), "road_grid_map", "Kenney grid visuals should resolve to RoadGridMap")
	assert_equal(TrackSceneAuthoringData.canonical_road_source("route"), "auto", "Route markers should not resolve as an MVP track source")
	assert_equal(TrackSceneAuthoringData.canonical_road_source("segments"), "auto", "Segment roads should not resolve as an MVP track source")

func test_non_kitchen_track_resolves_grid_source_rules() -> void:
	var definition := TrackSceneAuthoringData.apply_to_definition(TrackCatalog.get_definition("garden"), {"road_source": "track_authoring_preview"})
	assert_equal(str(definition.get_meta("resolved_track_source", "")), "road_grid_map", "Catalog tracks should resolve through GridMap")
	assert_equal(definition.track_source_id, "road_grid_map", "Resolved track source should be canonical")
	assert_equal(definition.progress_rule_id, "route_lap_progress", "GridMap source should own route lap progress rules")
	assert_equal(definition.win_condition_id, "checkpoint_laps", "GridMap source should own checkpoint lap finish rules")
	assert_equal(definition.validate(), [], "Resolved GridMap track definition should validate")

func test_non_kitchen_tracks_load_as_gridmap_tracks() -> void:
	var definition := TrackCatalog.get_definition("garden")
	assert_true(definition is TrackDefinition, "Non-Kitchen tracks should load through get_definition")
	assert_equal(definition.id, "garden", "Garden id should be preserved")
	assert_equal(definition.track_source_id, "road_grid_map", "Garden should be authored as an MVP GridMap track")
	assert_true(not definition.road_grid_layout.is_empty(), "Garden should expose real RoadGridMap layout metadata")
	assert_equal(definition.validate(), [], "Garden GridMap definition should validate")

func test_grid_visuals_and_generated_collision_are_independent() -> void:
	var definition := TrackCatalog.get_definition("kitchen")
	var built := TrackRuntimeBuilder.build(definition)
	var track_node := built.get("node", null) as Node3D
	scene_tree.root.add_child(track_node)
	assert_true(track_node.get_node_or_null("GridRoad") != null, "Grid race should keep RoadGridMap visual road output")
	assert_true((track_node.get_node_or_null("GridRoad") as Node3D).visible, "Grid race should show the GridRoad visuals")
	var collision_body := track_node.get_node_or_null("Road/CollisionBody") as StaticBody3D
	var collision_shape := track_node.get_node_or_null("Road/CollisionBody/CollisionShape3D") as CollisionShape3D
	assert_true(collision_body != null and collision_body.collision_layer == 1 and collision_body.collision_mask == 2, "Grid race collision should use the kart gameplay channel")
	assert_true(collision_shape != null and collision_shape.shape is ConcavePolygonShape3D, "Grid race should still generate shared slab collision from the resolved layout")
	if collision_shape != null and collision_shape.shape is ConcavePolygonShape3D:
		assert_true((collision_shape.shape as ConcavePolygonShape3D).backface_collision, "Grid race collision should be backface-collidable")
	assert_equal(_enabled_collision_objects(track_node.get_node_or_null("GridRoad")), 0, "Grid road visuals should remain collision-free")
	assert_true(_enabled_collision_objects(track_node.get_node_or_null("Road")) > 0, "Generated road slab should own gameplay collision")
	assert_true(track_node.get_node_or_null("Rails") == null, "Grid race should not build legacy rail containment")
	assert_true(track_node.get_node_or_null("BoundaryWalls") != null and _enabled_collision_objects(track_node.get_node_or_null("BoundaryWalls")) > 0, "Grid race should generate invisible boundary wall containment")
	assert_true(track_node.get_node_or_null("Waypoints") != null, "Grid race should generate route waypoint nodes")
	assert_true(track_node.get_node_or_null("CheckpointSystem") != null, "Grid race should generate checkpoint nodes")
	assert_true(track_node.get_node_or_null("SpawnPoints") != null, "Grid race should generate spawn nodes")
	track_node.queue_free()

func _enabled_collision_objects(node: Node) -> int:
	if node == null:
		return 0
	var count := 0
	if node is CollisionObject3D:
		var collision_object := node as CollisionObject3D
		if collision_object.collision_layer != 0 or collision_object.collision_mask != 0:
			count += 1
	if node is CollisionShape3D and not (node as CollisionShape3D).disabled:
		count += 1
	for child in node.get_children():
		count += _enabled_collision_objects(child)
	return count

func _spawn_grid_starts_at_route_origin(spawns: Array[Vector4], route_points: Array[Vector3]) -> bool:
	if spawns.size() < 8 or route_points.size() < 2:
		return false
	var start := route_points[0]
	var first_left := Vector3(spawns[0].x, start.y, spawns[0].z)
	var first_right := Vector3(spawns[1].x, start.y, spawns[1].z)
	var midpoint := first_left.lerp(first_right, 0.5)
	if midpoint.distance_to(Vector3(start.x, start.y, start.z)) > 0.01:
		return false
	var forward := route_points[1] - route_points[0]
	forward.y = 0.0
	if forward.length_squared() <= 0.001:
		return false
	forward = forward.normalized()
	for spawn in spawns:
		var spawn_basis := Basis(Vector3.UP, deg_to_rad(spawn.w))
		var spawn_forward := (-spawn_basis.z).normalized()
		if spawn_forward.dot(forward) < 0.9:
			return false
	return true

func _visible_label3d_count(node: Node) -> int:
	var count := 0
	if node is Label3D and (node as Label3D).visible:
		count += 1
	for child in node.get_children():
		count += _visible_label3d_count(child)
	return count

func _visible_route_audit_box_count(node: Node) -> int:
	var count := 0
	if node.name == "RouteContainmentAuditBox" and node is Node3D and (node as Node3D).visible:
		count += 1
	for child in node.get_children():
		count += _visible_route_audit_box_count(child)
	return count

func _generated_visible_meshes(root: Node) -> Array[MeshInstance3D]:
	var meshes: Array[MeshInstance3D] = []
	_collect_generated_visible_meshes(root, meshes)
	return meshes

func _collect_generated_visible_meshes(node: Node, out: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D and (node as MeshInstance3D).visible and not _has_ancestor_named(node, "ModernFarmhouseShellAsset"):
		out.append(node as MeshInstance3D)
	for child in node.get_children():
		_collect_generated_visible_meshes(child, out)

func _has_ancestor_named(node: Node, ancestor_name: String) -> bool:
	var current := node.get_parent()
	while current != null:
		if current.name == ancestor_name:
			return true
		current = current.get_parent()
	return false

func _has_required_home_estate_provenance(node: Node) -> bool:
	if node == null:
		return false
	for key in [
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
	]:
		if not node.has_meta(key):
			return false
		var value = node.get_meta(key)
		if value is String and str(value) == "":
			return false
		if value is Array and (value as Array).is_empty():
			return false
	return true
