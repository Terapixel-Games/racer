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
const HOME_YARD_MAP_ID := "home_yard_v3"
const OLD_HOME_YARD_V2_MAP_ID := "home_yard_v2"
const HOME_YARD_MAP_SCENE := "res://assets/gameplay/tracks/home_yard_v3/home_yard_v3_map.tscn"
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
const HOME_YARD_GROUND_SIZE := Vector2(720.0, 680.0)
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
	assert_true(TrackCatalog.get_map_definition("home_yard") == null, "Old home_yard generated package should be hidden from normal catalog resolution")
	assert_true(TrackCatalog.get_map_definition(OLD_HOME_YARD_V2_MAP_ID) == null, "Old home_yard_v2 generated package should be hidden from normal catalog resolution")

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

func test_home_yard_start_validation_cameras_can_be_made_current() -> void:
	var packed := load(HOME_YARD_MAP_SCENE) as PackedScene
	assert_true(packed != null, "Home Yard shared map scene should load")
	if packed == null:
		return
	var root := packed.instantiate() as Node3D
	assert_true(root != null, "Home Yard shared map scene should instantiate")
	if root == null:
		return
	scene_tree.root.add_child(root)
	var camera_paths := {
		"attic": "ValidationCameras/AtticStartPlayerCamera",
		"bedroom": "ValidationCameras/BedroomStartPlayerCamera",
		"garden": "ValidationCameras/GardenStartPlayerCamera",
		"glam_closet": "ValidationCameras/GlamClosetStartPlayerCamera",
		"kitchen": "ValidationCameras/KitchenStartPlayerCamera",
		"outdoor_playground": "ValidationCameras/OutdoorPlaygroundStartPlayerCamera",
		"playroom": "ValidationCameras/PlayroomStartPlayerCamera",
		"sandbox": "ValidationCameras/SandboxStartPlayerCamera",
	}
	for track_id in SELECTABLE_TRACK_IDS:
		var camera := root.get_node_or_null(str(camera_paths[track_id])) as Camera3D
		assert_true(camera != null, "%s should have a start player validation camera" % track_id)
		if camera == null:
			continue
		camera.make_current()
		assert_equal(root.get_viewport().get_camera_3d(), camera, "%s start validation camera should be selectable as the current cinematic camera" % track_id)
	root.queue_free()

func test_home_yard_route_shell_validation_cameras_can_be_made_current() -> void:
	var packed := load(HOME_YARD_MAP_SCENE) as PackedScene
	assert_true(packed != null, "Home Yard shared map scene should load")
	if packed == null:
		return
	var root := packed.instantiate() as Node3D
	assert_true(root != null, "Home Yard shared map scene should instantiate")
	if root == null:
		return
	scene_tree.root.add_child(root)
	for camera_path in [
		"ValidationCameras/ExteriorRooflineCamera",
		"ValidationCameras/RoofGambrelSideProfileCamera",
		"ValidationCameras/AtticGableProfileCamera",
		"ValidationCameras/MainFloorRouteStartsCamera",
		"ValidationCameras/UpperFloorRouteStartsCamera",
		"ValidationCameras/YardCourseOverviewCamera",
	]:
		var camera := root.get_node_or_null(camera_path) as Camera3D
		assert_true(camera != null, "Home Yard route/shell validation camera %s should exist" % camera_path)
		if camera == null:
			continue
		camera.make_current()
		assert_equal(root.get_viewport().get_camera_3d(), camera, "Home Yard route/shell validation camera %s should be selectable as the current cinematic camera" % camera_path)
	root.queue_free()

func test_home_yard_human_scale_reference_clears_first_floor_blockers() -> void:
	var packed := load(HOME_YARD_MAP_SCENE) as PackedScene
	assert_true(packed != null, "Home Yard shared map scene should load")
	if packed == null:
		return
	var root := packed.instantiate() as Node3D
	assert_true(root != null, "Home Yard shared map scene should instantiate")
	if root == null:
		return
	scene_tree.root.add_child(root)
	var human := root.get_node_or_null("ConceptReference/HumanScaleReference") as Node3D
	assert_true(human != null, "Home Yard should include a human scale reference")
	if human != null:
		assert_true(human.is_visible_in_tree(), "Source-scene human scale reference should stay visible for editor/noclip scale review")
		var proxy_size := human.get_meta("clearance_proxy_size", Vector3(16.0, 32.0, 16.0)) as Vector3
		var proxy := AABB(human.global_transform.origin + Vector3(-proxy_size.x * 0.5, 0.0, -proxy_size.z * 0.5), proxy_size)
		for holder_path in ["MainFloor/RoomFinishes", "MainFloor/InteriorWalls", "VerticalConnectors"]:
			var holder := root.get_node_or_null(holder_path)
			assert_true(holder != null, "Home Yard should include %s for human reference clearance audit" % holder_path)
			if holder != null:
				_assert_no_visible_mesh_intersects_aabb(holder, proxy, "ConceptReference", "Human scale reference should not intersect first-floor furniture, walls, or ramp geometry")
	root.queue_free()

func test_home_yard_scale_contract_separates_human_house_from_toy_racers() -> void:
	var packed := load(HOME_YARD_MAP_SCENE) as PackedScene
	assert_true(packed != null, "Home Yard shared map scene should load")
	if packed == null:
		return
	var root := packed.instantiate() as Node3D
	assert_true(root != null, "Home Yard shared map scene should instantiate")
	if root == null:
		return
	var contract: Variant = root.get_meta("scale_contract", {})
	assert_true(contract is Dictionary, "Home Yard should export a machine-readable scale contract")
	if contract is Dictionary:
		var data := contract as Dictionary
		assert_equal(str(data.get("id", "")), "home_yard_v3_human_house_toy_racer_scale_v1", "Scale contract should have a stable id")
		assert_equal(float(data.get("units_per_floor_plan_foot", 0.0)), 4.0, "Scale contract should lock 4 Godot units per floor-plan foot")
		var human: Dictionary = data.get("human_house_scale", {})
		assert_equal(float(human.get("reference_height_units", 0.0)), 25.0, "Human reference should be 6.25 ft / 25 units")
		assert_equal(float(human.get("clearance_proxy_height_units", 0.0)), 32.0, "Human clearance proxy should remain 8 ft / 32 units")
		assert_equal(float(human.get("occupied_ceiling_clearance_units", 0.0)), 40.0, "Occupied rooms should retain 10 ft / 40 unit ceiling clearances")
		var racer: Dictionary = data.get("toy_racer_scale", {})
		assert_true(float(racer.get("observed_visual_height_units_max", 999.0)) <= 1.5, "Runtime toy racers should remain under 1.5 units tall")
		assert_true(float(racer.get("route_swept_width_units", 0.0)) >= 6.0, "Toy racer swept route width should include gameplay clearance beyond raw mesh size")
		assert_true(float(racer.get("chase_camera_clearance_height_units", 0.0)) >= 12.0, "Scale contract should include third-person camera height clearance")
		var road: Dictionary = data.get("road_scale", {})
		assert_equal(float(road.get("road_width_units", 0.0)), 16.0, "Plastic road width should stay 16 units / 4 ft")
	var human_ref := root.get_node_or_null("ConceptReference/HumanScaleReference") as Node3D
	assert_true(human_ref != null, "Home Yard should include human scale reference metadata")
	if human_ref != null:
		assert_equal(str(human_ref.get_meta("scale_contract_id", "")), "home_yard_v3_human_house_toy_racer_scale_v1", "Human reference should point at the scale contract")
		assert_equal(float(human_ref.get_meta("declared_human_height_units", 0.0)), 25.0, "Human reference should declare visual human height separately from clearance proxy")
		assert_equal(float(human_ref.get_meta("clearance_proxy_height_ft", 0.0)), 8.0, "Human clearance proxy should be explicitly identified as an 8 ft envelope")
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
	_assert_home_yard_stage_asset_manifest(definition, track_id)
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
	assert_equal(str(definition.get_meta("track_map_id", "")), HOME_YARD_MAP_ID, "%s should resolve through the scratch-built home-yard v3 map" % track_id)
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
	_assert_home_yard_metadata_stage_asset_manifest(metadata, track_id)
	_assert_home_yard_metadata_stage_asset_manifest(package_metadata, track_id)

func _assert_home_yard_stage_asset_manifest(definition: TrackDefinition, track_id: String) -> void:
	var landmark_count := 0
	for prop in definition.stage_props:
		assert_equal(str(prop.get("kind", "")), "scene", "%s stage prop %s should be scene-backed, not a placeholder box" % [track_id, str(prop.get("id", ""))])
		assert_true(ResourceLoader.exists(str(prop.get("asset_path", ""))), "%s stage prop %s should reference an existing asset" % [track_id, str(prop.get("id", ""))])
		assert_equal(str(prop.get("collision_mode", "")), "visual", "%s stage prop %s should be visual-only by default" % [track_id, str(prop.get("id", ""))])
		assert_equal(str(prop.get("route_clearance", "")), "outside_route_corridor", "%s stage prop %s should declare route clearance" % [track_id, str(prop.get("id", ""))])
		assert_equal(str(prop.get("scale_contract_id", "")), "home_yard_v3_human_house_toy_racer_scale_v1", "%s stage prop %s should declare the scale contract" % [track_id, str(prop.get("id", ""))])
		assert_true(not str(prop.get("scale_class", "")).is_empty(), "%s stage prop %s should declare whether it is human-scale furnishing, toy-scale cue, or yard landmark" % [track_id, str(prop.get("id", ""))])
		assert_true(prop.get("target_dimensions_units", Vector3.ZERO) is Vector3, "%s stage prop %s should declare target dimensions for scale review" % [track_id, str(prop.get("id", ""))])
		assert_equal(str(prop.get("scale_validation_status", "")), "declared_pending_import_aabb_review", "%s stage prop %s should require imported AABB scale review before production acceptance" % [track_id, str(prop.get("id", ""))])
		assert_true(not str(prop.get("asset_source", "")).is_empty(), "%s stage prop %s should declare an asset source" % [track_id, str(prop.get("id", ""))])
		assert_true(not str(prop.get("license_origin", "")).is_empty(), "%s stage prop %s should declare license/origin" % [track_id, str(prop.get("id", ""))])
		assert_true(str(prop.get("validation_camera", "")).begins_with("ValidationCameras/"), "%s stage prop %s should declare a validation camera" % [track_id, str(prop.get("id", ""))])
		if str(prop.get("gameplay_tag", "")) == "landmark":
			landmark_count += 1
	assert_true(landmark_count >= 3, "%s should include multiple themed landmark assets" % track_id)

func _assert_home_yard_metadata_stage_asset_manifest(metadata: Dictionary, track_id: String) -> void:
	var props := metadata.get("stage_props", []) as Array
	assert_true(props.size() >= 5, "%s metadata should export the stage asset manifest" % track_id)
	for prop_value in props:
		assert_true(prop_value is Dictionary, "%s metadata stage prop should be a dictionary" % track_id)
		if not (prop_value is Dictionary):
			continue
		var prop := prop_value as Dictionary
		assert_equal(str(prop.get("kind", "")), "scene", "%s metadata stage prop %s should be scene-backed" % [track_id, str(prop.get("id", ""))])
		assert_true(not str(prop.get("asset_path", "")).is_empty(), "%s metadata stage prop %s should export asset path" % [track_id, str(prop.get("id", ""))])
		assert_true(not str(prop.get("asset_source", "")).is_empty(), "%s metadata stage prop %s should export asset source" % [track_id, str(prop.get("id", ""))])
		assert_true(not str(prop.get("license_origin", "")).is_empty(), "%s metadata stage prop %s should export license/origin" % [track_id, str(prop.get("id", ""))])
		assert_equal(str(prop.get("route_clearance", "")), "outside_route_corridor", "%s metadata stage prop %s should export route clearance" % [track_id, str(prop.get("id", ""))])
		assert_equal(str(prop.get("scale_contract_id", "")), "home_yard_v3_human_house_toy_racer_scale_v1", "%s metadata stage prop %s should export scale contract id" % [track_id, str(prop.get("id", ""))])
		assert_true(not str(prop.get("scale_class", "")).is_empty(), "%s metadata stage prop %s should export scale class" % [track_id, str(prop.get("id", ""))])
		assert_true(prop.has("target_dimensions_units"), "%s metadata stage prop %s should export target dimensions" % [track_id, str(prop.get("id", ""))])

func test_backyard_scenes_do_not_reference_old_meshy_landmarks() -> void:
	for track_id in BACKYARD_TRACK_IDS:
		var definition := TrackCatalog.get_definition(track_id)
		assert_true(definition != null, "%s definition should load" % track_id)
		if definition == null:
			continue
		_assert_scene_text_excludes_old_backyard_resources(definition.dressing_scene_path)
		_assert_scene_text_excludes_old_backyard_resources(definition.preview_dressing_scene_path)

func test_home_yard_instanced_assets_are_not_flattened_into_map_scene() -> void:
	_assert_scene_text_excludes_instanced_asset_descendants(HOME_YARD_MAP_SCENE)

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

func _assert_scene_text_excludes_instanced_asset_descendants(path: String) -> void:
	assert_true(ResourceLoader.exists(path), "%s should exist" % path)
	var file := FileAccess.open(path, FileAccess.READ)
	assert_true(file != null, "%s should be readable" % path)
	if file == null:
		return
	var text := file.get_as_text()
	file.close()
	for parent_path in [
		"MainFloor/KitchenFridge/",
		"MainFloor/KitchenSink/",
		"MainFloor/DiningTable/",
		"MainFloor/PlayroomToyBear/",
		"UpperFloor/BedroomBed/",
		"UpperFloor/BedroomRug/",
		"Attic/AtticOldChest/",
		"Attic/AtticJackInTheBox/",
		"Yard/PlaygroundStructure/",
		"Yard/ToyboxTreeTireSwing/",
		"Yard/SandboxFossil/",
		"Yard/GardenLogBush/",
	]:
		assert_true(not text.contains("parent=\"%s" % parent_path), "Home Yard map should save %s as an external scene instance without flattened imported descendants" % parent_path.trim_suffix("/"))

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
	var inset := float(data.get("usable_inset", 0.0))
	assert_true(route_min.x >= zone_min.x + inset - 0.01, "%s route should keep the planned wall/furniture inset on min X" % track_id)
	assert_true(route_max.x <= zone_max.x - inset + 0.01, "%s route should keep the planned wall/furniture inset on max X" % track_id)
	assert_true(route_min.z >= zone_min.z + inset - 0.01, "%s route should keep the planned wall/furniture inset on min Z" % track_id)
	assert_true(route_max.z <= zone_max.z - inset + 0.01, "%s route should keep the planned wall/furniture inset on max Z" % track_id)
	var road_surface_y := float(data.get("road_surface_y", 0.0))
	var floor_top_y := float(data.get("floor_top_y", 0.0))
	var minimum_clearance_y := float(data.get("minimum_clearance_y", 0.0))
	assert_true(road_surface_y > floor_top_y, "%s road surface should sit above the finished floor/ground" % track_id)
	assert_true(minimum_clearance_y >= 0.5, "%s route envelope should declare toy-track floor clearance" % track_id)
	assert_true(road_surface_y - floor_top_y >= minimum_clearance_y - 0.01, "%s road surface should have the declared floor clearance" % track_id)
	assert_true(float(data.get("corridor_width", 0.0)) >= definition.road_width, "%s route corridor should cover the road width" % track_id)
	assert_equal(str(data.get("scale_contract_id", "")), "home_yard_v3_human_house_toy_racer_scale_v1", "%s route envelope should point at the scale contract" % track_id)
	assert_true(float(data.get("toy_racer_visual_height_units_max", 0.0)) <= 1.5, "%s route envelope should carry toy racer visual height, not human height" % track_id)
	assert_true(float(data.get("toy_racer_route_swept_width_units", 0.0)) >= 6.0, "%s route envelope should reserve toy racer swept width" % track_id)
	assert_true(float(data.get("toy_racer_drift_margin_units", 0.0)) >= 5.0, "%s route envelope should reserve drift margin" % track_id)
	assert_true(float(data.get("third_person_camera_clearance_height_units", 0.0)) >= 12.0, "%s route envelope should reserve third-person camera height" % track_id)
	if track_id == "attic":
		assert_true(float(data.get("roof_clearance_max_y", 0.0)) >= route_max.y + 8.0, "attic route should stay below the Dutch gambrel roof clearance")
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
	_assert_home_yard_generated_scene_provenance_contract(root, track_id)
	_assert_home_yard_whole_unit_visual_contract(root, track_id)
	_assert_home_yard_route_infrastructure_is_classified_and_dressed(root, track_id)
	_assert_home_yard_validation_camera_matrix(root, track_id)
	_assert_home_yard_exterior_visual_completeness(root, track_id)
	_assert_home_yard_yard_and_service_visual_completeness(root, track_id)
	_assert_home_yard_shared_shell_ownership(root, track_id)
	_assert_home_yard_interior_placeholder_replacements(root, track_id)
	_assert_home_yard_exterior_shell(root, track_id)
	_assert_home_yard_roof_and_attic_contract(root, track_id)
	_assert_home_yard_landscape_and_assets(root, track_id)
	_assert_validation_only_nodes_are_non_rendered(root, track_id)
	_assert_no_broad_foundation_slab_inside_first_floor(root, track_id)
	_assert_no_roof_closure_blocks_attic(root, track_id)
	_assert_no_visible_blockout_nodes(root, track_id)
	if track_id == "kitchen":
		_assert_home_yard_kitchen_readability(root)
	assert_true(root.get_node_or_null("VerticalConnectors/MainStairLowerFlightKenneySteps") != null, "%s should include sourced main stair lower flight geometry" % track_id)
	assert_true(root.get_node_or_null("VerticalConnectors/MainStairUpperFlightKenneySteps") != null, "%s should include sourced main stair upper flight geometry" % track_id)
	assert_true(root.get_node_or_null("VerticalConnectors/AtticPullDownStairKenneySteps") != null, "%s should include sourced attic access stair geometry" % track_id)
	_assert_home_yard_vertical_circulation_continuity(root, track_id)
	assert_true(root.get_node_or_null("VerticalConnectors/MainToUpperToyRamp") == null, "%s should not keep the blue placeholder toy ramp as house circulation" % track_id)
	assert_true(root.get_node_or_null("VerticalConnectors/UpperToAtticToyRamp") == null, "%s should not keep the red placeholder toy ramp as attic circulation" % track_id)
	assert_true(root.get_node_or_null("CourseRoutes/%sRoutePreview" % track_id.capitalize()) != null, "%s should include a route preview holder" % track_id)
	var audit_marker := root.get_node_or_null("CourseRoutes/%sRoutePreview/RouteContainmentAuditBox" % track_id.capitalize())
	assert_true(audit_marker != null, "%s should include a route containment audit marker" % track_id)
	if audit_marker != null:
		assert_equal(str(audit_marker.get_meta("visual_state", "")), "metadata_only_non_rendered", "%s route containment audit should not render slab geometry" % track_id)
	assert_true(root.find_child("PlasticTrackSegment00", true, false) == null, "%s shared scene should not render duplicate plastic slab route previews" % track_id)
	assert_true(root.find_child("VerticalChangeMarker00", true, false) == null, "%s shared scene should not render duplicate vertical route markers through the roof" % track_id)

func _assert_home_yard_floor_plan_contract(root: Node, track_id: String) -> void:
	var contract: Variant = root.get_meta("floor_plan_contract", {})
	assert_true(contract is Dictionary, "%s shared home-yard scene should include a floor-plan contract" % track_id)
	if not (contract is Dictionary):
		return
	var data := contract as Dictionary
	assert_equal(str(data.get("selected_alternative", "")), "Residential Open World V3", "%s should record the selected floor-plan alternative" % track_id)
	assert_true(str(data.get("site_orientation", "")).contains("front/street"), "%s should record front/street site orientation" % track_id)
	assert_true(data.get("floor_heights", {}) is Dictionary, "%s should record vertical floor relationships" % track_id)
	assert_true(str(data.get("vertical_circulation_contract", "")).contains("architectural vertical circulation"), "%s should record architectural stair circulation" % track_id)
	var vertical_links: Variant = data.get("vertical_links", [])
	assert_true(vertical_links is Array and (vertical_links as Array).size() >= 2, "%s floor-plan contract should include main-to-upper and upper-to-attic vertical links" % track_id)
	if vertical_links is Array:
		assert_true(_vertical_link_has_id(vertical_links as Array, "MainStairEntryToUpperHall"), "%s floor-plan contract should include main stair vertical link" % track_id)
		assert_true(_vertical_link_has_id(vertical_links as Array, "AtticPullDownStairUpperHallToAttic"), "%s floor-plan contract should include attic access vertical link" % track_id)
	assert_equal(float(data.get("ceiling_clear_height", 0.0)), 40.0, "%s should record 10 ft / 40 unit occupied ceiling clearances" % track_id)
	assert_true(data.get("lot_bounds", {}) is Dictionary, "%s should record the larger residential lot bounds" % track_id)
	assert_true(str(data.get("free_drive_contract", "")).contains("doggie door"), "%s should record the free-drive doggie-door contract" % track_id)
	assert_true(str(data.get("human_scale_reference", "")).contains("characterLargeMale.blend"), "%s should record the Kenney human scale reference" % track_id)
	assert_true(str(data.get("route_contract", "")) != "", "%s should record route envelope contract requirements" % track_id)
	assert_true(str(data.get("roof_contract", "")).contains("Dutch gambrel"), "%s should record the Dutch gambrel attic roof contract" % track_id)
	assert_true(str(data.get("shell_ownership", "")).contains("ExteriorShell"), "%s should record shared shell ownership" % track_id)
	var wall_schedule: Variant = root.get_meta("interior_wall_schedule", [])
	assert_true(wall_schedule is Array, "%s shared home-yard scene should include an interior wall schedule" % track_id)
	if wall_schedule is Array:
		var schedule := wall_schedule as Array
		assert_true(schedule.size() >= 10, "%s interior wall schedule should cover connected room seams" % track_id)
		for expected_wall_id in ["KitchenDiningCasedOpening", "KitchenPlayroomDivider", "PlayroomLivingCasedOpening", "GarageInteriorBackWall", "BedroomGlamCasedOpening", "DoggieDoorInteriorThreshold", "AtticWestKneePartition"]:
			assert_true(_wall_schedule_has_id(schedule, expected_wall_id), "%s interior wall schedule should include %s" % [track_id, expected_wall_id])
	var envelopes: Variant = root.get_meta("route_envelopes", {})
	assert_true(envelopes is Dictionary and (envelopes as Dictionary).has(track_id), "%s shared home-yard scene should include numeric route envelopes" % track_id)
	var conflicts: Variant = root.get_meta("clearance_conflicts", [])
	assert_true(conflicts is Array and (conflicts as Array).is_empty(), "%s shared home-yard scene should export no known clearance conflicts" % track_id)

func _assert_home_yard_generated_scene_provenance_contract(root: Node, track_id: String) -> void:
	for holder_path in ["ExteriorShell", "Roof", "Foundation"]:
		var holder := root.get_node_or_null(holder_path)
		assert_true(holder != null, "%s should include %s for generated provenance audit" % [track_id, holder_path])
		if holder != null:
			_assert_visible_generated_meshes_have_provenance(holder, root, track_id)

func _assert_home_yard_whole_unit_visual_contract(root: Node, track_id: String) -> void:
	var contract: Variant = root.get_meta("whole_unit_visual_review_contract", {})
	assert_true(contract is Dictionary, "%s should export a whole-unit visual review contract" % track_id)
	if not (contract is Dictionary):
		return
	var data := contract as Dictionary
	assert_equal(str(data.get("evidence_mode", "")), "clean_runtime_or_cinematic_no_editor_overlays", "%s final visual proof should require clean runtime/cinematic evidence" % track_id)
	var diagnostic_overlays: Variant = data.get("diagnostic_only_overlays", [])
	assert_true(diagnostic_overlays is Array and (diagnostic_overlays as Array).has("editor_camera_icons"), "%s should treat editor camera icons as diagnostic-only evidence" % track_id)
	var course_requirements: Variant = data.get("course_view_requirements", [])
	for requirement in ["start_player", "first_turn_player", "midpoint_route", "chase_readability"]:
		assert_true(course_requirements is Array and (course_requirements as Array).has(requirement), "%s whole-unit contract should require %s course evidence" % [track_id, requirement])
	var blockers: Variant = data.get("beta_blockers", [])
	for blocker in ["flat tray yard", "weak window assembly", "weak porch hierarchy", "unclassified placeholder box", "route infrastructure without material/edge treatment"]:
		assert_true(blockers is Array and (blockers as Array).has(blocker), "%s whole-unit contract should list beta blocker: %s" % [track_id, blocker])

func _assert_home_yard_route_infrastructure_is_classified_and_dressed(root: Node, track_id: String) -> void:
	for node_path in [
		"Attic/RoomFinishes/PopperHighRampLaunchDeck",
		"Attic/RoomFinishes/PopperHighRampLandingDeck",
		"Attic/RoomFinishes/PopperBankedCardboardRamp",
		"Attic/RoomFinishes/PopperCardboardGuardWall",
	]:
		var node := root.get_node_or_null(node_path) as MeshInstance3D
		assert_true(node != null, "%s visible route infrastructure should include %s" % [track_id, node_path])
		if node == null:
			continue
		var data: Variant = node.get_meta("generated_scene_provenance", {})
		assert_true(data is Dictionary, "%s route infrastructure %s should declare generated provenance" % [track_id, node_path])
		if data is Dictionary:
			var provenance := data as Dictionary
			assert_equal(str(provenance.get("visible_class", "")), "route_infrastructure", "%s %s must be classified as route_infrastructure, not generic blockout" % [track_id, node_path])
			assert_true(str(provenance.get("role", "")).contains("route infrastructure"), "%s %s should explain its route-infrastructure role" % [track_id, node_path])
			assert_true(str(provenance.get("forbidden_intersections", "")).contains("third-person chase camera"), "%s %s should forbid chase-camera obstruction" % [track_id, node_path])
			assert_equal(str(provenance.get("validation_gate", "")), "test_home_yard_route_infrastructure_is_classified_and_dressed", "%s %s should point at the route infrastructure gate" % [track_id, node_path])
			assert_true(str(provenance.get("validation_camera", "")).begins_with("ValidationCameras/"), "%s %s should name a validation camera" % [track_id, node_path])
	for edge_path in [
		"Attic/RoomFinishes/PopperHighRampLaunchDeckEdgeLeft",
		"Attic/RoomFinishes/PopperHighRampLaunchDeckEdgeRight",
		"Attic/RoomFinishes/PopperHighRampLandingDeckEdgeLeft",
		"Attic/RoomFinishes/PopperHighRampLandingDeckEdgeRight",
	]:
		assert_true(root.get_node_or_null(edge_path) != null, "%s route infrastructure should include non-placeholder edge treatment %s" % [track_id, edge_path])
	assert_true(root.find_child("AtticBoxWall", true, false) == null, "%s should not keep the old attic box wall blockout; use named route infrastructure instead" % track_id)

func _assert_home_yard_validation_camera_matrix(root: Node, track_id: String) -> void:
	var camera_prefixes := {
		"attic": "Attic",
		"bedroom": "Bedroom",
		"garden": "Garden",
		"glam_closet": "GlamCloset",
		"kitchen": "Kitchen",
		"outdoor_playground": "OutdoorPlayground",
		"playroom": "Playroom",
		"sandbox": "Sandbox",
	}
	assert_true(camera_prefixes.has(track_id), "%s should be a known home-yard public course for camera matrix validation" % track_id)
	if not camera_prefixes.has(track_id):
		return
	var prefix := str(camera_prefixes[track_id])
	for suffix in ["StartPlayerCamera", "FirstTurnPlayerCamera", "MidpointRouteCamera", "ChaseReadabilityCamera"]:
		var camera_path := "ValidationCameras/%s%s" % [prefix, suffix]
		var camera := root.get_node_or_null(camera_path) as Camera3D
		assert_true(camera != null, "%s should include clean evidence camera %s" % [track_id, camera_path])
		if camera == null:
			continue
		assert_equal(str(camera.get_meta("visual_evidence_mode", "")), "clean_runtime_or_cinematic_no_editor_overlays", "%s %s should reject editor-overlay screenshots as final proof" % [track_id, camera_path])
		assert_true(str(camera.get_meta("review_contract", "")).contains("Camera3D path"), "%s %s should state that final proof must render through the named camera" % [track_id, camera_path])

func _assert_home_yard_exterior_visual_completeness(root: Node, track_id: String) -> void:
	for node_path in [
		"ExteriorShell/FrontEntryPorchLightLeft",
		"ExteriorShell/FrontEntryPorchLightRight",
		"ExteriorShell/FrontEntryHouseNumberPlaque",
		"ExteriorShell/FrontFacadeBatten00",
		"ExteriorShell/FrontFacadeBatten07",
		"ExteriorShell/FrontDownspoutWest",
		"ExteriorShell/FrontDownspoutEast",
		"ExteriorShell/BackDownspoutWest",
		"ExteriorShell/BackDownspoutEast",
		"PorchesDecks/FrontPorchWelcomeMat",
		"ExteriorShell/UpperFrontBedroomWindowCenterMuntinVertical",
		"ExteriorShell/UpperFrontBedroomWindowInteriorShadowBacking",
		"Openings/DiningFrontWindowCenterMuntinHorizontal",
		"Openings/KitchenGardenWindowInteriorShadowBacking",
	]:
		assert_true(root.get_node_or_null(node_path) != null, "%s exterior should include whole-unit beta visual detail %s" % [track_id, node_path])
	_assert_home_yard_front_facade_details_respect_openings_and_wall_plane(root, track_id)
	_assert_home_yard_front_openings_have_clear_bays(root, track_id)
	_assert_home_yard_front_entry_upper_wall_closes_second_floor_gap(root, track_id)
	_assert_home_yard_gambrel_gable_wall_aligns_to_front_wall(root, track_id)
	_assert_home_yard_front_entry_assembly_fits_doorway(root, track_id)
	_assert_home_yard_back_facade_openings_are_provenance_audited(root, track_id)
	_assert_home_yard_exterior_long_members_are_clipped_to_owner_runs(root, track_id)
	_assert_home_yard_porch_roof_does_not_intrude_into_front_wall(root, track_id)

func _assert_home_yard_front_openings_have_clear_bays(root: Node, track_id: String) -> void:
	var front_wall_face_z := 148.0
	for window_path in [
		"Openings/DiningFrontWindow",
		"Openings/LivingFrontWindow",
		"ExteriorShell/UpperFrontBedroomWindow",
		"ExteriorShell/UpperFrontGlamWindow",
		"ExteriorShell/GambrelAtticFrontVentWindow",
	]:
		var window := root.get_node_or_null(window_path) as MeshInstance3D
		assert_true(window != null, "%s front opening should include glass %s" % [track_id, window_path])
		if window == null:
			continue
		var bounds := _mesh_instance_global_aabb(window)
		assert_true(bounds.position.z >= front_wall_face_z - 0.05, "%s %s glass should sit on the exterior side of the front wall, not buried in wall geometry: %s" % [track_id, window_path, str(bounds)])
		assert_true(bounds.end.z <= 150.5, "%s %s glass should not float far proud of the wall face: %s" % [track_id, window_path, str(bounds)])
	var living := root.get_node_or_null("Openings/LivingFrontWindow") as MeshInstance3D
	var right_sidelight := root.get_node_or_null("Openings/FrontEntrySidelightRight") as MeshInstance3D
	var door := root.get_node_or_null("Openings/FrontDoorPanel") as MeshInstance3D
	assert_true(living != null and right_sidelight != null and door != null, "%s front entry/window bay should include living window, sidelight, and door" % track_id)
	if living != null and right_sidelight != null and door != null:
		var living_bounds := _mesh_instance_global_aabb(living)
		var sidelight_bounds := _mesh_instance_global_aabb(right_sidelight)
		var door_bounds := _mesh_instance_global_aabb(door)
		assert_true(not _aabb_overlaps_on_axes(living_bounds, sidelight_bounds, ["x", "y"], 0.25), "%s LivingFrontWindow must not overlap the front-entry sidelight: window=%s sidelight=%s" % [track_id, str(living_bounds), str(sidelight_bounds)])
		assert_true(not _aabb_overlaps_on_axes(living_bounds, door_bounds, ["x", "y"], 0.25), "%s LivingFrontWindow must not overlap the front door: window=%s door=%s" % [track_id, str(living_bounds), str(door_bounds)])
	var kitchen_backing := root.get_node_or_null("Openings/KitchenGardenWindowInteriorShadowBacking") as MeshInstance3D
	assert_true(kitchen_backing != null, "%s kitchen garden window should include an interior-side backing" % track_id)
	if kitchen_backing != null:
		var backing_bounds := _mesh_instance_global_aabb(kitchen_backing)
		assert_true(backing_bounds.position.x > -203.0, "%s KitchenGardenWindowInteriorShadowBacking should be inside the west exterior wall plane, not outside the home: %s" % [track_id, str(backing_bounds)])

func _assert_home_yard_front_entry_upper_wall_closes_second_floor_gap(root: Node, track_id: String) -> void:
	var left_wall := root.get_node_or_null("ExteriorShell/ExteriorFrontWallLeft") as MeshInstance3D
	var upper_wall := root.get_node_or_null("ExteriorShell/ExteriorFrontEntryUpperWall") as MeshInstance3D
	var right_wall := root.get_node_or_null("ExteriorShell/ExteriorFrontWallEntryHeader") as MeshInstance3D
	assert_true(left_wall != null and upper_wall != null and right_wall != null, "%s front entry bay should include left wall, upper/header wall, and right wall owners" % track_id)
	if left_wall == null or upper_wall == null or right_wall == null:
		return
	var left_bounds := _mesh_instance_global_aabb(left_wall)
	var upper_bounds := _mesh_instance_global_aabb(upper_wall)
	var right_bounds := _mesh_instance_global_aabb(right_wall)
	assert_true(absf(upper_bounds.position.z - left_bounds.position.z) <= 0.05 and absf(upper_bounds.end.z - left_bounds.end.z) <= 0.05, "%s front entry upper wall must be flush with the left front wall face: upper=%s left=%s" % [track_id, str(upper_bounds), str(left_bounds)])
	assert_true(absf(upper_bounds.position.z - right_bounds.position.z) <= 0.05 and absf(upper_bounds.end.z - right_bounds.end.z) <= 0.05, "%s front entry upper wall must be flush with the right front wall face: upper=%s right=%s" % [track_id, str(upper_bounds), str(right_bounds)])
	assert_true(upper_bounds.position.x <= left_bounds.end.x + 0.25 and upper_bounds.end.x >= right_bounds.position.x - 0.25, "%s front entry upper wall should bridge the full selected-piece gap: left=%s upper=%s right=%s" % [track_id, str(left_bounds), str(upper_bounds), str(right_bounds)])
	assert_true(upper_bounds.position.y <= 62.5 and upper_bounds.end.y >= 103.5, "%s front entry upper wall should close from the entry siding/header band to the second-floor/eave datum: %s" % [track_id, str(upper_bounds)])
	var provenance: Variant = upper_wall.get_meta("generated_scene_provenance", {})
	assert_true(provenance is Dictionary, "%s ExteriorFrontEntryUpperWall should declare gap-closure provenance" % track_id)
	if provenance is Dictionary:
		assert_equal(str((provenance as Dictionary).get("validation_gate", "")), "test_home_yard_front_entry_upper_wall_closes_second_floor_gap", "%s ExteriorFrontEntryUpperWall should point at the second-floor front gap gate" % track_id)
		assert_true(str((provenance as Dictionary).get("forbidden_intersections", "")).contains("daylight gap"), "%s ExteriorFrontEntryUpperWall provenance should forbid recurring selected-piece daylight gaps" % track_id)

func _assert_home_yard_exterior_long_members_are_clipped_to_owner_runs(root: Node, track_id: String) -> void:
	var back_skirt := root.get_node_or_null("ExteriorShell/ExteriorFoundationBackSkirt") as MeshInstance3D
	assert_true(back_skirt != null, "%s should include a rear foundation skirt" % track_id)
	if back_skirt == null:
		return
	var bounds := _mesh_instance_global_aabb(back_skirt)
	assert_true(bounds.position.x >= -204.5 and bounds.end.x <= 94.5, "%s ExteriorFoundationBackSkirt must be clipped to the main rear wall run, not extend beyond the house: %s" % [track_id, str(bounds)])
	assert_true(bounds.size.x <= 300.0, "%s ExteriorFoundationBackSkirt should not be a whole-house broad bar: %s" % [track_id, str(bounds)])
	var provenance: Variant = back_skirt.get_meta("generated_scene_provenance", {})
	assert_true(provenance is Dictionary, "%s ExteriorFoundationBackSkirt should have clipped-run provenance" % track_id)
	if provenance is Dictionary:
		assert_equal(str((provenance as Dictionary).get("validation_gate", "")), "test_home_yard_exterior_long_members_are_clipped_to_owner_runs", "%s back skirt should point at the long-member clipping gate" % track_id)
		assert_true(str((provenance as Dictionary).get("forbidden_intersections", "")).contains("overlong broad bar"), "%s back skirt provenance should forbid overlong broad bars" % track_id)

func _assert_home_yard_porch_roof_does_not_intrude_into_front_wall(root: Node, track_id: String) -> void:
	var back_plane := root.get_node_or_null("Roof/FrontPorchGableBackPlane") as MeshInstance3D
	assert_true(back_plane != null, "%s should include a front porch gable back plane" % track_id)
	if back_plane == null:
		return
	var bounds := _mesh_instance_global_aabb(back_plane)
	assert_true(bounds.position.z >= 144.5, "%s FrontPorchGableBackPlane should stop at the front wall tie-in, not slant back into the house volume: %s" % [track_id, str(bounds)])

func _assert_home_yard_back_facade_openings_are_provenance_audited(root: Node, track_id: String) -> void:
	var rear_detail_paths := [
		"ExteriorShell/RearPatioLowerWallLeftInfill",
		"ExteriorShell/RearPatioLowerWallBetweenDoorAndDoggie",
		"ExteriorShell/RearPatioLowerWallRightInfill",
		"Openings/KitchenPatioDoorFrameHeader",
		"Openings/KitchenPatioDoorFrameSill",
		"Openings/KitchenPatioDoorFrameLeftJamb",
		"Openings/KitchenPatioDoorFrameRightJamb",
		"Openings/KitchenPatioDoorGlass",
		"Openings/PlayroomPatioDoorFrameHeader",
		"Openings/PlayroomPatioDoorFrameSill",
		"Openings/PlayroomPatioDoorFrameLeftJamb",
		"Openings/PlayroomPatioDoorFrameRightJamb",
		"Openings/PlayroomPatioDoorGlass",
		"Openings/OversizedDoggieDoorFrameHeader",
		"Openings/OversizedDoggieDoorFrameSill",
		"Openings/OversizedDoggieDoorFrameLeftJamb",
		"Openings/OversizedDoggieDoorFrameRightJamb",
		"Openings/OversizedDoggieDoorFlap",
	]
	var rear_opening_paths := [
		"Openings/KitchenPatioDoorGlass",
		"Openings/PlayroomPatioDoorGlass",
		"Openings/OversizedDoggieDoorFlap",
	]
	for node_path in rear_detail_paths:
		var node := root.get_node_or_null(node_path) as MeshInstance3D
		assert_true(node != null, "%s rear facade auditor should find %s" % [track_id, node_path])
		if node == null:
			continue
		var provenance: Variant = node.get_meta("generated_scene_provenance", {})
		assert_true(provenance is Dictionary, "%s %s should declare rear facade provenance" % [track_id, node_path])
		if provenance is Dictionary:
			assert_equal(str((provenance as Dictionary).get("validation_gate", "")), "test_home_yard_back_facade_openings_are_provenance_audited", "%s %s should point at the rear facade audit gate" % [track_id, node_path])
			assert_true(str((provenance as Dictionary).get("forbidden_intersections", "")).contains("yellow interior leak"), "%s %s should forbid the yellow rear-wall leak class" % [track_id, node_path])
	var patio_glass := root.get_node_or_null("Openings/PlayroomPatioDoorGlass") as MeshInstance3D
	var doggie_flap := root.get_node_or_null("Openings/OversizedDoggieDoorFlap") as MeshInstance3D
	assert_true(patio_glass != null and doggie_flap != null, "%s rear facade should include separate patio glass and doggie-door flap panels" % track_id)
	if patio_glass != null and doggie_flap != null:
		var patio_bounds := _mesh_instance_global_aabb(patio_glass)
		var doggie_bounds := _mesh_instance_global_aabb(doggie_flap)
		assert_true(not _aabb_overlaps_on_axes(patio_bounds, doggie_bounds, ["x", "y"], 0.25), "%s playroom patio glass and doggie flap must not occupy the same rear opening: patio=%s doggie=%s" % [track_id, str(patio_bounds), str(doggie_bounds)])
		assert_true(doggie_bounds.size.x <= 18.0 and doggie_bounds.size.y <= 16.0, "%s doggie flap should read as a small route portal panel, not a broad loose wall panel: %s" % [track_id, str(doggie_bounds)])
	_assert_rear_frame_surrounds_panel_without_covering_center(root, track_id, "KitchenPatioDoor", "KitchenPatioDoorGlass")
	_assert_rear_frame_surrounds_panel_without_covering_center(root, track_id, "PlayroomPatioDoor", "PlayroomPatioDoorGlass")
	_assert_rear_frame_surrounds_panel_without_covering_center(root, track_id, "OversizedDoggieDoor", "OversizedDoggieDoorFlap")
	for infill_path in [
		"ExteriorShell/RearPatioLowerWallLeftInfill",
		"ExteriorShell/RearPatioLowerWallBetweenDoorAndDoggie",
		"ExteriorShell/RearPatioLowerWallRightInfill",
	]:
		var infill := root.get_node_or_null(infill_path) as MeshInstance3D
		assert_true(infill != null, "%s lower rear wall should include infill %s" % [track_id, infill_path])
		if infill == null:
			continue
		var infill_bounds := _mesh_instance_global_aabb(infill)
		assert_true(infill_bounds.position.z <= -133.0 and infill_bounds.end.z >= -127.0, "%s %s should occupy the lower rear wall plane, not float behind the deck: %s" % [track_id, infill_path, str(infill_bounds)])
		for opening_path in rear_opening_paths:
			var opening := root.get_node_or_null(opening_path) as MeshInstance3D
			if opening == null:
				continue
			var opening_bounds := _mesh_instance_global_aabb(opening)
			assert_true(not _aabb_overlaps_on_axes(infill_bounds, opening_bounds, ["x", "y"], 0.25), "%s rear lower wall infill %s should not cover rear opening %s; infill=%s opening=%s" % [track_id, infill_path, opening_path, str(infill_bounds), str(opening_bounds)])

func _assert_rear_frame_surrounds_panel_without_covering_center(root: Node, track_id: String, prefix: String, panel_name: String) -> void:
	var panel := root.get_node_or_null("Openings/%s" % panel_name) as MeshInstance3D
	assert_true(panel != null, "%s rear opening should include panel %s" % [track_id, panel_name])
	if panel == null:
		return
	var panel_bounds := _mesh_instance_global_aabb(panel)
	var header := root.get_node_or_null("Openings/%sFrameHeader" % prefix) as MeshInstance3D
	var sill := root.get_node_or_null("Openings/%sFrameSill" % prefix) as MeshInstance3D
	var left_jamb := root.get_node_or_null("Openings/%sFrameLeftJamb" % prefix) as MeshInstance3D
	var right_jamb := root.get_node_or_null("Openings/%sFrameRightJamb" % prefix) as MeshInstance3D
	for suffix in ["Header", "Sill", "LeftJamb", "RightJamb"]:
		var frame_path := "Openings/%sFrame%s" % [prefix, suffix]
		var frame_member := root.get_node_or_null(frame_path) as MeshInstance3D
		assert_true(frame_member != null, "%s rear opening should include frame member %s" % [track_id, frame_path])
		if frame_member == null:
			continue
		var frame_bounds := _mesh_instance_global_aabb(frame_member)
		assert_true(not _aabb_overlaps_on_axes(frame_bounds, panel_bounds, ["x", "y"], 0.25), "%s %s should surround, not cover, %s; frame=%s panel=%s" % [track_id, frame_path, panel_name, str(frame_bounds), str(panel_bounds)])
	if header == null or sill == null or left_jamb == null or right_jamb == null:
		return
	var header_bounds := _mesh_instance_global_aabb(header)
	var sill_bounds := _mesh_instance_global_aabb(sill)
	var left_jamb_bounds := _mesh_instance_global_aabb(left_jamb)
	var right_jamb_bounds := _mesh_instance_global_aabb(right_jamb)
	var reveal := 1.25
	assert_true(panel_bounds.position.x >= left_jamb_bounds.end.x + reveal, "%s %s should fit inside the left jamb reveal: panel=%s left_jamb=%s" % [track_id, panel_name, str(panel_bounds), str(left_jamb_bounds)])
	assert_true(panel_bounds.end.x <= right_jamb_bounds.position.x - reveal, "%s %s should fit inside the right jamb reveal: panel=%s right_jamb=%s" % [track_id, panel_name, str(panel_bounds), str(right_jamb_bounds)])
	assert_true(panel_bounds.position.y >= sill_bounds.end.y + reveal, "%s %s should fit above the sill reveal: panel=%s sill=%s" % [track_id, panel_name, str(panel_bounds), str(sill_bounds)])
	assert_true(panel_bounds.end.y <= header_bounds.position.y - reveal, "%s %s should fit below the header reveal: panel=%s header=%s" % [track_id, panel_name, str(panel_bounds), str(header_bounds)])
	assert_true(panel_bounds.end.z <= left_jamb_bounds.position.z + 0.25, "%s %s should be inset behind the rear frame face: panel=%s frame=%s" % [track_id, panel_name, str(panel_bounds), str(left_jamb_bounds)])

func _assert_home_yard_front_entry_assembly_fits_doorway(root: Node, track_id: String) -> void:
	var left_wall := root.get_node_or_null("ExteriorShell/ExteriorFrontWallLeft") as MeshInstance3D
	var right_wall := root.get_node_or_null("ExteriorShell/ExteriorFrontWallEntryHeader") as MeshInstance3D
	var door := root.get_node_or_null("Openings/FrontDoorPanel") as MeshInstance3D
	var sidelight_left := root.get_node_or_null("Openings/FrontEntrySidelightLeft") as MeshInstance3D
	var sidelight_right := root.get_node_or_null("Openings/FrontEntrySidelightRight") as MeshInstance3D
	var jamb_left := root.get_node_or_null("ExteriorShell/FrontDoorDeepJambLeft") as MeshInstance3D
	var jamb_right := root.get_node_or_null("ExteriorShell/FrontDoorDeepJambRight") as MeshInstance3D
	var mullion_left := root.get_node_or_null("ExteriorShell/FrontDoorCenterMullionLeft") as MeshInstance3D
	var mullion_right := root.get_node_or_null("ExteriorShell/FrontDoorCenterMullionRight") as MeshInstance3D
	var header := root.get_node_or_null("ExteriorShell/FrontDoorLintelHeader") as MeshInstance3D
	var sill := root.get_node_or_null("ExteriorShell/FrontDoorFrameSill") as MeshInstance3D
	var door_glass := root.get_node_or_null("Openings/FrontDoorGlass") as MeshInstance3D
	for node in [left_wall, right_wall, door, sidelight_left, sidelight_right, jamb_left, jamb_right, mullion_left, mullion_right, header, sill, door_glass]:
		assert_true(node != null, "%s front entry should include complete doorway, sidelight, jamb, and mullion assembly" % track_id)
	if left_wall == null or right_wall == null or door == null or sidelight_left == null or sidelight_right == null or jamb_left == null or jamb_right == null or mullion_left == null or mullion_right == null or header == null or sill == null or door_glass == null:
		return
	var left_wall_bounds := _mesh_instance_global_aabb(left_wall)
	var right_wall_bounds := _mesh_instance_global_aabb(right_wall)
	var rough_opening_min_x := left_wall_bounds.end.x
	var rough_opening_max_x := right_wall_bounds.position.x
	var door_bounds := _mesh_instance_global_aabb(door)
	var sidelight_left_bounds := _mesh_instance_global_aabb(sidelight_left)
	var sidelight_right_bounds := _mesh_instance_global_aabb(sidelight_right)
	var jamb_left_bounds := _mesh_instance_global_aabb(jamb_left)
	var jamb_right_bounds := _mesh_instance_global_aabb(jamb_right)
	var mullion_left_bounds := _mesh_instance_global_aabb(mullion_left)
	var mullion_right_bounds := _mesh_instance_global_aabb(mullion_right)
	var header_bounds := _mesh_instance_global_aabb(header)
	var sill_bounds := _mesh_instance_global_aabb(sill)
	var door_glass_bounds := _mesh_instance_global_aabb(door_glass)
	assert_true(rough_opening_max_x - rough_opening_min_x >= 72.0, "%s front entry rough opening should be wide enough for a narrower door plus two sidelights" % track_id)
	for item in [
		{"name": "door", "bounds": door_bounds},
		{"name": "left sidelight", "bounds": sidelight_left_bounds},
		{"name": "right sidelight", "bounds": sidelight_right_bounds},
		{"name": "left mullion", "bounds": mullion_left_bounds},
		{"name": "right mullion", "bounds": mullion_right_bounds},
	]:
		var bounds := item["bounds"] as AABB
		assert_true(bounds.position.x >= rough_opening_min_x - 2.0 and bounds.end.x <= rough_opening_max_x + 2.0, "%s front entry %s should fit inside the rough opening instead of clipping adjacent wall: opening=[%f,%f] bounds=%s" % [track_id, str(item["name"]), rough_opening_min_x, rough_opening_max_x, str(bounds)])
	assert_true(door_bounds.size.x < 34.0, "%s front door should be a narrower residential panel so sidelights have real width: %s" % [track_id, str(door_bounds)])
	assert_true(door_bounds.size.y >= 32.0, "%s front door should fill the doorway height instead of reading squat/short: %s" % [track_id, str(door_bounds)])
	assert_true(sidelight_left_bounds.size.x >= 8.0 and sidelight_right_bounds.size.x >= 8.0, "%s front sidelights need visible width after the door is placed" % track_id)
	assert_true(sidelight_left_bounds.end.x < mullion_left_bounds.position.x and mullion_left_bounds.end.x < door_bounds.position.x, "%s left sidelight, mullion, and door should be ordered without overlap" % track_id)
	assert_true(door_bounds.end.x < mullion_right_bounds.position.x and mullion_right_bounds.end.x < sidelight_right_bounds.position.x, "%s door, right mullion, and right sidelight should be ordered without overlap" % track_id)
	assert_true(jamb_left_bounds.position.x <= rough_opening_min_x + 6.0 and jamb_right_bounds.end.x >= rough_opening_max_x - 6.0, "%s front entry jambs should frame the full rough opening, not only the door panel" % track_id)
	var reveal := 1.5
	assert_true(sidelight_left_bounds.position.x >= jamb_left_bounds.end.x + reveal and sidelight_left_bounds.end.x <= mullion_left_bounds.position.x - reveal, "%s left sidelight glass should fit inside the jamb/mullion bay with a visible reveal: glass=%s jamb=%s mullion=%s" % [track_id, str(sidelight_left_bounds), str(jamb_left_bounds), str(mullion_left_bounds)])
	assert_true(door_bounds.position.x >= mullion_left_bounds.end.x + reveal and door_bounds.end.x <= mullion_right_bounds.position.x - reveal, "%s front door panel should fit inside the mullion bay with a visible reveal: door=%s left=%s right=%s" % [track_id, str(door_bounds), str(mullion_left_bounds), str(mullion_right_bounds)])
	assert_true(sidelight_right_bounds.position.x >= mullion_right_bounds.end.x + reveal and sidelight_right_bounds.end.x <= jamb_right_bounds.position.x - reveal, "%s right sidelight glass should fit inside the mullion/jamb bay with a visible reveal: glass=%s mullion=%s jamb=%s" % [track_id, str(sidelight_right_bounds), str(mullion_right_bounds), str(jamb_right_bounds)])
	assert_true(door_bounds.end.y <= header_bounds.position.y - reveal, "%s front door panel should fit below the lintel header with reveal: door=%s header=%s" % [track_id, str(door_bounds), str(header_bounds)])
	assert_true(sill_bounds.end.y <= door_bounds.position.y + 4.25, "%s front sill should sit at the base of the door/frame instead of floating into the glass opening: sill=%s door=%s" % [track_id, str(sill_bounds), str(door_bounds)])
	assert_true(door_glass_bounds.position.x >= door_bounds.position.x + reveal and door_glass_bounds.end.x <= door_bounds.end.x - reveal, "%s front door glass should fit inside the door panel width: glass=%s door=%s" % [track_id, str(door_glass_bounds), str(door_bounds)])
	assert_true(door_glass_bounds.position.y >= door_bounds.position.y + reveal and door_glass_bounds.end.y <= door_bounds.end.y - reveal, "%s front door glass should fit inside the door panel height: glass=%s door=%s" % [track_id, str(door_glass_bounds), str(door_bounds)])

func _assert_home_yard_front_facade_details_respect_openings_and_wall_plane(root: Node, track_id: String) -> void:
	var detail_paths := [
		"ExteriorShell/DutchFrontEntrySidingField",
		"ExteriorShell/GarageFrontSidingField",
		"ExteriorShell/FrontFacadeBatten00",
		"ExteriorShell/FrontFacadeBatten01",
		"ExteriorShell/FrontFacadeBatten02",
		"ExteriorShell/FrontFacadeBatten03",
		"ExteriorShell/FrontFacadeBatten04",
		"ExteriorShell/FrontFacadeBatten05",
		"ExteriorShell/FrontFacadeBatten06",
		"ExteriorShell/FrontFacadeBatten07",
		"ExteriorShell/GarageFacadeBattenLeft",
		"ExteriorShell/GarageFacadeBattenRight",
		"ExteriorShell/GarageFacadeBattenUpperLeft",
		"ExteriorShell/GarageFacadeBattenUpperCenter",
		"ExteriorShell/GarageFacadeBattenUpperRight",
	]
	var opening_paths := [
		"Openings/DiningFrontWindow",
		"Openings/LivingFrontWindow",
		"Openings/FrontDoorPanel",
		"Openings/FrontEntrySidelightLeft",
		"Openings/FrontEntrySidelightRight",
		"Openings/GarageDoorPanel",
		"ExteriorShell/UpperFrontBedroomWindow",
		"ExteriorShell/UpperFrontGlamWindow",
	]
	for detail_path in detail_paths:
		var detail := root.get_node_or_null(detail_path) as MeshInstance3D
		assert_true(detail != null, "%s front facade detail should exist: %s" % [track_id, detail_path])
		if detail == null:
			continue
		var detail_bounds := _mesh_instance_global_aabb(detail)
		assert_true(detail_bounds.size.z <= 3.2, "%s %s should be shallow facade dressing, not a proud wall patch: %s" % [track_id, detail_path, str(detail_bounds)])
		assert_true(detail_bounds.position.z >= 147.5 and detail_bounds.end.z <= 150.2, "%s %s should stay snapped to the front wall face plane: %s" % [track_id, detail_path, str(detail_bounds)])
		var provenance: Variant = detail.get_meta("generated_scene_provenance", {})
		assert_true(provenance is Dictionary, "%s %s should declare facade provenance" % [track_id, detail_path])
		if provenance is Dictionary:
			assert_equal(str((provenance as Dictionary).get("validation_gate", "")), "test_home_yard_front_facade_details_respect_openings_and_wall_plane", "%s %s should point at the front facade opening gate" % [track_id, detail_path])
			assert_true(str((provenance as Dictionary).get("forbidden_intersections", "")).contains("window glass AABB"), "%s %s should forbid window/door AABB intersections" % [track_id, detail_path])
		for opening_path in opening_paths:
			var opening := root.get_node_or_null(opening_path) as MeshInstance3D
			assert_true(opening != null, "%s facade opening schedule should include %s" % [track_id, opening_path])
			if opening == null:
				continue
			var opening_bounds := _mesh_instance_global_aabb(opening)
			assert_true(not _aabb_overlaps_on_axes(detail_bounds, opening_bounds, ["x", "y"], 0.25), "%s front facade detail %s should not cross opening %s; detail=%s opening=%s" % [track_id, detail_path, opening_path, str(detail_bounds), str(opening_bounds)])

func _assert_home_yard_gambrel_gable_wall_aligns_to_front_wall(root: Node, track_id: String) -> void:
	var front_gable := root.get_node_or_null("Roof/DutchGambrelFrontGableWall/GambrelGableUpperWall") as MeshInstance3D
	var back_gable := root.get_node_or_null("Roof/DutchGambrelBackGableWall/GambrelGableUpperWall") as MeshInstance3D
	var front_left_wall := root.get_node_or_null("ExteriorShell/ExteriorFrontWallLeft") as MeshInstance3D
	var front_right_wall := root.get_node_or_null("ExteriorShell/ExteriorFrontWallEntryHeader") as MeshInstance3D
	var back_left_wall := root.get_node_or_null("ExteriorShell/ExteriorBackWallWest") as MeshInstance3D
	var back_right_wall := root.get_node_or_null("ExteriorShell/ExteriorBackPatioHeader") as MeshInstance3D
	assert_true(front_gable != null, "%s front gambrel gable wall should exist" % track_id)
	assert_true(back_gable != null, "%s back gambrel gable wall should exist" % track_id)
	assert_true(front_left_wall != null and front_right_wall != null, "%s lower front walls should exist for gable wall plane flush validation" % track_id)
	assert_true(back_left_wall != null and back_right_wall != null, "%s lower back walls should exist for gable wall plane flush validation" % track_id)
	if front_gable != null and front_left_wall != null and front_right_wall != null:
		var front_bounds := _mesh_instance_global_aabb(front_gable)
		var front_left_bounds := _mesh_instance_global_aabb(front_left_wall)
		var front_right_bounds := _mesh_instance_global_aabb(front_right_wall)
		var front_wall_face_z := maxf(front_left_bounds.end.z, front_right_bounds.end.z)
		assert_true(front_bounds.position.x >= front_left_bounds.position.x - 0.2 and front_bounds.end.x <= front_right_bounds.end.x + 0.2, "%s front GambrelGableUpperWall should align to the lower front wall span, not an overwide roof helper span: %s" % [track_id, str(front_bounds)])
		assert_true(absf(front_bounds.position.z - front_wall_face_z) <= 0.05 and absf(front_bounds.end.z - front_wall_face_z) <= 0.05, "%s front GambrelGableUpperWall should be flush with the lower front wall face datum %f: %s" % [track_id, front_wall_face_z, str(front_bounds)])
	if back_gable != null and back_left_wall != null and back_right_wall != null:
		var back_bounds := _mesh_instance_global_aabb(back_gable)
		var back_left_bounds := _mesh_instance_global_aabb(back_left_wall)
		var back_right_bounds := _mesh_instance_global_aabb(back_right_wall)
		var back_wall_face_z := minf(back_left_bounds.position.z, back_right_bounds.position.z)
		assert_true(back_bounds.position.x >= back_left_bounds.position.x - 0.2 and back_bounds.end.x <= back_right_bounds.end.x + 0.2, "%s back GambrelGableUpperWall should align to the lower back wall span, not an overwide roof helper span: %s" % [track_id, str(back_bounds)])
		assert_true(absf(back_bounds.position.z - back_wall_face_z) <= 0.05 and absf(back_bounds.end.z - back_wall_face_z) <= 0.05, "%s back GambrelGableUpperWall should be flush with the lower back wall face datum %f: %s" % [track_id, back_wall_face_z, str(back_bounds)])

func _assert_home_yard_yard_and_service_visual_completeness(root: Node, track_id: String) -> void:
	for node_path in [
		"Site/ServiceTrashBinALid",
		"Site/ServiceTrashBinAWheel00",
		"Site/ServiceTrashBinAHandle",
		"Site/ServiceTrashBinBLid",
		"Site/ServiceTrashBinBWheel03",
		"Site/ServiceTrashBinBHandle",
		"Yard/BackyardStonePathToGarden",
		"Yard/BackyardPatioPaverGridA",
		"Yard/BackyardPatioPaverGridB",
		"Yard/BackFenceShrubMass00",
		"Yard/BackFenceShrubMass07",
	]:
		assert_true(root.get_node_or_null(node_path) != null, "%s yard/service side should include whole-unit beta visual detail %s" % [track_id, node_path])

func _assert_visible_generated_meshes_have_provenance(node: Node, scene_root: Node, track_id: String) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.visible:
			var data: Variant = mesh_instance.get_meta("generated_scene_provenance", {})
			var node_path := str(scene_root.get_path_to(mesh_instance))
			assert_true(data is Dictionary, "%s visible generated mesh %s should have generated_scene_provenance metadata" % [track_id, node_path])
			if data is Dictionary:
				var dict := data as Dictionary
				for field in GENERATED_PROVENANCE_REQUIRED_FIELDS:
					assert_true(dict.has(field), "%s visible generated mesh %s should declare provenance field %s" % [track_id, node_path, field])
					assert_true(str(dict.get(field, "")).length() > 0, "%s visible generated mesh %s provenance field %s should not be empty" % [track_id, node_path, field])
				assert_true(str(dict.get("owner_volume", "")).length() > 0, "%s visible generated mesh %s should not be unowned geometry" % [track_id, node_path])
				assert_true(not str(dict.get("role", "")).contains("unowned"), "%s visible generated mesh %s should not be classified as unowned geometry" % [track_id, node_path])
	for child in node.get_children():
		_assert_visible_generated_meshes_have_provenance(child, scene_root, track_id)

func _wall_schedule_has_id(schedule: Array, wall_id: String) -> bool:
	for item in schedule:
		if item is Dictionary and str((item as Dictionary).get("id", "")) == wall_id:
			var data := item as Dictionary
			return str(data.get("owner", "")) == "interior_partition" and data.get("connected_zones", []) is Array and str(data.get("owner_skill", "")) == "floor-plan-architect"
	return false

func _vertical_link_has_id(links: Array, link_id: String) -> bool:
	for item in links:
		if item is Dictionary and str((item as Dictionary).get("id", "")) == link_id:
			var data := item as Dictionary
			return not str(data.get("source_asset", "")).is_empty() and str(data.get("validation_gate", "")).contains("must not intersect") and data.get("path_segments", []) is Array and not (data.get("path_segments", []) as Array).is_empty() and not str(data.get("continuity_gate", "")).is_empty()
	return false

func _assert_home_yard_vertical_circulation_continuity(root: Node, track_id: String) -> void:
	var contract: Variant = root.get_meta("vertical_circulation_contract", {})
	assert_true(contract is Dictionary, "%s should export a machine-readable vertical circulation continuity contract" % track_id)
	if not (contract is Dictionary):
		return
	var data := contract as Dictionary
	assert_equal(str(data.get("scale_contract_id", "")), "home_yard_v3_human_house_toy_racer_scale_v1", "%s vertical circulation should use the shared scale contract" % track_id)
	assert_true(bool(data.get("continuity_required", false)), "%s vertical circulation should require floor-to-floor continuity" % track_id)
	_assert_vertical_link_contract(data.get("main_stair", {}), "MainStairEntryToUpperHall", "main stair", MAIN_FLOOR_TOP_Y_FOR_TEST(), 52.60, track_id)
	_assert_vertical_link_contract(data.get("attic_ladder", {}), "AtticPullDownStairUpperHallToAttic", "attic ladder", 52.60, 104.60, track_id)
	for node_path in [
		"VerticalConnectors/MainStairLowerLandingSurface",
		"VerticalConnectors/MainStairSwitchbackLandingSurface",
		"VerticalConnectors/MainStairUpperLandingSurface",
		"VerticalConnectors/MainStairLowerFlightTread00",
		"VerticalConnectors/MainStairLowerFlightTread10",
		"VerticalConnectors/MainStairUpperFlightTread00",
		"VerticalConnectors/MainStairUpperFlightTread10",
		"VerticalConnectors/MainStairLowerFlightRiser00",
		"VerticalConnectors/MainStairUpperFlightRiser10",
		"VerticalConnectors/AtticPullDownLowerLandingSurface",
		"VerticalConnectors/AtticPullDownUpperLandingSurface",
		"VerticalConnectors/AtticPullDownLadderRailLeft",
		"VerticalConnectors/AtticPullDownLadderRailRight",
		"VerticalConnectors/AtticPullDownLadderRung00",
		"VerticalConnectors/AtticPullDownLadderRung11",
	]:
		var node := root.get_node_or_null(node_path)
		assert_true(node != null, "%s should include continuous vertical connector node %s" % [track_id, node_path])
		if node != null:
			var is_main_stair: bool = node_path.contains("MainStair")
			if is_main_stair:
				assert_true(not bool(node.get_meta("temporary_stand_in", true)), "%s %s should be an authored measured stair, not a temporary stand-in" % [track_id, node_path])
				assert_true(not bool(node.get_meta("validation_only_visible_placeholder", true)), "%s %s should render as the visible architectural stair" % [track_id, node_path])
				if node is MeshInstance3D:
					assert_true((node as MeshInstance3D).visible, "%s %s should be visible for stair critique and gameplay readability" % [track_id, node_path])
			else:
				assert_true(not bool(node.get_meta("temporary_stand_in", true)), "%s %s should be authored rear attic access geometry, not a hidden temporary stand-in" % [track_id, node_path])
				assert_true(not bool(node.get_meta("validation_only_visible_placeholder", true)), "%s %s should be production-intent visible attic access geometry" % [track_id, node_path])
				assert_equal(str(node.get_meta("asset_lifecycle_state", "")), "authored_measured_attic_access", "%s %s should declare authored attic access lifecycle metadata" % [track_id, node_path])
				if node is MeshInstance3D:
					assert_true((node as MeshInstance3D).visible, "%s %s should render so the rear attic stair can be visually critiqued" % [track_id, node_path])
			assert_true(not str(node.get_meta("replacement_source", "")).is_empty(), "%s %s should declare the replacement asset source" % [track_id, node_path])
			assert_true(str(node.get_meta("vertical_path_continuity", "")).contains("connects_"), "%s %s should state the floor-to-floor continuity it supports" % [track_id, node_path])
	var upper_deck_holder := root.get_node_or_null("UpperFloor/RoomFinishes/UpperFloorDeck")
	var glam_holder := root.get_node_or_null("UpperFloor/RoomFinishes/GlamDressing")
	var main_ceiling_holder := root.get_node_or_null("MainFloor/RoomFinishes/MainFloorTenFootCeilingPlane")
	assert_true(upper_deck_holder != null and not (upper_deck_holder is MeshInstance3D), "%s upper floor deck should be a split holder, not one broad mesh covering the stair opening" % track_id)
	assert_true(glam_holder != null and not (glam_holder is MeshInstance3D), "%s glam floor should be a holder so front-hall stair changes cannot become one broad route-blocking mesh" % track_id)
	assert_true(main_ceiling_holder != null and not (main_ceiling_holder is MeshInstance3D), "%s first-floor ceiling should be a split holder, not one broad mesh covering the stairwell shaft" % track_id)
	assert_true(root.find_child("MainCeilingEastOfStairShaft", true, false) == null, "%s first-floor ceiling must not keep an east-of-stair broad patch outside the main interior shell; garage ceiling is a separate owned assembly" % track_id)
	assert_true(root.find_child("UpperFloorDeckUpperHallEast", true, false) == null, "%s upper floor deck must not keep an east-of-stair patch because that space is either stair opening or one-story garage volume" % track_id)
	for floor_path in [
		"MainFloor/RoomFinishes/MainFloorTenFootCeilingPlane/MainCeilingWestOfStairShaft",
		"MainFloor/RoomFinishes/MainFloorTenFootCeilingPlane/MainCeilingNorthOfStairShaft",
		"MainFloor/RoomFinishes/MainFloorTenFootCeilingPlane/MainCeilingSouthOfStairShaft",
		"MainFloor/RoomFinishes/MainFloorTenFootCeilingPlane/MainStairShaftReturnNorth",
		"MainFloor/RoomFinishes/MainFloorTenFootCeilingPlane/MainStairShaftReturnSouth",
		"MainFloor/RoomFinishes/MainFloorTenFootCeilingPlane/MainStairShaftReturnWest",
		"MainFloor/RoomFinishes/MainFloorTenFootCeilingPlane/MainStairShaftReturnEast",
		"UpperFloor/RoomFinishes/UpperFloorDeck/UpperFloorDeckWestShellStrip",
		"UpperFloor/RoomFinishes/UpperFloorDeck/UpperFloorDeckFrontBedroomHallShell",
		"UpperFloor/RoomFinishes/UpperFloorDeck/UpperFloorDeckBedroomBack",
		"UpperFloor/RoomFinishes/UpperFloorDeck/UpperFloorDeckGlamBack",
		"UpperFloor/RoomFinishes/UpperFloorDeck/UpperFloorDeckGlamFrontWestOfStair",
		"UpperFloor/RoomFinishes/UpperFloorDeck/UpperFloorDeckUpperHallWest",
		"UpperFloor/RoomFinishes/UpperHallLandingFloor/UpperHallLandingFloorWestOfStairOpening",
		"UpperFloor/RoomFinishes/GlamDressing/GlamDressingBackFloor",
		"UpperFloor/RoomFinishes/GlamDressing/GlamDressingFrontFloorWestOfStair",
	]:
		assert_true(root.get_node_or_null(floor_path) != null, "%s should include split floor/ceiling assembly piece %s around the stairwell shaft" % [track_id, floor_path])
	var opening_volume := AABB(Vector3(54.0, 50.0, 78.0), Vector3(36.0, 4.0, 68.0))
	var shaft_volume := AABB(Vector3(54.0, 39.5, 78.0), Vector3(36.0, 14.1, 68.0))
	_assert_home_yard_main_stair_is_measured_and_visible(root, track_id)
	_assert_home_yard_stair_route_exclusion(root, shaft_volume, track_id)
	_assert_home_yard_stair_is_front_hall_not_garage(root, shaft_volume, track_id)
	if main_ceiling_holder != null:
		_assert_no_visible_mesh_intersects_aabb(main_ceiling_holder, shaft_volume, "MainFloor/RoomFinishes/MainFloorTenFootCeilingPlane/MainStairShaftReturn", "%s first-floor ceiling and interstitial floor assembly must leave a clear stairwell shaft" % track_id)
	if upper_deck_holder != null:
		_assert_no_visible_mesh_intersects_aabb(upper_deck_holder, opening_volume, "NoExclusions/", "%s upper deck must leave a clear stairwell floor opening" % track_id)
		_assert_upper_floor_deck_clear_of_garage_volume(upper_deck_holder, track_id)
		for sample in [
			Vector3(-195, 52.6, -120),
			Vector3(-195, 52.6, 138),
			Vector3(-96, 52.6, 138),
			Vector3(50, 52.6, 138),
			Vector3(50, 52.6, 96),
		]:
			assert_true(_visible_descendant_covers_xz_sample(upper_deck_holder, sample), "%s upper floor deck should fit the main exterior shell footprint at sample %s" % [track_id, str(sample)])
	if glam_holder != null:
		_assert_no_visible_mesh_intersects_aabb(glam_holder, opening_volume, "NoExclusions/", "%s glam floor must leave a clear stairwell floor opening" % track_id)
	var upper_hall_divider_return := root.get_node_or_null("UpperFloor/InteriorWalls/UpperHallBedroomDividerSegment02") as MeshInstance3D
	assert_true(upper_hall_divider_return != null, "%s upper hall divider should terminate before the stair shaft instead of closing the stair opening" % track_id)
	if upper_hall_divider_return != null:
		var divider_bounds := _mesh_instance_global_aabb(upper_hall_divider_return)
		assert_true(divider_bounds.end.x <= 54.5, "%s upper hall divider return should stop at the stairwell west edge; bounds=%s" % [track_id, str(divider_bounds)])
	for opening_header_path in [
		"UpperFloor/InteriorWalls/BedroomGlamCasedOpeningOpeningHeader",
		"UpperFloor/InteriorWalls/UpperHallBedroomDividerBedroomDoorHeader",
		"UpperFloor/InteriorWalls/UpperHallBedroomDividerGlamClosetDoorHeader",
	]:
		var header := root.get_node_or_null(opening_header_path) as MeshInstance3D
		assert_true(header != null, "%s upper room entry should include measured header %s" % [track_id, opening_header_path])
		if header != null:
			var header_bounds := _mesh_instance_global_aabb(header)
			var clear_span := maxf(header_bounds.size.x, header_bounds.size.z)
			assert_true(clear_span <= 44.5, "%s upper room entry %s should be door/cased-opening sized, not a wall-sized void: %s" % [track_id, opening_header_path, str(header_bounds)])
	assert_true(root.get_node_or_null("UpperFloor/RoomFinishes/MainStairOpeningRailSouth") == null, "%s upper stair landing should open into the upstairs living area without a south/front guardrail blocking entry" % track_id)
	for rail_path in ["UpperFloor/RoomFinishes/MainStairOpeningRailNorth", "UpperFloor/RoomFinishes/MainStairOpeningRailWest", "UpperFloor/RoomFinishes/MainStairOpeningRailEast"]:
		var rail := root.get_node_or_null(rail_path)
		assert_true(rail != null, "%s should include stairwell guardrail %s" % [track_id, rail_path])
		if rail != null:
			assert_true(bool(rail.get_meta("stairwell_opening_part", false)), "%s %s should be tagged as part of the stairwell opening guardrail" % [track_id, rail_path])
			assert_equal(str(rail.get_meta("collision_policy", "")), "visual_guardrail_no_gameplay_collision", "%s stairwell guardrail should not create gameplay collision until authored as a named boundary" % track_id)
	var attic_lower := root.get_node_or_null("VerticalConnectors/AtticPullDownLowerLandingSurface") as MeshInstance3D
	assert_true(attic_lower != null, "%s attic stair should be generated at the upstairs back wall with landing geometry" % track_id)
	if attic_lower != null:
		var lower_bounds := _mesh_instance_global_aabb(attic_lower)
		assert_true(attic_lower.visible, "%s rear attic stair landing should be visible authored geometry, not a hidden temporary helper" % track_id)
		assert_equal(str(attic_lower.get_meta("asset_lifecycle_state", "")), "authored_measured_attic_access", "%s rear attic stair landing should be production-intent authored attic access geometry" % track_id)
		assert_true(lower_bounds.position.z <= -121.0 and lower_bounds.end.z <= -86.0, "%s attic stair landing should sit against the rear/back wall zone, bounds=%s" % [track_id, str(lower_bounds)])
	var attic_rung := root.get_node_or_null("VerticalConnectors/AtticPullDownLadderRung05") as MeshInstance3D
	assert_true(attic_rung != null and attic_rung.visible, "%s rear attic stair should include visible rungs, not only a hatch marker" % track_id)
	if attic_rung != null:
		assert_equal(str(attic_rung.get_meta("asset_lifecycle_state", "")), "authored_measured_attic_access", "%s rear attic stair rungs should be authored visible access geometry" % track_id)
	var attic_hatch := root.get_node_or_null("VerticalConnectors/AtticAccessHatchOpening") as Node3D
	assert_true(attic_hatch != null, "%s attic stair should include a rear-wall hatch marker" % track_id)
	if attic_hatch != null:
		assert_true(attic_hatch.position.z <= -108.0, "%s attic hatch marker should move to the upstairs back wall, position=%s" % [track_id, str(attic_hatch.position)])

func _assert_upper_floor_deck_clear_of_garage_volume(upper_deck_holder: Node, track_id: String) -> void:
	var garage_volume := AABB(Vector3(90.01, 0.0, -60.0), Vector3(129.99, 54.0, 205.0))
	_assert_no_visible_mesh_intersects_aabb(upper_deck_holder, garage_volume, "NoExclusions/", "%s upper floor deck pieces must not occupy the garage/service bay; the garage is a one-story volume with its own ceiling and roof" % track_id)

func _assert_home_yard_main_stair_is_measured_and_visible(root: Node, track_id: String) -> void:
	var main_stair_contract := (root.get_meta("vertical_circulation_contract", {}) as Dictionary).get("main_stair", {}) as Dictionary
	assert_equal(str(main_stair_contract.get("type", "")), "u_shaped_residential_stair", "%s main stair should be planned as a U-shaped residential stair" % track_id)
	assert_true(float(main_stair_contract.get("tread_depth_units", 0.0)) >= 5.0, "%s main stair should have readable tread depth, not ladder-like blocks" % track_id)
	assert_true(str(main_stair_contract.get("continuity_gate", "")).contains("separated lower/upper flights"), "%s main stair continuity contract should require separated stair flights" % track_id)
	for node_path in [
		"VerticalConnectors/MainStairLowerLandingSurface",
		"VerticalConnectors/MainStairSwitchbackLandingSurface",
		"VerticalConnectors/MainStairUpperLandingSurface",
		"VerticalConnectors/MainStairLowerStringerLeft",
		"VerticalConnectors/MainStairLowerStringerRight",
		"VerticalConnectors/MainStairUpperStringerLeft",
		"VerticalConnectors/MainStairUpperStringerRight",
		"VerticalConnectors/MainStairLowerGuardrailLeft",
		"VerticalConnectors/MainStairUpperGuardrailRight",
	]:
		var node := root.get_node_or_null(node_path) as MeshInstance3D
		assert_true(node != null, "%s visible measured stair should include %s" % [track_id, node_path])
		if node != null:
			assert_true(node.visible, "%s %s should be visible" % [track_id, node_path])
			assert_equal(str(node.get_meta("asset_lifecycle_state", "")), "authored_measured_stair", "%s %s should be authored measured stair geometry" % [track_id, node_path])
	var lower_landing := root.get_node_or_null("VerticalConnectors/MainStairLowerLandingSurface") as MeshInstance3D
	var upper_landing := root.get_node_or_null("VerticalConnectors/MainStairUpperLandingSurface") as MeshInstance3D
	var upper_guardrail := root.get_node_or_null("VerticalConnectors/MainStairUpperGuardrailRight") as MeshInstance3D
	if lower_landing != null:
		var lower_landing_bounds := _mesh_instance_global_aabb(lower_landing)
		assert_true(lower_landing_bounds.size.x >= 27.5 and lower_landing_bounds.size.z >= 15.5, "%s lower stair should include a real bottom landing area, bounds=%s" % [track_id, str(lower_landing_bounds)])
	if upper_landing != null:
		var upper_landing_bounds := _mesh_instance_global_aabb(upper_landing)
		assert_true(upper_landing_bounds.size.x >= 33.5 and upper_landing_bounds.size.z >= 17.5, "%s upper stair landing should be large enough for arrival and turn-in, bounds=%s" % [track_id, str(upper_landing_bounds)])
		if upper_guardrail != null:
			var rail_bounds := _mesh_instance_global_aabb(upper_guardrail)
			assert_true(rail_bounds.end.z <= upper_landing_bounds.position.z + 1.0, "%s upper guardrail should stop before the landing entry instead of blocking it; rail=%s landing=%s" % [track_id, str(rail_bounds), str(upper_landing_bounds)])
	for index in [0, 5, 10]:
		for prefix in ["MainStairLowerFlightTread", "MainStairUpperFlightTread"]:
			var node := root.get_node_or_null("VerticalConnectors/%s%02d" % [prefix, index]) as MeshInstance3D
			assert_true(node != null, "%s visible measured stair should include tread %s%02d" % [track_id, prefix, index])
			if node != null:
				var bounds := _mesh_instance_global_aabb(node)
				assert_true(node.visible, "%s %s%02d should be visible" % [track_id, prefix, index])
				assert_true(maxf(bounds.size.x, bounds.size.z) >= 5.0, "%s %s%02d should have readable tread run, bounds=%s" % [track_id, prefix, index, str(bounds)])
		var lower_tread := root.get_node_or_null("VerticalConnectors/MainStairLowerFlightTread%02d" % index) as MeshInstance3D
		var upper_tread := root.get_node_or_null("VerticalConnectors/MainStairUpperFlightTread%02d" % index) as MeshInstance3D
		if lower_tread != null and upper_tread != null:
			var lower_bounds := _mesh_instance_global_aabb(lower_tread)
			var upper_bounds := _mesh_instance_global_aabb(upper_tread)
			var x_overlap: float = minf(lower_bounds.end.x, upper_bounds.end.x) - maxf(lower_bounds.position.x, upper_bounds.position.x)
			var z_overlap: float = minf(lower_bounds.end.z, upper_bounds.end.z) - maxf(lower_bounds.position.z, upper_bounds.position.z)
			assert_true(x_overlap <= 0.05 or z_overlap <= 0.05, "%s main stair lower and upper treads should be separated in plan, not overlapping; lower=%s upper=%s" % [track_id, str(lower_bounds), str(upper_bounds)])
			assert_true(lower_bounds.end.x <= upper_bounds.position.x - 2.0, "%s lower flight should be moved west of upper flight with a visible gap; lower=%s upper=%s" % [track_id, str(lower_bounds), str(upper_bounds)])
	for index in [0, 5, 10]:
		for prefix in ["MainStairLowerFlightRiser", "MainStairUpperFlightRiser"]:
			var riser := root.get_node_or_null("VerticalConnectors/%s%02d" % [prefix, index]) as MeshInstance3D
			assert_true(riser != null, "%s visible measured stair should fill stair run with riser %s%02d" % [track_id, prefix, index])
			if riser != null:
				assert_true(riser.visible, "%s %s%02d should be visible stair fill" % [track_id, prefix, index])
				assert_equal(str(riser.get_meta("asset_lifecycle_state", "")), "authored_measured_stair", "%s %s%02d should be authored measured stair fill" % [track_id, prefix, index])
	var lower_ref := root.get_node_or_null("VerticalConnectors/MainStairLowerFlightKenneySteps") as Node3D
	var upper_ref := root.get_node_or_null("VerticalConnectors/MainStairUpperFlightKenneySteps") as Node3D
	for ref in [lower_ref, upper_ref]:
		assert_true(ref != null, "%s hidden Kenney stair reference should remain for provenance" % track_id)
		if ref != null:
			assert_true(not ref.visible, "%s tiny Kenney stair reference should not be the visible stair design" % track_id)
			assert_true(bool(ref.get_meta("visual_reference_hidden_by_measured_stair", false)), "%s hidden Kenney stair reference should document why it is hidden" % track_id)

func _assert_home_yard_stair_route_exclusion(root: Node, shaft_volume: AABB, track_id: String) -> void:
	var envelopes: Variant = root.get_meta("route_envelopes", {})
	assert_true(envelopes is Dictionary, "%s shared map should expose route envelopes before placing vertical circulation" % track_id)
	if not (envelopes is Dictionary):
		return
	for protected_course in ["bedroom", "glam_closet"]:
		var envelope: Variant = (envelopes as Dictionary).get(protected_course, {})
		assert_true(envelope is Dictionary, "%s main stair shaft exclusion should be checked against %s route envelope" % [track_id, protected_course])
		if not (envelope is Dictionary):
			continue
		var route_bounds: Variant = (envelope as Dictionary).get("route_world_bounds", {})
		assert_true(route_bounds is Dictionary, "%s %s route envelope should include route_world_bounds" % [track_id, protected_course])
		if not (route_bounds is Dictionary):
			continue
		var route_min: Vector3 = (route_bounds as Dictionary).get("min", Vector3.ZERO) as Vector3
		var route_max: Vector3 = (route_bounds as Dictionary).get("max", Vector3.ZERO) as Vector3
		var route_volume := AABB(route_min, route_max - route_min)
		assert_true(not route_volume.intersects(shaft_volume), "%s main stair shaft must stay outside %s route envelope" % [track_id, protected_course])

func _assert_home_yard_stair_is_front_hall_not_garage(root: Node, shaft_volume: AABB, track_id: String) -> void:
	var garage_volume := AABB(Vector3(90.01, 0.0, -60.0), Vector3(129.99, 54.0, 205.0))
	var front_hall_volume := AABB(Vector3(35.0, 0.0, 100.0), Vector3(70.0, 54.0, 50.0))
	assert_true(not shaft_volume.intersects(garage_volume), "%s main stair shaft must not be pushed into the garage/service bay" % track_id)
	assert_true(shaft_volume.intersects(front_hall_volume), "%s main stair shaft should live in the front entry/upper-hall stair zone" % track_id)
	var envelopes: Variant = root.get_meta("route_envelopes", {})
	if envelopes is Dictionary:
		for protected_course in ["bedroom", "glam_closet"]:
			var envelope: Variant = (envelopes as Dictionary).get(protected_course, {})
			if envelope is Dictionary and (envelope as Dictionary).get("zone_world_bounds", {}) is Dictionary:
				var zone_bounds := (envelope as Dictionary).get("zone_world_bounds", {}) as Dictionary
				var zone_min: Vector3 = zone_bounds.get("min", Vector3.ZERO) as Vector3
				var zone_max: Vector3 = zone_bounds.get("max", Vector3.ZERO) as Vector3
				assert_true(zone_min.z <= -129.0, "%s %s room zone should be pushed back to the rear upper-floor wall after carving the front hall" % [track_id, protected_course])
				assert_true(zone_max.z <= 106.1, "%s %s room zone should leave the front band for upper-hall circulation" % [track_id, protected_course])
	var contract: Variant = root.get_meta("floor_plan_contract", {})
	if contract is Dictionary:
		var links: Variant = (contract as Dictionary).get("vertical_links", [])
		if links is Array:
			for item in links:
				if item is Dictionary and str((item as Dictionary).get("id", "")) == "MainStairEntryToUpperHall":
					assert_equal(str((item as Dictionary).get("lower_zone", "")), "entry_stair_hall", "%s main stair lower zone should remain the entry stair hall" % track_id)
					assert_equal(str((item as Dictionary).get("upper_zone", "")), "upper_front_hall", "%s main stair upper zone should remain the upper front hall" % track_id)

func _assert_vertical_link_contract(value: Variant, expected_id: String, label: String, expected_lower_y: float, expected_upper_y: float, track_id: String) -> void:
	assert_true(value is Dictionary, "%s should include a %s continuity contract" % [track_id, label])
	if not (value is Dictionary):
		return
	var data := value as Dictionary
	assert_equal(str(data.get("id", "")), expected_id, "%s %s continuity contract should have a stable id" % [track_id, label])
	assert_true(bool(data.get("continuous_path_verified", false)), "%s %s should be marked continuous after segment checks" % [track_id, label])
	assert_true(absf(float(data.get("lower_floor_datum_y", -999.0)) - expected_lower_y) <= 0.1, "%s %s lower datum should match the finished floor" % [track_id, label])
	assert_true(absf(float(data.get("upper_floor_datum_y", -999.0)) - expected_upper_y) <= 0.1, "%s %s upper datum should match the finished floor" % [track_id, label])
	assert_true(float(data.get("total_rise_units", 0.0)) >= 50.0, "%s %s should span a real floor-to-floor rise" % [track_id, label])
	assert_true(data.get("path_segments", []) is Array and (data.get("path_segments", []) as Array).size() >= 3, "%s %s should declare solved path segments" % [track_id, label])
	assert_true(bool(data.get("opening_overlap_required", false)), "%s %s should require floor-opening or hatch overlap with the landing" % [track_id, label])
	if expected_id == "MainStairEntryToUpperHall":
		assert_true(data.get("floor_assembly_shaft_void_bounds", {}) is Dictionary, "%s main stair should declare a shaft void through the ceiling/floor assembly" % track_id)
		assert_true(data.get("floor_assembly_layers_cut", []) is Array and (data.get("floor_assembly_layers_cut", []) as Array).has("MainFloorTenFootCeilingPlane"), "%s main stair should cut through the first-floor ceiling layer" % track_id)

func MAIN_FLOOR_TOP_Y_FOR_TEST() -> float:
	return 0.05

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
		"ValidationCameras/MainInteriorExteriorFlushCamera",
		"ValidationCameras/UpperInteriorExteriorFlushCamera",
		"ValidationCameras/AtticRoofInteriorFlushCamera",
	]:
		assert_true(root.get_node_or_null(node_path) != null, "%s shared home-yard scene should include seam validation camera %s" % [track_id, node_path])
	_assert_home_yard_interior_exterior_aabb_separation(root, track_id)
	_assert_home_yard_site_props_stay_outside_interior(root, track_id)
	_assert_home_yard_upper_hall_and_ceiling_complete(root, track_id)

func _assert_home_yard_interior_placeholder_replacements(root: Node, track_id: String) -> void:
	for removed_path in [
		"MainFloor/RoomFinishes/KitchenCabinetRunBack",
		"MainFloor/RoomFinishes/KitchenIsland",
		"MainFloor/RoomFinishes/LivingSofa",
		"MainFloor/RoomFinishes/DiningTableAnchor",
		"MainFloor/RoomFinishes/PlayroomBlockMountain",
		"MainFloor/RoomFinishes/PlayroomLowTable",
		"UpperFloor/RoomFinishes/BedroomClosetBuiltIn",
		"UpperFloor/RoomFinishes/BedroomDeskNook",
		"UpperFloor/RoomFinishes/BedroomBedPlatform",
		"UpperFloor/RoomFinishes/GlamWardrobeRun",
		"UpperFloor/RoomFinishes/GlamVanityIsland",
		"UpperFloor/RoomFinishes/GlamMirrorWall",
		"Attic/RoomFinishes/AtticTrunkStack",
	]:
		assert_true(root.get_node_or_null(removed_path) == null, "%s should not keep visible primitive interior placeholder %s" % [track_id, removed_path])
	var expected_assets := {
		"MainFloor/KitchenCabinetRunA": "res://assets/source/kenney/furniture_kit/kitchenCabinet.glb",
		"MainFloor/KitchenCabinetRunB": "res://assets/source/kenney/furniture_kit/kitchenCabinet.glb",
		"MainFloor/KitchenIslandBar": "res://assets/source/kenney/furniture_kit/kitchenBar.glb",
		"MainFloor/LivingCushionSofa": "res://assets/source/kenney/furniture_kit/chairCushion.glb",
		"MainFloor/PlayroomRoundActivityTable": "res://assets/source/kenney/furniture_kit/tableRound.glb",
		"MainFloor/PlayroomBlockTower": "res://assets/source/meshy/home_yard_v3/playroom/low_poly_playroom_toy_block_tower/low_poly_playroom_toy_block_tower.glb",
		"UpperFloor/BedroomClosetCabinet": "res://assets/source/kenney/furniture_kit/cabinetBed.glb",
		"UpperFloor/BedroomDeskSideTable": "res://assets/source/kenney/furniture_kit/sideTable.glb",
		"UpperFloor/GlamWardrobeDrawerA": "res://assets/source/kenney/furniture_kit/cabinetBedDrawer.glb",
		"UpperFloor/GlamVanityTable": "res://assets/source/kenney/furniture_kit/sideTable.glb",
		"UpperFloor/GlamMirror": "res://assets/source/kenney/furniture_kit/bathroomMirror.glb",
		"Attic/AtticChest": "res://assets/source/meshy/home_yard_v3/attic/low_poly_dusty_attic_trunk/low_poly_dusty_attic_trunk.glb",
	}
	for node_path in expected_assets.keys():
		var node := root.get_node_or_null(str(node_path))
		assert_true(node != null, "%s should include sourced interior replacement %s" % [track_id, str(node_path)])
		if node != null:
			assert_equal(str(node.get_meta("asset_source", "")), str(expected_assets[node_path]), "%s %s should record its source asset" % [track_id, str(node_path)])
			assert_true(bool(node.get_meta("placeholder_replacement", false)), "%s %s should be marked as replacing a placeholder" % [track_id, str(node_path)])
			assert_true(str(node.get_meta("validation_camera", "")).begins_with("ValidationCameras/"), "%s %s should name a validation camera" % [track_id, str(node_path)])
	for camera_path in [
		"ValidationCameras/KitchenAssetCloseupCamera",
		"ValidationCameras/MainFloorFurnitureCloseupCamera",
		"ValidationCameras/BedroomAssetCloseupCamera",
		"ValidationCameras/GlamClosetAssetCloseupCamera",
		"ValidationCameras/GlamClosetMirrorCamera",
		"ValidationCameras/AtticAssetCloseupCamera",
	]:
		assert_true(root.get_node_or_null(camera_path) != null, "%s should include interior asset review camera %s" % [track_id, camera_path])

func _assert_no_stage_owned_exterior_nodes(node: Node, track_id: String, holder_name: String, path: String) -> void:
	for child in node.get_children():
		var child_name := str(child.name)
		var child_path := "%s/%s" % [path, child_name]
		var lower := child_name.to_lower()
		var is_forbidden := lower.begins_with("exterior") or lower.contains("roof") or lower.contains("gable")
		assert_true(not is_forbidden, "%s %s must not own exterior shell node %s" % [track_id, holder_name, child_path])
		_assert_no_stage_owned_exterior_nodes(child, track_id, holder_name, child_path)

func _assert_home_yard_interior_exterior_aabb_separation(root: Node, track_id: String) -> void:
	var exterior_bounds: Array[Dictionary] = []
	for holder_path in ["ExteriorShell", "Foundation"]:
		var holder := root.get_node_or_null(holder_path)
		assert_true(holder != null, "%s should include %s for interior/exterior AABB separation audit" % [track_id, holder_path])
		if holder != null:
			_collect_exterior_blocker_aabbs(holder, root, exterior_bounds)
	assert_true(not exterior_bounds.is_empty(), "%s should expose exterior shell/foundation AABBs for interior separation audit" % track_id)
	for interior_path in ["MainFloor", "UpperFloor", "Attic", "VerticalConnectors"]:
		var interior_holder := root.get_node_or_null(interior_path)
		assert_true(interior_holder != null, "%s should include %s for interior/exterior AABB separation audit" % [track_id, interior_path])
		if interior_holder != null:
			_assert_interior_meshes_clear_exterior_aabbs(interior_holder, root, exterior_bounds, track_id)

func _assert_home_yard_site_props_stay_outside_interior(root: Node, track_id: String) -> void:
	var site := root.get_node_or_null("Site")
	assert_true(site != null, "%s should include Site for exterior-prop/interior leak audit" % track_id)
	if site == null:
		return
	var occupied_volumes := [
		{"name": "dining_living", "bounds": AABB(Vector3(-200, -1, 15), Vector3(235, 42, 130))},
		{"name": "entry_stair_hall", "bounds": AABB(Vector3(35, -1, 15), Vector3(55, 42, 130))},
		{"name": "kitchen_breakfast", "bounds": AABB(Vector3(-200, -1, -130), Vector3(145, 42, 145))},
		{"name": "playroom_family", "bounds": AABB(Vector3(-55, -1, -130), Vector3(145, 42, 145))},
		{"name": "upper_bedroom", "bounds": AABB(Vector3(-180, 51, -130), Vector3(165, 43, 275))},
		{"name": "upper_glam_hall", "bounds": AABB(Vector3(-15, 51, -130), Vector3(105, 43, 275))},
	]
	_assert_site_loose_props_clear_interior_volumes(site, root, occupied_volumes, track_id)

func _assert_site_loose_props_clear_interior_volumes(node: Node, scene_root: Node, occupied_volumes: Array, track_id: String) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.visible and _is_site_loose_prop_for_interior_gate(mesh_instance):
			var site_bounds := _mesh_instance_global_aabb(mesh_instance)
			var site_path := str(scene_root.get_path_to(mesh_instance))
			for item in occupied_volumes:
				var room_bounds := (item as Dictionary).get("bounds", AABB()) as AABB
				if site_bounds.intersects(room_bounds) and _aabb_overlap_is_blocking(site_bounds, room_bounds):
					assert_true(false, "%s exterior/site prop %s must stay outside interior volume %s; prop=%s room=%s" % [track_id, site_path, str((item as Dictionary).get("name", "")), str(site_bounds), str(room_bounds)])
	for child in node.get_children():
		_assert_site_loose_props_clear_interior_volumes(child, scene_root, occupied_volumes, track_id)

func _is_site_loose_prop_for_interior_gate(node: Node) -> bool:
	var lower := str(node.name).to_lower()
	return lower.contains("planting") or lower.contains("shrub") or lower.contains("mailbox") or lower.contains("trashbin") or lower.contains("wheel") or lower.contains("handle")

func _assert_home_yard_upper_hall_and_ceiling_complete(root: Node, track_id: String) -> void:
	var ceiling := root.get_node_or_null("UpperFloor/RoomFinishes/UpperFloorTenFootCeilingPlane")
	assert_true(ceiling != null, "%s upper floor should include a split ceiling holder" % track_id)
	if ceiling == null:
		return
	for node_name in [
		"UpperCeilingWestOfAtticHatch",
		"UpperCeilingEastOfAtticHatch",
		"UpperCeilingNorthOfAtticHatch",
		"UpperCeilingSouthOfAtticHatch",
	]:
		assert_true(ceiling.get_node_or_null(node_name) is MeshInstance3D, "%s upper ceiling should include measured piece %s" % [track_id, node_name])
	for sample in [
		Vector3(-120, 92.8, 138),
		Vector3(36, 92.8, 138),
		Vector3(78, 92.8, 138),
		Vector3(-120, 92.8, -120),
		Vector3(78, 92.8, -120),
	]:
		assert_true(_visible_descendant_covers_xz_sample(ceiling, sample), "%s upper ceiling should cover shell-interior sample %s" % [track_id, str(sample)])
	var hatch_void := AABB(Vector3(18, 91, -130), Vector3(48, 5, 44))
	_assert_no_visible_descendant_intersects_aabb(ceiling, hatch_void, track_id, "upper attic hatch void")
	var east_rail := root.get_node_or_null("UpperFloor/RoomFinishes/MainStairOpeningRailEast")
	assert_true(east_rail is MeshInstance3D, "%s upper hall stair opening should have an east guardrail so the hallway reads enclosed and continuous" % track_id)
	var upper_hall_floor := root.get_node_or_null("UpperFloor/RoomFinishes/UpperHallLandingFloor")
	assert_true(upper_hall_floor != null and not (upper_hall_floor is MeshInstance3D), "%s upper hall landing floor should be a measured holder, not an unowned broad slab" % track_id)
	if upper_hall_floor != null:
		for node_name in [
			"UpperHallLandingFloorWestOfStairOpening",
			"UpperHallStairOpeningFloorTrimWest",
			"UpperHallStairOpeningFloorTrimNorth",
			"UpperHallStairOpeningFloorTrimSouth",
		]:
			assert_true(upper_hall_floor.get_node_or_null(node_name) is MeshInstance3D, "%s upper hall should include measured landing piece %s" % [track_id, node_name])
		for sample in [
			Vector3(-12, 52.6, 126),
			Vector3(20, 52.6, 126),
			Vector3(52.5, 52.6, 126),
		]:
			assert_true(_visible_descendant_covers_xz_sample(upper_hall_floor, sample), "%s upper hall landing floor should cover visible hall sample %s without looking missing" % [track_id, str(sample)])
		var stair_opening := AABB(Vector3(54.0, 50.0, 78.0), Vector3(36.0, 4.0, 68.0))
		_assert_no_visible_descendant_intersects_aabb(upper_hall_floor, stair_opening, track_id, "main stair upper-floor opening")
	var attic_finishes := root.get_node_or_null("Attic/RoomFinishes")
	assert_true(attic_finishes != null, "%s attic should include room finishes for shell-footprint deck audit" % track_id)
	if attic_finishes != null:
		for node_name in [
			"AtticFloorDeckWestEaveShellStrip",
			"AtticFloorDeckEastEaveShellStrip",
			"AtticFloorDeckBackEaveShellStrip",
			"AtticFloorDeckFrontEaveShellStrip",
			"AtticDeck",
		]:
			assert_true(attic_finishes.get_node_or_null(node_name) is MeshInstance3D, "%s attic shell deck should include measured piece %s" % [track_id, node_name])
		for sample in [
			Vector3(-195, 104.6, -120),
			Vector3(85, 104.6, -120),
			Vector3(-195, 104.6, 140),
			Vector3(85, 104.6, 140),
			Vector3(-50, 104.6, 132),
		]:
			assert_true(_visible_descendant_covers_xz_sample(attic_finishes, sample), "%s attic deck should fit the gambrel exterior shell footprint at sample %s" % [track_id, str(sample)])

func _visible_descendant_covers_xz_sample(node: Node, sample: Vector3) -> bool:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.visible:
			var bounds := _mesh_instance_global_aabb(mesh_instance)
			if sample.x >= bounds.position.x - 0.05 and sample.x <= bounds.end.x + 0.05 and sample.z >= bounds.position.z - 0.05 and sample.z <= bounds.end.z + 0.05:
				return true
	for child in node.get_children():
		if _visible_descendant_covers_xz_sample(child, sample):
			return true
	return false

func _assert_no_visible_descendant_intersects_aabb(node: Node, forbidden: AABB, track_id: String, label: String) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.visible:
			var bounds := _mesh_instance_global_aabb(mesh_instance)
			assert_true(not (bounds.intersects(forbidden) and _aabb_overlap_is_blocking(bounds, forbidden)), "%s visible mesh %s should not cover %s; mesh=%s forbidden=%s" % [track_id, str(mesh_instance.name), label, str(bounds), str(forbidden)])
	for child in node.get_children():
		_assert_no_visible_descendant_intersects_aabb(child, forbidden, track_id, label)

func _collect_exterior_blocker_aabbs(node: Node, scene_root: Node, output: Array[Dictionary]) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.visible and _is_exterior_blocker_for_interior_aabb_gate(mesh_instance):
			var bounds := _mesh_instance_global_aabb(mesh_instance)
			var shrunk := bounds.grow(-0.08)
			if shrunk.size.x > 0.0 and shrunk.size.y > 0.0 and shrunk.size.z > 0.0:
				bounds = shrunk
			output.append({
				"path": str(scene_root.get_path_to(mesh_instance)),
				"bounds": bounds,
			})
	for child in node.get_children():
		_collect_exterior_blocker_aabbs(child, scene_root, output)

func _is_exterior_blocker_for_interior_aabb_gate(node: Node) -> bool:
	var lower := str(node.name).to_lower()
	return lower.contains("wall") or lower.contains("foundation") or lower.contains("plinth") or lower.contains("skirt") or lower.contains("gable") or lower.contains("soffit")

func _assert_interior_meshes_clear_exterior_aabbs(node: Node, scene_root: Node, exterior_bounds: Array[Dictionary], track_id: String) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.visible and not _is_boundary_tolerated_interior_mesh(mesh_instance):
			var interior_bounds := _mesh_instance_global_aabb(mesh_instance)
			var interior_path := str(scene_root.get_path_to(mesh_instance))
			for exterior_item in exterior_bounds:
				var exterior_aabb := exterior_item.get("bounds", AABB()) as AABB
				if interior_bounds.intersects(exterior_aabb) and _aabb_overlap_is_blocking(interior_bounds, exterior_aabb):
					assert_true(false, "%s interior mesh %s must not intersect exterior shell/foundation AABB %s" % [track_id, interior_path, str(exterior_item.get("path", ""))])
	for child in node.get_children():
		_assert_interior_meshes_clear_exterior_aabbs(child, scene_root, exterior_bounds, track_id)

func _aabb_overlap_is_blocking(a: AABB, b: AABB) -> bool:
	var x_overlap: float = min(a.end.x, b.end.x) - max(a.position.x, b.position.x)
	var y_overlap: float = min(a.end.y, b.end.y) - max(a.position.y, b.position.y)
	var z_overlap: float = min(a.end.z, b.end.z) - max(a.position.z, b.position.z)
	if x_overlap <= 0.0 or y_overlap <= 0.0 or z_overlap <= 0.0:
		return false
	if y_overlap <= 0.25:
		return false
	var horizontal_penetration: float = min(x_overlap, z_overlap)
	return horizontal_penetration > 2.25

func _is_boundary_tolerated_interior_mesh(node: Node) -> bool:
	var lower := str(node.name).to_lower()
	if lower.contains("floor") or lower.contains("ceiling") or lower.contains("baseboard") or lower.contains("threshold") or lower.contains("rail") or lower.contains("post"):
		return true
	if lower.contains("trim") or lower.contains("return") or lower.contains("header") or lower.contains("opening"):
		return true
	if lower.contains("divider") or lower.contains("interiorbackwall"):
		return true
	return lower in [
		"diningliving",
		"entrystairhall",
		"garageservice",
		"kitchenbreakfast",
		"playroomfamily",
		"bedroomsuite",
	]

func _assert_home_yard_exterior_shell(root: Node, track_id: String) -> void:
	var shell := root.get_node_or_null("ExteriorShell")
	assert_true(shell != null, "%s should include an exterior shell holder" % track_id)
	if shell == null:
		return
	for node_name in [
		"ExteriorFoundationFrontSkirt",
		"ExteriorFoundationBackSkirt",
		"ExteriorFoundationWestSkirt",
		"ExteriorFoundationEastSkirt",
		"FrontPorchTaperedColumnLeftBase",
		"FrontPorchTaperedColumnRightShaft",
		"FrontPorchBeam",
		"FrontDoorDeepJambLeft",
		"FrontDoorLintelHeader",
		"FrontGutterRun",
		"BackGutterRun",
		"ExteriorEastUpperWallOverGarage",
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
		"DutchGambrelLowerLeftPlane",
		"DutchGambrelUpperLeftPlane",
		"DutchGambrelUpperRightPlane",
		"DutchGambrelLowerRightPlane",
		"DutchGambrelRidgeCap",
		"DutchGambrelLeftBreakCap",
		"DutchGambrelRightBreakCap",
		"DutchGambrelFrontGableWall",
		"DutchGambrelBackGableWall",
		"GarageCrossGableRidge",
		"FrontPorchGableRidge",
		"GambrelFrontEaveFascia",
		"GambrelBackEaveFascia",
		"GambrelWestRakeFascia",
		"GambrelEastRakeFascia",
		"GambrelSoffitFront",
		"GambrelSoffitBack",
	]:
		assert_true(roof.get_node_or_null(node_name) != null, "%s roof system should include measured assembly node %s" % [track_id, node_name])
	var massing_contract := str(roof.get_meta("massing_contract", ""))
	assert_true(massing_contract.contains("Dutch Colonial gambrel"), "%s roof should record the Dutch gambrel massing hierarchy" % track_id)
	assert_true(massing_contract.contains("no stacked attic box"), "%s roof should reject stacked attic boxes" % track_id)
	_assert_ridge_axis(roof, "DutchGambrelRidgeCap", "z", track_id)
	_assert_ridge_axis(roof, "GarageCrossGableRidge", "x", track_id)
	_assert_ridge_axis(roof, "FrontPorchGableRidge", "x", track_id)
	assert_true(root.find_child("MainRoofWestEaveClosure", true, false) == null, "%s should not keep the obsolete west eave closure support block after direct fascia seam validation" % track_id)
	assert_true(root.find_child("MainRoofEastEaveClosure", true, false) == null, "%s should not keep the obsolete east eave closure support block after direct fascia seam validation" % track_id)
	assert_true(root.find_child("GarageValleyCoverFront", true, false) == null, "%s should not keep obsolete floating garage valley cover bars when the lower garage roof is actually tied to a side wall" % track_id)
	assert_true(root.find_child("GarageValleyCoverBack", true, false) == null, "%s should not keep obsolete floating garage valley cover bars when the lower garage roof is actually tied to a side wall" % track_id)
	assert_true(root.find_child("GarageRoofSidewallFlashingFront", true, false) == null, "%s should not keep visible garage sidewall flashing bars; roof planes must prove direct wall contact instead" % track_id)
	assert_true(root.find_child("GarageRoofSidewallFlashingBack", true, false) == null, "%s should not keep visible garage sidewall flashing bars; roof planes must prove direct wall contact instead" % track_id)
	assert_true(root.find_child("WallBelowGambrelEave", true, false) == null, "%s gambrel gable helpers must not duplicate below-eave exterior wall surfaces" % track_id)
	_assert_side_fascia_mitres_to_eave_fascia(root, "Roof/GambrelWestRakeFascia", "Roof/GambrelFrontEaveFascia", "Roof/GambrelBackEaveFascia", track_id)
	_assert_side_fascia_mitres_to_eave_fascia(root, "Roof/GambrelEastRakeFascia", "Roof/GambrelFrontEaveFascia", "Roof/GambrelBackEaveFascia", track_id)
	_assert_gambrel_gable_rake_trim_contacts_eave_fascia(root, "Roof/DutchGambrelFrontGableWall", "Roof/GambrelFrontEaveFascia", track_id)
	_assert_gambrel_gable_rake_trim_contacts_eave_fascia(root, "Roof/DutchGambrelBackGableWall", "Roof/GambrelBackEaveFascia", track_id)
	_assert_gambrel_overhang_has_soffit_returns(root, "front", 148.0, 159.0, track_id)
	_assert_gambrel_overhang_has_soffit_returns(root, "back", -144.0, -133.0, track_id)
	_assert_garage_roof_ridge_centered_on_owner_footprint(roof, track_id)
	_assert_garage_roof_planes_contact_sidewall(root, track_id)
	_assert_exterior_garage_side_infill(root, track_id)
	_assert_garage_cross_gable_clear_of_main_house_volume(root, track_id)
	_assert_mesh_top_below(roof, "DutchGambrelRidgeCap", 168.0, track_id)
	var gambrel_planes := [
		roof.get_node_or_null("DutchGambrelLowerLeftPlane"),
		roof.get_node_or_null("DutchGambrelUpperLeftPlane"),
		roof.get_node_or_null("DutchGambrelUpperRightPlane"),
		roof.get_node_or_null("DutchGambrelLowerRightPlane"),
	]
	for plane in gambrel_planes:
		assert_true(plane != null and plane is MeshInstance3D, "%s attic roof plane should be real mesh geometry" % track_id)
		if plane != null:
			assert_equal(str(plane.get_meta("span_axis", "")), "x", "%s gambrel roof plane should slope across the declared span axis" % track_id)
			assert_true(float(plane.get_meta("slope_delta_y", 0.0)) > 0.0, "%s gambrel roof plane should have visible rise" % track_id)
	var attic := root.get_node_or_null("Attic")
	assert_true(attic != null, "%s should include attic holder" % track_id)
	if attic != null:
		assert_true(attic.get_node_or_null("InteriorPartitions/AtticWestKneePartition") != null, "%s attic should include contract-owned west knee partition" % track_id)
		assert_true(attic.get_node_or_null("InteriorPartitions/AtticEastKneePartition") != null, "%s attic should include contract-owned east knee partition" % track_id)
		assert_true(attic.get_node_or_null("RoomFinishes/PopperHighRampLaunchDeck") != null, "%s attic should include Popper high-ramp launch deck" % track_id)
		assert_true(attic.get_node_or_null("RoomFinishes/PopperHighRampLandingDeck") != null, "%s attic should include Popper high-ramp landing deck" % track_id)
		assert_true(attic.get_node_or_null("RoomFinishes/AtticHumanClearanceMarker") != null, "%s attic should include a human-walkable clearance marker" % track_id)
		var clearance_marker := attic.get_node_or_null("RoomFinishes/AtticHumanClearanceMarker")
		assert_true(not (clearance_marker is MeshInstance3D), "%s attic clearance marker should remain validation-only metadata, not visible roof-penetrating geometry" % track_id)
		if clearance_marker != null:
			assert_true(bool(clearance_marker.get_meta("validation_only", false)), "%s attic clearance marker should be tagged as validation-only" % track_id)
		_assert_mesh_top_below(attic, "RoomFinishes/AtticRidgeBeamInterior", 164.0, track_id)
		_assert_attic_meshes_inside_gambrel_envelope(attic, root, track_id)
	assert_true(root.find_child("RoofMassPlaceholder", true, false) == null, "%s should not keep a visible flat roof placeholder" % track_id)
	assert_true(root.find_child("MainEnvelopeCeilingPlane", true, false) == null, "%s should not expose a flat ceiling plane as a visible roof placeholder" % track_id)
	assert_true(root.find_child("UpperAtticRoofRidgeCap", true, false) == null, "%s should not keep the old stacked attic ridge cap" % track_id)
	assert_true(root.find_child("UpperDormerFrontGableWall", true, false) == null, "%s should not keep old upper-dormer gable walls" % track_id)
	assert_true(root.find_child("UpperRoofLeftRakeFascia", true, false) == null, "%s should not keep horizontal dormer side rake bars that read as floating rails" % track_id)
	assert_true(root.find_child("UpperRoofRightRakeFascia", true, false) == null, "%s should not keep horizontal dormer side rake bars that read as floating rails" % track_id)
	assert_true(root.find_child("MainRoofSoffitClosure", true, false) == null, "%s should not keep a broad full-footprint roof soffit closure inside the attic volume" % track_id)

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

func _assert_mesh_top_below(parent: Node, node_path: String, max_y: float, track_id: String) -> void:
	var node := parent.get_node_or_null(node_path) as MeshInstance3D
	assert_true(node != null, "%s should include %s for vertical roof-shell audit" % [track_id, node_path])
	if node == null:
		return
	var bounds := _mesh_instance_global_aabb(node)
	assert_true(bounds.position.y + bounds.size.y <= max_y + 0.01, "%s %s should not protrude above the measured roof/dormer datum" % [track_id, node_path])

func _assert_side_fascia_mitres_to_eave_fascia(root: Node, side_path: String, front_path: String, back_path: String, track_id: String) -> void:
	var side := root.get_node_or_null(side_path) as MeshInstance3D
	var front := root.get_node_or_null(front_path) as MeshInstance3D
	var back := root.get_node_or_null(back_path) as MeshInstance3D
	assert_true(side != null, "%s should include side fascia %s for direct eave seam audit" % [track_id, side_path])
	assert_true(front != null, "%s should include front eave fascia %s for direct eave seam audit" % [track_id, front_path])
	assert_true(back != null, "%s should include back eave fascia %s for direct eave seam audit" % [track_id, back_path])
	if side == null or front == null or back == null:
		return
	var side_bounds := _mesh_instance_global_aabb(side)
	var front_bounds := _mesh_instance_global_aabb(front)
	var back_bounds := _mesh_instance_global_aabb(back)
	assert_true(_aabb_overlaps_on_axes(side_bounds, front_bounds, ["x", "y", "z"], 0.25), "%s %s should directly meet/mitre with %s; an intermediate closure block must not be the only connection proof" % [track_id, side_path, front_path])
	assert_true(_aabb_overlaps_on_axes(side_bounds, back_bounds, ["x", "y", "z"], 0.25), "%s %s should directly meet/mitre with %s; an intermediate closure block must not be the only connection proof" % [track_id, side_path, back_path])
	assert_true(absf((side_bounds.position.y + side_bounds.size.y * 0.5) - (front_bounds.position.y + front_bounds.size.y * 0.5)) <= 2.0, "%s %s should share the eave fascia datum with %s" % [track_id, side_path, front_path])
	assert_true(absf((side_bounds.position.y + side_bounds.size.y * 0.5) - (back_bounds.position.y + back_bounds.size.y * 0.5)) <= 2.0, "%s %s should share the eave fascia datum with %s" % [track_id, side_path, back_path])

func _assert_gambrel_gable_rake_trim_contacts_eave_fascia(root: Node, gable_path: String, eave_path: String, track_id: String) -> void:
	var gable := root.get_node_or_null(gable_path)
	var eave := root.get_node_or_null(eave_path) as MeshInstance3D
	assert_true(gable != null, "%s should include gable assembly %s for rake/eave corner audit" % [track_id, gable_path])
	assert_true(eave != null, "%s should include eave fascia %s for rake/eave corner audit" % [track_id, eave_path])
	if gable == null or eave == null:
		return
	var eave_bounds := _mesh_instance_global_aabb(eave)
	for trim_name in ["GambrelLeftRakeTrim", "GambrelRightRakeTrim"]:
		var trim := gable.get_node_or_null(trim_name) as MeshInstance3D
		assert_true(trim != null, "%s %s should include %s for complete roof-corner closure" % [track_id, gable_path, trim_name])
		if trim == null:
			continue
		var trim_bounds := _mesh_instance_global_aabb(trim)
		assert_true(_aabb_overlaps_on_axes(trim_bounds, eave_bounds, ["x", "y", "z"], 0.25), "%s %s/%s should terminate into %s; gap=%s eave=%s" % [track_id, gable_path, trim_name, eave_path, str(trim_bounds), str(eave_bounds)])
		var provenance: Variant = trim.get_meta("generated_scene_provenance", {})
		assert_true(provenance is Dictionary, "%s %s/%s should declare rake/eave corner provenance" % [track_id, gable_path, trim_name])
		if provenance is Dictionary:
			assert_equal(str((provenance as Dictionary).get("validation_gate", "")), "test_home_yard_gambrel_gable_rake_trim_contacts_eave_fascia", "%s %s/%s should point at the rake/eave corner closure gate" % [track_id, gable_path, trim_name])
			assert_true(str((provenance as Dictionary).get("forbidden_intersections", "")).contains("open roof corner gap"), "%s %s/%s provenance should forbid recurring second-floor corner gaps" % [track_id, gable_path, trim_name])
			assert_true(str((provenance as Dictionary).get("forbidden_intersections", "")).contains("broad wall-colored diagonal patch"), "%s %s/%s provenance should forbid using rake trim as a broad patch" % [track_id, gable_path, trim_name])
		assert_true(trim_bounds.size.z <= 8.25, "%s %s/%s should be a narrow rake board, not a broad selected diagonal patch across the roof face: %s" % [track_id, gable_path, trim_name, str(trim_bounds)])

func _assert_gambrel_overhang_has_soffit_returns(root: Node, side: String, wall_z: float, fascia_z: float, track_id: String) -> void:
	var side_title := "Front" if side == "front" else "Back"
	var expected_names := [
		"Roof/DutchGambrel%sLowerLeftSoffitReturn" % side_title,
		"Roof/DutchGambrel%sUpperLeftSoffitReturn" % side_title,
		"Roof/DutchGambrel%sUpperRightSoffitReturn" % side_title,
		"Roof/DutchGambrel%sLowerRightSoffitReturn" % side_title,
	]
	for node_path in expected_names:
		var soffit := root.get_node_or_null(node_path) as MeshInstance3D
		assert_true(soffit != null, "%s %s should exist so the gambrel overhang does not leave an open underside gap" % [track_id, node_path])
		if soffit == null:
			continue
		var bounds := _mesh_instance_global_aabb(soffit)
		assert_true(bounds.position.z <= minf(wall_z, fascia_z) + 0.25 and bounds.end.z >= maxf(wall_z, fascia_z) - 0.25, "%s %s should bridge from gable wall plane to eave fascia instead of relying on rake trim: %s" % [track_id, node_path, str(bounds)])
		assert_true(bounds.size.x > 20.0, "%s %s should be a real sloped soffit segment, not a tiny closure block: %s" % [track_id, node_path, str(bounds)])
		var provenance: Variant = soffit.get_meta("generated_scene_provenance", {})
		assert_true(provenance is Dictionary, "%s %s should declare soffit-return provenance" % [track_id, node_path])
		if provenance is Dictionary:
			assert_equal(str((provenance as Dictionary).get("validation_gate", "")), "test_home_yard_gambrel_front_overhang_has_soffit_returns", "%s %s should point at the soffit-return recurrence gate" % [track_id, node_path])
			assert_true(str((provenance as Dictionary).get("forbidden_intersections", "")).contains("open black soffit gap"), "%s %s provenance should forbid recurring open underside gaps" % [track_id, node_path])
			assert_true(str((provenance as Dictionary).get("forbidden_intersections", "")).contains("broad diagonal rake patch"), "%s %s provenance should forbid fixing soffits with rake patch bars" % [track_id, node_path])

func _assert_garage_roof_ridge_centered_on_owner_footprint(roof: Node, track_id: String) -> void:
	var contract: Variant = roof.get_meta("roof_contract", {})
	assert_true(contract is Dictionary, "%s roof should export a roof_contract dictionary for ridge centering gates" % track_id)
	if not (contract is Dictionary):
		return
	var garage_contract: Variant = (contract as Dictionary).get("garage_cross_gable", {})
	assert_true(garage_contract is Dictionary, "%s roof contract should include garage_cross_gable footprint data" % track_id)
	if not (garage_contract is Dictionary):
		return
	var data := garage_contract as Dictionary
	var footprint_min := data.get("footprint_min", Vector3.ZERO) as Vector3
	var footprint_max := data.get("footprint_max", Vector3.ZERO) as Vector3
	var expected_z := (footprint_min.z + footprint_max.z) * 0.5
	var declared_z := float(data.get("ridge_z", -999.0))
	assert_true(absf(declared_z - expected_z) <= 0.1, "%s garage gable ridge_z should be centered on its owner footprint; declared=%f expected=%f" % [track_id, declared_z, expected_z])
	var ridge := roof.get_node_or_null("GarageCrossGableRidge") as MeshInstance3D
	assert_true(ridge != null, "%s should include GarageCrossGableRidge for owner-footprint centering gate" % track_id)
	if ridge != null:
		var bounds := _mesh_instance_global_aabb(ridge)
		var actual_z := bounds.position.z + bounds.size.z * 0.5
		assert_true(absf(actual_z - expected_z) <= 1.0, "%s GarageCrossGableRidge mesh should be centered on garage footprint Z; actual=%f expected=%f bounds=%s" % [track_id, actual_z, expected_z, str(bounds)])

func _assert_garage_roof_planes_contact_sidewall(root: Node, track_id: String) -> void:
	var upper_sidewall := root.get_node_or_null("ExteriorShell/ExteriorEastUpperWallOverGarage") as MeshInstance3D
	assert_true(upper_sidewall != null, "%s should include ExteriorEastUpperWallOverGarage for garage roof sidewall contact proof" % track_id)
	if upper_sidewall == null:
		return
	var upper_bounds := _mesh_instance_global_aabb(upper_sidewall)
	for roof_path in ["Roof/GarageCrossGableFrontPlane", "Roof/GarageCrossGableBackPlane"]:
		var roof_plane := root.get_node_or_null(roof_path) as MeshInstance3D
		assert_true(roof_plane != null, "%s should include %s for direct sidewall contact proof" % [track_id, roof_path])
		if roof_plane == null:
			continue
		var roof_bounds := _mesh_instance_global_aabb(roof_plane)
		assert_true(roof_bounds.position.x >= upper_bounds.position.x - 0.25 and roof_bounds.position.x <= upper_bounds.end.x + 0.25, "%s %s west edge should terminate within the ExteriorEastUpperWallOverGarage wall thickness instead of needing a visible helper bar" % [track_id, roof_path])
		assert_true(_aabb_overlaps_on_axes(roof_bounds, upper_bounds, ["z"], 8.0), "%s %s should overlap the upper sidewall run in Z enough to prove contact" % [track_id, roof_path])
		var data: Variant = roof_plane.get_meta("generated_scene_provenance", {})
		assert_true(data is Dictionary, "%s %s should declare generated provenance" % [track_id, roof_path])
		if data is Dictionary:
			var support := str((data as Dictionary).get("support_target", ""))
			assert_true(support.contains("ExteriorEastUpperWallOverGarage"), "%s %s provenance should name the upper sidewall contact instead of outsourcing proof to a visible flashing bar" % [track_id, roof_path])
			var forbidden := str((data as Dictionary).get("forbidden_intersections", ""))
			assert_true(forbidden.contains("floating sidewall flashing bar"), "%s %s provenance should explicitly forbid recurrence of floating flashing bars" % [track_id, roof_path])

func _assert_exterior_garage_side_infill(root: Node, track_id: String) -> void:
	var wall := root.get_node_or_null("ExteriorShell/ExteriorEastGarageWall") as MeshInstance3D
	var infill := root.get_node_or_null("ExteriorShell/ExteriorEastGarageGableInfill") as MeshInstance3D
	assert_true(wall != null, "%s should include ExteriorEastGarageWall for side-wall closure gate" % track_id)
	assert_true(infill != null, "%s should include ExteriorEastGarageGableInfill so the garage side wall does not stop below the roof" % track_id)
	if wall == null or infill == null:
		return
	var wall_bounds := _mesh_instance_global_aabb(wall)
	var infill_bounds := _mesh_instance_global_aabb(infill)
	assert_true(infill_bounds.position.y <= wall_bounds.end.y + 0.25, "%s garage gable infill should begin at the top of ExteriorEastGarageWall" % track_id)
	assert_true(infill_bounds.end.y > wall_bounds.end.y + 12.0, "%s garage gable infill should close visibly above ExteriorEastGarageWall toward the roof" % track_id)
	assert_true(absf((infill_bounds.position.x + infill_bounds.size.x * 0.5) - (wall_bounds.position.x + wall_bounds.size.x * 0.5)) <= 1.0, "%s garage gable infill should share the east wall plane" % track_id)

func _assert_garage_cross_gable_clear_of_main_house_volume(root: Node, track_id: String) -> void:
	var protected_main_house := AABB(Vector3(-214.0, 40.0, -144.0), Vector3(306.0, 68.0, 303.0))
	for roof_path in [
		"Roof/GarageCrossGableFrontPlane",
		"Roof/GarageCrossGableBackPlane",
		"Roof/GarageCrossGableRidge",
	]:
		_assert_mesh_aabb_outside_or_barely_touching(root, roof_path, protected_main_house, 2.0, "%s garage cross-gable module must not intrude into the protected main-house roof/wall volume" % track_id)

func _assert_mesh_aabb_outside_or_barely_touching(root: Node, node_path: String, forbidden: AABB, allowed_overlap_depth: float, message: String) -> void:
	var mesh_instance := root.get_node_or_null(node_path) as MeshInstance3D
	assert_true(mesh_instance != null, "%s; missing node: %s" % [message, node_path])
	if mesh_instance == null:
		return
	var bounds := _mesh_instance_global_aabb(mesh_instance)
	var overlap := _aabb_overlap_size(bounds, forbidden)
	if overlap == Vector3.ZERO:
		return
	var intrusion_depth := minf(overlap.x, minf(overlap.y, overlap.z))
	assert_true(intrusion_depth <= allowed_overlap_depth, "%s; %s intrusion=%f allowed=%f bounds=%s forbidden=%s" % [message, node_path, intrusion_depth, allowed_overlap_depth, str(bounds), str(forbidden)])

func _aabb_overlap_size(a: AABB, b: AABB) -> Vector3:
	var overlap := Vector3(
		minf(a.end.x, b.end.x) - maxf(a.position.x, b.position.x),
		minf(a.end.y, b.end.y) - maxf(a.position.y, b.position.y),
		minf(a.end.z, b.end.z) - maxf(a.position.z, b.position.z)
	)
	if overlap.x <= 0.0 or overlap.y <= 0.0 or overlap.z <= 0.0:
		return Vector3.ZERO
	return overlap

func _aabb_overlaps_on_axes(a: AABB, b: AABB, axes: Array[String], minimum_overlap: float) -> bool:
	for axis in axes:
		var overlap := 0.0
		if axis == "x":
			overlap = minf(a.end.x, b.end.x) - maxf(a.position.x, b.position.x)
		elif axis == "y":
			overlap = minf(a.end.y, b.end.y) - maxf(a.position.y, b.position.y)
		elif axis == "z":
			overlap = minf(a.end.z, b.end.z) - maxf(a.position.z, b.position.z)
		if overlap < minimum_overlap:
			return false
	return true

func _assert_attic_meshes_inside_gambrel_envelope(node: Node, scene_root: Node, track_id: String) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.visible:
			var bounds := _mesh_instance_global_aabb(mesh_instance)
			var allowed_top: float = minf(_gambrel_roof_envelope_y(bounds.position.x), _gambrel_roof_envelope_y(bounds.end.x)) - 1.0
			var node_path := str(scene_root.get_path_to(mesh_instance))
			assert_true(bounds.end.y <= allowed_top + 0.01, "%s attic mesh %s should stay inside the gambrel roof envelope; top=%f allowed=%f bounds=%s" % [track_id, node_path, bounds.end.y, allowed_top, str(bounds)])
	for child in node.get_children():
		_assert_attic_meshes_inside_gambrel_envelope(child, scene_root, track_id)

func _gambrel_roof_envelope_y(x: float) -> float:
	if x <= -214.0 or x >= 104.0:
		return 104.0
	if x <= -155.0:
		return lerpf(104.0, 136.0, (x + 214.0) / 59.0)
	if x <= -55.0:
		return lerpf(136.0, 164.0, (x + 155.0) / 100.0)
	if x <= 45.0:
		return lerpf(164.0, 136.0, (x + 55.0) / 100.0)
	return lerpf(136.0, 104.0, (x - 45.0) / 59.0)

func _assert_home_yard_landscape_and_assets(root: Node, track_id: String) -> void:
	for node_path in [
		"Foundation/HouseFoundationFrontPlinth",
		"Foundation/HouseFoundationBackPlinth",
		"Foundation/HouseFoundationWestPlinth",
		"Foundation/HouseFoundationEastPlinth",
		"Openings/KitchenPatioDoorFrameHeader",
		"Openings/KitchenPatioDoorFrameSill",
		"Openings/KitchenPatioDoorFrameLeftJamb",
		"Openings/KitchenPatioDoorFrameRightJamb",
		"Openings/OversizedDoggieDoorFrameHeader",
		"Openings/OversizedDoggieDoorFrameSill",
		"Openings/OversizedDoggieDoorFrameLeftJamb",
		"Openings/OversizedDoggieDoorFrameRightJamb",
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
		"ValidationCameras/BackyardDoggieDoorCamera",
		"ValidationCameras/RoofGambrelSideProfileCamera",
		"ValidationCameras/MainFloorRouteStartsCamera",
		"ValidationCameras/PlayroomStartPlayerCamera",
		"ValidationCameras/OutdoorPlaygroundStartPlayerCamera",
		"ValidationCameras/GardenStartPlayerCamera",
		"ValidationCameras/SandboxStartPlayerCamera",
		"ValidationCameras/UpperFloorRouteStartsCamera",
		"ValidationCameras/BedroomStartPlayerCamera",
		"ValidationCameras/GlamClosetStartPlayerCamera",
		"ValidationCameras/AtticStartPlayerCamera",
		"ValidationCameras/AtticRampSideProfileCamera",
		"ValidationCameras/YardCourseOverviewCamera",
		"ValidationCameras/AtticGableProfileCamera",
		"ValidationCameras/FrontPorchCloseupCamera",
		"ValidationCameras/GarageServiceSideCamera",
		"ValidationCameras/ToyboxTreeSwingCamera",
		"ConceptReference/HumanScaleReference",
	]:
		assert_true(root.get_node_or_null(node_path) != null, "%s shared home-yard scene should include %s" % [track_id, node_path])
	_assert_home_yard_foundation_plinth_bounds(root, track_id)

func _assert_home_yard_foundation_plinth_bounds(root: Node, track_id: String) -> void:
	var foundation := root.get_node_or_null("Foundation")
	assert_true(foundation != null, "%s should include Foundation for plinth footprint gates" % track_id)
	if foundation == null:
		return
	var contract := str(foundation.get_meta("foundation_footprint_contract", ""))
	assert_true(contract.contains("clipped to owning wall runs"), "%s foundation should document that plinths are clipped to owning wall runs" % track_id)
	var main_house_bounds := AABB(Vector3(-205.0, -1.0, -135.0), Vector3(300.0, 12.0, 285.0))
	var garage_bounds := AABB(Vector3(85.0, -1.0, -65.0), Vector3(140.0, 12.0, 215.0))
	_assert_mesh_aabb_within(root, "Foundation/HouseFoundationBackPlinth", main_house_bounds, "%s back foundation plinth must stop at the main-house rear wall run instead of continuing behind the garage/yard void" % track_id)
	_assert_mesh_aabb_within(root, "Foundation/HouseFoundationEastPlinth", garage_bounds, "%s east foundation plinth must stay on the garage/service wall run" % track_id)

func _assert_home_yard_kitchen_readability(root: Node) -> void:
	var kit := root.get_node_or_null("MainFloor/KitchenRaceReadabilityKit")
	assert_true(kit != null, "Kitchen shared route should include a player-height readability kit")
	if kit == null:
		return
	var contract: Variant = kit.get_meta("player_readability_contract", {})
	assert_true(contract is Dictionary, "Kitchen readability kit should export a player readability contract")
	if contract is Dictionary:
		assert_equal(str((contract as Dictionary).get("course_id", "")), "kitchen", "Kitchen readability contract should identify the kitchen course")
		assert_true(str((contract as Dictionary).get("surface", "")).contains("GridMap"), "Kitchen readability contract should defer the readable driving surface to the active GridMap route")
	for node_name in [
		"KitchenReadableRoute00Mat",
		"KitchenReadableRoute00LeftEdge",
		"KitchenReadableRoute00RightEdge",
		"KitchenCornerCurb00",
		"KitchenCornerArrow00",
		"KitchenStartFinishLeftPost",
		"KitchenStartFinishRightPost",
		"KitchenFirstTurnBillboard",
		"KitchenPantryStackLandmarkA",
		"KitchenPantryStackLandmarkB",
		"KitchenSinkIslandInfieldEdge",
		"KitchenFridgeLandmarkPanel",
		"KitchenWarmUndercabinetGlow",
		"KitchenStartFinishFloorBand",
		"KitchenStartFinishBanner",
	]:
		assert_true(kit.get_node_or_null(node_name) == null, "Kitchen shared readability kit should not render helper slab geometry %s" % node_name)
	assert_true(root.get_node_or_null("ValidationCameras/KitchenStartPlayerCamera") != null, "Kitchen should include a start-grid player-height validation camera")
	assert_true(root.get_node_or_null("ValidationCameras/KitchenFirstTurnPlayerCamera") != null, "Kitchen should include a first-turn player-height validation camera")

func _assert_validation_only_nodes_are_non_rendered(node: Node, track_id: String, path := "") -> void:
	var current_path := path if not path.is_empty() else "/%s" % str(node.name)
	if bool(node.get_meta("validation_only", false)):
		assert_true(not (node is MeshInstance3D), "%s validation-only node %s must not be a visible mesh" % [track_id, current_path])
		assert_true(not (node is CSGShape3D), "%s validation-only node %s must not be visible CSG geometry" % [track_id, current_path])
	for child in node.get_children():
		if child is Node:
			_assert_validation_only_nodes_are_non_rendered(child as Node, track_id, "%s/%s" % [current_path, str((child as Node).name)])

func _assert_no_visible_blockout_nodes(node: Node, track_id: String, path := "") -> void:
	var current_path := path if not path.is_empty() else "/%s" % str(node.name)
	if str(node.name).to_lower().contains("blockout"):
		assert_true(not (node is MeshInstance3D) and not (node is CSGShape3D), "%s must not ship visible blockout geometry at %s" % [track_id, current_path])
	for child in node.get_children():
		if child is Node:
			_assert_no_visible_blockout_nodes(child as Node, track_id, "%s/%s" % [current_path, str((child as Node).name)])

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

func _assert_mesh_aabb_within(root: Node, node_path: String, allowed: AABB, message: String) -> void:
	var mesh_instance := root.get_node_or_null(node_path) as MeshInstance3D
	assert_true(mesh_instance != null, "%s; missing node: %s" % [message, node_path])
	if mesh_instance == null:
		return
	var bounds := _mesh_instance_global_aabb(mesh_instance)
	var tolerance := 0.05
	assert_true(bounds.position.x >= allowed.position.x - tolerance, "%s; %s min x %f should be >= %f" % [message, node_path, bounds.position.x, allowed.position.x])
	assert_true(bounds.position.y >= allowed.position.y - tolerance, "%s; %s min y %f should be >= %f" % [message, node_path, bounds.position.y, allowed.position.y])
	assert_true(bounds.position.z >= allowed.position.z - tolerance, "%s; %s min z %f should be >= %f" % [message, node_path, bounds.position.z, allowed.position.z])
	assert_true(bounds.end.x <= allowed.end.x + tolerance, "%s; %s max x %f should be <= %f" % [message, node_path, bounds.end.x, allowed.end.x])
	assert_true(bounds.end.y <= allowed.end.y + tolerance, "%s; %s max y %f should be <= %f" % [message, node_path, bounds.end.y, allowed.end.y])
	assert_true(bounds.end.z <= allowed.end.z + tolerance, "%s; %s max z %f should be <= %f" % [message, node_path, bounds.end.z, allowed.end.z])

func _assert_no_visible_mesh_intersects_aabb(node: Node, forbidden: AABB, excluded_path_prefix: String, message: String) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.visible:
			var scene_root := node.owner if node.owner != null else node.get_tree().edited_scene_root
			var relative_path := str(scene_root.get_path_to(node)) if scene_root != null else str(node.get_path())
			if not relative_path.begins_with(excluded_path_prefix):
				var bounds := _mesh_instance_global_aabb(mesh_instance)
				assert_true(not bounds.intersects(forbidden), "%s; intersecting node: %s" % [message, relative_path])
	for child in node.get_children():
		_assert_no_visible_mesh_intersects_aabb(child, forbidden, excluded_path_prefix, message)

func _assert_no_broad_foundation_slab_inside_first_floor(root: Node, track_id: String) -> void:
	var occupied_first_floor := AABB(Vector3(-205.0, -0.1, -135.0), Vector3(430.0, 7.5, 285.0))
	for holder_path in ["Foundation", "ExteriorShell"]:
		var holder := root.get_node_or_null(holder_path)
		assert_true(holder != null, "%s should include %s for foundation false-floor audit" % [track_id, holder_path])
		if holder != null:
			_assert_no_broad_visible_mesh_intersects_aabb(holder, occupied_first_floor, 9000.0, "%s foundation/exterior shell must not render a broad false floor inside occupied first-floor space" % track_id)

func _assert_no_roof_closure_blocks_attic(root: Node, track_id: String) -> void:
	var attic_clear_volume := AABB(Vector3(-165.0, 103.5, -95.0), Vector3(230.0, 31.0, 215.0))
	var shell := root.get_node_or_null("ExteriorShell")
	assert_true(shell != null, "%s should include ExteriorShell for attic roof-closure audit" % track_id)
	if shell != null:
		_assert_no_broad_visible_mesh_intersects_aabb(shell, attic_clear_volume, 9000.0, "%s exterior shell roof closure must not span the playable attic clear volume" % track_id)

func _assert_no_broad_visible_mesh_intersects_aabb(node: Node, forbidden: AABB, max_horizontal_area: float, message: String) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.visible:
			var bounds := _mesh_instance_global_aabb(mesh_instance)
			var horizontal_area := bounds.size.x * bounds.size.z
			if horizontal_area > max_horizontal_area:
				assert_true(not bounds.intersects(forbidden), "%s; broad node: %s bounds=%s" % [message, str(node.name), str(bounds)])
	for child in node.get_children():
		_assert_no_broad_visible_mesh_intersects_aabb(child, forbidden, max_horizontal_area, message)

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
