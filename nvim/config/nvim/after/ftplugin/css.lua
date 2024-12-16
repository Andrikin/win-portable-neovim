if not vim.b.did_css then
    vim.cmd.Lazy('load emmet-vim')
    vim.cmd.EmmetInstall()
    vim.b.did_css = true
end
