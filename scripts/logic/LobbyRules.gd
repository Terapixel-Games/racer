extends Resource

const PHASE_LOBBY := "lobby"
const PHASE_STARTING := "starting"
const PHASE_CLOSED := "closed"

static func reset_countdown_on_join(countdown:float, phase:String, reset_threshold:float, reset_value:float) -> float:
	if phase != PHASE_LOBBY:
		return countdown
	if countdown > 0.0 and countdown < reset_threshold:
		return reset_value
	return countdown

static func allow_join(phase:String) -> bool:
	return phase == PHASE_LOBBY

static func tick_countdown(countdown:float, delta:float, humans:int, phase:String) -> Dictionary:
	var next_phase := phase
	var ready_to_start := false
	var new_countdown := countdown
	if phase != PHASE_LOBBY:
		return {"countdown": countdown, "phase": phase, "ready_to_start": false}
	if humans <= 0:
		return {"countdown": countdown, "phase": phase, "ready_to_start": false}
	new_countdown = max(0.0, countdown - delta)
	if new_countdown <= 0.0:
		next_phase = PHASE_STARTING
		ready_to_start = true
	return {"countdown": new_countdown, "phase": next_phase, "ready_to_start": ready_to_start}
