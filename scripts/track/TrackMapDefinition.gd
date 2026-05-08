extends Resource
class_name TrackMapDefinition

const TrackDefinition = preload("res://scripts/track/TrackDefinition.gd")

@export var id := ""
@export var display_name := ""
@export var version := ""
@export_file("*.tscn") var map_scene_path := ""
@export var default_mode_id := "race"
@export var mode_configs: Dictionary = {}

@export var sky_preset_id := ""
@export_range(0.0, 1.0, 0.01) var sky_time_of_day := 0.5
@export var sky_weather := ""
@export var sky_top_color := Color(0.58, 0.72, 0.9)
@export var sky_horizon_color := Color(0.64, 0.72, 0.82)
@export_range(0.0, 1.0, 0.01) var sky_cloud_amount := 0.25
@export var sky_cloud_speed := 0.02
@export_range(0.0, 1.0, 0.01) var sky_haze_amount := 0.18
@export var sky_light_energy := 2.4
@export var ground_size := Vector2(160.0, 140.0)
@export var ground_color := Color(0.82, 0.86, 0.88)
@export var ground_texture_path := ""
@export var ground_shader_path := ""
@export var audio_ids: Dictionary = {}

func list_mode_ids() -> Array[String]:
	var ids: Array[String] = []
	for key in mode_configs.keys():
		ids.append(str(key))
	ids.sort()
	return ids

func has_mode(mode_id: String) -> bool:
	return mode_configs.has(_normalize_mode_id(mode_id))

func get_mode_config(mode_id: String = "") -> Dictionary:
	var normalized := _normalize_mode_id(mode_id)
	var config: Dictionary = mode_configs.get(normalized, {})
	return config.duplicate(true)

func to_track_definition(mode_id: String = "") -> TrackDefinition:
	var normalized := _normalize_mode_id(mode_id)
	var mode_config := get_mode_config(normalized)
	if mode_config.is_empty():
		return null
	var definition := _load_base_definition(mode_config)
	if definition == null:
		definition = TrackDefinition.new()
	_apply_shared_fields(definition)
	_apply_mode_fields(definition, normalized, mode_config)
	return definition

func to_map_summary() -> Dictionary:
	return {
		"id": id,
		"display_name": display_name,
		"version": version,
		"scene_path": map_scene_path,
		"map_scene_path": map_scene_path,
		"default_mode_id": default_mode_id,
		"modes": list_mode_ids(),
	}

func mode_summary(mode_id: String = "") -> Dictionary:
	var normalized := _normalize_mode_id(mode_id)
	var config := get_mode_config(normalized)
	return {
		"id": normalized,
		"map_id": id,
		"display_name": str(config.get("display_name", display_name)),
		"kind": str(config.get("kind", normalized)),
		"road_source": str(config.get("road_source", "")),
		"definition_path": str(config.get("definition_path", "")),
		"metadata_path": str(config.get("metadata_path", "")),
		"scene_path": str(config.get("scene_path", map_scene_path)),
	}

func _load_base_definition(mode_config: Dictionary) -> TrackDefinition:
	var definition_path := str(mode_config.get("definition_path", ""))
	if definition_path.strip_edges().is_empty():
		return null
	var loaded := load(definition_path) as TrackDefinition
	if loaded == null:
		return null
	return loaded.duplicate(true) as TrackDefinition

func _apply_shared_fields(definition: TrackDefinition) -> void:
	if not id.strip_edges().is_empty():
		definition.id = id
	if not display_name.strip_edges().is_empty():
		definition.display_name = display_name
	if not version.strip_edges().is_empty():
		definition.version = version
	if not map_scene_path.strip_edges().is_empty():
		definition.dressing_scene_path = map_scene_path
	definition.sky_preset_id = sky_preset_id
	definition.sky_time_of_day = sky_time_of_day
	definition.sky_weather = sky_weather
	definition.sky_top_color = sky_top_color
	definition.sky_horizon_color = sky_horizon_color
	definition.sky_cloud_amount = sky_cloud_amount
	definition.sky_cloud_speed = sky_cloud_speed
	definition.sky_haze_amount = sky_haze_amount
	definition.sky_light_energy = sky_light_energy
	definition.ground_size = ground_size
	definition.ground_color = ground_color
	definition.ground_texture_path = ground_texture_path
	definition.ground_shader_path = ground_shader_path
	if not audio_ids.is_empty():
		definition.audio_ids = audio_ids.duplicate(true)

func _apply_mode_fields(definition: TrackDefinition, mode_id: String, mode_config: Dictionary) -> void:
	definition.set_meta("track_map_id", id)
	definition.set_meta("track_mode_id", mode_id)
	definition.set_meta("track_mode_kind", str(mode_config.get("kind", mode_id)))
	definition.set_meta("road_source", str(mode_config.get("road_source", "auto")))
	if mode_config.has("id"):
		definition.id = str(mode_config.get("id", definition.id))
	if mode_config.has("display_name"):
		definition.display_name = str(mode_config.get("display_name", definition.display_name))
	if mode_config.has("version"):
		definition.version = str(mode_config.get("version", definition.version))
	if mode_config.has("runtime_scene_path"):
		definition.runtime_scene_path = str(mode_config.get("runtime_scene_path", definition.runtime_scene_path))
	elif mode_config.has("scene_path"):
		definition.runtime_scene_path = str(mode_config.get("scene_path", definition.runtime_scene_path))
	if mode_config.has("map_scene_path"):
		definition.dressing_scene_path = str(mode_config.get("map_scene_path", definition.dressing_scene_path))
	if mode_config.has("dressing_scene_path"):
		definition.dressing_scene_path = str(mode_config.get("dressing_scene_path", definition.dressing_scene_path))
	if mode_config.has("laps"):
		definition.laps = int(mode_config.get("laps", definition.laps))
	if mode_config.has("road_visual_style"):
		definition.road_visual_style = str(mode_config.get("road_visual_style", definition.road_visual_style))
	if mode_config.has("road_width"):
		definition.road_width = float(mode_config.get("road_width", definition.road_width))
	if mode_config.has("reset_mode"):
		definition.reset_mode = str(mode_config.get("reset_mode", definition.reset_mode))

func _normalize_mode_id(mode_id: String) -> String:
	var normalized := mode_id.strip_edges().to_lower()
	if normalized.is_empty():
		normalized = default_mode_id.strip_edges().to_lower()
	return "race" if normalized.is_empty() else normalized
