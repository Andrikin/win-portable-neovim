-- BufWritePost: compilar tex para gerar pdf assim que salvar o arquivo
-- TODO: comando somente para arquivos de comunicação que precisam ser 
-- compilados
if vim.b.did_tex then
    do return end
end
local autocmd = vim.api.nvim_create_autocmd
local Andrikin = require('andrikin.utils').Andrikin
local Ouvidoria = require('andrikin.utils').Ouvidoria
autocmd(
    'BufWritePost',
    {
        group = Andrikin,
        pattern = '*.tex',
        callback = function()
            Ouvidoria.latex:compilar()
        end,
    }
)
vim.b.did_tex = true
