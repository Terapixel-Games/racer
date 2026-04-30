local nk = require("nakama")
local tracks = require("tracks")

local OP = {
	RACE_INPUT = 10,
	RACE_SNAPSHOT = 11,
	RACE_RESET = 12,
	RACE_WASTED = 13,
	RACE_FINISH = 14,
	RACE_MATCH_END = 15,
}

local GAME_ID = "circuit-collapse-racer"
local SNAPSHOT_HZ = 15
local BEHIND_THRESHOLD = 3
local BEHIND_SECONDS_TO_WASTED = 6
local MAX_RACERS = 8

local DEFAULT_ROUTE = {
	{0, 0.5, 60},
	{75, 0.5, 0},
	{0, 0.5, -60},
	{-75, 0.5, 0},
}

local M = {}

local function point_from_array(value)
	if type(value) ~= "table" then
		return {x = 0, y = 0.5, z = 0}
	end
	return {
		x = value.x or value[1] or 0,
		y = value.y or value[2] or 0.5,
		z = value.z or value[3] or 0,
	}
end

local ensure_track_state

local function normalize_route_points(list)
	local out = {}
	for _, point in ipairs(list or {}) do
		table.insert(out, point_from_array(point))
	end
	if #out < 2 then
		out = {}
		for _, point in ipairs(DEFAULT_ROUTE) do
			table.insert(out, point_from_array(point))
		end
	end
	return out
end

local function normalize_branch_points(list)
	local out = {}
	for _, point in ipairs(list or {}) do
		table.insert(out, point_from_array(point))
	end
	return out
end

local function normalize_alternate_routes(list)
	local out = {}
	for _, route in ipairs(list or {}) do
		if type(route) == "table" then
			table.insert(out, {
				id = route.id or "alternate",
				points = normalize_branch_points(route.points or {}),
				entry_checkpoint_index = route.entry_checkpoint_index or 0,
				exit_checkpoint_index = route.exit_checkpoint_index or 0,
				road_width = route.road_width,
				enabled = route.enabled ~= false,
			})
		end
	end
	return out
end

local function distance(a, b)
	local dx = (a.x or 0) - (b.x or 0)
	local dy = (a.y or 0) - (b.y or 0)
	local dz = (a.z or 0) - (b.z or 0)
	return math.sqrt(dx * dx + dy * dy + dz * dz)
end

local function route_length(points, closed_loop)
	if #points < 2 then return 0 end
	local total = 0
	for i = 1, #points - 1 do
		total = total + distance(points[i], points[i + 1])
	end
	if closed_loop and #points > 2 then
		total = total + distance(points[#points], points[1])
	end
	return total
end

local function project_position(points, position, closed_loop)
	if #points < 2 then
		return {distance = 0, route_ratio = 0, segment_index = 1, segment_ratio = 0, closest_point = {x = 0, y = 0.5, z = 0}}
	end
	local best_dist_sq = math.huge
	local best_along = 0
	local best_segment = 1
	local best_ratio = 0
	local best_point = points[1]
	local accumulated = 0
	local segment_count = (closed_loop and #points > 2) and #points or (#points - 1)
	for i = 1, segment_count do
		local a = points[i]
		local b = points[(i % #points) + 1]
		local abx = b.x - a.x
		local aby = b.y - a.y
		local abz = b.z - a.z
		local len_sq = abx * abx + aby * aby + abz * abz
		if len_sq > 0.0001 then
			local apx = position.x - a.x
			local apy = position.y - a.y
			local apz = position.z - a.z
			local ratio = (apx * abx + apy * aby + apz * abz) / len_sq
			ratio = math.max(0, math.min(1, ratio))
			local px = a.x + abx * ratio
			local py = a.y + aby * ratio
			local pz = a.z + abz * ratio
			local dx = position.x - px
			local dy = position.y - py
			local dz = position.z - pz
			local dist_sq = dx * dx + dy * dy + dz * dz
			local seg_len = math.sqrt(len_sq)
			if dist_sq < best_dist_sq then
				best_dist_sq = dist_sq
				best_along = accumulated + seg_len * ratio
				best_segment = i
				best_ratio = ratio
				best_point = {x = px, y = py, z = pz}
			end
			accumulated = accumulated + seg_len
		end
	end
	local total = math.max(route_length(points, closed_loop), 0.001)
	return {
		distance = best_along,
		route_ratio = best_along / total,
		segment_index = best_segment,
		segment_ratio = best_ratio,
		closest_point = best_point,
		distance_sq = best_dist_sq,
	}
end

local function distance_at_route_index(points, route_index)
	if #points < 2 then return 0 end
	local clamped = math.max(0, math.min(route_index or 0, #points - 1))
	local total = 0
	for i = 1, clamped do
		total = total + distance(points[i], points[i + 1])
	end
	return total
end

local function project_route_network(state, position)
	ensure_track_state(state)
	local canonical = project_position(state.route_points, position, state.closed_loop)
	canonical.route_id = "main"
	canonical.is_alternate = false
	local best = canonical
	local best_distance_sq = canonical.distance_sq or math.huge
	local total = math.max(state.route_length or route_length(state.route_points, state.closed_loop), 0.001)
	for _, route in ipairs(state.alternate_routes or {}) do
		if route.enabled ~= false and #route.points >= 2 then
			local entry_checkpoint = route.entry_checkpoint_index or -1
			local exit_checkpoint = route.exit_checkpoint_index or -1
			local entry = state.track.checkpoints[entry_checkpoint + 1]
			local exit = state.track.checkpoints[exit_checkpoint + 1]
			if entry and exit then
				local entry_distance = distance_at_route_index(state.route_points, entry.route_index or 0)
				local exit_distance = distance_at_route_index(state.route_points, exit.route_index or 0)
				if exit_distance <= entry_distance and state.closed_loop then
					exit_distance = exit_distance + total
				end
				if exit_distance > entry_distance then
					local projection = project_position(route.points, position, false)
					local distance_sq = projection.distance_sq or math.huge
					if distance_sq < best_distance_sq then
						local branch_ratio = math.max(0, math.min(1, projection.route_ratio or 0))
						local mapped = entry_distance + (exit_distance - entry_distance) * branch_ratio
						while mapped >= total do mapped = mapped - total end
						projection.distance = mapped
						projection.route_ratio = mapped / total
						projection.route_id = route.id or "alternate"
						projection.is_alternate = true
						projection.entry_checkpoint_index = entry_checkpoint
						projection.exit_checkpoint_index = exit_checkpoint
						best = projection
						best_distance_sq = distance_sq
					end
				end
			end
		end
	end
	return best
end

local function checkpoint_position(state, checkpoint)
	local route_index = (checkpoint.route_index or 0) + 1
	local route_point = state.route_points[route_index]
	if route_point then
		return route_point
	end
	return point_from_array(checkpoint.position)
end

ensure_track_state = function(state)
	state.route_points = normalize_route_points(state.track.route_points or state.track.waypoints)
	state.alternate_routes = normalize_alternate_routes(state.track.alternate_routes or {})
	state.closed_loop = state.track.closed_loop ~= false
	state.checkpoint_radius = state.track.checkpoint_radius or math.max((state.track.road_width or 12) * 0.65, 4)
	state.out_of_bounds_y = state.track.out_of_bounds_y or -100
	state.reset_mode = state.track.reset_mode or ""
	if not state.track.checkpoints or #state.track.checkpoints == 0 then
		state.track.checkpoints = {}
		for i, _ in ipairs(state.route_points) do
			table.insert(state.track.checkpoints, {index = i - 1, route_index = i - 1, is_lap_gate = i == 1})
		end
	end
	state.checkpoints = #state.track.checkpoints
	state.lap_gate_checkpoint_index = state.track.lap_gate_checkpoint_index or 0
	state.route_length = state.track.route_length or route_length(state.route_points, state.closed_loop)
end

local function route_yaw_for_index(state, route_index)
	ensure_track_state(state)
	if #state.route_points < 2 then return 0 end
	local index = math.max(0, math.min(route_index or 0, #state.route_points - 1))
	local current = state.route_points[index + 1]
	local next_point = state.route_points[((index + 1) % #state.route_points) + 1]
	return math.atan2(next_point.x - current.x, next_point.z - current.z)
end

local function reset_pose_for_racer(racer, state)
	ensure_track_state(state)
	if racer.last_safe_checkpoint ~= nil then
		local checkpoint = state.track.checkpoints[(racer.last_safe_checkpoint or 0) + 1]
		if checkpoint then
			local pos = checkpoint_position(state, checkpoint)
			return {
				x = pos.x,
				y = pos.y + 1.0,
				z = pos.z,
				yaw = route_yaw_for_index(state, checkpoint.route_index or 0),
			}
		end
	end
	local spawn = racer.spawn or state.spawns[1] or {x = 0, y = 0.8, z = 0, yaw = 0}
	return {x = spawn.x or 0, y = spawn.y or 0.8, z = spawn.z or 0, yaw = spawn.yaw or 0}
end

local update_progress

local function reset_if_out_of_bounds(racer, state, dispatcher)
	if racer.finished or racer.wasted then
		return false
	end
	ensure_track_state(state)
	if state.reset_mode ~= "instant_pop" then
		return false
	end
	if (racer.pos.y or 0) >= state.out_of_bounds_y then
		return false
	end
	local pose = reset_pose_for_racer(racer, state)
	racer.pos = {x = pose.x, y = pose.y, z = pose.z}
	racer.rot = {0, pose.yaw or 0, 0}
	racer.input = {throttle = 0, brake = 0, steer = 0, drift = false, boost = false}
	racer.behind_timer = 0
	update_progress(racer, state)
	dispatcher.broadcast_message(OP.RACE_RESET, nk.json_encode({
		player_id = racer.id,
		position = {racer.pos.x, racer.pos.y, racer.pos.z},
		rotation = racer.rot,
	}))
	return true
end

update_progress = function(racer, state)
	ensure_track_state(state)
	local projection = project_route_network(state, racer.pos)
	local route_ratio = math.max(0, math.min(0.999, projection.route_ratio or 0))
	racer.progress = (math.max(racer.lap, 1) - 1) * state.checkpoints + racer.checkpoint + route_ratio
	if racer.finished then
		racer.progress = state.laps * state.checkpoints + 1 + route_ratio
	end
end

local function advance_checkpoints(racer, state)
	if racer.finished or racer.wasted then
		return
	end
	ensure_track_state(state)
	local expected = racer.checkpoint or 0
	local checkpoint = state.track.checkpoints[expected + 1]
	if not checkpoint then
		return
	end
	local target = checkpoint_position(state, checkpoint)
	if distance(racer.pos, target) > state.checkpoint_radius then
		return
	end
	if expected == state.lap_gate_checkpoint_index then
		racer.lap_gate = true
	end
	racer.last_safe_checkpoint = expected
	racer.checkpoint = (expected + 1) % state.checkpoints
	if racer.checkpoint == 0 and racer.lap_gate then
		racer.lap = racer.lap + 1
		racer.lap_gate = false
	end
	if racer.lap > state.laps then
		racer.finished = true
		if not racer.finish_time then
			racer.finish_time = state.elapsed
		end
	end
end

local function new_racer(id, is_ai, spawn)
	return {
		id = id,
		is_ai = is_ai,
		pos = {
			x = (spawn and spawn.x) or 0,
			y = (spawn and spawn.y) or 0.8,
			z = (spawn and spawn.z) or 0,
		},
		rot = {0, (spawn and spawn.yaw) or 0, 0},
		lap = 1,
		checkpoint = 0,
		lap_gate = false,
		wasted = false,
		finished = false,
		finish_time = nil,
		behind_timer = 0,
		input = {throttle = 0, brake = 0, steer = 0, drift = false, boost = false},
		progress = 0,
		waypoint = 1,
		spawn = spawn,
		last_safe_checkpoint = nil,
	}
end

local function add_ai_racers(state)
	local ai_needed = MAX_RACERS - #state.roster
	for i = 1, ai_needed do
		local id = "ai_" .. i
		local spawn = state.spawns[(#state.racers % #state.spawns) + 1]
		table.insert(state.racers, new_racer(id, true, spawn))
	end
end

local function decode_json(data)
	if not data or data == "" then return {} end
	local ok, out = pcall(nk.json_decode, data)
	if not ok then return {} end
	return out
end

local function find_racer(state, user_id)
	for _, r in ipairs(state.racers) do
		if r.id == user_id then
			return r
		end
	end
	return nil
end

local function apply_input(racer, delta, state, dispatcher)
	if racer.finished or racer.wasted then
		return
	end
	local input = racer.input or {}
	if type(input.position) == "table" then
		racer.pos = point_from_array(input.position)
	else
		local speed = ((input.throttle or 0) * 22 - (input.brake or 0) * 12) * delta
		local yaw = racer.rot[2] or 0
		racer.pos.x = racer.pos.x + math.sin(yaw) * speed
		racer.pos.z = racer.pos.z + math.cos(yaw) * speed
	end
	if type(input.rotation) == "table" then
		racer.rot = {
			input.rotation[1] or 0,
			input.rotation[2] or 0,
			input.rotation[3] or 0,
		}
	end
	if reset_if_out_of_bounds(racer, state, dispatcher) then
		return
	end
	advance_checkpoints(racer, state)
	update_progress(racer, state)
end

local function ai_tick(racer, delta, state, dispatcher)
	if racer.finished or racer.wasted then
		return
	end
	ensure_track_state(state)
	if #state.route_points == 0 then
		return
	end
	if racer.waypoint < 1 or racer.waypoint > #state.route_points then
		racer.waypoint = 1
	end
	local target = state.route_points[racer.waypoint]
	local dx = target.x - racer.pos.x
	local dz = target.z - racer.pos.z
	local dist = math.sqrt(dx * dx + dz * dz)
	if dist > 0.001 then
		racer.rot = {0, math.atan2(dx, dz), 0}
	end
	if dist < 2.0 then
		racer.waypoint = racer.waypoint + 1
		if racer.waypoint > #state.route_points then
			racer.waypoint = 1
		end
		target = state.route_points[racer.waypoint]
		dx = target.x - racer.pos.x
		dz = target.z - racer.pos.z
		dist = math.sqrt(dx * dx + dz * dz)
	end
	if dist > 0.001 then
		local inv = 1 / dist
		dx = dx * inv
		dz = dz * inv
	end
	local move_speed = 24
	racer.pos.x = racer.pos.x + dx * move_speed * delta
	racer.pos.z = racer.pos.z + dz * move_speed * delta
	racer.pos.y = target.y or racer.pos.y
	if reset_if_out_of_bounds(racer, state, dispatcher) then
		return
	end
	advance_checkpoints(racer, state)
	update_progress(racer, state)
end

local function broadcast_snapshot(dispatcher, state)
	local racers = {}
	for _, r in ipairs(state.racers) do
		table.insert(racers, {
			id = r.id,
			pos = {r.pos.x, r.pos.y, r.pos.z},
			rot = r.rot,
			lap = r.lap,
			checkpoint = r.checkpoint,
			wasted = r.wasted,
			finished = r.finished,
			finish_time = r.finish_time,
			progress = r.progress,
		})
	end
	dispatcher.broadcast_message(OP.RACE_SNAPSHOT, nk.json_encode({
		track_id = state.track.id,
		racers = racers,
		checkpoints = state.checkpoints,
	}))
end

local function evaluate_wasted(dispatcher, state, delta)
	local leader = 0
	for _, r in ipairs(state.racers) do
		if not r.wasted then
			if r.progress > leader then leader = r.progress end
		end
	end
	for _, r in ipairs(state.racers) do
		if not r.wasted and not r.finished then
			if leader - r.progress >= BEHIND_THRESHOLD then
				r.behind_timer = r.behind_timer + delta
				if r.behind_timer >= BEHIND_SECONDS_TO_WASTED then
					r.wasted = true
					dispatcher.broadcast_message(OP.RACE_WASTED, nk.json_encode({player_id = r.id}))
				end
			else
				r.behind_timer = 0
			end
		end
	end
end

local function spawn_from_track_entry(entry)
	if type(entry) == "table" and entry.position then
		local p = point_from_array(entry.position)
		return {x = p.x, y = p.y, z = p.z, yaw = math.rad(entry.yaw_degrees or 0)}
	end
	return {
		x = entry and entry[1] or 0,
		y = entry and entry[2] or 0.8,
		z = entry and entry[3] or 0,
		yaw = math.rad(entry and entry[4] or 0),
	}
end

function M.match_init(context, params)
	local track = params.track or tracks.get("kitchen")
	local spawns = {}
	for _, s in ipairs(track.spawn_points or {}) do
		table.insert(spawns, spawn_from_track_entry(s))
	end
	if #spawns == 0 then
		table.insert(spawns, {x = 0, y = 0.8, z = 0, yaw = 0})
	end
	local state = {
		room_code = params.room_code or "AUTO",
		roster = params.roster or {},
		racers = {},
		elapsed = 0,
		snapshot_accum = 0,
		tickrate = 10,
		track = track,
		route_points = normalize_route_points(track.route_points or track.waypoints),
		checkpoints = #(track.checkpoints or {}),
		spawns = spawns,
		laps = track.laps or 2,
		closed_loop = track.closed_loop ~= false,
		lap_gate_checkpoint_index = track.lap_gate_checkpoint_index or 0,
	}
	ensure_track_state(state)
	for _, id in ipairs(state.roster) do
		local spawn = spawns[(#state.racers % #spawns) + 1]
		table.insert(state.racers, new_racer(id, false, spawn))
	end
	add_ai_racers(state)
	for _, r in ipairs(state.racers) do
		update_progress(r, state)
	end
	local label = nk.json_encode({game_id = GAME_ID, type = "race", room_code = state.room_code, track_id = track.id})
	return state, state.tickrate, label
end

function M.match_join_attempt(context, dispatcher, tick, state, presence, metadata)
	for _, id in ipairs(state.roster) do
		if id == presence.user_id then
			return state, true
		end
	end
	return state, false, "late_join"
end

function M.match_join(context, dispatcher, tick, state, presences)
	return state
end

function M.match_leave(context, dispatcher, tick, state, presences)
	return state
end

function M.match_loop(context, dispatcher, tick, state, messages)
	local delta = 1 / state.tickrate
	for _, m in ipairs(messages) do
		if m.op_code == OP.RACE_INPUT then
			local data = decode_json(m.data)
			local racer = find_racer(state, m.sender.user_id)
			if racer then
				racer.input = data.input or racer.input
			end
		end
	end

	for _, r in ipairs(state.racers) do
		if r.is_ai then
			ai_tick(r, delta, state, dispatcher)
		else
			apply_input(r, delta, state, dispatcher)
		end
	end

	evaluate_wasted(dispatcher, state, delta)

	state.elapsed = state.elapsed + delta
	state.snapshot_accum = state.snapshot_accum + delta
	if state.snapshot_accum >= (1 / SNAPSHOT_HZ) then
		state.snapshot_accum = 0
		broadcast_snapshot(dispatcher, state)
	end

	local all_done = true
	for _, r in ipairs(state.racers) do
		if not r.finished and not r.wasted then
			all_done = false
		end
	end
	if all_done then
		dispatcher.broadcast_message(OP.RACE_MATCH_END, nk.json_encode({results = state.racers}))
		return nil
	end
	return state
end

function M.match_terminate(context, dispatcher, tick, state, grace)
	return nil
end

function M.match_signal(context, dispatcher, tick, state, data)
	return state
end

return M
