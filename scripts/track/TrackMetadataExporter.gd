extends RefCounted
class_name TrackMetadataExporter

const TrackDefinition = preload("res://scripts/track/TrackDefinition.gd")

static func metadata_for(definition: TrackDefinition) -> Dictionary:
	if definition == null:
		return {}
	return definition.to_metadata()

static func json_for(definition: TrackDefinition) -> String:
	return JSON.stringify(metadata_for(definition), "\t")

static func save_json(definition: TrackDefinition, path: String) -> Error:
	if definition == null:
		return ERR_INVALID_PARAMETER
	var errors := definition.validate()
	if not errors.is_empty():
		push_error("Cannot export invalid track definition %s: %s" % [definition.id, "; ".join(errors)])
		return ERR_INVALID_DATA
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(json_for(definition))
	file.store_string("\n")
	file.close()
	return OK
