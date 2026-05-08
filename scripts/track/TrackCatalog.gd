extends RefCounted
class_name TrackCatalog

const TrackDefinition = preload("res://scripts/track/TrackDefinition.gd")
const TrackMapDefinition = preload("res://scripts/track/TrackMapDefinition.gd")

const DEFAULT_TRACK_ID := "kitchen"
const MANIFEST_PATH := "res://assets/gameplay/tracks/track_packages.json"
const KITCHEN_DEFINITION_PATH := "res://assets/gameplay/tracks/kitchen/kitchen_track_definition.tres"
const KITCHEN_MAP_PATH := "res://assets/gameplay/tracks/kitchen/kitchen_track_map.tres"
const KITCHEN_SCENE_PATH := "res://assets/gameplay/tracks/kitchen/kitchen_track.tscn"
const KITCHEN_METADATA_PATH := "res://assets/gameplay/tracks/kitchen/kitchen_track_metadata.json"

static var _manifest_cache: Dictionary = {}

static func get_default_track_id() -> String:
	var manifest := _load_manifest()
	return str(manifest.get("default_track_id", DEFAULT_TRACK_ID))

static func list_tracks() -> Array[Dictionary]:
	var manifest := _load_manifest()
	var tracks: Dictionary = manifest.get("tracks", {})
	var default_id := str(manifest.get("default_track_id", DEFAULT_TRACK_ID))
	var summaries: Array[Dictionary] = []
	if tracks.has(default_id):
		summaries.append(_track_summary(default_id, tracks[default_id]))
	var ids := tracks.keys()
	ids.sort()
	for id_value in ids:
		var track_id := str(id_value)
		if track_id == default_id:
			continue
		summaries.append(_track_summary(track_id, tracks[id_value]))
	if summaries.is_empty():
		summaries.append(_track_summary(DEFAULT_TRACK_ID, _fallback_kitchen_package()))
	return summaries

static func list_maps() -> Array[Dictionary]:
	var maps := _map_packages()
	var default_id := get_default_track_id()
	var summaries: Array[Dictionary] = []
	if maps.has(default_id):
		summaries.append(_map_summary(default_id, maps[default_id]))
	var ids := maps.keys()
	ids.sort()
	for id_value in ids:
		var map_id := str(id_value)
		if map_id == default_id:
			continue
		summaries.append(_map_summary(map_id, maps[id_value]))
	return summaries

static func list_modes(map_id: String) -> Array[Dictionary]:
	var map_definition := get_map_definition(map_id)
	if map_definition == null:
		return []
	var modes: Array[Dictionary] = []
	for mode_id in map_definition.list_mode_ids():
		modes.append(map_definition.mode_summary(mode_id))
	return modes

static func get_map_definition(map_id: String = DEFAULT_TRACK_ID) -> TrackMapDefinition:
	var package := get_map_package(map_id)
	var path := str(package.get("map_definition_path", package.get("definition_path", "")))
	if path.is_empty():
		return null
	return load(path) as TrackMapDefinition

static func get_mode_definition(map_id: String = DEFAULT_TRACK_ID, mode_id: String = "race") -> TrackDefinition:
	var map_definition := get_map_definition(map_id)
	if map_definition != null:
		var definition := map_definition.to_track_definition(mode_id)
		if definition != null:
			return definition
	return _get_legacy_definition(map_id)

static func get_package(track_id: String = DEFAULT_TRACK_ID) -> Dictionary:
	var normalized := _normalize_track_id(track_id)
	var manifest := _load_manifest()
	var tracks: Dictionary = manifest.get("tracks", {})
	if tracks.has(normalized):
		return tracks[normalized]
	match normalized:
		"oval", "serpentine", "sir_clink", "sir-clink":
			return tracks.get(DEFAULT_TRACK_ID, _fallback_kitchen_package())
		_:
			return {}

static func get_map_package(map_id: String = DEFAULT_TRACK_ID) -> Dictionary:
	var normalized := _normalize_track_id(map_id)
	var maps := _map_packages()
	if maps.has(normalized):
		return maps[normalized]
	return {}

static func get_definition(track_id: String = DEFAULT_TRACK_ID) -> TrackDefinition:
	return get_mode_definition(track_id, "race")

static func _get_legacy_definition(track_id: String = DEFAULT_TRACK_ID) -> TrackDefinition:
	var package := get_package(track_id)
	var path := str(package.get("definition_path", ""))
	if path.is_empty():
		return null
	return load(path) as TrackDefinition

static func get_metadata(track_id: String = DEFAULT_TRACK_ID) -> Dictionary:
	var package := get_package(track_id)
	var metadata_path := str(package.get("metadata_path", ""))
	if not metadata_path.is_empty():
		var from_json := _load_metadata_json(metadata_path)
		if not from_json.is_empty():
			_apply_package_fields(from_json, package)
			return from_json
	var definition := get_definition(track_id)
	if definition == null:
		return {}
	var metadata := definition.to_metadata()
	_apply_package_fields(metadata, package)
	return metadata

static func get_scene_path(track_id: String = DEFAULT_TRACK_ID) -> String:
	return str(get_package(track_id).get("scene_path", ""))

static func get_definition_path(track_id: String = DEFAULT_TRACK_ID) -> String:
	return str(get_package(track_id).get("definition_path", ""))

static func get_metadata_path(track_id: String = DEFAULT_TRACK_ID) -> String:
	return str(get_package(track_id).get("metadata_path", ""))

static func get_track_version(track_id: String = DEFAULT_TRACK_ID) -> String:
	return str(get_package(track_id).get("version", ""))

static func has_track(track_id: String) -> bool:
	return not get_package(track_id).is_empty()

static func has_map(map_id: String) -> bool:
	return not get_map_package(map_id).is_empty()

static func _normalize_track_id(track_id: String) -> String:
	var normalized := track_id.strip_edges().to_lower()
	return DEFAULT_TRACK_ID if normalized.is_empty() else normalized

static func _load_manifest() -> Dictionary:
	if not _manifest_cache.is_empty():
		return _manifest_cache
	if FileAccess.file_exists(MANIFEST_PATH):
		var file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
		if file != null:
			var parsed = JSON.parse_string(file.get_as_text())
			file.close()
			if parsed is Dictionary:
				_manifest_cache = parsed
				return _manifest_cache
	_manifest_cache = {
		"default_track_id": DEFAULT_TRACK_ID,
		"tracks": {
			DEFAULT_TRACK_ID: _fallback_kitchen_package()
		}
	}
	return _manifest_cache

static func _fallback_kitchen_package() -> Dictionary:
	return {
		"id": DEFAULT_TRACK_ID,
		"display_name": "Kitchen / Sir Clink",
		"version": "kitchen_v2_2026_04_29",
		"scene_path": KITCHEN_SCENE_PATH,
		"definition_path": KITCHEN_DEFINITION_PATH,
		"metadata_path": KITCHEN_METADATA_PATH,
	}

static func _fallback_kitchen_map_package() -> Dictionary:
	return {
		"id": DEFAULT_TRACK_ID,
		"display_name": "Kitchen / Sir Clink",
		"version": "kitchen_v2_2026_04_29",
		"map_definition_path": KITCHEN_MAP_PATH,
		"map_scene_path": "res://assets/gameplay/tracks/kitchen/kitchen_editable_room.tscn",
		"default_mode_id": "race",
	}

static func _map_packages() -> Dictionary:
	var manifest := _load_manifest()
	var maps: Dictionary = manifest.get("maps", {})
	if maps.is_empty():
		maps = {DEFAULT_TRACK_ID: _fallback_kitchen_map_package()}
	elif not maps.has(DEFAULT_TRACK_ID):
		maps[DEFAULT_TRACK_ID] = _fallback_kitchen_map_package()
	return maps

static func _track_summary(track_id: String, package_value: Variant) -> Dictionary:
	var package: Dictionary = package_value if package_value is Dictionary else {}
	var normalized := _normalize_track_id(str(package.get("id", track_id)))
	return {
		"id": normalized,
		"display_name": str(package.get("display_name", normalized.capitalize())),
		"version": str(package.get("version", "")),
		"scene_path": str(package.get("scene_path", "")),
		"definition_path": str(package.get("definition_path", "")),
		"metadata_path": str(package.get("metadata_path", "")),
	}

static func _map_summary(map_id: String, package_value: Variant) -> Dictionary:
	var package: Dictionary = package_value if package_value is Dictionary else {}
	var normalized := _normalize_track_id(str(package.get("id", map_id)))
	var summary := {
		"id": normalized,
		"display_name": str(package.get("display_name", normalized.capitalize())),
		"version": str(package.get("version", "")),
		"map_definition_path": str(package.get("map_definition_path", "")),
		"map_scene_path": str(package.get("map_scene_path", "")),
		"default_mode_id": str(package.get("default_mode_id", "race")),
	}
	var map_definition := get_map_definition(normalized)
	if map_definition != null:
		summary.merge(map_definition.to_map_summary(), true)
		summary["map_definition_path"] = str(package.get("map_definition_path", summary.get("map_definition_path", "")))
	return summary

static func _load_metadata_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary:
		return parsed
	return {}

static func _apply_package_fields(metadata: Dictionary, package: Dictionary) -> void:
	if metadata.is_empty() or package.is_empty():
		return
	metadata["track_id"] = str(package.get("id", metadata.get("id", "")))
	metadata["version"] = str(package.get("version", metadata.get("version", "")))
	metadata["runtime_scene_path"] = str(package.get("scene_path", metadata.get("runtime_scene_path", "")))
	metadata["definition_path"] = str(package.get("definition_path", metadata.get("definition_path", "")))
	metadata["metadata_path"] = str(package.get("metadata_path", metadata.get("metadata_path", "")))
