if vim.fn.executable('SumatraPDF-3.6.1-64.exe') == 0
    or vim.fn.executable('sumatra.exe') == 0 then
    return
end
local sumatra = vim.fn.exepath('SumatraPDF-3.6.1-64.exe')
if sumatra == "" then
    sumatra = vim.fn.exepath('sumatra.exe')
end
local pdfs = vim.iter(
    vim.split(vim.fn.glob(vim.fn.expand('%') .. '*.pdf'), '\n')
):map(function(d)
        d = '"' .. d .. '"'
        return d
    end):join(' ')
-- vim.bo.grepprg = sumatra .. ' grep -Hin "$*" ' .. pdfs
vim.bo.makeprg = sumatra .. ' grep -Hin "$*" ' .. pdfs
-- %f	%l	%m
vim.bo.errorformat = {
    '%I%f\t%l\t%m',
    '%-Cwarning:%.%#',
}
