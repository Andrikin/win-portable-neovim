---@diagnostic disable: need-check-nil
-- Configuração de LSP servers

local win7 = require('andrikin.utils').win7
local notify = require('andrikin.utils').notify

-- colorizer.lua
require('colorizer').setup(nil, { css = true })

-- Lazydev or Neodev
if win7 then
	require('neodev').setup()
else
	require('lazydev').setup()
end

-- TODO: Verificar se é possí
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
                    'muttrc',
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
else
    notify('Instalar x86_64-w64-mingw32-gcc para utilizar nvim-treesitter!')
end

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
        help_tags = {
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
                ['gq'] = telescope_actions.close, -- ruim para as buscas que precisarem de "gq"
                ['<c-u>'] = {'<c-u>', type = 'command'},
                ['<esc>'] = {'<esc>', type = 'command'},
            },
            n = {
                ['<NL>'] = telescope_actions.select_default + telescope_actions.center,
                ['gq'] = telescope_actions.close,
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
            luasnip.lsp_expand(args.body) -- For `luasnip` users.
            -- require('snippy').expand_snippet(args.body) -- For `snippy` users.
            -- vim.fn['UltiSnips#Anon'](args.body) -- For `ultisnips` users.
        end,
    },
    formatting = {
        expandable_indicator = true,
        fields = { 'abbr', 'kind', 'menu' },
        format = function(entry, vim_item)
            --- truncando itens muito grandes
            local ELLIPSIS_CHAR = '…'
            local MAX_LABEL_WIDTH = 20
            local MIN_LABEL_WIDTH = 20
            local label = vim_item.abbr
            local truncated_label = vim.fn.strcharpart(label, 0, MAX_LABEL_WIDTH)
            if truncated_label ~= label then
                vim_item.abbr = truncated_label .. ELLIPSIS_CHAR
            elseif string.len(label) < MIN_LABEL_WIDTH then
                local padding = string.rep(' ', MIN_LABEL_WIDTH - string.len(label))
                vim_item.abbr = label .. padding
            end
            -- Source
            vim_item.menu = ({
                buffer = "[BUFFER]",
                nvim_lsp = "[LSP]",
                luasnip = "[LUASNIP]",
                nvim_lua = "[LUA]",
                latex_symbols = "[LaTeX]",
                path = "[PATH]"
            })[entry.source.name]
            return vim_item
        end
    },
    experimental = {
        ghost_text = true,
    },
    completion = {
        completeopt = vim.o.completeopt,
        autocomplete = false,
    },
    sources = cmp.config.sources({
        { name = 'nvim_lsp' },
        {
            name = 'buffer',
            option = {
                get_bufnrs = function()
                    local buf = vim.api.nvim_get_current_buf() -- ganho de performace
                    local byte_size = vim.api.nvim_buf_get_offset(buf, vim.api.nvim_buf_line_count(buf))
                    if byte_size > 1024 * 1024 then -- 1 Megabyte max
                        return {}
                    end
                    local bufs = {} -- somente buffers visíveis
                    for _, win in ipairs(vim.api.nvim_list_wins()) do
                        bufs[vim.api.nvim_win_get_buf(win)] = true
                    end
                    return vim.tbl_keys(bufs)
                end
            }
        },
        { name = 'luasnip' }, -- For luasnip users.
        }, {
            { name = 'path' },
    })
})

-- Set up lspconfig.
local capabilities = require('cmp_nvim_lsp').default_capabilities(vim.lsp.protocol.make_client_capabilities())

-- LSP CONFIGURATION
local lsp = require('lspconfig')
local servers = {
    'emmet_ls', -- emmet LSP
    'pyright', -- python LSP
    'denols', -- javascript LSP
    'texlab', -- LaTeX LSP
    -- 'jdtls', -- java LSP
    'vimls', -- vim LSP
    'html', -- html LSP
    'jsonls', -- json LSP
    'cssls', -- css LSP
    {
        lsp = 'lua_ls',
        config = {
            settings = {
                Lua = {
                    runtime = {
                        version = 'LuaJIT',
                    },
                    diagnostics = {
                        globals = {
                            'vim',
                            'require',
                        }
                    },
                    workspace = {
                        library = vim.api.nvim_get_runtime_file("", true),
                    },
                },
            },
        },
    }, -- lua LSP
    'luau_lsp', -- luau LSP
    -- 'rust_analyzer', -- rust LSP
    -- { -- javascript LSP
    --     lsp = 'eslint',
    --     config = {
    --         on_attach = function(_, bufnr)
    --             vim.api.nvim_create_autocmd('BufWritePre', {
    --                 buffer = bufnr,
    --                 command = 'EslintFixAll',
    --             })
    --         end,
    --     }
    -- },
}
for _, server in ipairs(servers) do
---@diagnostic disable-next-line: undefined-field
    if server.config then
---@diagnostic disable-next-line: undefined-field
        lsp[server.lsp].setup({
            capabilities = capabilities,
---@diagnostic disable-next-line: undefined-field
            unpack(server.config)
        })
    else
        lsp[server].setup({
            capabilities = capabilities
        })
    end
end

-- vim.lsp.set_log_level("debug")
--
