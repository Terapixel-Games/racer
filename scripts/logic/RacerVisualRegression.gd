extends RefCounted

const DETAIL_SCORE_THRESHOLD := 0.99
const FULL_SCORE_THRESHOLD := 0.99
const DEFAULT_WIDTH := 1280
const DEFAULT_HEIGHT := 720
const DEFAULT_RACERS := ["Rexx", "Moko"]
const TARGET_LEVEL_SELECT := "level_select_preview"
const TARGET_DRIVING_CAMERA := "driving_camera"

const DETAIL_CROPS := {
	"eyes": Rect2(0.40, 0.16, 0.20, 0.18),
	"face_teeth": Rect2(0.35, 0.22, 0.30, 0.23),
	"decals": Rect2(0.32, 0.39, 0.36, 0.20),
	"tire_treads": Rect2(0.19, 0.47, 0.62, 0.26),
}

static func capture_targets() -> Array[Dictionary]:
	return [
		{
			"id": TARGET_LEVEL_SELECT,
			"kind": "model",
			"lod": "lod0",
			"camera_position": Vector3(0.0, 1.45, 7.1),
			"camera_target": Vector3(0.0, 0.8, 0.0),
			"fov": 34.0,
			"note": "Level-select full racer preview with LOD0 detail crops.",
		},
		{
			"id": TARGET_DRIVING_CAMERA,
			"kind": "car",
			"lod": "lod0",
			"camera_position": Vector3(0.0, 2.2, 8.6),
			"camera_target": Vector3(0.0, 0.65, 0.0),
			"fov": 42.0,
			"note": "Driving-camera racer view for gameplay framing regression.",
		},
	]

static func crop_rects_for_pixels(width: int, height: int) -> Dictionary:
	var out := {}
	for crop_id in DETAIL_CROPS.keys():
		out[crop_id] = normalized_to_pixel_rect(DETAIL_CROPS[crop_id] as Rect2, width, height)
	return out

static func normalized_to_pixel_rect(rect: Rect2, width: int, height: int) -> Rect2i:
	var x := clampi(roundi(rect.position.x * width), 0, maxi(width - 1, 0))
	var y := clampi(roundi(rect.position.y * height), 0, maxi(height - 1, 0))
	var w := clampi(roundi(rect.size.x * width), 1, maxi(width - x, 1))
	var h := clampi(roundi(rect.size.y * height), 1, maxi(height - y, 1))
	return Rect2i(x, y, w, h)

static func rect_to_array(rect: Rect2i) -> Array[int]:
	return [rect.position.x, rect.position.y, rect.size.x, rect.size.y]

static func normalized_rect_to_array(rect: Rect2) -> Array[float]:
	return [rect.position.x, rect.position.y, rect.size.x, rect.size.y]
