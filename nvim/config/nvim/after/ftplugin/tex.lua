-- BufWritePost: compilar tex para gerar pdf assim que salvar o arquivo
-- TODO: comando somente para arquivos de comunicação que precisam ser 
-- compilados
local Andrikin = require('andrikin.utils').Andrikin
local Ouvidoria = require('andrikin.utils').Ouvidoria
local buf = vim.api.nvim_get_current_buf()
local id = nil
if vim.b[buf].autocmd_id then
    goto configuracoes
end
id = vim.api.nvim_create_autocmd(
    'BufWritePost',
    {
        group = Andrikin,
        callback = function(env)
            if env.file:match('C%.I%. N°') then
                Ouvidoria.latex:compilar()
            end
        end,
        buffer = buf,
    }
)
vim.b[buf].autocmd_id = id
::configuracoes::
vim.bo[buf].textwidth = 80
