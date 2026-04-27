extends "res://tests/framework/TestCase.gd"

const ItemRules = preload("res://scripts/logic/ItemRules.gd")

func test_front_positions_favor_cleaner_tools() -> void:
	var weights := ItemRules.weights_for_position(1, 8)
	assert_true(weights[ItemRules.ITEM_BOOST] > weights[ItemRules.ITEM_INVINCIBILITY], "Leaders should see Boost more often than Invincibility")
	assert_true(weights[ItemRules.ITEM_BUBBLE] > weights[ItemRules.ITEM_JACKS], "Leaders should see Bubble more often than Jacks")

func test_back_positions_favor_comeback_items() -> void:
	var weights := ItemRules.weights_for_position(8, 8)
	assert_true(weights[ItemRules.ITEM_INVINCIBILITY] > weights[ItemRules.ITEM_BOOST], "Back markers should see Invincibility more often than Boost")
	assert_true(weights[ItemRules.ITEM_SIGNATURE] > weights[ItemRules.ITEM_BUBBLE], "Back markers should see Signature more often than Bubble")

func test_roll_returns_known_item() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var rolled := ItemRules.roll_for_position(4, 8, rng)
	assert_true(ItemRules.MID_WEIGHTS.has(rolled), "Item roll should come from the approved pool")
