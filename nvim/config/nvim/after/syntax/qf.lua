vim.wo.conceallevel = 2
vim.wo.concealcursor = 'nvc'
vim.wo.wrap = false
vim.schedule(function ()
    -- vim.cmd.syntax('match qfFileNameConceal =^[^|]*/= contained conceal')
    -- funciona
    vim.cmd.syntax('match qfFileNameConceal =^.*/\\ze[^/|]*= conceal')
    -- vim.cmd.syntax('clear qfFileName')
    -- vim.cmd.syntax('match qfFileName /^[^|]*/ contains=qfFileNameConceal nextgroup=qfSeparator1 links to Directory')
end)

