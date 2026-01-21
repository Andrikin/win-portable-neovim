local buf = vim.api.nvim_get_current_buf()
vim.treesitter.start()
vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
if not package.loaded['andrikin.options'] then
    require('andrikin.options')
end
