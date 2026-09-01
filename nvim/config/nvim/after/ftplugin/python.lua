vim.treesitter.start()
vim.schedule(function ()
    vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
end)
if vim.fn.executable('uv') == 1 then
    vim.bo.makeprg = 'uv run %:S'
elseif vim.fn.executable('python') == 1 then
    vim.bo.makeprg = 'python3 %:S'
end
vim.cmd.compiler('pyunit')

