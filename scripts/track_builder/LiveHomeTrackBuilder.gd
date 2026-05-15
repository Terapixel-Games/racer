extends Node3D
class_name LiveHomeTrackBuilder

const PlayerTrackBuild = preload("res://scripts/track_builder/PlayerTrackBuild.gd")
const PlayerTrackBuildRules = preload("res://scripts/track_builder/PlayerTrackBuildRules.gd")

signal build_changed(summary: Dictionary)
signal race_promotion_changed(summary: Dictionary)

@export var owner_user_id := ""
@export var home_map_id := "home_yard_v3"
@export var enabled := false

var build: PlayerTrackBuild
var selected_piece_id := PlayerTrackBuildRules.PIECE_STRAIGHT
var yaw_steps := 0
var overlay: Node3D = null
var protected_zones: Array[Dictionary] = []

func _ready() -> void:
	if build == null:
		build = PlayerTrackBuildRules.empty_build(owner_user_id, home_map_id)
	_refresh_overlay()

func set_build(source: PlayerTrackBuild) -> void:
	build = source if source != null else PlayerTrackBuildRules.empty_build(owner_user_id, home_map_id)
	_refresh_overlay()

func toggle_enabled() -> bool:
	enabled = not enabled
	return enabled

func set_selected_piece(piece_id: String) -> void:
	var normalized := piece_id.strip_edges().to_lower()
	if PlayerTrackBuildRules.allowed_piece_ids().has(normalized):
		selected_piece_id = normalized

func rotate_selection(step_delta := 1) -> void:
	yaw_steps = posmod(yaw_steps + step_delta, 4)

func place_at_world(world_position: Vector3) -> Dictionary:
	var cell := PlayerTrackBuildRules.snapped_cell(world_position)
	return place_at_cell(cell)

func place_at_cell(cell: Vector3i) -> Dictionary:
	var piece := PlayerTrackBuildRules.add_or_replace_piece(build, {
		"piece_id": selected_piece_id,
		"cell": cell,
		"yaw_steps": yaw_steps,
	})
	_refresh_overlay()
	return piece

func remove_at_world(world_position: Vector3) -> bool:
	return remove_at_cell(PlayerTrackBuildRules.snapped_cell(world_position))

func remove_at_cell(cell: Vector3i) -> bool:
	var removed := PlayerTrackBuildRules.remove_piece_at_cell(build, cell)
	if removed:
		_refresh_overlay()
	return removed

func validate_navigation() -> Dictionary:
	var result := PlayerTrackBuildRules.validate_navigation(build, protected_zones)
	emit_signal("build_changed", _summary(result))
	return result

func validate_race() -> Dictionary:
	var result := PlayerTrackBuildRules.validate_race(build, protected_zones)
	emit_signal("race_promotion_changed", _summary(result))
	return result

func promoted_track_definition(options: Dictionary = {}) -> TrackDefinition:
	return PlayerTrackBuildRules.promote_to_track_definition(build, options)

func build_payload() -> Dictionary:
	validate_navigation()
	validate_race()
	return build.to_payload()

func _refresh_overlay() -> void:
	if overlay != null and overlay.get_parent() != null:
		overlay.get_parent().remove_child(overlay)
		overlay.queue_free()
	overlay = PlayerTrackBuildRules.build_overlay_node(build)
	add_child(overlay)
	var validation := validate_navigation()
	emit_signal("build_changed", _summary(validation))

func _summary(result: Dictionary) -> Dictionary:
	return {
		"enabled": enabled,
		"piece_count": build.pieces.size() if build != null else 0,
		"selected_piece_id": selected_piece_id,
		"yaw_steps": yaw_steps,
		"navigation_status": build.navigation_status if build != null else "unchecked",
		"race_status": build.race_status if build != null else "unchecked",
		"errors": result.get("errors", []),
	}
