-- BufWritePost: compilar tex para gerar pdf assim que salvar o arquivo
local Andrikin = require('andrikin.utils').Andrikin
local buf = vim.api.nvim_get_current_buf()
local has_autocmd = false
local autocmds = vim.api.nvim_get_autocmds({
    group = Andrikin,
    event = 'BufWritePost',
    buffer = buf,
})
vim.treesitter.start()
vim.bo[buf].syntax = "ON" -- wip: treesitter highlight não está funcionando
vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
for _, au in ipairs(autocmds) do
    if au.group_name == "Andrikin" then
        has_autocmd = true
        break
    end
end
if not has_autocmd then
    vim.api.nvim_create_autocmd(
        'BufWritePost',
        {
            group = Andrikin,
            callback = function(env)
                if env.file:match('C%.I%. N°') then
                    vim.cmd.CompilarOuvidoria()
                end
            end,
            buffer = buf,
        }
    )
    -- spell (local to window)
    vim.api.nvim_create_autocmd('BufEnter',{
        group = Andrikin,
        callback = function ()
            vim.o.spell = true
        end,
        buffer = buf,
    })
    vim.api.nvim_create_autocmd('BufLeave',{
        group = Andrikin,
        callback = function ()
            vim.o.spell = false
        end,
        buffer = buf,
    })
end
vim.bo[buf].textwidth = 80

-- Vim-Surround (Tim Pope)
-- Latex
vim.b[buf]['surround_' .. vim.fn.char2nr('l')] = "\\\1\\\1{\r}"
vim.b[buf]['surround_' .. vim.fn.char2nr('\\')] = "\\\1\\\1{\r}"

-- Mappings
vim.keymap.set({'i'}, '<c-v>', '<c-r>+', {buffer = buf})
