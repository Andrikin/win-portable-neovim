-- Autocmds goosebumps
local autocmd = vim.api.nvim_create_autocmd
local termcode = vim.api.nvim_replace_termcodes
local feedkey = vim.api.nvim_feedkeys
local reload = require('andrikin.utils').reload
local Andrikin = require('andrikin.utils').Andrikin
local Ouvidoria = require('andrikin.utils').Ouvidoria
local cursorline = require('andrikin.utils').cursorline
-- local win7 = require('andrikin.utils').win7

-- BufWritePost: compilar tex para gerar pdf assim que salvar o arquivo
autocmd(
	'BufWritePost',
	{
		group = Andrikin,
		pattern = '*.tex',
		callback = function()
			Ouvidoria.latex:compilar()
		end,
	}
)

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

-- Habilitar EmmetInstall
autocmd(
	'FileType',
	{
		group = Andrikin,
		pattern = {'html', 'css'},
        once = true,
		callback = function()
            vim.cmd.Lazy('load emmet-vim')
            vim.cmd.EmmetInstall()
        end,
	}
)

-- Habilitar Jdtls
autocmd(
	'FileType',
	{
		group = Andrikin,
		pattern = 'java',
        once = true,
		callback = function()
            vim.cmd.Lazy('load nvim-jdtls')
        end,
	}
)

-- 'gq' para fechar Undotree window
autocmd(
	'FileType',
	{
		group = Andrikin,
		pattern = 'undotree',
		callback = function(args)
			vim.keymap.set(
				'n',
				'gq',
				vim.cmd.UndotreeToggle,
				{
					silent = true,
					buffer = args.buf,
				}
			)
		end,
	}
)
-- 'gq' para fechar quickfix/loclist, checkhealth e help window
autocmd(
	'FileType',
	{
		group = Andrikin,
		pattern = {'qf', 'checkhealth', 'help', 'harpoon'},
		callback = function(args)
			vim.keymap.set(
				'n',
				'gq',
				function()
					local id = vim.fn.gettabinfo(vim.fn.tabpagenr())[1].windows[1]
					vim.cmd.quit()
					if id then
						vim.fn.win_gotoid(id) -- ir para a primeira window da tab
					end
				end,
				{ silent = true, buffer = args.buf }
			)
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

-- Desabilitar cmp quando em CommandMode
autocmd(
	'CmdlineEnter',
	{
		group = Andrikin,
		pattern = '*',
		callback = function()
			require('cmp').setup({ enabled = false })
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
            -- local client = vim.lsp.get_client_by_id(ev.data.client_id) -- remover LSP highlight 
            -- client.server_capabilities.semanticTokensProvider = nil -- remover LSP highlight 
			local opts = {buffer = ev.buf}
            -- if win7 then -- Prováveis comandos padrão para neovim, após 0.10
            vim.keymap.set('n', 'grn', vim.lsp.buf.rename, opts) -- default neovim
            vim.keymap.set('n', 'grr', vim.lsp.buf.references, opts) -- default neovim
            vim.keymap.set('n', 'gra', vim.lsp.buf.code_action, opts) -- default neovim
            vim.keymap.set('n', '<c-s>', vim.lsp.buf.signature_help, opts) -- default neovim
            -- end
			vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
			vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
			vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
			vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
            -- nvim-cmp (force autocompletion)
            if package.loaded['cmp'] then
                local cmp = require('cmp')
                local luasnip = require('luasnip')
                vim.keymap.set("i", "<c-n>", function(fallback)
                    if cmp.visible() then
                        cmp.select_next_item({behavior = cmp.SelectBehavior.Select})
                        -- You could replace the expand_or_jumpable() calls with expand_or_locally_jumpable() 
                        -- that way you will only jump inside the snippet region
                    elseif luasnip.expand_or_jumpable() then
                        luasnip.expand_or_jump()
                    elseif not cmp.complete() then
                        fallback()
                    end
                end, opts)
                vim.keymap.set("i", "<c-p>", function(fallback)
                    if cmp.visible() then
                        cmp.select_prev_item({behavior = cmp.SelectBehavior.Select})
                    elseif luasnip.jumpable(-1) then
                        luasnip.jump(-1)
                    elseif not cmp.complete() then
                        fallback()
                    end
                end, opts)
                vim.keymap.set("i", "<c-y>", function()
                    cmp.confirm({select = false})
                end, opts)
                vim.keymap.set("i", "<cr>", function() -- insert word and skip from INSERT MODE
                    cmp.confirm({select = false})
                    feedkey(termcode("<esc>", true, false, true), 'n', false)
                end, opts)
				vim.keymap.set("i", "<c-j>", function()
					if cmp.visible() then
						cmp.confirm({select = true})
					else
						feedkey(termcode("<c-j>", true, false, true), 'n', false)
					end
				end, opts)
                vim.keymap.set("i", "<c-e>", function()
                    cmp.abort()
                end, opts)
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

--- Registra mapeamentos para comandos na janela quickfix e loclist
autocmd(
	'FileType',
	{
		group = Andrikin,
		pattern = 'qf',
		callback = function(ev)
            local qf = vim.fn.getwininfo(vim.fn.bufwinid(ev.buf))[1]
            local mover = {
                mover = function(cmd, count)
                    count = count or vim.v.count1
                    local ok, erro = pcall(vim.cmd[cmd], {count =  count})
                    if not ok then
                        if erro:match('Vim:E553:') then
                            print('fim da lista.')
                        end
                    end
                    cursorline.on()
                    vim.fn.win_gotoid(qf.winid) -- retornar para quickfix/loclist
                end,
                enter = function(self)
                    local cmd = qf.loclist == 1 and 'll' or 'cc'
                    local linha = vim.fn.getpos('.')[2]
                    self.mover(cmd, linha)
                end,
                i = function()
                    local cmd = qf.loclist == 1 and 'll' or 'cc'
                    local linha = vim.fn.getpos('.')[2]
                    vim.cmd[cmd]({count = linha})
                    cursorline.off()
                    vim.cmd[cmd:sub(1, 1) .. 'close']()
                end,
                j = function(self)
                    local cmd = qf.loclist == 1 and 'lnext' or 'cnext'
                    self.mover(cmd)
                end,
                k = function(self)
                    local cmd = qf.loclist == 1 and 'lprevious' or 'cprevious'
                    self.mover(cmd)
                end,
            }
            local opts = { silent = true, buffer = ev.buf }
            vim.keymap.set('n', 'k', function() mover:k() end, opts)
            vim.keymap.set('n', 'j', function() mover:j() end, opts)
            vim.keymap.set('n', '<cr>', function() mover:enter() end, opts)
            vim.keymap.set('n', 'i', function() mover.i() end, opts)
            -- ... adicionar mais comandos para quickfix/loclist
		end,
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
            vim.cmd.cd(vim.loop.os_homedir() .. '/Desktop')
            -- BUG: lualine não redesenha o statusline. Comandos como redraw e redrawstatus também não funcionam
            -- vim.cmd.redrawstatus({bang = true}) -- não funciona
		end,
	}
)

-- Himalaya open file
autocmd(
	'FileType',
	{
		group = Andrikin,
		pattern = 'mail',
		callback = function(ev)
            local opts = { silent = true, buffer = ev.buf }
            local open = vim.ui.open or function(arquivo)
                -- If {cmd} is a String it runs in the 'shell'
                vim.fn.jobstart(vim.fn.shellescape(arquivo), {detach = true})
            end
            vim.keymap.set('n', 'go', function()
                local linha = vim.fn.getline('.')
                if not linha:match('^<#part') then
                    print('Não foi possível obter arquivo de diretório para abrir o arquivo')
                    do return end
                end
                local arquivo = linha:match('filename="(.*)"'):match('C:.*'):gsub('\\', '/')
                if arquivo then
                    print(('Abrindo arquivo: %s'):format(arquivo))
                    open(arquivo)
                end
            end, opts)
            vim.keymap.set('n', 'gm', function()
                local conta = vim.fn['himalaya#domain#account#current']()
                if conta == '' then
                    conta = 'ouvidoria'
                end
                local template = vim.g.himalaya_pandoc_template_email .. '/' .. conta .. '.html'
                if vim.fn.filereadable(template) == 0 then
                    print('Pandoc: Arquivo template para e-mails não configurado!')
                    do return end
                end
                vim.cmd['!']({
                    'pandoc --template ' .. template .. ' -t html',
                    range = {5, vim.fn.line('$')},
                })
            end, opts)
		end,
	}
)

-- Dirvish mappings
-- remover backslash, se houver
autocmd(
	'FileType',
	{
		group = Andrikin,
		pattern = 'dirvish',
		callback = function(ev)
            local opts = { expr = true, buffer = ev.buf }
            vim.keymap.set('n', '.', function()
                local cmd = ':<c-u>! '
                if vim.fn.empty(vim.fn.getline(".")) == 1 then
                    cmd = cmd .. '%:gs?\\/?\\?\\'
                else
                    cmd = cmd .. vim.fn.shellescape(vim.fn.getline('.'):gsub('\\/', '\\'):gsub('\\$', ''), 1)
                end
                -- finalizando map
                cmd = cmd .. '<home><c-right>'
                return cmd
            end, opts)
            vim.keymap.set('n', 'go', function()
                local arquivo = vim.fn.getline('.'):gsub('\\', '\\/'):gsub('\\/$', ''):gsub('\\$', '')
                if vim.fn.fnamemodify(arquivo, ':e') ~= '' and vim.fn.isdirectory(arquivo) == 0 then
                    vim.fn.jobstart(
                        vim.fn.shellescape(arquivo, 1),
                        {detach = true}
                    )
                else
                    print('dirvish: não foi encontrado arquivo para abrir')
                    do return end
                end
            end, {silent = true, buffer = ev.buf})
		end,
	}
)

