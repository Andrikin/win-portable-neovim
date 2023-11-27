-- CUSTOM MAPS
-- INFO: Função: vim.keymap.set()

local harpoon_add = require('harpoon.mark')
local harpoon_ui = require('harpoon.ui')

-- CTRL-U in insert mode deletes a lot. Use CTRL-G u to first break undo,
-- so that you can undo CTRL-U after inserting a line break.
-- Revert with ":iunmap <C-U>". -> from defaults.vim
vim.keymap.set('i', '<c-u>', '<c-g>u<c-u>')
vim.keymap.set('i', '<c-w>', '<c-g>u<c-w>')
vim.keymap.set('n', '<backspace>', 'X')
vim.keymap.set('n', '<c-h>', 'X')
vim.keymap.set('n', "'", '`')
-- Fix & command. Redo :substitute command
vim.keymap.set(
	{'n', 'x'},
	'&',
	function()
		pcall(
			vim.cmd('&&')
		)
	end
)
-- Yank to end of sreen line. Make default in Neovim 0.6.0
-- g$ cursor after last character, g_ cursor at last character
-- vim.keymap.set('n', 'Y', 'yg_')
-- Disable <c-z> (:stop)
vim.keymap.set('n', '<c-z>', '<nop>')
-- Join lines in a better way - From a video of ThePrimeagen
vim.keymap.set('n', 'J', 'mzJ`z')
-- Undo better - inserting breaking points, thanks to ThePrimeagen
vim.keymap.set('i', ',', ',<c-g>u')
vim.keymap.set('i', '.', '.<c-g>u')

-- Using gk and gj (screen cursor up/down)
-- nnoremap <expr> k v:count == 0 ? 'gk' : 'k'
-- nnoremap <expr> j v:count == 0 ? 'gj' : 'j'
-- Adding jumps to jumplist - The Primeagen gold apple with gk and gj (screen cursor up/down)
vim.keymap.set(
	'n',
	'k',
	function()
		local count = vim.v.count
		local marcador = ''
		if count > 1 then
			marcador = 'm`' .. count
		end
		if count == 0 then
			return marcador .. 'gk'
		end
		return marcador .. 'k'
	end,
	{ expr = true }
)
vim.keymap.set(
	'n',
	'j',
	function()
		local count = vim.v.count
		local marcador = ''
		if count > 1 then
			marcador = 'm`' .. count
		end
		if count == 0 then
			return marcador .. 'gj'
		end
		return marcador .. 'j'
	end,
	{ expr = true }
)

-- Moving lines up and down - The Primeagen knowledge word
-- inoremap <c-j> <c-o>:m.+1<cr> " utilizo muito <c-j> para newlines, seria inviável trocar para essa funcionalidade
-- inoremap <c-k> <c-o>:m.-2<cr>
-- nnoremap <leader>k <cmd>m.-2<cr>
-- nnoremap <leader>j <cmd>m.+1<cr>
vim.keymap.set('v', 'K', ":m'<-2<cr>gv")
vim.keymap.set('v', 'J', ":m'>+1<cr>gv")

-- Copy and paste from clipboard (* -> selection register/+ -> primary register)
vim.keymap.set('n', 'gP', '"+P')
vim.keymap.set('n', 'gp', '"+p')
vim.keymap.set('v', 'gy', '"+y')
vim.keymap.set('n', 'gy', '"+y')
vim.keymap.set('n', 'gY', '"+Y')

-- Fix c-] (nvim-qt)
vim.keymap.set('n', '<c-\\>', '<c-]>')

-- --- Mapleader Commands ---

-- open $MYVIMRC
vim.keymap.set(
	'n',
	'<leader>r',
	function()
		if vim.g.loaded_dirvish == 1 then -- plugin ativo
			vim.cmd.Dirvish(
				vim.fn.fnamemodify(vim.env.MYVIMRC, ':h') .. '/lua/andrikin'
			)
		else
			vim.cmd.edit(
				vim.fn.fnamemodify(vim.env.MYVIMRC, ':h') .. '/lua/andrikin/init.lua'
			)
		end
	end
)

-- --- Quickfix window ---
-- NeoVim excells about terminal jobs
-- nnoremap <silent> <leader>m <cmd>make %:S<cr>
-- TODO: Reescrever estas funções
-- Toggle quickfix window
-- nnoremap <silent> <expr> <leader>c <SID>toggle_list('c')
-- nnoremap <silent> <expr> <leader>l <SID>toggle_list('l')
-- nnoremap <silent> <expr> <leader>q <SID>quit_list()
-- -- Terminal
-- nnoremap <silent> <expr> <leader>t <SID>toggle_terminal()
-- vim.keymap.set(
-- 	'n',
-- 	'<leader>t',
-- 	function()
-- 	end,
-- 	{
-- 		silent = true,
-- 		expr = true,
-- 	}
-- )

-- Undotree plugin
vim.keymap.set(
	'n',
	'<leader>u',
	vim.cmd.UndotreeToggle
)

-- Fugitive maps
vim.keymap.set(
	'n',
	'<leader>g',
	vim.cmd.Git
)

-- --- Telescope ---
vim.keymap.set(
	'n',
	'<leader>b',
	function()
		vim.cmd.Telescope('buffers')
	end
)

-- The Primeagen Harpoon
vim.keymap.set(
	'n',
	'gha',
	harpoon_add.add_file
)
vim.keymap.set(
	'n',
	'ghh',
	harpoon_ui.toggle_quick_menu
)
vim.keymap.set(
	'n',
	'gh1',
	function()
		harpoon_ui.nav_file(1)
	end
)
vim.keymap.set(
	'n',
	'gh2',
	function()
		harpoon_ui.nav_file(2)
	end
)
vim.keymap.set(
	'n',
	'gh3',
	function()
		harpoon_ui.nav_file(3)
	end
)
vim.keymap.set(
	'n',
	'gh4',
	function()
		harpoon_ui.nav_file(4)
	end
)

-- --- Builtin LSP commands ---
-- Only available in git projects (git init)
local lsp = function(opt)
	vim.keymap.set(
		'n',
		opt.key,
		opt.map
	)
end
local lsp_maps = {
	{
		key = 'K',
		map = vim.lsp.buf.hover,
	},
	{
		key = 'gr',
		map = vim.lsp.buf.references,
	},
	{
		key = 'gd',
		map = vim.lsp.buf.definition,
	},
	{
		key = 'gD',
		map = vim.lsp.buf.declaration,
	},
	{
		key = '<c-k>',
		map = vim.lsp.buf.signature_help,
	},
	{
		key = ']e',
		map = vim.diagnostic.goto_next,
	},
	{
		key = '[e',
		map = vim.diagnostic.goto_prev,
	}
}
for _,m in ipairs(lsp_maps) do
	lsp(m)
end
vim.keymap.set(
	'n',
	'<leader>e',
	vim.diagnostic.open_float
)
vim.keymap.set(
	'n',
	'<leader>s',
	vim.lsp.buf.rename
)

