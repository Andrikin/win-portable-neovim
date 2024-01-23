---@class Utils
local Utils = {}

---@param msg string
Utils.notify = function(msg)
	vim.cmd.mode()
	vim.notify(msg) -- TODO: Verificar nvim_echo
end

Utils.npcall = vim.F.npcall

return Utils
