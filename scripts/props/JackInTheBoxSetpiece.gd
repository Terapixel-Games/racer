@tool
extends Node3D
class_name JackInTheBoxSetpiece

enum EditorPreviewPose {
	CLOSED,
	WINDUP,
	POP,
	OPEN,
	RESET,
}

const STATE_IDLE := "idle"
const STATE_WINDUP := "windup"
const STATE_POP := "pop"
const STATE_BOUNCE := "bounce"
const STATE_RESET := "reset"

@export_group("Trigger")
@export var trigger_radius := 12.0
@export var cooldown_seconds := 8.0
@export var popped_open_seconds := 1.0
@export var auto_demo := false

@export_group("Editor Preview")
@export var editor_preview_enabled := true
@export var editor_preview_pose: EditorPreviewPose = EditorPreviewPose.CLOSED
@export_range(0.0, 1.0, 0.01) var editor_preview_amount := 0.0

@export_group("Split Source")
@export_file("*.glb") var split_parts_scene_path := "res://assets/gameplay/tracks/attic/props/jack_parts/jack_in_the_box_parts.glb"
@export var source_scale := 2.55
@export var source_rotation_degrees := Vector3(0.0, 180.0, 0.0)
@export var box_base_source_position := Vector3(0.0, 2.42, 0.0)
@export var lid_source_position := Vector3(0.0, 0.37, -0.78)
@export var crank_source_position := Vector3(0.78, 0.96, -0.38)
@export var spring_source_position := Vector3(0.0, 2.05, 0.0)
@export var clown_source_position := Vector3.ZERO

@export_group("Lid Animation")
@export var lid_hinge_position := Vector3(0.0, 2.05, 0.78)
@export_range(-360.0, 360.0, 0.1) var lid_closed_rotation_x := 180.0
@export_range(-360.0, 360.0, 0.1) var lid_open_rotation_x := 0.0
@export_range(-40.0, 40.0, 0.1) var lid_windup_peek_degrees := 8.0

@export_group("Crank Animation")
@export var crank_pivot_position := Vector3(-0.78, 1.46, 0.38)
@export var crank_rotation_axis := Vector3(1.0, 0.0, 0.0)
@export_range(-3600.0, 3600.0, 1.0) var crank_preview_degrees := 0.0
@export_range(-3600.0, 3600.0, 1.0) var crank_windup_degrees_per_second := 1080.0

var _state := STATE_IDLE
var _state_time := 0.0
var _cooldown := 0.0
var _box_base: Node3D
var _lid: Node3D
var _crank: Node3D
var _spring: Node3D
var _spring_coil: Node3D
var _clown_head: Node3D
var _eyes: Node3D
var _mouth: Node3D
var _hat: Node3D
var _left_hand: Node3D
var _right_hand: Node3D
var _trigger_area: Area3D
var _animation_player: AnimationPlayer
var _crank_player: AudioStreamPlayer3D
var _spring_player: AudioStreamPlayer3D
var _laugh_player: AudioStreamPlayer3D

func _ready() -> void:
	_ensure_parts()
	_apply_closed_pose()
	set_process(true)

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		if _needs_parts_refresh():
			_ensure_parts()
		_sync_split_part_transforms()
		if editor_preview_enabled:
			_apply_editor_preview_pose()
		return

	_cooldown = maxf(_cooldown - delta, 0.0)
	if auto_demo and _state == STATE_IDLE and _cooldown <= 0.0:
		trigger()
	elif _state == STATE_IDLE and _cooldown <= 0.0 and _trigger_area != null:
		for body in _trigger_area.get_overlapping_bodies():
			if _is_valid_trigger_body(body):
				trigger()
				break
	if _state == STATE_IDLE:
		return
	_state_time += delta
	match _state:
		STATE_WINDUP:
			_tick_windup()
			if _state_time >= 1.15:
				_start_pop()
		STATE_POP:
			_tick_pop()
			if _state_time >= 0.42:
				_start_bounce()
		STATE_BOUNCE:
			_tick_bounce()
			if _state_time >= maxf(popped_open_seconds, 0.0):
				_start_reset()
		STATE_RESET:
			_tick_reset()
			if _state_time >= 0.72:
				_apply_closed_pose()
				_state = STATE_IDLE
				_cooldown = cooldown_seconds

func trigger() -> void:
	if _state != STATE_IDLE or _cooldown > 0.0:
		return
	_state = STATE_WINDUP
	_state_time = 0.0
	if _crank_player:
		_crank_player.play()

func state_for_test() -> String:
	return _state

func is_closed() -> bool:
	return _state == STATE_IDLE and _lid != null and _spring != null and _clown_head != null \
		and absf(_lid.rotation_degrees.x - lid_closed_rotation_x) <= 0.01 \
		and absf(_spring.scale.y - 0.08) <= 0.01 \
		and not _spring.visible \
		and not _clown_head.visible \
		and _clown_head.position.distance_to(Vector3(0.0, 0.42, 0.0)) <= 0.01

func _start_pop() -> void:
	_state = STATE_POP
	_state_time = 0.0
	if _spring_player:
		_spring_player.play()

func _start_bounce() -> void:
	_state = STATE_BOUNCE
	_state_time = 0.0
	if _laugh_player:
		_laugh_player.play()

func _start_reset() -> void:
	_state = STATE_RESET
	_state_time = 0.0
	if _laugh_player:
		_laugh_player.stop()

func _tick_windup() -> void:
	var shake := sin(_state_time * 48.0) * 0.055
	_box_base.rotation_degrees.z = shake * 2.0
	var crank_visual := _crank.get_node_or_null("CrankVisual") as Node3D
	if crank_visual:
		crank_visual.visible = false
	_apply_crank_rotation(_state_time * crank_windup_degrees_per_second)
	_lid.rotation_degrees.x = lerpf(lid_closed_rotation_x, lid_closed_rotation_x + lid_windup_peek_degrees, absf(sin(_state_time * 18.0)))

func _tick_pop() -> void:
	var t := clampf(_state_time / 0.42, 0.0, 1.0)
	var eased := 1.0 - pow(1.0 - t, 3.0)
	_lid.visible = true
	_spring.visible = t > 0.05
	if _spring_coil:
		_spring_coil.visible = false
	_lid.rotation_degrees.x = lerpf(lid_closed_rotation_x, lid_open_rotation_x, eased)
	_spring.scale.y = lerpf(0.08, 1.24, eased)
	_clown_head.position.y = lerpf(0.42, 3.9, eased)
	_clown_head.rotation_degrees.z = sin(t * PI) * 12.0
	_clown_head.visible = t > 0.08

func _tick_bounce() -> void:
	var duration := maxf(popped_open_seconds, 0.01)
	var decay := maxf(1.0 - _state_time / duration, 0.0)
	var wave := sin(_state_time * TAU * 3.2)
	_lid.visible = true
	_spring.visible = true
	if _spring_coil:
		_spring_coil.visible = false
	_clown_head.visible = true
	_lid.rotation_degrees.x = lid_open_rotation_x + wave * 3.0 * decay
	_spring.scale.y = 1.0 + wave * 0.16 * decay
	_clown_head.position.y = 3.35 + absf(wave) * 0.55 * decay
	_clown_head.rotation_degrees.z = wave * 10.0 * decay
	if _eyes:
		_eyes.scale = Vector3.ONE * (1.0 + absf(wave) * 0.18)
	if _hat:
		_hat.rotation_degrees.z = -wave * 12.0 * decay
	if _left_hand:
		_left_hand.rotation_degrees.z = 18.0 + wave * 22.0 * decay
	if _right_hand:
		_right_hand.rotation_degrees.z = -18.0 + wave * 22.0 * decay

func _tick_reset() -> void:
	var t := clampf(_state_time / 0.72, 0.0, 1.0)
	var eased := t * t * (3.0 - 2.0 * t)
	_lid.visible = true
	_lid.rotation_degrees.x = lerpf(lid_open_rotation_x, lid_closed_rotation_x, eased)
	_spring.scale.y = lerpf(1.0, 0.08, eased)
	if _spring_coil:
		_spring_coil.visible = false
	_clown_head.position.y = lerpf(3.35, 0.42, eased)
	_clown_head.rotation_degrees = Vector3(0.0, 0.0, lerpf(_clown_head.rotation_degrees.z, 0.0, eased))
	_clown_head.visible = t < 0.92
	_spring.visible = t < 0.92

func _apply_closed_pose() -> void:
	_sync_split_part_transforms()
	_box_base.rotation_degrees = Vector3.ZERO
	_lid.rotation_degrees = Vector3(lid_closed_rotation_x, 0.0, 0.0)
	_crank.rotation_degrees = Vector3.ZERO
	_lid.position = lid_hinge_position
	_crank.position = crank_pivot_position
	var crank_visual := _crank.get_node_or_null("CrankVisual") as Node3D
	if crank_visual:
		crank_visual.visible = false
	_spring.scale = Vector3(1.0, 0.08, 1.0)
	_spring.visible = false
	if _spring_coil:
		_spring_coil.scale = Vector3(1.0, 0.08, 1.0)
		_spring_coil.visible = false
	_clown_head.position = Vector3(0.0, 0.42, 0.0)
	_clown_head.rotation_degrees = Vector3.ZERO
	if _eyes:
		_eyes.scale = Vector3.ONE
	if _mouth:
		_mouth.scale = Vector3.ONE
	if _hat:
		_hat.rotation_degrees = Vector3.ZERO
	if _left_hand:
		_left_hand.rotation_degrees = Vector3(0.0, 0.0, 18.0)
	if _right_hand:
		_right_hand.rotation_degrees = Vector3(0.0, 0.0, -18.0)
	_lid.visible = true
	_clown_head.visible = false
	var lid_source := _source_part(_lid)
	if lid_source:
		lid_source.visible = true
	var crank_source := _source_part(_crank)
	if crank_source:
		crank_source.visible = true

func _apply_editor_preview_pose() -> void:
	_state = STATE_IDLE
	_state_time = 0.0
	match editor_preview_pose:
		EditorPreviewPose.CLOSED:
			_apply_closed_pose()
			_apply_crank_rotation(crank_preview_degrees)
		EditorPreviewPose.WINDUP:
			_apply_closed_pose()
			_state_time = editor_preview_amount * 1.15
			_tick_windup()
		EditorPreviewPose.POP:
			_apply_closed_pose()
			_state_time = editor_preview_amount * 0.42
			_tick_pop()
		EditorPreviewPose.OPEN:
			_apply_open_preview_pose()
			_apply_crank_rotation(crank_preview_degrees)
		EditorPreviewPose.RESET:
			_apply_open_preview_pose()
			_state_time = editor_preview_amount * 0.72
			_tick_reset()
	_state = STATE_IDLE
	_state_time = 0.0

func _apply_open_preview_pose() -> void:
	_sync_split_part_transforms()
	_box_base.rotation_degrees = Vector3.ZERO
	_lid.position = lid_hinge_position
	_lid.rotation_degrees = Vector3(lid_open_rotation_x, 0.0, 0.0)
	_lid.visible = true
	_crank.position = crank_pivot_position
	_spring.scale = Vector3.ONE
	_spring.visible = true
	if _spring_coil:
		_spring_coil.visible = false
	_clown_head.position = Vector3(0.0, 3.35, 0.0)
	_clown_head.rotation_degrees = Vector3.ZERO
	_clown_head.visible = true
	var lid_source := _source_part(_lid)
	if lid_source:
		lid_source.visible = true
	var crank_source := _source_part(_crank)
	if crank_source:
		crank_source.visible = true

func _apply_crank_rotation(degrees: float) -> void:
	var axis := crank_rotation_axis
	if axis.length_squared() <= 0.0001:
		axis = Vector3.RIGHT
	axis = axis.normalized()
	_crank.rotation_degrees = axis * degrees

func _needs_parts_refresh() -> bool:
	return _box_base == null \
		or _lid == null \
		or _crank == null \
		or _spring == null \
		or _clown_head == null \
		or get_node_or_null("BoxBase") == null \
		or get_node_or_null("Lid") == null \
		or get_node_or_null("Crank") == null \
		or get_node_or_null("Spring") == null \
		or get_node_or_null("ClownHead") == null \
		or get_node_or_null("BoxBase/SourcePart") == null \
		or get_node_or_null("Lid/SourcePart") == null \
		or get_node_or_null("Crank/SourcePart") == null \
		or get_node_or_null("Spring/SourcePart") == null \
		or get_node_or_null("ClownHead/SourcePart") == null

func _ensure_parts() -> void:
	_box_base = _part("BoxBase")
	_lid = _part("Lid")
	_crank = _part("Crank")
	_spring = _part("Spring")
	_spring_coil = _part("SpringCoil")
	_clown_head = _part("ClownHead")
	_eyes = _part("Eyes")
	_mouth = _part("Mouth")
	_hat = _part("Hat")
	_left_hand = _part("LeftHand")
	_right_hand = _part("RightHand")
	_trigger_area = _ensure_trigger_area()
	_animation_player = _ensure_animation_player()
	var uses_split_parts := _ensure_split_models()
	if not uses_split_parts:
		_lid.position = Vector3.ZERO
		_crank.position = Vector3.ZERO
		_make_box(_box_base, Vector3(3.4, 2.2, 3.4), Color(0.25, 0.12, 0.36), Vector3(0.0, 1.1, 0.0))
		_make_box_mesh(_box_base, "FrontStar", Vector3(1.1, 1.1, 0.08), Color(0.95, 0.76, 0.18), Vector3(0.0, 1.25, -1.74), Vector3.ZERO)
		_make_box_mesh(_box_base, "LeftStripe", Vector3(0.08, 1.8, 0.26), Color(0.12, 0.62, 0.78), Vector3(-1.74, 1.1, -0.75), Vector3.ZERO)
		_make_box_mesh(_box_base, "RightStripe", Vector3(0.08, 1.8, 0.26), Color(0.12, 0.62, 0.78), Vector3(1.74, 1.1, 0.75), Vector3.ZERO)
		_make_box(_lid, Vector3(3.55, 0.18, 3.55), Color(0.42, 0.22, 0.55), Vector3(0.0, 2.28, -1.7))
		_make_cylinder(_crank, 0.18, 1.0, Color(0.85, 0.48, 0.16), Vector3(1.9, 1.35, 0.0), Vector3(0.0, 0.0, 90.0))
		_make_cylinder_mesh(_crank, "Handle", 0.12, 0.72, Color(0.95, 0.74, 0.26), Vector3(2.05, 1.35, 0.58), Vector3(90.0, 0.0, 0.0))
		_make_cylinder(_spring, 0.42, 2.2, Color(0.48, 0.42, 0.5), Vector3(0.0, 1.86, 0.0), Vector3.ZERO)
		_make_spring_coil(_spring_coil)
		_make_sphere(_clown_head, 0.86, Color(0.95, 0.82, 0.56), Vector3(0.0, 0.42, 0.0))
		_make_sphere(_eyes, 0.12, Color(0.18, 0.85, 1.0), Vector3(0.0, 1.0, -0.62))
		_make_box(_mouth, Vector3(0.72, 0.1, 0.08), Color(0.82, 0.08, 0.12), Vector3(0.0, 0.68, -0.82))
		_make_cone(_hat, 0.52, 1.05, Color(0.2, 0.14, 0.72), Vector3(0.0, 1.34, 0.0))
		_make_sphere(_left_hand, 0.22, Color(0.95, 0.82, 0.56), Vector3(-0.95, 2.65, -0.1))
		_make_sphere(_right_hand, 0.22, Color(0.95, 0.82, 0.56), Vector3(0.95, 2.65, -0.1))
	else:
		_lid.position = lid_hinge_position
		_crank.position = crank_pivot_position
		_remove_generated_lid_placeholder()
		_remove_generated_crank_placeholder()
	_crank_player = _audio_player("CrankAudio", "res://assets/source/audio/sfx/attic/jack_crank.mp3")
	_spring_player = _audio_player("SpringAudio", "res://assets/source/audio/sfx/attic/jack_spring.mp3")
	_laugh_player = _audio_player("LaughAudio", "res://assets/source/audio/sfx/attic/jack_laugh.mp3")

func _ensure_trigger_area() -> Area3D:
	var area := get_node_or_null("TriggerArea") as Area3D
	if area == null:
		area = Area3D.new()
		area.name = "TriggerArea"
		_attach_child(self, area)
		var shape_node := CollisionShape3D.new()
		shape_node.name = "CollisionShape3D"
		_attach_child(area, shape_node)
	var shape_node := area.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if shape_node != null:
		var sphere := shape_node.shape as SphereShape3D
		if sphere == null:
			sphere = SphereShape3D.new()
			shape_node.shape = sphere
		sphere.radius = trigger_radius
	area.collision_layer = 0
	area.collision_mask = 2
	area.monitoring = true
	area.monitorable = true
	if not area.body_entered.is_connected(_on_trigger_body_entered):
		area.body_entered.connect(_on_trigger_body_entered)
	return area

func _ensure_animation_player() -> AnimationPlayer:
	var player := get_node_or_null("AnimationPlayer") as AnimationPlayer
	if player == null:
		player = AnimationPlayer.new()
		player.name = "AnimationPlayer"
		_attach_child(self, player)
	return player

func _ensure_split_models() -> bool:
	if not ResourceLoader.exists(split_parts_scene_path):
		return false
	var packed := load(split_parts_scene_path)
	if not (packed is PackedScene):
		return false
	var source_root := (packed as PackedScene).instantiate()
	var ok := source_root != null
	var scale := Vector3.ONE * source_scale
	ok = _ensure_part_model(source_root, _box_base, "BoxBasePart", box_base_source_position, source_rotation_degrees, scale) and ok
	ok = _ensure_part_model(source_root, _lid, "LidPart", lid_source_position, source_rotation_degrees, scale) and ok
	ok = _ensure_part_model(source_root, _crank, "CrankPart", crank_source_position, source_rotation_degrees, scale) and ok
	ok = _ensure_part_model(source_root, _spring, "SpringPart", spring_source_position, source_rotation_degrees, scale) and ok
	ok = _ensure_part_model(source_root, _clown_head, "ClownHeadPart", clown_source_position, source_rotation_degrees, scale) and ok
	if source_root:
		source_root.queue_free()
	return ok

func _ensure_part_model(source_root: Node, parent: Node3D, source_name: String, local_position: Vector3, local_rotation: Vector3, local_scale: Vector3) -> bool:
	var existing := parent.get_node_or_null("SourcePart") as Node3D
	if existing != null:
		_apply_part_model_transform(existing, local_position, local_rotation, local_scale)
		return true
	var source := _find_node_recursive(source_root, source_name) as Node3D
	if source == null:
		return false
	var duplicated := source.duplicate()
	if not (duplicated is Node3D):
		duplicated.queue_free()
		return false
	var model := duplicated as Node3D
	model.name = "SourcePart"
	_apply_part_model_transform(model, local_position, local_rotation, local_scale)
	_disable_collision(model)
	_attach_child(parent, model)
	return true

func _sync_split_part_transforms() -> void:
	var scale := Vector3.ONE * source_scale
	_apply_part_model_transform(_source_part(_box_base), box_base_source_position, source_rotation_degrees, scale)
	_apply_part_model_transform(_source_part(_lid), lid_source_position, source_rotation_degrees, scale)
	_apply_part_model_transform(_source_part(_crank), crank_source_position, source_rotation_degrees, scale)
	_apply_part_model_transform(_source_part(_spring), spring_source_position, source_rotation_degrees, scale)
	_apply_part_model_transform(_source_part(_clown_head), clown_source_position, source_rotation_degrees, scale)

func _apply_part_model_transform(model: Node3D, local_position: Vector3, local_rotation: Vector3, local_scale: Vector3) -> void:
	if model == null:
		return
	model.position = local_position
	model.rotation_degrees = local_rotation
	model.scale = local_scale

func _attach_child(parent: Node, child: Node) -> void:
	parent.add_child(child)

func _remove_generated_lid_placeholder() -> void:
	var placeholder := _lid.get_node_or_null("HingedCover")
	if placeholder:
		placeholder.queue_free()

func _remove_generated_crank_placeholder() -> void:
	var placeholder := _crank.get_node_or_null("CrankVisual")
	if placeholder:
		placeholder.queue_free()

func _source_part(parent: Node3D) -> Node3D:
	return parent.get_node_or_null("SourcePart") as Node3D

func _find_node_recursive(root: Node, node_name: String) -> Node:
	if root.name == node_name:
		return root
	for child in root.get_children():
		var found := _find_node_recursive(child, node_name)
		if found != null:
			return found
	return null

func _disable_collision(node: Node) -> void:
	if node is CollisionShape3D:
		(node as CollisionShape3D).disabled = true
	if node is CollisionObject3D:
		var collision_object := node as CollisionObject3D
		collision_object.collision_layer = 0
		collision_object.collision_mask = 0
	for child in node.get_children():
		_disable_collision(child)

func _on_trigger_body_entered(body: Node3D) -> void:
	if _is_valid_trigger_body(body):
		trigger()

func _is_valid_trigger_body(body: Node) -> bool:
	return body is CarController

func _part(node_name: String) -> Node3D:
	var existing := get_node_or_null(node_name) as Node3D
	if existing:
		return existing
	var node := Node3D.new()
	node.name = node_name
	_attach_child(self, node)
	return node

func _make_box(parent: Node3D, size: Vector3, color: Color, local_position: Vector3) -> void:
	_make_box_mesh(parent, "Mesh", size, color, local_position, Vector3.ZERO)

func _make_box_mesh(parent: Node3D, mesh_name: String, size: Vector3, color: Color, local_position: Vector3, local_rotation: Vector3) -> void:
	if parent.get_node_or_null(mesh_name):
		return
	var mesh := MeshInstance3D.new()
	mesh.name = mesh_name
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = _material(color)
	mesh.position = local_position
	mesh.rotation_degrees = local_rotation
	_attach_child(parent, mesh)

func _make_cylinder(parent: Node3D, radius: float, height: float, color: Color, local_position: Vector3, local_rotation: Vector3) -> void:
	_make_cylinder_mesh(parent, "Mesh", radius, height, color, local_position, local_rotation)

func _make_cylinder_mesh(parent: Node3D, mesh_name: String, radius: float, height: float, color: Color, local_position: Vector3, local_rotation: Vector3) -> void:
	if parent.get_node_or_null(mesh_name):
		return
	var mesh := MeshInstance3D.new()
	mesh.name = mesh_name
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = height
	cylinder.radial_segments = 18
	mesh.mesh = cylinder
	mesh.material_override = _material(color)
	mesh.position = local_position
	mesh.rotation_degrees = local_rotation
	_attach_child(parent, mesh)

func _make_cone(parent: Node3D, radius: float, height: float, color: Color, local_position: Vector3) -> void:
	if parent.get_node_or_null("Mesh"):
		return
	var mesh := MeshInstance3D.new()
	mesh.name = "Mesh"
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = radius
	cone.height = height
	cone.radial_segments = 24
	mesh.mesh = cone
	mesh.material_override = _material(color)
	mesh.position = local_position
	_attach_child(parent, mesh)

func _make_spring_coil(parent: Node3D) -> void:
	if parent.get_node_or_null("Mesh"):
		return
	var mesh := MeshInstance3D.new()
	mesh.name = "Mesh"
	var immediate := ImmediateMesh.new()
	var material := _material(Color(0.82, 0.78, 0.86))
	immediate.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, material)
	var turns := 7.0
	var steps := 96
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		var angle := t * turns * TAU
		var point := Vector3(cos(angle) * 0.42, lerpf(0.92, 3.02, t), sin(angle) * 0.42)
		immediate.surface_add_vertex(point)
	immediate.surface_end()
	mesh.mesh = immediate
	_attach_child(parent, mesh)

func _make_sphere(parent: Node3D, radius: float, color: Color, local_position: Vector3) -> void:
	if parent.get_node_or_null("Mesh"):
		return
	var mesh := MeshInstance3D.new()
	mesh.name = "Mesh"
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	sphere.radial_segments = 24
	sphere.rings = 12
	mesh.mesh = sphere
	mesh.material_override = _material(color)
	mesh.position = local_position
	_attach_child(parent, mesh)

func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.58
	if color.a < 1.0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material

func _audio_player(node_name: String, stream_path: String) -> AudioStreamPlayer3D:
	var player := get_node_or_null(node_name) as AudioStreamPlayer3D
	if player == null:
		player = AudioStreamPlayer3D.new()
		player.name = node_name
		_attach_child(self, player)
	player.stream = load(stream_path)
	player.unit_size = 16.0
	player.volume_db = -4.0
	return player
