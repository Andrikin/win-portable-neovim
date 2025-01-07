-- BufWritePost: compilar tex para gerar pdf assim que salvar o arquivo
-- TODO: comando somente para arquivos de comunicação que precisam ser 
-- compilados
local Andrikin = require('andrikin.utils').Andrikin
local Ouvidoria = require('andrikin.utils').Ouvidoria
vim.api.nvim_create_autocmd(
    'BufWritePost',
    {
        group = Andrikin,
        callback = function(env)
            if env.file:match('C%.I%. N°') then
                Ouvidoria.latex:compilar()
            end
        end,
        buffer = vim.api.nvim_get_current_buf(),
    }
)
