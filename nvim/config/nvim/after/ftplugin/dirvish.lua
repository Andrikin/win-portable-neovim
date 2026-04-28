local buf = vim.api.nvim_get_current_buf()
local open = function(arquivo)
-- local open = vim.ui.open and function(arquivo)
--     vim.print('vim.ui.open: ' .. arquivo)
--     vim.ui.open(arquivo, { cmd = {'start', '""'} })
-- end or function(arquivo)
    vim.print('jobstart: ' .. arquivo)
    vim.fn.jobstart(
        vim.fn.shellescape(arquivo, true),
        {detach = true}
    )
end
vim.keymap.set('n', 'go', function()
    local arquivo = vim.fn.getline('.'):gsub('\\', '\\/'):gsub('\\/$', ''):gsub('\\$', '')
    local extencao = vim.fn.fnamemodify(arquivo, ':e')
    if (extencao ~= '' or vim.env.PATHEXT:lower():match(extencao)) and vim.fn.isdirectory(arquivo) == 0 then
        open(arquivo)
    else
        print('dirvish: não foi encontrado arquivo para abrir')
        do return end
    end
end, {silent = true, buffer = buf})
