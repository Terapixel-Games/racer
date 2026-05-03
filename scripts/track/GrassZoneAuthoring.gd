@tool
extends Area3D
class_name GrassZoneAuthoring

var _size := Vector2(80.0, 60.0)

@export var zone_id := ""
@export var size: Vector2 = Vector2(80.0, 60.0):
	set(value):
		_size = Vector2(maxf(value.x, 0.1), maxf(value.y, 0.1))
		_sync_collision_shape_from_size()
		_sync_bounds_preview()
	get:
		return _size
@export_range(0.0, 3.0, 0.05) var density := 1.0
@export var enabled := true
@export var show_bounds_preview := true
@export var bounds_preview_color := Color(0.2, 0.95, 0.25, 0.22)

func _ready() -> void:
	monitoring = false
	monitorable = false
	_ensure_unique_edit_resources()
	_sync_collision_shape_from_size()
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
		_sync_size_from_collision_shape()
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

func _sync_collision_shape_from_size() -> void:
	if not is_inside_tree() and get_child_count() == 0:
		return
	var shape_node := _get_or_create_collision_shape()
	if shape_node == null:
		return
	_ensure_unique_shape_resource(shape_node)
	var box := shape_node.shape as BoxShape3D
	if box == null:
		box = BoxShape3D.new()
		box.resource_local_to_scene = true
		shape_node.shape = box
	box.size = Vector3(size.x, 1.0, size.y)

func _sync_size_from_collision_shape() -> void:
	var shape_node := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if shape_node == null or not (shape_node.shape is BoxShape3D):
		return
	var box := shape_node.shape as BoxShape3D
	var next_size := Vector2(box.size.x, box.size.z)
	if not next_size.is_equal_approx(size):
		size = next_size

func _get_or_create_collision_shape() -> CollisionShape3D:
	var shape_node := self.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if shape_node != null:
		return shape_node
	shape_node = CollisionShape3D.new()
	shape_node.name = "CollisionShape3D"
	shape_node.shape = BoxShape3D.new()
	shape_node.shape.resource_local_to_scene = true
	add_child(shape_node)
	if owner != null:
		shape_node.owner = owner
	return shape_node

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
		box_mesh.resource_local_to_scene = true
		preview.mesh = box_mesh
	elif not box_mesh.resource_local_to_scene:
		box_mesh = box_mesh.duplicate(true) as BoxMesh
		box_mesh.resource_local_to_scene = true
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

func _ensure_unique_edit_resources() -> void:
	var shape_node := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if shape_node != null:
		_ensure_unique_shape_resource(shape_node)
	var preview := get_node_or_null("BoundsPreview") as MeshInstance3D
	if preview != null and preview.mesh is BoxMesh:
		var mesh := preview.mesh as BoxMesh
		if not mesh.resource_local_to_scene or _is_preview_mesh_shared(preview):
			mesh = mesh.duplicate(true) as BoxMesh
			mesh.resource_local_to_scene = true
			preview.mesh = mesh

func _ensure_unique_shape_resource(shape_node: CollisionShape3D) -> void:
	if shape_node.shape == null:
		return
	if shape_node.shape.resource_local_to_scene and not _is_shape_resource_shared(shape_node):
		return
	var shape := shape_node.shape.duplicate(true) as Shape3D
	shape.resource_local_to_scene = true
	shape_node.shape = shape

func _is_shape_resource_shared(shape_node: CollisionShape3D) -> bool:
	var shape := shape_node.shape
	if shape == null:
		return false
	var root := _resource_scan_root()
	for other in root.find_children("*", "CollisionShape3D", true, false):
		var other_shape := other as CollisionShape3D
		if other_shape == shape_node:
			continue
		if other_shape.shape == shape:
			return true
	return false

func _is_preview_mesh_shared(preview: MeshInstance3D) -> bool:
	var mesh := preview.mesh
	if mesh == null:
		return false
	var root := _resource_scan_root()
	for other in root.find_children("*", "MeshInstance3D", true, false):
		var other_preview := other as MeshInstance3D
		if other_preview == preview:
			continue
		if other_preview.mesh == mesh:
			return true
	return false

func _resource_scan_root() -> Node:
	if Engine.is_editor_hint() and get_tree() != null and get_tree().edited_scene_root != null:
		return get_tree().edited_scene_root
	if owner != null:
		return owner
	return self
