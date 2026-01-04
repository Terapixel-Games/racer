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
local DEFAULT_WAYPOINTS = {
	{x = 0, y = 0.5, z = 60},
	{x = 75, y = 0.5, z = 0},
	{x = 0, y = 0.5, z = -60},
	{x = -75, y = 0.5, z = 0},
}

local M = {}
local function normalize_waypoints(list)
	local out = {}
	for _, w in ipairs(list or {}) do
		if type(w) == "table" then
			if w.x ~= nil and w.y ~= nil and w.z ~= nil then
				table.insert(out, {x = w.x, y = w.y, z = w.z})
			elseif #w >= 3 then
				table.insert(out, {x = w[1], y = w[2], z = w[3]})
			end
		end
	end
	if #out == 0 then
		out = DEFAULT_WAYPOINTS
	end
	return out
end

local function ensure_waypoints(state)
	state.waypoints = normalize_waypoints(state.waypoints)
	if not state.checkpoints or state.checkpoints <= 0 then
		state.checkpoints = #state.waypoints
	end
end

local function new_racer(id, is_ai, spawn)
	return {
		id = id,
		is_ai = is_ai,
		pos = {
			x = (spawn and spawn.x) or 0,
			y = (spawn and spawn.y) or 0.5,
			z = (spawn and spawn.z) or 0,
		},
		rot = {0, (spawn and spawn.yaw) or 0, 0},
		lap = 1,
		checkpoint = 0,
		lap_gate = false,
		wasted = false,
		finished = false,
		behind_timer = 0,
		input = {throttle = 0, brake = 0, steer = 0, drift = false, boost = false},
		progress = 0,
		waypoint = 1,
	}
end

local function add_ai_racers(state)
	local ai_needed = MAX_RACERS - #state.roster
	for i = 1, ai_needed do
		local id = "ai_" .. i
		local spawn = state.spawns[(#state.racers % #state.spawns) + 1]
		local racer = new_racer(id, true, spawn)
		table.insert(state.racers, racer)
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

local function update_progress(racer, state)
	racer.progress = (racer.lap - 1) * state.checkpoints + racer.checkpoint
end

local function apply_input(racer, delta, state)
	ensure_waypoints(state)
	local speed = racer.input.throttle * 10 - racer.input.brake * 8
	racer.pos.z = racer.pos.z - speed * delta
	if racer.pos.z < -state.checkpoints * 50 then
		if racer.lap_gate then
			racer.lap = racer.lap + 1
			racer.lap_gate = false
		end
		racer.pos.z = 0
	end
	local checkpoint_index = math.floor(math.abs(racer.pos.z) / 50) % state.checkpoints
	if checkpoint_index == racer.checkpoint then
		if checkpoint_index == 1 then
			racer.lap_gate = true
		end
		racer.checkpoint = (racer.checkpoint + 1) % state.checkpoints
	end
	if racer.lap > state.laps then
		racer.finished = true
	end
	update_progress(racer, state)
end

local function ai_tick(racer, delta, state)
	ensure_waypoints(state)
	if #state.waypoints == 0 then
		return
	 end
	if racer.waypoint < 1 or racer.waypoint > #state.waypoints then
		racer.waypoint = 1
	end
	-- Follow the center-line waypoints around the oval.
	local target = state.waypoints[racer.waypoint]
	if not target then return end
	local dx = target.x - racer.pos.x
	local dz = target.z - racer.pos.z
	local dist = math.sqrt(dx * dx + dz * dz)
	-- Rotate to face the target (Car forward uses +Z/basis.z).
	if dist > 0.001 then
		local yaw = math.atan2(dx, dz)
		racer.rot = {0, yaw, 0}
	end
	-- Advance to next waypoint when close enough.
	if dist < 1.5 then
		racer.waypoint = racer.waypoint + 1
		if racer.waypoint > #state.waypoints then
			racer.waypoint = 1
			if racer.lap <= state.laps then
				racer.lap = racer.lap + 1
			end
		end
		target = state.waypoints[racer.waypoint]
		dx = target.x - racer.pos.x
		dz = target.z - racer.pos.z
		dist = math.sqrt(dx * dx + dz * dz)
	end
	if dist > 0.001 then
		local inv = 1 / dist
		dx = dx * inv
		dz = dz * inv
	end
	local move_speed = 26 -- units per second around the course center-line
	racer.pos.x = racer.pos.x + dx * move_speed * delta
	racer.pos.z = racer.pos.z + dz * move_speed * delta
	racer.pos.y = 0.5
	-- checkpoint index mirrors waypoint index
	racer.checkpoint = (racer.waypoint - 1) % state.checkpoints
	if racer.lap > state.laps then
		racer.finished = true
	end
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
		})
	end
	dispatcher.broadcast_message(OP.RACE_SNAPSHOT, nk.json_encode({racers = racers}))
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

function M.match_init(context, params)
	local track = params.track or tracks.get("oval")
	local waypoints = track.waypoints or DEFAULT_WAYPOINTS
	local spawns = {}
	for _, s in ipairs(track.spawn_points or {}) do
		table.insert(spawns, {
			x = s[1] or 0,
			y = s[2] or 0.5,
			z = s[3] or 0,
			yaw = s[4] and math.rad(s[4]) or 0,
		})
	end
	if #spawns == 0 then
		table.insert(spawns, {x = 0, y = 0.5, z = 0, yaw = 0})
	end
	local state = {
		room_code = params.room_code or "AUTO",
		roster = params.roster or {},
		racers = {},
		elapsed = 0,
		snapshot_accum = 0,
		tickrate = 10,
		track = track,
		waypoints = waypoints,
		checkpoints = #waypoints,
		spawns = spawns,
		laps = track.laps or 2,
	}
	ensure_waypoints(state)
	for _, id in ipairs(state.roster) do
		local spawn = spawns[(#state.racers % #spawns) + 1]
		table.insert(state.racers, new_racer(id, false, spawn))
	end
	add_ai_racers(state)
	local label = nk.json_encode({game_id = GAME_ID, type = "race", room_code = state.room_code})
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
			ai_tick(r, delta, state)
		else
			apply_input(r, delta, state)
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
