if vim.b.did_css then
    do return end
end
vim.cmd.Lazy('load emmet-vim')
vim.cmd.EmmetInstall()
vim.b.did_css = true
