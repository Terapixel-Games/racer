extends "res://addons/gdunit4/src/core/GdUnitTestSuite.gd"
const CheckpointRules = preload("res://scripts/logic/CheckpointRules.gd")

func test_checkpoint_order_and_laps() -> void:
	var rules := CheckpointRules.new(3, 1)
	assert_int(rules.next_expected_checkpoint_index()).is_equal(0)
	assert_bool(rules.on_checkpoint_passed(0)).is_true()
	assert_bool(rules.on_checkpoint_passed(2)).is_false()
	assert_bool(rules.on_checkpoint_passed(1)).is_true()
	rules.on_finish_line_crossed()
	assert_int(rules.lap).is_equal(1)
