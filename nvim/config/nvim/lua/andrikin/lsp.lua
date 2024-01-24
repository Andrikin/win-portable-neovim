-- Configuração de LSP servers

local notify = require('andrikin.utils').notify

-- colorizer.lua
require('colorizer').setup(nil, { css = true })

-- Neodev
require('neodev').setup()

vim.defer_fn( -- kickstart.nvim
    function()
        require('nvim-treesitter.install').compilers = {'gcc', 'cc', 'clang'}
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
                'comment',
            },
            highlight = {
                enable = true,
                additional_vim_regex_highlighting = true,
            },
            indent = { enable = true },
        })
    end,
    0
)

local telescope_tema = 'dropdown'
local telescope_actions = require('telescope.actions')
require('telescope').setup({
    -- Playground configuration, extracted from github https://github.com/nvim-treesitter/playground
    playground = {
        enable = true,
        disable = {},
        updatetime = 25, -- Debounced time for highlighting nodes in the playground from source code
        persist_queries = false, -- Whether the query persists across vim sessions
        keybindings = {
            toggle_query_editor = 'o',
            toggle_hl_groups = 'i',
            toggle_injected_languages = 't',
            toggle_anonymous_nodes = 'a',
            toggle_language_display = 'I',
            focus_language = 'f',
            unfocus_language = 'F',
            update = 'R',
            goto_node = '<cr>',
            show_help = '?',
        },
    },
    pickers = {
        buffers = {
            previewer = false,
            theme = telescope_tema,
            mappings = {
                n = {
                    ['dd'] = telescope_actions.delete_buffer,
                },
            },
        },
        find_files = {
            previewer = false,
            theme = telescope_tema,
        },
        file_browser = {
            previewer = false,
            theme = telescope_tema,
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
                ['<NL>'] = telescope_actions.select_default + telescope_actions.center,
                -- ['<esc>'] = telescope_actions.close,
                ['<c-u>'] = {'<c-u>', type = 'command'},
            },
            n = {
                ['<NL>'] = telescope_actions.select_default + telescope_actions.center,
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

local cmp = require('cmp')
local luasnip = require('luasnip')

require('luasnip.loaders.from_vscode').lazy_load() -- carregar snippets (templates)
luasnip.config.setup({})

cmp.setup({
    snippet = {
        -- REQUIRED - you must specify a snippet engine
        expand = function(args)
            -- vim.fn['vsnip#anonymous'](args.body) -- For `vsnip` users.
            require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
            -- require('snippy').expand_snippet(args.body) -- For `snippy` users.
            -- vim.fn['UltiSnips#Anon'](args.body) -- For `ultisnips` users.
        end,
    },
    completion = {
        completeopt = vim.o.completeopt,
    },
    window = {
        -- completion = cmp.config.window.bordered(),
        -- documentation = cmp.config.window.bordered(),
    },
    mapping = cmp.mapping.preset.insert({
        ['<c-n>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.select_next_item({behavior = cmp.SelectBehavior.Select})
                -- You could replace the expand_or_jumpable() calls with expand_or_locally_jumpable() 
                -- that way you will only jump inside the snippet region
            elseif luasnip.expand_or_jumpable() then
                luasnip.expand_or_jump()
            elseif cmp.complete() then
                do return end
            else
                fallback()
            end
        end, { 'i', 's' }),
        ['<c-p>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.select_prev_item({behavior = cmp.SelectBehavior.Select})
            elseif luasnip.jumpable(-1) then
                luasnip.jump(-1)
            else
                fallback()
            end
        end, { 'i', 's' }),
        -- ['<C-n>'] = cmp.mapping.select_next_item({behavior = cmp.SelectBehavior.Select}), -- backup
        -- ['<C-p>'] = cmp.mapping.select_prev_item({behavior = cmp.SelectBehavior.Select}), -- backup
        ['<C-b>'] = cmp.mapping.scroll_docs(-4),
        ['<C-f>'] = cmp.mapping.scroll_docs(4),
        ['<C-Space>'] = cmp.mapping.complete(),
        ['<CR>'] = cmp.mapping.confirm({ select = false }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
    }),
    sources = cmp.config.sources({
        { name = 'nvim_lsp' },
        -- { name = 'vsnip' }, -- For vsnip users.
        { name = 'luasnip' }, -- For luasnip users.
        -- { name = 'ultisnips' }, -- For ultisnips users.
        -- { name = 'snippy' }, -- For snippy users.
        }, {
            -- { name = 'buffer' },
            { name = 'path' },
            -- {
            --     name = 'buffer',
            --     option = {
            --         get_bufnrs = function()
            --             local bufs = {}
            --             for _, win in ipairs(vim.api.nvim_list_wins()) do
            --                 bufs[vim.api.nvim_win_get_buf(win)] = true
            --             end
            --             return vim.tbl_keys(bufs)
            --         end
            --     }
            -- },
    })
})

-- Set up lspconfig.
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

-- LSP SERVERS 
local lsp = require('lspconfig')

-- Emmet LSP
lsp.emmet_ls.setup({ -- npm install -g emmet-ls
    capabilities = capabilities
})

-- Python LSP
lsp.pyright.setup({ -- pip install pyright | npm -g install pyright
    capabilities = capabilities
})

-- Javascript LSP
lsp.denols.setup({
    capabilities = capabilities
})

-- LaTeX LSP
lsp.texlab.setup({
    capabilities = capabilities
})

-- Java LSP
lsp.jdtls.setup({
    capabilities = capabilities
})

-- Vim LSP
lsp.vimls.setup({
    capabilities = capabilities
})

-- VSCODE LSP PACKAGE
-- HTML
lsp.html.setup({ -- npm i -g vscode-langservers-extracted
    capabilities = capabilities
})
-- JSON
lsp.jsonls.setup({ -- npm i -g vscode-langservers-extracted
    capabilities = capabilities
})
-- CSS
lsp.cssls.setup({ -- npm i -g vscode-langservers-extracted
    capabilities = capabilities
})
-- WARNING: Utilizar denols
-- JS
-- lsp.eslint.setup({ -- npm i -g vscode-langservers-extracted
--     capabilities = capabilities,
--     on_attach = function(_, bufnr)
--         vim.api.nvim_create_autocmd('BufWritePre', {
--             buffer = bufnr,
--             command = 'EslintFixAll',
--         })
--     end,
-- })

-- -- Rust LSP
-- lsp.rust_analyzer.setup({
--    capabilities = capabilities
-- })

-- Lua LSP
lsp.lua_ls.setup({
    capabilities = capabilities,
    on_init = function(client)
        local path = client.workspace_folders[1].name
        if not vim.loop.fs_stat(path .. '/.luarc.json') and not vim.loop.fs_stat(path .. '/.luarc.jsonc') then
            client.config.settings = vim.tbl_deep_extend('force', client.config.settings, {
                Lua = {
                    completion = { -- folke/neodev configuration
                        callSnippet = "Replace"
                    },
                    -- runtime = { -- comentado para funcionamento do neodev
                    --     -- Tell the language server which version of Lua you're using
                    --     -- (most likely LuaJIT in the case of Neovim)
                    --     version = 'LuaJIT'
                    -- },
                    -- Make the server aware of Neovim runtime files
                    -- workspace = {
                    --     checkThirdParty = false,
                    --     library = {
                    --         vim.env.VIMRUNTIME
                    --         -- '${3rd}/luv/library'
                    --         -- '${3rd}/busted/library',
                    --     }
                    --     -- or pull in all of 'runtimepath'. NOTE: this is a lot slower
                    --     -- library = vim.api.nvim_get_runtime_file('', true)
                    -- },
                    diagnostics = {
                        -- Get the language server to recognize the `vim` global
                        globals = {'vim'},
                    },
                }
            })
            client.notify('workspace/didChangeConfiguration', { settings = client.config.settings })
        end
        return true
    end
})

