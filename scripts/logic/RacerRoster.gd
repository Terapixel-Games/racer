extends Resource

class_name RacerRoster

const ROSTER := {
	"Rexx": {
		"class": "Heavy",
		"home_course": "Sandbox",
		"motive": "Races for dominance",
		"stats": {"speed": 9, "accel": 4, "handling": 4, "weight": 10, "traction": 8, "boost": 6},
	},
	"Moko": {
		"class": "Heavy",
		"home_course": "Garden",
		"motive": "Races for the jungle",
		"stats": {"speed": 8, "accel": 4, "handling": 5, "weight": 10, "traction": 9, "boost": 5},
	},
	"Tuggs": {
		"class": "Bruiser",
		"home_course": "Bedroom",
		"motive": "Races to be the favorite",
		"stats": {"speed": 6, "accel": 6, "handling": 6, "weight": 7, "traction": 8, "boost": 6},
	},
	"Popper": {
		"class": "Bruiser",
		"home_course": "Attic",
		"motive": "Lives for chaos and tricks",
		"stats": {"speed": 7, "accel": 5, "handling": 5, "weight": 7, "traction": 7, "boost": 7},
	},
	"Sir Clink": {
		"class": "Medium",
		"home_course": "Kitchen",
		"motive": "Races for the kingdom toys",
		"stats": {"speed": 7, "accel": 6, "handling": 7, "weight": 5, "traction": 7, "boost": 6},
	},
	"Slammo": {
		"class": "Medium",
		"home_course": "Playroom",
		"motive": "He is the champ",
		"stats": {"speed": 8, "accel": 6, "handling": 6, "weight": 6, "traction": 6, "boost": 7},
	},
	"Velva": {
		"class": "Light",
		"home_course": "Glam Closet",
		"motive": "Races for glam",
		"stats": {"speed": 6, "accel": 8, "handling": 9, "weight": 3, "traction": 5, "boost": 8},
	},
	"Dash": {
		"class": "Light",
		"home_course": "Outdoor Playground",
		"motive": "Too cool for it all",
		"stats": {"speed": 8, "accel": 8, "handling": 8, "weight": 3, "traction": 6, "boost": 9},
	},
}

static func ids() -> Array[String]:
	var names: Array[String] = []
	for racer_id in ROSTER.keys():
		names.append(racer_id)
	names.sort()
	return names

static func has(racer_id: String) -> bool:
	return ROSTER.has(racer_id)

static func get_profile(racer_id: String) -> Dictionary:
	if not ROSTER.has(racer_id):
		return {}
	return (ROSTER[racer_id] as Dictionary).duplicate(true)
