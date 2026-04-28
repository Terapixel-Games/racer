extends "res://tests/framework/TestCase.gd"

const KartPhysicsRules = preload("res://scripts/logic/KartPhysicsRules.gd")

func test_turn_factor_is_speed_gated() -> void:
	var low_speed := KartPhysicsRules.turn_factor_for_speed(0.0, 20.0, 0.22)
	var mid_speed := KartPhysicsRules.turn_factor_for_speed(10.0, 20.0, 0.22)
	var full_speed := KartPhysicsRules.turn_factor_for_speed(24.0, 20.0, 0.22)
	assert_true(low_speed < mid_speed, "Low-speed steering should be weaker than moving steering")
	assert_true(mid_speed < full_speed, "Steering should keep gaining authority with speed")
	assert_equal(full_speed, 1.0, "Steering should cap at full authority")

func test_tire_grip_damps_sideways_velocity_without_instant_snap() -> void:
	var velocity := Vector3(8.0, 0.0, 20.0)
	var damped := KartPhysicsRules.damp_lateral_velocity(velocity, Vector3.RIGHT, 12.0, 1.0 / 60.0)
	assert_true(damped.x > 0.0, "Tire grip should not erase lateral motion instantly")
	assert_true(damped.x < velocity.x, "Tire grip should reduce lateral motion")
	assert_equal(damped.z, velocity.z, "Lateral damping should not steal forward speed")

func test_drift_grip_preserves_more_slide_than_normal_grip() -> void:
	var velocity := Vector3(8.0, 0.0, 20.0)
	var normal := KartPhysicsRules.damp_lateral_velocity(velocity, Vector3.RIGHT, 12.0, 1.0 / 60.0)
	var drift := KartPhysicsRules.damp_lateral_velocity(velocity, Vector3.RIGHT, 3.2, 1.0 / 60.0)
	assert_true(drift.x > normal.x, "Drift grip should preserve more lateral slide than normal tires")

func test_reverse_speed_is_limited() -> void:
	var clamped := KartPhysicsRules.clamp_reverse_speed(Vector3(0.0, 0.0, -28.0), Vector3.BACK, 12.0)
	assert_equal(clamped.z, -12.0, "Reverse speed should be capped")
