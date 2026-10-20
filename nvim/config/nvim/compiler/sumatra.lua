if vim.fn.executable('SumatraPDF-3.6.1-64.exe') == 0
    or vim.fn.executable('sumatra.exe') == 0 then
    return
end
if vim.b.did_sumatra then
    return
end
vim.b.did_sumatra = true
local sumatra = vim.fn.exepath('SumatraPDF-3.6.1-64.exe')
if sumatra == "" then
    sumatra = vim.fn.exepath('sumatra.exe')
end
vim.b.did_sumatra_grepbkp = vim.bo.grepprg
vim.bo.grepprg = sumatra .. ' grep -Hin "$*" (Get-ChildItem -Filter %*.pdf).FullName'
