-- Configuração de LSP servers

-- lsp.diagnostic: Mensagem de erro mais curta
vim.diagnostic.config({
    underline = true,
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
