local cursorline = require('andrikin.utils').cursorline
local buf = vim.api.nvim_get_current_buf()
local qf = vim.fn.getwininfo(vim.fn.bufwinid(buf))[1]
local mover = {
    mover = function(cmd, count)
        count = count or vim.v.count1
        local ok, erro = pcall(vim.cmd[cmd], {count =  count})
        if not ok then
            if erro:match('Vim:E553:') then
                print('fim da lista.')
            end
        end
        cursorline.on()
        vim.fn.win_gotoid(qf.winid) -- retornar para quickfix/loclist
    end,
    enter = function(self)
        local cmd = qf.loclist == 1 and 'll' or 'cc'
        local linha = vim.fn.getpos('.')[2]
        self.mover(cmd, linha)
    end,
    i = function()
        local cmd = qf.loclist == 1 and 'll' or 'cc'
        local linha = vim.fn.getpos('.')[2]
        vim.cmd[cmd]({count = linha})
        cursorline.off()
        vim.cmd[cmd:sub(1, 1) .. 'close']()
    end,
    j = function(self)
        local cmd = qf.loclist == 1 and 'lnext' or 'cnext'
        self.mover(cmd)
    end,
    k = function(self)
        local cmd = qf.loclist == 1 and 'lprevious' or 'cprevious'
        self.mover(cmd)
    end,
}
local opts = { silent = true, buffer = buf }
vim.keymap.set('n', 'k', function() mover:k() end, opts)
vim.keymap.set('n', 'j', function() mover:j() end, opts)
vim.keymap.set('n', '<cr>', function() mover:enter() end, opts)
vim.keymap.set('n', 'i', function() mover.i() end, opts)
-- ... adicionar mais comandos para quickfix/loclist
vim.keymap.set('n', 'gq', function()
    local id = vim.fn.gettabinfo(vim.fn.tabpagenr())[1].windows[1]
    vim.cmd.quit()
    if id then
        vim.fn.win_gotoid(id)
    end
end, opts)
