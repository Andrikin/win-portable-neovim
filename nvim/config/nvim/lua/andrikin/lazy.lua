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
    'https://github.com/tpope/vim-fugitive.git',
	'https://github.com/tpope/vim-commentary.git',
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
        priority = 1000,
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
	-- Harpoon2 - The Primeagen,
	{
		'https://github.com/ThePrimeagen/harpoon.git',
		branch = "harpoon2",
	},
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
	{
        'https://github.com/neovim/nvim-lspconfig.git',
        dependencies = {
            'https://github.com/folke/neodev.nvim.git', -- signature help, docs and completion for nvim lua API
        }
    },
    -- Java LSP
	{
		'https://github.com/mfussenegger/nvim-jdtls.git',
		lazy = true,
	},
	-- Traces.vim,
	'https://github.com/markonm/traces.vim.git',
	-- Undotree,
	'https://github.com/mbbill/undotree.git',
	-- Nim-cmp,
	{
		'https://github.com/hrsh7th/nvim-cmp.git',
		dependencies = {
			'https://github.com/hrsh7th/cmp-nvim-lsp.git',
			'https://github.com/hrsh7th/cmp-path.git',
            'https://github.com/saadparwaiz1/cmp_luasnip.git',
			'https://github.com/L3MON4D3/LuaSnip.git',
            'https://github.com/rafamadriz/friendly-snippets.git',
			-- 'https://github.com/hrsh7th/cmp-buffer.git',
			-- 'https://github.com/hrsh7th/cmp-cmdline.git',
		},
	},
	-- Telescope,
	{
		'https://github.com/nvim-telescope/telescope.nvim.git',
        lazy = true,
		dependencies = {
			'https://github.com/nvim-lua/plenary.nvim.git',
            {
                'nvim-telescope/telescope-fzf-native.nvim',
                build = 'make',
                cond = function()
                    return vim.fn.executable('make') == 1
                end,
            },
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

-- builtin plugins
-- vim.cmd.packadd('cfilter') -- filtrar itens no quickfix/localfix list
-- vim.cmd.packadd('justify')
vim.cmd.packadd('matchit')
-- vim.cmd.packadd('shellmenu')
-- vim.cmd.packadd('swapmouse')
-- vim.cmd.packadd('termdebug')
-- vim.cmd.packadd('vimball')

