vim.keymap.set('n', 'gq', function()
    vim.cmd.close()
    vim.fn.feedkeys('\\<c-w>p', 'n') -- voltar para window anterior
end,
    { silent = true, buffer = vim.api.nvim_get_current_buf()}
)

