-- CUSTOM COMMANDS
local fn = vim.fn
local api = vim.api
local env = vim.env
local cmd = vim.cmd

-- TODO: Criar plugin; criar método para configuração
-- config: setar arquivos auxiliares para pasta temp, conforme sistema
-- config: setar diretório onde se encontra as configurações latex
-- config: setar qual programa irá abrir o pdf (chrome como padrão?)
-- config: verificar a existência de TEXINPUTS antes de setá-lo
-- plugin: unificar objeto Latex com Ouvidoria
-- plugin: identificar em qual sistema o nvim está executando
local Latex = {}
Latex.OUTPUT_FOLDER = 'C:\\Users\\' .. env.USERNAME .. '\\Downloads'
Latex.AUX_FOLDER = Latex.OUTPUT_FOLDER
-- WIP: Como verificar em qual sistema o nvim está executando
Latex.PDF_READER = 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe' -- windows 10
Latex.ft = function()
	return vim.o.ft ~= 'tex'
end
Latex.clear = function(arquivo)
	-- deletar arquivos auxiliares da compilação, no linux
	if not fn.has('linux') then
		vim.notify('Caso esteja no sistema Windows, verifique a disponibilidade da opção de comando "-aux-directory"')
		return
	end
	local auxiliares = vim.tbl_filter(
		function(auxiliar)
			return string.match(auxiliar, 'aux$') or string.match(auxiliar, 'out$') or string.match(auxiliar, 'log$')
		end,
		fn.glob(Latex.OUTPUT_FOLDER .. '/' .. arquivo .. '.*', false, true)
	)
	if #auxiliares == 0 then
		return
	end
	for _, auxiliar in ipairs(auxiliares) do
		fn.delete(auxiliar)
	end
end
Latex.init = function() -- setando diretoria de modelos latex
	env.TEXINPUTS = fn.glob(fn.fnamemodify(env.HOME, ':h') .. '**\\ouvidoria-latex-modelos\\prefeitura')
end
Latex.compile = function(opts)
	if Latex.ft() then
		vim.notify('Comando executável somente para arquivos .tex!')
		return
	end
	if vim.o.modified then -- salvar arquivo que está modificado.
		cmd.write()
	end
	local arquivo = fn.expand('%:t')
	local cmd = {}
	if fn.has('linux') then
		cmd = {
			'pdflatex',
			'-file-line-error',
			'-interaction=nonstopmode',
			'-output-directory=' .. Latex.OUTPUT_FOLDER,
			arquivo
		}
	else -- para sistemas que não são linux, verificar a opção '-aux-directory'
		cmd = {
			'pdflatex',
			'-file-line-error',
			'-interaction=nonstopmode',
			'-aux-directory=' .. Latex.AUX_FOLDER,
			'-output-directory=' .. Latex.OUTPUT_FOLDER,
			arquivo
		}
	end
	vim.notify('1º compilação!')
	fn.system(cmd)
	vim.notify('2º compilação!')
	fn.system(cmd)
	vim.notify('Pdf compilado!')
	arquivo = string.match(arquivo, '(.*)%..*$') -- remover extenção do arquivo
	fn.jobstart(
		{
			Latex.PDF_READER,
			Latex.OUTPUT_FOLDER .. '/' .. arquivo .. '.pdf'
		}
	)
	Latex.clear(arquivo)
end
Latex.init()

local Ouvidoria = {}
Ouvidoria.TEX = '.tex'
Ouvidoria.CI_FOLDER = fn.fnamemodify(env.TEXINPUTS, ':h')
Ouvidoria.OUTPUT_FOLDER = Latex.OUTPUT_FOLDER
Ouvidoria.listagem = function()
	return vim.tbl_map(
		function(diretorio)
			return string.match(diretorio, "[a-zA-Z-]*.tex$")
		end,
		fn.glob(Ouvidoria.CI_FOLDER .. '/*.tex', false, true)
	)
end
Ouvidoria.nova_comunicacao = function(opts)
	local tipo = opts.fargs[1] or 'modelo-basico'
	local arquivo = opts.fargs[2] or 'ci-modelo'
	local alternativo = fn.expand('%')
	cmd.edit(Ouvidoria.CI_FOLDER .. '/' .. tipo .. Ouvidoria.TEX)
	local ok, retorno = pcall(
		cmd.saveas,
		Ouvidoria.OUTPUT_FOLDER .. '/' .. arquivo .. Ouvidoria.TEX
	)
	while not ok do
		if string.match(retorno, 'E13:') then
			arquivo = fn.input(
				'Arquivo com este nome já existe. Digite outro nome para arquivo: '
			)
			ok, retorno = pcall(
				cmd.saveas,
				Ouvidoria.OUTPUT_FOLDER .. '/' .. arquivo .. Ouvidoria.TEX
			)
		else
			vim.notify('Erro encontrado! Abortando comando.')
			return
		end
	end
	fn.setreg('#', alternativo) -- setando arquivo alternativo
	cmd.bdelete(tipo)
end
Ouvidoria.complete = function(args, command, position)
	return vim.tbl_filter(
		function(ci)
			return string.match(ci, args)
		end,
		vim.tbl_map(
			function(ci)
				return string.match(ci, '(.*).tex$')
			end,
			Ouvidoria.listagem()
		)
	)
end

api.nvim_create_user_command(
	'HexEditor',
	'%!xxd',
	{}
)

api.nvim_create_user_command(
	'Pdflatex',
	Latex.compile,
	{}
)

api.nvim_create_user_command(
	'Ouvidoria',
	Ouvidoria.nova_comunicacao,
	{
		nargs = "+",
		complete = Ouvidoria.complete,
	}
)

