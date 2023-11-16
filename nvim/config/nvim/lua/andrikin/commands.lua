-- CUSTOM COMMANDS
-- TODO: Criar plugin; criar método para configuração
-- config: setar arquivos auxiliares para pasta temp, conforme sistema
-- config: setar diretório onde se encontra as configurações latex
-- config: setar qual programa irá abrir o pdf (chrome como padrão?)
-- config: verificar a existência de TEXINPUTS antes de setá-lo
-- plugin: unificar objeto Latex com Ouvidoria
-- plugin: identificar em qual sistema o nvim está executando!!!
-- config: vim.loop.os_uname para obter informação do sistema
local Latex = {}
Latex.OUTPUT_FOLDER = vim.loop.os_homedir() .. '\\Downloads' -- windows
Latex.AUX_FOLDER = vim.env.TEMP -- windows
-- WIP: Como verificar em qual sistema o nvim está executando
Latex.PDF_READER = 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe' -- windows 10
Latex.ft = function()
	return vim.o.ft ~= 'tex'
end
Latex.clear = function(arquivo)
	-- deletar arquivos auxiliares da compilação, no linux
	if not vim.fn.has('linux') then
		vim.notify('Caso esteja no sistema Windows, verifique a disponibilidade da opção de comando "-aux-directory"')
		return
	end
	local auxiliares = vim.tbl_filter(
		function(auxiliar)
			return string.match(auxiliar, 'aux$') or string.match(auxiliar, 'out$') or string.match(auxiliar, 'log$')
		end,
		vim.fn.glob(Latex.OUTPUT_FOLDER .. '/' .. arquivo .. '.*', false, true)
	)
	if #auxiliares == 0 then
		return
	end
	for _, auxiliar in ipairs(auxiliares) do
		vim.fn.delete(auxiliar)
	end
end
Latex.init = function() -- setando diretoria de modelos latex
	vim.env.TEXINPUTS = vim.fs.find(
		'ouvidoria-latex-modelos',
		{
			path = vim.fn.fnamemodify(vim.env.HOME, ':h'),
			type = 'directory',
		}
	)[1]
end
Latex.compile = function(opts)
	if Latex.ft() then
		vim.notify('Comando executável somente para arquivos .tex!')
		return
	end
	if vim.o.modified then -- salvar arquivo que está modificado.
		vim.cmd.write()
		vim.cmd.redraw({bang = true})
	end
	local arquivo = vim.fn.expand('%:t')
	local comando = {}
	if vim.fn.has('linux') then
		comando = {
			'pdflatex',
			'-file-line-error',
			'-interaction=nonstopmode',
			'-output-directory=' .. Latex.OUTPUT_FOLDER,
			arquivo
		}
	else -- para sistemas que não são linux, verificar a opção '-aux-directory'
		comando = {
			'pdflatex',
			'-file-line-error',
			'-interaction=nonstopmode',
			'-aux-directory=' .. Latex.AUX_FOLDER,
			'-output-directory=' .. Latex.OUTPUT_FOLDER,
			arquivo
		}
	end
	vim.notify('1º compilação!')
	vim.fn.system(comando)
	vim.notify('2º compilação!')
	vim.fn.system(comando)
	vim.notify('Pdf compilado!')
	arquivo = string.match(arquivo, '(.*)%..*$') -- remover extenção do arquivo
	vim.fn.jobstart(
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
Ouvidoria.CI_FOLDER = vim.env.TEXINPUTS
Ouvidoria.OUTPUT_FOLDER = Latex.OUTPUT_FOLDER
Ouvidoria.listagem = function()
	return vim.tbl_map(
		function(diretorio)
			return string.match(diretorio, "[a-zA-Z-]*.tex$")
		end,
		vim.fs.find(
			function(name, path)
				return name:match('.*%.tex$') and path:match('[/\\]ouvidoria.latex.modelos')
			end,
			{
				path = vim.fn.fnamemodify(vim.env.HOME, ':h') .. '/projetos',
				limit = math.huge,
				type = 'file'
			}
		)
	)
end
Ouvidoria.nova_comunicacao = function(opts)
	local tipo = opts.fargs[1] or 'modelo-basico'
	local arquivo = opts.fargs[2] or 'ci-modelo'
	local alternativo = vim.fn.expand('%')
	vim.cmd.edit(Ouvidoria.CI_FOLDER .. '/' .. tipo .. Ouvidoria.TEX)
	local ok, retorno = pcall(
		vim.cmd.saveas,
		Ouvidoria.OUTPUT_FOLDER .. '/' .. arquivo .. Ouvidoria.TEX
	)
	while not ok do
		if string.match(retorno, 'E13:') then
			arquivo = vim.fn.input(
				'Arquivo com este nome já existe. Digite outro nome para arquivo: '
			)
			ok, retorno = pcall(
				vim.cmd.saveas,
				Ouvidoria.OUTPUT_FOLDER .. '/' .. arquivo .. Ouvidoria.TEX
			)
		else
			vim.notify('Erro encontrado! Abortando comando.')
			return
		end
	end
	vim.fn.setreg('#', alternativo) -- setando arquivo alternativo
	vim.cmd.bdelete(tipo)
end
Ouvidoria.complete = function(args, cmd, pos)
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

vim.api.nvim_create_user_command(
	'HexEditor',
	'%!xxd',
	{}
)

vim.api.nvim_create_user_command(
	'Pdflatex',
	Latex.compile,
	{}
)

vim.api.nvim_create_user_command(
	'Ouvidoria',
	Ouvidoria.nova_comunicacao,
	{
		nargs = "+",
		complete = Ouvidoria.complete,
	}
)

