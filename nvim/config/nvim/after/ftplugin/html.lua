if vim.b.did_html then
    do return end
end
vim.cmd.Lazy('load emmet-vim')
vim.cmd.EmmetInstall()
vim.b.did_html = true
