@tool
extends SceneTree

const TrackDefinition = preload("res://scripts/track/TrackDefinition.gd")
const TrackAuthoringPreview = preload("res://scripts/track/TrackAuthoringPreview.gd")
const StagePropAuthoring = preload("res://scripts/track/StagePropAuthoring.gd")
const SurfaceSegmentAuthoring = preload("res://scripts/track/SurfaceSegmentAuthoring.gd")
const AudioZoneAuthoring = preload("res://scripts/track/AudioZoneAuthoring.gd")
const GrassZoneAuthoring = preload("res://scripts/track/GrassZoneAuthoring.gd")
const TrackMetadataExporter = preload("res://scripts/track/TrackMetadataExporter.gd")
const TrackRuntimeScene = preload("res://scripts/track/TrackRuntimeScene.gd")

const TRACK_IDS := [
	"kitchen",
	"bedroom",
	"sandbox",
	"garden",
	"glam_closet",
	"outdoor_playground",
	"playroom",
	"attic",
]

const BACKYARD_IDS := ["sandbox", "garden", "outdoor_playground"]
const ARCHIVE_README_PATH := "res://assets/gameplay/tracks/_archive/2026-05-02_pre_toybox_dominion/README.md"
const BACKYARD_BASE_PATH := "res://assets/gameplay/tracks/shared/backyard/backyard_base.tscn"
const ROAD_Y := 3.35
const AUTHORING_GROUND_Y := -11.0
const FLOOR_Y := -32.0
const ROAD_WIDTH := 12.0
const INDOOR_FLOOR_SIZE := Vector2(292.0, 190.0)
const BACKYARD_FLOOR_SIZE := Vector2(840.0, 620.0)
const TRACK_BODY_COLOR := Color(0.09, 0.075, 0.065, 1.0)
const ROAD_TEXTURE := "res://assets/gameplay/materials/plastic/glossy_plastic_albedo.png"
const RAIL_TEXTURE := "res://assets/gameplay/materials/metal/toy_metal_albedo.png"
const PLAYGROUND_GRASS_SHADER := "res://assets/gameplay/materials/grass/playground_grass.gdshader"

const COURSES := {
	"kitchen": {
		"display_name": "Kitchen / Sir Clink",
		"root": "KitchenEditableRoom",
		"runtime": "KitchenTrack",
		"version": "kitchen_toybox_v1_2026_05_02",
		"sky": "noon_clear",
		"surface": "tile",
		"ground_texture": "",
		"ground_color": Color(0.74, 0.69, 0.58, 1.0),
		"music": "res://assets/source/audio/suno/tracks/kitchen/kitchen_loop_suno_01.mp3",
		"sfx_a": "res://assets/source/audio/canva/tracks/kitchen/kitchen_sink_splash_canva_01.mp3",
		"sfx_b": "res://assets/source/audio/canva/tracks/kitchen/kitchen_utensil_clink_canva_01.wav",
		"route": [
			Vector3(-94, ROAD_Y, -66), Vector3(-70, ROAD_Y, -78), Vector3(-32, ROAD_Y, -80), Vector3(18, ROAD_Y, -74),
			Vector3(60, ROAD_Y + 1.0, -54), Vector3(92, ROAD_Y + 1.8, -20), Vector3(104, ROAD_Y + 1.0, 20), Vector3(80, ROAD_Y, 56),
			Vector3(28, ROAD_Y, 78), Vector3(-24, ROAD_Y, 80), Vector3(-72, ROAD_Y, 58), Vector3(-106, ROAD_Y, 18), Vector3(-112, ROAD_Y, -28)
		],
		"props": [
			["CourtStartGate", Vector3(-94, 1.5, -66), Vector3(38, 22, 4), Color(0.72, 0.15, 0.12), "wood", "kitchen_landmark"],
			["SinkGauntlet", Vector3(76, 0.8, 50), Vector3(58, 10, 20), Color(0.62, 0.68, 0.7), "metal", "sink_splash"],
			["CuttingBoardBridge", Vector3(58, 5.2, -50), Vector3(54, 1.3, 17), Color(0.74, 0.52, 0.28), "wood", "shortcut_landmark"],
			["UtensilRail", Vector3(-20, 5.8, 78), Vector3(78, 3, 7), Color(0.78, 0.78, 0.72), "metal", "hazard_line"],
			["CabinetCourt", Vector3(-110, 4, 20), Vector3(14, 28, 72), Color(0.44, 0.24, 0.1), "wood", "kitchen_landmark"],
			["TournamentFinishArch", Vector3(-86, 13, -52), Vector3(36, 22, 5), Color(0.96, 0.76, 0.18), "plastic", "finish_landmark"],
			["SinkWater", Vector3(76, 6.1, 50), Vector3(46, 0.25, 14), Color(0.34, 0.72, 0.95, 0.7), "water", "signature_effect"],
		],
	},
	"bedroom": {
		"display_name": "Bedroom / Tuggs",
		"root": "BedroomEditableRoom",
		"runtime": "BedroomTrack",
		"version": "bedroom_toybox_v1_2026_05_02",
		"sky": "soft_morning",
		"surface": "fabric",
		"ground_texture": "res://assets/gameplay/materials/fabric/plush_fabric_albedo.png",
		"ground_color": Color(0.6, 0.55, 0.68, 1.0),
		"music": "res://assets/source/audio/suno/tracks/bedroom/bedroom_loop_suno_01.mp3",
		"sfx_a": "res://assets/source/audio/canva/tracks/bedroom/bedroom_blanket_slide_canva_01.mp3",
		"sfx_b": "res://assets/source/audio/canva/tracks/bedroom/bedroom_plush_thump_canva_01.wav",
		"route": [
			Vector3(-104, ROAD_Y, -58), Vector3(-76, ROAD_Y + 1.2, -76), Vector3(-34, ROAD_Y + 2.5, -82), Vector3(22, ROAD_Y + 1.4, -72),
			Vector3(78, ROAD_Y, -42), Vector3(112, ROAD_Y, 8), Vector3(92, ROAD_Y, 54), Vector3(34, ROAD_Y, 78),
			Vector3(-28, ROAD_Y, 72), Vector3(-82, ROAD_Y, 44), Vector3(-116, ROAD_Y, 0)
		],
		"props": [
			["BedRamp", Vector3(-54, 1.2, -76), Vector3(78, 3.2, 22), Color(0.3, 0.42, 0.82), "fabric", "ramp"],
			["BlanketTunnel", Vector3(68, 9, -36), Vector3(50, 22, 24), Color(0.28, 0.38, 0.72), "fabric", "soft_occluder"],
			["BedsideLampBeacon", Vector3(-118, 16, -12), Vector3(14, 34, 14), Color(1.0, 0.82, 0.42), "glass", "signature_effect"],
			["ToyTriageCorner", Vector3(92, 1, 54), Vector3(44, 10, 24), Color(0.9, 0.86, 0.76), "plush", "story_landmark"],
			["WaitingLine", Vector3(-68, 0.5, 54), Vector3(72, 7, 10), Color(0.74, 0.88, 0.92), "plastic", "story_landmark"],
			["ToyBlockBarriers", Vector3(10, 1, 76), Vector3(42, 12, 9), Color(0.9, 0.18, 0.16), "plastic", "hazard_line"],
		],
	},
	"sandbox": {
		"display_name": "Sandbox / Rexx",
		"root": "SandboxEditableRoom",
		"runtime": "SandboxTrack",
		"version": "sandbox_toybox_v1_2026_05_02",
		"sky": "hot_afternoon",
		"surface": "sand",
		"ground_texture": "res://assets/gameplay/materials/sand/sandbox_sand_albedo.png",
		"ground_color": Color(0.86, 0.72, 0.45, 1.0),
		"music": "res://assets/source/audio/canva/tracks/sandbox/sandbox_grit_slide_canva_01.wav",
		"sfx_a": "res://assets/source/audio/canva/tracks/sandbox/sandbox_grit_slide_canva_01.wav",
		"sfx_b": "res://assets/source/audio/canva/tracks/sandbox/sandbox_bucket_bonk_canva_01.mp3",
		"yard_offset": Vector3(250, 0, 130),
		"route": [
			Vector3(164, ROAD_Y, 72), Vector3(202, ROAD_Y + 0.6, 42), Vector3(256, ROAD_Y + 2.2, 36), Vector3(320, ROAD_Y + 1.0, 58),
			Vector3(352, ROAD_Y, 112), Vector3(330, ROAD_Y, 170), Vector3(272, ROAD_Y - 0.5, 200), Vector3(204, ROAD_Y, 188),
			Vector3(158, ROAD_Y, 138)
		],
		"props": [
			["SandRidgeThrone", Vector3(260, 7, 120), Vector3(54, 16, 30), Color(0.74, 0.5, 0.22), "sand", "sandbox_landmark"],
			["OverturnedBucketTunnel", Vector3(318, 8, 58), Vector3(36, 20, 24), Color(0.9, 0.18, 0.12), "plastic", "tunnel"],
			["FossilArch", Vector3(210, 10, 188), Vector3(42, 22, 6), Color(0.84, 0.78, 0.62), "bone", "sandbox_landmark"],
			["ShovelRamp", Vector3(202, 5, 42), Vector3(44, 2, 16), Color(0.12, 0.46, 0.9), "metal", "ramp"],
			["TributePile", Vector3(340, 4, 152), Vector3(34, 12, 28), Color(0.72, 0.38, 0.14), "plastic", "story_landmark"],
			["SandBurstZone", Vector3(252, 4, 40), Vector3(42, 3, 18), Color(0.92, 0.72, 0.36, 0.8), "sand", "signature_effect"],
		],
	},
	"garden": {
		"display_name": "Garden / Moko",
		"root": "GardenEditableRoom",
		"runtime": "GardenTrack",
		"version": "garden_toybox_v1_2026_05_02",
		"sky": "fresh_morning",
		"surface": "dirt",
		"ground_texture": "res://assets/gameplay/materials/garden/garden_dirt_mud_albedo.png",
		"ground_color": Color(0.32, 0.43, 0.24, 1.0),
		"music": "res://assets/source/audio/suno/tracks/garden/garden_loop_suno_01.mp3",
		"sfx_a": "res://assets/source/audio/canva/tracks/garden/garden_mud_splat_canva_01.wav",
		"sfx_b": "res://assets/source/audio/canva/tracks/garden/garden_stone_hit_canva_01.mp3",
		"yard_offset": Vector3(-240, 0, 110),
		"route": [
			Vector3(-334, ROAD_Y, 64), Vector3(-288, ROAD_Y + 0.4, 38), Vector3(-230, ROAD_Y + 1.0, 48), Vector3(-176, ROAD_Y, 82),
			Vector3(-150, ROAD_Y, 140), Vector3(-176, ROAD_Y - 0.4, 194), Vector3(-240, ROAD_Y, 214), Vector3(-306, ROAD_Y + 0.8, 184),
			Vector3(-354, ROAD_Y, 126)
		],
		"props": [
			["RootGate", Vector3(-292, 9, 42), Vector3(46, 20, 8), Color(0.38, 0.2, 0.08), "wood", "garden_landmark"],
			["StoneBridge", Vector3(-236, 4, 54), Vector3(58, 4, 18), Color(0.48, 0.5, 0.46), "stone", "shortcut_landmark"],
			["HoseCrossing", Vector3(-158, 3.5, 138), Vector3(48, 3, 10), Color(0.1, 0.48, 0.18), "rubber", "signature_effect"],
			["FlowerCanopy", Vector3(-230, 16, 210), Vector3(70, 24, 20), Color(0.88, 0.36, 0.62), "leaf", "garden_landmark"],
			["SurvivalMarkers", Vector3(-340, 2, 116), Vector3(32, 10, 10), Color(0.76, 0.54, 0.22), "plastic", "story_landmark"],
			["LogHazard", Vector3(-190, 4, 188), Vector3(46, 9, 12), Color(0.32, 0.18, 0.08), "wood", "hazard_line"],
		],
	},
	"glam_closet": {
		"display_name": "Glam Closet / Velva",
		"root": "GlamClosetEditableRoom",
		"runtime": "GlamClosetTrack",
		"version": "glam_closet_toybox_v1_2026_05_02",
		"sky": "night_city_glow",
		"surface": "gloss",
		"ground_texture": "res://assets/gameplay/materials/glam/glam_mirror_glitter_albedo.png",
		"ground_color": Color(0.78, 0.42, 0.68, 1.0),
		"music": "res://assets/source/audio/suno/tracks/glam_closet/glam_closet_loop_suno_01.mp3",
		"sfx_a": "res://assets/source/audio/canva/tracks/glam_closet/glam_perfume_puff_canva_01.mp3",
		"sfx_b": "res://assets/source/audio/canva/tracks/glam_closet/glam_sparkle_whoosh_canva_01.mp3",
		"route": [
			Vector3(-112, ROAD_Y, -58), Vector3(-58, ROAD_Y, -78), Vector3(10, ROAD_Y, -76), Vector3(78, ROAD_Y, -48),
			Vector3(112, ROAD_Y + 1.4, 6), Vector3(82, ROAD_Y + 1.4, 58), Vector3(24, ROAD_Y, 78), Vector3(-40, ROAD_Y, 68),
			Vector3(-100, ROAD_Y, 28)
		],
		"props": [
			["MirrorArch", Vector3(-70, 14, -72), Vector3(48, 28, 5), Color(0.78, 0.88, 0.96), "glass", "glam_landmark"],
			["VanityRunway", Vector3(0, 2, -74), Vector3(96, 2, 16), Color(0.9, 0.42, 0.68), "gloss", "runway"],
			["PerfumeMistZone", Vector3(100, 8, 8), Vector3(34, 20, 24), Color(0.76, 0.88, 1.0, 0.45), "mist", "signature_effect"],
			["JewelryBoxRamp", Vector3(74, 5.5, 58), Vector3(48, 2, 18), Color(0.42, 0.12, 0.32), "velvet", "ramp"],
			["DisplayPedestals", Vector3(-28, 4, 72), Vector3(62, 10, 14), Color(0.98, 0.82, 0.94), "plastic", "glam_landmark"],
			["StatusGate", Vector3(-104, 11, 28), Vector3(28, 22, 5), Color(0.96, 0.78, 0.24), "metal", "shortcut_landmark"],
		],
	},
	"outdoor_playground": {
		"display_name": "Outdoor Playground / Dash",
		"root": "OutdoorPlaygroundEditableRoom",
		"runtime": "OutdoorPlaygroundTrack",
		"version": "outdoor_playground_toybox_v1_2026_05_02",
		"sky": "clear_afternoon",
		"surface": "asphalt",
		"ground_texture": "res://assets/gameplay/materials/playground/outdoor_playground_floor_albedo.png",
		"ground_shader": PLAYGROUND_GRASS_SHADER,
		"ground_color": Color(0.24, 0.34, 0.14, 1.0),
		"music": "res://assets/source/audio/suno/tracks/playground/playground_loop_suno_01.mp3",
		"sfx_a": "res://assets/source/audio/canva/tracks/playground/playground_slide_drop_canva_01.mp3",
		"sfx_b": "res://assets/source/audio/canva/tracks/playground/playground_chain_swing_canva_01.mp3",
		"yard_offset": Vector3(0, 0, -150),
		"route": [
			Vector3(-122, ROAD_Y, -226), Vector3(-72, ROAD_Y, -252), Vector3(-4, ROAD_Y, -248), Vector3(62, ROAD_Y + 2.4, -220),
			Vector3(116, ROAD_Y + 3.4, -172), Vector3(124, ROAD_Y, -104), Vector3(70, ROAD_Y, -58), Vector3(-8, ROAD_Y, -48),
			Vector3(-88, ROAD_Y, -82), Vector3(-134, ROAD_Y, -150)
		],
		"props": [
			["SlideDrop", Vector3(84, 8, -208), Vector3(58, 2.5, 20), Color(0.92, 0.16, 0.12), "plastic", "ramp"],
			["SwingGate", Vector3(-96, 13, -82), Vector3(58, 24, 8), Color(0.1, 0.22, 0.28), "metal", "signature_effect"],
			["ChalkRouteArrows", Vector3(-8, 3, -48), Vector3(72, 0.3, 16), Color(0.9, 0.9, 0.84), "chalk", "route_language"],
			["RailShortcut", Vector3(42, 7, -58), Vector3(78, 3, 6), Color(0.1, 0.44, 0.8), "metal", "shortcut_landmark"],
			["HalfPipeBank", Vector3(118, 5, -136), Vector3(52, 9, 26), Color(0.16, 0.42, 0.74), "plastic", "stunt_landmark"],
			["BrokenBorderGate", Vector3(-124, 10, -226), Vector3(32, 20, 5), Color(0.58, 0.36, 0.18), "wood", "story_landmark"],
		],
	},
	"playroom": {
		"display_name": "Playroom / Slammo",
		"root": "PlayroomEditableRoom",
		"runtime": "PlayroomTrack",
		"version": "playroom_toybox_v1_2026_05_02",
		"sky": "party_evening",
		"surface": "foam",
		"ground_texture": "res://assets/gameplay/materials/plastic/glossy_plastic_albedo.png",
		"ground_color": Color(0.22, 0.5, 0.86, 1.0),
		"music": "res://assets/source/audio/suno/tracks/playroom/playroom_loop_suno_01.mp3",
		"sfx_a": "res://assets/source/audio/canva/tracks/playroom/playroom_block_crash_canva_01.mp3",
		"sfx_b": "res://assets/source/audio/canva/tracks/playroom/playroom_spring_ramp_canva_01.mp3",
		"route": [
			Vector3(-108, ROAD_Y, -48), Vector3(-62, ROAD_Y, -78), Vector3(-6, ROAD_Y + 1.0, -52), Vector3(52, ROAD_Y, -78),
			Vector3(110, ROAD_Y, -38), Vector3(78, ROAD_Y, 12), Vector3(112, ROAD_Y + 1.8, 58), Vector3(42, ROAD_Y, 78),
			Vector3(-12, ROAD_Y, 46), Vector3(-68, ROAD_Y, 78), Vector3(-116, ROAD_Y, 28)
		],
		"props": [
			["ToyRingPlatform", Vector3(-6, 4, -12), Vector3(52, 6, 52), Color(0.92, 0.18, 0.16), "foam", "arena_landmark"],
			["ChampionRamp", Vector3(94, 5.2, 58), Vector3(48, 2, 18), Color(0.98, 0.76, 0.16), "plastic", "signature_effect"],
			["BlockGrandstands", Vector3(-88, 6, 72), Vector3(58, 18, 16), Color(0.16, 0.34, 0.92), "plastic", "crowd_landmark"],
			["MarbleMachine", Vector3(88, 15, -36), Vector3(38, 30, 20), Color(0.72, 0.86, 0.94), "plastic", "hazard_machine"],
			["TrophyFinishStretch", Vector3(-108, 8, -48), Vector3(34, 16, 8), Color(0.96, 0.72, 0.18), "metal", "finish_landmark"],
			["ArenaLoop", Vector3(0, 2, 0), Vector3(120, 2, 80), Color(0.12, 0.16, 0.22), "foam", "arena_landmark"],
		],
	},
	"attic": {
		"display_name": "Attic / Popper",
		"root": "AtticEditableRoom",
		"runtime": "AtticTrack",
		"version": "attic_toybox_v1_2026_05_02",
		"sky": "stormy_moonlight_night",
		"surface": "wood",
		"ground_texture": "res://assets/gameplay/materials/attic/attic_cardboard_wood_albedo.png",
		"ground_color": Color(0.48, 0.38, 0.28, 1.0),
		"music": "res://assets/source/audio/suno/tracks/attic/attic_loop_suno_01.mp3",
		"sfx_a": "res://assets/source/audio/canva/tracks/attic/attic_creak_canva_01.mp3",
		"sfx_b": "res://assets/source/audio/canva/tracks/attic/attic_prank_squeak_canva_01.wav",
		"route": [
			Vector3(-108, ROAD_Y, -60), Vector3(-72, ROAD_Y, -80), Vector3(-20, ROAD_Y + 1.8, -74), Vector3(42, ROAD_Y + 2.8, -46),
			Vector3(106, ROAD_Y, -12), Vector3(100, ROAD_Y, 46), Vector3(50, ROAD_Y, 78), Vector3(-14, ROAD_Y, 72),
			Vector3(-72, ROAD_Y, 48), Vector3(-116, ROAD_Y, 4)
		],
		"props": [
			["PrankTrunkMaze", Vector3(-70, 5, -74), Vector3(56, 16, 22), Color(0.36, 0.2, 0.08), "wood", "attic_landmark"],
			["StringLiftShortcut", Vector3(42, 14, -46), Vector3(4, 28, 4), Color(0.86, 0.78, 0.58), "fabric", "signature_effect"],
			["FalseFinishGate", Vector3(104, 12, -12), Vector3(34, 22, 5), Color(0.88, 0.2, 0.16), "plastic", "prank_landmark"],
			["SheetTunnel", Vector3(82, 9, 46), Vector3(48, 20, 24), Color(0.84, 0.82, 0.76), "fabric", "soft_occluder"],
			["BoxStackSwitchback", Vector3(-16, 7, 72), Vector3(60, 20, 18), Color(0.54, 0.38, 0.2), "cardboard", "attic_landmark"],
			["MarbleTrap", Vector3(-106, 5, 4), Vector3(28, 10, 18), Color(0.56, 0.66, 0.82), "glass", "hazard_machine"],
		],
	},
}

func _initialize() -> void:
	_save_archive_readme()
	_save_backyard_base_scene()
	var manifest := {"default_track_id": "kitchen", "tracks": {}}
	for track_id in TRACK_IDS:
		var course := (COURSES[track_id] as Dictionary).duplicate(true)
		course["id"] = track_id
		course["folder"] = track_id
		_generate_course(course)
		manifest["tracks"][track_id] = {
			"id": track_id,
			"display_name": course["display_name"],
			"version": course["version"],
			"scene_path": _runtime_scene_path(course),
			"definition_path": _definition_path(course),
			"metadata_path": _metadata_path(course),
		}
	_save_manifest(manifest)
	print("Generated %d Toybox Dominion character stages." % TRACK_IDS.size())
	quit()

func _generate_course(course: Dictionary) -> void:
	var dir := "res://assets/gameplay/tracks/%s" % course["folder"]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var definition := _make_definition(course)
	ResourceSaver.save(definition, _definition_path(course))
	_save_editable_scene(course)
	_save_runtime_scene(course)
	var metadata_error := TrackMetadataExporter.save_json(definition, _metadata_path(course))
	if metadata_error != OK:
		push_error("Metadata export failed for %s: %s" % [course["id"], metadata_error])

func _make_definition(course: Dictionary) -> TrackDefinition:
	var definition := TrackDefinition.new()
	definition.id = course["id"]
	definition.display_name = course["display_name"]
	definition.version = course["version"]
	definition.laps = 3
	definition.road_width = ROAD_WIDTH
	definition.out_of_bounds_y = AUTHORING_GROUND_Y
	definition.reset_mode = "instant_pop"
	definition.floor_visual_y = FLOOR_Y
	definition.runtime_scene_path = _runtime_scene_path(course)
	definition.dressing_scene_path = _editable_scene_path(course)
	definition.ground_size = _floor_size(course)
	definition.ground_color = course["ground_color"]
	definition.ground_texture_path = str(course.get("ground_texture", ""))
	definition.ground_shader_path = _ground_shader_path(course)
	definition.road_texture_path = ROAD_TEXTURE
	definition.rail_texture_path = RAIL_TEXTURE
	definition.rail_texture_uv_scale = 0.5
	definition.track_body_color = TRACK_BODY_COLOR
	_apply_sky_preset(definition, str(course["sky"]))
	definition.route_points = _route_points(course)
	definition.checkpoint_indices = _checkpoint_indices(definition.route_points)
	definition.lap_gate_checkpoint_index = 0
	definition.spawn_points = _spawn_points(definition.route_points)
	definition.item_sockets = _socket_points(definition.route_points, [1, 2, 4, 5, 7, 8, 9, 10])
	definition.hazard_sockets = _socket_points(definition.route_points, [2, 4, 6, 8, 10, 11])
	definition.alternate_routes = _alternate_routes(course)
	definition.shortcut_gates = _shortcut_gates(course)
	definition.stage_props = _stage_props(course)
	definition.surface_segments = _surface_segments(course, definition.route_points)
	definition.audio_ids = _audio_ids(course)
	definition.audio_zones = _audio_zones(course, definition.route_points)
	definition.grass_zones = _grass_zones(course)
	return definition

func _save_editable_scene(course: Dictionary) -> void:
	var root := Node3D.new()
	root.name = course["root"]
	root.set_script(TrackAuthoringPreview)
	root.set("preview_enabled", false)
	root.set("ground_size", _floor_size(course))
	root.set("ground_y", AUTHORING_GROUND_Y)
	root.set("road_y_offset", 0.0)
	root.set("track_definition_path", _definition_path(course))
	root.set("metadata_output_path", _metadata_path(course))
	root.set("show_dressing_preview", false)
	root.set("metadata_authoring_enabled", true)
	root.set("road_preview_alpha", 0.84)
	root.set("wall_preview_alpha", 0.27)
	_add_floor(root, course)
	if _is_backyard_course(course):
		_add_backyard_base_instance(root)
	else:
		_add_room_shell(root, course)
	_add_route_markers(root, _route_points(course))
	_add_checkpoint_markers(root, _route_points(course), _checkpoint_indices(_route_points(course)))
	_add_socket_markers(root, "SpawnPoints", "Start", _spawn_points(_route_points(course)))
	_add_socket_markers(root, "ItemSockets", "ItemSocket", _socket_points(_route_points(course), [1, 2, 4, 5, 7, 8, 9, 10]))
	_add_socket_markers(root, "HazardSockets", "HazardSocket", _socket_points(_route_points(course), [2, 4, 6, 8, 10, 11]))
	_add_alternate_route_nodes(root, course)
	_add_shortcut_gate_nodes(root, course)
	_add_stage_prop_nodes(root, course)
	_add_surface_segment_nodes(root, course)
	_add_audio_zone_nodes(root, course)
	_add_grass_zone_nodes(root, course)
	_add_signature_effect_nodes(root, course)
	_set_owner_recursive(root, root)
	var packed := PackedScene.new()
	packed.pack(root)
	ResourceSaver.save(packed, _editable_scene_path(course))
	root.free()

func _save_runtime_scene(course: Dictionary) -> void:
	var root := Node3D.new()
	root.name = course["runtime"]
	root.set_script(TrackRuntimeScene)
	root.set("definition", load(_definition_path(course)))
	var packed := PackedScene.new()
	packed.pack(root)
	ResourceSaver.save(packed, _runtime_scene_path(course))
	root.free()

func _save_backyard_base_scene() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/gameplay/tracks/shared/backyard"))
	var root := Node3D.new()
	root.name = "BackyardBase"
	_add_backyard_plane(root)
	_add_backyard_fence(root)
	_add_backyard_territories(root)
	_set_owner_recursive(root, root)
	var packed := PackedScene.new()
	packed.pack(root)
	ResourceSaver.save(packed, BACKYARD_BASE_PATH)
	root.free()

func _add_backyard_plane(root: Node3D) -> void:
	var floor := Node3D.new()
	floor.name = "BackyardFloor"
	floor.position.y = FLOOR_Y
	root.add_child(floor)
	var mesh := MeshInstance3D.new()
	mesh.name = "MeshInstance3D"
	var plane := PlaneMesh.new()
	plane.size = BACKYARD_FLOOR_SIZE
	mesh.mesh = plane
	mesh.position = Vector3(0.0, 21.648705, 0.0)
	mesh.material_override = _material(Color(0.28, 0.42, 0.18, 1.0), 0.82)
	floor.add_child(mesh)

func _add_backyard_fence(root: Node3D) -> void:
	var fence := Node3D.new()
	fence.name = "YardFence"
	root.add_child(fence)
	_add_box(fence, "BackFence", Vector3(0, 17, 315), Vector3(840, 34, 5), Color(0.54, 0.36, 0.2))
	_add_box(fence, "FrontFence", Vector3(0, 17, -315), Vector3(840, 34, 5), Color(0.5, 0.32, 0.18))
	_add_box(fence, "LeftFence", Vector3(-425, 17, 0), Vector3(5, 34, 620), Color(0.48, 0.3, 0.16))
	_add_box(fence, "RightFence", Vector3(425, 17, 0), Vector3(5, 34, 620), Color(0.48, 0.3, 0.16))

func _add_backyard_territories(root: Node3D) -> void:
	var territories := Node3D.new()
	territories.name = "VisibleCourseTerritories"
	root.add_child(territories)
	_add_box(territories, "SandboxTerritory", Vector3(250, -7, 130), Vector3(190, 5, 150), Color(0.82, 0.64, 0.36))
	_add_box(territories, "GardenTerritory", Vector3(-240, -7, 130), Vector3(210, 5, 170), Color(0.22, 0.48, 0.2))
	_add_box(territories, "PlaygroundTerritory", Vector3(0, -7, -150), Vector3(240, 5, 180), Color(0.32, 0.36, 0.3))
	_add_box(territories, "DistantSlideSilhouette", Vector3(70, 9, -205), Vector3(54, 18, 14), Color(0.86, 0.12, 0.1))
	_add_box(territories, "DistantFlowerBeds", Vector3(-245, 4, 210), Vector3(116, 10, 16), Color(0.86, 0.34, 0.58))
	_add_box(territories, "DistantSandboxWall", Vector3(250, 2, 50), Vector3(170, 14, 8), Color(0.58, 0.34, 0.12))

func _add_archive_readme_line(lines: Array[String], text: String) -> void:
	lines.append(text)

func _save_archive_readme() -> void:
	var archive_dir := "res://assets/gameplay/tracks/_archive/2026-05-02_pre_toybox_dominion"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(archive_dir))
	var lines: Array[String] = []
	_add_archive_readme_line(lines, "# Pre-Toybox Dominion Stage Archive")
	_add_archive_readme_line(lines, "")
	_add_archive_readme_line(lines, "This folder contains the playable stage package files that were active before the Toybox Dominion character-stage rebuild on 2026-05-02.")
	_add_archive_readme_line(lines, "")
	_add_archive_readme_line(lines, "These files are preserved for reference only. They are intentionally not listed in `assets/gameplay/tracks/track_packages.json`, so level select uses the new active Toybox Dominion packages at the original track IDs and paths.")
	_add_archive_readme_line(lines, "")
	_add_archive_readme_line(lines, "Archived per-stage files include the old editable room scene, runtime scene, track definition, and exported metadata. Concept docs, build specs, and key art remain in the active stage folders.")
	var file := FileAccess.open(ARCHIVE_README_PATH, FileAccess.WRITE)
	file.store_string("\n".join(lines))
	file.store_string("\n")
	file.close()

func _add_floor(root: Node3D, course: Dictionary) -> void:
	var floor := Node3D.new()
	floor.name = "floor"
	floor.position.y = FLOOR_Y
	root.add_child(floor)
	var mesh := MeshInstance3D.new()
	mesh.name = "MeshInstance3D"
	var plane := PlaneMesh.new()
	plane.size = _floor_size(course)
	mesh.mesh = plane
	mesh.position = Vector3(0.0, 21.648705, 0.0)
	mesh.material_override = _floor_material(course)
	floor.add_child(mesh)

func _floor_material(course: Dictionary) -> Material:
	var shader_path := _ground_shader_path(course)
	if not shader_path.is_empty():
		var shader := load(shader_path)
		if shader is Shader:
			var shader_material := ShaderMaterial.new()
			shader_material.shader = shader
			shader_material.set_shader_parameter("base_color", course["ground_color"])
			var texture_path := str(course.get("ground_texture", ""))
			if ResourceLoader.exists(texture_path):
				shader_material.set_shader_parameter("floor_texture", load(texture_path))
			return shader_material
	var material := _material(course["ground_color"], 0.78)
	var texture_path := str(course.get("ground_texture", ""))
	if ResourceLoader.exists(texture_path):
		material.albedo_texture = load(texture_path)
		material.uv1_scale = Vector3(24, 24, 1)
	return material

func _add_room_shell(root: Node3D, course: Dictionary) -> void:
	var shell := Node3D.new()
	shell.name = "RoomShell"
	root.add_child(shell)
	var color := _stage_wall_color(str(course["id"]))
	_add_box(shell, "BackWall", Vector3(0, 21, 98), Vector3(292, 58, 2), color)
	_add_box(shell, "LeftWall", Vector3(-146, 21, 0), Vector3(2, 58, 190), color.darkened(0.08))
	_add_box(shell, "RightWall", Vector3(146, 21, 0), Vector3(2, 58, 190), color.darkened(0.08))
	_add_box(shell, "FrontWallLeft", Vector3(-96, 21, -98), Vector3(96, 58, 2), color.darkened(0.03))
	_add_box(shell, "FrontWallRight", Vector3(96, 21, -98), Vector3(96, 58, 2), color.darkened(0.03))
	_add_box(shell, "DoorHeader", Vector3(0, 45, -98), Vector3(96, 10, 2), color.darkened(0.03))

func _add_backyard_base_instance(root: Node3D) -> void:
	var packed := load(BACKYARD_BASE_PATH)
	if not (packed is PackedScene):
		return
	var instance := (packed as PackedScene).instantiate()
	instance.name = "SharedBackyardBase"
	root.add_child(instance)

func _add_route_markers(root: Node3D, route: Array[Vector3]) -> void:
	var holder := _add_holder(root, "RoutePoints")
	for i in range(route.size()):
		var marker := Marker3D.new()
		marker.name = "RoutePoint%02d" % i
		marker.position = route[i]
		holder.add_child(marker)

func _add_checkpoint_markers(root: Node3D, route: Array[Vector3], indices: Array[int]) -> void:
	var holder := _add_holder(root, "Checkpoints")
	for i in range(indices.size()):
		var marker := Marker3D.new()
		marker.name = "Checkpoint%02d%s" % [i, "_LapGate" if i == 0 else ""]
		marker.position = route[indices[i]]
		holder.add_child(marker)

func _add_socket_markers(root: Node3D, holder_name: String, prefix: String, sockets: Array[Vector4]) -> void:
	var holder := _add_holder(root, holder_name)
	for i in range(sockets.size()):
		var socket := sockets[i]
		var marker := Marker3D.new()
		marker.name = "%s%02d" % [prefix, i + 1]
		marker.position = Vector3(socket.x, socket.y, socket.z)
		marker.rotation_degrees.y = socket.w
		holder.add_child(marker)

func _add_alternate_route_nodes(root: Node3D, course: Dictionary) -> void:
	var holder := _add_holder(root, "AlternateRoutes")
	for route in _alternate_routes(course):
		var route_node := Node3D.new()
		route_node.name = str(route.get("id", "AlternateRoute"))
		holder.add_child(route_node)
		var points: Array[Vector3] = []
		for point in route.get("points", []):
			if point is Vector3:
				points.append(point)
		for i in range(points.size()):
			var marker := Marker3D.new()
			marker.name = "Point%02d" % i
			marker.position = points[i]
			route_node.add_child(marker)

func _add_shortcut_gate_nodes(root: Node3D, course: Dictionary) -> void:
	var holder := _add_holder(root, "ShortcutGates")
	for gate in _shortcut_gates(course):
		var entry := Marker3D.new()
		entry.name = "%s_Entry" % gate["id"]
		entry.position = gate["entry"]
		holder.add_child(entry)
		var exit := Marker3D.new()
		exit.name = "%s_Exit" % gate["id"]
		exit.position = gate["exit"]
		holder.add_child(exit)

func _add_stage_prop_nodes(root: Node3D, course: Dictionary) -> void:
	var holder := _add_holder(root, "Dressing")
	for data in _stage_props(course):
		var prop := StagePropAuthoring.new()
		prop.name = str(data["id"])
		prop.prop_id = str(data["id"])
		prop.prop_kind = str(data["kind"])
		prop.asset_path = str(data["asset_path"])
		prop.box_size = _vec3(data["box_size"])
		prop.box_color = _color(data["box_color"])
		prop.collision_mode = str(data["collision_mode"])
		prop.audio_material_id = str(data["audio_material_id"])
		prop.gameplay_tag = str(data["gameplay_tag"])
		prop.position = _vec3(data["position"])
		prop.rotation_degrees.y = float(data["yaw_degrees"])
		holder.add_child(prop)

func _add_surface_segment_nodes(root: Node3D, course: Dictionary) -> void:
	var holder := _add_holder(root, "SurfaceSegments")
	for data in _surface_segments(course, _route_points(course)):
		var segment := SurfaceSegmentAuthoring.new()
		segment.name = str(data["id"])
		segment.segment_id = str(data["id"])
		segment.start_route_index = int(data["start_route_index"])
		segment.end_route_index = int(data["end_route_index"])
		segment.surface_audio_id = str(data["surface_audio_id"])
		segment.surface_material_id = str(data["surface_material_id"])
		segment.position = _vec3(data["position"])
		holder.add_child(segment)

func _add_audio_zone_nodes(root: Node3D, course: Dictionary) -> void:
	var holder := _add_holder(root, "AudioZones")
	for data in _audio_zones(course, _route_points(course)):
		var zone := AudioZoneAuthoring.new()
		zone.name = str(data["id"])
		zone.zone_id = str(data["id"])
		zone.audio_id = str(data["audio_id"])
		zone.zone_kind = str(data["zone_kind"])
		zone.radius = float(data["radius"])
		zone.volume_db = float(data["volume_db"])
		zone.position = _vec3(data["position"])
		holder.add_child(zone)

func _add_grass_zone_nodes(root: Node3D, course: Dictionary) -> void:
	var holder := _add_holder(root, "GrassZones")
	for data in _grass_zones(course):
		var zone := GrassZoneAuthoring.new()
		zone.name = str(data["id"]).capitalize().replace(" ", "")
		zone.zone_id = str(data["id"])
		zone.size = _vec2(data["size"])
		zone.density = float(data["density"])
		zone.enabled = bool(data["enabled"])
		zone.position = _vec3(data["position"])
		zone.rotation_degrees.y = float(data["yaw_degrees"])
		var shape_node := CollisionShape3D.new()
		shape_node.name = "CollisionShape3D"
		var shape := BoxShape3D.new()
		shape.size = Vector3(zone.size.x, 1.0, zone.size.y)
		shape_node.shape = shape
		zone.add_child(shape_node)
		var preview := MeshInstance3D.new()
		preview.name = "BoundsPreview"
		var mesh := BoxMesh.new()
		mesh.size = shape.size
		preview.mesh = mesh
		preview.material_override = _transparent_material(Color(0.2, 0.95, 0.25, 0.22))
		zone.add_child(preview)
		holder.add_child(zone)

func _add_signature_effect_nodes(root: Node3D, course: Dictionary) -> void:
	var holder := _add_holder(root, "SignatureEffects")
	var id := str(course["id"])
	var route := _route_points(course)
	var effect := MeshInstance3D.new()
	effect.name = _signature_effect_name(id)
	var mesh := BoxMesh.new()
	mesh.size = Vector3(20, 4, 14)
	effect.mesh = mesh
	effect.position = route[maxi(1, route.size() / 2)]
	effect.material_override = _transparent_material(_signature_effect_color(id))
	holder.add_child(effect)

func _route_points(course: Dictionary) -> Array[Vector3]:
	var points: Array[Vector3] = []
	for point in course["route"]:
		if point is Vector3:
			points.append(point)
	return points

func _checkpoint_indices(route: Array[Vector3]) -> Array[int]:
	var count := route.size()
	var indices: Array[int] = []
	for i in range(6):
		indices.append(clampi(floori(float(i) * float(count) / 6.0), 0, count - 1))
	return indices

func _spawn_points(route: Array[Vector3]) -> Array[Vector4]:
	var spawns: Array[Vector4] = []
	var origin := route[0]
	var forward := route[1] - route[0]
	forward.y = 0.0
	forward = forward.normalized()
	var right := Vector3(forward.z, 0, -forward.x).normalized()
	var yaw := rad_to_deg(atan2(forward.x, forward.z))
	for row in range(4):
		for col in range(2):
			var pos := origin + forward * float(row) * 5.0 + right * (-2.0 if col == 0 else 2.0) + Vector3.UP * 0.8
			spawns.append(Vector4(pos.x, pos.y, pos.z, yaw))
	return spawns

func _socket_points(route: Array[Vector3], indices: Array) -> Array[Vector4]:
	var sockets: Array[Vector4] = []
	for index in indices:
		var point := route[int(index) % route.size()] + Vector3.UP * 0.7
		sockets.append(Vector4(point.x, point.y, point.z, 0.0))
	return sockets

func _alternate_routes(course: Dictionary) -> Array[Dictionary]:
	var route := _route_points(course)
	var mid := route.size() / 2
	var id := str(course["id"])
	return [{
		"id": "%s_alt_route" % id,
		"points": [
			route[2] + Vector3(0, 0.4, 0),
			(route[2] + route[mid]) * 0.5 + Vector3(0, 1.2, 0),
			route[mid] + Vector3(0, 0.4, 0),
		],
		"entry_checkpoint_index": 1,
		"exit_checkpoint_index": 3,
		"road_width": ROAD_WIDTH * 0.8,
		"enabled": true,
	}]

func _shortcut_gates(course: Dictionary) -> Array[Dictionary]:
	var route := _route_points(course)
	return [{
		"id": "%s_shortcut" % course["id"],
		"entry": route[2],
		"exit": route[route.size() / 2],
		"kind": "shortcut",
		"width": ROAD_WIDTH * 0.75,
		"surface_enabled": true,
	}]

func _stage_props(course: Dictionary) -> Array[Dictionary]:
	var props: Array[Dictionary] = []
	for prop in course["props"]:
		props.append({
			"id": prop[0],
			"kind": "box",
			"asset_path": "",
			"box_size": prop[2],
			"box_color": prop[3],
			"position": prop[1],
			"yaw_degrees": 0.0,
			"scale": Vector3.ONE,
			"collision_mode": "visual",
			"audio_material_id": prop[4],
			"gameplay_tag": prop[5],
		})
	return props

func _surface_segments(course: Dictionary, route: Array[Vector3]) -> Array[Dictionary]:
	var id := str(course["id"])
	var last := route.size() - 1
	return [
		{"id": "%s_start_surface" % id, "start_route_index": 0, "end_route_index": maxi(1, last / 3), "surface_audio_id": "%s_primary" % id, "surface_material_id": course["surface"], "position": route[1]},
		{"id": "%s_feature_surface" % id, "start_route_index": maxi(2, last / 3), "end_route_index": maxi(3, (last * 2) / 3), "surface_audio_id": "%s_secondary" % id, "surface_material_id": "%s_feature" % course["surface"], "position": route[route.size() / 2]},
		{"id": "%s_return_surface" % id, "start_route_index": maxi(4, (last * 2) / 3), "end_route_index": last, "surface_audio_id": "%s_primary" % id, "surface_material_id": course["surface"], "position": route[last - 1]},
	]

func _audio_ids(course: Dictionary) -> Dictionary:
	var id := str(course["id"])
	return {
		"music": course["music"],
		"%s_primary" % id: course["sfx_a"],
		"%s_secondary" % id: course["sfx_b"],
	}

func _audio_zones(course: Dictionary, route: Array[Vector3]) -> Array[Dictionary]:
	var id := str(course["id"])
	var effect_id := _signature_effect_audio_zone(id)
	return [
		{"id": "%s_music_zone" % id, "audio_id": "music", "audio_path": "", "zone_kind": "ambient", "radius": 140.0 if _is_backyard_course(course) else 96.0, "volume_db": -14.0, "position": Vector3.ZERO},
		{"id": effect_id, "audio_id": "%s_secondary" % id, "audio_path": "", "zone_kind": "oneshot", "radius": 28.0, "volume_db": -6.0, "position": route[route.size() / 2]},
		{"id": "%s_route_zone" % id, "audio_id": "%s_primary" % id, "audio_path": "", "zone_kind": "oneshot", "radius": 26.0, "volume_db": -7.0, "position": route[2]},
	]

func _grass_zones(course: Dictionary) -> Array[Dictionary]:
	if not _is_backyard_course(course):
		return []
	return [
		{"id": "%s_active_grass" % course["id"], "position": course.get("yard_offset", Vector3.ZERO), "yaw_degrees": 0.0, "size": Vector2(230, 170), "density": 1.0, "enabled": true},
		{"id": "%s_border_grass" % course["id"], "position": course.get("yard_offset", Vector3.ZERO) + Vector3(0, 0, 80), "yaw_degrees": 18.0, "size": Vector2(160, 80), "density": 0.65, "enabled": true},
	]

func _floor_size(course: Dictionary) -> Vector2:
	return BACKYARD_FLOOR_SIZE if _is_backyard_course(course) else INDOOR_FLOOR_SIZE

func _ground_shader_path(course: Dictionary) -> String:
	var shader_path := str(course.get("ground_shader", "")).strip_edges()
	if shader_path.is_empty() and _is_backyard_course(course):
		return PLAYGROUND_GRASS_SHADER
	return shader_path

func _is_backyard_course(course: Dictionary) -> bool:
	return str(course["id"]) in BACKYARD_IDS

func _signature_effect_name(track_id: String) -> String:
	match track_id:
		"kitchen":
			return "SinkSplashZone"
		"bedroom":
			return "LampBeaconZone"
		"sandbox":
			return "SandBurstZone"
		"garden":
			return "HoseSplashZone"
		"glam_closet":
			return "PerfumeMistZone"
		"outdoor_playground":
			return "SwingGateEffect"
		"playroom":
			return "MarbleMachineEffect"
		"attic":
			return "PrankTriggerZone"
	return "SignatureEffect"

func _signature_effect_audio_zone(track_id: String) -> String:
	return _signature_effect_name(track_id)

func _signature_effect_color(track_id: String) -> Color:
	match track_id:
		"kitchen":
			return Color(0.34, 0.72, 0.95, 0.42)
		"bedroom":
			return Color(1.0, 0.78, 0.34, 0.42)
		"sandbox":
			return Color(0.92, 0.72, 0.36, 0.48)
		"garden":
			return Color(0.24, 0.64, 0.24, 0.42)
		"glam_closet":
			return Color(0.76, 0.88, 1.0, 0.34)
		"outdoor_playground":
			return Color(0.96, 0.22, 0.12, 0.38)
		"playroom":
			return Color(0.96, 0.76, 0.16, 0.42)
		"attic":
			return Color(0.58, 0.5, 0.86, 0.42)
	return Color(1, 1, 1, 0.35)

func _apply_sky_preset(definition: TrackDefinition, preset_id: String) -> void:
	var preset := _sky_preset(preset_id)
	definition.sky_preset_id = preset_id
	definition.sky_time_of_day = float(preset["time_of_day"])
	definition.sky_weather = str(preset["weather"])
	definition.sky_top_color = _color(preset["top_color"])
	definition.sky_horizon_color = _color(preset["horizon_color"])
	definition.sky_cloud_amount = float(preset["cloud_amount"])
	definition.sky_cloud_speed = float(preset["cloud_speed"])
	definition.sky_haze_amount = float(preset["haze_amount"])
	definition.sky_light_energy = float(preset["light_energy"])

func _sky_preset(preset_id: String) -> Dictionary:
	match preset_id:
		"noon_clear":
			return {"time_of_day": 0.5, "weather": "clear", "top_color": Color(0.44, 0.72, 1.0), "horizon_color": Color(0.78, 0.9, 1.0), "cloud_amount": 0.16, "cloud_speed": 0.014, "haze_amount": 0.1, "light_energy": 2.45}
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
		"kitchen":
			return Color(0.66, 0.59, 0.48)
		"bedroom":
			return Color(0.54, 0.48, 0.6)
		"playroom":
			return Color(0.42, 0.58, 0.82)
		"glam_closet":
			return Color(0.72, 0.48, 0.66)
		"attic":
			return Color(0.42, 0.32, 0.24)
	return Color(0.6, 0.58, 0.52)

func _add_holder(root: Node3D, holder_name: String) -> Node3D:
	var holder := Node3D.new()
	holder.name = holder_name
	root.add_child(holder)
	return holder

func _add_box(parent: Node3D, node_name: String, position: Vector3, size: Vector3, color: Color) -> void:
	var mesh := MeshInstance3D.new()
	mesh.name = node_name
	mesh.position = position
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = _material(color, 0.72)
	parent.add_child(mesh)

func _material(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	if color.a < 1.0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material

func _transparent_material(color: Color) -> StandardMaterial3D:
	var material := _material(color, 0.64)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material

func _definition_path(course: Dictionary) -> String:
	return "res://assets/gameplay/tracks/%s/%s_track_definition.tres" % [course["folder"], course["folder"]]

func _editable_scene_path(course: Dictionary) -> String:
	return "res://assets/gameplay/tracks/%s/%s_editable_room.tscn" % [course["folder"], course["folder"]]

func _runtime_scene_path(course: Dictionary) -> String:
	return "res://assets/gameplay/tracks/%s/%s_track.tscn" % [course["folder"], course["folder"]]

func _metadata_path(course: Dictionary) -> String:
	return "res://assets/gameplay/tracks/%s/%s_track_metadata.json" % [course["folder"], course["folder"]]

func _save_manifest(manifest: Dictionary) -> void:
	var file := FileAccess.open("res://assets/gameplay/tracks/track_packages.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest, "\t"))
	file.store_string("\n")
	file.close()

func _set_owner_recursive(node: Node, scene_owner: Node) -> void:
	for child in node.get_children():
		child.owner = scene_owner
		_set_owner_recursive(child, scene_owner)

func _vec3(value: Variant) -> Vector3:
	if value is Vector3:
		return value
	if value is Array and value.size() >= 3:
		return Vector3(float(value[0]), float(value[1]), float(value[2]))
	return Vector3.ZERO

func _vec2(value: Variant) -> Vector2:
	if value is Vector2:
		return value
	if value is Array and value.size() >= 2:
		return Vector2(float(value[0]), float(value[1]))
	return Vector2.ZERO

func _color(value: Variant) -> Color:
	if value is Color:
		return value
	if value is Array and value.size() >= 4:
		return Color(float(value[0]), float(value[1]), float(value[2]), float(value[3]))
	return Color.WHITE
