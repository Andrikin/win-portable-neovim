local autocmd = vim.api.nvim_create_autocmd
local Andrikin = vim.api.nvim_create_augroup('Andrikin', { clear = true })

-- Highlight linha quando entrar em INSERT MODE
autocmd('InsertEnter', {
    group = Andrikin,
    pattern = '*',
    callback = function()
        local dirvish = vim.bo.ft == 'dirvish' -- não desativar quando for Dirvish
        if dirvish then
            return
        end
        vim.wo.cursorline = true
    end,
})
autocmd('InsertLeave', {
    group = Andrikin,
    pattern = '*',
    callback = function()
        local dirvish = vim.bo.ft == 'dirvish' -- não desativar quando for Dirvish
        if dirvish then
            return
        end
        vim.wo.cursorline = false
    end,
})
autocmd('WinEnter', {
    group = Andrikin,
    pattern = '*',
    callback = function()
        vim.wo.cursorline = false
    end,
})

-- Resize windows automatically
-- Tim Pope goodness
autocmd('VimResized', {
    group = Andrikin,
    pattern = '*',
    callback = function()
        vim.cmd.wincmd('=')
    end,
})

-- Highlight configuração
autocmd('TextYankPost', {
    group = Andrikin,
    pattern = '*',
    callback = function()
        vim.hl.hl_op({
            higroup = 'IncSearch',
            timeout = 300,
        })
    end,
})

-- Remover fonte do regedit (Windows)
autocmd('VimLeave', {
    group = Andrikin,
    callback = function()
        local flashdrive = vim.env.HOME:sub(1, 1):lower() ~= 'c'
        local remover = false
        if flashdrive then
            remover = vim.fn.confirm(
                'Remover fonte do regedit?',
                '&Sim\n&Não',
                2
            ) == 1
        else
            return
        end
        if remover then
            vim.cmd.FonteRemover()
        end
    end,
})

-- --- Builtin LSP commands ---
-- Only available in git projects (git init)
autocmd('LspAttach', {
    group = Andrikin,
    callback = function(ev)
        local client = vim.lsp.get_client_by_id(ev.data.client_id)
        if client and client:supports_method('textDocument/completion') then
            vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = false })
        end
    end
})

-- WIP: ao selecionar a entrada para edição no editor externo, mudar o foco do
-- programa faz com que a janela do copyq feche, executando o restante da macro
-- - copiar conteúdo do arquivo para entrada e deletar arquivo, antes mesmo de
-- completar a edição no editor externo.
-- https://copyq.readthedocs.io/en/latest/faq.html#why-does-my-external-editor-fail-to-edit-items
--
-- ideia: copiar todo texto quando sair do buffer, criando nova entrada no
-- copyq: tab -> clipboard
autocmd('BufWrite', {
    group = Andrikin,
    pattern = 'Copyq*.txt',
    callback = function()
        vim.bo.fixendofline = false
        vim.bo.endofline = false
        vim.bo.fileformat = 'dos'
        vim.cmd.yank({reg = '+', range = {1, vim.fn.line('$')}})
    end
})

autocmd('UIEnter', {
    group = Andrikin,
    -- experimental: ui2
    callback = require('vim._core.ui2').enable
})

