extends "res://tests/framework/TestCase.gd"

func test_car_can_swap_to_selected_racer_visual() -> void:
	var car_scene := load("res://scenes/Car.tscn")
	assert_true(car_scene is PackedScene, "Car scene should load")
	var car := (car_scene as PackedScene).instantiate()
	scene_tree.root.add_child(car)
	assert_true(car is CarController, "Car scene should instantiate a CarController")
	var applied := (car as CarController).set_racer_visual("Sir Clink")
	assert_true(applied, "Car should apply a selected racer visual")
	assert_equal((car as CarController).get_racer_visual_id(), "Sir Clink", "Car should remember the active racer visual")
	assert_true((car as CarController).get_racer_visual_mode() in ["model", "portrait"], "Car should use either a Meshy model or portrait fallback")
	assert_true((car as CarController).has_racer_visual(), "Car should have a spawned visual model")
	car.queue_free()

func test_car_reads_selected_racer_metadata_when_spawned() -> void:
	NakamaService.set_meta_value("selected_racer_id", "Sir Clink")
	var car_scene := load("res://scenes/Car.tscn")
	assert_true(car_scene is PackedScene, "Car scene should load")
	var car := (car_scene as PackedScene).instantiate()
	scene_tree.root.add_child(car)
	assert_equal((car as CarController).get_racer_visual_id(), "Sir Clink", "Spawned car should use selected racer metadata")
	assert_true((car as CarController).has_racer_visual(), "Spawned car should display a selected racer visual")
	car.queue_free()

func test_valid_meshy_racer_model_faces_car_forward() -> void:
	var car_scene := load("res://scenes/Car.tscn")
	assert_true(car_scene is PackedScene, "Car scene should load")
	var car := (car_scene as PackedScene).instantiate()
	scene_tree.root.add_child(car)
	var applied := (car as CarController).set_racer_visual("Velva")
	assert_true(applied, "Velva visual should apply")
	assert_equal((car as CarController).get_racer_visual_mode(), "model", "Velva should use a loaded Meshy model for orientation coverage")
	var model := car.find_child("RacerInKartModel", true, false) as Node3D
	assert_true(model != null, "Loaded Meshy model should exist")
	if model != null:
		var yaw_error := absf(wrapf(model.rotation_degrees.y - 90.0, -180.0, 180.0))
		assert_true(yaw_error <= 0.1, "Meshy racer-in-kart model should be yaw-corrected to car forward")
	car.queue_free()
