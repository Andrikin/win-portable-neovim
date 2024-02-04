-- INFO: Lista de links para download das dependências:
-- curl: https://curl.se/windows/latest.cgi?p=win64-mingw.zip
-- unzip: http://linorg.usp.br/CTAN/systems/win32/w32tex/unzip.exe
-- w64devkit-compiler: https://github.com/skeeto/w64devkit/releases/download/v1.21.0/w64devkit-1.21.0.zip
-- git: https://github.com/git-for-windows/git/releases/download/v2.43.0.windows.1/Git-2.43.0-64-bit.tar.bz2 -- Full Version
-- git: https://github.com/git-for-windows/git/releases/download/v2.43.0.windows.1/MinGit-2.43.0-64-bit.zip -- Minimal Version
-- fd: https://github.com/sharkdp/fd/releases/download/v8.7.1/fd-v8.7.1-x86_64-pc-windows-gnu.zip
-- ripgrep: https://github.com/BurntSushi/ripgrep/releases/download/14.0.3/ripgrep-14.0.3-i686-pc-windows-msvc.zip
-- sumatra: https://www.sumatrapdfreader.org/dl/rel/3.5.2/SumatraPDF-3.5.2-64.zip
-- node: https://nodejs.org/dist/v20.10.0/node-v20.10.0-win-x64.zip
-- HOW PORTABLE PYTHON: https://chrisapproved.com/blog/portable-python-for-windows.html
-- python 3.8.9 (Windows 7): https://www.python.org/ftp/python/3.8.9/python-3.8.9-embed-amd64.zip
-- python 3.12.1: https://www.python.org/ftp/python/3.12.1/python-3.12.1-embed-amd64.zip
-- pip installer: https://bootstrap.pypa.io/get-pip.py
-- TinyTex: https://github.com/rstudio/tinytex-releases/releases/download/v2023.12/TinyTeX-1-v2023.12.zip
-- TinyTex: https://yihui.org/tinytex/
-- Tectonic: https://github.com/tectonic-typesetting/tectonic/releases/download/tectonic%400.14.1/tectonic-0.14.1-x86_64-pc-windows-msvc.zip
-- Java: https://download.oracle.com/java/21/latest/jdk-21_windows-x64_bin.zip -- oracle
-- Java: https://download.java.net/java/GA/jdk21.0.1/415e3f918a1f4062a0074a2794853d0d/12/GPL/openjdk-21.0.1_windows-x64_bin.zip -- openjdk
-- Jdtls: https://www.eclipse.org/downloads/download.php?file=/jdtls/snapshots/jdt-language-server-latest.tar.gz
-- Maven: https://dlcdn.apache.org/maven/maven-3/3.9.6/binaries/apache-maven-3.9.6-bin.zip
-- rust: TODO

-- LSPs:
-- javascript: (deno 1.27.0 Windows 7) https://github.com/denoland/deno/releases/download/v1.27.0/deno-x86_64-pc-windows-msvc.zip
-- lua: https://github.com/LuaLS/lua-language-server/releases/download/3.7.3/lua-language-server-3.7.3-win32-x64.zip
-- emmet: npm install -g emmet-ls
-- python: pip install pyright | npm -g install pyright
-- rust: TODO

-- WIP: Utilizar multithreads para realizar os downloads
-- TODO: Refatorar código?

-- IMPORTANT(Windows 10+): Desabilitar python.exe e python3.exe em "Gerenciar aliases de execução de aplicativo".
-- Windows executa este alias antes de executar python declarado em PATH.
-- ALTERNATIVE FIX: Remover WindowsApps do PATH
if vim.env.PATH:match('WindowsApps') or vim.env.PATH:match('Oracle') then
	local PATH = ''
	for path in vim.env.PATH:gmatch('([^;]+)') do
		if not path:match('WindowsApps') and not path:match('Oracle') then
			PATH = PATH ..  ';' .. path
		end
	end
	PATH = PATH:match('^.(.*)$')
	vim.env.PATH = PATH
end

local npcall = require('andrikin.utils').npcall
local notify = require('andrikin.utils').notify
local Diretorio = require('andrikin.utils').Diretorio
---@type Diretorio
local NVIM_OPT = Diretorio:new(vim.env.NVIM_OPT)

local win7 = string.match(vim.loop.os_uname()['version'], 'Windows 7')

---@class Curl
---@field UNZIP string Url para download de unzip.exe
local Curl = {}

Curl.__index = Curl

Curl.UNZIP = 'http://linorg.usp.br/CTAN/systems/win32/w32tex/unzip.exe'

-- FATO: Windows 10 build 17063 or later is bundled with tar.exe which is capable of working with ZIP files 
---@private
Curl.bootstrap = function()
	-- Realizar o download da ferramenta unzip
	if win7 and vim.fn.executable('tar') == 0 then
		notify('Curl: bootstrap: Sistema não possui tar.exe! Realizar a instalação do programa.')
		do return end
	end
	if vim.fn.executable('unzip') == 1 then
		notify('Curl: bootstrap: Sistema já possui Unzip.')
		do return end
	end
	Curl.download(Curl.UNZIP, NVIM_OPT.nome)
	local unzip = vim.fs.find('unzip.exe', {path = NVIM_OPT.nome, type = 'file'})[1]
	if unzip == '' then
		error('Curl: bootstrap: Não foi possível encontrar o executável unzip.exe.')
	end
end

---@private
Curl.instalado = function()
	return vim.fn.executable('curl') == 1
end

---@param link string
---@param diretorio string
Curl.download = function(link, diretorio)
	vim.validate({
		link = {link, 'string'},
		diretorio = {diretorio, 'string'}
	})
	if link == '' or diretorio == '' then
		error('Curl: download: Variável nula')
	end
	local arquivo = vim.fn.fnamemodify(link, ':t')
	diretorio = (Diretorio:new(diretorio) / arquivo).nome
	vim.fn.system({
		'curl',
		'--fail',
		'--location',
		'--silent',
		'--output',
		diretorio,
		link
	})
	if vim.v.shell_error == 0 then
		notify(string.format('Curl: download: Arquivo %s baixado!', arquivo))
	else
		notify(string.format('Curl: download: Não foi possível realizar o download do arquivo %s!', arquivo))
	end
end

---@param arquivo string
---@param diretorio string
Curl.extrair = function(arquivo, diretorio)
	vim.validate({
		arquivo = {arquivo, 'string'},
		diretorio = {diretorio, 'string'}
	})
	if arquivo == '' or diretorio == '' then
		error('Curl: extrair: Variárvel nula.')
	end
	local extencao = arquivo:match('%.(tar)%.[a-z.]*$') or arquivo:match('%.([a-z]*)$')
	if extencao == 'zip' then
		vim.fn.system({
			'unzip',
			arquivo,
			'-d',
			diretorio
		})
	elseif extencao == 'tar' then
		vim.fn.system({
			'tar',
			'-xf',
			arquivo,
			'-C',
			diretorio
		})
	end
	local nome = arquivo:match('[/\\]([^/\\]+)$') or arquivo
	if vim.v.shell_error == 0 then
		notify(string.format('Curl: extrair: Arquivo %s extraído com sucesso!', nome))
	else
		notify(string.format('Curl: extrair: Erro encontrado! Não foi possível extrair o diretorio_arquivo %s', nome))
	end
end

if not Curl.instalado() then
	error('Curl: instalado: Não foi encontrado curl no sistema. Verificar e realizar a instalação do curl neste computador!\nLink para download: https://curl.se/windows/latest.cgi?p=win64-mingw.zip')
else
	Curl.bootstrap()
end

-- Instalação da fonte SauceCodePro no computador
---@class Fonte
---@field DIRETORIO Diretorio Onde a fonte será instalada
---@field LINK string Url para download da fonte
---@field ARQUIVO string Nome do arquivo
---@field REGISTRO string Caminho aonde será instalado a fonte no regedit do sistema
---@field FONTES table Lista de fontes encontradas no sistema
local SauceCodePro = {}

SauceCodePro.__index = SauceCodePro

---@type Diretorio
SauceCodePro.DIRETORIO = NVIM_OPT / 'fonte'

SauceCodePro.LINK = 'https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/SourceCodePro.zip'

SauceCodePro.ARQUIVO = SauceCodePro.DIRETORIO .. vim.fn.fnamemodify(SauceCodePro.LINK, ':t')

SauceCodePro.REGISTRO = 'HKCU\\Software\\Microsoft\\Windows NT\\CurrentVersion\\Fonts'

SauceCodePro.FONTES = vim.fn.glob(SauceCodePro.DIRETORIO .. 'SauceCodePro*.ttf', false, true)

SauceCodePro.bootstrap = function()
	if vim.fn.isdirectory(SauceCodePro.DIRETORIO.nome) == 0 then
		vim.fn.mkdir(SauceCodePro.DIRETORIO.nome, 'p', 0700)
	end
	vim.api.nvim_create_user_command(
		'FonteRemover',
		SauceCodePro.remover_regedit,
		{}
	)
end

SauceCodePro.setup = function()
	SauceCodePro.bootstrap()
	if not SauceCodePro.instalada() then
        if Curl.instalado() then
            SauceCodePro.instalar()
        else
            notify('Não foi possível instalar a fonte SauceCodePro neste computador. Instale curl para continuar.')
        end
    else
		notify('Fonte SauceCodePro já instalada.')
	end
end

---@return boolean
SauceCodePro.fonte_extraida = function()
	return #(vim.fn.glob(SauceCodePro.DIRETORIO .. 'SauceCodePro*.ttf', false, true)) > 0
end

SauceCodePro.download = function()
	if vim.fn.isdirectory(tostring(SauceCodePro.DIRETORIO)) == 0 then
		vim.fn.mkdir(tostring(SauceCodePro.DIRETORIO), 'p', 0700)
	end
	-- Realizar download da fonte
	Curl.download(SauceCodePro.LINK, SauceCodePro.DIRETORIO.nome)
	if not SauceCodePro.baixada() then
		error('Fonte: download: Não foi possível realizar o download do arquivo da fonte.')
	end
	notify('Arquivo fonte .zip baixado!')
end

---Decompressar arquivo zip
SauceCodePro.extrair = function()
	if not SauceCodePro.baixada() then
		error('Fonte: extrair: Arquivo .zip não encontrado! Realizar o download do arquivo de fonte para continuar a intalação.')
	end
	Curl.extrair(SauceCodePro.ARQUIVO, SauceCodePro.DIRETORIO.nome)
	if SauceCodePro.fonte_extraida() then
		notify('Arquivo fonte SauceCodePro.zip extraído!')
		SauceCodePro.FONTES = vim.fn.glob(SauceCodePro.DIRETORIO .. 'SauceCodePro*.ttf', false, true)
        -- remover arquivo .zip
        vim.fn.delete(SauceCodePro.ARQUIVO)
	else
		error('Fonte: extrair: Não foi possível extrair os arquivo de fonte.')
	end
end

---Verificando se a fonte está intalada no computador
---@return boolean
SauceCodePro.instalada = function()
	local lista = vim.tbl_filter(
		function(elemento)
			return elemento:match('SauceCodePro')
		end,
		vim.fn.systemlist({
			'reg',
			'query',
			SauceCodePro.REGISTRO,
			'/s'
	}))
	return #lista > 0
end

---Registra as fontes no regedit do sistema Windows.
SauceCodePro.regedit = function()
	for _, fonte in ipairs(SauceCodePro.FONTES) do
		local arquivo = vim.fn.fnamemodify(fonte, ':t')
		local diretorio = SauceCodePro.DIRETORIO .. arquivo
		vim.fn.system({
			'reg',
			'add',
			SauceCodePro.REGISTRO,
			'/v',
			arquivo:match('(.*)%..*$'), -- nome de registro da fonte
			'/t',
			'REG_SZ',
			'/d',
			diretorio,
			'/f'
		})
	end
end

---@return boolean
SauceCodePro.baixada = function()
    return vim.fn.getftype(SauceCodePro.ARQUIVO) ~= ''
end

---Desinstala a fonte do regedit do sistema Windows.
SauceCodePro.remover_regedit = function()
	for _, fonte in ipairs(SauceCodePro.FONTES) do
		local nome = vim.fn.fnamemodify(fonte, ':t')
		nome = nome:match('(.*)%..*$')
		if nome then
			vim.fn.system({
				'reg',
				'delete',
				SauceCodePro.REGISTRO,
				'/v',
				nome,
				'/f'
			})
		end
	end
end

---Instalar a Fonte no sistema Windows.
SauceCodePro.instalar = function()
	if not SauceCodePro.fonte_extraida() then
        if not SauceCodePro.baixada() then
            SauceCodePro.download()
        end
		SauceCodePro.extrair()
	end
	if not SauceCodePro.instalada() then
		SauceCodePro.regedit()
		if SauceCodePro.instalada() then
			notify('Fonte instalada com sucesso. Reinicie o nvim para carregar a fonte.')
			vim.cmd.quit({bang = true})
		else
			notify('Erro encontrado. Verificar se é possível executar comandos no regedit.')
		end
	else
		notify('Fonte SauceCodePro já instalada no sistema!')
	end
end

---@class Opt
---@field DIRETORIO Diretorio Onde as dependências ficaram instaladas
local Opt = {}

Opt.__index = Opt

---@type Diretorio
Opt.DIRETORIO = NVIM_OPT

Opt.bootstrap = function()
	-- Criar diretório, setar configurações, etc
	if vim.fn.isdirectory(tostring(Opt.DIRETORIO)) == 0 then
		vim.fn.mkdir(tostring(Opt.DIRETORIO), 'p', 0700)
	end
	if not vim.env.PATH:match(tostring(Opt.DIRETORIO):gsub('[\\/-]', '.')) then
		vim.env.PATH = vim.env.PATH .. ';' .. tostring(Opt.DIRETORIO)
	end
end

---@param cfg table
Opt.config = function(cfg)
	Opt.DEPENDENCIAS = cfg
end

---@param programa table
---@return boolean
---Verifica se o programa já está no PATH
Opt.registrar = function(programa)
	local diretorio = Opt.DIRETORIO .. programa.nome
	local registrado = vim.env.PATH:match(diretorio:gsub('[\\-]', '.'))
	if registrado then
		notify(string.format('Opt: registrar_path: Programa %s já registrado no sistema!', programa.nome))
		return true
	end
	local limite = vim.tbl_islist(programa.cmd) and #programa.cmd or 1
	local executaveis = vim.fs.find(programa.cmd, {path = diretorio, type = 'file', limit = limite})
    local sem_executavel = vim.tbl_isempty(executaveis)
	if not registrado and sem_executavel then
		notify(string.format('Opt: registrar_path: Baixar programa %s e registrar no sistema.', programa.nome))
		return false
	end
	-- simplesmente adicionar ao PATH
	for _, exe in ipairs(executaveis) do
		vim.env.PATH = vim.env.PATH .. ';' .. vim.fn.fnamemodify(exe, ':h')
	end
	registrado = vim.env.PATH:match(diretorio:gsub('[\\-]', '.'))
	if registrado then
		notify(string.format('Opt: registrar_path: Programa %s registrado no PATH do sistema.', programa.nome))
		if programa.config then -- caso tenha configuração, executá-la
			notify(string.format('Opt: registrar_path: Configurando programa %s.', programa.nome))
			programa.config()
		end
	end
	return true
end

Opt.init = function()
	for _, programa in ipairs(Opt.DEPENDENCIAS) do
		local arquivo = vim.fn.fnamemodify(programa.link, ':t')
		local diretorio = Opt.DIRETORIO .. programa.nome
		local registrado = Opt.registrar(programa)
		if not registrado then
			local baixado = vim.fn.getftype(Opt.DIRETORIO .. arquivo) ~= ''
			local extraido = #vim.fn.glob((Diretorio:new(diretorio) / '*').nome, false, true) ~= 0
			if not baixado then
				Curl.download(programa.link, Opt.DIRETORIO.nome)
                baixado = true
			else
				notify(string.format('Opt: init: Arquivo %s já existe.', arquivo))
			end
			if not extraido and baixado then
				-- criar diretório para extrair arquivo
				if vim.fn.isdirectory(diretorio) == 0 then
					vim.fn.mkdir(diretorio, 'p', 0700)
				end
				Curl.extrair(Opt.DIRETORIO .. arquivo, diretorio)
			else
				notify(string.format('Opt: init: Arquivo %s já extraído.', arquivo))
			end
			Opt.registrar(programa)
			-- Remover arquivo baixado (não é mais necessário) 
			if baixado then
				vim.fn.delete(Opt.DIRETORIO .. arquivo)
			end
		end
	end
end

---@param cfg table
Opt.setup = function(cfg)
	Opt.config(cfg)
	Opt.init()
end

local PROGRAMAS = {
	{
		nome = 'w64devkit',
		link = 'https://github.com/skeeto/w64devkit/releases/download/v1.21.0/w64devkit-1.21.0.zip',
		cmd = 'gcc.exe'
	},{
		nome = 'git',
		link = 'https://github.com/git-for-windows/git/releases/download/v2.43.0.windows.1/MinGit-2.43.0-64-bit.zip',
		cmd = 'git.exe'
	},{
		nome = 'fd',
		link = 'https://github.com/sharkdp/fd/releases/download/v8.7.1/fd-v8.7.1-x86_64-pc-windows-gnu.zip',
		cmd = 'fd.exe'
	},{
		nome = 'ripgrep',
		link = 'https://github.com/BurntSushi/ripgrep/releases/download/14.0.3/ripgrep-14.0.3-i686-pc-windows-msvc.zip',
		cmd = 'rg.exe'
	},{
		nome = 'sumatra',
		link = 'https://www.sumatrapdfreader.org/dl/rel/3.5.2/SumatraPDF-3.5.2-64.zip',
		cmd = 'sumatra.exe',
		config = function()
			local diretorio = NVIM_OPT / 'sumatra'
			local executavel = vim.fn.glob((diretorio / 'sumatra*.exe').nome)
			if executavel ~= '' then
				if vim.fn.fnamemodify(executavel, ':t') == 'sumatra.exe' then
					notify('Arquivo Sumatra já renomeado.')
					do return end
				end
                notify('Renomeando executável Sumatra.')
				vim.fn.system({
					'mv',
					executavel,
					diretorio .. 'sumatra.exe'
				})
			else
				notify('Não foi encontrado executável Sumatra.')
			end
		end
	},{
		nome = 'node',
		link = 'https://nodejs.org/dist/v20.10.0/node-v20.10.0-win-x64.zip',
		cmd = 'node.exe',
		config = function()
			local installed = function(pacote) -- checar se diretório existe
				return not vim.tbl_isempty(vim.fs.find(pacote, {path = (NVIM_OPT / 'node').nome, type = 'directory'}))
			end
			-- configurações extras
			if win7 and vim.env.NODE_SKIP_PLATFORM_CHECK ~= 1 then
				vim.env.NODE_SKIP_PLATFORM_CHECK = 1
			end
			if vim.fn.executable('npm') == 1 then
				local plugins = {
					'neovim',
					'emmet-ls',
					'vim-language-server',
					'vscode-langservers-extracted',
				}
				for _, plugin in ipairs(plugins) do
					if not installed(plugin) then
                        notify(string.format('Instalando pacote node: %s', plugin))
						vim.fn.system({
							'npm',
							'install',
							'-g',
							plugin
						})
                    else
                        notify(string.format('Pacote node já instalado %s', plugin))
					end
				end
			end
		end
	},{
		nome = 'python',
		link = 'https://www.python.org/ftp/python/3.8.9/python-3.8.9-embed-amd64.zip',
		cmd = {'python.exe', 'pip.exe'},
		config = function()
			-- INFO: Na primeira instalação, baixar get-pip.py e modificar o arquivo python38._pth
			-- descomentando a linha 4
			local get_pip = {}
			get_pip.link =  'https://bootstrap.pypa.io/get-pip.py'
			get_pip.nome = vim.fn.fnamemodify(get_pip.link, ':t')
			get_pip.diretorio = (NVIM_OPT / 'python').nome
			get_pip.instalado = function(self)
				local pip = vim.fs.find('pip.exe', {path = tostring(self.diretorio), type = 'file'})[1]
				if not pip then
					return nil
				end
				return npcall(
					vim.fn.fnamemodify,
					pip,
					':h'
				)
			end
			get_pip.instalar = function(self)
				if vim.fn.executable('sed') == 1 then
					if vim.fn.executable('pip.exe') == 0 then
						vim.fn.system({
							'sed',
							'-i',
							'$s/^#\\(.*\\)$/\\1/',
							self.diretorio .. 'python38._pth' -- versão 3.8.9
						})
					end
				else
					notify('"sed" não encontrado nas dependências. Abortando configuração de python.')
					do return end
				end
				-- download get-pip.py
				if not vim.fs.find(self.nome, {path = tostring(self.diretorio), type = 'file'})[1] then
					Curl.download(self.link, self.diretorio)
				end
				-- executar get-pip.py
				if vim.fn.executable('pip.exe') == 0 then
					notify(string.format('Executando "%s".', self.nome))
					vim.fn.system({
						'python.exe',
						self.diretorio .. self.nome
					})
				else
					notify('Instalação de "pip.exe" encontrou um erro.')
					do return end
				end
			end
			if not get_pip:instalado() then
				get_pip:instalar()
				-- instalar lsp
				local pip = vim.fn.fnamemodify(vim.fs.find('pip.exe', {path = tostring(get_pip.diretorio), type = 'file'})[1], ':h')
				if pip then
					vim.env.PATH = vim.env.PATH .. ';' .. pip
				else
					notify('Erro ao registrar "pip.exe" na variável de ambiente PATH.')
					do return end
				end
			end
			if vim.fn.executable('pip.exe') == 1 then
				local instalar = function(pacote)
					local instalado = vim.fs.find(pacote, {path = tostring(get_pip.diretorio), type = 'directory'})[1]
					if not instalado then
						notify(string.format('Instalando pacote python %s.', pacote))
						vim.fn.system({
							'pip.exe',
							'install',
							pacote
						})
					else
						notify(string.format('Pacote python %s já instalado.', pacote))
					end
				end
				instalar('pyright')
				instalar('pynvim')
				instalar('greenlet')
			else
				notify('"pip.exe" não encontrado. Falha na instalação.')
				do return end
			end
			vim.g.python3_host_prog = vim.fs.find('python.exe', {path = tostring(get_pip.diretorio), type = 'file'})[1]
			if not vim.g.python3_host_prog or vim.g.python3_host_prog == '' then
				notify('Variável python3_host_prog não configurado.')
			end
		end
	},{
		nome = 'tectonic',
		link = 'https://github.com/tectonic-typesetting/tectonic/releases/download/tectonic%400.14.1/tectonic-0.14.1-x86_64-pc-windows-msvc.zip',
		cmd = 'tectonic.exe',
	},{
		nome = 'texlab-latex-lsp',
		link = 'https://github.com/latex-lsp/texlab/releases/download/v5.12.1/texlab-x86_64-windows.zip',
		cmd = 'texlab.exe'
	},{
		nome = 'deno-javascript-lsp',
		link = 'https://github.com/denoland/deno/releases/download/v1.27.0/deno-x86_64-pc-windows-msvc.zip',
		cmd = 'deno.exe'
	},{
		nome = 'lua-lsp',
		link = 'https://github.com/LuaLS/lua-language-server/releases/download/3.7.3/lua-language-server-3.7.3-win32-x64.zip',
		cmd = 'lua-language-server.exe'
	},{
		nome = 'java',
		link = 'https://download.java.net/java/GA/jdk21.0.1/415e3f918a1f4062a0074a2794853d0d/12/GPL/openjdk-21.0.1_windows-x64_bin.zip', -- openjdk
		cmd = 'java.exe'
	},{
		nome = 'jdtls-java-lsp',
		link = 'https://www.eclipse.org/downloads/download.php?file=/jdtls/snapshots/jdt-language-server-latest.tar.gz',
		cmd = 'jdtls'
	},{
		nome = 'maven',
		link = 'https://dlcdn.apache.org/maven/maven-3/3.9.6/binaries/apache-maven-3.9.6-bin.zip',
		cmd = 'mvn.cmd'
	}
}

Opt.bootstrap()
Opt.setup(PROGRAMAS)
SauceCodePro.setup()

