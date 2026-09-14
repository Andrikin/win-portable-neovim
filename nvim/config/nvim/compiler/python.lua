if vim.fn.executable('uv.exe') == 1 then
    local VENV_DIR = vim.fs.joinpath(vim.fn.expand('%:h'), '.venv')
    if vim.uv.fs_stat(VENV_DIR) then
        vim.env.VIRTUAL_ENV = VENV_DIR
    end
    local PYTHON = vim.fs.joinpath(VENV_DIR, 'Script', 'python')
    if vim.fn.executable(PYTHON) == 1 then
        vim.bo.makeprg = PYTHON .. ' %:S'
    else
        vim.print('compiler(python): não foi possível encontrar executável "python"')
    end
else
    vim.env.VIRTUAL_ENV = nil
    vim.bo.makeprg = 'python3 %:S'
end
-- https://flukus.github.io/vim-errorformat-demystified.html
vim.bo.errorformat = {
    '%-GTraceback (most recent call last):',
    '%E %#File "%f"\\, line %l%.%#',
    '%+C%.%#Error: %#%m',
    '%-C%.%#',
}
