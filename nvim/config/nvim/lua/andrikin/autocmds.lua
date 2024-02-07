-- Autocmds goosebumps
local autocmd = vim.api.nvim_create_autocmd
local Andrikin = vim.api.nvim_create_augroup('Andrikin', {})

-- Highlight linha quando entrar em InsertMode
autocmd(
	'InsertEnter',
	{
		group = Andrikin,
		pattern = '*',
		callback = function() vim.opt_local.cursorline = true end,
	}
)
autocmd(
	'InsertLeave',
	{
		group = Andrikin,
		pattern = '*',
		callback = function() vim.opt_local.cursorline = false end,
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

-- 'gq' para fechar help
autocmd(
	'FileType',
	{
		group = Andrikin,
		pattern = 'help',
		callback = function(args)
			vim.keymap.set(
				'n',
				'gq',
				vim.cmd.helpclose,
				{
					silent = true,
					buffer = args.buf,
				}
			)
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

-- 'gq' para fechar quickfix list
autocmd(
	'FileType',
	{
		group = Andrikin,
		pattern = {'qf', 'checkhealth'},
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

--- Forçar nvim-cmp a mostrar autocompletion
-- autocmd(
--     {"TextChangedI", "TextChangedP"},
--     {
--         callback = function()
--             local cmp = require('cmp')
--             local line = vim.api.nvim_get_current_line()
--             local cursor = vim.api.nvim_win_get_cursor(0)[2]
--             local current = string.sub(line, cursor, cursor + 1)
--             if current == "." or current == "," or current == " " then
--                 cmp.close()
--             end
--             local before_line = string.sub(line, 1, cursor + 1)
--             local after_line = string.sub(line, cursor + 1, -1)
--             if not string.match(before_line, '^%s+$') then
--                 if after_line == "" or string.match(before_line, " $") or string.match(before_line, "%.$") then
--                     cmp.complete()
--                 end
--             end
--         end,
--         pattern = "*"
--     }
-- )

