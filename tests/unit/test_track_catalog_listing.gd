extends "res://tests/framework/TestCase.gd"

const TrackCatalog = preload("res://scripts/track/TrackCatalog.gd")
const TrackDefinition = preload("res://scripts/track/TrackDefinition.gd")
const TrackGridRoadBuilder = preload("res://scripts/track/TrackGridRoadBuilder.gd")
const TrackSceneAuthoringData = preload("res://scripts/track/TrackSceneAuthoringData.gd")

const SELECTABLE_TRACK_IDS := [
	"kitchen",
	"attic",
	"bedroom",
	"garden",
	"glam_closet",
	"outdoor_playground",
	"playroom",
	"sandbox",
]
const BACKYARD_TRACK_IDS := [
	"outdoor_playground",
	"garden",
	"sandbox",
]
const NON_KITCHEN_TRACK_IDS := [
	"attic",
	"bedroom",
	"garden",
	"glam_closet",
	"outdoor_playground",
	"playroom",
	"sandbox",
]
const GENERATED_VERTICAL_TRACK_IDS := [
	"attic",
	"bedroom",
	"garden",
	"glam_closet",
	"outdoor_playground",
	"playroom",
	"sandbox",
]
const INDOOR_NON_KITCHEN_TRACK_IDS := [
	"attic",
	"bedroom",
	"glam_closet",
	"playroom",
]
const EXPECTED_STAGE_SKY_PRESETS := {
	"kitchen": "noon_clear",
	"attic": "stormy_moonlight_night",
	"bedroom": "soft_morning",
	"garden": "fresh_morning",
	"glam_closet": "night_city_glow",
	"outdoor_playground": "clear_afternoon",
	"playroom": "party_evening",
	"sandbox": "hot_afternoon",
}
const RAMP_TILE_ITEMS := [
	TrackGridRoadBuilder.TILE_RAMP,
	TrackGridRoadBuilder.TILE_RAMP_LONG,
	TrackGridRoadBuilder.TILE_RAMP_LONG_CURVED,
]
const LEGACY_GAMEPLAY_NODES := [
	"TrackAuthoringPreview",
	"RoutePoints",
	"RoadSegments",
	"SpawnPoints",
	"Checkpoints",
	"ItemSockets",
	"HazardSockets",
]
const INDOOR_FLOOR_SIZE := Vector2(360.0, 240.0)
const BACKYARD_FLOOR_SIZE := Vector2(900.0, 720.0)
const KITCHEN_DEFINITION_GROUND_SIZE := Vector2(560.0, 400.0)
const KITCHEN_EDITABLE_FLOOR_SIZE := Vector2(292.0, 190.0)
const OUTDOOR_GRASS_SHADER := "res://assets/gameplay/materials/grass/playground_grass.gdshader"
const OUTDOOR_PLAYGROUND_FLOOR_TEXTURE := "res://assets/gameplay/materials/playground/outdoor_playground_floor_albedo.png"
const BACKYARD_PREVIEW_SHELL := "res://assets/gameplay/tracks/shared/backyard_optimized/backyard_preview_shell.tscn"
const HOME_YARD_MAP_SCENE := "res://assets/gameplay/tracks/home_yard/home_yard_map.tscn"
const HOME_YARD_GROUND_SIZE := Vector2(520.0, 620.0)
const OLD_BACKYARD_RESOURCE_MARKERS := [
	"wooden_playground_set_static.glb",
	"wooden_playground_set_swing.glb",
]

func test_list_tracks_returns_default_first_summary() -> void:
	var tracks := TrackCatalog.list_tracks()
	assert_equal(tracks.size(), SELECTABLE_TRACK_IDS.size(), "Track catalog should expose the eight MVP GridMap tracks")
	var first: Dictionary = tracks[0]
	assert_equal(str(first.get("id", "")), TrackCatalog.get_default_track_id(), "Default track should appear first")
	assert_equal(str(first.get("display_name", "")), "Kitchen / Sir Clink", "Track summary should expose display name")
	assert_true(str(first.get("scene_path", "")).ends_with(".tscn"), "Track summary should expose runtime scene path")
	assert_true(str(first.get("definition_path", "")).ends_with(".tres"), "Track summary should expose definition path")
	assert_true(str(first.get("metadata_path", "")).ends_with(".json"), "Track summary should expose metadata path")

func test_catalog_exposes_only_gridmap_backed_tracks() -> void:
	var listed_ids: Array[String] = []
	for summary in TrackCatalog.list_tracks():
		var track_id := str(summary.get("id", ""))
		listed_ids.append(track_id)
		assert_true(SELECTABLE_TRACK_IDS.has(track_id), "%s should be one of the selectable MVP tracks" % track_id)
		var definition := TrackCatalog.get_definition(track_id)
		assert_true(definition is TrackDefinition, "%s definition should load" % track_id)
		if definition is TrackDefinition:
			_assert_gridmap_contract(definition, track_id)
	for expected_id in SELECTABLE_TRACK_IDS:
		assert_true(listed_ids.has(expected_id), "%s should remain selectable" % expected_id)

func test_tracks_without_real_gridmap_metadata_fail_validation() -> void:
	var definition := TrackDefinition.new()
	definition.id = "no_grid_fixture"
	definition.display_name = "No Grid Fixture"
	definition.laps = 3
	definition.track_source_id = "road_grid_map"
	definition.road_visual_style = "kenney_gridmap"
	definition.road_width = 16.0
	definition.route_points = [
		Vector3(0, 0, 0),
		Vector3(16, 0, 0),
		Vector3(16, 0, 16),
		Vector3(0, 0, 16),
	]
	definition.checkpoint_indices = [0, 1, 2, 3]
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
	assert_true(authored.road_grid_layout.is_empty(), "Legacy route data should not synthesize GridMap metadata")
	assert_true(authored.validate().has("Track must include RoadGridMap layout metadata."), "Definitions without real RoadGridMap metadata should fail validation")

func test_track_sky_presets_match_stage_plan() -> void:
	for track_id in EXPECTED_STAGE_SKY_PRESETS.keys():
		var definition := TrackCatalog.get_definition(str(track_id))
		assert_true(definition != null, "%s definition should load" % track_id)
		assert_equal(definition.sky_preset_id, str(EXPECTED_STAGE_SKY_PRESETS[track_id]), "%s should use the planned sky preset" % track_id)
		var metadata: Dictionary = TrackCatalog.get_metadata(str(track_id))
		assert_equal(str(metadata.get("sky_preset_id", "")), str(EXPECTED_STAGE_SKY_PRESETS[track_id]), "%s package metadata should export the planned sky preset" % track_id)

func test_authoring_scenes_use_road_gridmap_without_legacy_gameplay_nodes() -> void:
	for track_id in SELECTABLE_TRACK_IDS:
		var definition := TrackCatalog.get_definition(track_id)
		assert_true(definition != null, "%s definition should load" % track_id)
		var packed := load(definition.dressing_scene_path) as PackedScene
		assert_true(packed != null, "%s editable scene should load" % track_id)
		if packed == null:
			continue
		var root := packed.instantiate()
		assert_true(root != null, "%s editable scene should instantiate" % track_id)
		if root == null:
			continue
		for legacy_name in LEGACY_GAMEPLAY_NODES:
			assert_true(root.find_child(legacy_name, true, false) == null, "%s should not keep legacy gameplay node %s" % [track_id, legacy_name])
		assert_equal(definition.dressing_scene_path, HOME_YARD_MAP_SCENE, "%s should use the shared home-yard map scene" % track_id)
		assert_true(not definition.road_grid_layout.is_empty(), "%s should carry its RoadGridMap layout in the mode definition" % track_id)
		assert_equal((definition.road_grid_layout.get("spawn_slots", []) as Array).size(), 8, "%s should export authored spawn slots from its mode definition" % track_id)
		_assert_home_yard_scene_holders(root, track_id)
		root.queue_free()

func _assert_gridmap_contract(definition: TrackDefinition, track_id: String) -> void:
	assert_equal(definition.validate(), [], "%s definition should validate" % track_id)
	assert_equal(definition.track_source_id, "road_grid_map", "%s should resolve as a GridMap track" % track_id)
	assert_equal(definition.road_visual_style, "kenney_gridmap", "%s should use GridMap road visuals" % track_id)
	assert_equal(definition.road_width, 16.0, "%s should use the fixed MVP road width" % track_id)
	assert_equal(definition.rails_enabled, false, "%s should not build rails in the GridMap MVP" % track_id)
	assert_equal(definition.boundary_walls_enabled, true, "%s should build invisible boundary containment" % track_id)
	assert_equal(definition.boundary_wall_debug_visible, false, "%s should hide boundary debug meshes by default" % track_id)
	assert_equal(definition.laps, 3, "%s should run 3 laps" % track_id)
	assert_true(not definition.road_grid_layout.is_empty(), "%s should expose GridMap layout metadata" % track_id)
	assert_equal(definition.road_segment_layout.size(), 0, "%s should not use legacy segment layout data" % track_id)
	assert_true(definition.route_points.size() >= 12, "%s route should be generated from GridMap route cells" % track_id)
	assert_true(definition.checkpoint_indices.size() >= 5, "%s should expose at least 5 checkpoints" % track_id)
	assert_equal(definition.lap_gate_checkpoint_index, 0, "%s checkpoint 0 should be the lap gate" % track_id)
	assert_equal(definition.spawn_points.size(), 8, "%s should expose exactly 8 spawns" % track_id)
	assert_equal(definition.item_sockets.size(), 0, "%s MVP metadata should not export item sockets" % track_id)
	assert_equal(definition.hazard_sockets.size(), 0, "%s MVP metadata should not export hazard sockets" % track_id)
	assert_true(definition.stage_props.size() >= 5, "%s should export named stage props" % track_id)
	assert_true(definition.stage_interactions.size() >= 2, "%s should export explicit stage interactions" % track_id)
	assert_equal(str(definition.road_grid_layout.get("mesh_library_path", "")), "res://assets/source/kenney/racing_kit/racer_road_mesh_library.tres", "%s should use the shared Kenney GridMap mesh library" % track_id)
	assert_true((definition.road_grid_layout.get("ordered_route_cells", []) as Array).size() >= 12, "%s should export ordered GridMap route cells" % track_id)
	if NON_KITCHEN_TRACK_IDS.has(track_id):
		_assert_closed_grid_route_visual_contract(definition, track_id)
	if GENERATED_VERTICAL_TRACK_IDS.has(track_id):
		_assert_generated_route_has_verticality(definition, track_id)
	assert_equal((definition.road_grid_layout.get("spawn_slots", []) as Array).size(), 8, "%s should export expected RoadGridMap spawn slots" % track_id)
	_assert_home_yard_route_envelope(definition, track_id)
	_assert_two_by_four_start_slots(definition.road_grid_layout.get("spawn_slots", []) as Array, track_id)
	assert_true(_spawn_grid_starts_at_route_origin(definition.spawn_points, definition.route_points), "%s runtime spawns should start at ordered_route_cells[0]" % track_id)
	assert_equal(definition.sky_preset_id, str(EXPECTED_STAGE_SKY_PRESETS[track_id]), "%s should use its stage sky preset" % track_id)
	var expected_ground_shader := OUTDOOR_GRASS_SHADER if track_id == "outdoor_playground" else ""
	assert_equal(definition.ground_shader_path, expected_ground_shader, "%s should use the expected ground shader" % track_id)
	if track_id == "outdoor_playground":
		assert_equal(definition.ground_texture_path, OUTDOOR_PLAYGROUND_FLOOR_TEXTURE, "Outdoor Playground should use the authored floor texture")
	assert_equal(definition.ground_size, _expected_definition_ground_size(track_id), "%s definition should match its runtime ground dimensions" % track_id)
	assert_equal(definition.preview_dressing_scene_path, HOME_YARD_MAP_SCENE, "%s should use the shared home-yard preview dressing" % track_id)
	var metadata: Dictionary = definition.to_metadata()
	assert_equal(str(metadata.get("track_source_id", "")), "road_grid_map", "%s metadata should export GridMap source" % track_id)
	assert_equal(str(metadata.get("progress_rule_id", "")), "route_lap_progress", "%s metadata should export route progress rules" % track_id)
	assert_equal(str(metadata.get("win_condition_id", "")), "checkpoint_laps", "%s metadata should export checkpoint lap rules" % track_id)
	assert_equal(bool(metadata.get("boundary_walls_enabled", false)), true, "%s metadata should export boundary wall containment" % track_id)
	assert_equal(bool(metadata.get("rails_enabled", true)), false, "%s metadata should export disabled rails" % track_id)
	assert_equal(str(metadata.get("preview_dressing_scene_path", "")), definition.preview_dressing_scene_path, "%s metadata should export preview dressing path" % track_id)
	assert_equal((metadata.get("stage_interactions", []) as Array).size(), definition.stage_interactions.size(), "%s metadata should export stage interactions from the definition" % track_id)
	var package_metadata: Dictionary = TrackCatalog.get_metadata(track_id)
	assert_equal((package_metadata.get("stage_interactions", []) as Array).size(), definition.stage_interactions.size(), "%s package metadata should include exported stage interactions" % track_id)

func test_backyard_scenes_do_not_reference_old_meshy_landmarks() -> void:
	for track_id in BACKYARD_TRACK_IDS:
		var definition := TrackCatalog.get_definition(track_id)
		assert_true(definition != null, "%s definition should load" % track_id)
		if definition == null:
			continue
		_assert_scene_text_excludes_old_backyard_resources(definition.dressing_scene_path)
		_assert_scene_text_excludes_old_backyard_resources(definition.preview_dressing_scene_path)

func _assert_scene_text_excludes_old_backyard_resources(path: String) -> void:
	assert_true(ResourceLoader.exists(path), "%s should exist" % path)
	var file := FileAccess.open(path, FileAccess.READ)
	assert_true(file != null, "%s should be readable" % path)
	if file == null:
		return
	var text := file.get_as_text()
	file.close()
	for marker in OLD_BACKYARD_RESOURCE_MARKERS:
		assert_true(not text.contains(marker), "%s should not reference old heavy resource %s" % [path, marker])

func _assert_home_yard_route_envelope(definition: TrackDefinition, track_id: String) -> void:
	var envelope: Variant = definition.road_grid_layout.get("route_envelope", {})
	assert_true(envelope is Dictionary, "%s should export a numeric route envelope" % track_id)
	if not (envelope is Dictionary):
		return
	var data := envelope as Dictionary
	assert_equal(str(data.get("course_id", "")), track_id, "%s route envelope should identify the course" % track_id)
	assert_true(data.get("zone_world_bounds", {}) is Dictionary, "%s route envelope should include zone bounds" % track_id)
	assert_true(data.get("route_world_bounds", {}) is Dictionary, "%s route envelope should include route bounds" % track_id)
	var zone_bounds := data.get("zone_world_bounds", {}) as Dictionary
	var route_bounds := data.get("route_world_bounds", {}) as Dictionary
	var zone_min := zone_bounds.get("min", Vector3.ZERO) as Vector3
	var zone_max := zone_bounds.get("max", Vector3.ZERO) as Vector3
	var route_min := route_bounds.get("min", Vector3.ZERO) as Vector3
	var route_max := route_bounds.get("max", Vector3.ZERO) as Vector3
	assert_true(route_min.x >= zone_min.x - 0.01, "%s route should stay inside its assigned zone on min X" % track_id)
	assert_true(route_max.x <= zone_max.x + 0.01, "%s route should stay inside its assigned zone on max X" % track_id)
	assert_true(route_min.z >= zone_min.z - 0.01, "%s route should stay inside its assigned zone on min Z" % track_id)
	assert_true(route_max.z <= zone_max.z + 0.01, "%s route should stay inside its assigned zone on max Z" % track_id)
	assert_true(float(data.get("road_surface_y", 0.0)) > float(data.get("floor_top_y", 0.0)), "%s road surface should sit above the finished floor/ground" % track_id)
	assert_true(float(data.get("road_surface_y", 0.0)) - float(data.get("floor_top_y", 0.0)) >= 0.14, "%s road surface should have a visible floor clearance" % track_id)
	assert_true(float(data.get("corridor_width", 0.0)) >= definition.road_width, "%s route corridor should cover the road width" % track_id)
	assert_true(data.get("forbidden_overlap", []) is Array and not (data.get("forbidden_overlap", []) as Array).is_empty(), "%s route envelope should declare obstacle exclusions" % track_id)

func _assert_two_by_four_start_slots(slots: Array, track_id: String) -> void:
	var lateral_offsets: Array[float] = []
	var forward_offsets: Array[float] = []
	for slot in slots:
		assert_true(slot is Dictionary, "%s spawn slots should export dictionaries" % track_id)
		if not (slot is Dictionary):
			continue
		var data := slot as Dictionary
		assert_equal(int(data.get("route_index", -1)), 0, "%s spawn slots should anchor to ordered_route_cells[0]" % track_id)
		var lateral := snappedf(float(data.get("lateral_offset", 999.0)), 0.001)
		var forward := snappedf(float(data.get("forward_offset", 999.0)), 0.001)
		if not lateral_offsets.has(lateral):
			lateral_offsets.append(lateral)
		if not forward_offsets.has(forward):
			forward_offsets.append(forward)
	lateral_offsets.sort()
	forward_offsets.sort()
	assert_equal(lateral_offsets.size(), 2, "%s start grid should have two lateral columns" % track_id)
	assert_equal(forward_offsets.size(), 4, "%s start grid should have four forward rows" % track_id)
	assert_equal(forward_offsets[0], 0.0, "%s first start-grid row should sit on the route start" % track_id)

func _assert_indoor_shell_seals(root: Node, track_id: String) -> void:
	var shell := root.get_node_or_null("RoomShell")
	assert_true(shell != null, "%s indoor scene should keep a RoomShell" % track_id)
	if shell == null:
		return
	for node_name in [
		"CeilingBackSeal",
		"CeilingLeftSeal",
		"CeilingRightSeal",
		"CeilingFrontSeal",
		"ExteriorBackCeilingFascia",
		"ExteriorLeftCeilingFascia",
		"ExteriorRightCeilingFascia",
		"ExteriorFrontCeilingFascia",
		"ExteriorBackWallTopBelt",
		"ExteriorLeftWallTopBelt",
		"ExteriorRightWallTopBelt",
		"ExteriorFrontWallTopBelt",
		"BackLeftCornerSeal",
		"BackRightCornerSeal",
		"FrontLeftCornerSeal",
		"FrontRightCornerSeal",
		"DoorJambLeft",
		"DoorJambRight",
		"DoorHeader",
		"DoorPanel",
	]:
		assert_true(shell.get_node_or_null(node_name) != null, "%s RoomShell should include seam/door seal node %s" % [track_id, node_name])

func _assert_home_yard_scene_holders(root: Node, track_id: String) -> void:
	for holder_name in ["Site", "Foundation", "ExteriorShell", "Roof", "Openings", "PorchesDecks", "GarageService", "MainFloor", "UpperFloor", "Attic", "Yard", "VerticalConnectors", "CourseRoutes", "Collision", "ValidationCameras"]:
		assert_true(root.get_node_or_null(holder_name) != null, "%s shared home-yard scene should include %s" % [track_id, holder_name])
	_assert_home_yard_floor_plan_contract(root, track_id)
	_assert_home_yard_shared_shell_ownership(root, track_id)
	_assert_home_yard_exterior_shell(root, track_id)
	_assert_home_yard_roof_and_attic_contract(root, track_id)
	_assert_home_yard_landscape_and_assets(root, track_id)
	if track_id == "kitchen":
		_assert_home_yard_kitchen_readability(root)
	assert_true(root.get_node_or_null("VerticalConnectors/MainToUpperToyRamp") != null, "%s should include a main-to-upper toy ramp" % track_id)
	assert_true(root.get_node_or_null("VerticalConnectors/UpperToAtticToyRamp") != null, "%s should include an upper-to-attic toy ramp" % track_id)
	assert_true(root.get_node_or_null("CourseRoutes/%sRoutePreview" % track_id.capitalize()) != null, "%s should include a route preview holder" % track_id)
	assert_true(root.get_node_or_null("CourseRoutes/%sRoutePreview/RouteContainmentAuditBox" % track_id.capitalize()) != null, "%s should include a route containment audit box" % track_id)

func _assert_home_yard_floor_plan_contract(root: Node, track_id: String) -> void:
	var contract: Variant = root.get_meta("floor_plan_contract", {})
	assert_true(contract is Dictionary, "%s shared home-yard scene should include a floor-plan contract" % track_id)
	if not (contract is Dictionary):
		return
	var data := contract as Dictionary
	assert_equal(str(data.get("selected_alternative", "")), "Architecture-First", "%s should record the selected floor-plan alternative" % track_id)
	assert_true(str(data.get("site_orientation", "")).contains("front/street"), "%s should record front/street site orientation" % track_id)
	assert_true(data.get("floor_heights", {}) is Dictionary, "%s should record vertical floor relationships" % track_id)
	assert_true(str(data.get("route_contract", "")) != "", "%s should record route envelope contract requirements" % track_id)
	assert_true(str(data.get("shell_ownership", "")).contains("ExteriorShell"), "%s should record shared shell ownership" % track_id)
	var wall_schedule: Variant = root.get_meta("interior_wall_schedule", [])
	assert_true(wall_schedule is Array, "%s shared home-yard scene should include an interior wall schedule" % track_id)
	if wall_schedule is Array:
		var schedule := wall_schedule as Array
		assert_true(schedule.size() >= 10, "%s interior wall schedule should cover connected room seams" % track_id)
		for expected_wall_id in ["KitchenDiningCasedOpening", "KitchenPlayroomDivider", "PlayroomLivingCasedOpening", "GarageInteriorBackWall", "BedroomGlamCasedOpening", "AtticWestKneePartition"]:
			assert_true(_wall_schedule_has_id(schedule, expected_wall_id), "%s interior wall schedule should include %s" % [track_id, expected_wall_id])
	var envelopes: Variant = root.get_meta("route_envelopes", {})
	assert_true(envelopes is Dictionary and (envelopes as Dictionary).has(track_id), "%s shared home-yard scene should include numeric route envelopes" % track_id)
	var conflicts: Variant = root.get_meta("clearance_conflicts", [])
	assert_true(conflicts is Array and (conflicts as Array).is_empty(), "%s shared home-yard scene should export no known clearance conflicts" % track_id)

func _wall_schedule_has_id(schedule: Array, wall_id: String) -> bool:
	for item in schedule:
		if item is Dictionary and str((item as Dictionary).get("id", "")) == wall_id:
			var data := item as Dictionary
			return str(data.get("owner", "")) == "interior_partition" and data.get("connected_zones", []) is Array and str(data.get("owner_skill", "")) == "floor-plan-architect"
	return false

func _assert_home_yard_shared_shell_ownership(root: Node, track_id: String) -> void:
	for node_path in [
		"MainFloor/InteriorWalls",
		"MainFloor/RoomFinishes",
		"UpperFloor/InteriorWalls",
		"UpperFloor/RoomFinishes",
		"Attic/InteriorPartitions",
		"Attic/RoomFinishes",
	]:
		assert_true(root.get_node_or_null(node_path) != null, "%s shared home-yard scene should include %s" % [track_id, node_path])
	for forbidden_holder in ["MainFloor", "UpperFloor", "Attic"]:
		var holder := root.get_node_or_null(forbidden_holder)
		assert_true(holder != null, "%s should include %s for shell-ownership audit" % [track_id, forbidden_holder])
		if holder != null:
			_assert_no_stage_owned_exterior_nodes(holder, track_id, forbidden_holder, forbidden_holder)
	for node_path in [
		"ValidationCameras/KitchenDiningSeamCamera",
		"ValidationCameras/KitchenPlayroomSeamCamera",
		"ValidationCameras/PlayroomLivingSeamCamera",
		"ValidationCameras/GarageServiceSeamCamera",
		"ValidationCameras/BedroomGlamSeamCamera",
		"ValidationCameras/AtticStorageSeamCamera",
	]:
		assert_true(root.get_node_or_null(node_path) != null, "%s shared home-yard scene should include seam validation camera %s" % [track_id, node_path])

func _assert_no_stage_owned_exterior_nodes(node: Node, track_id: String, holder_name: String, path: String) -> void:
	for child in node.get_children():
		var child_name := str(child.name)
		var child_path := "%s/%s" % [path, child_name]
		var lower := child_name.to_lower()
		var is_forbidden := lower.begins_with("exterior") or lower.contains("roof") or lower.contains("gable")
		assert_true(not is_forbidden, "%s %s must not own exterior shell node %s" % [track_id, holder_name, child_path])
		_assert_no_stage_owned_exterior_nodes(child, track_id, holder_name, child_path)

func _assert_home_yard_exterior_shell(root: Node, track_id: String) -> void:
	var shell := root.get_node_or_null("ExteriorShell")
	assert_true(shell != null, "%s should include an exterior shell holder" % track_id)
	if shell == null:
		return
	for node_name in [
		"ContinuousStoneFoundationPlinth",
		"FrontPorchTaperedColumnLeftBase",
		"FrontPorchTaperedColumnRightShaft",
		"FrontPorchBeam",
		"FrontDoorDeepJambLeft",
		"FrontDoorLintelHeader",
		"FrontGutterRun",
		"BackGutterRun",
		"ChimneyMasonryStack",
		"ServiceElectricMeter",
	]:
		assert_true(shell.get_node_or_null(node_name) != null, "%s exterior shell should include architectural assembly node %s" % [track_id, node_name])

func _assert_home_yard_roof_and_attic_contract(root: Node, track_id: String) -> void:
	var roof := root.get_node_or_null("Roof")
	assert_true(roof != null, "%s should include a roof holder" % track_id)
	if roof == null:
		return
	for node_name in [
		"MainRoofLeftPlane",
		"MainRoofRightPlane",
		"MainRoofRidgeCap",
		"MainFrontGableWall",
		"MainBackGableWall",
		"GarageCrossGableRidge",
		"FrontPorchGableRidge",
		"UpperAtticRoofLeftPlane",
		"UpperAtticRoofRightPlane",
		"UpperAtticRoofRidgeCap",
		"UpperDormerCheekLeft",
		"UpperDormerCheekRight",
		"UpperDormerFrontGableWall",
		"UpperDormerBackGableWall",
		"GarageValleyCoverFront",
		"UpperDormerValleyCoverLeft",
	]:
		assert_true(roof.get_node_or_null(node_name) != null, "%s roof system should include measured assembly node %s" % [track_id, node_name])
	var massing_contract := str(roof.get_meta("massing_contract", ""))
	assert_true(massing_contract.contains("single craftsman primary gable"), "%s roof should record one cohesive massing hierarchy" % track_id)
	assert_true(massing_contract.contains("no layer-cake"), "%s roof should reject layer-cake exposed boxes" % track_id)
	_assert_ridge_axis(roof, "MainRoofRidgeCap", "z", track_id)
	_assert_ridge_axis(roof, "UpperAtticRoofRidgeCap", "z", track_id)
	_assert_ridge_axis(roof, "GarageCrossGableRidge", "x", track_id)
	_assert_ridge_axis(roof, "FrontPorchGableRidge", "x", track_id)
	var left_plane := roof.get_node_or_null("UpperAtticRoofLeftPlane")
	var right_plane := roof.get_node_or_null("UpperAtticRoofRightPlane")
	for plane in [left_plane, right_plane]:
		assert_true(plane != null and plane is MeshInstance3D, "%s attic roof plane should be real mesh geometry" % track_id)
		if plane != null:
			assert_equal(str(plane.get_meta("span_axis", "")), "x", "%s attic roof plane should slope across the declared span axis" % track_id)
			assert_true(float(plane.get_meta("slope_delta_y", 0.0)) > 0.0, "%s attic roof plane should have visible rise" % track_id)
	var attic := root.get_node_or_null("Attic")
	assert_true(attic != null, "%s should include attic holder" % track_id)
	if attic != null:
		assert_true(attic.get_node_or_null("InteriorPartitions/AtticWestKneePartition") != null, "%s attic should include contract-owned west knee partition" % track_id)
		assert_true(attic.get_node_or_null("InteriorPartitions/AtticEastKneePartition") != null, "%s attic should include contract-owned east knee partition" % track_id)
	assert_true(root.find_child("RoofMassPlaceholder", true, false) == null, "%s should not keep a visible flat roof placeholder" % track_id)

func _assert_ridge_axis(roof: Node, node_name: String, expected_axis: String, track_id: String) -> void:
	var node := roof.get_node_or_null(node_name) as MeshInstance3D
	assert_true(node != null, "%s roof should include ridge cap %s" % [track_id, node_name])
	if node == null:
		return
	var bounds := _mesh_instance_global_aabb(node)
	if expected_axis == "z":
		assert_true(bounds.size.z > bounds.size.x, "%s %s should run along Z, not across the whole facade" % [track_id, node_name])
	else:
		assert_true(bounds.size.x > bounds.size.z, "%s %s should run along X, not float as a depth strip" % [track_id, node_name])

func _assert_home_yard_landscape_and_assets(root: Node, track_id: String) -> void:
	for node_path in [
		"Foundation/HouseContinuousFoundationPlinth",
		"Openings/KitchenPatioDoorFrame",
		"PorchesDecks/FrontPorchDeck",
		"PorchesDecks/BackDeckLanding",
		"GarageService/GarageToolBench",
		"Site/ConcreteStreetCurb",
		"Site/PublicSidewalk",
		"Site/MailboxBox",
		"Site/ServiceTrashBinA",
		"Yard/ToyboxTreeSwingLandingPatch",
		"Yard/ToyboxTreeTireSwing",
		"Yard/GardenVegetableRow00",
		"Yard/MixedGrassHeightClump00",
		"ValidationCameras/ExteriorRooflineCamera",
		"ValidationCameras/AtticGableProfileCamera",
		"ValidationCameras/FrontPorchCloseupCamera",
		"ValidationCameras/GarageServiceSideCamera",
		"ValidationCameras/ToyboxTreeSwingCamera",
	]:
		assert_true(root.get_node_or_null(node_path) != null, "%s shared home-yard scene should include %s" % [track_id, node_path])

func _assert_home_yard_kitchen_readability(root: Node) -> void:
	var kit := root.get_node_or_null("MainFloor/KitchenRaceReadabilityKit")
	assert_true(kit != null, "Kitchen shared route should include a player-height readability kit")
	if kit == null:
		return
	var contract: Variant = kit.get_meta("player_readability_contract", {})
	assert_true(contract is Dictionary, "Kitchen readability kit should export a player readability contract")
	if contract is Dictionary:
		assert_equal(str((contract as Dictionary).get("course_id", "")), "kitchen", "Kitchen readability contract should identify the kitchen course")
		assert_true(str((contract as Dictionary).get("surface", "")).contains("toy-track"), "Kitchen readability contract should name a readable driving surface")
	for node_name in [
		"KitchenReadableRoute00Mat",
		"KitchenReadableRoute00LeftEdge",
		"KitchenReadableRoute00RightEdge",
		"KitchenStartFinishFloorBand",
		"KitchenStartFinishBanner",
		"KitchenFirstTurnBillboard",
		"KitchenPantryStackLandmarkA",
		"KitchenSinkIslandInfieldEdge",
		"KitchenFridgeLandmarkPanel",
		"KitchenWarmUndercabinetGlow",
	]:
		assert_true(kit.get_node_or_null(node_name) != null, "Kitchen readability kit should include %s" % node_name)
	assert_true(root.get_node_or_null("ValidationCameras/KitchenStartPlayerCamera") != null, "Kitchen should include a start-grid player-height validation camera")
	assert_true(root.get_node_or_null("ValidationCameras/KitchenFirstTurnPlayerCamera") != null, "Kitchen should include a first-turn player-height validation camera")

func _assert_closed_grid_route_visual_contract(definition: TrackDefinition, track_id: String) -> void:
	assert_true(definition.closed_loop, "%s should be authored as a closed loop" % track_id)
	var cells := (definition.road_grid_layout.get("ordered_route_cells", []) as Array)
	var cell_items := _grid_cell_items(definition.road_grid_layout)
	for i in range(cells.size()):
		var current := _vector3i_from_value(cells[i])
		var next := _vector3i_from_value(cells[(i + 1) % cells.size()])
		assert_true(_route_step_is_continuous(current, next), "%s route cell %d should connect horizontally to the next cell, including ramp transitions and the lap seam" % [track_id, i])
		var previous := _vector3i_from_value(cells[(i - 1 + cells.size()) % cells.size()])
		var after_next := _vector3i_from_value(cells[(i + 2) % cells.size()])
		var item := int(cell_items.get(current, -1))
		var vertical_delta := next.y - current.y
		if vertical_delta != 0:
			var lower_cell := current if current.y < next.y else next
			var lower_item := int(cell_items.get(lower_cell, -1))
			assert_true(_is_ramp_item(lower_item), "%s route index %d changes elevation but the lower cell is not a ramp tile" % [track_id, i])
			assert_true(not _is_horizontal_corner(previous, current, next), "%s route index %d changes elevation on a corner cell; straight ramp tiles must not replace turn geometry" % [track_id, i])
			assert_equal(previous.y, current.y, "%s route index %d ramp should have a flat same-level approach before changing elevation" % [track_id, i])
			assert_equal(after_next.y, next.y, "%s route index %d ramp should have a flat same-level landing before the next elevation or turn" % [track_id, i])
			assert_equal(_horizontal_delta(previous, current), _horizontal_delta(current, next), "%s route index %d ramp should have a straight same-direction approach" % [track_id, i])
			assert_equal(_horizontal_delta(current, next), _horizontal_delta(next, after_next), "%s route index %d ramp should land into a straight same-direction cell before turning" % [track_id, i])
			continue
		if previous.y > current.y:
			assert_true(_is_ramp_item(item), "%s descent landing cell should own the ramp tile at route index %d" % [track_id, i])
			assert_true(not _is_horizontal_corner(previous, current, next), "%s descent ramp tile at route index %d should remain straight through the landing" % [track_id, i])
			continue
		var is_corner := _is_horizontal_corner(previous, current, next)
		assert_true(not _is_ramp_item(item), "%s ramp tile at route index %d should have an outgoing elevation change" % [track_id, i])
		if item == TrackGridRoadBuilder.TILE_START:
			assert_true(not is_corner, "%s start tile must sit on a straight route cell so the lap seam renders closed" % track_id)
		elif item == TrackGridRoadBuilder.TILE_STRAIGHT:
			assert_true(not is_corner, "%s straight tile at route index %d should not hide a corner seam" % [track_id, i])
		elif item == TrackGridRoadBuilder.TILE_CORNER:
			assert_true(is_corner, "%s corner tile at route index %d should be a real route corner" % [track_id, i])

func _assert_generated_route_has_verticality(definition: TrackDefinition, track_id: String) -> void:
	var cells := (definition.road_grid_layout.get("ordered_route_cells", []) as Array)
	var cell_items := _grid_cell_items(definition.road_grid_layout)
	var y_levels := {}
	var ramp_tile_count := 0
	for value in cells:
		var cell := _vector3i_from_value(value)
		y_levels[cell.y] = true
		if _is_ramp_item(int(cell_items.get(cell, -1))):
			ramp_tile_count += 1
	assert_true(y_levels.size() >= 2, "%s concept includes playable elevation, so ordered_route_cells should use multiple Y levels" % track_id)
	assert_true(ramp_tile_count >= 2, "%s should include at least one climb and one descent ramp tile" % track_id)
	var min_y := 999999.0
	var max_y := -999999.0
	for point in definition.route_points:
		min_y = minf(min_y, point.y)
		max_y = maxf(max_y, point.y)
	assert_true(max_y - min_y >= 3.9, "%s route_points should expose a visible one-cell elevation change" % track_id)

func _grid_cell_items(layout: Dictionary) -> Dictionary:
	var out := {}
	for value in layout.get("cells", []):
		if not (value is Dictionary):
			continue
		var data := value as Dictionary
		out[_vector3i_from_value(data.get("cell", Vector3i.ZERO))] = int(data.get("item", -1))
	return out

func _vector3i_from_value(value: Variant) -> Vector3i:
	if value is Vector3i:
		return value as Vector3i
	if value is Vector3:
		var point := value as Vector3
		return Vector3i(roundi(point.x), roundi(point.y), roundi(point.z))
	if value is Array:
		var array := value as Array
		if array.size() >= 3:
			return Vector3i(roundi(float(array[0])), roundi(float(array[1])), roundi(float(array[2])))
	return Vector3i.ZERO

func _route_step_is_continuous(a: Vector3i, b: Vector3i) -> bool:
	var delta := b - a
	var horizontal_distance := absi(delta.x) + absi(delta.z)
	return horizontal_distance == 1 and absi(delta.y) <= 1

func _is_horizontal_corner(previous: Vector3i, current: Vector3i, next: Vector3i) -> bool:
	return _horizontal_delta(current, previous) + _horizontal_delta(current, next) != Vector3i.ZERO

func _horizontal_delta(from_cell: Vector3i, to_cell: Vector3i) -> Vector3i:
	return Vector3i(to_cell.x - from_cell.x, 0, to_cell.z - from_cell.z)

func _is_ramp_item(item: int) -> bool:
	return RAMP_TILE_ITEMS.has(item)

func _spawn_grid_starts_at_route_origin(spawns: Array[Vector4], route_points: Array[Vector3]) -> bool:
	if spawns.size() < 2 or route_points.size() < 2:
		return false
	var origin := route_points[0]
	var forward := route_points[1] - route_points[0]
	forward.y = 0.0
	if forward.length_squared() <= 0.001:
		forward = Vector3.FORWARD
	forward = forward.normalized()
	var right := Vector3(forward.z, 0.0, -forward.x).normalized()
	for i in range(2):
		var spawn := spawns[i]
		var position := Vector3(spawn.x, spawn.y, spawn.z)
		var from_origin := position - origin
		var forward_distance := from_origin.dot(forward)
		var lateral_distance := from_origin.dot(right)
		if absf(forward_distance) > 0.1:
			return false
		if absf(lateral_distance) < 0.5:
			return false
	return true

func _find_authoring_road_grid(root: Node) -> Node:
	var direct := root.get_node_or_null("RoadGridMap")
	if direct != null:
		return direct
	var nested := root.get_node_or_null("Track/RoadGridMap")
	if nested != null:
		return nested
	return null

func _mesh_instance_global_aabb(mesh_instance: MeshInstance3D) -> AABB:
	var local := mesh_instance.get_aabb()
	var corners: Array[Vector3] = [
		local.position,
		local.position + Vector3(local.size.x, 0, 0),
		local.position + Vector3(0, local.size.y, 0),
		local.position + Vector3(0, 0, local.size.z),
		local.position + Vector3(local.size.x, local.size.y, 0),
		local.position + Vector3(local.size.x, 0, local.size.z),
		local.position + Vector3(0, local.size.y, local.size.z),
		local.end,
	]
	var xform := mesh_instance.global_transform if mesh_instance.is_inside_tree() else mesh_instance.transform
	var bounds := AABB(xform * corners[0], Vector3.ZERO)
	for i in range(1, corners.size()):
		bounds = bounds.expand(xform * corners[i])
	return bounds

func _expected_definition_ground_size(track_id: String) -> Vector2:
	return HOME_YARD_GROUND_SIZE

func _expected_editable_floor_size(track_id: String) -> Vector2:
	if track_id == "kitchen":
		return KITCHEN_EDITABLE_FLOOR_SIZE
	if BACKYARD_TRACK_IDS.has(track_id):
		return BACKYARD_FLOOR_SIZE
	return INDOOR_FLOOR_SIZE

func _floor_mesh_size_from_root(root: Node) -> Vector2:
	var mesh_instance := root.get_node_or_null("floor/MeshInstance3D") as MeshInstance3D
	if mesh_instance == null:
		mesh_instance = root.get_node_or_null("BackyardShell/floor/MeshInstance3D") as MeshInstance3D
	if mesh_instance == null:
		mesh_instance = root.get_node_or_null("Track/floor/MeshInstance3D") as MeshInstance3D
	if mesh_instance == null:
		var floor_holder := root.find_child("floor", true, false)
		if floor_holder != null:
			mesh_instance = floor_holder.get_node_or_null("MeshInstance3D") as MeshInstance3D
	if mesh_instance != null and mesh_instance.mesh is PlaneMesh:
		return (mesh_instance.mesh as PlaneMesh).size
	return Vector2.ZERO
