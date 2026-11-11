if vim.fn.executable('bash') == 0 then
    vim.print('Sumatra-grep: necessário a instalação de "bash".\nBusque rever Cygwin.')
    return
end
if vim.fn.executable('SumatraPDF-3.6.1-64.exe') == 0
    or vim.fn.executable('sumatra.exe') == 0 then
    vim.print('Sumatra-grep: não foram encontrados executáveis do sumatra.\nRealizar instalação.')
    return
end
if not vim.g.did_sumatra then
    local sumatra = vim.fn.exepath('SumatraPDF-3.6.1-64.exe')
    if sumatra == "" then
        sumatra = vim.fn.exepath('sumatra.exe')
    end
    vim.g.did_sumatra = true
    vim.g.sumatra = vim.fs.normalize(sumatra)
end
-- ANOTHER SOLUTION --
-- local pdfs = vim.iter(
--     vim.split(vim.fn.glob(vim.fn.expand('%') .. '*.pdf'), '\n')
-- ):map(function(d)
--     d = '"' .. d .. '"'
--     return d
-- end):join(' ')
-- vim.bo.makeprg = vim.g.sumatra .. ' grep -Hin "$*" ' .. pdfs
-- ANOTHER SOLUTION --
-- WARNING: possui limite de argumentos...
vim.bo.makeprg = "bash -c '" .. vim.g.sumatra .. ' grep -Hin "$*" %:gs?\\?/?:S*.pdf' .. "'"
-- %f	%l	%m
vim.bo.errorformat = {
    '%A%f\t%l\t%m',
    '%-Cwarning:%.%#',
}
