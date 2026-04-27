local root1 = {
  '.emmyrc.json',
  '.luarc.json',
  '.luarc.jsonc',
}
local root2 = {
  '.luacheckrc',
  '.stylua.toml',
  'stylua.toml',
  'selene.toml',
  'selene.yml',
}
return {
    -- cmd = {'lua-language-server', '--force-accept-workspace'},
    cmd = {'lua-language-server'},
    filetypes = { 'lua' },
    root_markers = vim.fn.has('nvim-0.11.3') == 1 and { root1, root2, { '.git' } }
        or vim.list_extend(vim.list_extend(root1, root2), { '.git' }),
    single_file_support = true,
    log_level = vim.lsp.protocol.MessageType.Warning,
    settings = {
        Lua = {
            format = {
                enable = true,
                defaultConfig = {
                    indent_style = 'space',
                    indent_size = '4',
                    continuation_indent = '4',
                }
            },
            codeLens = { enable = true },
            hint = { enable = true, semicolon = 'Disable' },
            runtime = { version = 'LuaJIT' },
            diagnostics = {
                globals = {
                    'vim',
                    'require',
                }
            },
            workspace = { library = vim.api.nvim_get_runtime_file("", true) },
        },
    },
}
