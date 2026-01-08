-- CUSTOM COMMANDS

local command = vim.api.nvim_create_user_command
local Ouvidoria = require('andrikin.utils').Ouvidoria -- executar bootstrap
local Cygwin = require('andrikin.utils').Cygwin
local Diretorio = require('andrikin.utils').Diretorio
local Copyq = require('andrikin.utils').Copyq


command(
	'Clipboard',
    function(opts)
        Copyq.clipboard(opts)
    end,
	{
		nargs = "?",
		complete = function(arg, _, _) return Copyq:tab_complete(arg) end,
	}
)

command(
    'CompilarOuvidoria',
    function()
    ---@diagnostic disable-next-line: missing-parameter
        Ouvidoria.latex:compilar()
    end,
    {}
)

command(
    'CompilarLatex',
    function()
        ---@diagnostic disable-next-line: param-type-mismatch, undefined-field
        local destino = Diretorio.new(vim.uv.os_homedir()) / 'Downloads'
        ---@diagnostic disable-next-line: missing-parameter
        Ouvidoria.latex:compilar(destino)
    end,
    {}
)

command(
    'Ouvidoria',
    function(opts)
        Ouvidoria.ci:nova(opts)
    end,
    {
        nargs = "+",
        complete = function(arg, _, _) return Ouvidoria.ci:tab(arg) end,
    }
)

command(
    'Projetos',
    function()
        vim.cmd.Dirvish(Ouvidoria.ci.diretorios.projetos.diretorio)
    end,
    {}
)

command(
    'Desktop',
    function()
        vim.cmd.Dirvish(vim.fs.joinpath(
            vim.env.HOMEPATH,
            'Desktop'
        ))
    end,
    {}
)

command(
    'Downloads',
    function()
        vim.cmd.Dirvish(vim.fs.joinpath(
            vim.env.HOMEPATH,
            'Downloads'
        ))
    end,
    {}
)

command(
    'Documents',
    function()
        vim.cmd.Dirvish(vim.fs.joinpath(
            vim.env.HOMEPATH,
            'Documents'
        ))
    end,
    {}
)

command(
    'RedeLocal',
    function()
        local andre = 'T:/16-Diretoria de Ouvidoria/Andre Aguiar'
        if vim.fn.isdirectory(andre) == 1 then
            vim.cmd.Dirvish(andre)
        end
    end,
    {}
)

command(
    'ComunicacaoInterna',
    function()
        local andre = 'T:/1-Comunicação Interna - C.I'
        if vim.fn.isdirectory(andre) == 1 then
            vim.cmd.Dirvish(andre)
        end
    end,
    {}
)

command(
    'SysinitEdit',
    function()
        vim.cmd.edit('$VIM/sysinit.vim')
    end,
    {}
)

-- https://help.libreoffice.org/latest/en-US/text/sbasic/python/python_locations.html?&DbPAR=BASIC&System=WIN
command(
    'LibreOfficeScripts',
    function()
        vim.cmd.Dirvish('$APPDATA/LibreOffice/4/user/Scripts')
    end,
    {}
)

command(
    'Config',
    function()
        vim.cmd.edit('$XDG_CONFIG_HOME')
    end,
    {}
)

command(
    'Snippets',
    function()
        vim.cmd.edit(vim.fs.joinpath(
            ---@diagnostic disable-next-line: param-type-mismatch
            vim.fn.stdpath('config'),
            'snippets'
        ))
    end,
    {}
)

-- imprimir arquivos na impressora padrão
command(
    'Imprimir',
    function(opts)
        local arquivo = opts.fargs[1]
        local printer = opts.fargs[2]
        if not arquivo then
            print('Não foi informado arquivo para impressão. Abortando')
            do return end
        end
        if not printer then
            -- printer = vim.fn.system({'wmic', 'printer', 'get', 'name,default'})
            printer = '\\\\printserver\\CI-OUVIDORIA'
        end
        vim.fn.jobstart(
            ('print %s /D:%s'):format(vim.fn.shellescape(arquivo), printer),
        {detach = true})
    end,
    { nargs = "+", complete = 'file' }
)

command(
    'Reload',
    require('andrikin.utils').reload,
    {}
)

command(
    'Cygwin',
    function(opts) Cygwin:comando(opts) end,
    {nargs = '+', complete = Cygwin.complete}
)

