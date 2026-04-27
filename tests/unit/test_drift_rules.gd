extends "res://tests/framework/TestCase.gd"

const DriftRules = preload("res://scripts/logic/DriftRules.gd")

func test_drift_requires_minimum_speed() -> void:
	assert_true(not DriftRules.can_start(6.0), "Drift should not start below the minimum speed")
	assert_true(DriftRules.can_start(12.0), "Drift should start above the minimum speed")

func test_charge_tiers_escalate() -> void:
	assert_equal(DriftRules.tier_for_charge(0.0), 0, "Zero charge should produce no drift tier")
	assert_equal(DriftRules.tier_for_charge(DriftRules.TIER_1_CHARGE), 1, "Tier 1 threshold should produce the first mini-turbo")
	assert_equal(DriftRules.tier_for_charge(DriftRules.TIER_2_CHARGE), 2, "Tier 2 threshold should produce the second mini-turbo")
	assert_equal(DriftRules.tier_for_charge(DriftRules.TIER_3_CHARGE), 3, "Tier 3 threshold should produce the strongest mini-turbo")

func test_release_boost_matches_charge_tier() -> void:
	assert_equal(DriftRules.release_boost_amount(10.0), 0.0, "Low charge should not yield a release boost")
	assert_equal(DriftRules.release_boost_amount(32.0), 16.0, "Tier 1 release should use the small boost")
	assert_equal(DriftRules.release_boost_amount(64.0), 28.0, "Tier 2 release should use the medium boost")
	assert_equal(DriftRules.release_boost_amount(92.0), 42.0, "Tier 3 release should use the big boost")
