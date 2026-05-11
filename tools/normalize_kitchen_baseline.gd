@tool
extends SceneTree

const TrackDefinition = preload("res://scripts/track/TrackDefinition.gd")
const TrackMetadataExporter = preload("res://scripts/track/TrackMetadataExporter.gd")
const TrackSceneAuthoringData = preload("res://scripts/track/TrackSceneAuthoringData.gd")

const SCENE_PATH := "res://assets/gameplay/tracks/kitchen/kitchen_editable_room.tscn"
const DEFINITION_PATH := "res://assets/gameplay/tracks/kitchen/kitchen_track_definition.tres"
const METADATA_PATH := "res://assets/gameplay/tracks/kitchen/kitchen_track_metadata.json"

const ROOM_SIZE := Vector2(560.0, 400.0)
const ROOM_BOTTOM_Y := -32.0
const ROOM_TOP_Y := 64.0
const WALL_THICKNESS := 4.0
const OUT_OF_BOUNDS_Y := -36.0

func _initialize() -> void:
	var errors: Array[String] = []
	var packed := load(SCENE_PATH) as PackedScene
	if packed == null:
		_finish(["Could not load Kitchen editable scene: %s" % SCENE_PATH])
		return
	var root := packed.instantiate() as Node3D
	if root == null:
		_finish(["Kitchen editable scene root is not Node3D"])
		return
	var original_scene_text := FileAccess.get_file_as_string(SCENE_PATH)

	_normalize_track_holder(root, errors)
	_standardize_floor(root, errors)
	_standardize_room_shell(root, errors)

	var new_packed := PackedScene.new()
	var pack_error := new_packed.pack(root)
	if pack_error != OK:
		errors.append("Could not pack Kitchen editable scene: %s" % error_string(pack_error))
	else:
		var save_error := ResourceSaver.save(new_packed, SCENE_PATH)
		if save_error != OK:
			errors.append("Could not save Kitchen editable scene: %s" % error_string(save_error))
		else:
			_restore_resource_uids(SCENE_PATH, original_scene_text)
	root.free()

	if errors.is_empty():
		_export_definition(errors)
	_finish(errors)

func _normalize_track_holder(root: Node3D, errors: Array[String]) -> void:
	var track := root.get_node_or_null("Track") as Node3D
	if track == null:
		errors.append("Kitchen scene is missing Track holder")
		return
	var content_nodes: Array[Node3D] = []
	var transforms := {}
	_collect_transform_content(track, content_nodes)
	for node in content_nodes:
		transforms[node] = _root_relative_transform(node, root)
	track.transform = Transform3D.IDENTITY
	_reset_holder_transforms(track)
	for node in content_nodes:
		if is_instance_valid(node):
			node.transform = transforms[node]

func _root_relative_transform(node: Node3D, root: Node) -> Transform3D:
	var xform := node.transform
	var current := node.get_parent()
	while current != null and current != root:
		if current is Node3D:
			xform = (current as Node3D).transform * xform
		current = current.get_parent()
	return xform

func _collect_transform_content(parent: Node, out: Array[Node3D]) -> void:
	for child in parent.get_children():
		if not (child is Node3D):
			continue
		var node := child as Node3D
		if _is_transform_content(node):
			out.append(node)
			continue
		_collect_transform_content(node, out)

func _reset_holder_transforms(parent: Node) -> void:
	for child in parent.get_children():
		if not (child is Node3D):
			continue
		var node := child as Node3D
		if _is_transform_content(node):
			continue
		node.transform = Transform3D.IDENTITY
		_reset_holder_transforms(node)

func _is_transform_content(node: Node3D) -> bool:
	if node is MeshInstance3D or node is Light3D or node is Camera3D or node is CollisionObject3D or node is GridMap:
		return true
	if not node.scene_file_path.strip_edges().is_empty():
		return true
	if node.get_script() != null:
		return true
	return false

func _standardize_floor(root: Node3D, errors: Array[String]) -> void:
	var floor := root.get_node_or_null("Track/floor") as Node3D
	if floor == null:
		errors.append("Kitchen scene is missing Track/floor")
		return
	floor.transform = Transform3D(Basis.IDENTITY, Vector3(0.0, ROOM_BOTTOM_Y, 0.0))
	var mesh := floor.get_node_or_null("MeshInstance3D") as MeshInstance3D
	if mesh == null:
		errors.append("Kitchen scene is missing Track/floor/MeshInstance3D")
		return
	mesh.transform = Transform3D.IDENTITY
	if mesh.mesh is PlaneMesh:
		(mesh.mesh as PlaneMesh).size = ROOM_SIZE
	else:
		var plane := PlaneMesh.new()
		plane.size = ROOM_SIZE
		mesh.mesh = plane

func _standardize_room_shell(root: Node3D, errors: Array[String]) -> void:
	var shell := root.get_node_or_null("Track/RoomShell") as Node3D
	if shell == null:
		errors.append("Kitchen scene is missing Track/RoomShell")
		return
	shell.transform = Transform3D.IDENTITY
	var wall_material := _material_from(shell, "BackWall")
	var trim_material := _material_from(shell, "DoorFrameRight")
	var dark_material := _material_from(shell, "WindowFrame")
	var accent_material := _material_from(shell, "WindowGlass")
	var half_x := ROOM_SIZE.x * 0.5
	var half_z := ROOM_SIZE.y * 0.5
	var wall_height := ROOM_TOP_Y - ROOM_BOTTOM_Y
	var wall_center_y := (ROOM_TOP_Y + ROOM_BOTTOM_Y) * 0.5

	_set_box(shell, "BackWall", Vector3(0.0, wall_center_y, half_z), Vector3(ROOM_SIZE.x, wall_height, WALL_THICKNESS), wall_material, false)
	_set_box(shell, "BackWallLeftOfWindow", Vector3(-259.0, wall_center_y, half_z), Vector3(42.0, wall_height, WALL_THICKNESS), wall_material, true)
	_set_box(shell, "BackWallRightOfWindow", Vector3(69.0, wall_center_y, half_z), Vector3(422.0, wall_height, WALL_THICKNESS), wall_material, true)
	_set_box(shell, "BackWallBelowWindow", Vector3(-190.0, -5.0, half_z), Vector3(96.0, 54.0, WALL_THICKNESS), wall_material, true)
	_set_box(shell, "BackWallAboveWindow", Vector3(-190.0, 57.0, half_z), Vector3(96.0, 14.0, WALL_THICKNESS), wall_material, true)
	_set_box(shell, "LeftWall", Vector3(-half_x, wall_center_y, 0.0), Vector3(WALL_THICKNESS, wall_height, ROOM_SIZE.y), wall_material, true)
	_set_box(shell, "RightWall", Vector3(half_x, wall_center_y, 0.0), Vector3(WALL_THICKNESS, wall_height, ROOM_SIZE.y), wall_material, true)
	_set_box(shell, "RightWall2", Vector3.ZERO, Vector3.ONE, wall_material, false)
	_set_box(shell, "RightWall3", Vector3.ZERO, Vector3.ONE, wall_material, false)
	_set_box(shell, "RightWall4", Vector3.ZERO, Vector3.ONE, wall_material, false)
	_set_box(shell, "FrontWallLeft", Vector3(-167.5, wall_center_y, -half_z), Vector3(225.0, wall_height, WALL_THICKNESS), wall_material, true)
	_set_box(shell, "FrontWallRight", Vector3(167.5, wall_center_y, -half_z), Vector3(225.0, wall_height, WALL_THICKNESS), wall_material, true)
	_set_box(shell, "FrontWallRight2", Vector3.ZERO, Vector3.ONE, wall_material, false)
	_set_box(shell, "DoorHeader", Vector3(0.0, 52.0, -half_z), Vector3(120.0, 24.0, WALL_THICKNESS), wall_material, true)
	_set_box(shell, "DoorFrameLeft", Vector3(-61.0, 4.0, -half_z - 1.0), Vector3(3.0, 72.0, 2.0), trim_material, true)
	_set_box(shell, "DoorFrameRight", Vector3(61.0, 4.0, -half_z - 1.0), Vector3(3.0, 72.0, 2.0), trim_material, true)
	_set_box(shell, "Ceiling", Vector3(0.0, ROOM_TOP_Y, 0.0), Vector3(ROOM_SIZE.x, WALL_THICKNESS, ROOM_SIZE.y), wall_material, true)
	_set_box(shell, "WindowGlass", Vector3(-190.0, 36.0, half_z - 1.5), Vector3(88.0, 28.0, 1.0), accent_material, true)
	_set_box(shell, "WindowFrame", Vector3(-190.0, 51.0, half_z - 2.0), Vector3(96.0, 3.0, 2.0), dark_material, true)
	_set_box(shell, "WindowFrame2", Vector3(-190.0, 21.0, half_z - 2.0), Vector3(96.0, 3.0, 2.0), dark_material, true)
	_set_box(shell, "WindowFrame3", Vector3(-140.0, 36.0, half_z - 2.0), Vector3(3.0, 32.0, 2.0), dark_material, true)
	_set_box(shell, "WindowFrame4", Vector3(-240.0, 36.0, half_z - 2.0), Vector3(3.0, 32.0, 2.0), dark_material, true)

func _set_box(parent: Node3D, node_name: String, position: Vector3, size: Vector3, material: Material, is_visible: bool) -> void:
	var mesh := parent.get_node_or_null(node_name) as MeshInstance3D
	if mesh == null:
		mesh = MeshInstance3D.new()
		mesh.name = node_name
		parent.add_child(mesh)
		mesh.owner = _scene_root(parent)
	var box := mesh.mesh as BoxMesh
	if box == null:
		box = BoxMesh.new()
		mesh.mesh = box
	mesh.transform = Transform3D(Basis.from_scale(size), position)
	mesh.visible = is_visible
	if material != null:
		mesh.material_override = material

func _material_from(parent: Node, node_name: String) -> Material:
	var mesh := parent.get_node_or_null(node_name) as MeshInstance3D
	if mesh != null and mesh.material_override != null:
		return mesh.material_override
	return null

func _scene_root(node: Node) -> Node:
	var current := node
	while current.get_parent() != null:
		current = current.get_parent()
	return current

func _export_definition(errors: Array[String]) -> void:
	var source := load(DEFINITION_PATH) as TrackDefinition
	if source == null:
		errors.append("Could not load Kitchen definition: %s" % DEFINITION_PATH)
		return
	var original_definition_text := FileAccess.get_file_as_string(DEFINITION_PATH)
	var definition := TrackSceneAuthoringData.apply_to_definition(source)
	if definition == null:
		errors.append("Could not resolve Kitchen authoring data")
		return
	definition.floor_visual_y = ROOM_BOTTOM_Y
	definition.out_of_bounds_y = OUT_OF_BOUNDS_Y
	definition.ground_size = ROOM_SIZE
	_update_room_envelope_stage_props(definition)
	var validation := definition.validate()
	if not validation.is_empty():
		errors.append("Kitchen definition is invalid after normalization: %s" % "; ".join(validation))
		return
	var save_error := ResourceSaver.save(definition, DEFINITION_PATH)
	if save_error != OK:
		errors.append("Could not save Kitchen definition: %s" % error_string(save_error))
		return
	_restore_resource_uids(DEFINITION_PATH, original_definition_text)
	var metadata_error := TrackMetadataExporter.save_json(definition, METADATA_PATH)
	if metadata_error != OK:
		errors.append("Could not save Kitchen metadata: %s" % error_string(metadata_error))

func _restore_resource_uids(path: String, original_text: String) -> void:
	if original_text.is_empty():
		return
	var saved_text := FileAccess.get_file_as_string(path)
	if saved_text.is_empty():
		return
	var header_uid := _resource_header_uid(original_text)
	var ext_resource_uids := _ext_resource_uids_by_path(original_text)
	if header_uid.is_empty() and ext_resource_uids.is_empty():
		return
	var lines := saved_text.split("\n", true)
	for i in range(lines.size()):
		var line := str(lines[i])
		if i == 0 and not header_uid.is_empty() and (line.begins_with("[gd_scene") or line.begins_with("[gd_resource")):
			lines[i] = _line_with_uid(line, header_uid)
		elif line.begins_with("[ext_resource"):
			var resource_path := _attribute_value(line, "path")
			var uid := str(ext_resource_uids.get(resource_path, ""))
			if not uid.is_empty():
				lines[i] = _line_with_uid(line, uid)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return
	file.store_string("\n".join(lines))
	file.close()

func _resource_header_uid(text: String) -> String:
	var first_line := text.get_slice("\n", 0)
	if first_line.begins_with("[gd_scene") or first_line.begins_with("[gd_resource"):
		return _attribute_value(first_line, "uid")
	return ""

func _ext_resource_uids_by_path(text: String) -> Dictionary:
	var out := {}
	for line in text.split("\n", false):
		if not line.begins_with("[ext_resource"):
			continue
		var resource_path := _attribute_value(line, "path")
		var uid := _attribute_value(line, "uid")
		if not resource_path.is_empty() and not uid.is_empty():
			out[resource_path] = uid
	return out

func _line_with_uid(line: String, uid: String) -> String:
	var existing_uid := _attribute_value(line, "uid")
	if existing_uid == uid:
		return line
	if not existing_uid.is_empty():
		line = line.replace(" uid=\"%s\"" % existing_uid, "")
	if line.begins_with("[ext_resource"):
		var type_start := line.find("type=\"")
		if type_start >= 0:
			var type_end := line.find("\"", type_start + "type=\"".length())
			if type_end >= 0:
				var insert_index := type_end + 1
				return "%s uid=\"%s\"%s" % [line.substr(0, insert_index), uid, line.substr(insert_index)]
	var close_index := line.rfind("]")
	if close_index < 0:
		return line
	return "%s uid=\"%s\"%s" % [line.substr(0, close_index), uid, line.substr(close_index)]

func _attribute_value(line: String, attribute_name: String) -> String:
	var marker := "%s=\"" % attribute_name
	var start := line.find(marker)
	if start < 0:
		return ""
	start += marker.length()
	var end := line.find("\"", start)
	if end < 0:
		return ""
	return line.substr(start, end - start)

func _update_room_envelope_stage_props(definition: TrackDefinition) -> void:
	var half_x := ROOM_SIZE.x * 0.5
	var half_z := ROOM_SIZE.y * 0.5
	var wall_height := ROOM_TOP_Y - ROOM_BOTTOM_Y
	var wall_center_y := (ROOM_TOP_Y + ROOM_BOTTOM_Y) * 0.5
	_upsert_box_prop(definition, "KitchenBackWall", Vector3(0.0, wall_center_y, half_z), Vector3(ROOM_SIZE.x, wall_height, WALL_THICKNESS), "drywall", "room_envelope")
	_upsert_box_prop(definition, "KitchenCeiling", Vector3(0.0, ROOM_TOP_Y, 0.0), Vector3(ROOM_SIZE.x, WALL_THICKNESS, ROOM_SIZE.y), "drywall", "room_envelope")
	_upsert_box_prop(definition, "KitchenLeftWall", Vector3(-half_x, wall_center_y, 0.0), Vector3(WALL_THICKNESS, wall_height, ROOM_SIZE.y), "drywall", "room_envelope")
	_upsert_box_prop(definition, "KitchenRightWall", Vector3(half_x, wall_center_y, 0.0), Vector3(WALL_THICKNESS, wall_height, ROOM_SIZE.y), "drywall", "room_envelope")
	_upsert_box_prop(definition, "KitchenFrontWallLeft", Vector3(-167.5, wall_center_y, -half_z), Vector3(225.0, wall_height, WALL_THICKNESS), "drywall", "room_envelope")
	_upsert_box_prop(definition, "KitchenFrontWallRight", Vector3(167.5, wall_center_y, -half_z), Vector3(225.0, wall_height, WALL_THICKNESS), "drywall", "room_envelope")
	_upsert_box_prop(definition, "KitchenFrontDoorHeader", Vector3(0.0, 52.0, -half_z), Vector3(120.0, 24.0, WALL_THICKNESS), "drywall", "room_envelope")
	_upsert_box_prop(definition, "KitchenDoorFrameLeft", Vector3(-61.0, 4.0, -half_z - 1.0), Vector3(3.0, 72.0, 2.0), "wood", "doorway")
	_upsert_box_prop(definition, "KitchenDoorFrameRight", Vector3(61.0, 4.0, -half_z - 1.0), Vector3(3.0, 72.0, 2.0), "wood", "doorway")
	_upsert_box_prop(definition, "KitchenDoorFrameTop", Vector3(0.0, 41.0, -half_z - 1.0), Vector3(126.0, 3.0, 2.0), "wood", "doorway")

func _upsert_box_prop(definition: TrackDefinition, prop_id: String, position: Vector3, size: Vector3, audio_material_id: String, gameplay_tag: String) -> void:
	var prop := _stage_prop(definition, prop_id)
	prop["id"] = prop_id
	prop["kind"] = "box"
	prop["asset_path"] = ""
	prop["position"] = [position.x, position.y, position.z]
	prop["box_size"] = [size.x, size.y, size.z]
	prop["scale"] = [1.0, 1.0, 1.0]
	prop["yaw_degrees"] = 0.0
	prop["collision_mode"] = "visual"
	prop["audio_material_id"] = audio_material_id
	prop["gameplay_tag"] = gameplay_tag
	if not prop.has("box_color"):
		prop["box_color"] = [0.62, 0.58, 0.51, 1.0]

func _stage_prop(definition: TrackDefinition, prop_id: String) -> Dictionary:
	for i in range(definition.stage_props.size()):
		var prop := definition.stage_props[i]
		if str(prop.get("id", "")) == prop_id:
			return prop
	var new_prop: Dictionary = {}
	definition.stage_props.append(new_prop)
	return new_prop

func _finish(errors: Array[String]) -> void:
	if errors.is_empty():
		print("[KitchenBaseline] normalized Kitchen scene, definition, and metadata")
		quit()
		return
	for error in errors:
		printerr("[KitchenBaseline] %s" % error)
	quit(1)
