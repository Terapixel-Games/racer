extends Area3D
class_name StageInteractionArea

var interaction_data: Dictionary = {}
var _cooldowns := {}

func configure(data: Dictionary) -> void:
	interaction_data = data.duplicate(true)
	name = str(interaction_data.get("id", "StageInteraction"))
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	monitorable = false
	body_entered.connect(_on_body_entered)
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	for key in _cooldowns.keys():
		_cooldowns[key] = maxf(float(_cooldowns[key]) - delta, 0.0)
	var action := str(interaction_data.get("action", ""))
	if action == "slow":
		for body in get_overlapping_bodies():
			_apply_slow(body)
	elif action == "rumble":
		for body in get_overlapping_bodies():
			_apply_rumble(body)

func _on_body_entered(body: Node) -> void:
	var action := str(interaction_data.get("action", "boost"))
	match action:
		"boost":
			_apply_boost(body)
		"slow":
			_apply_slow(body)
		"impulse":
			_apply_impulse(body)
		"rumble":
			_apply_rumble(body)
		"trigger":
			_apply_trigger(body)

func _apply_boost(body: Node) -> void:
	var car := body as CarController
	if car == null or not _consume_cooldown(car):
		return
	car.trigger_item_boost(
		maxf(float(interaction_data.get("duration", 0.8)), 0.0),
		maxf(float(interaction_data.get("boost_force", 82.0)), 0.0)
	)

func _apply_slow(body: Node) -> void:
	var car := body as CarController
	if car == null:
		return
	car.apply_stage_speed_modifier(
		clampf(float(interaction_data.get("speed_multiplier", 0.72)), 0.2, 2.0),
		maxf(float(interaction_data.get("duration", 0.35)), 0.05)
	)

func _apply_impulse(body: Node) -> void:
	var car := body as CarController
	if car == null or not _consume_cooldown(car):
		return
	var local_impulse := _vector3_from_value(interaction_data.get("impulse", [0.0, 0.0, 0.0]), Vector3.ZERO)
	var world_impulse := global_transform.basis.orthonormalized() * local_impulse
	car.apply_stage_impulse(world_impulse)

func _apply_rumble(body: Node) -> void:
	var car := body as CarController
	if car == null or not _consume_cooldown(car):
		return
	var intensity := maxf(float(interaction_data.get("intensity", 1.0)), 0.0)
	var side := global_transform.basis.orthonormalized().x * 2.0 * intensity
	car.apply_stage_impulse(side)
	car.apply_stage_speed_modifier(0.94, maxf(float(interaction_data.get("duration", 0.25)), 0.05))

func _apply_trigger(body: Node) -> void:
	var car := body as CarController
	if car == null or not _consume_cooldown(car):
		return
	var target_path := str(interaction_data.get("target_node_path", "")).strip_edges()
	if target_path.is_empty():
		return
	var target := _track_root().get_node_or_null(NodePath(target_path))
	var method := str(interaction_data.get("target_method", "trigger")).strip_edges()
	if target != null and not method.is_empty() and target.has_method(method):
		target.call(method)

func _consume_cooldown(car: CarController) -> bool:
	var key := str(car.get_instance_id())
	if float(_cooldowns.get(key, 0.0)) > 0.0:
		return false
	_cooldowns[key] = maxf(float(interaction_data.get("cooldown", 1.0)), 0.0)
	return true

func _track_root() -> Node:
	var node: Node = self
	while node.get_parent() != null and node.get_parent() is Node3D:
		node = node.get_parent()
	return node

func _vector3_from_value(value: Variant, fallback: Vector3) -> Vector3:
	if value is Vector3:
		return value
	if value is Array and value.size() >= 3:
		return Vector3(float(value[0]), float(value[1]), float(value[2]))
	if value is Dictionary:
		return Vector3(float(value.get("x", fallback.x)), float(value.get("y", fallback.y)), float(value.get("z", fallback.z)))
	return fallback
