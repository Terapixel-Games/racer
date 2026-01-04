local nk = require("nakama")
local room_code = require("room_code")

local OP = {
	LOBBY_STATE = 1,
	LOBBY_RACE_START = 2,
}

local GAME_ID = "circuit-collapse-racer"
local LOBBY_COUNTDOWN = 20
local RESET_THRESHOLD = 10
local MAX_RACERS = 8

local M = {}

local function new_state(params)
	local code = params.room_code or room_code.generate()
	return {
		room_code = code,
		humans = {},
		countdown = LOBBY_COUNTDOWN,
		countdown_running = false,
		phase = "lobby",
	}
end

local function broadcast_state(dispatcher, state)
	local players = {}
	for _, p in pairs(state.humans) do
		table.insert(players, p.username or "Racer")
	end
	local data = {
		room_code = state.room_code,
		countdown = state.countdown,
		players = players,
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
	return state, true
end

function M.match_join(context, dispatcher, tick, state, presences)
	for _, p in ipairs(presences) do
		state.humans[p.user_id] = p
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
			for id, _ in pairs(state.humans) do
				table.insert(roster, id)
			end
			local race_match_id = nk.match_create("race_match", {room_code = state.room_code, roster = roster})
			dispatcher.broadcast_message(OP.LOBBY_RACE_START, nk.json_encode({race_match_id = race_match_id}))
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
