local buf = vim.api.nvim_get_current_buf()
vim.keymap.set('n', 'gq', function()
    local id = vim.api.nvim_get_current_win()
    vim.cmd.wincmd('p') -- voltar para window anterior
    vim.api.nvim_win_close(id, true)
end,
    { silent = true, buffer = buf}
)
local sumatra = ""
if not vim.g.did_sumatra then
    sumatra = vim.fn.exepath('SumatraPDF-3.6.1-64.exe')
    if sumatra == "" then
        sumatra = vim.fn.exepath('sumatra.exe')
    end
else
    sumatra = vim.g.sumatra
end
local pdf = function(file, number, word)
    local cmd = {vim.g.sumatra, '-reuse-instance', '-page', number, vim.fs.basename(file)}
    if word then
        word = vim.fn.trim(word)
        cmd = {vim.g.sumatra, '-search', word, '-reuse-instance', '-page', number, vim.fs.basename(file)}
    end
    vim.system(cmd, {detach = true, cwd = vim.fs.dirname(file)})
end
-- WARNING: open current file with default system open
vim.keymap.set('n', 'go', function()
    local entrada = vim.fn.getline('.')
    local arquivo = entrada:match('^([^|]+)')
    local pagina = entrada:match('|([^|]+)|')
    local termo = entrada:match('|([^|]+)$')
    local extencao = vim.fn.fnamemodify(arquivo, ':e')
    if extencao:match('pdf') then
        pdf(arquivo, pagina, termo)
    else
        vim.print('dirvish: não é um arquivo pdf.')
        do return end
    end
end, {silent = true, buffer = buf})

