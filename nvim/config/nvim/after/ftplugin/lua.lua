local buf = vim.api.nvim_get_current_buf()
vim.treesitter.start()
vim.schedule(function ()
    vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
end)
if not package.loaded['andrikin.options'] then
    require('andrikin.options')
end
