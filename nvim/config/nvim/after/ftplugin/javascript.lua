local buf = vim.api.nvim_get_current_buf()
vim.treesitter.start()
vim.schedule(function ()
    vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
end)
