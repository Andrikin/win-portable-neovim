vim.treesitter.start()
vim.schedule(function ()
    vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
end)
vim.bo.makeprg = 'python3 %:S'

