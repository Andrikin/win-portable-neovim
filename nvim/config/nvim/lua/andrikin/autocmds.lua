-- Autocmds goosebumps
local autocmd = vim.api.nvim_create_autocmd
local Andrikin = vim.api.nvim_create_augroup('Andrikin', {clear = true})
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

-- Habilitar EmmetInstall
autocmd(
	'FileType',
	{
		group = Andrikin,
		pattern = {'*.html', '*.css'},
		callback = vim.cmd.EmmetInstall,
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
		pattern = {'qf', 'checkhealth', 'help'},
		callback = function(args)
			vim.keymap.set(
				'n',
				'gq',
                vim.cmd.quit,
				{
					silent = true,
					buffer = args.buf,
				}
			)
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
			vim.highlight.on_yank(
				{
					higroup = 'IncSearch',
					timeout = 300,
				}
			)
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
			require('cmp').setup(
				{
					enabled = false
				}
			)
		end,
	}
)

-- Redimensionar janelas do Fugitive
autocmd(
	'FileType',
	{
		group = Andrikin,
		pattern = 'fugitive',
		callback = function()
			vim.cmd.resize(15)
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
			vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
			vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
			vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
			vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
			vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
			vim.keymap.set('n', '<c-k>', vim.lsp.buf.signature_help, opts)
			vim.keymap.set('n', 'gs', vim.lsp.buf.rename, opts)
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
                end)
                vim.keymap.set("i", "<c-p>", function(fallback)
                    if cmp.visible() then
                        cmp.select_prev_item({behavior = cmp.SelectBehavior.Select})
                    elseif luasnip.jumpable(-1) then
                        luasnip.jump(-1)
                    elseif not cmp.complete() then
                        fallback()
                    end
                end)
                vim.keymap.set("i", "<c-y>", function()
                    cmp.confirm({select = false})
                end)
                vim.keymap.set("i", "<cr>", function() -- insert word and skip from INSERT MODE
                    cmp.confirm({select = false})
                    local esc = vim.api.nvim_replace_termcodes("<esc>", true, false, true)
                    vim.api.nvim_feedkeys(esc, 'n', false)
                end)
                vim.keymap.set("i", "<c-e>", function()
                    cmp.abort()
                end)
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
            local opts = { buffer = true }
            vim.keymap.set('n', 'k', function() mover:k() end, opts)
            vim.keymap.set('n', 'j', function() mover:j() end, opts)
            vim.keymap.set('n', '<cr>', function() mover:enter() end, opts)
            vim.keymap.set('n', 'i', function() mover.i() end, opts)
            -- ... adicionar mais comandos para quickfix/loclist
		end,
	}
)

