-- Autocmds goosebumps
local autocmd = vim.api.nvim_create_autocmd
local reload = require('andrikin.utils').reload
local Andrikin = require('andrikin.utils').Andrikin
local cursorline = require('andrikin.utils').cursorline

-- Highlight linha quando entrar em INSERT MODE
autocmd(
    'InsertEnter',
    {
        group = Andrikin,
        pattern = '*',
        callback = function()
            cursorline.on()
        end,
    }
)
autocmd(
    'InsertLeave',
    {
        group = Andrikin,
        pattern = '*',
        callback = function()
            local dirvish = vim.o.ft == 'dirvish' -- não desativar quando for Dirvish
            if not dirvish then
                cursorline.off()
            end
        end,
    }
)

-- Resize windows automatically
-- Tim Pope goodness
autocmd(
    'VimResized',
    {
        group = Andrikin,
        pattern = '*',
        callback = function()
            vim.cmd.wincmd('=')
        end,
    }
)

-- Highlight configuração
autocmd(
    'TextYankPost',
    {
        group = Andrikin,
        pattern = '*',
        callback = function()
            vim.hl.on_yank({
                higroup = 'IncSearch',
                timeout = 300,
            })
        end,
    }
)

-- Remover fonte do regedit (Windows)
autocmd(
    'VimLeave',
    {
        group = Andrikin,
        callback = function()
            local flashdrive = vim.env.HOME:sub(1, 1):lower() ~= 'c'
            local remover = false
            if flashdrive then
                remover = vim.fn.confirm(
                    'Remover fonte do regedit?',
                    '&Sim\n&Não',
                    2
                ) == 1
            else
                do return end
            end
            if remover then
                vim.cmd.FonteRemover()
            end
        end,
    }
)

-- --- Builtin LSP commands ---
-- Only available in git projects (git init)
autocmd(
    'LspAttach',
    {
        group = Andrikin,
        callback = function(ev)
            local client = vim.lsp.get_client_by_id(ev.data.client_id)
            if client and client:supports_method('textDocument/completion') then
                vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = false })
            end
        end
    }
)

-- Setar cwd para $HOMEPATH/Desktop
-- Realizar Git pull no repositório win-portable-neovim\
autocmd(
    'VimEnter',
    {
        group = Andrikin,
        pattern = '*',
        once = true,
        callback = function()
            if vim.fn.exists('g:loaded_fugitive') then
                vim.fn.jobstart({
                    'git',
                    'pull'
                }, {
                    cwd = vim.env.HOME,
                    on_stdout = function(_, data, _)
                        if data[1] == 'Already up to date.' then
                            print('win-portable-neovim: não há nada para atualizar!')
                        elseif data[1]:match('^Updating') then
                            reload()
                            print('win-portable-neovim: atualizado e recarregado!')
                        end
                    end,
                })
            end
---@diagnostic disable-next-line: undefined-field
            vim.cmd.cd(vim.uv.os_homedir() .. '/Desktop')
            -- BUG: lualine não redesenha o statusline. Comandos como redraw e redrawstatus também não funcionam
            -- vim.cmd.redrawstatus({bang = true}) -- não funciona
        end,
    }
)

autocmd(
    'WinNew',
    {
        group = Andrikin,
        pattern = 'checkhealth',
        callback = function()
            vim.cmd.LualineRenameTab('CheckHealth')
        end,
    }
)

