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
