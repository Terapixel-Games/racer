extends "res://tests/framework/TestCase.gd"

const TrackCatalog = preload("res://scripts/track/TrackCatalog.gd")
const TrackRuntimeBuilder = preload("res://scripts/track/TrackRuntimeBuilder.gd")
const TrackSceneAuthoringData = preload("res://scripts/track/TrackSceneAuthoringData.gd")
const RaceController = preload("res://scripts/RaceController.gd")
const OutOfBoundsRules = preload("res://scripts/logic/OutOfBoundsRules.gd")
const StagePropAuthoring = preload("res://scripts/track/StagePropAuthoring.gd")
const OUTDOOR_GRASS_SHADER := "res://assets/gameplay/materials/grass/playground_grass.gdshader"
const OUTDOOR_GRASS_BLADE_SHADER := "res://assets/gameplay/materials/grass/playground_grass_blades.gdshader"
const OUTDOOR_PLAYGROUND_FLOOR_TEXTURE := "res://assets/gameplay/materials/playground/outdoor_playground_floor_albedo.png"

func test_kitchen_track_scene_loads_with_runtime_nodes() -> void:
	var packed := load("res://assets/gameplay/tracks/kitchen/kitchen_track.tscn")
	assert_true(packed is PackedScene, "Kitchen track scene should load")
	var instance := (packed as PackedScene).instantiate()
	scene_tree.root.add_child(instance)
	var built_track := instance.get_node_or_null("BuiltTrack")
	assert_true(built_track != null, "Kitchen track scene should build runtime track")
	assert_true(instance.get_node_or_null("BuiltTrack/Road") != null, "Kitchen track should include generated road")
	assert_true(instance.get_node_or_null("BuiltTrack/GridRoad") != null, "Kitchen track should include Kenney Racing Kit grid road visuals")
	assert_true(instance.get_node_or_null("BuiltTrack/GridRoad") is GridMap, "Kitchen visible road should be a runtime GridMap so Kenney tile materials and rotations are preserved")
	assert_equal(_node_count_by_type(built_track, "WorldEnvironment"), 1, "Kitchen runtime should build exactly one WorldEnvironment")
	var world_environment := instance.get_node_or_null("BuiltTrack/WorldEnvironment") as WorldEnvironment
	assert_true(world_environment != null, "Kitchen track should include a world environment")
	if world_environment != null:
		assert_true(world_environment.environment != null, "Kitchen world environment should own an Environment resource")
		if world_environment.environment != null:
			assert_true(world_environment.environment.sky != null, "Kitchen world environment should include a sky")
			if world_environment.environment.sky != null:
				assert_true(world_environment.environment.sky.sky_material is ShaderMaterial, "Kitchen sky should use the stage sky shader material")
	assert_true(instance.get_node_or_null("BuiltTrack/SunLight") is DirectionalLight3D, "Kitchen runtime should include the stage directional light")
	var road_shape_node := instance.get_node_or_null("BuiltTrack/Road/CollisionBody/CollisionShape3D") as CollisionShape3D
	assert_true(road_shape_node != null, "Kitchen road should include collision shape")
	if road_shape_node != null:
		assert_true(road_shape_node.shape is ConcavePolygonShape3D, "Kitchen road should use generated mesh collision")
		if road_shape_node.shape is ConcavePolygonShape3D:
			assert_true((road_shape_node.shape as ConcavePolygonShape3D).backface_collision, "Kitchen road collision should be visible to camera probes from underneath")
	assert_true(instance.get_node_or_null("BuiltTrack/TrackBody") == null, "Kitchen grid mode should not build the broad legacy track body")
	assert_true(instance.get_node_or_null("BuiltTrack/Rails") != null, "Kitchen track should include generated route rails")
	assert_true(_child_count(instance.get_node_or_null("BuiltTrack/Rails")) > 0, "Kitchen route rails should instantiate rail asset pieces")
	assert_true(_enabled_collision_objects(instance.get_node_or_null("BuiltTrack/Rails")) > 0, "Kitchen generated rails should be collidable")
	assert_equal(_first_material_texture_path(instance.get_node_or_null("BuiltTrack/Rails")), "res://assets/gameplay/materials/metal/toy_metal_albedo.png", "Kitchen generated rails should use the stage metal material")
	assert_true(absf(_first_material_uv_scale(instance.get_node_or_null("BuiltTrack/Rails")) - 0.5) <= 0.01, "Kitchen generated rails should use the stage rail texture UV scale")
	assert_true(instance.get_node_or_null("BuiltTrack/Walls") == null, "Kitchen track should not auto-generate route walls while guard segments are being authored")
	assert_true(instance.get_node_or_null("BuiltTrack/CheckpointSystem") != null, "Kitchen track should include checkpoint system")
	assert_true(instance.get_node_or_null("BuiltTrack/SpawnPoints") != null, "Kitchen track should include spawn points")
	assert_true(instance.get_node_or_null("BuiltTrack/SpawnPoints/Start01") != null, "Kitchen track should generate Start01 from RoadGridMap slots")
	assert_true(instance.get_node_or_null("BuiltTrack/SpawnPoints/Start08") != null, "Kitchen track should generate Start08 from RoadGridMap slots")
	assert_true(instance.get_node_or_null("BuiltTrack/ItemSockets") == null, "MVP Kitchen track should not include item sockets")
	assert_true(instance.get_node_or_null("BuiltTrack/HazardSockets") == null, "MVP Kitchen track should not include hazard sockets")
	assert_true(instance.get_node_or_null("BuiltTrack/ShortcutGates") == null, "MVP Kitchen track should not include shortcut gates")
	assert_true(instance.get_node_or_null("BuiltTrack/ShortcutSurface") == null, "Kitchen table jump surface should stay disabled while it blocks the main path")
	assert_true(instance.get_node_or_null("BuiltTrack/SurfaceSegments") == null, "MVP Kitchen track should not include surface segment metadata markers")
	assert_true(instance.get_node_or_null("BuiltTrack/AudioZones/SinkSplashZone") != null, "Kitchen track should include authored audio zone markers")
	assert_true(instance.get_node_or_null("BuiltTrack/AudioZones/StoveSizzleZone") != null, "Kitchen track should include stove sizzle audio zone markers")
	assert_true(instance.get_node_or_null("BuiltTrack/SectionMarkers") == null, "Kitchen MVP track should not build legacy section marker overlays")
	assert_true(instance.get_node_or_null("BuiltTrack/FloorVisual") != null, "Kitchen track should include a non-colliding floor visual below the counter")
	assert_true(instance.get_node_or_null("BuiltTrack/FloorTileGrid") != null, "Kitchen floor should include visible tile grid lines for room scale")
	assert_true(_node_position(instance, "BuiltTrack/FloorVisual").y <= -8.0, "Kitchen floor visual should be far below the countertop route")
	assert_true(instance.get_node_or_null("BuiltTrack/Ground") == null, "Kitchen floor should not be a colliding ground plane")
	assert_true(instance.get_node_or_null("BuiltTrack/Dressing/KitchenCeiling") == null, "Kitchen runtime should not add old hardcoded ceiling geometry over authored room scale")
	assert_true(instance.get_node_or_null("BuiltTrack/Dressing/FridgeLandmark") == null, "Kitchen runtime should not duplicate old hardcoded fridge geometry over authored room scale")
	assert_true(instance.get_node_or_null("BuiltTrack/Dressing/EditableRoom") != null, "Kitchen track should include the directly editable room scene")
	assert_true(instance.get_node_or_null("BuiltTrack/Dressing/EditableRoom/RoadGridMap") != null, "Editable room scene should expose the authored RoadGridMap")
	var road_grid_map := instance.get_node_or_null("BuiltTrack/Dressing/EditableRoom/RoadGridMap")
	assert_true(road_grid_map is Node3D and not (road_grid_map as Node3D).visible, "Runtime dressing should hide the authoring RoadGridMap so only generated GridRoad is visible")
	assert_equal((road_grid_map.get("spawn_slots") as Array).size() if road_grid_map != null else 0, 8, "Editable room RoadGridMap should author the full spawn grid")
	assert_true(instance.get_node_or_null("BuiltTrack/Dressing/EditableRoom/TrackAuthoringPreview") == null, "Kitchen editable room should not keep the legacy TrackAuthoringPreview")
	assert_true(instance.get_node_or_null("BuiltTrack/Dressing/EditableRoom/RoadSegments") == null, "Kitchen editable room should not keep legacy road segment authoring")
	assert_true(instance.get_node_or_null("BuiltTrack/Dressing/EditableRoom/Track/Checkpoints") == null, "Kitchen editable room should not keep legacy checkpoint markers")
	assert_true(instance.get_node_or_null("BuiltTrack/Dressing/EditableRoom/Track/SectionMarkers") == null, "Kitchen editable room should not keep legacy section markers")
	assert_true(instance.get_node_or_null("BuiltTrack/Dressing/EditableRoom/Track/ItemSockets") == null, "Kitchen editable room should not keep legacy item socket markers")
	assert_true(instance.get_node_or_null("BuiltTrack/Dressing/EditableRoom/Track/HazardSockets") == null, "Kitchen editable room should not keep legacy hazard socket markers")
	assert_true(instance.get_node_or_null("BuiltTrack/Dressing/EditableRoom/Track/ShortcutGates") == null, "Kitchen editable room should not keep legacy shortcut gate markers")
	assert_true(instance.get_node_or_null("BuiltTrack/Dressing/EditableRoom/Track/SpawnPoints") == null, "Kitchen grid gameplay should not require legacy editable spawn markers")
	assert_true(instance.get_node_or_null("BuiltTrack/Dressing/EditableRoom/Track/floor") != null, "Editable room scene should include the authored floor")
	assert_true(not (instance.get_node_or_null("BuiltTrack/Dressing/EditableRoom/Track/floor") is CollisionObject3D), "Editable room floor should be visual-only so it cannot block the course")
	assert_true(_node_position(instance, "BuiltTrack/Dressing/EditableRoom/Track/floor").y <= -32.0, "Editable room floor should stay below the playable course")
	assert_true(instance.get_node_or_null("BuiltTrack/Dressing/EditableRoom/Track/RoomShell/BackWall") != null, "Editable room scene should include selectable room shell pieces")
	assert_true(not _node_visible(instance, "BuiltTrack/Dressing/EditableRoom/Track/RoomShell/BackWall"), "Kitchen back wall should be split around the window instead of blocking the view")
	assert_true(instance.get_node_or_null("BuiltTrack/Dressing/EditableRoom/Track/RoomShell/BackWallLeftOfWindow") != null, "Kitchen window should keep editable wall trim on the left")
	assert_true(instance.get_node_or_null("BuiltTrack/Dressing/EditableRoom/Track/RoomShell/BackWallRightOfWindow") != null, "Kitchen window should keep editable wall trim on the right")
	assert_true(_mesh_material_alpha(instance, "BuiltTrack/Dressing/EditableRoom/Track/RoomShell/WindowGlass") <= 0.15, "Kitchen window glass should be transparent enough for sky visibility")
	assert_true(instance.get_node_or_null("BuiltTrack/Dressing/EditableRoom/Track/Appliances/kitchenSink") != null, "Editable room scene should preserve hand-placed kitchen props")
	assert_true(instance.get_node_or_null("BuiltTrack/Dressing/EditableRoom/Track/WaterSurfaces/SinkWater") != null, "Editable room scene should include authored sink water")
	assert_true(_node_position(instance, "BuiltTrack/Dressing/EditableRoom/Track/WaterSurfaces/SinkWater").distance_to(_authored_kitchen_position("Track/WaterSurfaces/SinkWater")) <= 0.05, "Kitchen sink water should stay at the authored editable scene location")
	assert_true(instance.get_node_or_null("BuiltTrack/Dressing/EditableRoom/Track/WaterSurfaces/WasherWater") != null, "Editable room scene should include authored washer water")
	assert_true(_node_has_script(instance, "BuiltTrack/Dressing/EditableRoom/Track/washer"), "Editable room washer should run its in-place rumble script")
	assert_true(_node_has_script(instance, "BuiltTrack/Dressing/EditableRoom/Track/dryer"), "Editable room dryer should run its in-place rumble script")
	assert_true(instance.get_node_or_null("BuiltTrack/Dressing/EditableRoom/Track/UpperCabinets") != null, "Editable room scene should preserve authored upper cabinet grouping")
	assert_equal(_enabled_collision_objects(instance.get_node_or_null("BuiltTrack/Dressing/EditableRoom")), 0, "Editable room dressing should not collide with the kart")
	assert_equal(instance.get_node_or_null("BuiltTrack/Dressing").get_child_count(), 1, "Kitchen runtime dressing should only instantiate the editable room")
	assert_true(instance.get_node_or_null("BuiltTrack/Dressing/StageProps") == null, "Kitchen runtime should not instantiate metadata stage props")
	assert_true(instance.get_node_or_null("BuiltTrack/Dressing/KitchenTable") == null, "Kitchen runtime should not add hardcoded kitchen table dressing")
	assert_true(instance.get_node_or_null("BuiltTrack/Dressing/KitchenSink") == null, "Kitchen runtime should not add hardcoded sink dressing")
	assert_true(instance.get_node_or_null("BuiltTrack/Dressing/SpoonHazard") == null, "Kitchen runtime should not add hardcoded food hazards")
	assert_true(instance.get_node_or_null("BuiltTrack/Dressing/FridgeTopSpeedStrip") == null, "Kitchen runtime should not add hardcoded route stripes")
	var definition := TrackSceneAuthoringData.apply_to_definition(TrackCatalog.get_definition("kitchen"))
	assert_true(_runtime_spawn_matches_socket(instance, "BuiltTrack/SpawnPoints/Start01", definition.spawn_points[0]), "Generated Start01 should match the first RoadGridMap-authored slot")
	assert_true(_runtime_spawn_matches_socket(instance, "BuiltTrack/SpawnPoints/Start08", definition.spawn_points[7]), "Generated Start08 should match the eighth RoadGridMap-authored slot")
	instance.queue_free()

func test_outdoor_playground_runtime_uses_grass_shader() -> void:
	var definition := TrackSceneAuthoringData.apply_to_definition(TrackCatalog.get_definition("outdoor_playground"))
	assert_true(definition != null, "Outdoor Playground definition should load")
	var built := TrackRuntimeBuilder.build(definition)
	var track_node := built.get("node", null) as Node3D
	scene_tree.root.add_child(track_node)
	assert_true(definition.grass_zones.size() >= 2, "Outdoor Playground should use authored grass zones")
	assert_true(_has_editable_grass_zone_bounds(track_node.get_node_or_null("Dressing/EditableRoom/GrassZones")), "Runtime editable room should retain selectable grass zone Area3D bounds")
	assert_equal(_mesh_shader_path(track_node, "FloorVisual"), OUTDOOR_GRASS_SHADER, "Outdoor Playground generated floor should use the grass shader")
	assert_equal(_shader_texture_path(track_node, "FloorVisual", "floor_texture"), OUTDOOR_PLAYGROUND_FLOOR_TEXTURE, "Outdoor Playground generated floor should use the authored floor texture")
	assert_equal(_mesh_shader_path(track_node, "Dressing/EditableRoom/floor/MeshInstance3D"), OUTDOOR_GRASS_SHADER, "Outdoor Playground editable floor should use the grass shader at runtime")
	assert_equal(_shader_texture_path(track_node, "Dressing/EditableRoom/floor/MeshInstance3D", "floor_texture"), OUTDOOR_PLAYGROUND_FLOOR_TEXTURE, "Outdoor Playground editable floor should use the authored floor texture at runtime")
	assert_true(track_node.get_node_or_null("PlaygroundGrassBlades") is MultiMeshInstance3D, "Outdoor Playground should build an upright grass blade layer")
	assert_true(_multimesh_instance_count(track_node, "PlaygroundGrassBlades") >= 18000, "Outdoor Playground grass should use enough blades to read as grass from kart height")
	assert_equal(_multimesh_shader_path(track_node, "PlaygroundGrassBlades"), OUTDOOR_GRASS_BLADE_SHADER, "Outdoor Playground grass blades should use the blade sway shader")
	assert_true(_first_multimesh_instance_y(track_node, "PlaygroundGrassBlades") > definition.floor_visual_y + 10.0, "Outdoor Playground grass blades should sit on the authored visible floor, not the lower reset plane")
	assert_true(_multimesh_instances_inside_grass_zones(track_node, "PlaygroundGrassBlades", definition.grass_zones, 300), "Outdoor Playground grass blades should be scattered inside authored grass zones")
	track_node.queue_free()

func test_attic_mayhem_authoring_scene_contains_redesign_assets() -> void:
	assert_true(FileAccess.file_exists("res://assets/gameplay/tracks/attic/reference/attic_mayhem_reference.png"), "Attic Mayhem reference image should be copied into the repo")
	assert_true(FileAccess.file_exists("res://assets/gameplay/tracks/attic/props/source/jack_in_the_box_source.glb"), "Jack-in-the-box source GLB should be retained for future cleanup")
	assert_true(FileAccess.file_exists("res://assets/gameplay/tracks/attic/props/jack_parts/jack_in_the_box_parts.glb"), "Jack-in-the-box split runtime GLB should exist")
	assert_true(FileAccess.get_file_as_bytes("res://assets/gameplay/tracks/attic/props/JackInTheBoxSetpiece.tscn").size() < 1000000, "Jack-in-the-box scene should stay lightweight and not embed GLB mesh payloads")
	assert_true(FileAccess.file_exists("res://assets/gameplay/tracks/attic/props/old_chest.glb"), "Old chest GLB should be imported")
	assert_true(FileAccess.file_exists("res://assets/gameplay/tracks/attic/props/industrial_object.glb"), "Industrial object GLB should be imported")
	assert_true(FileAccess.file_exists("res://assets/source/audio/sfx/attic/wind_blowing.mp3"), "Attic wind audio should be imported")
	assert_true(FileAccess.file_exists("res://assets/source/audio/sfx/attic/jack_crank.mp3"), "Jack crank audio should be imported")
	assert_true(FileAccess.file_exists("res://assets/source/audio/sfx/attic/jack_spring.mp3"), "Jack spring audio should be imported")
	assert_true(FileAccess.file_exists("res://assets/source/audio/sfx/attic/jack_laugh.mp3"), "Jack laugh audio should be imported")
	var packed := load("res://assets/gameplay/tracks/attic/attic_editable_room.tscn")
	assert_true(packed is PackedScene, "Attic editable scene should load")
	var instance := (packed as PackedScene).instantiate()
	scene_tree.root.add_child(instance)
	assert_true(instance.get_node_or_null("RoomShell/AtticRidgeBeam") != null, "Attic shell should include a ridge beam")
	assert_true(instance.get_node_or_null("RoomShell/BackUpperGableWall") != null, "Attic shell should close the rear gable under the pitched roof")
	assert_true(instance.get_node_or_null("RoomShell/FrontUpperGableWall") != null, "Attic shell should close the front gable under the pitched roof")
	assert_true(instance.get_node_or_null("RoomShell/LeftUpperEaveWall") != null, "Attic shell should close the left upper eave")
	assert_true(instance.get_node_or_null("RoomShell/RightUpperEaveWall") != null, "Attic shell should close the right upper eave")
	assert_true(instance.get_node_or_null("RoomShell/BackWallClosure") != null, "Attic shell should include a full rear backing wall")
	assert_true(instance.get_node_or_null("RoomShell/FrontWallClosure") != null, "Attic shell should include a full front backing wall")
	assert_true(instance.get_node_or_null("RoomShell/LeftWallClosure") != null, "Attic shell should include a full left backing wall")
	assert_true(instance.get_node_or_null("RoomShell/RightWallFrontClosure") != null, "Attic shell should close the right wall before the window")
	assert_true(instance.get_node_or_null("RoomShell/RightWallRearClosure") != null, "Attic shell should close the right wall after the window")
	assert_true(instance.get_node_or_null("RoomShell/RightWindowLowerClosure") != null, "Attic shell should close below the right window")
	assert_true(instance.get_node_or_null("RoomShell/RightWindowUpperClosure") != null, "Attic shell should close above the right window")
	assert_true(instance.get_node_or_null("RoomShell/RafterLeft01") != null, "Attic shell should include left rafters")
	assert_true(instance.get_node_or_null("RoomShell/RafterRight01") != null, "Attic shell should include right rafters")
	assert_true(instance.get_node_or_null("RoomShell/AtticWindowGlass") != null, "Attic shell should include intact square window glass")
	assert_true(instance.get_node_or_null("RoomShell/AtticWindowStormBackdrop") != null, "Attic shell should include the storm backdrop behind the window")
	assert_equal(_mesh_shader_path(instance, "RoomShell/AtticWindowGlass"), "res://assets/shaders/attic_window_glass.gdshader", "Attic window glass should use the glass shader")
	assert_equal(_first_material_texture_path(instance.get_node_or_null("RoomShell/AtticWindowStormBackdrop")), "res://assets/gameplay/tracks/attic/textures/window_storm_backdrop.png", "Attic window backdrop should use the storm texture")
	assert_true(instance.get_node_or_null("Dressing/JackInTheBoxSetpiece") != null, "Attic dressing should include the jack-in-the-box setpiece marker")
	assert_true(instance.get_node_or_null("Dressing/OldChestMeshy") != null, "Attic dressing should include the old chest marker")
	assert_true(instance.get_node_or_null("Dressing/IndustrialObjectMeshy") != null, "Attic dressing should include the industrial object marker")
	assert_true(instance.get_node_or_null("AudioZones/attic_window_wind_zone") != null, "Attic authoring scene should expose the window wind zone")
	instance.queue_free()

func test_jack_in_the_box_setpiece_builds_animated_parts() -> void:
	var packed := load("res://assets/gameplay/tracks/attic/props/JackInTheBoxSetpiece.tscn")
	assert_true(packed is PackedScene, "Jack-in-the-box setpiece scene should load")
	var instance := (packed as PackedScene).instantiate() as Node3D
	scene_tree.root.add_child(instance)
	for node_path in ["BoxBase", "Lid", "Crank", "Spring", "SpringCoil", "ClownHead", "Eyes", "Mouth", "Hat", "LeftHand", "RightHand", "TriggerArea", "AnimationPlayer", "CrankAudio", "SpringAudio", "LaughAudio"]:
		assert_true(instance.get_node_or_null(node_path) != null, "Jack-in-the-box setpiece should create %s" % node_path)
	for node_path in ["BoxBase/SourcePart", "Lid/SourcePart", "Crank/SourcePart", "Spring/SourcePart", "ClownHead/SourcePart"]:
		assert_true(instance.get_node_or_null(node_path) != null, "Jack-in-the-box should use a split Meshy source part at %s" % node_path)
	assert_true(instance.get_node_or_null("Lid/HingedCover") == null, "Jack-in-the-box should not create placeholder lid geometry when split source parts are available")
	assert_true(instance.get_node_or_null("Crank/CrankVisual") == null, "Jack-in-the-box should animate the split source crank instead of placeholder geometry")
	assert_true(instance.get_node_or_null("ClownHead/Mesh") == null, "Split Meshy clown part should replace the old spherical clown head placeholder")
	assert_true(not (instance.get_node_or_null("Spring") as Node3D).visible, "Spring should be hidden while the box is closed")
	assert_true((instance.get_node_or_null("Lid/SourcePart") as Node3D).visible, "Split source lid part should drive the lid animation instead of placeholder geometry")
	assert_true((instance.get_node_or_null("Crank/SourcePart") as Node3D).visible, "Split source crank should stay visible and rotate around the crank pivot")
	var trigger_area := instance.get_node_or_null("TriggerArea") as Area3D
	assert_true(trigger_area != null and trigger_area.get_node_or_null("CollisionShape3D") is CollisionShape3D, "Jack-in-the-box should expose an Area3D trigger shape")
	assert_true(instance.has_method("trigger"), "Jack-in-the-box should expose a trigger method")
	instance.call("trigger")
	assert_equal(str(instance.call("state_for_test")), "windup", "Jack-in-the-box should enter windup after triggering")
	instance.call("trigger")
	assert_equal(str(instance.call("state_for_test")), "windup", "Jack-in-the-box should ignore repeat triggers while active")
	instance.set("cooldown_seconds", 0.2)
	assert_true((instance.get_node_or_null("CrankAudio") as AudioStreamPlayer3D).stream != null, "Jack crank stream should load")
	assert_true((instance.get_node_or_null("SpringAudio") as AudioStreamPlayer3D).stream != null, "Jack spring stream should load")
	assert_true((instance.get_node_or_null("LaughAudio") as AudioStreamPlayer3D).stream != null, "Jack laugh stream should load")
	instance.queue_free()

func test_stage_prop_authoring_does_not_build_heavy_preview_at_runtime() -> void:
	var prop := StagePropAuthoring.new()
	prop.prop_kind = "scene"
	prop.asset_path = "res://assets/gameplay/tracks/attic/props/JackInTheBoxSetpiece.tscn"
	prop.preview_enabled = true
	scene_tree.root.add_child(prop)
	assert_true(prop.get_node_or_null("GeneratedPreview") == null, "Authoring prop previews should be editor-only so level select does not synchronously load heavy GLBs")
	prop.queue_free()

func test_jack_in_the_box_exposes_editor_tuning_and_preview() -> void:
	var packed := load("res://assets/gameplay/tracks/attic/props/JackInTheBoxSetpiece.tscn")
	assert_true(packed is PackedScene, "Jack-in-the-box setpiece scene should load")
	var instance := (packed as PackedScene).instantiate() as Node3D
	scene_tree.root.add_child(instance)
	instance.set("lid_hinge_position", Vector3(0.25, 2.1, 0.6))
	instance.set("lid_source_position", Vector3(0.1, 0.2, -0.3))
	instance.set("lid_closed_rotation_x", 135.0)
	instance.set("crank_pivot_position", Vector3(-0.6, 1.5, 0.25))
	instance.set("crank_source_position", Vector3(0.7, 0.9, -0.2))
	instance.set("crank_preview_degrees", 45.0)
	instance.call("_apply_editor_preview_pose")
	var lid := instance.get_node_or_null("Lid") as Node3D
	var crank := instance.get_node_or_null("Crank") as Node3D
	var lid_source := instance.get_node_or_null("Lid/SourcePart") as Node3D
	var crank_source := instance.get_node_or_null("Crank/SourcePart") as Node3D
	assert_equal(lid.position, Vector3(0.25, 2.1, 0.6), "Editor tuning should move the lid hinge object")
	assert_equal(lid_source.position, Vector3(0.1, 0.2, -0.3), "Editor tuning should move the visible split lid source object")
	assert_equal(crank.position, Vector3(-0.6, 1.5, 0.25), "Editor tuning should move the crank pivot object")
	assert_equal(crank_source.position, Vector3(0.7, 0.9, -0.2), "Editor tuning should move the visible split crank source object")
	assert_true(absf(lid.rotation_degrees.x - 135.0) <= 0.01, "Editor closed preview should use the tuned lid rotation")
	assert_true(absf(crank.rotation_degrees.x - 45.0) <= 0.01, "Editor closed preview should use the tuned crank preview rotation")
	instance.set("editor_preview_pose", JackInTheBoxSetpiece.EditorPreviewPose.OPEN)
	instance.call("_apply_editor_preview_pose")
	assert_true((instance.get_node_or_null("ClownHead") as Node3D).visible, "Editor open preview should show the clown source object")
	assert_true((instance.get_node_or_null("Spring") as Node3D).visible, "Editor open preview should show the spring source object")
	instance.queue_free()

func test_jack_in_the_box_shows_clown_source_part_during_pop() -> void:
	var packed := load("res://assets/gameplay/tracks/attic/props/JackInTheBoxSetpiece.tscn")
	assert_true(packed is PackedScene, "Jack-in-the-box setpiece scene should load")
	var instance := (packed as PackedScene).instantiate() as Node3D
	scene_tree.root.add_child(instance)
	var clown_head := instance.get_node_or_null("ClownHead") as Node3D
	assert_true(clown_head != null and clown_head.get_node_or_null("SourcePart") != null and not clown_head.visible, "Split clown part should start hidden inside the closed box")
	instance.call("trigger")
	for i in range(13):
		instance.call("_process", 0.1)
	assert_true(clown_head.visible, "Split clown part should become visible during the pop")
	instance.queue_free()

func test_jack_in_the_box_only_triggers_for_racers() -> void:
	var packed := load("res://assets/gameplay/tracks/attic/props/JackInTheBoxSetpiece.tscn")
	assert_true(packed is PackedScene, "Jack-in-the-box setpiece scene should load")
	var instance := (packed as PackedScene).instantiate() as Node3D
	scene_tree.root.add_child(instance)
	var trigger_area := instance.get_node_or_null("TriggerArea") as Area3D
	assert_equal(trigger_area.collision_mask, 2, "Jack-in-the-box trigger should only listen to the car collision layer")
	var static_body := StaticBody3D.new()
	instance.call("_on_trigger_body_entered", static_body)
	assert_equal(str(instance.call("state_for_test")), "idle", "Static track geometry should not trigger the jack-in-the-box")
	var car_scene := load("res://scenes/Car.tscn") as PackedScene
	var car := car_scene.instantiate() as CarController
	instance.call("_on_trigger_body_entered", car)
	assert_equal(str(instance.call("state_for_test")), "windup", "A racer body should trigger the jack-in-the-box")
	static_body.queue_free()
	car.queue_free()
	instance.queue_free()

func test_jack_in_the_box_resets_closed_after_pop() -> void:
	var packed := load("res://assets/gameplay/tracks/attic/props/JackInTheBoxSetpiece.tscn")
	assert_true(packed is PackedScene, "Jack-in-the-box setpiece scene should load")
	var instance := (packed as PackedScene).instantiate() as Node3D
	scene_tree.root.add_child(instance)
	instance.set("popped_open_seconds", 0.2)
	instance.call("trigger")
	for i in range(36):
		instance.call("_process", 0.1)
	assert_true(bool(instance.call("is_closed")), "Jack-in-the-box should reset to the closed pose after popping")
	instance.queue_free()

func test_jack_in_the_box_retriggers_after_cooldown() -> void:
	var packed := load("res://assets/gameplay/tracks/attic/props/JackInTheBoxSetpiece.tscn")
	assert_true(packed is PackedScene, "Jack-in-the-box setpiece scene should load")
	var instance := (packed as PackedScene).instantiate() as Node3D
	scene_tree.root.add_child(instance)
	instance.set("popped_open_seconds", 0.1)
	instance.set("cooldown_seconds", 0.2)
	instance.call("trigger")
	for i in range(36):
		instance.call("_process", 0.1)
	assert_true(bool(instance.call("is_closed")), "Jack-in-the-box should close after its first pop")
	instance.call("trigger")
	assert_equal(str(instance.call("state_for_test")), "windup", "Jack-in-the-box should accept another trigger after cooldown")
	instance.queue_free()

func test_attic_mayhem_runtime_builds_redesigned_room() -> void:
	var definition := TrackSceneAuthoringData.apply_to_definition(TrackCatalog.get_definition("attic"))
	assert_true(definition != null, "Attic definition should load")
	assert_true(definition.road_width >= 15.0, "Attic Mayhem route should be widened for AI reliability")
	assert_true(definition.audio_ids.has("attic_window_wind"), "Attic definition should include window wind audio")
	assert_true(definition.audio_zones.size() >= 3, "Attic definition should export music, feature, and window wind zones")
	var built := TrackRuntimeBuilder.build(definition)
	var track_node := built.get("node", null) as Node3D
	scene_tree.root.add_child(track_node)
	assert_true(track_node.get_node_or_null("Dressing/EditableRoom/RoomShell/AtticRidgeBeam") != null, "Runtime attic should include the pitched shell ridge beam")
	assert_true(track_node.get_node_or_null("Dressing/EditableRoom/RoomShell/AtticWindowGlass") != null, "Runtime attic should include the square window glass")
	assert_true(track_node.get_node_or_null("Dressing/EditableRoom/Dressing/JackInTheBoxSetpiece") != null, "Runtime attic should include the jack-in-the-box setpiece marker")
	assert_true(track_node.get_node_or_null("Dressing/EditableRoom/Dressing/IndustrialObjectMeshy") != null, "Runtime attic should include the industrial object marker")
	assert_true(track_node.get_node_or_null("AudioZones/attic_window_wind_zone") != null, "Runtime attic should build the window wind audio zone")
	assert_true((built.get("waypoints", []) as Array).size() >= 30, "Runtime attic should keep the full route")
	assert_true((built.get("spawns", []) as Array).size() >= 8, "Runtime attic should keep a full start grid")
	assert_true(_enabled_collision_objects(track_node.get_node_or_null("Dressing/EditableRoom")) == 0, "Runtime editable attic dressing should not collide with racers")
	track_node.queue_free()

func test_car_can_be_placed_on_kitchen_start_grid() -> void:
	var definition := TrackCatalog.get_definition("kitchen")
	var built := TrackRuntimeBuilder.build(definition)
	var track_node := built.get("node", null) as Node3D
	scene_tree.root.add_child(track_node)
	var spawns: Array = built.get("spawns", [])
	var route_points: Array[Vector3] = []
	for point in built.get("waypoints", definition.route_points):
		if point is Vector3:
			route_points.append(point)
	assert_true(spawns.size() >= 8, "Kitchen builder should return 8 spawn transforms")
	for spawn in spawns:
		if spawn is Transform3D:
			var distance := _distance_to_route_xz((spawn as Transform3D).origin, route_points, definition.closed_loop)
			assert_true(distance <= definition.road_width * 0.5 + 0.1, "Kitchen start grid should place every spawn on the road")
	var car_scene := load("res://scenes/Car.tscn")
	assert_true(car_scene is PackedScene, "Car scene should load")
	var car := (car_scene as PackedScene).instantiate() as Node3D
	scene_tree.root.add_child(car)
	car.global_transform = spawns[0]
	assert_true(car.global_transform.origin.distance_to((spawns[0] as Transform3D).origin) < 0.01, "Car should be placeable on the Kitchen start grid")
	car.queue_free()
	track_node.queue_free()

func test_kitchen_out_of_bounds_instant_pop_reset() -> void:
	var definition := TrackCatalog.get_definition("kitchen")
	assert_true(not OutOfBoundsRules.should_reset(-10.0, definition.out_of_bounds_y, definition.reset_mode), "Driving on the authored floor should not auto-reset")
	assert_true(OutOfBoundsRules.should_reset(definition.out_of_bounds_y - 0.5, definition.out_of_bounds_y, definition.reset_mode), "Falling below the floor should trigger Kitchen reset")
	var car_scene := load("res://scenes/Car.tscn")
	assert_true(car_scene is PackedScene, "Car scene should load")
	var car := (car_scene as PackedScene).instantiate() as CharacterBody3D
	scene_tree.root.add_child(car)
	car.global_transform.origin = Vector3(0, 0.2, 0)
	car.velocity = Vector3(4, -8, 2)
	var reset_transform := Transform3D(Basis(Vector3.UP, deg_to_rad(90.0)), Vector3(-82, 3.8, -79))
	RaceController.apply_instant_reset(car, reset_transform)
	assert_equal(car.global_transform.origin, reset_transform.origin, "Instant pop reset should move the car back to the safe transform")
	assert_equal(car.velocity, Vector3.ZERO, "Instant pop reset should stop the car")
	car.queue_free()

func test_manual_return_uses_last_road_center_point() -> void:
	var definition := TrackCatalog.get_definition("kitchen")
	var off_course_position := definition.route_points[3] + Vector3(18.0, 0.0, 0.0)
	var reset_transform := RaceController.centered_track_return_transform(definition.route_points, off_course_position, definition.closed_loop)
	var distance := _distance_to_route_xz(reset_transform.origin, definition.route_points, definition.closed_loop)
	assert_true(distance <= 0.01, "Manual return transform should land on the route centerline")
	assert_true(absf(reset_transform.origin.y - (definition.route_points[3].y + 1.0)) < 0.2, "Manual return transform should preserve the road height plus kart clearance")

func _distance_to_route_xz(point: Vector3, route_points: Array[Vector3], closed_loop: bool) -> float:
	var best := INF
	var segment_count := route_points.size() if closed_loop else route_points.size() - 1
	for i in range(segment_count):
		best = minf(best, _distance_to_segment_xz(point, route_points[i], route_points[(i + 1) % route_points.size()]))
	return best

func _distance_to_segment_xz(point: Vector3, a3: Vector3, b3: Vector3) -> float:
	var point_2d := Vector2(point.x, point.z)
	var a := Vector2(a3.x, a3.z)
	var b := Vector2(b3.x, b3.z)
	var ab := b - a
	var length_squared := ab.length_squared()
	if length_squared <= 0.0001:
		return point_2d.distance_to(a)
	var t := clampf((point_2d - a).dot(ab) / length_squared, 0.0, 1.0)
	return point_2d.distance_to(a + ab * t)

func _node_scale_x(root: Node, path: NodePath) -> float:
	var node := root.get_node_or_null(path) as Node3D
	if node == null:
		return 0.0
	return node.transform.basis.get_scale().x

func _node_position(root: Node, path: NodePath) -> Vector3:
	var node := root.get_node_or_null(path) as Node3D
	if node == null:
		return Vector3.ZERO
	return node.transform.origin

func _runtime_spawn_matches_socket(root: Node, path: NodePath, socket: Vector4) -> bool:
	var node := root.get_node_or_null(path) as Node3D
	if node == null:
		return false
	var expected := Vector3(socket.x, socket.y, socket.z)
	var expected_yaw := socket.w
	var actual_yaw := rad_to_deg(node.transform.basis.get_euler().y)
	return node.transform.origin.distance_to(expected) <= 0.01 and absf(angle_difference(deg_to_rad(actual_yaw), deg_to_rad(expected_yaw))) <= 0.01

func _authored_kitchen_position(path: NodePath) -> Vector3:
	var packed := load("res://assets/gameplay/tracks/kitchen/kitchen_editable_room.tscn")
	if not (packed is PackedScene):
		return Vector3.ZERO
	var instance := (packed as PackedScene).instantiate() as Node3D
	var position := _node_position(instance, path)
	instance.queue_free()
	return position

func _node_visible(root: Node, path: NodePath) -> bool:
	var node := root.get_node_or_null(path) as Node3D
	if node == null:
		return false
	return node.visible

func _node_has_script(root: Node, path: NodePath) -> bool:
	var node := root.get_node_or_null(path)
	return node != null and node.get_script() != null

func _box_size_x(root: Node, path: NodePath) -> float:
	var mesh_instance := root.get_node_or_null(path) as MeshInstance3D
	if mesh_instance == null or not (mesh_instance.mesh is BoxMesh):
		return 0.0
	return (mesh_instance.mesh as BoxMesh).size.x

func _box_size_y(root: Node, path: NodePath) -> float:
	var mesh_instance := root.get_node_or_null(path) as MeshInstance3D
	if mesh_instance == null or not (mesh_instance.mesh is BoxMesh):
		return 0.0
	return (mesh_instance.mesh as BoxMesh).size.y

func _child_count(node: Node) -> int:
	if node == null:
		return 0
	return node.get_child_count()

func _first_material_texture_path(node: Node) -> String:
	if node == null:
		return ""
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.material_override is StandardMaterial3D:
			var material := mesh_instance.material_override as StandardMaterial3D
			if material.albedo_texture != null:
				return material.albedo_texture.resource_path
	for child in node.get_children():
		var found := _first_material_texture_path(child)
		if not found.is_empty():
			return found
	return ""

func _first_material_uv_scale(node: Node) -> float:
	if node == null:
		return 0.0
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.material_override is StandardMaterial3D:
			return (mesh_instance.material_override as StandardMaterial3D).uv1_scale.x
	for child in node.get_children():
		var found := _first_material_uv_scale(child)
		if found > 0.0:
			return found
	return 0.0

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

func _node_count_by_type(node: Node, type_name: String) -> int:
	if node == null:
		return 0
	var count := 1 if node.is_class(type_name) else 0
	for child in node.get_children():
		count += _node_count_by_type(child, type_name)
	return count

func _mesh_material_alpha(root: Node, path: NodePath) -> float:
	var mesh := root.get_node_or_null(path) as MeshInstance3D
	if mesh == null:
		return 1.0
	var material := mesh.material_override
	if material is StandardMaterial3D:
		return (material as StandardMaterial3D).albedo_color.a
	return 1.0

func _mesh_shader_path(root: Node, path: NodePath) -> String:
	var mesh := root.get_node_or_null(path) as MeshInstance3D
	if mesh == null:
		return ""
	if mesh.material_override is ShaderMaterial:
		var material := mesh.material_override as ShaderMaterial
		if material.shader != null:
			return material.shader.resource_path
	return ""

func _shader_texture_path(root: Node, path: NodePath, parameter_name: String) -> String:
	var mesh := root.get_node_or_null(path) as MeshInstance3D
	if mesh == null or not (mesh.material_override is ShaderMaterial):
		return ""
	var value = (mesh.material_override as ShaderMaterial).get_shader_parameter(parameter_name)
	if value is Texture2D:
		return (value as Texture2D).resource_path
	return ""

func _multimesh_instance_count(root: Node, path: NodePath) -> int:
	var instance := root.get_node_or_null(path) as MultiMeshInstance3D
	if instance == null or instance.multimesh == null:
		return 0
	return instance.multimesh.instance_count

func _multimesh_shader_path(root: Node, path: NodePath) -> String:
	var instance := root.get_node_or_null(path) as MultiMeshInstance3D
	if instance == null or instance.multimesh == null or instance.multimesh.mesh == null:
		return ""
	var material := instance.multimesh.mesh.surface_get_material(0)
	if material is ShaderMaterial:
		var shader_material := material as ShaderMaterial
		if shader_material.shader != null:
			return shader_material.shader.resource_path
	return ""

func _first_multimesh_instance_y(root: Node, path: NodePath) -> float:
	var instance := root.get_node_or_null(path) as MultiMeshInstance3D
	if instance == null or instance.multimesh == null or instance.multimesh.instance_count == 0:
		return -INF
	var sample_positions := instance.get_meta("scatter_sample_positions", []) as Array
	if not sample_positions.is_empty() and sample_positions[0] is Vector3:
		return (sample_positions[0] as Vector3).y
	return instance.multimesh.get_instance_transform(0).origin.y

func _has_editable_grass_zone_bounds(holder: Node) -> bool:
	if holder == null:
		return false
	for child in holder.get_children():
		if child is Area3D and child.get_node_or_null("CollisionShape3D") is CollisionShape3D and child.get_node_or_null("BoundsPreview") is MeshInstance3D:
			return true
	return false

func _multimesh_instances_inside_grass_zones(root: Node, path: NodePath, zones: Array[Dictionary], sample_count: int) -> bool:
	var instance := root.get_node_or_null(path) as MultiMeshInstance3D
	if instance == null or instance.multimesh == null:
		return false
	var sample_positions := instance.get_meta("scatter_sample_positions", []) as Array
	if not sample_positions.is_empty():
		var metadata_count := mini(sample_count, sample_positions.size())
		for i in range(metadata_count):
			var position_value: Variant = sample_positions[i]
			if not (position_value is Vector3):
				return false
			if not _point_inside_any_grass_zone(position_value as Vector3, zones):
				return false
		return true
	var count := mini(sample_count, instance.multimesh.instance_count)
	for i in range(count):
		var position := instance.multimesh.get_instance_transform(i).origin
		if not _point_inside_any_grass_zone(position, zones):
			return false
	return true

func _point_inside_any_grass_zone(point: Vector3, zones: Array[Dictionary]) -> bool:
	for zone in zones:
		if not bool(zone.get("enabled", true)):
			continue
		var center := _point_from_value(zone.get("position", Vector3.ZERO))
		var size := _vector2_from_value(zone.get("size", Vector2.ZERO))
		var yaw := deg_to_rad(float(zone.get("yaw_degrees", 0.0)))
		var local := Basis(Vector3.UP, -yaw) * (point - center)
		if absf(local.x) <= size.x * 0.5 + 0.01 and absf(local.z) <= size.y * 0.5 + 0.01:
			return true
	return false

func _point_from_value(value: Variant) -> Vector3:
	if value is Vector3:
		return value
	if value is Array and value.size() >= 3:
		return Vector3(float(value[0]), float(value[1]), float(value[2]))
	return Vector3.ZERO

func _vector2_from_value(value: Variant) -> Vector2:
	if value is Vector2:
		return value
	if value is Array and value.size() >= 2:
		return Vector2(float(value[0]), float(value[1]))
	return Vector2.ZERO
