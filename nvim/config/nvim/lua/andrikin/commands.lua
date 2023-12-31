-- CUSTOM COMMANDS
-- TODO: Criar plugin; criar método para configuração
-- config: setar arquivos auxiliares para pasta temp, conforme sistema
-- config: setar diretório onde se encontra as configurações latex
-- config: setar qual programa irá abrir o pdf (chrome como padrão?)
-- config: verificar a existência de TEXINPUTS antes de setá-lo
-- plugin: unificar objeto Latex com Ouvidoria
-- plugin: identificar em qual sistema o nvim está executando!!!
-- config: vim.loop.os_uname para obter informação do sistema
-- TODO: Utilizar objeto Diretorio, para gerenciamento de path's

local Path = vim.F.npcall(require, 'plenary.path')
if not Path then
	error('Não foi encontrado plugin Plenary. Verificar instalação do plugin')
end

local notify = function(msg)
	vim.notify(msg)
	vim.cmd.redraw({bang = true})
end

local Latex = {}
Latex.OUTPUT_FOLDER = vim.fs.find('Downloads', {path = vim.loop.os_homedir(), type = 'directory'})[1] -- windows 
Latex.AUX_FOLDER = vim.env.TEMP -- windows
Latex.PDF_READER = vim.fn.fnamemodify(vim.fn.glob(vim.env.HOME .. '/nvim/opt/sumatra/sumatra*exe'), ':t')
Latex.ft = function()
	return vim.o.ft ~= 'tex'
end
Latex.clear = function(arquivo)
	-- deletar arquivos auxiliares da compilação, no linux
	if not vim.fn.has('linux') then
		vim.notify('Caso esteja no sistema Windows, verifique a disponibilidade da opção de comando "-aux-directory"')
		do return end
	end
	local auxiliares = vim.tbl_filter(
		function(auxiliar)
			return auxiliar:match('aux$') or auxiliar:match('out$') or auxiliar:match('log$')
		end,
		vim.fn.glob(Latex.OUTPUT_FOLDER .. '/' .. arquivo .. '.*', false, true)
	)
	if #auxiliares == 0 then
		do return end
	end
	for _, auxiliar in ipairs(auxiliares) do
		vim.fn.delete(auxiliar)
	end
end
Latex.init = function() -- setando diretoria de modelos latex
	vim.env.TEXINPUTS = '.;' .. vim.fs.find(
		'ouvidoria-latex-modelos',
		{
			path = vim.fn.fnamemodify(vim.env.HOME, ':h'),
			type = 'directory',
		}
	)[1] .. ';'
end
Latex.compile = function()
	if Latex.ft() then
		vim.notify('Comando executável somente para arquivos .tex!')
		do return end
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
	notify('1º compilação!')
	vim.fn.system(comando)
	notify('2º compilação!')
	vim.fn.system(comando)
	notify('Pdf compilado!')
	arquivo =  arquivo:match('(.*)%..*$') or arquivo
	local pdf = Latex.OUTPUT_FOLDER .. '/' .. arquivo .. '.pdf'
	if vim.loop.fs_stat(pdf) then
		notify(string.format('Abrindo arquivo %s', vim.fn.fnamemodify(pdf, ':t')))
		vim.fn.jobstart({
			Latex.PDF_READER,
			pdf
		})
	else
		notify('Latex: Não foi encontrado arquivo .pdf!')
	end
	Latex.clear(arquivo)
end
Latex.init()

local Ouvidoria = {}
Ouvidoria.TEX = '.tex'
Ouvidoria.CI_FOLDER = vim.env.TEXINPUTS:match('..(.*).')
Ouvidoria.OUTPUT_FOLDER = Latex.OUTPUT_FOLDER
Ouvidoria.listagem = function()
	return vim.tbl_map(
		function(diretorio)
			return diretorio:match("[a-zA-Z-]*.tex$")
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
	local NONAME = vim.api.nvim_buf_get_name(vim.fn.bufnr('%')) == ''
	vim.cmd.edit(Ouvidoria.CI_FOLDER .. '/' .. tipo .. Ouvidoria.TEX)
	local ok, retorno = pcall(
		vim.cmd.saveas,
		Ouvidoria.OUTPUT_FOLDER .. '/' .. arquivo .. Ouvidoria.TEX
	)
	while not ok do
		if retorno:match('E13:') then
			arquivo = vim.fn.input(
				'Arquivo com este nome já existe. Digite outro nome para arquivo: '
			)
			ok, retorno = pcall(
				vim.cmd.saveas,
				Ouvidoria.OUTPUT_FOLDER .. '/' .. arquivo .. Ouvidoria.TEX
			)
		else
			vim.notify('Erro encontrado! Abortando comando Pdflatex.')
			do return end
		end
	end
	if NONAME then
		alternativo = Ouvidoria.OUTPUT_FOLDER .. '/' .. arquivo .. Ouvidoria.TEX
	end
	vim.fn.setreg('#', alternativo) -- setando arquivo alternativo
	vim.cmd.bdelete(tipo .. Ouvidoria.TEX)
end
Ouvidoria.complete = function(args)
	return vim.tbl_filter(
		function(comunicacao)
			return comunicacao:match(args:gsub('-', '.'))
		end,
		vim.tbl_map(
			function(modelo)
				return modelo:match('(.*).tex$')
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

vim.api.nvim_create_user_command(
	'Projetos',
	function()
		local projetos = nil
		if vim.env.HOME:match('^.') == 'C' then
			projetos = Path:new({
				vim.loop.os_homedir(),
				'Documents'
			})
		else
			projetos = Path:new({
				vim.fn.fnamemodify(vim.env.HOME, ':h'),
			})
		end
		print(projetos)
		vim.cmd.Dirvish(
			vim.fs.find('projetos', {path = projetos.filename, type = 'directory'})
		)
	end,
	{}
)

