@tool
extends Area3D
class_name GrassZoneAuthoring

@export var zone_id := ""
@export var size := Vector2(80.0, 60.0)
@export_range(0.0, 3.0, 0.05) var density := 1.0
@export var enabled := true
@export var show_bounds_preview := true
@export var bounds_preview_color := Color(0.2, 0.95, 0.25, 0.22)

func _ready() -> void:
	monitoring = false
	monitorable = false
	if Engine.is_editor_hint():
		set_process(true)
		_sync_bounds_preview()
	else:
		set_process(false)
		var preview := get_node_or_null("BoundsPreview") as MeshInstance3D
		if preview != null:
			preview.visible = false

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		_sync_bounds_preview()

func to_grass_zone() -> Dictionary:
	var bounds := _bounds_from_collision_shape()
	var zone_size: Vector2 = bounds.get("size", size)
	var zone_position: Vector3 = bounds.get("position", position)
	var zone_yaw_degrees := float(bounds.get("yaw_degrees", rotation_degrees.y))
	return {
		"id": zone_id if not zone_id.strip_edges().is_empty() else str(name),
		"position": [zone_position.x, zone_position.y, zone_position.z],
		"yaw_degrees": zone_yaw_degrees,
		"size": [zone_size.x, zone_size.y],
		"density": density,
		"enabled": enabled,
	}

func _bounds_from_collision_shape() -> Dictionary:
	var shape_node := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if shape_node == null:
		return {}
	if not (shape_node.shape is BoxShape3D):
		return {}
	var box := shape_node.shape as BoxShape3D
	var shape_scale := shape_node.transform.basis.get_scale().abs()
	var box_size := Vector3(box.size.x * shape_scale.x, box.size.y * shape_scale.y, box.size.z * shape_scale.z)
	var center := position + transform.basis * shape_node.position
	return {
		"position": center,
		"yaw_degrees": rotation_degrees.y + shape_node.rotation_degrees.y,
		"size": Vector2(box_size.x, box_size.z),
	}

func _sync_bounds_preview() -> void:
	var preview := _get_or_create_bounds_preview()
	if preview == null:
		return
	var shape_node := get_node_or_null("CollisionShape3D") as CollisionShape3D
	preview.visible = show_bounds_preview and shape_node != null and shape_node.shape is BoxShape3D
	if not preview.visible:
		return
	var box := shape_node.shape as BoxShape3D
	var box_mesh := preview.mesh as BoxMesh
	if box_mesh == null:
		box_mesh = BoxMesh.new()
		preview.mesh = box_mesh
	box_mesh.size = box.size
	preview.transform = shape_node.transform
	if not (preview.material_override is StandardMaterial3D):
		preview.material_override = _bounds_material()
	else:
		var material := preview.material_override as StandardMaterial3D
		material.albedo_color = bounds_preview_color

func _get_or_create_bounds_preview() -> MeshInstance3D:
	var preview := get_node_or_null("BoundsPreview") as MeshInstance3D
	if preview != null:
		return preview
	preview = MeshInstance3D.new()
	preview.name = "BoundsPreview"
	preview.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	preview.material_override = _bounds_material()
	add_child(preview)
	if owner != null:
		preview.owner = owner
	return preview

func _bounds_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = bounds_preview_color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material
