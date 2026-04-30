---@diagnostic disable: param-type-mismatch
-- TODO: Usar vim.pack para gerenciamento de plugins no neovim 0.12+nightly

local notify = require('andrikin.utils').notify
if not notify then
    notify = vim.print
end

-- install plugins
vim.pack.add({
    -- colorscheme
    'https://github.com/biisal/blackhole',
    -- my plugins and forks
    'https://github.com/Andrikin/awesome-pairing',
    'https://github.com/Andrikin/awesome-substitute',
    'https://github.com/Andrikin/vim-capslock',
    -- tim pope pieces of miracles - plugins
    'https://github.com/tpope/vim-fugitive.git',
    'https://github.com/tpope/vim-surround.git',
    'https://github.com/tpope/vim-eunuch.git',
    'https://github.com/tpope/vim-dadbod.git',
    -- plugins
    { src = 'https://github.com/ThePrimeagen/harpoon.git', version = 'harpoon2' },
    -- harpoon dependency
    'https://github.com/nvim-lua/plenary.nvim.git',
    'https://github.com/romainl/vim-cool.git',
    'https://github.com/justinmk/vim-dirvish.git',
    'https://github.com/nvim-lualine/lualine.nvim',
    'https://github.com/neovim/nvim-lspconfig.git',
    { src = 'https://github.com/Saghen/blink.cmp', version = 'v1' },
    -- 'https://github.com/Saghen/blink.lib',
    'https://github.com/rafamadriz/friendly-snippets.git',
    'https://github.com/L3MON4D3/LuaSnip.git',
    'https://github.com/glacambre/firenvim',
    'https://github.com/stevearc/dressing.nvim',
    'https://github.com/nvim-mini/mini.pick',
    -- ft = css, html, javascript
    'https://github.com/mattn/emmet-vim.git',
    -- 'https://github.com/norcalli/nvim-colorizer.lua.git', -- outdated
    'https://github.com/catgoose/nvim-colorizer.lua.git',
    -- ft = lua
    'https://github.com/folke/lazydev.nvim.git',
    -- ft = java
    'https://github.com/mfussenegger/nvim-jdtls.git',
})

if vim.fn.isdirectory(vim.fn.expand('$HOME') .. '\\nvim\\config\\firenvim') == 0 then
    vim.cmd.packadd("firenvim")
    vim.cmd("silent! call firenvim#install(1)")
else
    if vim.g.firenvim_loaded then
        vim.cmd("silent! call firenvim#install(0)")
    end
end

local gcc = vim.fn.executable('x86_64-w64-mingw32-gcc') == 1
if not gcc then
    vim.notify('Treesitter: Não foi possível encontrar compilador executável "gcc".')
    pcall(vim.cmd.Cygwin, 'install x86_64-w64-mingw32-gcc')
else
    vim.pack.add({{
        src = 'https://github.com/nvim-treesitter/nvim-treesitter.git',
        version = 'main'
    }})
    require('nvim-treesitter').install({
        'python',
        'diff',
        'luadoc',
        'latex',
        'regex',
        'git_config', 'git_rebase', 'gitattributes', 'gitcommit', 'gitignore',
        'css', 'html', 'javascript', 'vue', 'typescript',
        'jsdoc', 'json', 'json5', 'java',
        'powershell',
        'xml',
        'sql',
        'jq',
        'ini',
        'rust',
        'zig',
        -- https://github.com/folke/dot/blob/master/nvim/lua/plugins/treesitter.lua
        -- folke saying that "comment" slow TS
        -- 'comment',
        -- DEFAULT Neovim 0.11:
        'c',
        'lua',
        'query',
        'markdown', 'markdown_inline',
        'vim', 'vimdoc',
    })
    -- vim.o.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    -- vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
    -- vim.wo.foldmethod = 'expr'
end

-- Colorscheme
vim.o.termguicolors = true
vim.cmd.colorscheme('blackhole')

vim.cmd.packadd('nvim.difftool')
vim.cmd.packadd('nvim.undotree')
vim.cmd.packadd('justify')

-- experimental: ui2
require('vim._core.ui2').enable()
-- spellfile.vim
require('nvim.spellfile').config()
-- colorizer.lua
require('colorizer').setup({ filetype = {'css', 'html', 'javascript'}, lazy_load = true })
-- Lazydev -- Neovim 0.11
require('lazydev').setup()
-- mini.pick
require('mini.pick').setup({
    window= {
        config = function()
            local height = math.floor(0.3 * vim.o.lines)
            local width = math.floor(0.7 * vim.o.columns)
            return {
                anchor = 'NW', height = height, width = width,
                row = math.floor(0.5 * (vim.o.lines - height)),
                col = math.floor(0.5 * (vim.o.columns - width)),
            }
        end
    }
})
-- carregar snippets (LuaSnip)
require('luasnip').config.set_config({
	history = true,
})
require('luasnip.loaders.from_vscode').lazy_load() -- carregar snippets (templates)
require('luasnip.loaders.from_lua').lazy_load({
---@diagnostic disable-next-line: assign-type-mismatch
    paths = vim.fs.joinpath(
        ---@diagnostic disable-next-line: param-type-mismatch
        vim.fn.stdpath('config'),
        'snippets'
    )
})
require('dressing').setup({
    input = {
        mappings = {
            i = {
                ['<NL>'] = "Confirm",
            }
        }
    }
})
-- WARNING: caso remova configuração 'tabline' não serão inicializados comandos
-- deste componente como, por exemplo, 'LualineRenameTab'. Remover, portanto,
-- autocomando para renomear buffer checkhealth.
require('lualine').setup({
    options = { theme = 'auto',
        component_separators = { left = '', right = ''},
        section_separators = { left = '', right = ''},
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
})
-- blink.cmp configuration
local rust = vim.fn.executable('cargo.exe') == 1
if not rust then
    notify("rust: Não foi encontrado executável do 'rust'. Verificar instalação.")
    do return end
end
-- compile fuzzy for blink.cmp - v2
-- require('blink.cmp').build():wait(240000)
require('blink.cmp').setup({
    enabled = function ()
        return not vim.tbl_contains({ "vim"}, vim.bo.filetype)
    end,
    cmdline = { enabled = false },
    snippets = { preset = 'luasnip' },
    fuzzy = {
        sorts = {
            'exact',
            -- defaults
            'score',
            'sort_text',
        },
        implementation = "prefer_rust_with_warning",
    },
    keymap = {
        preset = 'default',
        ['<c-space>'] = {},
    },
    -- (Default) Only show the documentation popup when manually triggered
    completion = {
        menu = {
            -- auto_show = false,
            -- border = vim.o.winborder, -- default for 0.11+
            draw = {
                columns = { { "label", "label_description", gap = 1 }, { "kind" } },
            }
        },
        list = {
            selection = {
                preselect = false, auto_insert = true
            }
        },
        documentation = { auto_show = false }
    },
    -- Default list of enabled providers defined so that you can extend it
    -- elsewhere in your config, without redefining it, due to `opts_extend`
    sources = {
        providers = {
            cmdline = { enabled = false }
        },
        default = { 'lsp', 'snippets', 'buffer', 'path' },
    },
})

