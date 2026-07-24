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
        print('nvim.dir: não foi encontrado arquivo para abrir')
        do return end
    end
end, {silent = true, buffer = buf})
-- dirvish like
vim.keymap.set('n', 'i', '<cr>')
vim.keymap.set('n', '.', function ()
    if vim.v.count > 0 then
        return ''
    end
    local cmd = ":\\<c-u>! "
    local arquivo = vim.fn.fnamemodify(vim.fn.getline('.'), ':.')
    if arquivo == "" then
        arquivo = "."
    end
    cmd = cmd .. vim.fn.shellescape(arquivo, true) .. "\\<home>\\<c-right>"
    return cmd
end, { expr = true, silent = true }
)

