-- Configuração de LSP servers

local cmp = require('cmp')
cmp.setup({
	snippet = {
		-- REQUIRED - you must specify a snippet engine
		expand = function(args)
			-- vim.fn["vsnip#anonymous"](args.body) -- For `vsnip` users.
			require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
			-- require('snippy').expand_snippet(args.body) -- For `snippy` users.
			-- vim.fn["UltiSnips#Anon"](args.body) -- For `ultisnips` users.
		end,
	},
	window = {
		-- completion = cmp.config.window.bordered(),
		-- documentation = cmp.config.window.bordered(),
	},
	mapping = cmp.mapping.preset.insert({
		['<C-b>'] = cmp.mapping.scroll_docs(-4),
		['<C-f>'] = cmp.mapping.scroll_docs(4),
		['<C-Space>'] = cmp.mapping.complete(),
		['<C-e>'] = cmp.mapping.abort(),
		['<CR>'] = cmp.mapping.confirm({ select = false }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
		['<C-n>'] = cmp.mapping.select_next_item(),
		['<C-p>'] = cmp.mapping.select_prev_item(),
	}),
	sources = cmp.config.sources({
		{ name = 'nvim_lsp' },
		-- { name = 'vsnip' }, -- For vsnip users.
		{ name = 'luasnip' }, -- For luasnip users.
		-- { name = 'ultisnips' }, -- For ultisnips users.
		-- { name = 'snippy' }, -- For snippy users.
		}, {
			{ name = 'buffer' },
	})
})
-- Set configuration for specific filetype.
cmp.setup.filetype('gitcommit', {
	sources = cmp.config.sources({
		{ name = 'cmp_git' }, -- You can specify the `cmp_git` source if you were installed it.
		}, {
			{ name = 'buffer' },
	})
})
-- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline({ '/', '?' }, {
	mapping = cmp.mapping.preset.cmdline(),
	sources = {
		{ name = 'buffer' }
	}
})
-- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline(':', {
	mapping = cmp.mapping.preset.cmdline(),
	sources = cmp.config.sources({
		{ name = 'path' }
		}, {
			{ name = 'cmdline' }
	})
})
-- Mensagem de erro mais curta
vim.diagnostic.config(
	{
		virtual_text = {
			format = function(diagnostic)
				if diagnostic.severity == vim.diagnostic.severity.ERROR then
					return 'Erro!'
				end
				return diagnostic.message
			end
		}
	}
)
-- Set up lspconfig.
-- Replace <YOUR_LSP_SERVER> with each lsp server you've enabled.
local cmp_capabilities = require('cmp_nvim_lsp').default_capabilities()

-- LSP SERVERS 
-- TODO: Sempre instalar os arquivos binários dos executáveis
local lsp = require('lspconfig')

-- Emmet LSP
lsp.emmet_ls.setup({}) -- npm install -g emmet-ls

-- HTML LSP
lsp.html.setup({}) -- npm i -g vscode-langservers-extracted

-- Python LSP
lsp.pyright.setup({
	capabilities = cmp_capabilities
}) -- pip install pyright | npm -g install pyright

-- Javascript LSP
lsp.denols.setup({
	capabilities = cmp_capabilities
})

-- Lua LSP
lsp.lua_ls.setup {
	capabilities = cmp_capabilities,
	on_init = function(client)
		local path = client.workspace_folders[1].name
		if not vim.loop.fs_stat(path..'/.luarc.json') and not vim.loop.fs_stat(path..'/.luarc.jsonc') then
			client.config.settings = vim.tbl_deep_extend('force', client.config.settings, {
				Lua = {
					runtime = {
						-- Tell the language server which version of Lua you're using
						-- (most likely LuaJIT in the case of Neovim)
						version = 'LuaJIT'
					},
					-- Make the server aware of Neovim runtime files
					workspace = {
						checkThirdParty = false,
						library = {
							vim.env.VIMRUNTIME
							-- "${3rd}/luv/library"
							-- "${3rd}/busted/library",
						}
						-- or pull in all of 'runtimepath'. NOTE: this is a lot slower
						-- library = vim.api.nvim_get_runtime_file("", true)
					}
				}
			})

			client.notify("workspace/didChangeConfiguration", { settings = client.config.settings })
		end
		return true
	end
}

-- Java LSP
lsp.jdtls.setup({
	capabilities = cmp_capabilities
})

-- Vim LSP
lsp.vimls.setup({
	capabilities = cmp_capabilities
})

-- Rust LSP
-- lsp.rust_analyzer.setup({})

require('colorizer').setup(nil, { css = true })

-- require('nvim-treesitter.install').compilers = {'clang', 'gcc'}
require('nvim-treesitter.configs').setup({
	highlight = {
		enable = true,
		additional_vim_regex_highlighting = true,
	},
	indent = {
		enable = true
	},
	ensure_installed = { -- linguagens para web development
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
	},
	context_commentstring = {
		enable = true,
	},
})

local telescope_tema = 'dropdown'
local telescope_actions = require('telescope.actions')
require('telescope').setup{
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
					["dd"] = telescope_actions.delete_buffer,
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
				["<NL>"] = telescope_actions.select_default + telescope_actions.center,
				-- ["<esc>"] = telescope_actions.close,
				["<c-u>"] = {"<c-u>", type = "command"},
			},
			n = {
				["<NL>"] = telescope_actions.select_default + telescope_actions.center,
			},
		},
	}
}

