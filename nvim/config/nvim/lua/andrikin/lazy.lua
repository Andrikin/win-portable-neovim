local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
-- Inicializando caminho para git
---@diagnostic disable-next-line: undefined-field
if not vim.uv.fs_stat(lazypath) then
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

-- Temas - interface: nome, url
local tokyonight = {
    nome = 'tokyonight',
    link = 'https://github.com/folke/tokyonight.nvim.git',
    -- config = function()
    --     vim.api.nvim_set_hl(0, 'CursorLine', {link = 'Visual'})
    -- end
}
-- local dracula = {
--     nome = 'dracula',
--     url = 'https://github.com/Mofiqul/dracula.nvim.git'
-- }
local tema = tokyonight
if tema.config then
    tema.config()
end

local has_rm = vim.fn.executable('rm') == 1
local has_mkdir = vim.fn.executable('mkdir') == 1
local plugins = {
	-- Fork Tim Pope vim-capslock
	'https://github.com/Andrikin/vim-capslock',
	-- Tim Pope's miracles
    'https://github.com/tpope/vim-fugitive.git',
	'https://github.com/tpope/vim-surround.git',
    {
        'https://github.com/tpope/vim-eunuch.git',
        enabled = has_rm and has_mkdir,
    },
	{
		'https://github.com/tpope/vim-dadbod.git',
		lazy = true,
	},
    -- Theme
    {
        tema.link,
        priority = 1000,
        lazy = false,
		config = function()
			vim.cmd.colorscheme(tema.nome)
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
        ft = {'css', 'html'},
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
					options = { theme = tema.nome,
						always_show_tabline = false,
					},
                    sections = {
						lualine_a = {'mode', 'CapsLockStatusline'},
                    },
					winbar = {
						lualine_a = {},
						lualine_b = {},
						lualine_c = {'filename'},
						lualine_x = {},
						lualine_y = {},
						lualine_z = {}
					},
                    tabline = {
                        lualine_a = {
                            {
                                'tabs',
                                mode = 1,
                                path = 0,
                            },
                        },
                    }
				}
			)
		end
	},
	-- Nvim-Colorizer,
	{
		'https://github.com/norcalli/nvim-colorizer.lua.git',
		lazy = true,
        ft = {'css', 'html'},
	},
	-- Nvim Lspconfig,
	{
        'https://github.com/neovim/nvim-lspconfig.git',
        dependencies = {
            'https://github.com/folke/lazydev.nvim.git', -- signature help, docs and completion for nvim lua API
        }
    },
    -- Java LSP
	{
		'https://github.com/mfussenegger/nvim-jdtls.git',
		lazy = true,
        ft = {'java'},
	},
	-- Traces.vim,
	'https://github.com/markonm/traces.vim.git',
	-- Undotree,
	'https://github.com/mbbill/undotree.git',
    -- Snippets
    {
        'https://github.com/L3MON4D3/LuaSnip.git',
        dependencies = 'https://github.com/rafamadriz/friendly-snippets.git',
    },
    -- Telescope
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
    {
        'https://github.com/nvim-treesitter/nvim-treesitter.git',
        build = ':TSUpdate',
        cond = function()
            return vim.fn.executable('x86_64-w64-mingw32-gcc') == 1
        end
    },
    {
---@diagnostic disable-next-line: undefined-field
        dir = vim.uv.os_homedir() .. '/Documents/nvim/projetos/himalaya-vim',
        lazy = true,
        dev = true,
        enabled = function() return vim.fn.executable('himalaya') == 1 end,
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
    rocks = {
        hererocks = false,
        enabled = false,
    }
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

