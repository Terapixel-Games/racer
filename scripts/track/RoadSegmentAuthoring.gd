@tool
extends Node3D
class_name RoadSegmentAuthoring

const RoadSegmentProfile = preload("res://scripts/track/RoadSegmentProfile.gd")
const TrackSegmentRoadBuilder = preload("res://scripts/track/TrackSegmentRoadBuilder.gd")

@export var segment_id := "straight_long":
	set(value):
		segment_id = value
		_refresh_preview()
@export var segment_length := 16.0:
	set(value):
		segment_length = maxf(value, 0.1)
		_refresh_preview()
@export var pitch_degrees := 0.0:
	set(value):
		pitch_degrees = value
		_refresh_preview()
@export var road_width_override := 0.0:
	set(value):
		road_width_override = maxf(value, 0.0)
		_refresh_preview()
@export var role_tags: Array[String] = []:
	set(value):
		role_tags = value
@export var preview_enabled := true:
	set(value):
		preview_enabled = value
		_refresh_preview()

func _ready() -> void:
	_refresh_preview()

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		_refresh_preview()

func to_road_segment(default_road_width := 12.0) -> Dictionary:
	var resolved_transform := global_transform if is_inside_tree() else _local_scene_transform()
	var yaw := rad_to_deg(resolved_transform.basis.get_euler().y)
	return {
		"segment_id": segment_id,
		"position": resolved_transform.origin,
		"yaw_degrees": yaw,
		"pitch_degrees": pitch_degrees,
		"length": segment_length,
		"road_width": road_width_override if road_width_override > 0.0 else default_road_width,
		"roles": role_tags.duplicate(),
	}

func _local_scene_transform() -> Transform3D:
	var resolved := transform
	var current := get_parent()
	while current != null and current is Node3D:
		resolved = (current as Node3D).transform * resolved
		current = current.get_parent()
	return resolved

func _refresh_preview() -> void:
	if not Engine.is_editor_hint():
		return
	if not is_inside_tree():
		return
	var existing := get_node_or_null("SegmentPreview")
	if existing:
		existing.queue_free()
	if not preview_enabled:
		return
	var profile := RoadSegmentProfile.default_profile()
	var width := road_width_override if road_width_override > 0.0 else 12.0
	var preview := TrackSegmentRoadBuilder.build_segment_road([], width, false, [_local_preview_segment(width)], profile)
	preview.name = "SegmentPreview"
	preview.owner = null
	add_child(preview)

func _local_preview_segment(default_road_width: float) -> Dictionary:
	return {
		"segment_id": segment_id,
		"position": Vector3.ZERO,
		"yaw_degrees": 0.0,
		"pitch_degrees": pitch_degrees,
		"length": segment_length,
		"road_width": road_width_override if road_width_override > 0.0 else default_road_width,
		"roles": role_tags.duplicate(),
	}
