extends Node3D
class_name JackInTheBoxSetpiece

const STATE_IDLE := "idle"
const STATE_WINDUP := "windup"
const STATE_POP := "pop"
const STATE_BOUNCE := "bounce"
const STATE_RESET := "reset"

@export var trigger_radius := 12.0
@export var cooldown_seconds := 8.0
@export var popped_open_seconds := 1.0
@export var auto_demo := false

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
		and absf(_lid.rotation_degrees.x) <= 0.01 \
		and absf(_spring.scale.y - 0.08) <= 0.01 \
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
	_box_base.rotation_degrees.z = shake * 8.0
	_crank.rotation_degrees.x = _state_time * 1080.0
	_lid.rotation_degrees.x = lerpf(0.0, -8.0, absf(sin(_state_time * 18.0)))

func _tick_pop() -> void:
	var t := clampf(_state_time / 0.42, 0.0, 1.0)
	var eased := 1.0 - pow(1.0 - t, 3.0)
	_lid.rotation_degrees.x = lerpf(0.0, -112.0, eased)
	_spring.scale.y = lerpf(0.08, 1.24, eased)
	if _spring_coil:
		_spring_coil.scale.y = lerpf(0.08, 1.24, eased)
	_clown_head.position.y = lerpf(0.42, 3.9, eased)
	_clown_head.rotation_degrees.z = sin(t * PI) * 12.0

func _tick_bounce() -> void:
	var duration := maxf(popped_open_seconds, 0.01)
	var decay := maxf(1.0 - _state_time / duration, 0.0)
	var wave := sin(_state_time * TAU * 3.2)
	_lid.rotation_degrees.x = -112.0 + wave * 3.0 * decay
	_spring.scale.y = 1.0 + wave * 0.16 * decay
	if _spring_coil:
		_spring_coil.scale.y = 1.0 + wave * 0.16 * decay
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
	_lid.rotation_degrees.x = lerpf(-112.0, 0.0, eased)
	_spring.scale.y = lerpf(1.0, 0.08, eased)
	if _spring_coil:
		_spring_coil.scale.y = lerpf(1.0, 0.08, eased)
	_clown_head.position.y = lerpf(3.35, 0.42, eased)
	_clown_head.rotation_degrees = Vector3(0.0, 0.0, lerpf(_clown_head.rotation_degrees.z, 0.0, eased))

func _apply_closed_pose() -> void:
	_box_base.rotation_degrees = Vector3.ZERO
	_lid.rotation_degrees = Vector3.ZERO
	_crank.rotation_degrees = Vector3.ZERO
	_spring.scale = Vector3(1.0, 0.08, 1.0)
	if _spring_coil:
		_spring_coil.scale = Vector3(1.0, 0.08, 1.0)
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
	_crank_player = _audio_player("CrankAudio", "res://assets/source/audio/sfx/attic/jack_crank.mp3")
	_spring_player = _audio_player("SpringAudio", "res://assets/source/audio/sfx/attic/jack_spring.mp3")
	_laugh_player = _audio_player("LaughAudio", "res://assets/source/audio/sfx/attic/jack_laugh.mp3")

func _ensure_trigger_area() -> Area3D:
	var area := get_node_or_null("TriggerArea") as Area3D
	if area == null:
		area = Area3D.new()
		area.name = "TriggerArea"
		add_child(area)
		var shape_node := CollisionShape3D.new()
		shape_node.name = "CollisionShape3D"
		area.add_child(shape_node)
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
		add_child(player)
	return player

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
	add_child(node)
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
	parent.add_child(mesh)

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
	parent.add_child(mesh)

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
	parent.add_child(mesh)

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
	parent.add_child(mesh)

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
	parent.add_child(mesh)

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
		add_child(player)
	player.stream = load(stream_path)
	player.unit_size = 16.0
	player.volume_db = -4.0
	return player
