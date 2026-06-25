-- BufWritePost: compilar tex para gerar pdf assim que salvar o arquivo
local buf = vim.api.nvim_get_current_buf()
vim.treesitter.start()
vim.schedule(function ()
    -- vim.bo[buf].syntax = "ON" -- wip: treesitter highlight não está funcionando
    vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    vim.bo[buf].textwidth = 80
end)

-- Vim-Surround (Tim Pope)
-- Latex
vim.b[buf]['surround_' .. vim.fn.char2nr('l')] = "\\\1\\\1{\r}"
vim.b[buf]['surround_' .. vim.fn.char2nr('\\')] = "\\\1\\\1{\r}"

-- Mappings
vim.keymap.set({'i'}, '<c-v>', '<c-r>+', {buffer = buf})

