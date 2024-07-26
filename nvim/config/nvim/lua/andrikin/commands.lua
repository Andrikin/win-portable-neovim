-- CUSTOM COMMANDS

-- config: verificar a existência de TEXINPUTS antes de setá-lo
-- config: setar diretório onde se encontra as configurações latex TEXINPUTS
-- tratamento de erros

local notify = require('andrikin.utils').notify
local Diretorio = require('andrikin.utils').Diretorio
local Opt = require('andrikin.utils').OPT

local Ouvidoria = {}

Ouvidoria.__index = Ouvidoria

Ouvidoria.tex = '.tex'

Ouvidoria.ci = {}

Ouvidoria.ci.diretorio = {-- diretório onde os modelos de comunicação interna estão (projeto git)
    modelos = Diretorio.new(vim.fn.fnamemodify(vim.env.HOME, ':h')) / 'projetos' / 'ouvidoria-latex-modelos',
    downloads = Diretorio.new(vim.loop.os_homedir()) / 'Downloads',
    projetos = Diretorio.new(vim.fn.fnamemodify(vim.env.HOME, ':h')) / 'projetos',
}

Ouvidoria.ci.modelos = function()
    return vim.fs.find(
        function(name, path)
            return name:match('.*%.tex$') and path:match('[/\\]ouvidoria.latex.modelos')
        end,
        {
            path = tostring(Ouvidoria.ci.diretorio.modelos),
            limit = math.huge,
            type = 'file'
        }
    )
end

Ouvidoria.ci.nova = function(opts)
	local tipo = opts.fargs[1] or 'modelo-basico'
	local titulo = opts.fargs[2] or 'ci-modelo'
    local modelo = vim.tbl_filter(
		function(ci)
			return ci:match(tipo:gsub('-', '.'))
		end,
        Ouvidoria.ci.modelos()
	)
	if tipo:match('sipe.lai') then
		titulo = 'LAI-' .. titulo .. Ouvidoria.tex
	elseif tipo:match('carga.gabinete') then
        titulo = 'GAB-PREF-LAI-' .. titulo .. Ouvidoria.tex
    else
		titulo = 'OUV-' .. titulo .. Ouvidoria.tex
	end
    if modelo[1] then
        modelo = modelo[1]
    else
        notify('Ouvidoria: Ci: não foi encontrado o arquivo modelo para criar nova comunicação.')
        do return end
    end
    local texto = vim.fn.readfile(modelo)
    local ci = (Ouvidoria.ci.diretorio.downloads / titulo).diretorio
    vim.fn.writefile(texto, ci) -- Sobreescreve arquivo, se existir
    vim.cmd.edit(ci)
end

Ouvidoria.ci.tab = function(args)-- tab completion
	return vim.tbl_filter(
		function(ci)
			return ci:match(args:gsub('-', '.'))
		end,
		vim.tbl_map(
			function(modelo)
				return vim.fn.fnamemodify(modelo, ':t'):match('(.*).tex$')
			end,
            Ouvidoria.ci.modelos()
		)
	)
end

-- Clonando projeto git "git@github.com:Andrikin/ouvidoria-latex-modelos"
Ouvidoria.ci.bootstrap = function(self)
    local has_diretorio_modelos = vim.fn.isdirectory(tostring(self.diretorio.modelos)) == 1
    if has_diretorio_modelos then
        notify('Ouvidoria: bootstrap: projeto com os modelos de LaTeX já está baixado!')
        do return end
    end
    local Ssh = require('andrikin.utils').Ssh.destino.diretorio
    local has_git = vim.fn.executable('git') == 1
    if not has_git then
        notify('Ouvidoria: bootstrap: não foi encontrado o comando git')
        do return end
    end
    local has_diretorio_projetos = vim.fn.isdirectory(self.diretorio.projetos.diretorio) == 1
    local has_diretorio_ssh = vim.fn.isdirectory(Ssh) == 1
    if has_diretorio_projetos and has_diretorio_ssh then
        vim.fn.system({
            "git",
            "clone",
            "git@github.com:Andrikin/ouvidoria-latex-modelos",
            tostring(self.diretorio.modelos),
        })
    else
        if not has_diretorio_ssh then
            notify("Git: não foi encontrado o diretório '.ssh'")
        end
        if not has_diretorio_projetos then
            notify("Git: não foi encontrado o diretório 'projetos'")
        end
    end
end

Ouvidoria.ci:bootstrap()

local Latex = {}

Latex.__index = Latex

Latex.diretorio = {
    opt = Opt,
    downloads = Diretorio.new(vim.loop.os_homedir()) / 'Downloads',
    auxiliar = Diretorio.new(vim.env.TEMP),
}

Latex.arquivo_tex = function()
    local extencao = vim.fn.expand('%'):match('%.([a-zA-Z0-9]*)$')
    return extencao and extencao == 'tex'
end

Latex.bootstrap = function()
	vim.env.TEXINPUTS = '.;' .. Ouvidoria.ci.diretorio.modelos.diretorio .. ';'
    if vim.fn.executable('tectonic') == 0 then
        notify('Latex: bootstrap: não foi encontrado executável "tectonic"')
    end
end

Latex.pdf = {
    executavel = vim.fn.fnamemodify(vim.fn.glob(tostring(Latex.diretorio.opt / 'sumatra' / 'sumatra*.exe')), ':t')
}

Latex.pdf.abrir = function(arquivo)
    arquivo = arquivo:gsub('tex$', 'pdf')
    notify(string.format('Abrindo arquivo %s', vim.fn.fnamemodify(arquivo, ':t')))
    vim.fn.jobstart({
        Latex.pdf.executavel,
        arquivo
    })
end

Latex.compilar = function(self)
	if vim.fn.has('linux') == 1 then
		error('Sistema OS Linux!')
	end
	if not self.arquivo_tex() then
		notify('Comando executável somente para arquivos .tex!')
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
            notify('Latex: compilar: não foi encontrado número da C.I.')
            do return end
		end
		arquivo = string.format('C.I. N° %s.%s - ', numero_ci, os.date('%Y')) .. arquivo
		local antes = vim.fn.expand('%')
		local depois = vim.fn.expand('%:h') .. '/' .. arquivo
		local renomeado = vim.fn.rename(antes, depois) == 0
		if renomeado then
			local alternativo = vim.fn.getreg('#')
			if alternativo == '' then
				alternativo = depois
			end
			vim.cmd.edit(depois) -- recarregar arquivo buffer
			vim.fn.setreg('#', alternativo)
			vim.cmd.bdelete(antes)
		else
			error('Latex: compilar: não foi possível renomear o arquivo.')
		end
	end
    arquivo = vim.fn.expand('%')
    if not arquivo:match(self.diretorio.downloads.diretorio) then
        notify('Latex: compilar: arquivo "tex" não está na pasta $HOMEPATH/Downloads')
        do return end
    end
    local comando = { -- windows
        'tectonic.exe',
        '-X',
        'compile',
        '-o',
        self.diretorio.downloads.diretorio,
        '-k',
        '-Z',
        'search-path=' .. Ouvidoria.ci.diretorio.modelos.diretorio,
        arquivo
    }
	notify('Compilando arquivo!')
    local resultado = vim.fn.system(comando)
    if vim.v.shell_error > 0 then
        notify(resultado)
        do return end
    end
	notify('Pdf compilado!')
    self.pdf.abrir(arquivo)
end

Latex:bootstrap()

vim.api.nvim_create_user_command(
	'HexEditor',
	'%!xxd',
	{}
)

vim.api.nvim_create_user_command(
	'Pdflatex',
    -- Latex.compile,
    function()
        Latex:compilar()
    end,
	{}
)

vim.api.nvim_create_user_command(
	'Ouvidoria',
	-- Ouvidoria.nova_comunicacao,
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
			projetos = Ouvidoria.ci.diretorio.projetos.diretorio
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

