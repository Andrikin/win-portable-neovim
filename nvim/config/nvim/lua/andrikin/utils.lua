---@class Utils
local Utils = {}

--- Mostra notificação para usuário, registrando em :messages
---@param msg string
Utils.notify = function(msg)
	vim.cmd.mode()
    vim.api.nvim_echo({{msg, 'DiagnosticInfo'}}, true, {})
end

--- Mostra uma notificação para o usuário, mas sem registrar em :messages
---@param msg string
Utils.echo = function(msg)
	vim.cmd.mode()
    vim.api.nvim_echo({{msg, 'DiagnosticInfo'}}, false, {})
end

Utils.npcall = vim.F.npcall

return Utils
