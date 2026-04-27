extends Resource

class_name ItemRules

const ITEM_BOOST := "Boost"
const ITEM_INVINCIBILITY := "Invincibility"
const ITEM_SIGNATURE := "Signature Token"
const ITEM_JACKS := "Jacks"
const ITEM_MARBLE := "Marble"
const ITEM_BUBBLE := "Bubble"

const FRONT_WEIGHTS := {
	ITEM_BOOST: 36,
	ITEM_BUBBLE: 24,
	ITEM_MARBLE: 16,
	ITEM_JACKS: 10,
	ITEM_INVINCIBILITY: 6,
	ITEM_SIGNATURE: 8,
}

const MID_WEIGHTS := {
	ITEM_BOOST: 22,
	ITEM_BUBBLE: 18,
	ITEM_MARBLE: 20,
	ITEM_JACKS: 18,
	ITEM_INVINCIBILITY: 10,
	ITEM_SIGNATURE: 12,
}

const BACK_WEIGHTS := {
	ITEM_BOOST: 18,
	ITEM_BUBBLE: 14,
	ITEM_MARBLE: 16,
	ITEM_JACKS: 10,
	ITEM_INVINCIBILITY: 22,
	ITEM_SIGNATURE: 20,
}

static func weights_for_position(position: int, total_racers: int) -> Dictionary:
	var capped_total: int = max(total_racers, 1)
	if position <= min(2, capped_total):
		return FRONT_WEIGHTS.duplicate()
	if position >= max(1, capped_total - 2):
		return BACK_WEIGHTS.duplicate()
	return MID_WEIGHTS.duplicate()

static func roll_for_position(position: int, total_racers: int, rng: RandomNumberGenerator) -> String:
	var weights: Dictionary = weights_for_position(position, total_racers)
	var total_weight: int = 0
	for value in weights.values():
		total_weight += int(value)
	if total_weight <= 0:
		return ITEM_BOOST
	var roll: int = rng.randi_range(1, total_weight)
	var running: int = 0
	for item_name in weights.keys():
		running += int(weights[item_name])
		if roll <= running:
			return String(item_name)
	return ITEM_BOOST
