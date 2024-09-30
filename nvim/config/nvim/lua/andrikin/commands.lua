-- CUSTOM COMMANDS

local Ouvidoria = require('andrikin.utils').Ouvidoria -- executar bootstrap

vim.api.nvim_create_user_command(
	'HexEditor',
	'%!xxd',
	{}
)

vim.api.nvim_create_user_command(
	'OuvidoriaCompilar',
    function()
        Ouvidoria.latex:compilar()
    end,
	{}
)

vim.api.nvim_create_user_command(
	'Ouvidoria',
    function(opts)
        Ouvidoria.ci:nova(opts)
    end,
	{
		nargs = "+",
		complete = function(arg, cmd, pos) return Ouvidoria.ci:tab(arg) end,
	}
)

vim.api.nvim_create_user_command(
	'Projetos',
	function()
		vim.cmd.Dirvish(Ouvidoria.ci.diretorios.projetos.diretorio)
	end,
	{}
)

vim.api.nvim_create_user_command(
	'SysinitEdit',
	function()
		vim.cmd.edit('$VIM/sysinit.vim')
	end,
	{}
)

