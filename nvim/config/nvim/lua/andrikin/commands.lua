-- CUSTOM COMMANDS

local command = vim.api.nvim_create_user_command

command('Projetos',
    function()
        vim.cmd.Dirvish(vim.fs.joinpath(
            vim.fs.dirname(vim.env.HOME),
            'projetos'
        ))
    end, {}
)

command('InicializacaoWindows',
    function()
        vim.cmd.Dirvish(vim.fs.joinpath(
            vim.env.APPDATA,
            '/Microsoft/Windows/Start Menu/Programs/Startup'
        ))
    end, {}
)

command('Desktop',
    function()
        vim.cmd.Dirvish(vim.fs.joinpath(
            vim.env.HOMEDRIVE .. vim.env.HOMEPATH,
            'Desktop'
        ))
    end, {}
)

command('Downloads',
    function()
        vim.cmd.Dirvish(vim.fs.joinpath(
            vim.env.HOMEDRIVE .. vim.env.HOMEPATH,
            'Downloads'
        ))
    end, {}
)

command('Documents',
    function()
        vim.cmd.Dirvish(vim.fs.joinpath(
            vim.env.HOMEDRIVE .. vim.env.HOMEPATH,
            'Documents'
        ))
    end, {}
)

command('RedeLocal',
    function()
        local andre = 'T:/12-Diretoria de Auditoria/Servidor - André Aguiar'
        if vim.fn.isdirectory(andre) == 1 then
            vim.cmd.Dirvish(andre)
        else
            vim.print('Dirvish: diretório não existe!')
        end
    end, {}
)

command('AuditoriaDiretorio',
    function()
        local auditoria = 'T:/12-Diretoria de Auditoria'
        if vim.fn.isdirectory(auditoria) == 1 then
            vim.cmd.Dirvish(auditoria)
        else
            vim.print('Dirvish: diretório não existe!')
        end
    end, {}
)

command('ComunicacaoInterna',
    function()
        local andre = 'T:/1-Comunicação Interna - C.I/' .. os.date('%Y')
        if vim.fn.isdirectory(andre) == 1 then
            vim.cmd.Dirvish(andre)
        else
            vim.print('Dirvish: diretório não existe!')
        end
    end, {}
)

command('SysinitEdit',
    function()
        vim.cmd.edit('$VIM/sysinit.vim')
    end, {}
)

-- https://help.libreoffice.org/latest/en-US/text/sbasic/python/python_locations.html?&DbPAR=BASIC&System=WIN
command('LibreOfficeScripts',
    function()
        vim.cmd.Dirvish('$APPDATA/LibreOffice/4/user/Scripts')
    end, {}
)

command('Config',
    function()
        vim.cmd.edit('$XDG_CONFIG_HOME')
    end, {}
)

command('Snippets',
    function()
        vim.cmd.edit(vim.fs.joinpath(
            ---@diagnostic disable-next-line: param-type-mismatch
            vim.fn.stdpath('config'),
            'snippets'
        ))
    end, {}
)

-- imprimir arquivos na impressora padrão
command('Imprimir',
    function(opts)
        local arquivo = opts.fargs[1]
        local printer = opts.fargs[2] or '\\\\printserver\\CI-OUVIDORIA'
        if not arquivo then
            print('Não foi informado arquivo para impressão. Abortando')
            return
        end
        vim.fn.jobstart(
            ('print %s /D:%s'):format(vim.fn.shellescape(arquivo), printer),
        {detach = true})
    end,
    { nargs = "+", complete = 'file' }
)

-- Sort paths in dirvish buffer, from newest to oldest
command('SortingDirvish',
    function()
        local buf = vim.api.nvim_get_current_buf()
        local plist = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        if #plist == 1 and plist[1] == '' then
            return
        end
		-- diretórios; .diretórios
		vim.cmd('silent sort :/$:')
        -- somente diretórios
        vim.cmd('silent g/[^/]$/d')
        local dlist = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
		if #dlist == 1 and dlist[1] == '' then
			dlist = {}
		end
        local fpaths = {}
        for _, p in ipairs(plist) do
            local m = vim.uv.fs_stat(p)
            local path = {
                path = p,
                mtime = m.mtime.sec or m.mtime,
            }
			if m.type ~= 'directory' then
				table.insert(fpaths, path)
			end
        end
		-- ordernar arquivos
        table.sort(fpaths, function (a, b)
            return a.mtime > b.mtime
        end)
		-- adicionar arquivos aos diretórios
        for _, path in ipairs(fpaths) do
			table.insert(dlist, path.path)
        end
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, dlist)
    end, {}
)

-- WARNING: utilizar definindo diretórios com '""'
command('Shortcut',
    function(opts)
        local args = vim.npcall(function()
            return vim.iter(opts.args:gmatch('".-"')):totable()
        end)
        if not args then
            vim.print('Shortcut: não foi possível interpretar os argumentos do comando.')
            return
        end
        if #args > 2 then
            vim.print('Shortcut: número de argumentos excedido. Abortando.')
            return
        end
        local executavel = args[1]
        local destino = args[2]
        local shortcut = {'Shortcut.exe', '/F:' .. destino, '/T:' .. executavel}
        vim.system(shortcut, {detach = true})
    end, {}
)

-- WIP!
command('Pandoc',
    function(opts)
        if not vim.env.PANDOC_DATA_DIRS then
            vim.print('Pandoc: variável $PANDOC_DATA_DIRS não está configurada!')
            return
        end
        opts.args = opts.args and vim.trim(opts.args)
        local md = ''
        local doc = ''
        if opts.args == '' then
            md = vim.fn.expand('%')
            doc = md:gsub('%.md$', '.docx')
        else
            md = opts.args:match('^["](.-%.md)[" ]+')
            doc = opts.args:match('%.md["%s]+(.-%.docx)$')
        end
        if not md or not doc then
            vim.print('pandoc: não foram encontrados parâmetros. Abortando.')
            return
        end
        if not md:match('%.md$') then
            vim.print('Pandoc: não é um arquivo "md" válido para converção!')
            return
        end
        local cmd = {
            'pandoc',
            '-f',
            'markdown',
            '-t',
            'docx',
            '--resource-path=' .. vim.env.PANDOC_DATA_DIRS,
            '--reference-doc=carta.docx',
            '--template=modelo.openxml',
            '-o',
            doc,
            md,
        }
        vim.system(cmd, { detach = true }, function (out)
            if out.code > 0 then
                vim.print('pandoc: erro encontrado.')
                vim.print('pandoc_error: '.. out.stderr)
                return
            end
            if vim.uv.fs_stat(doc) then
                vim.print('pandoc: conversão concluída!')
                vim.open(doc)
            end
        end)
    end, { nargs = "+", complete = 'file' }
)

