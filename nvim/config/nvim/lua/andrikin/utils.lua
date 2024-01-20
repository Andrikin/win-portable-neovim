---@class Utils
local Utils = {}

---@param msg string
Utils.notify = function(msg)
	vim.cmd.mode()
	vim.notify(msg)
end

Utils.npcall = vim.F.npcall

return Utils
