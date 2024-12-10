if not vim.b.did_mail then
    local opts = { silent = true, buffer = vim.api.nvim_get_current_buf() }
    local open = vim.ui.open or function(arquivo)
        -- If {cmd} is a String it runs in the 'shell'
        vim.fn.jobstart(vim.fn.shellescape(arquivo), {detach = true})
    end
    vim.keymap.set('n', 'go', function()
        local linha = vim.fn.getline('.')
        if not linha:match('^<#part') then
            print('Não foi possível obter arquivo de diretório para abrir o arquivo')
            do return end
        end
        local arquivo = linha:match('filename="(.*)"'):match('C:.*'):gsub('\\', '/')
        if arquivo then
            print(('Abrindo arquivo: %s'):format(arquivo))
            open(arquivo)
        end
    end, opts)
    vim.keymap.set('n', 'gm', function()
        local conta = vim.fn['himalaya#domain#account#current']()
        if conta == '' then
            conta = 'ouvidoria'
        end
        local template = vim.g.himalaya_pandoc_template_email .. '/' .. conta .. '.html'
        if vim.fn.filereadable(template) == 0 then
            print('Pandoc: Arquivo template para e-mails não configurado!')
            do return end
        end
        vim.cmd['!']({
            'pandoc --template ' .. template .. ' -t html',
            range = {5, vim.fn.line('$')},
        })
    end, opts)
    vim.bo.textwidth = 80
    vim.b.did_mail = true
end

