-- BufWritePost: compilar tex para gerar pdf assim que salvar o arquivo
local Andrikin = require('andrikin.utils').Andrikin
local buf = vim.api.nvim_get_current_buf()
local has_autocmd = false
local autocmds = vim.api.nvim_get_autocmds({
    group = Andrikin,
    event = 'BufWritePost',
    buffer = buf,
})
vim.treesitter.start()
vim.schedule(function ()
    vim.bo[buf].syntax = "ON" -- wip: treesitter highlight não está funcionando
    vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    vim.bo[buf].textwidth = 80
end)
for _, au in ipairs(autocmds) do
    if au.group_name == "Andrikin" then
        has_autocmd = true
        break
    end
end
if not has_autocmd then
    vim.api.nvim_create_autocmd(
        'BufWritePost',
        {
            group = Andrikin,
            callback = function(env)
                if env.file:match('C%.I%. N°') then
                    vim.cmd.CompilarOuvidoria()
                end
            end,
            buffer = buf,
        }
    )
    -- spell (local to window)
    vim.api.nvim_create_autocmd('BufEnter',{
        group = Andrikin,
        callback = function ()
            vim.o.spell = true
        end,
        buffer = buf,
    })
    vim.api.nvim_create_autocmd('BufLeave',{
        group = Andrikin,
        callback = function ()
            vim.o.spell = false
        end,
        buffer = buf,
    })
end

-- Vim-Surround (Tim Pope)
-- Latex
vim.b[buf]['surround_' .. vim.fn.char2nr('l')] = "\\\1\\\1{\r}"
vim.b[buf]['surround_' .. vim.fn.char2nr('\\')] = "\\\1\\\1{\r}"

-- Mappings
vim.keymap.set({'i'}, '<c-v>', '<c-r>+', {buffer = buf})

-- autocmd formatação
local latexaugroup = vim.api.nvim_create_augroup('AndrikinLatex', {clear = true})
vim.api.nvim_create_autocmd(
    'BufWritePre', {
        group = latexaugroup,
        pattern = 'C.I. N*.tex',
        callback = function()
            local manifestacao = {
                inicio = vim.fn.matchbufline(
                    vim.api.nvim_get_current_buf(),
                    "begin{document}", 1,
                    vim.fn.line('$'))[1],
                fim = vim.fn.matchbufline(
                    vim.api.nvim_get_current_buf(),
                    "end{document}", 1,
                    vim.fn.line('$'))[1],
            }
            local documento = {
                manifestacao.inicio.lnum or 1,
                manifestacao.fim.lnum or vim.fn.line('$')
            }
            -- Formatar texto -- OBS: ver vim.api.nvim_parse_cmd
            vim.cmd.substitute({"/[º°ª]/{\\\\textdegree}/ge", range = documento, mods = { silent = true }})
            vim.cmd.substitute({"/§/\\\\S/ge", range = documento, mods = { silent = true }})
            vim.cmd.substitute({'/[“”]/\\"/ge', range = documento, mods = { silent = true }})
            vim.cmd.substitute({"/[^\\\\]\\@<=\\$/\\\\$/ge", range = documento, mods = { silent = true }})
            -- Formatar espaços e pontuações
            vim.cmd.substitute({'/\\s\\+\\([.,]\\)\\s\\?/\\1 /ge', range = documento, mods = { silent = true }})
            vim.cmd.substitute({'/\\s\\+/ /ge', range = documento, mods = { silent = true }})
            vim.cmd(
                documento[1] .. ',' .. documento[2] .. 'v/@\\|gov\\.br\\|\\.com\\|\\.br/s/\\([a-zA-Z]\\)\\s\\{,}\\([:.,]\\)\\s\\{,}\\([a-zA-Z0-9]\\)/\\1\\2 \\3/ge'
            )
            vim.cmd.substitute({
                "/{\\\\textdegree}\\([a-zA-Z0-9]\\)/{\\\\textdegree} \\1/ge",
                range = documento,
                mods = { silent = true },
            })
        end
    }
)

