-- CUSTOM COMMANDS

local command = vim.api.nvim_create_user_command
local notify = require('andrikin.utils').notify or vim.notify
local Ouvidoria = require('andrikin.utils').Ouvidoria -- executar bootstrap
local Cygwin = require('andrikin.utils').Cygwin
local Diretorio = require('andrikin.utils').Diretorio
local Copyq = require('andrikin.utils').Copyq


command('Clipboard',
    function(opts)
        Copyq.clipboard(opts)
    end,
	{
        nargs = "?",
        complete = function(arg, _, _)
            return Copyq:tab_complete(arg)
        end,
    }
)

command('CompilarOuvidoria',
    function()
    ---@diagnostic disable-next-line: missing-parameter
        Ouvidoria.latex:compilar(nil, nil, true)
    end,
{})

command('CompilarLatex',
    function()
        ---@diagnostic disable-next-line: param-type-mismatch, undefined-field
        local destino = Diretorio.new(vim.uv.os_homedir()) / 'Downloads'
        ---@diagnostic disable-next-line: missing-parameter
        Ouvidoria.latex:compilar(destino, nil, false)
    end,
{})

command('Ouvidoria',
    function(opts)
        local ok, erro = pcall(function(o) Ouvidoria.ci:nova(o) end, opts)
        if not ok and (erro and erro:match('Keyboard interrupt')) then
            notify('Ouvidoria: Operação interrompida por Ctrl-C')
        elseif not ok then
            notify('Ouvidoria: ' .. erro)
        end
    end,
    {
        nargs = "+",
        complete = function(arg, _, _)
            return Ouvidoria.ci:tab(arg)
        end,
    }
)

command('Projetos',
    function()
        vim.cmd.Dirvish(Ouvidoria.ci.diretorios.projetos.diretorio)
    end,
{})

command('InicializacaoWindows',
    function()
        vim.cmd.Dirvish(vim.fs.joinpath(
            vim.env.APPDATA,
            '/Microsoft/Windows/Start Menu/Programs/Startup'
        ))
    end,
{})

command('Desktop',
    function()
        vim.cmd.Dirvish(vim.fs.joinpath(
            vim.env.HOMEDRIVE .. vim.env.HOMEPATH,
            'Desktop'
        ))
    end,
{})

command('Downloads',
    function()
        vim.cmd.Dirvish(vim.fs.joinpath(
            vim.env.HOMEDRIVE .. vim.env.HOMEPATH,
            'Downloads'
        ))
    end,
{})

command('Documents',
    function()
        vim.cmd.Dirvish(vim.fs.joinpath(
            vim.env.HOMEDRIVE .. vim.env.HOMEPATH,
            'Documents'
        ))
    end,
{})

command('RedeLocal',
    function()
        local andre = 'T:/16-Diretoria de Ouvidoria/Andre Aguiar'
        if vim.fn.isdirectory(andre) == 1 then
            vim.cmd.Dirvish(andre)
        end
    end,
{})

command('ComunicacaoInterna',
    function()
        local andre = 'T:/1-Comunicação Interna - C.I/' .. os.date('%Y')
        if vim.fn.isdirectory(andre) == 1 then
            vim.cmd.Dirvish(andre)
        end
    end,
{})

command('SysinitEdit',
    function()
        vim.cmd.edit('$VIM/sysinit.vim')
    end,
{})

-- https://help.libreoffice.org/latest/en-US/text/sbasic/python/python_locations.html?&DbPAR=BASIC&System=WIN
command('LibreOfficeScripts',
    function()
        vim.cmd.Dirvish('$APPDATA/LibreOffice/4/user/Scripts')
    end,
{})

command('Config',
    function()
        vim.cmd.edit('$XDG_CONFIG_HOME')
    end,
{})

command('Snippets',
    function()
        vim.cmd.edit(vim.fs.joinpath(
            ---@diagnostic disable-next-line: param-type-mismatch
            vim.fn.stdpath('config'),
            'snippets'
        ))
    end,
{})

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

command('Cygwin',
    function(opts) Cygwin:comando(opts) end,
    {nargs = '+', complete = Cygwin.complete}
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
    end,
{})
