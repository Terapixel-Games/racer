extends "res://addons/gdunit4/src/core/GdUnitTestSuite.gd"
const LobbyRules = preload("res://scripts/logic/LobbyRules.gd")
const Config = preload("res://scripts/Config.gd")

func test_lobby_countdown_resets_to_threshold() -> void:
	var countdown = LobbyRules.reset_countdown_on_join(5, LobbyRules.PHASE_LOBBY, Config.LOBBY_RESET_TO_TEN_THRESHOLD, 10)
	assert_float(countdown).is_equal(10.0)
	var unchanged = LobbyRules.reset_countdown_on_join(15, LobbyRules.PHASE_LOBBY, Config.LOBBY_RESET_TO_TEN_THRESHOLD, 10)
	assert_float(unchanged).is_equal(15.0)
