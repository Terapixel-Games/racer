extends Resource

class_name DriftRules

const MIN_START_SPEED := 8.0
const MAX_CHARGE := 100.0
const TIER_1_CHARGE := 28.0
const TIER_2_CHARGE := 58.0
const TIER_3_CHARGE := 86.0

static func can_start(speed: float) -> bool:
	return speed >= MIN_START_SPEED

static func tier_for_charge(charge: float) -> int:
	if charge >= TIER_3_CHARGE:
		return 3
	if charge >= TIER_2_CHARGE:
		return 2
	if charge >= TIER_1_CHARGE:
		return 1
	return 0

static func update_charge(current_charge: float, delta: float, steering_abs: float, speed_ratio: float, charge_rate: float) -> float:
	var steering_factor: float = clamp(steering_abs, 0.35, 1.0)
	var pace_factor: float = clamp(speed_ratio, 0.45, 1.15)
	return clamp(current_charge + (charge_rate * steering_factor * pace_factor * delta), 0.0, MAX_CHARGE)

static func release_boost_amount(charge: float) -> float:
	match tier_for_charge(charge):
		3:
			return 42.0
		2:
			return 28.0
		1:
			return 16.0
		_:
			return 0.0
