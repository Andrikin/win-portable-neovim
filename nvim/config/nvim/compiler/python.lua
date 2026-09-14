if vim.w.current_compiler == "python" then
    return
end
vim.w.current_compiler = "python"

if vim.fn.executable('uv') == 1 then
    vim.bo.makeprg = 'uv run %:S'
elseif vim.fn.executable('python') == 1 then
    vim.bo.makeprg = 'python3 %:S'
end
vim.bo.errorformat={
    '%A  File "%f"',
    'line %l',
    '%m',
    '%C  %.%#',
    '%+Z%.%#Error: %.%#',
    '%A  File "%f"',
    'line %l',
    '%+C  %.%#',
    '%-C%p^',
    '%Z%m',
    '%-G%.%#'
}
