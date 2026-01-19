vim.treesitter.start()
if not vim.g.loaded_emmet_vim then
    vim.cmd.packadd('emmet-vim')
end
vim.cmd.EmmetInstall()
vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"

