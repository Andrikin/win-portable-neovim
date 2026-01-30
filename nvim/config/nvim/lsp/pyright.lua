-- Verificar fix de bug: https://github.com/neovim/neovim/issues/34731
local function set_python_path(path)
    local clients = vim.lsp.get_clients {
        bufnr = vim.api.nvim_get_current_buf(),
        name = 'pyright',
    }
    for _, client in ipairs(clients) do
        if client.settings then
            client.settings.python = vim.tbl_deep_extend('force', client.settings.python, { pythonPath = path })
        else
            client.config.settings = vim.tbl_deep_extend('force', client.config.settings, { python = { pythonPath = path } })
        end
        client.notify('workspace/didChangeConfiguration', { settings = nil })
    end
end

return {
    cmd = { 'pyright-langserver', '--stdio' },
    filetypes = { 'python' },
    root_markers = {
        'pyproject.toml',
        'setup.py',
        'setup.cfg',
        'requirements.txt',
        'Pipfile',
        'pyrightconfig.json',
        '.git',
    },
    settings = {
        python = {
            analysis = {
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
                diagnosticMode = 'openFilesOnly',
            },
        },
    },
    on_attach = function(client, bufnr)
        vim.api.nvim_buf_create_user_command(bufnr, 'LspPyrightOrganizeImports', function()
            client:exec_cmd({
                command = 'pyright.organizeimports',
                arguments = { vim.uri_from_bufnr(bufnr) },
            })
        end, {
        desc = 'Organize Imports',
        })
        vim.api.nvim_buf_create_user_command(bufnr, 'LspPyrightSetPythonPath', set_python_path, {
            desc = 'Reconfigure pyright with the provided python path',
            nargs = 1,
            complete = 'file',
        })
    end,
    handlers = {
        -- Override the default rename handler to remove the `annotationId` from edits.
        --
        -- Pyright is being non-compliant here by returning `annotationId` in the edits, but not
        -- populating the `changeAnnotations` field in the `WorkspaceEdit`. This causes Neovim to
        -- throw an error when applying the workspace edit.
        --
        -- See:
        -- - https://github.com/neovim/neovim/issues/34731
        -- - https://github.com/microsoft/pyright/issues/10671
        [vim.lsp.protocol.Methods.textDocument_rename] = function(err, result, ctx)
            if err then
                vim.notify('Pyright rename failed: ' .. err.message, vim.log.levels.ERROR)
                return
            end

            ---@cast result lsp.WorkspaceEdit
            for _, change in ipairs(result.documentChanges or {}) do
                for _, edit in ipairs(change.edits or {}) do
                    if edit.annotationId then
                        edit.annotationId = nil
                    end
                end
            end

            local client = assert(vim.lsp.get_client_by_id(ctx.client_id))
            vim.lsp.util.apply_workspace_edit(result, client.offset_encoding)
        end,
    },
}
