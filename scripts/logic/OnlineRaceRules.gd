extends RefCounted
class_name OnlineRaceRules

const SCHEMA_VERSION := 1
const MODE_SINGLE_RACE := "single_race"
const MODE_TOURNAMENT := "tournament"
const RACE_MODE_ONLINE_SINGLE := "online_single"
const RACE_MODE_ONLINE_TOURNAMENT := "online_tournament"
const TOURNAMENT_ROUND_COUNT := 4
const POINTS_BY_PLACE := [15, 12, 10, 8, 6, 4, 2, 1]

static func normalize_mode(mode: String) -> String:
	var normalized := mode.strip_edges().to_lower()
	if normalized in [MODE_TOURNAMENT, RACE_MODE_ONLINE_TOURNAMENT]:
		return MODE_TOURNAMENT
	return MODE_SINGLE_RACE

static func race_mode_for_online_mode(mode: String) -> String:
	return RACE_MODE_ONLINE_TOURNAMENT if normalize_mode(mode) == MODE_TOURNAMENT else RACE_MODE_ONLINE_SINGLE

static func normalize_room_code(code: String) -> String:
	var out := ""
	for i in code.strip_edges().to_upper():
		var c := str(i)
		if c >= "A" and c <= "Z" or c >= "0" and c <= "9":
			out += c
	return out

static func select_track_ids(available_tracks: Array, mode: String, requested_track_id: String = "") -> Array[String]:
	var ids: Array[String] = []
	for track in available_tracks:
		if track is Dictionary:
			var track_id := str((track as Dictionary).get("id", "")).strip_edges()
			if not track_id.is_empty() and not ids.has(track_id):
				ids.append(track_id)
	if ids.is_empty():
		return []
	var requested := requested_track_id.strip_edges()
	if not requested.is_empty() and ids.has(requested):
		ids.erase(requested)
		ids.push_front(requested)
	if normalize_mode(mode) == MODE_SINGLE_RACE:
		return [ids[0]]
	return ids.slice(0, min(TOURNAMENT_ROUND_COUNT, ids.size()))

static func award_points(results: Array, existing_points: Dictionary = {}) -> Dictionary:
	var points := existing_points.duplicate(true)
	var place := 0
	for entry in results:
		if not (entry is Dictionary):
			continue
		var racer_id := str((entry as Dictionary).get("racer_id", (entry as Dictionary).get("id", ""))).strip_edges()
		if racer_id.is_empty():
			continue
		var add := int(POINTS_BY_PLACE[place]) if place < POINTS_BY_PLACE.size() else 0
		points[racer_id] = int(points.get(racer_id, 0)) + add
		place += 1
	return points

static func sorted_standings(points: Dictionary) -> Array:
	var standings := []
	for racer_id in points.keys():
		standings.append({"racer_id": str(racer_id), "points": int(points[racer_id])})
	standings.sort_custom(func(a, b):
		var ap := int((a as Dictionary).get("points", 0))
		var bp := int((b as Dictionary).get("points", 0))
		if ap == bp:
			return str((a as Dictionary).get("racer_id", "")) < str((b as Dictionary).get("racer_id", ""))
		return ap > bp
	)
	return standings

static func should_accept_progress(previous: Dictionary, incoming: Dictionary) -> bool:
	if bool(previous.get("finished", false)):
		return false
	if bool(incoming.get("finished", false)):
		return true
	var previous_progress := float(previous.get("progress", 0.0))
	var incoming_progress := float(incoming.get("progress", 0.0))
	return incoming_progress + 0.001 >= previous_progress

static func next_round_index(current_round: int, track_ids: Array) -> int:
	if track_ids.is_empty():
		return 0
	return clampi(current_round + 1, 0, track_ids.size() - 1)
