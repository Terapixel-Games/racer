extends "res://addons/gdunit4/src/core/GdUnitTestSuite.gd"
const RoomCode = preload("res://scripts/logic/RoomCode.gd")

func test_room_code_generator_length() -> void:
	var code = RoomCode.generate()
	assert_int(code.length()).is_equal(6)
	assert_bool(code.is_upper()).is_true()
