extends "res://tests/framework/TestCase.gd"

const ARKitFaceDriverScript = preload("res://scripts/ARKitFaceDriver.gd")

func test_driver_maps_arkit_names_to_imported_blendshape_casing() -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = _mesh_with_blend_shapes(["eyeBlinkLeft", "jaw_open", "MouthSmileRight"])
	var model := Node3D.new()
	model.add_child(mesh_instance)
	var driver := ARKitFaceDriverScript.new()
	model.add_child(driver)

	assert_true(driver.bind_to_model(model), "Driver should find the first MeshInstance3D with blend shapes")
	assert_equal(driver.get_mapped_blend_shape_count(), 3, "Driver should cache all blend shape targets on the face mesh")

	var applied := driver.apply_blendshape_dictionary({
		"EyeBlinkLeft": 0.75,
		"JawOpen": 0.5,
		"mouthSmileRight": 0.25,
		"MissingShape": 1.0,
	})

	assert_equal(applied, 3, "Driver should apply only ARKit names that resolve to mesh blend shapes")
	assert_equal(mesh_instance.get_blend_shape_value(0), 0.75, "PascalCase ARKit name should map to lower-first mesh shape")
	assert_equal(mesh_instance.get_blend_shape_value(1), 0.5, "ARKit name should map to underscore mesh shape")
	assert_equal(mesh_instance.get_blend_shape_value(2), 0.25, "Lower-first ARKit name should map to matching mesh shape")
	model.queue_free()

func test_driver_ignores_models_without_blendshapes() -> void:
	var model := Node3D.new()
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = ArrayMesh.new()
	model.add_child(mesh_instance)
	var driver := ARKitFaceDriverScript.new()
	model.add_child(driver)

	assert_true(not driver.bind_to_model(model), "Driver should not attach to models without blend shapes")
	assert_equal(driver.apply_blendshape_dictionary({"JawOpen": 1.0}), 0, "Driver should no-op when no face mesh is available")
	model.queue_free()

func test_driver_prefers_named_arkit_face_proxy() -> void:
	var model := Node3D.new()
	var full_mesh := MeshInstance3D.new()
	full_mesh.name = "Mesh_0_optimized"
	full_mesh.mesh = _mesh_with_blend_shapes(["JawOpen"])
	var proxy := MeshInstance3D.new()
	proxy.name = "ARKitFaceProxy"
	proxy.mesh = _mesh_with_blend_shapes(["JawOpen"])
	model.add_child(full_mesh)
	model.add_child(proxy)
	var driver := ARKitFaceDriverScript.new()
	model.add_child(driver)

	assert_true(driver.bind_to_model(model), "Driver should bind to the authored ARKit face proxy")
	assert_equal(driver.apply_blendshape_dictionary({"JawOpen": 1.0}), 1, "Driver should apply the packet to the proxy mesh")
	assert_equal(full_mesh.get_blend_shape_value(0), 0.0, "Full model blendshapes should not be driven when ARKitFaceProxy exists")
	assert_equal(proxy.get_blend_shape_value(0), 1.0, "Named ARKitFaceProxy should receive face weights")
	model.queue_free()

func _mesh_with_blend_shapes(names: Array[String]) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	for shape_name in names:
		mesh.add_blend_shape(shape_name)

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array([
		Vector3(0.0, 0.0, 0.0),
		Vector3(1.0, 0.0, 0.0),
		Vector3(0.0, 1.0, 0.0),
	])
	var blend_arrays := []
	for _shape_name in names:
		var shape_arrays := []
		shape_arrays.resize(Mesh.ARRAY_MAX)
		shape_arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array([
			Vector3(0.0, 0.0, 0.0),
			Vector3(1.0, 0.0, 0.0),
			Vector3(0.0, 1.0, 0.0),
		])
		blend_arrays.append(shape_arrays)
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, blend_arrays)
	return mesh
