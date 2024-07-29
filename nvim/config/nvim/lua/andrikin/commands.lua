-- CUSTOM COMMANDS

local Ouvidoria = require('andrikin.utils').Ouvidoria.new() -- executar bootstrap

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
	Ouvidoria.ci.nova,
	{
		nargs = "+",
		complete = Ouvidoria.ci.tab,
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

