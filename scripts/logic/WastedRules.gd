extends Resource

class_name WastedRules

var timer : float = 0.0
var wasted : bool = false

func update(leader_progress:float, racer_progress:float, delta:float, gap_threshold:float, seconds_to_wasted:float) -> bool:
	if wasted:
		return true
	if leader_progress - racer_progress >= gap_threshold:
		timer += delta
	else:
		timer = 0.0
	if timer >= seconds_to_wasted:
		wasted = true
	return wasted
