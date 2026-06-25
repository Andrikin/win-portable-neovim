vim.treesitter.start()
vim.schedule(function ()
    vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
end)
if not package.loaded['andrikin.options'] then
    require('andrikin.options')
end
