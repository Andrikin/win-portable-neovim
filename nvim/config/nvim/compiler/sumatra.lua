if vim.fn.executable('SumatraPDF-3.6.1-64.exe') == 0
    or vim.fn.executable('sumatra.exe') == 0 then
    return
end
if not vim.g.did_sumatra then
    local sumatra = vim.fn.exepath('SumatraPDF-3.6.1-64.exe')
    if sumatra == "" then
        sumatra = vim.fn.exepath('sumatra.exe')
    end
    vim.g.did_sumatra = true
    vim.g.sumatra = sumatra
end
local pdfs = vim.iter(
    vim.split(vim.fn.glob(vim.fn.expand('%') .. '*.pdf'), '\n')
):map(function(d)
        d = '"' .. d .. '"'
        return d
    end):join(' ')
-- vim.bo.grepprg = sumatra .. ' grep -Hin "$*" ' .. pdfs
vim.bo.makeprg = vim.g.sumatra .. ' grep -Hin "$*" ' .. pdfs
-- %f	%l	%m
vim.bo.errorformat = {
    '%A%f\t%l\t%m',
    '%-Cwarning:%.%#',
}
