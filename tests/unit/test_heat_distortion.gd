extends "res://tests/framework/TestCase.gd"

const RaceController = preload("res://scripts/RaceController.gd")

func test_heat_distortion_full_strength_inside_stove_core() -> void:
	var sources: Array[Vector3] = [Vector3(10, -8, 20)]
	var intensity := RaceController.heat_distortion_target_intensity(Vector3(16, 3, 20), sources, 38.0, 12.0)
	assert_equal(intensity, 1.0, "Heat distortion should be full strength inside the stove core radius")

func test_heat_distortion_fades_outside_stove_radius() -> void:
	var sources: Array[Vector3] = [Vector3(10, -8, 20)]
	var near_edge := RaceController.heat_distortion_target_intensity(Vector3(35, 3, 20), sources, 38.0, 12.0)
	var outside := RaceController.heat_distortion_target_intensity(Vector3(60, 3, 20), sources, 38.0, 12.0)
	assert_true(near_edge > 0.0 and near_edge < 1.0, "Heat distortion should fade between inner and outer radius")
	assert_equal(outside, 0.0, "Heat distortion should be off outside the stove radius")

func test_heat_distortion_uses_strongest_source() -> void:
	var sources: Array[Vector3] = [Vector3(0, 0, 0), Vector3(100, 0, 0)]
	var intensity := RaceController.heat_distortion_target_intensity(Vector3(100, 25, 0), sources, 38.0, 12.0)
	assert_equal(intensity, 1.0, "Heat distortion should use the closest heat source in XZ space")

func test_sink_water_drop_intensity_uses_zone_radius() -> void:
	var zones: Array[Dictionary] = [{"position": Vector3(0, 4, 10), "radius": 20.0}]
	assert_equal(RaceController.sink_water_drop_target_intensity(Vector3(0, 2, 10), zones), 1.0, "Sink drops should be full strength in the inner splash zone")
	assert_equal(RaceController.sink_water_drop_target_intensity(Vector3(0, 2, 40), zones), 0.0, "Sink drops should turn off outside the splash zone")

func test_appliance_rumble_intensity_fades_by_distance() -> void:
	var appliances: Array[Vector3] = [Vector3(10, 0, -20)]
	var near_edge := RaceController.appliance_rumble_target_intensity(Vector3(33, 5, -20), appliances, 34.0, 13.0)
	assert_true(near_edge > 0.0 and near_edge < 1.0, "Appliance rumble should fade between inner and outer radius")
	assert_equal(RaceController.appliance_rumble_target_intensity(Vector3(50, 5, -20), appliances, 34.0, 13.0), 0.0, "Appliance rumble should stop outside the appliance radius")
