if not vim.b.did_dirvish then
    local buf = vim.api.nvim_get_current_buf()
    local opts = { expr = true, buffer = buf }
    vim.keymap.set('n', '.', function()
        local cmd = ':<c-u>! '
        if vim.fn.empty(vim.fn.getline(".")) == 1 then
            cmd = cmd .. '%:gs?\\/?\\?\\'
        else
            cmd = cmd .. vim.fn.shellescape(vim.fn.getline('.'):gsub('\\/', '\\'):gsub('\\$', ''), 1)
        end
        -- finalizando map
        cmd = cmd .. '<home><c-right>'
        return cmd
    end, opts)
    vim.keymap.set('n', 'go', function()
        local arquivo = vim.fn.getline('.'):gsub('\\', '\\/'):gsub('\\/$', ''):gsub('\\$', '')
        if vim.fn.fnamemodify(arquivo, ':e') ~= '' and vim.fn.isdirectory(arquivo) == 0 then
            vim.fn.jobstart(
                vim.fn.shellescape(arquivo, 1),
                {detach = true}
            )
        else
            print('dirvish: não foi encontrado arquivo para abrir')
            do return end
        end
    end, {silent = true, buffer = buf})
    vim.b.did_dirvish = true
end
