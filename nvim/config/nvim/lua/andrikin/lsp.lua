-- Configuração de LSP servers

local notify = require('andrikin.utils').notify
if not notify then
    notify = print
end

-- lsp.diagnostic: Mensagem de erro mais curta
vim.diagnostic.config({
    underline = true,
})

-- colorizer.lua
require('colorizer').setup(nil, { css = true })

-- Lazydev -- Neovim 0.11
require('lazydev').setup()

if vim.fn.executable('x86_64-w64-mingw32-gcc') == 1 then
    vim.defer_fn( -- kickstart.nvim
        function()
            require('nvim-treesitter.install').compilers = {'x86_64-w64-mingw32-gcc', 'x86_64-w64-mingw32-clang', 'gcc', 'cc', 'clang'}
            require('nvim-treesitter.configs').setup({
                modules = {}, -- padrao
                ignore_install = {}, -- padrao
                auto_install = false, -- padrao
                sync_install = false, -- padrao
                ensure_installed = { -- parsers para highlight - treesitter
                    'css', 'html', 'javascript', 'vue',
                    'diff',
                    'git_config', 'git_rebase', 'gitattributes', 'gitcommit', 'gitignore',
                    'jsdoc', 'json', 'json5', 'java',
                    'lua', 'luadoc', 'luap', 'luau',
                    'markdown', 'markdown_inline',
                    'regex',
                    'xml',
                    'python',
                    'vim', 'vimdoc',
                    'latex',
                    -- https://github.com/folke/dot/blob/master/nvim/lua/plugins/treesitter.lua -- folke saying that comment slow TS
                    -- 'comment',
                    -- 'muttrc',
                },
                highlight = {
                    enable = true,
                    ---@diagnostic disable-next-line: unused-local
                    disable = function(lang, buf)
                        local max_filesize = 100 * 1024 -- 100 KB
                        ---@diagnostic disable-next-line: undefined-field
                        local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(buf))
                        if ok and stats and stats.size > max_filesize then
                            return true
                        end
                    end,
                    additional_vim_regex_highlighting = true,
                },
                indent = { enable = true },
            })
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
local ok, _ = pcall(require('telescope').load_extension, 'fzf')
if not ok then
    notify('Telescope: não foi possível carregar a extenção fzf.')
else
    notify('Telescope: extenção fzf carregada com sucesso')
end

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

-- Ativar LSP nos buffers, automaticamente -- Neovim 0.11
vim.lsp.enable({
    'luals',
    'texlab',
    'emmetls',
    'pyright',
    'denols',
    'vimls',
    'html',
    'jsonls',
    'cssls',
})
-- vim.lsp.set_log_level("debug")
