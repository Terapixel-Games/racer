extends CharacterBody3D
class_name CarController

const DriftRules = preload("res://scripts/logic/DriftRules.gd")
const KartPhysicsRules = preload("res://scripts/logic/KartPhysicsRules.gd")
const RacerRoster = preload("res://scripts/logic/RacerRoster.gd")
const ARKitFaceDriverScript = preload("res://scripts/ARKitFaceDriver.gd")
const RacerSpriteLodVisualScript = preload("res://scripts/RacerSpriteLodVisual.gd")

const VISUAL_TARGET_FOOTPRINT := 1.75
const VISUAL_BOTTOM_Y := -0.78
const PORTRAIT_BADGE_PIXEL_SIZE := 0.0024
const RACER_LOD0_TO_LOD1_DISTANCE := 42.0
const RACER_LOD1_TO_LOD0_DISTANCE := 34.0
const RACER_LOD1_TO_LOD2_DISTANCE := 72.0
const RACER_LOD2_TO_LOD1_DISTANCE := 62.0

@export var acceleration := 28.0
@export var brake_force := 32.0
@export var max_speed := 42.0
@export var steer_speed := 2.8
@export var tire_grip_rate := 12.0
@export var drift_tire_grip_rate := 3.2
@export var low_speed_turn_factor := 0.22
@export var full_turn_speed := 20.0
@export var reverse_max_speed := 12.0
@export var ground_snap_distance := 0.85
@export var grounded_downforce := 18.0
@export var boost_force := 70.0
@export var boost_meter_max := 100.0
@export var boost_gain_drift := 18.0
@export var boost_drain := 28.0
@export var correction_speed := 6.0
@export var auto_accelerate := false
@export var coast_drag := 12.0
@export var brake_drag := 18.0
@export var debug_wall_logging := false
@export var drift_charge_rate := 34.0
@export var drift_hop_velocity := 1.2
@export var visual_animation_enabled := true
@export var visual_bob_height := 0.045
@export var visual_bob_rate := 9.0
@export var visual_turn_lean_degrees := 9.0
@export var visual_accel_pitch_degrees := 5.0
@export var visual_drift_wobble_degrees := 3.0
@export var visual_landing_squash := 0.1
@export var visual_animation_lerp := 14.0

var boost_meter := 0.0
var input_state := {"throttle": 0.0, "brake": 0.0, "steer": 0.0, "drift": false, "boost": false, "item_use": false}
var controlled_locally := false
var target_basis : Basis
var target_position : Vector3
var gravity : float = ProjectSettings.get_setting("physics/3d/default_gravity") as float
var _wall_log_cooldown := 0.0
var drift_charge := 0.0
var drift_tier := 0
var is_drifting := false
var _drift_direction := 0.0
var _item_boost_timer := 0.0
var _item_boost_force := 0.0
var _stage_speed_multiplier := 1.0
var _stage_speed_timer := 0.0
var _racer_visual_id := ""
var _racer_visual_mode := ""
var _racer_visual_lod := RacerRoster.RACER_MODEL_LOD0
var _active_visual_model: Node3D = null
var _arkit_face_driver: ARKitFaceDriver = null
var _visual_anim_time := 0.0
var _visual_last_position := Vector3.ZERO
var _visual_last_yaw := 0.0
var _visual_last_speed := 0.0
var _visual_last_position_initialized := false
var _visual_was_on_floor := false
var _visual_landing_amount := 0.0

func _ready() -> void:
	floor_snap_length = maxf(floor_snap_length, ground_snap_distance)
	target_basis = global_transform.basis
	target_position = global_transform.origin
	velocity = Vector3.ZERO
	_apply_selected_racer_visual_from_metadata()

func set_racer_visual(racer_id: String) -> bool:
	return set_racer_visual_lod(racer_id, RacerRoster.RACER_MODEL_LOD0)

func set_racer_visual_lod(racer_id: String, lod: String) -> bool:
	var normalized := RacerRoster.normalize_id(racer_id)
	var normalized_lod := RacerRoster.normalize_model_lod(lod)
	if _racer_visual_id == normalized and _racer_visual_lod == normalized_lod and has_racer_visual():
		return true
	if _can_use_sprite_lod(normalized, normalized_lod):
		return _apply_sprite_lod_visual(normalized, normalized_lod)
	var model_path := RacerRoster.get_racer_in_kart_model_path_for_lod(normalized, normalized_lod)
	model_path = _racer_arkit_face_model_path(model_path)
	if model_path.is_empty() or not ResourceLoader.exists(model_path) or not _is_scene_import_valid(model_path):
		return _apply_portrait_visual(normalized)
	var packed := load(model_path)
	if not (packed is PackedScene):
		return _apply_portrait_visual(normalized)
	var model := (packed as PackedScene).instantiate()
	if not (model is Node3D):
		if model is Node:
			(model as Node).queue_free()
		return _apply_portrait_visual(normalized)

	_clear_racer_visual()
	var visual_mount := _get_visual_mount()
	_active_visual_model = model as Node3D
	_active_visual_model.name = "RacerInKartModel"
	_active_visual_model.rotation_degrees.y = RacerRoster.get_racer_in_kart_yaw_degrees(normalized)
	_disable_gameplay_collision(_active_visual_model)
	visual_mount.add_child(_active_visual_model)
	_fit_visual_model(_active_visual_model, visual_mount)
	_attach_arkit_face_driver(_active_visual_model)
	_set_placeholder_visible(false)
	_racer_visual_id = normalized
	_racer_visual_mode = "model"
	_racer_visual_lod = normalized_lod
	return true

func get_racer_visual_id() -> String:
	return _racer_visual_id

func get_racer_visual_mode() -> String:
	return _racer_visual_mode

func get_racer_visual_lod() -> String:
	return _racer_visual_lod

func update_racer_visual_lod_for_camera(camera_position: Vector3) -> void:
	if _racer_visual_id.is_empty():
		return
	var distance := global_transform.origin.distance_to(camera_position)
	var target_lod := _racer_visual_lod_for_camera_distance(distance)
	if target_lod != _racer_visual_lod:
		set_racer_visual_lod(_racer_visual_id, target_lod)
	if _racer_visual_mode.begins_with("sprite_"):
		_update_sprite_lod_camera(camera_position)

func _racer_visual_lod_for_camera_distance(distance: float) -> String:
	match _racer_visual_lod:
		RacerRoster.RACER_MODEL_LOD2:
			if distance < RACER_LOD2_TO_LOD1_DISTANCE:
				return RacerRoster.RACER_MODEL_LOD1 if distance >= RACER_LOD0_TO_LOD1_DISTANCE else RacerRoster.RACER_MODEL_LOD0
			return RacerRoster.RACER_MODEL_LOD2
		RacerRoster.RACER_MODEL_LOD1:
			if distance >= RACER_LOD1_TO_LOD2_DISTANCE:
				return RacerRoster.RACER_MODEL_LOD2
			if distance < RACER_LOD1_TO_LOD0_DISTANCE:
				return RacerRoster.RACER_MODEL_LOD0
			return RacerRoster.RACER_MODEL_LOD1
		_:
			if distance >= RACER_LOD1_TO_LOD2_DISTANCE:
				return RacerRoster.RACER_MODEL_LOD2
			if distance >= RACER_LOD0_TO_LOD1_DISTANCE:
				return RacerRoster.RACER_MODEL_LOD1
			return RacerRoster.RACER_MODEL_LOD0

func has_racer_visual() -> bool:
	return _active_visual_model != null and is_instance_valid(_active_visual_model)

func get_visual_animation_root() -> Node3D:
	var root := get_node_or_null("RacerVisual")
	return root as Node3D

func update_visual_animation(delta: float) -> void:
	if not visual_animation_enabled or delta <= 0.0:
		return
	var root := get_visual_animation_root()
	if root == null:
		return

	var horizontal_velocity := velocity
	horizontal_velocity.y = 0.0
	var speed: float = horizontal_velocity.length()
	if _visual_last_position_initialized:
		var measured_velocity := (global_transform.origin - _visual_last_position) / delta
		measured_velocity.y = 0.0
		speed = maxf(speed, measured_velocity.length())
	_visual_last_position = global_transform.origin
	_visual_last_position_initialized = true

	var speed_ratio: float = clampf(speed / maxf(max_speed, 0.01), 0.0, 1.4)
	_visual_anim_time += delta * lerpf(0.8, 1.7, clampf(speed_ratio, 0.0, 1.0))

	var current_yaw := global_transform.basis.get_euler().y
	var yaw_delta: float = wrapf(current_yaw - _visual_last_yaw, -PI, PI)
	var yaw_turn: float = clampf((yaw_delta / delta) / maxf(steer_speed, 0.01), -1.0, 1.0)
	_visual_last_yaw = current_yaw
	var steering_visual: float = float(input_state.get("steer", 0.0)) if controlled_locally else yaw_turn
	if absf(steering_visual) < 0.05:
		steering_visual = yaw_turn

	var speed_delta: float = (speed - _visual_last_speed) / delta
	_visual_last_speed = speed
	var accel_pitch: float = clampf(speed_delta / 70.0, -1.0, 1.0)
	var bob: float = sin(_visual_anim_time * visual_bob_rate) * visual_bob_height * speed_ratio
	var drift_wobble: float = sin(_visual_anim_time * visual_bob_rate * 1.8) * deg_to_rad(visual_drift_wobble_degrees) if is_drifting else 0.0

	if is_on_floor() and not _visual_was_on_floor:
		_visual_landing_amount = 1.0
	_visual_was_on_floor = is_on_floor()
	_visual_landing_amount = move_toward(_visual_landing_amount, 0.0, delta * 5.0)

	var target_position := Vector3(0.0, bob - _visual_landing_amount * 0.03, 0.0)
	var target_rotation := Vector3(
		deg_to_rad(-accel_pitch * visual_accel_pitch_degrees),
		drift_wobble,
		deg_to_rad(-steering_visual * visual_turn_lean_degrees) + drift_wobble * 0.35
	)
	var squash: float = _visual_landing_amount * visual_landing_squash
	var target_scale := Vector3(1.0 + squash * 0.45, 1.0 - squash, 1.0 + squash * 0.45)
	var blend: float = clampf(delta * visual_animation_lerp, 0.0, 1.0)
	root.position = root.position.lerp(target_position, blend)
	root.rotation = root.rotation.lerp(target_rotation, blend)
	root.scale = root.scale.lerp(target_scale, blend)

func _physics_process(delta: float) -> void:
	if controlled_locally:
		_apply_input(delta)
	else:
		_apply_remote_correction(delta)
	move_and_slide()
	update_visual_animation(delta)
	_log_wall_contacts(delta)

func set_input(state:Dictionary) -> void:
	input_state = state

func _apply_input(delta: float) -> void:
	_stage_speed_timer = maxf(_stage_speed_timer - delta, 0.0)
	if _stage_speed_timer <= 0.0:
		_stage_speed_multiplier = 1.0
	var vertical_vel := velocity.y
	var horiz_vel := velocity
	horiz_vel.y = 0
	var speed := horiz_vel.length()
	var forward := global_transform.basis.z
	var throttle_input : float = 1.0 if auto_accelerate else input_state.get("throttle", 0.0)
	var brake_input : float = input_state.get("brake", 0.0)
	var accel := 0.0
	if throttle_input > 0.1:
		accel += acceleration * throttle_input
	if brake_input > 0.1:
		accel -= brake_force * brake_input
	if accel > 0.0:
		accel *= _stage_speed_multiplier
	var steering_input : float = input_state.get("steer", 0.0)
	var requested_drift : bool = input_state.get("drift", false)
	if requested_drift and absf(steering_input) > 0.08 and DriftRules.can_start(speed):
		if not is_drifting:
			_start_drift(signf(steering_input), speed)
		elif absf(steering_input) > 0.0:
			_drift_direction = signf(steering_input)
	if (not requested_drift or absf(steering_input) <= 0.08) and is_drifting:
		accel += _release_drift_boost()
	if is_drifting:
		boost_meter = min(boost_meter_max, boost_meter + boost_gain_drift * delta)
		drift_charge = DriftRules.update_charge(drift_charge, delta, absf(steering_input), speed / max(max_speed, 0.01), drift_charge_rate)
		drift_tier = DriftRules.tier_for_charge(drift_charge)
	if _item_boost_timer > 0.0:
		_item_boost_timer = max(_item_boost_timer - delta, 0.0)
		accel += _item_boost_force
	if input_state.get("boost", false) and boost_meter > 1.0:
		boost_meter = max(0.0, boost_meter - boost_drain * delta)
		accel += boost_force
	var forward_speed := horiz_vel.dot(forward)
	var turn_factor := KartPhysicsRules.turn_factor_for_speed(speed, full_turn_speed, low_speed_turn_factor)
	if throttle_input <= 0.1 and brake_input <= 0.1 and speed < 1.0:
		turn_factor = 0.0
	var reverse_turn_sign := -1.0 if forward_speed < -0.5 else 1.0
	var steer_amount : float = steering_input * steer_speed * turn_factor * reverse_turn_sign * delta
	if is_drifting:
		steer_amount *= 1.35
	rotate_y(steer_amount)
	_lock_physics_upright()
	forward = global_transform.basis.z
	var lateral := global_transform.basis.x
	horiz_vel += forward * accel * delta
	var grip_rate := drift_tire_grip_rate if is_drifting else tire_grip_rate
	horiz_vel = KartPhysicsRules.damp_lateral_velocity(horiz_vel, lateral, grip_rate, delta)
	horiz_vel = KartPhysicsRules.clamp_reverse_speed(horiz_vel, forward, reverse_max_speed)
	var effective_max_speed := max_speed * _stage_speed_multiplier
	horiz_vel = horiz_vel.limit_length(effective_max_speed + (boost_force * 0.5 if input_state.get("boost", false) else 0.0) + (_item_boost_force * 0.25 if _item_boost_timer > 0.0 else 0.0))
	# natural drag and braking drag
	var drag_force := coast_drag
	if brake_input > 0.1:
		drag_force += brake_drag * brake_input
	horiz_vel = horiz_vel.move_toward(Vector3.ZERO, drag_force * delta)
	velocity = horiz_vel
	velocity.y = vertical_vel
	if is_on_floor():
		velocity.y = -grounded_downforce
	else:
		velocity.y -= gravity * delta
	if velocity.y <= 0.0:
		apply_floor_snap()

func _lock_physics_upright() -> void:
	var yaw := global_transform.basis.get_euler().y
	global_transform.basis = Basis(Vector3.UP, yaw).orthonormalized()

func _start_drift(direction: float, speed: float) -> void:
	is_drifting = true
	drift_charge = 0.0
	drift_tier = 0
	_drift_direction = direction if absf(direction) > 0.0 else 1.0
	if is_on_floor() and speed >= DriftRules.MIN_START_SPEED:
		velocity.y = drift_hop_velocity

func _release_drift_boost() -> float:
	var release_boost := DriftRules.release_boost_amount(drift_charge)
	is_drifting = false
	drift_charge = 0.0
	drift_tier = 0
	_drift_direction = 0.0
	return release_boost

func trigger_item_boost(duration: float, force: float) -> void:
	_item_boost_timer = max(duration, 0.0)
	_item_boost_force = max(force, 0.0)

func apply_stage_speed_modifier(multiplier: float, duration: float) -> void:
	var clamped := clampf(multiplier, 0.2, 2.0)
	if _stage_speed_timer <= 0.0:
		_stage_speed_multiplier = clamped
	elif clamped < 1.0:
		_stage_speed_multiplier = minf(_stage_speed_multiplier, clamped)
	else:
		_stage_speed_multiplier = maxf(_stage_speed_multiplier, clamped)
	_stage_speed_timer = maxf(_stage_speed_timer, maxf(duration, 0.0))

func apply_stage_impulse(world_impulse: Vector3) -> void:
	velocity += world_impulse

func get_drift_charge_ratio() -> float:
	return drift_charge / max(DriftRules.MAX_CHARGE, 0.01)

func get_drift_tier() -> int:
	return drift_tier

func _apply_remote_correction(delta:float) -> void:
	global_transform.origin = global_transform.origin.lerp(target_position, delta * correction_speed)
	var current_quat := global_transform.basis.get_rotation_quaternion()
	var target_quat := target_basis.get_rotation_quaternion()
	var blended := current_quat.slerp(target_quat, clamp(delta * correction_speed, 0.0, 1.0))
	global_transform.basis = Basis(blended)
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0

func apply_network_state(position:Vector3, basis:Basis) -> void:
	target_position = position
	target_basis = basis

func capture_state() -> Dictionary:
	return {
		"position": global_transform.origin,
		"basis": global_transform.basis,
		"boost": boost_meter
	}

func _log_wall_contacts(delta: float) -> void:
	if not debug_wall_logging:
		return
	_wall_log_cooldown = max(_wall_log_cooldown - delta, 0.0)
	if _wall_log_cooldown > 0.0:
		return
	for i in range(get_slide_collision_count()):
		var col := get_slide_collision(i)
		if col == null:
			continue
		var collider := col.get_collider()
		var collider_name := ""
		if collider is Node:
			collider_name = (collider as Node).name
		var normal := col.get_normal()
		# Heuristic: only log likely wall hits.
		var is_wall := collider_name.findn("Wall") != -1 or collider is StaticBody3D
		if not is_wall:
			continue
		var collider_vel := col.get_collider_velocity()
		var rel_vel : Vector3 = velocity - collider_vel
		var normal_speed := rel_vel.dot(normal)
		print("[WallHit] name=", collider_name, " normal=", normal, " normal_speed=", "%.2f" % normal_speed, " vel=", velocity, " position=", global_transform.origin)
		_wall_log_cooldown = 0.25
		break

func _apply_selected_racer_visual_from_metadata() -> void:
	var service := get_node_or_null("/root/NakamaService")
	if service == null or not service.has_method("get_meta_value"):
		return
	var selected := str(service.call("get_meta_value", "selected_racer_id", "")).strip_edges()
	if selected == "":
		return
	set_racer_visual(selected)

func _get_visual_mount() -> Node3D:
	var existing := get_node_or_null("RacerVisual")
	if existing is Node3D:
		return existing as Node3D
	var mount := Node3D.new()
	mount.name = "RacerVisual"
	add_child(mount)
	return mount

func _clear_racer_visual() -> void:
	if _active_visual_model != null and is_instance_valid(_active_visual_model):
		_active_visual_model.queue_free()
	_active_visual_model = null
	_arkit_face_driver = null
	_racer_visual_id = ""
	_racer_visual_mode = ""
	_racer_visual_lod = RacerRoster.RACER_MODEL_LOD0
	var mount := get_node_or_null("RacerVisual")
	if mount != null:
		if mount is Node3D:
			(mount as Node3D).transform = Transform3D.IDENTITY
		for child in mount.get_children():
			child.queue_free()
	_visual_last_position_initialized = false
	_visual_landing_amount = 0.0

func _show_placeholder_visual() -> void:
	_clear_racer_visual()
	_set_placeholder_visible(true)

func _set_placeholder_visible(visible: bool) -> void:
	var placeholder := get_node_or_null("Mesh")
	if placeholder is Node3D:
		(placeholder as Node3D).visible = visible

func _apply_portrait_visual(racer_id: String) -> bool:
	var portrait_path := RacerRoster.get_portrait_path(racer_id)
	if portrait_path.is_empty() or not ResourceLoader.exists(portrait_path):
		_show_placeholder_visual()
		return false
	var texture := load(portrait_path)
	if not (texture is Texture2D):
		_show_placeholder_visual()
		return false
	_clear_racer_visual()
	_set_placeholder_visible(true)
	var badge := Sprite3D.new()
	badge.name = "RacerPortraitBillboard"
	badge.texture = texture as Texture2D
	badge.pixel_size = PORTRAIT_BADGE_PIXEL_SIZE
	badge.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	badge.position = Vector3(0.0, 0.46, -0.25)
	badge.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_get_visual_mount().add_child(badge)
	_active_visual_model = badge
	_arkit_face_driver = null
	_racer_visual_id = racer_id
	_racer_visual_mode = "portrait"
	_racer_visual_lod = RacerRoster.RACER_MODEL_LOD0
	return true

func _can_use_sprite_lod(racer_id: String, lod: String) -> bool:
	var sheet_path := RacerRoster.get_racer_sprite_sheet_path(racer_id, lod)
	var manifest_path := RacerRoster.get_racer_sprite_manifest_path(racer_id, lod)
	return not sheet_path.is_empty() and ResourceLoader.exists(sheet_path) and FileAccess.file_exists(manifest_path)

func _apply_sprite_lod_visual(racer_id: String, lod: String) -> bool:
	var normalized_lod := RacerRoster.normalize_model_lod(lod)
	var sheet_path := RacerRoster.get_racer_sprite_sheet_path(racer_id, normalized_lod)
	var manifest_path := RacerRoster.get_racer_sprite_manifest_path(racer_id, normalized_lod)
	var texture := load(sheet_path)
	if not (texture is Texture2D):
		return _apply_portrait_visual(racer_id)
	var visual := RacerSpriteLodVisualScript.new()
	visual.name = "RacerInKartSprite%s" % normalized_lod.to_upper()
	visual.configure(texture as Texture2D, RacerSpriteLodVisualScript.manifest_for_path(manifest_path))
	visual.position.y = VISUAL_BOTTOM_Y
	_clear_racer_visual()
	_set_placeholder_visible(false)
	_get_visual_mount().add_child(visual)
	_active_visual_model = visual
	_arkit_face_driver = null
	_racer_visual_id = racer_id
	_racer_visual_mode = "sprite_%s" % normalized_lod
	_racer_visual_lod = normalized_lod
	return true

func _update_sprite_lod_camera(camera_position: Vector3) -> void:
	if _active_visual_model is RacerSpriteLodVisual:
		(_active_visual_model as RacerSpriteLodVisual).update_for_camera(global_transform, camera_position)

func _racer_arkit_face_model_path(model_path: String) -> String:
	if model_path.is_empty() or not model_path.ends_with(".glb"):
		return model_path
	var slash := model_path.rfind("/")
	if slash < 0:
		return model_path
	var directory := model_path.substr(0, slash)
	var file_name := model_path.substr(slash + 1)
	var arkit_path := "%s/arkit/%s" % [directory, file_name]
	return arkit_path if ResourceLoader.exists(arkit_path) else model_path

func _attach_arkit_face_driver(model: Node3D) -> void:
	var driver := ARKitFaceDriverScript.new()
	driver.name = "ARKitFaceDriver"
	driver.auto_start_server = true
	model.add_child(driver)
	if driver.bind_to_model(model):
		_arkit_face_driver = driver
	else:
		driver.queue_free()
		_arkit_face_driver = null

func _is_scene_import_valid(resource_path: String) -> bool:
	var import_path := "%s.import" % resource_path
	if not FileAccess.file_exists(import_path):
		return true
	var file := FileAccess.open(import_path, FileAccess.READ)
	if file == null:
		return true
	var text := file.get_as_text()
	file.close()
	return text.find("valid=false") == -1

func _disable_gameplay_collision(node: Node) -> void:
	if node is CollisionShape3D:
		(node as CollisionShape3D).disabled = true
	elif node is CollisionObject3D:
		var collision_object := node as CollisionObject3D
		collision_object.collision_layer = 0
		collision_object.collision_mask = 0
	if node is Area3D:
		var area := node as Area3D
		area.monitoring = false
		area.monitorable = false
	for child in node.get_children():
		_disable_gameplay_collision(child)

func _fit_visual_model(model: Node3D, mount: Node3D) -> void:
	var aabb: AABB = _visual_aabb_in_mount_space(model, mount)
	var footprint: float = maxf(aabb.size.x, aabb.size.z)
	if footprint <= 0.001:
		model.position = Vector3.ZERO
		return
	var scale_factor: float = VISUAL_TARGET_FOOTPRINT / footprint
	scale_factor = clamp(scale_factor, 0.02, 4.0)
	var center: Vector3 = aabb.get_center()
	model.scale *= scale_factor
	model.position = Vector3(
		-center.x * scale_factor,
		VISUAL_BOTTOM_Y - aabb.position.y * scale_factor,
		-center.z * scale_factor
	)

func _visual_aabb_in_mount_space(node: Node3D, mount: Node3D) -> AABB:
	var found := false
	var combined := AABB()
	var stack: Array[Node] = [node]
	while not stack.is_empty():
		var current: Node = stack.pop_back()
		if current is VisualInstance3D:
			var visual := current as VisualInstance3D
			var local_aabb: AABB = visual.get_aabb()
			var to_mount: Transform3D = mount.global_transform.affine_inverse() * visual.global_transform
			for point in _aabb_points(local_aabb):
				var mount_point: Vector3 = to_mount * point
				if not found:
					combined = AABB(mount_point, Vector3.ZERO)
					found = true
				else:
					combined = combined.expand(mount_point)
		for child in current.get_children():
			if child is Node:
				stack.append(child)
	return combined

func _aabb_points(aabb: AABB) -> Array[Vector3]:
	var p := aabb.position
	var s := aabb.size
	return [
		p,
		p + Vector3(s.x, 0, 0),
		p + Vector3(0, s.y, 0),
		p + Vector3(0, 0, s.z),
		p + Vector3(s.x, s.y, 0),
		p + Vector3(s.x, 0, s.z),
		p + Vector3(0, s.y, s.z),
		p + s,
	]
