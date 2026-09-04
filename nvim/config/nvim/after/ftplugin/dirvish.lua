local buf = vim.api.nvim_get_current_buf()
local open = vim.ui.open or function(arquivo)
    vim.print('vim.system: ' .. arquivo)
    vim.system(
        {vim.fn.shellescape(arquivo, true)},
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
-- use command 'grep <regex>' in dirvish buffer to fill quickfix list
vim.bo.grepprg = vim.go.grepprg .. ' "$*" %'
