-- TODO: Escrever plugin para utilizar na Ouvidoria
local Ouvidoria = {}
local Latex = {}


-- CUSTOM COMMANDS
vim.api.nvim_create_user_command('HexEditor', '%!xxd', {})
