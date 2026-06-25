vim.treesitter.start()
vim.schedule(function ()
    vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    vim.bo.textwidth = 80
end)
