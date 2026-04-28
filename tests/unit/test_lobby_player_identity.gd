extends "res://tests/framework/TestCase.gd"

const LobbyController = preload("res://scripts/LobbyController.gd")
const RacerRoster = preload("res://scripts/logic/RacerRoster.gd")

func test_lobby_join_metadata_uses_selected_racer_as_identity() -> void:
	var metadata := LobbyController.lobby_join_metadata_for_racer("Moko")
	assert_equal(metadata.get("selected_racer_id", ""), "Moko", "Join metadata should carry the selected racer")
	assert_equal(metadata.get("racer_display_name", ""), "Moko", "Lobby display name should match the selected racer")

func test_lobby_join_metadata_defaults_invalid_racer() -> void:
	var metadata := LobbyController.lobby_join_metadata_for_racer("Not A Racer")
	assert_equal(metadata.get("selected_racer_id", ""), RacerRoster.DEFAULT_RACER_ID, "Invalid selections should fall back to the default racer")

func test_lobby_player_label_prefers_racer_id() -> void:
	var label := LobbyController.player_label_from_entry({"name": "ignored user", "racer_id": "Velva"})
	assert_equal(label, "Velva", "Lobby labels should show the selected racer")

func test_lobby_player_label_keeps_legacy_name_entries() -> void:
	var label := LobbyController.player_label_from_entry({"name": "Arcade Guest"})
	assert_equal(label, "Arcade Guest", "Lobby labels should still support legacy name-only entries")
