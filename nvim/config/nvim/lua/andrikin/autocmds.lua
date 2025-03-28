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
            vim.highlight.on_yank({
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
                vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
            end
        end
    }
)

--- Quando quickfix/loclist for para estado hidden, resetar configurações
autocmd(
    'User',
    {
        group = Andrikin,
        pattern = 'AndrikinQuickFixHidden',
        callback = function(ev)
            local qf_winid = vim.fn.bufwinid(ev.buf)
            local windows = vim.fn.gettabinfo(vim.fn.tabpagenr())[1].windows
            windows = vim.tbl_filter(function(winid)
                return winid ~= qf_winid
            end, windows)
            for _, id in ipairs(windows) do
                vim.wo[id].cursorline = false
            end
        end
    }
)
autocmd(
    {'BufHidden', 'BufLeave'},
    {
        group = Andrikin,
        pattern = '*',
        callback = function()
            if vim.o.buftype == 'quickfix' then
                vim.api.nvim_exec_autocmds('User', {
                    group = Andrikin,
                    pattern = 'AndrikinQuickFixHidden',
                })
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
            vim.cmd.cd(vim.loop.os_homedir() .. '/Desktop')
            -- BUG: lualine não redesenha o statusline. Comandos como redraw e redrawstatus também não funcionam
            -- vim.cmd.redrawstatus({bang = true}) -- não funciona
        end,
    }
)

