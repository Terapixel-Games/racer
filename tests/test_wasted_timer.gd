extends "res://addons/gdunit4/src/core/GdUnitTestSuite.gd"
const WastedRules = preload("res://scripts/logic/WastedRules.gd")
const Config = preload("res://scripts/Config.gd")

func test_wasted_after_delay() -> void:
	var rules := WastedRules.new()
	var wasted := false
	for i in 6:
		wasted = rules.update(10, 0, 1.0, 3, Config.BEHIND_SECONDS_TO_WASTED)
	assert_bool(wasted).is_true()
	assert_bool(rules.wasted).is_true()
