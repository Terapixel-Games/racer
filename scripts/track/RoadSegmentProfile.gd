extends Resource
class_name RoadSegmentProfile

const DEFAULT_ID := "kenney_racing_kit"
const DEFAULT_SEGMENT_LENGTH := 16.0
const DEFAULT_MODEL_WIDTH := 1.0
const DEFAULT_MODEL_LENGTH := 2.0
const DEFAULT_MODEL_CENTER := Vector3(0.5, 0.0, -1.0)
const DEFAULT_Y_OFFSET := 0.08
const DEFAULT_TOY_ROAD_COLOR := Color(0.95, 0.36, 0.08, 1.0)

const SEGMENT_SCENES := {
	"straight": "res://assets/source/kenney/racing_kit/roadStraight.glb",
	"straight_long": "res://assets/source/kenney/racing_kit/roadStraightLong.glb",
	"corner_small": "res://assets/source/kenney/racing_kit/roadCornerSmall.glb",
	"corner_large": "res://assets/source/kenney/racing_kit/roadCornerLarge.glb",
	"corner_larger": "res://assets/source/kenney/racing_kit/roadCornerLarger.glb",
	"curved": "res://assets/source/kenney/racing_kit/roadCurved.glb",
	"start": "res://assets/source/kenney/racing_kit/roadStart.glb",
	"start_positions": "res://assets/source/kenney/racing_kit/roadStartPositions.glb",
	"ramp": "res://assets/source/kenney/racing_kit/roadRamp.glb",
	"ramp_long": "res://assets/source/kenney/racing_kit/roadRampLong.glb",
	"ramp_long_curved": "res://assets/source/kenney/racing_kit/roadRampLongCurved.glb",
	"bump": "res://assets/source/kenney/racing_kit/roadBump.glb",
	"crossing": "res://assets/source/kenney/racing_kit/roadCrossing.glb",
	"split": "res://assets/source/kenney/racing_kit/roadSplit.glb",
	"split_large": "res://assets/source/kenney/racing_kit/roadSplitLarge.glb",
	"split_larger": "res://assets/source/kenney/racing_kit/roadSplitLarger.glb",
	"side": "res://assets/source/kenney/racing_kit/roadSide.glb",
}

@export var id := DEFAULT_ID
@export var segment_length := DEFAULT_SEGMENT_LENGTH
@export var model_width := DEFAULT_MODEL_WIDTH
@export var model_length := DEFAULT_MODEL_LENGTH
@export var model_center := DEFAULT_MODEL_CENTER
@export var y_offset := DEFAULT_Y_OFFSET
@export var material_style := "toy_plastic"
@export var toy_road_color := DEFAULT_TOY_ROAD_COLOR

static func default_profile() -> RoadSegmentProfile:
	return RoadSegmentProfile.new()

func segment_path(segment_id: String) -> String:
	var normalized := segment_id.strip_edges()
	return str(SEGMENT_SCENES.get(normalized, SEGMENT_SCENES["straight_long"]))

func required_scene_paths() -> Array[String]:
	var out: Array[String] = []
	for path in SEGMENT_SCENES.values():
		out.append(str(path))
	return out

func validate() -> Array[String]:
	var errors: Array[String] = []
	if segment_length <= 0.0:
		errors.append("Segment length must be greater than zero.")
	if model_width <= 0.0:
		errors.append("Model width must be greater than zero.")
	if model_length <= 0.0:
		errors.append("Model length must be greater than zero.")
	for path in required_scene_paths():
		if not ResourceLoader.exists(path):
			errors.append("Missing Kenney Racing Kit segment scene: %s" % path)
	return errors

func road_material() -> Material:
	if material_style != "toy_plastic":
		return null
	var material := StandardMaterial3D.new()
	material.albedo_color = toy_road_color
	material.roughness = 0.46
	material.metallic = 0.0
	return material
