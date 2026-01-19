---@diagnostic disable: param-type-mismatch
-- TODO: Usar vim.pack para gerenciamento de plugins no neovim 0.12+nightlY

local notify = require('andrikin.utils').notify
if not notify then
    notify = print
end

if not vim.opt.packpath._value:match("site") then
    vim.opt.packpath:prepend(vim.fn.stdpath('data') .. '\\site')
end

-- install plugins
vim.pack.add({
    -- colorscheme
    'https://github.com/biisal/blackhole',
    -- my plugins
    'https://github.com/Andrikin/awesome-pairing',
    'https://github.com/Andrikin/awesome-substitute',
    'https://github.com/Andrikin/vim-capslock',
    -- tim pope plugins
    'https://github.com/tpope/vim-fugitive.git',
    'https://github.com/tpope/vim-surround.git',
    'https://github.com/tpope/vim-eunuch.git',
    'https://github.com/tpope/vim-dadbod.git',
    -- plugins
    { src = 'https://github.com/ThePrimeagen/harpoon.git', version = 'harpoon2' },
    'https://github.com/romainl/vim-cool.git',
    'https://github.com/justinmk/vim-dirvish.git',
    'https://github.com/nvim-lualine/lualine.nvim',
    'https://github.com/neovim/nvim-lspconfig.git',
    'https://github.com/markonm/traces.vim.git',
    'https://github.com/Saghen/blink.cmp.git',
    'https://github.com/rafamadriz/friendly-snippets.git',
    'https://github.com/L3MON4D3/LuaSnip.git',
    'https://github.com/nvim-telescope/telescope.nvim.git',
    'https://github.com/nvim-lua/plenary.nvim.git',
    'https://github.com/nvim-telescope/telescope-ui-select.nvim',
    'https://github.com/glacambre/firenvim',
    'https://github.com/stevearc/dressing.nvim',
    -- ft = css, html, javascript
    'https://github.com/mattn/emmet-vim.git',
    'https://github.com/norcalli/nvim-colorizer.lua.git',
    -- ft = lua
    'https://github.com/folke/lazydev.nvim.git',
    -- ft = java
    'https://github.com/mfussenegger/nvim-jdtls.git',
})

if vim.fn.isdirectory(vim.fn.expand('$HOME') .. '\\nvim\\config\\firenvim') == 0 then
    vim.cmd("silent! call firenvim#install(1)")
else
    vim.cmd("silent! call firenvim#install(0)")
end

local gcc = vim.fn.executable('x86_64-w64-mingw32-gcc') == 1
if not gcc then
    vim.notify('Treesitter: Não foi possível encontrar compilador executável "gcc".')
else
    vim.pack.add({{
        src = 'https://github.com/nvim-treesitter/nvim-treesitter.git',
        version = 'main'
    }})
end

vim.cmd.colorscheme('blackhole')

if vim.fn.executable('x86_64-w64-mingw32-gcc') == 1 then
    vim.defer_fn( -- kickstart.nvim
        function()
            require('nvim-treesitter.install').compilers = {'x86_64-w64-mingw32-gcc', 'x86_64-w64-mingw32-clang', 'gcc', 'cc', 'clang'}
            require('nvim-treesitter').install({
                    'css', 'html', 'javascript', 'vue', 'typescript',
                    'diff',
                    'git_config', 'git_rebase', 'gitattributes', 'gitcommit', 'gitignore',
                    'jsdoc', 'json', 'json5', 'java',
                    'luadoc',
                    'regex',
                    'xml',
                    'latex',
                    'sql',
                    'powershell',
                    'jq',
                    'ini',
                    -- https://github.com/folke/dot/blob/master/nvim/lua/plugins/treesitter.lua -- folke saying that comment slow TS
                    -- 'comment',
                    -- DEFAULT Neovim 0.11:
                    'python',
                    'lua',
                    'markdown', 'markdown_inline',
                    'vim', 'vimdoc',
            })
            vim.opt.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
        0
    )
else
    notify('Instalar x86_64-w64-mingw32-gcc para utilizar nvim-treesitter!')
end

local _telescope = {
    tema = 'dropdown',
    actions = require('telescope.actions')
}
require('telescope').setup({
    extensions = { -- configurando extenções
        ["ui-select"] = {
            require("telescope.themes").get_dropdown()
        }
    },
    pickers = {
        buffers = {
            previewer = false,
            theme = _telescope.tema,
            mappings = {
                n = {
                    ['dd'] = _telescope.actions.delete_buffer,
                },
            },
        },
        find_files = {
            previewer = false,
            theme = _telescope.tema,
        },
        help_tags = {
            previewer = false,
            theme = _telescope.tema,
        },
        file_browser = {
            previewer = false,
            theme = _telescope.tema,
        },
    },
    defaults = {
        layout_config = {
            width = 0.5,
            height = 0.70,
        },
        path_display = {
            tail = true,
        },
        mappings = {
            i = {
                ['<c-j>'] = _telescope.actions.select_default + _telescope.actions.center,
                ['gq'] = _telescope.actions.close, -- ruim para as buscas que precisarem de "gq"
                ['<c-u>'] = {'<c-u>', type = 'command'},
                ['<esc>'] = {'<esc>', type = 'command'},
            },
            n = {
                ['<c-j>'] = _telescope.actions.select_default + _telescope.actions.center,
                ['gq'] = _telescope.actions.close,
            },
        },
    }
})
-- Carregando extenções do telescope
local carregar = function (extencao)
    local ok, _ = pcall(require('telescope').load_extension, extencao)
    if not ok then
        notify(('Telescope: não foi possível carregar a extenção %s.'):format(extencao))
    else
        notify(('Telescope: extenção %s carregada com sucesso'):format(extencao))
    end
end
carregar('fzf')
carregar('ui-select')

vim.cmd.packadd('telescope.nvim')
vim.cmd.packadd('nvim.difftool')
vim.cmd.packadd('nvim.undotree')

-- colorizer.lua
require('colorizer').setup({'css', 'html', 'javascript'})
-- Lazydev -- Neovim 0.11
require('lazydev').setup()
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

-- WARNING: caso remova configuração 'tabline'
-- não serão inicializados comandos deste componente
-- como, por exemplo, 'LualineRenameTab'.
-- Remover, portanto, autocomando para renomear
-- buffer checkhealth.
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
        prebuilt_binaries = { force_version = "1.8.0"},
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
