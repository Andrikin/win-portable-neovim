vim.wo.conceallevel = 2
vim.wo.concealcursor = 'nvc'
vim.wo.wrap = false
vim.schedule(function ()
    vim.cmd.syntax('match qfFileNameConceal =[^|]\\{-}/= contained nextgroup=qfFileNameConcel,qfFileName conceal')
    vim.cmd.syntax('match qfFileName /^[^|]*/ contains=qfFileNameConceal nextgroup=qfSeparator1')
end)

