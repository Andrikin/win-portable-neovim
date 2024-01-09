-- TODO: autocmds para quickfix e localfix
-- Autocmds goosebumps
local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd
local AndrikinGroup = augroup('Andrikin', {})

-- Highlight linha quando entrar em InsertMode
autocmd(
	'InsertEnter',
	{
		group = AndrikinGroup,
		pattern = '*',
		callback = function() vim.opt_local.cursorline = true end,
	}
)
autocmd(
	'InsertLeave',
	{
		group = AndrikinGroup,
		pattern = '*',
		callback = function() vim.opt_local.cursorline = false end,
	}
)

-- Habilitar EmmetInstall
autocmd(
	'FileType',
	{
		group = AndrikinGroup,
		pattern = {'*.html', '*.css'},
		callback = vim.cmd.EmmetInstall,
	}
)

-- 'gq' para fechar help
autocmd(
	'FileType',
	{
		group = AndrikinGroup,
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
		group = AndrikinGroup,
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
		group = AndrikinGroup,
		pattern = {'quickfix', 'checkhealth'},
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
		group = AndrikinGroup,
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
		group = AndrikinGroup,
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
		group = AndrikinGroup,
		pattern = 'fugitive',
		callback = function()
			vim.cmd.resize(15)
		end,
	}
)

-- --- Builtin LSP commands ---
-- Only available in git projects (git init)
autocmd(
	'LspAttach',
	{
		group = AndrikinGroup,
		callback = function(ev)
			local opts = {buffer = ev.buf}
			vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts) -- TODO: on_list -> criar handler para retorno de listas
			vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
			vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
			vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
			vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
			vim.keymap.set('n', '<c-k>', vim.lsp.buf.signature_help, opts)
			vim.keymap.set('n', 'gs', vim.lsp.buf.rename, opts)
		end
	}
)

