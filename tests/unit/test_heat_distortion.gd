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
