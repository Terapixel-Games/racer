local M = {}

local charset = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"

function M.generate()
	math.randomseed(os.time() + math.random(0, 1000))
	local code = {}
	for i = 1, 6 do
		local idx = math.random(1, #charset)
		table.insert(code, string.sub(charset, idx, idx))
	end
	return table.concat(code)
end

return M
