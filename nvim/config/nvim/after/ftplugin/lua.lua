vim.treesitter.start()
vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
if not package.loaded['andrikin.options'] then
    require('andrikin.options')
end
