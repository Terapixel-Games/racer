extends "res://tests/framework/TestCase.gd"

const TrackCatalog = preload("res://scripts/track/TrackCatalog.gd")
const TrackDefinition = preload("res://scripts/track/TrackDefinition.gd")

func test_kitchen_definition_validates() -> void:
	var definition := TrackCatalog.get_definition("kitchen")
	assert_true(definition != null, "Kitchen definition should load")
	assert_equal(definition.validate(), [], "Kitchen definition should be valid")

func test_validation_rejects_missing_route() -> void:
	var definition := _base_definition()
	definition.route_points = []
	assert_true(_has_error(definition.validate(), "route"), "Missing route should be rejected")

func test_validation_rejects_missing_lap_gate() -> void:
	var definition := _base_definition()
	definition.lap_gate_checkpoint_index = 8
	assert_true(_has_error(definition.validate(), "lap gate"), "Invalid lap gate should be rejected")

func test_validation_rejects_too_few_spawns() -> void:
	var definition := _base_definition()
	definition.spawn_points = [Vector4(0, 0.8, 0, 0)]
	assert_true(_has_error(definition.validate(), "8 spawn"), "Track must require 8 spawn points")

func test_validation_rejects_off_road_spawns() -> void:
	var definition := _base_definition()
	definition.spawn_points[0] = Vector4(0, 0.8, -20, 0)
	assert_true(_has_error(definition.validate(), "outside the road"), "Track must reject spawn points outside road bounds")

func test_validation_rejects_non_monotonic_checkpoints() -> void:
	var definition := _base_definition()
	definition.checkpoint_indices = [0, 2, 1]
	assert_true(_has_error(definition.validate(), "strictly increasing"), "Checkpoints should follow route order")

func _base_definition() -> TrackDefinition:
	var definition := TrackDefinition.new()
	definition.id = "test"
	definition.display_name = "Test Track"
	definition.laps = 2
	definition.closed_loop = true
	definition.road_width = 12.0
	definition.route_points = [
		Vector3(0, 0.5, 0),
		Vector3(20, 0.5, 0),
		Vector3(20, 0.5, 20),
		Vector3(0, 0.5, 20),
	]
	definition.checkpoint_indices = [0, 1, 2]
	definition.lap_gate_checkpoint_index = 0
	definition.item_sockets = [Vector4(3, 0.8, 3, 0)]
	definition.spawn_points = [
		Vector4(0, 0.8, -2, 0),
		Vector4(2, 0.8, -2, 0),
		Vector4(4, 0.8, -2, 0),
		Vector4(6, 0.8, -2, 0),
		Vector4(0, 0.8, -5, 0),
		Vector4(2, 0.8, -5, 0),
		Vector4(4, 0.8, -5, 0),
		Vector4(6, 0.8, -5, 0),
	]
	return definition

func _has_error(errors: Array[String], needle: String) -> bool:
	for error in errors:
		if error.to_lower().contains(needle.to_lower()):
			return true
	return false
