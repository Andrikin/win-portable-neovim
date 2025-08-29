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
