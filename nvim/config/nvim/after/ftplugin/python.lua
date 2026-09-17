vim.treesitter.start()
vim.schedule(function ()
    vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
end)

if vim.fn.executable('python') == 1 then
    vim.cmd.compiler('python')
end
