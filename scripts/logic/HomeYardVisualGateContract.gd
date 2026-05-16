extends RefCounted

const MAP_ID := "home_yard_v3"
const REVIEW_TEMPLATE_PATH := "res://docs/validation/home_yard_v3/screenshot_reviews/_template.md"

const REQUIRED_PUBLIC_COURSES := [
	"attic",
	"bedroom",
	"glam_closet",
	"playroom",
	"outdoor_playground",
	"garden",
	"sandbox",
]

const REQUIRED_THIRD_PERSON_VIEW_IDS := [
	"start_grid",
	"third_person_launch",
	"first_turn_chase",
	"camera_clearance",
	"overhead_route",
]

const REQUIRED_ROUTE_SAMPLE_RATIOS := [0.25, 0.5, 0.75]
const INDOOR_TRACK_IDS := [
	"attic",
	"bedroom",
	"glam_closet",
	"kitchen",
	"playroom",
]
const REQUIRED_GATE_CLASSES := [
	"third_person_route_obstruction",
	"route_readability",
	"route_containment",
]

const CENTRAL_OCCLUSION_FAIL_RATIO := 0.35
const MINIMUM_REVIEW_SCORE := 4
const CHASE_CAMERA_DISTANCE := 3.75
const CHASE_CAMERA_HEIGHT := 1.35
const CHASE_CAMERA_LOOK_HEIGHT := 0.8
const OUTDOOR_LEVEL_SELECT_BACKYARD_Z_OFFSET_MIN := 140.0

static func required_view_ids() -> Array[String]:
	var out: Array[String] = []
	for view_id in REQUIRED_THIRD_PERSON_VIEW_IDS:
		out.append(str(view_id))
	for ratio in REQUIRED_ROUTE_SAMPLE_RATIOS:
		out.append("route_sample_%d" % int(float(ratio) * 100.0))
	return out

static func review_categories() -> Array[String]:
	return [
		"third_person_camera_clearance",
		"central_view_occlusion",
		"road_visibility",
		"next_turn_readability",
		"route_corridor_clearance",
		"collision_risk",
		"visual_confusion",
	]

static func gate_metadata(view_id: String) -> Dictionary:
	var gate_class := "route_readability"
	if view_id in ["third_person_launch", "first_turn_chase", "camera_clearance"]:
		gate_class = "third_person_route_obstruction"
	elif view_id == "overhead_route":
		gate_class = "route_containment"
	return {
		"gate_class": gate_class,
		"manual_review_required": true,
		"minimum_review_score": MINIMUM_REVIEW_SCORE,
		"central_occlusion_fail_ratio": CENTRAL_OCCLUSION_FAIL_RATIO,
		"review_categories": review_categories(),
	}

static func is_indoor_track_id(track_id: String) -> bool:
	return INDOOR_TRACK_IDS.has(track_id)

static func level_select_camera_position(track_id: String, center: Vector3, size: Vector3) -> Vector3:
	if is_indoor_track_id(track_id):
		return center + Vector3(
			minf(size.x * 0.32 + 42.0, 128.0),
			46.0,
			minf(size.z * 0.28 + 38.0, 86.0)
		)
	if track_id == "outdoor_playground":
		return center + Vector3(
			-(size.x * 0.32 + 72.0),
			104.0,
			-maxf(size.z * 0.46 + 92.0, OUTDOOR_LEVEL_SELECT_BACKYARD_Z_OFFSET_MIN + 30.0)
		)
	return center + Vector3(
		size.x * 0.42 + 86.0,
		76.0,
		-maxf(size.z * 0.46 + 92.0, OUTDOOR_LEVEL_SELECT_BACKYARD_Z_OFFSET_MIN)
	)
