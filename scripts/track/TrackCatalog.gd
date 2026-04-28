extends RefCounted
class_name TrackCatalog

const TrackDefinition = preload("res://scripts/track/TrackDefinition.gd")

const DEFAULT_TRACK_ID := "kitchen"
const KITCHEN_DEFINITION_PATH := "res://assets/gameplay/tracks/kitchen/kitchen_track_definition.tres"

static func get_default_track_id() -> String:
	return DEFAULT_TRACK_ID

static func get_definition(track_id: String = DEFAULT_TRACK_ID) -> TrackDefinition:
	var normalized := track_id.strip_edges().to_lower()
	if normalized.is_empty():
		normalized = DEFAULT_TRACK_ID
	match normalized:
		"kitchen", "sir_clink", "sir-clink":
			return load(KITCHEN_DEFINITION_PATH) as TrackDefinition
		_:
			return null

static func get_metadata(track_id: String = DEFAULT_TRACK_ID) -> Dictionary:
	var definition := get_definition(track_id)
	if definition == null:
		return {}
	return definition.to_metadata()

static func has_track(track_id: String) -> bool:
	return get_definition(track_id) != null
