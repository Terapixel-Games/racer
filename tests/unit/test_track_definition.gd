extends "res://tests/framework/TestCase.gd"

const TrackCatalog = preload("res://scripts/track/TrackCatalog.gd")
const TrackDefinition = preload("res://scripts/track/TrackDefinition.gd")

const ACTIVE_TRACK_IDS := [
	"kitchen",
	"bedroom",
	"sandbox",
	"garden",
	"glam_closet",
	"outdoor_playground",
	"playroom",
	"attic",
]

func test_active_toybox_definitions_validate() -> void:
	for track_id in ACTIVE_TRACK_IDS:
		var definition := TrackCatalog.get_definition(track_id)
		assert_true(definition != null, "%s definition should load" % track_id)
		assert_equal(definition.validate(), [], "%s definition should be valid" % track_id)
		assert_equal(definition.laps, 3, "%s should run 3 laps" % track_id)
		assert_true(definition.route_points.size() >= 9, "%s should expose a complete route loop" % track_id)
		assert_equal(definition.checkpoint_indices.size(), 6, "%s should expose six checkpoints" % track_id)
		assert_equal(definition.spawn_points.size(), 8, "%s should expose 8 spawn points" % track_id)
		assert_equal(definition.item_sockets.size(), 8, "%s should expose item sockets" % track_id)
		assert_equal(definition.hazard_sockets.size(), 6, "%s should expose hazard sockets" % track_id)
		assert_equal(definition.alternate_routes.size(), 1, "%s should expose one alternate route" % track_id)
		assert_equal(definition.shortcut_gates.size(), 1, "%s should expose one shortcut gate pair" % track_id)
		assert_true(definition.version.contains("_toybox_v1_2026_05_02"), "%s should use the Toybox version" % track_id)
		assert_true(_route_fits_ground_bounds(definition), "%s route should stay within authored ground bounds" % track_id)

func test_kitchen_definition_uses_new_toybox_court_landmarks() -> void:
	var definition := TrackCatalog.get_definition("kitchen")
	assert_true(_has_stage_prop(definition, "CourtStartGate"), "Kitchen should include the court start gate")
	assert_true(_has_stage_prop(definition, "SinkGauntlet"), "Kitchen should include the sink gauntlet")
	assert_true(_has_stage_prop(definition, "CuttingBoardBridge"), "Kitchen should include the cutting-board bridge")
	assert_true(_has_stage_prop(definition, "TournamentFinishArch"), "Kitchen should include the tournament finish arch")
	assert_true(_has_audio_zone(definition, "SinkSplashZone"), "Kitchen should expose the sink splash signature effect zone")

func test_bedroom_definition_preserves_tuggs_belief() -> void:
	var definition := TrackCatalog.get_definition("bedroom")
	assert_true(_has_stage_prop(definition, "WaitingLine"), "Bedroom should show toys kept ready for the family's return")
	assert_true(_has_stage_prop(definition, "ToyTriageCorner"), "Bedroom should include Tuggs' protected triage area")
	assert_true(_has_audio_zone(definition, "LampBeaconZone"), "Bedroom should expose the lamp beacon signature effect zone")

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

func test_validation_accepts_rejoining_alternate_route() -> void:
	var definition := _base_definition()
	definition.alternate_routes = [{
		"id": "inside_lane",
		"entry_checkpoint_index": 0,
		"exit_checkpoint_index": 2,
		"points": [Vector3(0, 0.5, 4), Vector3(12, 0.5, 10), Vector3(20, 0.5, 20)],
		"road_width": 8.0,
		"enabled": true,
	}]
	assert_equal(definition.validate(), [], "Rejoining alternate route should validate against shared checkpoints")

func test_validation_rejects_backtracking_alternate_route() -> void:
	var definition := _base_definition()
	definition.alternate_routes = [{
		"id": "bad_lane",
		"entry_checkpoint_index": 2,
		"exit_checkpoint_index": 1,
		"points": [Vector3(20, 0.5, 20), Vector3(20, 0.5, 0)],
	}]
	assert_true(_has_error(definition.validate(), "after entry"), "Alternate routes should rejoin at a later checkpoint")

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

func _has_stage_prop(definition: TrackDefinition, prop_id: String) -> bool:
	for prop in definition.stage_props:
		if str(prop.get("id", "")) == prop_id:
			return true
	return false

func _has_audio_zone(definition: TrackDefinition, zone_id: String) -> bool:
	for zone in definition.audio_zones:
		if str(zone.get("id", "")) == zone_id:
			return true
	return false

func _route_fits_ground_bounds(definition: TrackDefinition) -> bool:
	var half_width := definition.ground_size.x * 0.5
	var half_depth := definition.ground_size.y * 0.5
	var clearance := definition.road_width * 0.5
	for point in definition.route_points:
		if absf(point.x) + clearance > half_width:
			return false
		if absf(point.z) + clearance > half_depth:
			return false
	return true
