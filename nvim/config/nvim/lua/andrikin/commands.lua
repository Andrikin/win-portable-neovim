-- CUSTOM COMMANDS

-- config: verificar a existência de TEXINPUTS antes de setá-lo
-- config: setar diretório onde se encontra as configurações latex TEXINPUTS
-- tratamento de erros

local Ouvidoria = require('andrikin.utils').Ouvidoria.new() -- executar bootstrap
local Diretorio = require('andrikin.utils').Diretorio

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
		local projetos = nil
		if vim.env.HOME:match('^.') == 'C' then
			projetos = Ouvidoria.ci.diretorios.projetos.diretorio
		else
			projetos = tostring(Diretorio.new(vim.fn.fnamemodify(vim.env.HOME, ':h')))
		end
		vim.cmd.Dirvish(
			vim.fs.find('projetos', {path = projetos, type = 'directory'})
		)
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

vim.api.nvim_create_user_command(
	'WhatsAppMensagem',
	function()
        local fim = vim.fn.getpos('$')[2]
        if fim < 1 then
            fim = 1
        end
        vim.cmd.normal({args = {'df:df:x'}, range = {1, fim}})
	end,
	{}
)

