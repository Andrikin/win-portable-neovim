local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
-- Inicializando caminho para git
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

local TEMA = 'dracula'
local plugins = {
	-- Fork Tim Pope vim-capslock
	'https://github.com/Andrikin/vim-capslock',
	-- Tim Pope's miracles
	'https://github.com/tpope/vim-commentary.git',
	'https://github.com/tpope/vim-fugitive.git',
	'https://github.com/tpope/vim-surround.git',
	{
		'https://github.com/tpope/vim-dadbod.git',
		lazy = true,
	},
	{
		'https://github.com/tpope/vim-eunuch.git',
		lazy = true,
	},
	{
		'https://github.com/tpope/vim-obsession.git',
		lazy = true,
	},
	-- Dracula theme,
	{
		'https://github.com/Mofiqul/dracula.nvim.git',
		config = function()
			vim.cmd.colorscheme(TEMA)
		end
	},
	-- Vim Cool,
	'https://github.com/romainl/vim-cool.git',
	-- Dirvirsh,
	'https://github.com/justinmk/vim-dirvish.git',
	-- Emmet,
	{
		'https://github.com/mattn/emmet-vim.git',
		lazy = true,
	},
	-- Harpoon - The Primeagen,
	'https://github.com/ThePrimeagen/harpoon.git',
	-- Lightline,
	-- 'https://github.com/itchyny/lightline.vim.git',
	-- Lualine,
	{
		'https://github.com/nvim-lualine/lualine.nvim',
		config = function()
			require('lualine').setup(
				{
					options = { theme = TEMA },
					winbar = {
						lualine_a = {},
						lualine_b = {},
						lualine_c = {'filename'},
						lualine_x = {},
						lualine_y = {},
						lualine_z = {}
					}
				}
			)
		end
	},
	-- Nvim-Colorizer,
	{
		'https://github.com/norcalli/nvim-colorizer.lua.git',
		lazy = true,
	},
	-- Nvim Lspconfig,
	'https://github.com/neovim/nvim-lspconfig.git',
	{
		'https://github.com/mfussenegger/nvim-jdtls.git',
		lazy = true,
		-- config = function()
		-- end,
	},
	-- Traces.vim,
	'https://github.com/markonm/traces.vim.git',
	-- Nvim-ts-context-commentstring,
	-- 'https://github.com/JoosepAlviste/nvim-ts-context-commentstring.git',
	-- Undotree,
	'https://github.com/mbbill/undotree.git',
	-- Nim-cmp,
	{
		'https://github.com/hrsh7th/nvim-cmp.git',
		event = 'InsertEnter',
		dependencies = {
			'https://github.com/hrsh7th/cmp-nvim-lsp.git',
			'https://github.com/hrsh7th/cmp-buffer.git',
			'https://github.com/hrsh7th/cmp-path.git',
			'https://github.com/hrsh7th/cmp-cmdline.git',
		},
	},
	-- Telescope,
	{
		'https://github.com/nvim-telescope/telescope.nvim.git',
		dependencies = {
			'https://github.com/nvim-lua/plenary.nvim.git',
		},
	},
	-- Treesitter,
	'https://github.com/nvim-treesitter/nvim-treesitter.git',
	{
		'https://github.com/nvim-treesitter/playground.git',
		lazy = true,
	},
}

local opts = {
	performance = {
		rtp = {
			disabled_plugins = {
				-- "gzip",
				-- "matchit",
				-- "matchparen",
				"netrwPlugin",
				-- "tarPlugin",
				-- "tohtml",
				-- "tutor",
				-- "zipPlugin",
			},
		},
	},
}

require("lazy").setup(plugins, opts)

