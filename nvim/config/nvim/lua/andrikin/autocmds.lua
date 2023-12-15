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
