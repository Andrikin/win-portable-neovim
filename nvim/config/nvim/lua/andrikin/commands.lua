-- CUSTOM COMMANDS

local command = vim.api.nvim_create_user_command
local Ouvidoria = require('andrikin.utils').Ouvidoria -- executar bootstrap
local Cygwin = require('andrikin.utils').Cygwin
local Diretorio = require('andrikin.utils').Diretorio

command(
	'HexEditor',
	'%!xxd',
	{}
)

command(
	'CompilarOuvidoria',
    function()
        Ouvidoria.latex:compilar()
    end,
	{}
)

command(
	'CompilarLatex',
    function()
        local destino = Diretorio.new(vim.loop.os_homedir()) / 'Downloads'
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
	'SysinitEdit',
	function()
		vim.cmd.edit('$VIM/sysinit.vim')
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

