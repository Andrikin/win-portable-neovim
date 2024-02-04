-- CUSTOM COMMANDS

-- config: verificar a existência de TEXINPUTS antes de setá-lo
-- config: setar diretório onde se encontra as configurações latex TEXINPUTS
-- tratamento de erros

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
Latex.not_tex_file = function()
    local extencao = vim.fn.expand('%'):match('%.([a-zA-Z0-9]*)$')
    return extencao and extencao ~= 'tex'
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
	if vim.fn.has('linux') == 1 then
		error('Sistema OS Linux!')
	end
	if Latex.not_tex_file() then
		vim.notify('Comando executável somente para arquivos .tex!')
		do return end
	end
	if vim.o.modified then -- salvar arquivo que está modificado.
		vim.cmd.write()
		vim.cmd.redraw({bang = true})
	end
	local arquivo = vim.fn.expand('%:t')
	if not vim.fn.expand('%'):match('C%.I%.') then
		local numero_ci = vim.fn.getline(vim.fn.search('^.Cabecalho')):match('{(%d+)}')
		if not numero_ci then
			numero_ci = 'NUMEROCI'
		end
		arquivo = string.format('C.I. N° %s.%s - ', numero_ci, os.date('%Y')) .. arquivo
		local antes = vim.fn.expand('%')
		local depois = vim.fn.expand('%:h') .. '/' .. arquivo
		local renomeado = vim.fn.rename(antes, depois)
		if renomeado == 0 then
			local alternativo = vim.fn.getreg('#')
			if alternativo == '' then
				alternativo = depois
			end
			vim.cmd.edit(depois) -- recarregar arquivo buffer
			vim.fn.setreg('#', alternativo)
			vim.cmd.bdelete(antes)
		else
			error('Não foi possível renomear o arquivo. Verifique e tente novamente.')
		end
	end
    arquivo = vim.fn.expand('%')
    local comando = { -- windows
        'tectonic.exe',
        '-X',
        'compile',
        '-o',
        Latex.OUTPUT_FOLDER,
        '-k',
        '-Z',
        'search-path=' .. vim.env.TEXINPUTS:match('^..(.+).$'),
        arquivo
    }
	notify('Compilando arquivo!')
	vim.print(vim.fn.system(comando))
    if vim.v.shell_error > 0 then
        notify('Erro encontrado ao compilar arquivo. Verifique com o comando "g<".')
        do return end
    end
	notify('Pdf compilado!')
    arquivo = vim.fn.fnamemodify(arquivo, ':t')
	arquivo =  arquivo:match('(.*)%..*$') or arquivo
    local pdf = vim.fs.find(arquivo .. '.pdf', {path = Latex.OUTPUT_FOLDER, type = 'file'})
    if vim.tbl_isempty(pdf) then
		notify('Latex: Não foi encontrado arquivo .pdf!')
    else
        pdf = pdf[1]
		notify(string.format('Abrindo arquivo %s', vim.fn.fnamemodify(pdf, ':t')))
		vim.fn.jobstart({
			Latex.PDF_READER,
			pdf
		})
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
	if tipo:match('sipe.lai') then
		arquivo = 'LAI-' .. arquivo
	elseif tipo:match('carga.gabinete') then
        arquivo = 'GAB-PREF-LAI-' .. arquivo
    else
		arquivo = 'OUV-' .. arquivo
	end
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

