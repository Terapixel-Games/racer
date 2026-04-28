local nk = require("nakama")
local room_code = require("room_code")
local tracks = require("tracks")

local OP = {
	LOBBY_STATE = 1,
	LOBBY_RACE_START = 2,
}

local GAME_ID = "circuit-collapse-racer"
local LOBBY_COUNTDOWN = 20
local RESET_THRESHOLD = 10
local MAX_RACERS = 8
local DEFAULT_TRACK_ID = "kitchen"
local DEFAULT_RACER_ID = "Sir Clink"

local VALID_RACERS = {
	["Rexx"] = true,
	["Moko"] = true,
	["Tuggs"] = true,
	["Popper"] = true,
	["Sir Clink"] = true,
	["Slammo"] = true,
	["Velva"] = true,
	["Dash"] = true,
}

local M = {}

local function normalize_racer_id(value)
	if type(value) ~= "string" then
		return DEFAULT_RACER_ID
	end
	if VALID_RACERS[value] then
		return value
	end
	return DEFAULT_RACER_ID
end

local function new_state(params)
	local code = params.room_code or room_code.generate()
	local track = params.track or tracks.get(DEFAULT_TRACK_ID)
	return {
		room_code = code,
		humans = {},
		racers = {},
		pending_racers = {},
		countdown = LOBBY_COUNTDOWN,
		countdown_running = false,
		phase = "lobby",
		track = track,
	}
end

local function broadcast_state(dispatcher, state)
	local players = {}
	for _, p in pairs(state.humans) do
		local racer_id = normalize_racer_id(state.racers[p.user_id])
		table.insert(players, {
			user_id = p.user_id,
			name = racer_id,
			racer_id = racer_id,
		})
	end
	table.sort(players, function(a, b)
		if a.name == b.name then
			return a.user_id < b.user_id
		end
		return a.name < b.name
	end)
	local data = {
		room_code = state.room_code,
		countdown = state.countdown,
		players = players,
		track = state.track,
	}
	dispatcher.broadcast_message(OP.LOBBY_STATE, nk.json_encode(data))
end

function M.match_init(context, params)
	local state = new_state(params or {})
	local label = nk.json_encode({game_id = GAME_ID, type = "lobby", room_code = state.room_code})
	return state, 1, label
end

function M.match_join_attempt(context, dispatcher, tick, state, presence, metadata)
	if state.phase ~= "lobby" then
		return state, false, "closed"
	end
	state.pending_racers[presence.user_id] = normalize_racer_id(metadata and metadata.selected_racer_id)
	return state, true
end

function M.match_join(context, dispatcher, tick, state, presences)
	for _, p in ipairs(presences) do
		state.humans[p.user_id] = p
		state.racers[p.user_id] = normalize_racer_id(state.pending_racers[p.user_id])
		state.pending_racers[p.user_id] = nil
	end
	if state.countdown > 0 and state.countdown < RESET_THRESHOLD then
		state.countdown = RESET_THRESHOLD
	end
	if next(state.humans) ~= nil then
		state.countdown_running = true
	end
	broadcast_state(dispatcher, state)
	return state
end

function M.match_leave(context, dispatcher, tick, state, presences)
	for _, p in ipairs(presences) do
		state.humans[p.user_id] = nil
		state.racers[p.user_id] = nil
		state.pending_racers[p.user_id] = nil
	end
	if next(state.humans) == nil then
		return nil
	end
	broadcast_state(dispatcher, state)
	return state
end

function M.match_loop(context, dispatcher, tick, state, messages)
	for _, m in ipairs(messages) do end

	if state.countdown_running and state.phase == "lobby" then
		state.countdown = state.countdown - 1
		if state.countdown <= 0 then
			state.phase = "closed"
			local roster = {}
			local racer_selections = {}
			for id, _ in pairs(state.humans) do
				table.insert(roster, id)
				racer_selections[id] = normalize_racer_id(state.racers[id])
			end
			local race_match_id = nk.match_create("race_match", {
				room_code = state.room_code,
				roster = roster,
				racer_selections = racer_selections,
				track = state.track,
			})
			dispatcher.broadcast_message(OP.LOBBY_RACE_START, nk.json_encode({race_match_id = race_match_id, track = state.track}))
		else
			broadcast_state(dispatcher, state)
		end
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
