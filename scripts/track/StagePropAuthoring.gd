@tool
extends Node3D
class_name StagePropAuthoring

const PREVIEW_NAME := "GeneratedPreview"

@export_enum("box", "scene") var prop_kind := "box":
	set(value):
		prop_kind = value
		_rebuild_preview_deferred()
@export var prop_id := "":
	set(value):
		prop_id = value
		if prop_id.strip_edges().is_empty():
			name = "StageProp"
@export_file("*.tscn", "*.glb", "*.gltf") var asset_path := "":
	set(value):
		asset_path = value
		_rebuild_preview_deferred()
@export var box_size := Vector3.ONE:
	set(value):
		box_size = value
		_rebuild_preview_deferred()
@export var box_color := Color(0.75, 0.72, 0.64, 1.0):
	set(value):
		box_color = value
		_rebuild_preview_deferred()
@export_enum("none", "visual", "static") var collision_mode := "visual"
@export var audio_material_id := ""
@export var gameplay_tag := ""
@export var preview_enabled := true:
	set(value):
		preview_enabled = value
		_rebuild_preview_deferred()

var _preview_refresh_queued := false

func _ready() -> void:
	_rebuild_preview()

func to_stage_prop() -> Dictionary:
	return {
		"id": _resolved_prop_id(),
		"kind": prop_kind,
		"asset_path": asset_path,
		"box_size": [box_size.x, box_size.y, box_size.z],
		"box_color": [box_color.r, box_color.g, box_color.b, box_color.a],
		"position": [position.x, position.y, position.z],
		"yaw_degrees": rotation_degrees.y,
		"scale": [scale.x, scale.y, scale.z],
		"collision_mode": collision_mode,
		"audio_material_id": audio_material_id,
		"gameplay_tag": gameplay_tag,
	}

func _resolved_prop_id() -> String:
	if not prop_id.strip_edges().is_empty():
		return prop_id
	return str(name)

func _rebuild_preview_deferred() -> void:
	if _preview_refresh_queued or not is_inside_tree():
		return
	_preview_refresh_queued = true
	call_deferred("_rebuild_preview")

func _rebuild_preview() -> void:
	_preview_refresh_queued = false
	_clear_preview()
	if not preview_enabled:
		return
	var holder := Node3D.new()
	holder.name = PREVIEW_NAME
	add_child(holder)
	if prop_kind == "scene":
		_add_scene_preview(holder)
	else:
		_add_box_preview(holder)

func _clear_preview() -> void:
	var existing := get_node_or_null(PREVIEW_NAME)
	if existing == null:
		return
	remove_child(existing)
	if Engine.is_editor_hint():
		existing.queue_free()
	else:
		existing.free()

func _add_scene_preview(parent: Node3D) -> void:
	if asset_path.strip_edges().is_empty() or not ResourceLoader.exists(asset_path):
		_add_box_preview(parent, Color(1.0, 0.2, 0.1, 0.8))
		return
	var packed := load(asset_path)
	if not (packed is PackedScene):
		_add_box_preview(parent, Color(1.0, 0.2, 0.1, 0.8))
		return
	var instance := (packed as PackedScene).instantiate()
	if not (instance is Node3D):
		instance.queue_free()
		_add_box_preview(parent, Color(1.0, 0.2, 0.1, 0.8))
		return
	instance.name = "Asset"
	parent.add_child(instance)

func _add_box_preview(parent: Node3D, color: Color = box_color) -> void:
	var mesh := MeshInstance3D.new()
	mesh.name = "Box"
	var box := BoxMesh.new()
	box.size = box_size
	mesh.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.64
	if color.a < 1.0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh.material_override = material
	parent.add_child(mesh)
