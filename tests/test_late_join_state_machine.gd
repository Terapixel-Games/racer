extends "res://addons/gdunit4/src/core/GdUnitTestSuite.gd"
const LobbyRules = preload("res://scripts/logic/LobbyRules.gd")

func test_allow_join_only_in_lobby_phase() -> void:
	assert_bool(LobbyRules.allow_join(LobbyRules.PHASE_LOBBY)).is_true()
	assert_bool(LobbyRules.allow_join(LobbyRules.PHASE_STARTING)).is_false()
	assert_bool(LobbyRules.allow_join(LobbyRules.PHASE_CLOSED)).is_false()
