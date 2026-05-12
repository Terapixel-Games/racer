extends Node3D
class_name RacerSpriteLodVisual

const DEFAULT_FRAME_COUNT := 16
const DEFAULT_COLUMNS := 4
const DEFAULT_FRAME_SIZE := 256
const DEFAULT_PIXEL_SIZE := 1.75 / 256.0

var _sprite: Sprite3D
var _frame_count := DEFAULT_FRAME_COUNT

static func frame_index_for_camera(racer_transform: Transform3D, camera_position: Vector3, frame_count: int = DEFAULT_FRAME_COUNT) -> int:
	var count := maxi(frame_count, 1)
	var to_camera := camera_position - racer_transform.origin
	to_camera.y = 0.0
	if to_camera.length_squared() <= 0.0001:
		return 0
	to_camera = to_camera.normalized()
	var forward := racer_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() <= 0.0001:
		forward = Vector3.FORWARD
	else:
		forward = forward.normalized()
	var angle := atan2(forward.cross(to_camera).y, forward.dot(to_camera))
	return int(round(fposmod(angle, TAU) / TAU * float(count))) % count

static func manifest_for_path(manifest_path: String) -> Dictionary:
	var text := FileAccess.get_file_as_string(manifest_path)
	if text.is_empty():
		return {}
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Dictionary:
		return parsed as Dictionary
	return {}

func configure(texture: Texture2D, manifest: Dictionary = {}) -> void:
	_frame_count = maxi(int(manifest.get("frame_count", DEFAULT_FRAME_COUNT)), 1)
	var columns := maxi(int(manifest.get("columns", DEFAULT_COLUMNS)), 1)
	var frame_size := maxi(int(manifest.get("frame_size", DEFAULT_FRAME_SIZE)), 1)
	var rows := ceili(float(_frame_count) / float(columns))
	_sprite = Sprite3D.new()
	_sprite.name = "DirectionalSprite"
	_sprite.texture = texture
	_sprite.hframes = columns
	_sprite.vframes = rows
	_sprite.frame = 0
	_sprite.pixel_size = 1.75 / float(frame_size)
	_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_sprite.no_depth_test = false
	add_child(_sprite)

func update_for_camera(racer_transform: Transform3D, camera_position: Vector3) -> void:
	if _sprite == null:
		return
	_sprite.frame = frame_index_for_camera(racer_transform, camera_position, _frame_count)

func current_frame_for_test() -> int:
	if _sprite == null:
		return -1
	return _sprite.frame
