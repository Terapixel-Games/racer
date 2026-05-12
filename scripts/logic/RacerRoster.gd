extends Resource

class_name RacerRoster

const SELECT_ORDER := [
	"Rexx",
	"Moko",
	"Tuggs",
	"Popper",
	"Sir Clink",
	"Slammo",
	"Velva",
	"Dash",
]

const DEFAULT_RACER_ID := "Sir Clink"
const FORWARD_AUTHORED_RACER_IN_KART_YAW_DEGREES := 0.0
const VELVA_RACER_IN_KART_YAW_DEGREES := 90.0
const RACER_ASSET_PROFILE_SETTING := "racer/assets/profile"
const RACER_ASSET_PROFILE_ENV := "RACER_ASSET_PROFILE"
const RACER_ASSET_PROFILE_SOURCE := "source"
const RACER_ASSET_PROFILE_MOBILE_DETAIL := "mobile_detail"
const RACER_ASSET_PROFILE_MOBILE_DETAIL_PHASE1 := "mobile_detail_phase1"
const DEFAULT_RACER_ASSET_PROFILE := RACER_ASSET_PROFILE_SOURCE
const RACER_MODEL_LOD0 := "lod0"
const RACER_MODEL_LOD1 := "lod1"
const RACER_MODEL_LOD2 := "lod2"
const RACER_SPRITE_LOD1_RACERS := SELECT_ORDER
const RACER_SPRITE_LOD2_RACERS := SELECT_ORDER

const ROSTER := {
	"Rexx": {
		"class": "Heavy",
		"home_course": "Sandbox",
		"motive": "Races for dominance",
		"portrait": "res://assets/ui/racers/headshots/rexx_headshot.png",
		"racer_in_kart_model": "res://assets/source/meshy/2026-04-27-character-track-batch/rexx/racer_in_kart.glb",
		"racer_in_kart_yaw_degrees": FORWARD_AUTHORED_RACER_IN_KART_YAW_DEGREES,
		"accent": Color(0.92, 0.25, 0.11, 1.0),
		"stats": {"speed": 9, "accel": 4, "handling": 4, "weight": 10, "traction": 8, "boost": 6},
	},
	"Moko": {
		"class": "Heavy",
		"home_course": "Garden",
		"motive": "Races for the jungle",
		"portrait": "res://assets/ui/racers/headshots/moko_headshot.png",
		"racer_in_kart_model": "res://assets/source/meshy/2026-04-27-character-track-batch/moko/racer_in_kart.glb",
		"racer_in_kart_yaw_degrees": FORWARD_AUTHORED_RACER_IN_KART_YAW_DEGREES,
		"accent": Color(0.2, 0.55, 0.27, 1.0),
		"stats": {"speed": 8, "accel": 4, "handling": 5, "weight": 10, "traction": 9, "boost": 5},
	},
	"Tuggs": {
		"class": "Bruiser",
		"home_course": "Bedroom",
		"motive": "Races to be the favorite",
		"portrait": "res://assets/ui/racers/headshots/tuggs_headshot.png",
		"racer_in_kart_model": "res://assets/source/meshy/2026-04-27-character-track-batch/tuggs/racer_in_kart.glb",
		"racer_in_kart_yaw_degrees": VELVA_RACER_IN_KART_YAW_DEGREES,
		"accent": Color(0.7, 0.54, 0.41, 1.0),
		"stats": {"speed": 6, "accel": 6, "handling": 6, "weight": 7, "traction": 8, "boost": 6},
	},
	"Popper": {
		"class": "Bruiser",
		"home_course": "Attic",
		"motive": "Lives for chaos and tricks",
		"portrait": "res://assets/ui/racers/headshots/popper_headshot.png",
		"racer_in_kart_model": "res://assets/source/meshy/2026-04-27-character-track-batch/popper/racer_in_kart.glb",
		"racer_in_kart_yaw_degrees": FORWARD_AUTHORED_RACER_IN_KART_YAW_DEGREES,
		"accent": Color(0.48, 0.24, 0.82, 1.0),
		"stats": {"speed": 7, "accel": 5, "handling": 5, "weight": 7, "traction": 7, "boost": 7},
	},
	"Sir Clink": {
		"class": "Medium",
		"home_course": "Kitchen",
		"motive": "Races for the kingdom toys",
		"portrait": "res://assets/ui/racers/headshots/sir_clink_headshot.png",
		"racer_in_kart_model": "res://assets/source/meshy/2026-04-27-character-track-batch/sir_clink/racer_in_kart.glb",
		"racer_in_kart_yaw_degrees": VELVA_RACER_IN_KART_YAW_DEGREES,
		"accent": Color(0.9, 0.72, 0.19, 1.0),
		"stats": {"speed": 7, "accel": 6, "handling": 7, "weight": 5, "traction": 7, "boost": 6},
	},
	"Slammo": {
		"class": "Medium",
		"home_course": "Playroom",
		"motive": "He is the champ",
		"portrait": "res://assets/ui/racers/headshots/slammo_headshot.png",
		"racer_in_kart_model": "res://assets/source/meshy/2026-04-27-character-track-batch/slammo/racer_in_kart.glb",
		"racer_in_kart_yaw_degrees": FORWARD_AUTHORED_RACER_IN_KART_YAW_DEGREES,
		"accent": Color(0.86, 0.16, 0.21, 1.0),
		"stats": {"speed": 8, "accel": 6, "handling": 6, "weight": 6, "traction": 6, "boost": 7},
	},
	"Velva": {
		"class": "Light",
		"home_course": "Glam Closet",
		"motive": "Races for glam",
		"portrait": "res://assets/ui/racers/headshots/velva_headshot.png",
		"racer_in_kart_model": "res://assets/source/meshy/2026-04-27-character-track-batch/velva/racer_in_kart.glb",
		"racer_in_kart_yaw_degrees": VELVA_RACER_IN_KART_YAW_DEGREES,
		"accent": Color(0.9, 0.42, 0.7, 1.0),
		"stats": {"speed": 6, "accel": 8, "handling": 9, "weight": 3, "traction": 5, "boost": 8},
	},
	"Dash": {
		"class": "Light",
		"home_course": "Outdoor Playground",
		"motive": "Too cool for it all",
		"portrait": "res://assets/ui/racers/headshots/dash_headshot.png",
		"racer_in_kart_model": "res://assets/source/meshy/2026-04-27-character-track-batch/dash/racer_in_kart.glb",
		"racer_in_kart_yaw_degrees": VELVA_RACER_IN_KART_YAW_DEGREES,
		"accent": Color(0.16, 0.55, 0.86, 1.0),
		"stats": {"speed": 8, "accel": 8, "handling": 8, "weight": 3, "traction": 6, "boost": 9},
	},
}

static func ids() -> Array[String]:
	var names: Array[String] = []
	for racer_id in ROSTER.keys():
		names.append(racer_id)
	names.sort()
	return names

static func select_order() -> Array[String]:
	var order: Array[String] = []
	for racer_id in SELECT_ORDER:
		order.append(racer_id)
	return order

static func has(racer_id: String) -> bool:
	return ROSTER.has(racer_id)

static func normalize_id(racer_id: String) -> String:
	var trimmed := racer_id.strip_edges()
	if ROSTER.has(trimmed):
		return trimmed
	return DEFAULT_RACER_ID

static func normalize_asset_profile(profile: String) -> String:
	var trimmed := profile.strip_edges()
	if trimmed in [
		RACER_ASSET_PROFILE_SOURCE,
		RACER_ASSET_PROFILE_MOBILE_DETAIL,
		RACER_ASSET_PROFILE_MOBILE_DETAIL_PHASE1,
	]:
		return trimmed
	return DEFAULT_RACER_ASSET_PROFILE

static func normalize_model_lod(lod: String) -> String:
	var trimmed := lod.strip_edges().to_lower()
	if trimmed in [RACER_MODEL_LOD0, RACER_MODEL_LOD1, RACER_MODEL_LOD2]:
		return trimmed
	return RACER_MODEL_LOD0

static func get_racer_asset_profile() -> String:
	var env_profile := OS.get_environment(RACER_ASSET_PROFILE_ENV).strip_edges()
	if not env_profile.is_empty():
		return normalize_asset_profile(env_profile)
	if ProjectSettings.has_setting(RACER_ASSET_PROFILE_SETTING):
		return normalize_asset_profile(str(ProjectSettings.get_setting(RACER_ASSET_PROFILE_SETTING, DEFAULT_RACER_ASSET_PROFILE)))
	return DEFAULT_RACER_ASSET_PROFILE

static func get_profile(racer_id: String) -> Dictionary:
	if not ROSTER.has(racer_id):
		return {}
	return (ROSTER[racer_id] as Dictionary).duplicate(true)

static func get_racer_in_kart_model_path(racer_id: String) -> String:
	return get_racer_in_kart_model_path_for_profile(racer_id, get_racer_asset_profile(), true)

static func get_racer_in_kart_model_path_for_lod(racer_id: String, lod: String, allow_source_fallback: bool = true) -> String:
	return get_racer_in_kart_model_path_for_profile_lod(racer_id, get_racer_asset_profile(), lod, allow_source_fallback)

static func get_racer_sprite_sheet_path(racer_id: String, lod: String, asset_profile: String = "") -> String:
	var normalized := normalize_id(racer_id)
	var normalized_lod := normalize_model_lod(lod)
	var normalized_profile := normalize_asset_profile(asset_profile if not asset_profile.strip_edges().is_empty() else get_racer_asset_profile())
	if not has_sprite_lod(normalized, normalized_lod, normalized_profile):
		return ""
	var slug := _racer_asset_slug(normalized)
	return "res://assets/optimized/racers/%s/%s_racer_in_kart_%s_%s_sprites.png" % [slug, slug, normalized_profile, normalized_lod]

static func get_racer_sprite_manifest_path(racer_id: String, lod: String, asset_profile: String = "") -> String:
	var sheet_path := get_racer_sprite_sheet_path(racer_id, lod, asset_profile)
	return sheet_path.replace(".png", ".json") if not sheet_path.is_empty() else ""

static func has_sprite_lod(racer_id: String, lod: String, asset_profile: String = "") -> bool:
	var normalized := normalize_id(racer_id)
	var normalized_lod := normalize_model_lod(lod)
	var normalized_profile := normalize_asset_profile(asset_profile if not asset_profile.strip_edges().is_empty() else get_racer_asset_profile())
	if normalized_profile != RACER_ASSET_PROFILE_MOBILE_DETAIL_PHASE1:
		return false
	if normalized_lod == RACER_MODEL_LOD1:
		return normalized in RACER_SPRITE_LOD1_RACERS
	if normalized_lod == RACER_MODEL_LOD2:
		return normalized in RACER_SPRITE_LOD2_RACERS
	return false

static func get_racer_lod2_sprite_sheet_path(racer_id: String, asset_profile: String = "") -> String:
	return get_racer_sprite_sheet_path(racer_id, RACER_MODEL_LOD2, asset_profile)

static func get_racer_lod2_sprite_manifest_path(racer_id: String, asset_profile: String = "") -> String:
	return get_racer_sprite_manifest_path(racer_id, RACER_MODEL_LOD2, asset_profile)

static func has_sprite_lod2(racer_id: String, asset_profile: String = "") -> bool:
	return has_sprite_lod(racer_id, RACER_MODEL_LOD2, asset_profile)

static func get_racer_in_kart_source_model_path(racer_id: String) -> String:
	var normalized := normalize_id(racer_id)
	var profile := get_profile(normalized)
	return str(profile.get("racer_in_kart_model", ""))

static func get_racer_in_kart_model_path_for_profile(racer_id: String, asset_profile: String, allow_source_fallback: bool = true) -> String:
	return get_racer_in_kart_model_path_for_profile_lod(racer_id, asset_profile, RACER_MODEL_LOD0, allow_source_fallback)

static func get_racer_in_kart_model_path_for_profile_lod(racer_id: String, asset_profile: String, lod: String, allow_source_fallback: bool = true) -> String:
	var normalized := normalize_id(racer_id)
	var normalized_profile := normalize_asset_profile(asset_profile)
	var normalized_lod := normalize_model_lod(lod)
	var source_path := get_racer_in_kart_source_model_path(normalized)
	if normalized_profile == RACER_ASSET_PROFILE_SOURCE:
		return source_path
	var optimized_path := _optimized_racer_in_kart_model_path(normalized, normalized_profile, normalized_lod)
	if allow_source_fallback and (optimized_path.is_empty() or not ResourceLoader.exists(optimized_path)):
		if normalized_lod != RACER_MODEL_LOD0:
			var lod0_path := _optimized_racer_in_kart_model_path(normalized, normalized_profile, RACER_MODEL_LOD0)
			if not lod0_path.is_empty() and ResourceLoader.exists(lod0_path):
				return lod0_path
		return source_path
	return optimized_path

static func _optimized_racer_in_kart_model_path(racer_id: String, asset_profile: String, lod: String = RACER_MODEL_LOD0) -> String:
	var slug := _racer_asset_slug(racer_id)
	if slug.is_empty():
		return ""
	var lod_suffix := ""
	if normalize_model_lod(lod) != RACER_MODEL_LOD0:
		lod_suffix = "_%s" % normalize_model_lod(lod)
	return "res://assets/optimized/racers/%s/%s_racer_in_kart_%s%s.glb" % [slug, slug, asset_profile, lod_suffix]

static func _racer_asset_slug(racer_id: String) -> String:
	return normalize_id(racer_id).to_lower().replace(" ", "_")

static func get_racer_in_kart_yaw_degrees(racer_id: String) -> float:
	var normalized := normalize_id(racer_id)
	var profile := get_profile(normalized)
	return float(profile.get("racer_in_kart_yaw_degrees", VELVA_RACER_IN_KART_YAW_DEGREES))

static func get_portrait_path(racer_id: String) -> String:
	var normalized := normalize_id(racer_id)
	var profile := get_profile(normalized)
	return str(profile.get("portrait", ""))
