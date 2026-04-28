extends RefCounted
class_name OutOfBoundsRules

const RESET_INSTANT_POP := "instant_pop"

static func should_reset(position_y: float, out_of_bounds_y: float, reset_mode: String) -> bool:
	return reset_mode == RESET_INSTANT_POP and position_y < out_of_bounds_y
