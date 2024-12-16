if not vim.b.did_undotree then
    vim.keymap.set( 'n', 'gq',
        vim.cmd.UndotreeToggle,
        { silent = true, buffer = vim.api.nvim_get_current_buf()}
    )
    vim.b.did_undotree = true
end
