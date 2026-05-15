extends RefCounted
class_name NavigationFlow

const TrackCatalog = preload("res://scripts/track/TrackCatalog.gd")
const RacerRoster = preload("res://scripts/logic/RacerRoster.gd")
const OnlineRaceRules = preload("res://scripts/logic/OnlineRaceRules.gd")

const KEY_NAV_FLOW_MODE := "nav_flow_mode"
const KEY_RACE_FLOW := "race_flow"
const KEY_RACE_MODE := "race_mode"
const KEY_SELECTED_RACER_ID := "selected_racer_id"
const KEY_TRACK_ID := "track_id"
const KEY_TRACK_RECIPE := "track_recipe"
const KEY_RACE_MATCH_ID := "race_match_id"
const KEY_TOURNAMENT_TRACK_IDS := "tournament_track_ids"
const KEY_TOURNAMENT_ROUND_INDEX := "tournament_round_index"
const KEY_TOURNAMENT_POINTS := "tournament_points"
const KEY_TOURNAMENT_STANDINGS := "tournament_standings"
const KEY_PLACEHOLDER_ENDING_ID := "placeholder_ending_id"
const KEY_PLACEHOLDER_ENDING_TYPE := "placeholder_ending_type"
const KEY_PLAYER_TOURNAMENT_RANK := "player_tournament_rank"

const FLOW_SINGLE_RACE := "single_race"
const FLOW_TOURNAMENT := "tournament"
const RACE_FLOW_SINGLE_MULTIPLAYER := "single_multiplayer"
const RACE_FLOW_TOURNAMENT_MULTIPLAYER := "tournament_multiplayer"
const RACE_MODE_LOCAL_SINGLE := "local_single"
const RACE_MODE_LOCAL_TOURNAMENT := "local_tournament"
const RACE_MODE_HOME_FREE_ROAM := "home_free_roam"
const RACE_MODE_ONLINE_SINGLE := OnlineRaceRules.RACE_MODE_ONLINE_SINGLE
const RACE_MODE_ONLINE_TOURNAMENT := OnlineRaceRules.RACE_MODE_ONLINE_TOURNAMENT
const LOCAL_SINGLE_MATCH_ID := "local-single-race"
const LOCAL_TOURNAMENT_MATCH_ID := "local-tournament-race"
const HOME_FREE_ROAM_MATCH_ID := "home-free-roam"
const HOME_FREE_ROAM_MAP_ID := "home_yard_v3"
const HOME_FREE_ROAM_TRACK_ID := "kitchen"

const WIN_PLACEHOLDER_SCENE := "res://scenes/endings/WinPlaceholderEnding.tscn"
const LOSS_PLACEHOLDER_SCENE := "res://scenes/endings/FrontDoorLossPlaceholder.tscn"
const POINTS_BY_PLACE := [15, 12, 10, 8, 6, 4, 2, 1]
const TOURNAMENT_ROUND_COUNT := 4

static func set_nav_flow_mode(service: Node, mode: String) -> void:
	_set_meta(service, KEY_NAV_FLOW_MODE, mode)

static func clear_nav_flow_mode(service: Node) -> void:
	_set_meta(service, KEY_NAV_FLOW_MODE, "")

static func get_nav_flow_mode(service: Node) -> String:
	return str(_get_meta(service, KEY_NAV_FLOW_MODE, ""))

static func prepare_single_multiplayer(service: Node) -> void:
	_set_meta(service, KEY_RACE_FLOW, RACE_FLOW_SINGLE_MULTIPLAYER)
	_set_meta(service, KEY_RACE_MODE, RACE_MODE_ONLINE_SINGLE)
	_set_meta(service, "online_mode", OnlineRaceRules.MODE_SINGLE_RACE)
	_set_meta(service, KEY_RACE_MATCH_ID, "")

static func prepare_tournament_multiplayer(service: Node) -> void:
	_set_meta(service, KEY_RACE_FLOW, RACE_FLOW_TOURNAMENT_MULTIPLAYER)
	_set_meta(service, KEY_RACE_MODE, RACE_MODE_ONLINE_TOURNAMENT)
	_set_meta(service, "online_mode", OnlineRaceRules.MODE_TOURNAMENT)
	_set_meta(service, KEY_RACE_MATCH_ID, "")

static func prepare_local_single_track(service: Node, track_id: String) -> void:
	_set_meta(service, KEY_TRACK_ID, track_id)
	_set_meta(service, KEY_TRACK_RECIPE, TrackCatalog.get_metadata(track_id))
	_set_meta(service, KEY_RACE_MATCH_ID, LOCAL_SINGLE_MATCH_ID)
	_set_meta(service, KEY_RACE_MODE, RACE_MODE_LOCAL_SINGLE)

static func prepare_home_free_roam(service: Node, map_id: String = HOME_FREE_ROAM_MAP_ID) -> void:
	var resolved_track_id := HOME_FREE_ROAM_TRACK_ID
	if map_id.strip_edges().to_lower() != HOME_FREE_ROAM_MAP_ID:
		resolved_track_id = TrackCatalog.get_default_track_id()
	_set_meta(service, KEY_NAV_FLOW_MODE, FLOW_SINGLE_RACE)
	_set_meta(service, KEY_TRACK_ID, resolved_track_id)
	_set_meta(service, KEY_TRACK_RECIPE, TrackCatalog.get_metadata(resolved_track_id))
	_set_meta(service, "track_map_id", map_id)
	_set_meta(service, "home_free_roam_spawn_id", "front_foyer")
	_set_meta(service, KEY_RACE_MATCH_ID, HOME_FREE_ROAM_MATCH_ID)
	_set_meta(service, KEY_RACE_MODE, RACE_MODE_HOME_FREE_ROAM)

static func prepare_local_tournament(service: Node, rng: RandomNumberGenerator = null, first_track_id: String = "") -> Array[String]:
	var track_ids := random_tournament_track_ids(rng, first_track_id)
	_set_meta(service, KEY_RACE_MODE, RACE_MODE_LOCAL_TOURNAMENT)
	_set_meta(service, KEY_NAV_FLOW_MODE, FLOW_TOURNAMENT)
	_set_meta(service, KEY_RACE_MATCH_ID, LOCAL_TOURNAMENT_MATCH_ID)
	_set_meta(service, KEY_TOURNAMENT_TRACK_IDS, track_ids)
	_set_meta(service, KEY_TOURNAMENT_ROUND_INDEX, 0)
	_set_meta(service, KEY_TOURNAMENT_POINTS, {})
	if not track_ids.is_empty():
		_apply_tournament_track(service, track_ids[0])
	return track_ids

static func random_tournament_track_ids(rng: RandomNumberGenerator = null, first_track_id: String = "") -> Array[String]:
	var ids: Array[String] = []
	for track in TrackCatalog.list_tracks():
		if track is Dictionary:
			var track_id := str((track as Dictionary).get("id", "")).strip_edges()
			if track_id != "":
				ids.append(track_id)
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	for index in range(ids.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var temp := ids[index]
		ids[index] = ids[swap_index]
		ids[swap_index] = temp
	var requested := first_track_id.strip_edges()
	if requested != "" and ids.has(requested):
		ids.erase(requested)
		ids.push_front(requested)
	return ids.slice(0, min(TOURNAMENT_ROUND_COUNT, ids.size()))

static func award_tournament_points(service: Node, results: Array) -> Dictionary:
	var points: Dictionary = _get_meta(service, KEY_TOURNAMENT_POINTS, {})
	if not (points is Dictionary):
		points = {}
	var place := 0
	for entry in results:
		if not (entry is Dictionary):
			continue
		var racer_id := str((entry as Dictionary).get("racer_id", (entry as Dictionary).get("id", "")))
		if racer_id == "":
			continue
		var add := int(POINTS_BY_PLACE[place]) if place < POINTS_BY_PLACE.size() else 0
		points[racer_id] = int(points.get(racer_id, 0)) + add
		place += 1
	_set_meta(service, KEY_TOURNAMENT_POINTS, points)
	_set_meta(service, KEY_TOURNAMENT_STANDINGS, sorted_standings(points))
	return points

static func sorted_standings(points: Dictionary) -> Array:
	var standings := []
	for racer_id in points.keys():
		standings.append({"racer_id": str(racer_id), "points": int(points[racer_id])})
	standings.sort_custom(func(a, b):
		var a_points := int(a.get("points", 0))
		var b_points := int(b.get("points", 0))
		if a_points == b_points:
			return str(a.get("racer_id", "")) < str(b.get("racer_id", ""))
		return a_points > b_points
	)
	return standings

static func get_tournament_round_index(service: Node) -> int:
	return int(_get_meta(service, KEY_TOURNAMENT_ROUND_INDEX, 0))

static func get_tournament_track_ids(service: Node) -> Array:
	var track_ids = _get_meta(service, KEY_TOURNAMENT_TRACK_IDS, [])
	return track_ids if track_ids is Array else []

static func has_next_tournament_round(service: Node) -> bool:
	return get_tournament_round_index(service) + 1 < get_tournament_track_ids(service).size()

static func advance_tournament_round(service: Node) -> bool:
	var track_ids := get_tournament_track_ids(service)
	var next_index := get_tournament_round_index(service) + 1
	if next_index >= track_ids.size():
		return false
	_set_meta(service, KEY_TOURNAMENT_ROUND_INDEX, next_index)
	_set_meta(service, KEY_RACE_MODE, RACE_MODE_LOCAL_TOURNAMENT)
	_set_meta(service, KEY_RACE_MATCH_ID, LOCAL_TOURNAMENT_MATCH_ID)
	_apply_tournament_track(service, str(track_ids[next_index]))
	return true

static func resolve_placeholder_ending(service: Node) -> String:
	var standings := sorted_standings(_get_meta(service, KEY_TOURNAMENT_POINTS, {}))
	var selected := RacerRoster.normalize_id(str(_get_meta(service, KEY_SELECTED_RACER_ID, RacerRoster.DEFAULT_RACER_ID)))
	var rank := 0
	for index in range(standings.size()):
		if str((standings[index] as Dictionary).get("racer_id", "")) == selected:
			rank = index + 1
			break
	if rank <= 0:
		rank = standings.size() + 1
	var won := rank == 1
	_set_meta(service, KEY_PLAYER_TOURNAMENT_RANK, rank)
	_set_meta(service, KEY_PLACEHOLDER_ENDING_TYPE, "win" if won else "loss")
	_set_meta(service, KEY_PLACEHOLDER_ENDING_ID, "%s_win_placeholder" % selected.to_snake_case() if won else "generic_front_door_loss_placeholder")
	return WIN_PLACEHOLDER_SCENE if won else LOSS_PLACEHOLDER_SCENE

static func _apply_tournament_track(service: Node, track_id: String) -> void:
	_set_meta(service, KEY_TRACK_ID, track_id)
	_set_meta(service, KEY_TRACK_RECIPE, TrackCatalog.get_metadata(track_id))

static func _set_meta(service: Node, key: String, value: Variant) -> void:
	if service != null and service.has_method("set_meta_value"):
		service.call("set_meta_value", key, value)

static func _get_meta(service: Node, key: String, default_value: Variant) -> Variant:
	if service != null and service.has_method("get_meta_value"):
		return service.call("get_meta_value", key, default_value)
	return default_value
