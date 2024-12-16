if not vim.b.did_html then
    vim.cmd.Lazy('load emmet-vim')
    vim.cmd.EmmetInstall()
    vim.b.did_html = true
end
