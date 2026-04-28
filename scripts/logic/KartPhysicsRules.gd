extends RefCounted
class_name KartPhysicsRules

static func turn_factor_for_speed(speed: float, full_turn_speed: float, low_speed_factor: float) -> float:
	var safe_full_turn_speed: float = maxf(full_turn_speed, 0.01)
	var speed_ratio: float = clampf(absf(speed) / safe_full_turn_speed, 0.0, 1.0)
	return lerpf(clampf(low_speed_factor, 0.0, 1.0), 1.0, speed_ratio)

static func damping_factor(rate: float, delta: float) -> float:
	if rate <= 0.0 or delta <= 0.0:
		return 0.0
	return clampf(1.0 - exp(-rate * delta), 0.0, 1.0)

static func damp_lateral_velocity(horizontal_velocity: Vector3, lateral_axis: Vector3, grip_rate: float, delta: float) -> Vector3:
	if lateral_axis.length_squared() <= 0.0001:
		return horizontal_velocity
	var lateral := lateral_axis.normalized()
	var lateral_speed := horizontal_velocity.dot(lateral)
	return horizontal_velocity - lateral * lateral_speed * damping_factor(grip_rate, delta)

static func clamp_reverse_speed(horizontal_velocity: Vector3, forward_axis: Vector3, max_reverse_speed: float) -> Vector3:
	if forward_axis.length_squared() <= 0.0001:
		return horizontal_velocity
	var forward := forward_axis.normalized()
	var forward_speed := horizontal_velocity.dot(forward)
	if forward_speed >= -max_reverse_speed:
		return horizontal_velocity
	var lateral_velocity := horizontal_velocity - forward * forward_speed
	return lateral_velocity + forward * -max_reverse_speed
