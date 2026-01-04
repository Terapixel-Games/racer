local nk = require("nakama")
local room_code = require("room_code")

local GAME_ID = "circuit-collapse-racer"

local function read_payload(payload)
	if not payload or payload == "" then
		return {}
	end
	local ok, decoded = pcall(nk.json_decode, payload)
	if not ok then
		return {}
	end
	return decoded
end

local function validate(payload)
	if payload.game_id ~= GAME_ID then
		error("invalid game id")
	end
end

local function find_open_lobby()
	local query = "+label.game_id:" .. GAME_ID .. " +label.type:lobby"
	local matches = nk.match_list(1, true, nil, nil, nil, query)
	if #matches > 0 then
		return matches[1].match_id
	end
	return nil
end

local function rpc_lobby_join_or_create(context, payload)
	local data = read_payload(payload)
	validate(data)
	local match_id = find_open_lobby()
	local code = nil
	if not match_id then
		code = room_code.generate()
		match_id = nk.match_create("lobby", {room_code = code})
	else
		code = "AUTO"
	end
	return nk.json_encode({match_id = match_id, room_code = code})
end

nk.register_rpc(rpc_lobby_join_or_create, "lobby_join_or_create")
