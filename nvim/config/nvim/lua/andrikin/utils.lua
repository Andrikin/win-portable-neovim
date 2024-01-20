---@class Utils
local Utils = {}

---@param msg string
Utils.notify = function(msg)
	vim.notify(msg)
	vim.cmd.redrawstatus()
end

Utils.npcall = vim.F.npcall

return Utils
