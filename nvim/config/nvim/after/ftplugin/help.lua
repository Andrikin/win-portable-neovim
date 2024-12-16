if not vim.b.did_help then
    vim.keymap.set('n', 'gq', function()
        local id = vim.fn.gettabinfo(vim.fn.tabpagenr())[1].windows[1]
        vim.cmd.quit()
        if id then
            vim.fn.win_gotoid(id) -- ir para a primeira window da tab
        end
    end,
    { silent = true, buffer = vim.api.nvim_get_current_buf()}
    )
    vim.b.did_help = true
end
vim.treesitter.start()
