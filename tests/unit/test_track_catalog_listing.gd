extends "res://tests/framework/TestCase.gd"

const TrackCatalog = preload("res://scripts/track/TrackCatalog.gd")

func test_list_tracks_returns_default_first_summary() -> void:
	var tracks := TrackCatalog.list_tracks()
	assert_true(tracks.size() >= 1, "Track catalog should expose at least one selectable track")
	var first: Dictionary = tracks[0]
	assert_equal(str(first.get("id", "")), TrackCatalog.get_default_track_id(), "Default track should appear first")
	assert_equal(str(first.get("display_name", "")), "Kitchen / Sir Clink", "Track summary should expose display name")
	assert_true(str(first.get("scene_path", "")).ends_with(".tscn"), "Track summary should expose runtime scene path")
	assert_true(str(first.get("definition_path", "")).ends_with(".tres"), "Track summary should expose definition path")
	assert_true(str(first.get("metadata_path", "")).ends_with(".json"), "Track summary should expose metadata path")
