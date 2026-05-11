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
		var yaw_error := absf(wrapf(model.rotation_degrees.y - RacerRoster.get_racer_in_kart_yaw_degrees("Velva"), -180.0, 180.0))
		assert_true(yaw_error <= 0.1, "Meshy racer-in-kart model should be yaw-corrected to Velva's direction")
	car.queue_free()

func test_all_loaded_meshy_racer_models_use_roster_direction() -> void:
	var car_scene := load("res://scenes/Car.tscn")
	assert_true(car_scene is PackedScene, "Car scene should load")
	for racer_id in RacerRoster.select_order():
		var car := (car_scene as PackedScene).instantiate()
		scene_tree.root.add_child(car)
		var applied := (car as CarController).set_racer_visual(racer_id)
		assert_true(applied, "%s visual should apply" % racer_id)
		if (car as CarController).get_racer_visual_mode() == "model":
			var model := car.find_child("RacerInKartModel", true, false) as Node3D
			assert_true(model != null, "%s loaded Meshy model should exist" % racer_id)
			if model != null:
				var expected_yaw := RacerRoster.get_racer_in_kart_yaw_degrees(racer_id)
				var yaw_error := absf(wrapf(model.rotation_degrees.y - expected_yaw, -180.0, 180.0))
				assert_true(yaw_error <= 0.1, "%s Meshy racer-in-kart model should use the roster direction" % racer_id)
		car.queue_free()

func test_car_visual_lod_switches_by_camera_distance() -> void:
	var car_scene := load("res://scenes/Car.tscn")
	assert_true(car_scene is PackedScene, "Car scene should load")
	var car := (car_scene as PackedScene).instantiate()
	scene_tree.root.add_child(car)
	var controller := car as CarController
	assert_true(controller != null, "Car should be a CarController")
	if controller != null:
		assert_true(controller.set_racer_visual("Sir Clink"), "Car should apply LOD0 visual")
		assert_equal(controller.get_racer_visual_lod(), RacerRoster.RACER_MODEL_LOD0, "Default racer visual should use LOD0")
		controller.update_racer_visual_lod_for_camera(controller.global_transform.origin + Vector3(0, 0, 36))
		assert_equal(controller.get_racer_visual_lod(), RacerRoster.RACER_MODEL_LOD0, "Close race camera framing should keep rough LODs out of view")
		controller.update_racer_visual_lod_for_camera(controller.global_transform.origin + Vector3(0, 0, 48))
		assert_equal(controller.get_racer_visual_lod(), RacerRoster.RACER_MODEL_LOD1, "Race camera distance should switch to LOD1")
		controller.update_racer_visual_lod_for_camera(controller.global_transform.origin + Vector3(0, 0, 68))
		assert_equal(controller.get_racer_visual_lod(), RacerRoster.RACER_MODEL_LOD1, "LOD1 should hold below the conservative LOD2 threshold")
		controller.update_racer_visual_lod_for_camera(controller.global_transform.origin + Vector3(0, 0, 78))
		assert_equal(controller.get_racer_visual_lod(), RacerRoster.RACER_MODEL_LOD2, "Far race camera distance should switch to LOD2")
		controller.update_racer_visual_lod_for_camera(controller.global_transform.origin + Vector3(0, 0, 66))
		assert_equal(controller.get_racer_visual_lod(), RacerRoster.RACER_MODEL_LOD2, "LOD2 should not flicker down immediately near its entry threshold")
		controller.update_racer_visual_lod_for_camera(controller.global_transform.origin + Vector3(0, 0, 58))
		assert_equal(controller.get_racer_visual_lod(), RacerRoster.RACER_MODEL_LOD1, "LOD2 should step down once the camera is clearly back in mid-distance")
		controller.update_racer_visual_lod_for_camera(controller.global_transform.origin + Vector3(0, 0, 38))
		assert_equal(controller.get_racer_visual_lod(), RacerRoster.RACER_MODEL_LOD1, "LOD1 should not flicker down immediately near its entry threshold")
		controller.update_racer_visual_lod_for_camera(controller.global_transform.origin + Vector3(0, 0, 24))
		assert_equal(controller.get_racer_visual_lod(), RacerRoster.RACER_MODEL_LOD0, "Close camera distance should restore LOD0")
	car.queue_free()

func test_racer_visual_has_procedural_motion() -> void:
	var car_scene := load("res://scenes/Car.tscn")
	assert_true(car_scene is PackedScene, "Car scene should load")
	var car := (car_scene as PackedScene).instantiate()
	scene_tree.root.add_child(car)
	var controller := car as CarController
	assert_true(controller != null, "Car should be a CarController")
	if controller != null:
		var applied := controller.set_racer_visual("Sir Clink")
		assert_true(applied, "Car should apply a racer visual before animation")
		var root := controller.get_visual_animation_root()
		assert_true(root != null, "Racer visual should have an animation root")
		if root != null:
			var start_position := root.position
			var start_rotation := root.rotation
			controller.controlled_locally = true
			controller.velocity = Vector3(0, 0, 24)
			controller.set_input({"throttle": 1.0, "brake": 0.0, "steer": 1.0, "drift": false, "boost": false, "item_use": false})
			controller.update_visual_animation(0.1)
			var moved := root.position.distance_to(start_position) > 0.001 or root.rotation.distance_to(start_rotation) > 0.001
			assert_true(moved, "Racer visual should bob or lean while driving")
	car.queue_free()

func test_car_scene_uses_grounded_kart_physics_defaults() -> void:
	var car_scene := load("res://scenes/Car.tscn")
	assert_true(car_scene is PackedScene, "Car scene should load")
	var car := (car_scene as PackedScene).instantiate()
	scene_tree.root.add_child(car)
	var controller := car as CarController
	assert_true(controller != null, "Car should be a CarController")
	if controller != null:
		assert_true(controller.floor_snap_length >= 0.8, "Car scene should use floor snap so it stays planted")
		assert_true(controller.ground_snap_distance >= 0.8, "Controller should preserve grounded snap distance")
		assert_true(controller.tire_grip_rate > controller.drift_tire_grip_rate, "Normal tires should grip more than drift tires")
		assert_true(controller.low_speed_turn_factor < 1.0, "Low-speed steering should be limited like a kart")
	car.queue_free()
