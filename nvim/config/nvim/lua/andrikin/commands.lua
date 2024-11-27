-- CUSTOM COMMANDS

local command = require('andrikin.utils').command
local Ouvidoria = require('andrikin.utils').Ouvidoria -- executar bootstrap

command(
	'HexEditor',
	'%!xxd',
	{}
)

command(
	'OuvidoriaCompilar',
    function()
        Ouvidoria.latex:compilar()
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
		complete = function(arg, cmd, pos) return Ouvidoria.ci:tab(arg) end,
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
	'SysinitEdit',
	function()
		vim.cmd.edit('$VIM/sysinit.vim')
	end,
	{}
)

-- imprimir arquivos na impressora padrão
command(
    'Imprimir',
    function(arquivo, printer)
        if not arquivo then
            print('Não foi informado arquivo para impressão. Abortando')
            do return end
        end
        if not printer then
            -- printer = vim.fn.system({'wmic', 'printer', 'get', 'name,default'})
            printer = '\\\\printserver\\CI-OUVIDORIA'
        end
        vim.fn.jobstart({
            ('print %s /D:%s'):format(vim.fn.shellescape(arquivo), printer)
        },{detach = true})
    end,
    { nargs = "+", complete = 'file' }
)

command(
	'Reload',
    require('andrikin.utils').reload,
	{}
)

