local notify = require('andrikin.utils').notify
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

-- Clonando git ouvidoria-latex-modelos
---@type Diretorio
local Projetos = require('andrikin.utils').PROJETOS
local ModelosLatex = (Projetos / 'ouvidoria-latex-modelos').diretorio
local Ssh = require('andrikin.utils').Ssh.destino.diretorio
if vim.fn.isdirectory(ModelosLatex) == 0 then
    local diretorio_projetos = vim.fn.isdirectory(Projetos.diretorio) == 1
    local diretorio_ssh = vim.fn.isdirectory(Ssh) == 1
    if diretorio_projetos and diretorio_ssh then
        vim.fn.system({
            "git",
            "clone",
            "git@github.com:Andrikin/ouvidoria-latex-modelos",
            ModelosLatex,
        })
    else
        if not diretorio_ssh then
            notify("Git: não foi encontrado o diretório '.ssh'.")
        end
        if not diretorio_projetos then
            notify("Git: não foi encontrado o diretório 'projetos'.")
        end
    end
else
    notify('Git: projeto com os modelos de LaTeX já está baixado!')
end

-- Temas - interface: nome, url
local tokyonight = {
    nome = 'tokyonight',
    url = 'https://github.com/folke/tokyonight.nvim.git',
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

local plugins = {
	-- Fork Tim Pope vim-capslock
	'https://github.com/Andrikin/vim-capslock',
	-- Tim Pope's miracles
    'https://github.com/tpope/vim-fugitive.git',
	'https://github.com/tpope/vim-commentary.git',
	'https://github.com/tpope/vim-surround.git',
    {
        'https://github.com/tpope/vim-eunuch.git',
        lazy = vim.fn.executable('rm') == 0 and vim.fn.executable('mkdir') == 0,
    },
	{
		'https://github.com/tpope/vim-dadbod.git',
		lazy = true,
	},
	{
		'https://github.com/tpope/vim-obsession.git',
		lazy = true,
	},
    -- Theme
    {
        tema.url,
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
					options = { theme = tema.nome },
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
	},
	-- Nvim Lspconfig,
	{
        'https://github.com/neovim/nvim-lspconfig.git',
        dependencies = {
            'https://github.com/folke/neodev.nvim.git', -- signature help, docs and completion for nvim lua API
            { 'https://github.com/j-hui/fidget.nvim.git',
                opts = {
                    progress = {
                        display = {
                            skip_history = false,
                        }
                    }
                }
            },
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
			'https://github.com/hrsh7th/cmp-buffer.git',
			'https://github.com/hrsh7th/cmp-path.git',
			'https://github.com/L3MON4D3/LuaSnip.git',
            'https://github.com/saadparwaiz1/cmp_luasnip.git',
            'https://github.com/rafamadriz/friendly-snippets.git',
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

