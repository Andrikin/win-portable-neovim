local buf = vim.api.nvim_get_current_buf()
vim.treesitter.start()
if not vim.g.loaded_emmet_vim then
    vim.cmd.packadd('emmet-vim')
end
vim.cmd.EmmetInstall()
vim.schedule(function ()
    vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
end)
