local nk = require("nakama")

local OP = {
	RACE_INPUT = 10,
	RACE_SNAPSHOT = 11,
	RACE_RESET = 12,
	RACE_WASTED = 13,
	RACE_FINISH = 14,
	RACE_MATCH_END = 15,
}

local GAME_ID = "circuit-collapse-racer"
local LAPS = 2
local CHECKPOINTS = 3
local SNAPSHOT_HZ = 15
local BEHIND_THRESHOLD = 3
local BEHIND_SECONDS_TO_WASTED = 6
local MAX_RACERS = 8

local M = {}

local function new_racer(id, is_ai)
	return {
		id = id,
		is_ai = is_ai,
		pos = {x = 0, y = 0.5, z = 0},
		rot = {0, 0, 0},
		lap = 1,
		checkpoint = 0,
		lap_gate = false,
		wasted = false,
		finished = false,
		behind_timer = 0,
		input = {throttle = 0, brake = 0, steer = 0, drift = false, boost = false},
		progress = 0,
	}
end

local function add_ai_racers(state)
	local ai_needed = MAX_RACERS - #state.roster
	for i = 1, ai_needed do
		local id = "ai_" .. i
		local racer = new_racer(id, true)
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

local function update_progress(racer)
	racer.progress = (racer.lap - 1) * CHECKPOINTS + racer.checkpoint
end

local function apply_input(racer, delta)
	local speed = racer.input.throttle * 10 - racer.input.brake * 8
	racer.pos.z = racer.pos.z - speed * delta
	if racer.pos.z < -CHECKPOINTS * 50 then
		if racer.lap_gate then
			racer.lap = racer.lap + 1
			racer.lap_gate = false
		end
		racer.pos.z = 0
	end
	local checkpoint_index = math.floor(math.abs(racer.pos.z) / 50) % CHECKPOINTS
	if checkpoint_index == racer.checkpoint then
		if checkpoint_index == 1 then
			racer.lap_gate = true
		end
		racer.checkpoint = (racer.checkpoint + 1) % CHECKPOINTS
	end
	if racer.lap > LAPS then
		racer.finished = true
	end
	update_progress(racer)
end

local function ai_tick(racer, delta)
	racer.input.throttle = 0.8
	apply_input(racer, delta)
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
	local state = {
		room_code = params.room_code or "AUTO",
		roster = params.roster or {},
		racers = {},
		elapsed = 0,
		snapshot_accum = 0,
		tickrate = 10,
	}
	for _, id in ipairs(state.roster) do
		table.insert(state.racers, new_racer(id, false))
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
			ai_tick(r, delta)
		else
			apply_input(r, delta)
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
