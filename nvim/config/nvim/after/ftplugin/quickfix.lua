vim.keymap.set('n', 'gq', function()
    local id = vim.api.nvim_get_current_win()
    vim.cmd.wincmd('p') -- voltar para window anterior
    vim.api.nvim_win_close(id, true)
end,
    { silent = true, buffer = vim.api.nvim_get_current_buf()}
)
