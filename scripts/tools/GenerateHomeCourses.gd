@tool
extends SceneTree

const TrackDefinition = preload("res://scripts/track/TrackDefinition.gd")
const TrackAuthoringPreview = preload("res://scripts/track/TrackAuthoringPreview.gd")
const StagePropAuthoring = preload("res://scripts/track/StagePropAuthoring.gd")
const SurfaceSegmentAuthoring = preload("res://scripts/track/SurfaceSegmentAuthoring.gd")
const AudioZoneAuthoring = preload("res://scripts/track/AudioZoneAuthoring.gd")
const TrackMetadataExporter = preload("res://scripts/track/TrackMetadataExporter.gd")
const TrackRuntimeScene = preload("res://scripts/track/TrackRuntimeScene.gd")

const FLOOR_SIZE := Vector2(292.0, 190.0)
const FLOOR_Y := -32.0
const AUTHORING_GROUND_Y := -11.0
const ROAD_Y := 3.35
const ROAD_WIDTH := 12.0
const TRACK_BODY_COLOR := Color(0.09, 0.075, 0.065, 1.0)
const RAIL_TEXTURE := "res://assets/gameplay/materials/metal/toy_metal_albedo.png"
const ROAD_TEXTURE := "res://assets/gameplay/materials/plastic/glossy_plastic_albedo.png"

const COURSES := [
	{
		"id": "sandbox",
		"display_name": "Sandbox / Rexx",
		"folder": "sandbox",
		"root": "SandboxEditableRoom",
		"runtime": "SandboxTrack",
		"version": "sandbox_v1_2026_05_01",
		"ground_texture": "res://assets/gameplay/materials/sand/sandbox_sand_albedo.png",
		"ground_color": Color(0.86, 0.72, 0.45, 1.0),
		"route": "heavy_loop",
		"surface": "sand",
		"music": "res://assets/source/audio/canva/tracks/sandbox/sandbox_grit_slide_canva_01.wav",
		"sfx_a": "res://assets/source/audio/canva/tracks/sandbox/sandbox_grit_slide_canva_01.wav",
		"sfx_b": "res://assets/source/audio/canva/tracks/sandbox/sandbox_bucket_bonk_canva_01.mp3",
		"props": [
			["SandBucketWall", "box", Vector3(-122, -8, -48), Vector3(10, 26, 44), Color(0.86, 0.18, 0.14), "plastic", "sandbox_landmark"],
			["ToyDumpTruck", "box", Vector3(96, -6, 52), Vector3(30, 16, 18), Color(0.95, 0.72, 0.18), "plastic", "sandbox_landmark"],
			["SandCastleTrench", "box", Vector3(-8, -10, 10), Vector3(72, 7, 14), Color(0.66, 0.48, 0.27), "sand", "sandbox_hazard"],
			["ShovelRamp", "box", Vector3(32, 1.8, -68), Vector3(46, 1.2, 14), Color(0.15, 0.48, 0.9), "metal", "ramp"],
			["SandboxSideBoard", "box", Vector3(0, -6, 94), Vector3(292, 22, 4), Color(0.48, 0.26, 0.12), "wood", "room_envelope"],
		],
	},
	{
		"id": "garden",
		"display_name": "Garden / Moko",
		"folder": "garden",
		"root": "GardenEditableRoom",
		"runtime": "GardenTrack",
		"version": "garden_v1_2026_05_01",
		"ground_texture": "res://assets/gameplay/materials/garden/garden_dirt_mud_albedo.png",
		"ground_color": Color(0.32, 0.43, 0.24, 1.0),
		"route": "garden_loop",
		"surface": "dirt",
		"music": "res://assets/source/audio/suno/tracks/garden/garden_loop_suno_01.mp3",
		"sfx_a": "res://assets/source/audio/canva/tracks/garden/garden_mud_splat_canva_01.wav",
		"sfx_b": "res://assets/source/audio/canva/tracks/garden/garden_stone_hit_canva_01.mp3",
		"props": [
			["WateringCan", "box", Vector3(104, -5, -48), Vector3(28, 18, 24), Color(0.36, 0.58, 0.72), "metal", "garden_landmark"],
			["LeafTunnel", "box", Vector3(-70, 5, 54), Vector3(50, 2, 20), Color(0.16, 0.52, 0.18), "leaf", "garden_landmark"],
			["FlowerPotA", "box", Vector3(-118, -3, -10), Vector3(18, 22, 18), Color(0.62, 0.28, 0.16), "ceramic", "garden_landmark"],
			["StoneShortcut", "box", Vector3(4, -7, 8), Vector3(58, 5, 18), Color(0.42, 0.46, 0.42), "stone", "shortcut_landmark"],
			["MudPatch", "box", Vector3(66, -10, 28), Vector3(42, 4, 28), Color(0.24, 0.16, 0.08), "mud", "slow_zone"],
		],
	},
	{
		"id": "bedroom",
		"display_name": "Bedroom / Tuggs",
		"folder": "bedroom",
		"root": "BedroomEditableRoom",
		"runtime": "BedroomTrack",
		"version": "bedroom_v1_2026_05_01",
		"ground_texture": "res://assets/gameplay/materials/fabric/plush_fabric_albedo.png",
		"ground_color": Color(0.58, 0.52, 0.64, 1.0),
		"route": "bedroom_loop",
		"surface": "fabric",
		"music": "res://assets/source/audio/suno/tracks/bedroom/bedroom_loop_suno_01.mp3",
		"sfx_a": "res://assets/source/audio/canva/tracks/bedroom/bedroom_blanket_slide_canva_01.mp3",
		"sfx_b": "res://assets/source/audio/canva/tracks/bedroom/bedroom_plush_thump_canva_01.wav",
		"props": [
			["BedBase", "box", Vector3(-92, -5, 50), Vector3(72, 26, 60), Color(0.38, 0.28, 0.24), "wood", "bedroom_landmark"],
			["BlanketHill", "box", Vector3(-30, 0.5, -62), Vector3(76, 3, 24), Color(0.3, 0.44, 0.86), "fabric", "ramp"],
			["PillowFort", "box", Vector3(84, -4, -32), Vector3(36, 18, 30), Color(0.92, 0.86, 0.76), "plush", "bedroom_landmark"],
			["SlipperWall", "box", Vector3(116, -6, 48), Vector3(16, 14, 48), Color(0.42, 0.24, 0.16), "rubber", "bedroom_landmark"],
			["ToyBlockStack", "box", Vector3(16, -5, 30), Vector3(22, 18, 22), Color(0.9, 0.24, 0.18), "plastic", "bedroom_landmark"],
		],
	},
	{
		"id": "attic",
		"display_name": "Attic / Popper",
		"folder": "attic",
		"root": "AtticEditableRoom",
		"runtime": "AtticTrack",
		"version": "attic_v1_2026_05_01",
		"ground_texture": "res://assets/gameplay/materials/attic/attic_cardboard_wood_albedo.png",
		"ground_color": Color(0.48, 0.38, 0.28, 1.0),
		"route": "attic_loop",
		"surface": "wood",
		"music": "res://assets/source/audio/suno/tracks/attic/attic_loop_suno_01.mp3",
		"sfx_a": "res://assets/source/audio/canva/tracks/attic/attic_creak_canva_01.mp3",
		"sfx_b": "res://assets/source/audio/canva/tracks/attic/attic_prank_squeak_canva_01.wav",
		"props": [
			["BoxMazeA", "box", Vector3(-104, -4, -28), Vector3(28, 20, 28), Color(0.58, 0.42, 0.24), "cardboard", "attic_landmark"],
			["BoxMazeB", "box", Vector3(86, -4, 34), Vector3(34, 24, 26), Color(0.5, 0.36, 0.2), "cardboard", "attic_landmark"],
			["OldTrunk", "box", Vector3(10, -5, 62), Vector3(46, 18, 24), Color(0.24, 0.14, 0.08), "wood", "attic_landmark"],
			["RafterBranch", "box", Vector3(0, 10, -8), Vector3(112, 2.2, 12), Color(0.34, 0.2, 0.1), "wood", "ramp"],
			["PullCord", "box", Vector3(64, 15, -48), Vector3(1, 30, 1), Color(0.9, 0.82, 0.62), "fabric", "attic_landmark"],
		],
	},
	{
		"id": "playroom",
		"display_name": "Playroom / Slammo",
		"folder": "playroom",
		"root": "PlayroomEditableRoom",
		"runtime": "PlayroomTrack",
		"version": "playroom_v1_2026_05_01",
		"ground_texture": "res://assets/gameplay/materials/plastic/glossy_plastic_albedo.png",
		"ground_color": Color(0.24, 0.5, 0.86, 1.0),
		"route": "figure_eight",
		"surface": "foam",
		"music": "res://assets/source/audio/suno/tracks/playroom/playroom_loop_suno_01.mp3",
		"sfx_a": "res://assets/source/audio/canva/tracks/playroom/playroom_block_crash_canva_01.mp3",
		"sfx_b": "res://assets/source/audio/canva/tracks/playroom/playroom_spring_ramp_canva_01.mp3",
		"props": [
			["BlockTowerRed", "box", Vector3(-58, -4, 0), Vector3(22, 22, 22), Color(0.9, 0.14, 0.14), "plastic", "playroom_landmark"],
			["BlockTowerBlue", "box", Vector3(58, -4, 0), Vector3(22, 22, 22), Color(0.14, 0.34, 0.9), "plastic", "playroom_landmark"],
			["PlasticSlide", "box", Vector3(92, 1, -54), Vector3(54, 2, 20), Color(0.98, 0.82, 0.18), "plastic", "ramp"],
			["FoamMatSeam", "box", Vector3(0, -10, 0), Vector3(292, 1, 2), Color(0.08, 0.12, 0.16), "foam", "floor_detail"],
			["ToyShelf", "box", Vector3(-132, 4, 38), Vector3(16, 34, 70), Color(0.62, 0.38, 0.18), "wood", "playroom_landmark"],
		],
	},
	{
		"id": "glam_closet",
		"display_name": "Glam Closet / Velva",
		"folder": "glam_closet",
		"root": "GlamClosetEditableRoom",
		"runtime": "GlamClosetTrack",
		"version": "glam_closet_v1_2026_05_01",
		"ground_texture": "res://assets/gameplay/materials/glam/glam_mirror_glitter_albedo.png",
		"ground_color": Color(0.8, 0.42, 0.68, 1.0),
		"route": "runway_loop",
		"surface": "gloss",
		"music": "res://assets/source/audio/suno/tracks/glam_closet/glam_closet_loop_suno_01.mp3",
		"sfx_a": "res://assets/source/audio/canva/tracks/glam_closet/glam_perfume_puff_canva_01.mp3",
		"sfx_b": "res://assets/source/audio/canva/tracks/glam_closet/glam_sparkle_whoosh_canva_01.mp3",
		"props": [
			["VanityMirror", "box", Vector3(-118, 6, 18), Vector3(12, 34, 48), Color(0.86, 0.88, 0.94), "glass", "glam_landmark"],
			["PerfumeBottle", "box", Vector3(98, -3, -46), Vector3(18, 22, 18), Color(0.72, 0.9, 0.96), "glass", "glam_landmark"],
			["ShoeRack", "box", Vector3(112, -5, 46), Vector3(26, 18, 54), Color(0.18, 0.12, 0.1), "wood", "glam_landmark"],
			["ScarfBridge", "box", Vector3(4, 3.8, 12), Vector3(86, 1.0, 16), Color(0.9, 0.24, 0.62), "fabric", "shortcut_landmark"],
			["MakeupPalette", "box", Vector3(-24, -8, -64), Vector3(54, 6, 24), Color(0.24, 0.12, 0.22), "plastic", "glam_landmark"],
		],
	},
	{
		"id": "outdoor_playground",
		"display_name": "Outdoor Playground / Dash",
		"folder": "outdoor_playground",
		"root": "OutdoorPlaygroundEditableRoom",
		"runtime": "OutdoorPlaygroundTrack",
		"version": "outdoor_playground_v1_2026_05_01",
		"ground_texture": "",
		"ground_color": Color(0.28, 0.32, 0.34, 1.0),
		"route": "fast_loop",
		"surface": "asphalt",
		"music": "res://assets/source/audio/suno/tracks/playground/playground_loop_suno_01.mp3",
		"sfx_a": "res://assets/source/audio/canva/tracks/playground/playground_slide_drop_canva_01.mp3",
		"sfx_b": "res://assets/source/audio/canva/tracks/playground/playground_chain_swing_canva_01.mp3",
		"props": [
			["SlideSpiral", "box", Vector3(94, 2, -44), Vector3(54, 2, 18), Color(0.95, 0.22, 0.16), "plastic", "ramp"],
			["SwingSetTopBar", "box", Vector3(-82, 12, 48), Vector3(58, 2, 4), Color(0.1, 0.2, 0.26), "metal", "playground_landmark"],
			["SwingChains", "box", Vector3(-82, 4, 48), Vector3(2, 18, 2), Color(0.72, 0.72, 0.7), "metal", "playground_landmark"],
			["MonkeyBars", "box", Vector3(8, 10, 66), Vector3(72, 3, 18), Color(0.1, 0.44, 0.8), "metal", "playground_landmark"],
			["MulchSlowZone", "box", Vector3(-16, -10, -30), Vector3(76, 4, 26), Color(0.36, 0.16, 0.06), "mulch", "slow_zone"],
		],
	},
]

func _initialize() -> void:
	var manifest := _load_manifest()
	for course in COURSES:
		_generate_course(course)
		manifest["tracks"][course["id"]] = {
			"id": course["id"],
			"display_name": course["display_name"],
			"version": course["version"],
			"scene_path": _runtime_scene_path(course),
			"definition_path": _definition_path(course),
			"metadata_path": _metadata_path(course),
		}
	_save_manifest(manifest)
	print("Generated %d human-editable home-course stages." % COURSES.size())
	quit()

func _generate_course(course: Dictionary) -> void:
	var dir := "res://assets/gameplay/tracks/%s" % course["folder"]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var definition := _make_definition(course)
	ResourceSaver.save(definition, _definition_path(course))
	_save_editable_scene(course)
	_save_runtime_scene(course)
	TrackMetadataExporter.save_json(definition, _metadata_path(course))

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
	definition.ground_size = FLOOR_SIZE
	definition.ground_color = course["ground_color"]
	definition.ground_texture_path = course["ground_texture"]
	definition.road_texture_path = ROAD_TEXTURE
	definition.rail_texture_path = RAIL_TEXTURE
	definition.rail_texture_uv_scale = 0.5
	definition.track_body_color = TRACK_BODY_COLOR
	definition.route_points = _route_points(str(course["route"]))
	definition.checkpoint_indices = _checkpoint_indices()
	definition.lap_gate_checkpoint_index = 0
	definition.spawn_points = _spawn_points(definition.route_points)
	definition.item_sockets = _socket_points(definition.route_points, [2, 5, 8, 11, 14, 17, 20, 23, 26, 29])
	definition.hazard_sockets = _socket_points(definition.route_points, [4, 9, 13, 18, 22, 27, 30])
	definition.alternate_routes = _alternate_routes(course)
	definition.stage_props = _stage_props(course)
	definition.surface_segments = _surface_segments(course)
	definition.audio_ids = {
		"music": course["music"],
		"%s_primary" % course["id"]: course["sfx_a"],
		"%s_secondary" % course["id"]: course["sfx_b"],
	}
	definition.audio_zones = _audio_zones(course)
	return definition

func _save_editable_scene(course: Dictionary) -> void:
	var root := Node3D.new()
	root.name = course["root"]
	root.set_script(TrackAuthoringPreview)
	root.set("preview_enabled", false)
	root.set("ground_size", FLOOR_SIZE)
	root.set("ground_y", AUTHORING_GROUND_Y)
	root.set("road_y_offset", 0.0)
	root.set("track_definition_path", _definition_path(course))
	root.set("metadata_output_path", _metadata_path(course))
	root.set("show_dressing_preview", false)
	root.set("metadata_authoring_enabled", true)
	root.set("road_preview_alpha", 0.84)
	root.set("wall_preview_alpha", 0.27)
	_add_floor(root, course)
	_add_room_shell(root, course)
	_add_route_markers(root, _route_points(str(course["route"])))
	_add_checkpoint_markers(root, _route_points(str(course["route"])), _checkpoint_indices())
	_add_socket_markers(root, "SpawnPoints", "Start", _spawn_points(_route_points(str(course["route"]))))
	_add_socket_markers(root, "ItemSockets", "ItemSocket", _socket_points(_route_points(str(course["route"])), [2, 5, 8, 11, 14, 17, 20, 23, 26, 29]))
	_add_socket_markers(root, "HazardSockets", "HazardSocket", _socket_points(_route_points(str(course["route"])), [4, 9, 13, 18, 22, 27, 30]))
	_add_alternate_route_nodes(root, course)
	_add_holder(root, "ShortcutGates")
	_add_stage_prop_nodes(root, course)
	_add_surface_segment_nodes(root, course)
	_add_audio_zone_nodes(root, course)
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

func _add_floor(root: Node3D, course: Dictionary) -> void:
	var floor := Node3D.new()
	floor.name = "floor"
	floor.position.y = FLOOR_Y
	root.add_child(floor)
	var mesh := MeshInstance3D.new()
	mesh.name = "MeshInstance3D"
	var plane := PlaneMesh.new()
	plane.size = FLOOR_SIZE
	mesh.mesh = plane
	mesh.position = Vector3(0.0, 21.648705, 0.0)
	var material := StandardMaterial3D.new()
	material.albedo_color = course["ground_color"]
	material.roughness = 0.78
	material.uv1_scale = Vector3(24, 24, 1)
	var texture_path := str(course["ground_texture"])
	if not texture_path.strip_edges().is_empty():
		var texture := load(texture_path)
		if texture is Texture2D:
			material.albedo_texture = texture
	mesh.material_override = material
	floor.add_child(mesh)

func _add_room_shell(root: Node3D, course: Dictionary) -> void:
	var shell := Node3D.new()
	shell.name = "RoomShell"
	root.add_child(shell)
	var wall_color := _stage_wall_color(course["id"])
	_add_box(shell, "BackWall", Vector3(0, 21, 98), Vector3(292, 58, 2), wall_color)
	_add_box(shell, "LeftWall", Vector3(-146, 21, 0), Vector3(2, 58, 190), wall_color.darkened(0.08))
	_add_box(shell, "RightWall", Vector3(146, 21, 0), Vector3(2, 58, 190), wall_color.darkened(0.08))
	_add_box(shell, "FrontWallLeft", Vector3(-96, 21, -98), Vector3(96, 58, 2), wall_color.darkened(0.03))
	_add_box(shell, "FrontWallRight", Vector3(96, 21, -98), Vector3(96, 58, 2), wall_color.darkened(0.03))
	_add_box(shell, "DoorHeader", Vector3(0, 45, -98), Vector3(96, 10, 2), wall_color.darkened(0.03))
	_add_box(shell, "Ceiling", Vector3(0, 55, 0), Vector3(292, 1, 190), wall_color.lightened(0.08))

func _add_route_markers(root: Node3D, route: Array[Vector3]) -> void:
	var holder := _add_holder(root, "RoutePoints")
	for i in range(route.size()):
		var marker := Marker3D.new()
		marker.name = "RoutePoint%02d" % i
		marker.position = route[i]
		holder.add_child(marker)

func _add_checkpoint_markers(root: Node3D, route: Array[Vector3], indices: Array) -> void:
	var holder := _add_holder(root, "Checkpoints")
	for i in range(indices.size()):
		var marker := Marker3D.new()
		marker.name = "Checkpoint%02d%s" % [i, "_LapGate" if i == 0 else ""]
		marker.position = route[int(indices[i])]
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
		var points: Array = route.get("points", [])
		for i in range(points.size()):
			var marker := Marker3D.new()
			marker.name = "Point%02d" % i
			marker.position = points[i]
			route_node.add_child(marker)

func _add_stage_prop_nodes(root: Node3D, course: Dictionary) -> void:
	var holder := _add_holder(root, "Dressing")
	for data in _stage_props(course):
		var prop := StagePropAuthoring.new()
		prop.name = str(data["id"])
		prop.prop_id = str(data["id"])
		prop.prop_kind = str(data["kind"])
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
	for data in _surface_segments(course):
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
	for data in _audio_zones(course):
		var zone := AudioZoneAuthoring.new()
		zone.name = str(data["id"])
		zone.zone_id = str(data["id"])
		zone.audio_id = str(data["audio_id"])
		zone.zone_kind = str(data["zone_kind"])
		zone.radius = float(data["radius"])
		zone.volume_db = float(data["volume_db"])
		zone.position = _vec3(data["position"])
		holder.add_child(zone)

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
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.72
	mesh.material_override = material
	parent.add_child(mesh)

func _route_points(kind: String) -> Array[Vector3]:
	var base: Array[Vector3] = [
		Vector3(-108, ROAD_Y, -72),
		Vector3(-94, ROAD_Y, -78),
		Vector3(-78, ROAD_Y, -82),
		Vector3(-60, ROAD_Y, -84),
		Vector3(-40, ROAD_Y, -83),
		Vector3(-20, ROAD_Y, -80),
		Vector3(0, ROAD_Y, -76),
		Vector3(24, ROAD_Y, -76),
		Vector3(48, ROAD_Y, -78),
		Vector3(72, ROAD_Y, -76),
		Vector3(96, ROAD_Y, -68),
		Vector3(116, ROAD_Y, -52),
		Vector3(128, ROAD_Y, -30),
		Vector3(132, ROAD_Y, -6),
		Vector3(130, ROAD_Y, 18),
		Vector3(122, ROAD_Y, 42),
		Vector3(106, ROAD_Y, 60),
		Vector3(84, ROAD_Y, 72),
		Vector3(60, ROAD_Y, 78),
		Vector3(34, ROAD_Y, 82),
		Vector3(8, ROAD_Y, 82),
		Vector3(-18, ROAD_Y, 80),
		Vector3(-44, ROAD_Y, 76),
		Vector3(-70, ROAD_Y, 68),
		Vector3(-94, ROAD_Y, 54),
		Vector3(-114, ROAD_Y, 34),
		Vector3(-126, ROAD_Y, 10),
		Vector3(-130, ROAD_Y, -16),
		Vector3(-126, ROAD_Y, -40),
		Vector3(-116, ROAD_Y, -60),
		Vector3(-104, ROAD_Y, -70),
		Vector3(-112, ROAD_Y, -68)
	]
	if kind == "heavy_loop":
		base[7].y += 1.8
		base[8].y += 3.2
		base[9].y += 1.8
		base[21].y -= 0.8
		base[22].y -= 1.0
	elif kind == "garden_loop":
		base[16].x -= 6
		base[17].z += 3
		base[24].y += 1.2
	elif kind == "bedroom_loop":
		base[2].y += 1.5
		base[3].y += 2.6
		base[4].y += 1.5
		base[25].z += 5
	elif kind == "attic_loop":
		base[10].y += 2.0
		base[11].y += 3.2
		base[12].y += 2.0
		base[22].y += 1.2
	elif kind == "figure_eight":
		base[6].z -= 5
		base[14].x -= 5
		base[22].z += 5
		base[29].x += 5
	elif kind == "runway_loop":
		for i in range(base.size()):
			base[i].z *= 0.86
		base[18].y += 1.4
		base[19].y += 1.4
	elif kind == "fast_loop":
		for i in range(base.size()):
			base[i].x *= 1.03
		base[10].y += 1.8
		base[11].y += 2.8
	return base

func _checkpoint_indices() -> Array[int]:
	return [0, 6, 12, 18, 24, 28]

func _spawn_points(route: Array[Vector3]) -> Array[Vector4]:
	var spawns: Array[Vector4] = []
	var origin := route[0]
	var forward := (route[1] - route[0]).normalized()
	var right := Vector3(forward.z, 0, -forward.x).normalized()
	var yaw := rad_to_deg(atan2(forward.x, forward.z))
	for row in range(4):
		for col in range(2):
			var pos := origin + forward * float(row) * 5.0 + right * ((-2.0 if col == 0 else 2.0)) + Vector3.UP * 0.8
			spawns.append(Vector4(pos.x, pos.y, pos.z, yaw))
	return spawns

func _socket_points(route: Array[Vector3], indices: Array) -> Array[Vector4]:
	var sockets: Array[Vector4] = []
	for index in indices:
		var point := route[int(index) % route.size()] + Vector3.UP * 0.7
		sockets.append(Vector4(point.x, point.y, point.z, 0.0))
	return sockets

func _alternate_routes(course: Dictionary) -> Array[Dictionary]:
	var id := str(course["id"])
	var points: Array[Vector3] = []
	if id in ["garden", "bedroom", "attic", "playroom", "glam_closet", "outdoor_playground"]:
		points = [Vector3(0, ROAD_Y + 0.2, -76), Vector3(18, ROAD_Y + 1.0, -32), Vector3(36, ROAD_Y + 1.0, 20), Vector3(60, ROAD_Y + 0.4, 78)]
	elif id == "sandbox":
		points = [Vector3(0, ROAD_Y + 0.4, -76), Vector3(22, ROAD_Y + 3.0, -32), Vector3(30, ROAD_Y - 1.0, 18), Vector3(60, ROAD_Y + 0.2, 78)]
	if points.is_empty():
		return []
	return [{
		"id": "%s_branch" % id,
		"points": points,
		"entry_checkpoint_index": 1,
		"exit_checkpoint_index": 3,
		"road_width": ROAD_WIDTH,
		"enabled": true,
	}]

func _stage_props(course: Dictionary) -> Array[Dictionary]:
	var props: Array[Dictionary] = []
	for prop in course["props"]:
		props.append({
			"id": prop[0],
			"kind": prop[1],
			"asset_path": "",
			"box_size": prop[3],
			"box_color": prop[4],
			"position": prop[2],
			"yaw_degrees": 0.0,
			"scale": Vector3.ONE,
			"collision_mode": "visual",
			"audio_material_id": prop[5],
			"gameplay_tag": prop[6],
		})
	return props

func _surface_segments(course: Dictionary) -> Array[Dictionary]:
	return [
		{"id": "%s_start_surface" % course["id"], "start_route_index": 0, "end_route_index": 10, "surface_audio_id": "%s_primary" % course["id"], "surface_material_id": course["surface"], "position": Vector3(-30, ROAD_Y + 0.2, -70)},
		{"id": "%s_feature_surface" % course["id"], "start_route_index": 11, "end_route_index": 20, "surface_audio_id": "%s_secondary" % course["id"], "surface_material_id": "%s_feature" % course["surface"], "position": Vector3(70, ROAD_Y + 0.2, 50)},
		{"id": "%s_return_surface" % course["id"], "start_route_index": 21, "end_route_index": 31, "surface_audio_id": "%s_primary" % course["id"], "surface_material_id": course["surface"], "position": Vector3(-80, ROAD_Y + 0.2, 10)},
	]

func _audio_zones(course: Dictionary) -> Array[Dictionary]:
	return [
		{"id": "%s_music_zone" % course["id"], "audio_id": "music", "audio_path": "", "zone_kind": "ambient", "radius": 120.0, "volume_db": -14.0, "position": Vector3.ZERO},
		{"id": "%s_feature_zone" % course["id"], "audio_id": "%s_secondary" % course["id"], "audio_path": "", "zone_kind": "oneshot", "radius": 28.0, "volume_db": -6.0, "position": Vector3(60, ROAD_Y + 1.0, 36)},
	]

func _stage_wall_color(stage_id: String) -> Color:
	match stage_id:
		"sandbox":
			return Color(0.72, 0.58, 0.36)
		"garden":
			return Color(0.38, 0.52, 0.34)
		"bedroom":
			return Color(0.54, 0.48, 0.6)
		"attic":
			return Color(0.42, 0.32, 0.24)
		"playroom":
			return Color(0.42, 0.58, 0.82)
		"glam_closet":
			return Color(0.72, 0.48, 0.66)
		"outdoor_playground":
			return Color(0.58, 0.72, 0.86)
	return Color(0.6, 0.58, 0.52)

func _vec3(value: Variant) -> Vector3:
	if value is Vector3:
		return value
	if value is Array and value.size() >= 3:
		return Vector3(float(value[0]), float(value[1]), float(value[2]))
	return Vector3.ZERO

func _color(value: Variant) -> Color:
	if value is Color:
		return value
	if value is Array and value.size() >= 4:
		return Color(float(value[0]), float(value[1]), float(value[2]), float(value[3]))
	return Color.WHITE

func _definition_path(course: Dictionary) -> String:
	return "res://assets/gameplay/tracks/%s/%s_track_definition.tres" % [course["folder"], course["folder"]]

func _editable_scene_path(course: Dictionary) -> String:
	return "res://assets/gameplay/tracks/%s/%s_editable_room.tscn" % [course["folder"], course["folder"]]

func _runtime_scene_path(course: Dictionary) -> String:
	return "res://assets/gameplay/tracks/%s/%s_track.tscn" % [course["folder"], course["folder"]]

func _metadata_path(course: Dictionary) -> String:
	return "res://assets/gameplay/tracks/%s/%s_track_metadata.json" % [course["folder"], course["folder"]]

func _load_manifest() -> Dictionary:
	var path := "res://assets/gameplay/tracks/track_packages.json"
	var file := FileAccess.open(path, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary:
		if not parsed.has("tracks"):
			parsed["tracks"] = {}
		return parsed
	return {"default_track_id": "kitchen", "tracks": {}}

func _save_manifest(manifest: Dictionary) -> void:
	var file := FileAccess.open("res://assets/gameplay/tracks/track_packages.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest, "\t"))
	file.store_string("\n")
	file.close()

func _set_owner_recursive(node: Node, scene_owner: Node) -> void:
	for child in node.get_children():
		child.owner = scene_owner
		_set_owner_recursive(child, scene_owner)
