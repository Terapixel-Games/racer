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
const VELVA_RACER_IN_KART_YAW_DEGREES := 90.0

const ROSTER := {
	"Rexx": {
		"class": "Heavy",
		"home_course": "Sandbox",
		"motive": "Races for dominance",
		"portrait": "res://assets/ui/racers/headshots/rexx_headshot.png",
		"racer_in_kart_model": "res://assets/source/meshy/2026-04-27-character-track-batch/rexx/racer_in_kart.glb",
		"racer_in_kart_yaw_degrees": VELVA_RACER_IN_KART_YAW_DEGREES,
		"accent": Color(0.92, 0.25, 0.11, 1.0),
		"stats": {"speed": 9, "accel": 4, "handling": 4, "weight": 10, "traction": 8, "boost": 6},
	},
	"Moko": {
		"class": "Heavy",
		"home_course": "Garden",
		"motive": "Races for the jungle",
		"portrait": "res://assets/ui/racers/headshots/moko_headshot.png",
		"racer_in_kart_model": "res://assets/source/meshy/2026-04-27-character-track-batch/moko/racer_in_kart.glb",
		"racer_in_kart_yaw_degrees": VELVA_RACER_IN_KART_YAW_DEGREES,
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
		"racer_in_kart_yaw_degrees": VELVA_RACER_IN_KART_YAW_DEGREES,
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
		"racer_in_kart_yaw_degrees": VELVA_RACER_IN_KART_YAW_DEGREES,
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

static func get_profile(racer_id: String) -> Dictionary:
	if not ROSTER.has(racer_id):
		return {}
	return (ROSTER[racer_id] as Dictionary).duplicate(true)

static func get_racer_in_kart_model_path(racer_id: String) -> String:
	var normalized := normalize_id(racer_id)
	var profile := get_profile(normalized)
	return str(profile.get("racer_in_kart_model", ""))

static func get_racer_in_kart_yaw_degrees(racer_id: String) -> float:
	var normalized := normalize_id(racer_id)
	var profile := get_profile(normalized)
	return float(profile.get("racer_in_kart_yaw_degrees", VELVA_RACER_IN_KART_YAW_DEGREES))

static func get_portrait_path(racer_id: String) -> String:
	var normalized := normalize_id(racer_id)
	var profile := get_profile(normalized)
	return str(profile.get("portrait", ""))
