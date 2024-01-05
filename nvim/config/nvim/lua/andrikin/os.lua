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
-- TexLive: (2021) http://linorg.usp.br/CTAN/systems/win32/w32tex/TLW64/tl-win64.zip
-- TexLive: (Windows 7 2017) https://ftp.math.utah.edu/pub/tex/historic/systems/texlive/2017/texlive-20170524-bin.tar.xz
-- TinyTex: https://yihui.org/tinytex/
-- TinyTex: https://github.com/rstudio/tinytex-releases/releases/download/v2023.12/TinyTeX-1-v2023.12.zip
-- Java: https://download.oracle.com/java/21/latest/jdk-21_windows-x64_bin.zip
-- Jdtls: https://www.eclipse.org/downloads/download.php?file=/jdtls/snapshots/jdt-language-server-latest.tar.gz
-- Maven: https://dlcdn.apache.org/maven/maven-3/3.9.6/binaries/apache-maven-3.9.6-bin.zip
-- rust: TODO

-- LSPs:
-- javascript: (deno 1.27.0 Windows 7) https://github.com/denoland/deno/releases/download/v1.27.0/deno-x86_64-pc-windows-msvc.zip
-- lua: https://github.com/LuaLS/lua-language-server/releases/download/3.7.3/lua-language-server-3.7.3-win32-x64.zip
-- emmet: npm install -g emmet-ls
-- python: pip install pyright | npm -g install pyright
-- java: TODO
-- rust: TODO

-- WIP: Como realizar o download do curl, quando não tem ele no sistema?
-- WIP: Utilizar multithreads para realizar os downloads
-- TODO: Refatorar código?

-- IMPORTANT(Windows 10+): Desabilitar python.exe e python3.exe em "Gerenciar aliases de execução de aplicativo".
-- Windows executa este alias antes de executar python declarado em PATH.
-- ALTERNATIVE FIX: Remover WindowsApps do PATH
if vim.env.PATH:match('WindowsApps') then
	local PATH = ''
	for path in vim.env.PATH:gmatch('([^;]+)') do
		if not path:match('WindowsApps') then
			PATH = PATH ..  ';' .. path
		end
	end
	PATH = PATH:match('^.(.*)$')
	vim.env.PATH = PATH
end

local npcall = vim.F.npcall

local notify = function(msg)
	vim.notify(msg)
	vim.cmd.redraw({bang = true})
end

local win7 = string.match(vim.loop.os_uname()['version'], 'Windows 7')

local Diretorio = {}

Diretorio.__index = Diretorio

Diretorio.separador = '\\'

Diretorio.new = function(self, diretorio)
	vim.validate({diretorio = {diretorio, {'table', 'string'}}})
	if type(diretorio) == 'table' then
		for _, valor in ipairs(diretorio) do
			if type(valor) ~= 'string' then
				error('Diretorio: new: Elemento de lista diferente de "string"!')
			end
		end
	end
	local obj = {}
	setmetatable(obj, self)
	if type(diretorio) == 'table' then
		local concatenar = diretorio[1]
		for i=2,#diretorio do
			concatenar = concatenar .. obj.suffix(diretorio[i])
		end
		diretorio = concatenar
	end
	obj.nome = self.sanitize(diretorio)
	return obj
end

Diretorio.sanitize = function(str)
	vim.validate({ str = {str, 'string'} })
	return string.gsub(str, '/', '\\')
end

Diretorio.suffix = function(str)
	vim.validate({ str = {str, 'string'} })
	return (str:match('^[/\\]') or str == '') and str or Diretorio.separador .. str
end

Diretorio.add = function(self, diretorio)
	if type(diretorio) == 'table' then
		local concatenar = ''
		for _, p in ipairs(diretorio) do
			concatenar = concatenar .. self.suffix(p)
		end
		diretorio = concatenar
	end
	self.nome = self.nome .. self.suffix(diretorio)
end

Diretorio.__div = function(self, other)
	if getmetatable(self) ~= Diretorio or getmetatable(other) ~= Diretorio then
		error('Diretorio: __div: Elementos precisam ser do tipo "string".')
	end
	return self.sanitize(self.nome .. Diretorio.suffix(other.dir))
end

Diretorio.__concat = function(self, str)
	if getmetatable(self) ~= Diretorio then
		error('Diretorio: __concat: Objeto não é do tipo Diretorio.')
	end
	if type(str) ~= 'string' then
		error('Diretorio: __concat: Argumento precisa ser do tipo "string".')
	end
	return self.sanitize(self.nome .. Diretorio.suffix(str))
end

Diretorio.__tostring = function(self)
	return self.nome
end

local Curl = {}

Curl.__index = Curl

Curl.UNZIP = 'http://linorg.usp.br/CTAN/systems/win32/w32tex/unzip.exe'

-- FATO: Windows 10 build 17063 or later is bundled with tar.exe which is capable of working with ZIP files 
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
	Curl.download(Curl.UNZIP, vim.env.NVIM_OPT)
	local unzip = vim.fs.find('unzip.exe', {path = vim.env.NVIM_OPT, type = 'file'})[1]
	if unzip == '' then
		error('Curl: bootstrap: Não foi possível encontrar o executável unzip.exe.')
	end
end

Curl.instalado = function()
	return vim.fn.executable('curl') == 1
end

-- @param link string
-- @param diretorio string
Curl.download = function(link, diretorio)
	vim.validate({
		link = {link, 'string'},
		diretorio = {diretorio, 'string'}
	})
	if link == '' or diretorio == '' then
		error('Curl: download: Variável nula')
	end
	local arquivo = vim.fn.fnamemodify(link, ':t')
	diretorio = Diretorio:new(diretorio) .. arquivo
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

-- @param arquivo string
-- @param diretorio string
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
	error('Não foi encontrado curl no sistema. Verificar e realizar a instalação do curl neste computador!\nLink para download: https://curl.se/windows/latest.cgi?p=win64-mingw.zip')
else
	Curl.bootstrap()
end

-- Instalação da fonte SauceCodePro no computador
local Fonte = {}

Fonte.__index = Fonte

Fonte.DIRETORIO = Diretorio:new({
	vim.env.LOCALAPPDATA,
	'Microsoft',
	'Windows',
	'Fonts'
})

Fonte.LINK = 'https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/SourceCodePro.zip'

Fonte.ARQUIVO = Fonte.DIRETORIO .. vim.fn.fnamemodify(Fonte.LINK, ':t')

Fonte.REGISTRO = 'HKCU\\Software\\Microsoft\\Windows NT\\CurrentVersion\\Fonts'

Fonte.setup = function()
	if Fonte.query_regedit() then
		notify('Fonte SauceCodePro já instalada.')
		do return end
	end
	if Curl.instalado() then
		Fonte.instalar()
	else
		notify('Não foi possível instalar a fonte SauceCodePro neste computador. Instale curl para continuar.')
	end
end


Fonte.fonte_extraida = function()
	return #(vim.fn.glob(Fonte.DIRETORIO .. 'SauceCodePro*.ttf', false, true)) > 0
end

Fonte.zip_encontrado = function()
	return vim.loop.fs_stat(Fonte.ARQUIVO)
end

Fonte.download = function()
	-- Realiza download em AppData/Local/Microsoft/Windows/Fonts
	if vim.fn.isdirectory(tostring(Fonte.DIRETORIO)) == 0 then
		vim.fn.mkdir(tostring(Fonte.DIRETORIO), 'p', 0700)
	end
	-- Realizar download da fonte
	Curl.download(Fonte.LINK, Fonte.DIRETORIO.nome)
	if not Fonte.zip_encontrado() then
		error('Não foi possível realizar o download do arquivo da fonte.')
	end
	notify('Arquivo fonte SauceCodePro baixado!')
end

Fonte.extrair = function()
	-- Decompressar arquivo zip
	-- Appdata/Local
	if not Fonte.zip_encontrado() then
		notify('Arquivo SauceCodePro.zip não encontrado! Realizar o download do arquivo para continuar a intalação.')
		do return end
	end
	Curl.extrair(Fonte.ARQUIVO, Fonte.DIRETORIO.nome)
	if Fonte.fonte_extraida() then
		notify('Arquivo fonte SauceCodePro.zip extraído!')
		Fonte.FONTES = vim.fn.glob(Fonte.DIRETORIO .. 'SauceCodePro*.ttf', false, true)
	else
		error('Não foi possível extrair os arquivo de fonte SauceCodePro.')
	end
end

Fonte.query_regedit = function()
	-- Verificando se a fonte SauceCodePro está intalada no computador
	local lista = vim.tbl_filter(
		function(elemento)
			return elemento:match('SauceCodePro')
		end,
		vim.fn.systemlist({
			'reg',
			'query',
			Fonte.REGISTRO,
			'/s'
	}))
	return #lista > 0
end

Fonte.regedit = function()
	-- Registra as fontes no RegEdit do sistema.
	for _, fonte in ipairs(Fonte.FONTES) do
		local arquivo = vim.fn.fnamemodify(fonte, ':t')
		local diretorio = Fonte.DIRETORIO .. arquivo
		vim.fn.system({
			'reg',
			'add',
			Fonte.REGISTRO,
			'/v',
			arquivo:match('(.*)%..*$') .. ' (TrueType)', -- nome de registro da fonte
			'/t',
			'REG_SZ',
			'/d',
			diretorio,
			'/f'
		})
	end
end

Fonte.instalar = function()
	if Fonte.fonte_extraida() then
		notify('Encontrado fonte SauceCodePro extraída neste computador!')
		do return end
	else
		Fonte.download()
		Fonte.extrair()
	end
	if Fonte.query_regedit() then
		notify('Fonte SauceCodePro já registrada no sistema regedit deste computador!')
		do return end
	else
		Fonte.regedit()
		if Fonte.query_regedit() then
			notify('Fonte SauceCodePro instalada com sucesso. Reinicie o nvim para carregar a fonte.')
		else
			notify('Erro encontrado. Verificar se é possível executar comandos no regedit.')
		end
	end
end

local Opt = {}

Opt.__index = Opt

Opt.DIRETORIO = Diretorio:new(vim.env.NVIM_OPT)

Opt.bootstrap = function()
	-- Criar diretório, setar configurações, etc
	if vim.fn.isdirectory(tostring(Opt.DIRETORIO)) == 0 then
		vim.fn.mkdir(tostring(Opt.DIRETORIO), 'p', 0700)
	end
	if not vim.env.PATH:match(tostring(Opt.DIRETORIO):gsub('[\\/-]', '.')) then
		vim.env.PATH = vim.env.PATH .. ';' .. tostring(Opt.DIRETORIO)
	end
end

Opt.config = function(cfg)
	Opt.DEPENDENCIAS = cfg
end

-- @param programa table
Opt.registrar = function(programa)
	-- verificar se programa já está no PATH
	local busca = Opt.DIRETORIO .. programa.nome
	local limite = vim.tbl_islist(programa.cmd) and #programa.cmd or 1
	local diretorios = vim.fs.find(programa.cmd, {path = busca, type = 'file', limit = limite})
	local registrado = vim.env.PATH:match(busca:gsub('[\\-]', '.'))
	if not registrado and #diretorios == 0 then
		notify('Opt: registrar_path: Baixar programa e registrar no sistema.')
		return false
	end
	if registrado then
		notify(string.format('Opt: registrar_path: Programa %s já registrado no sistema!', programa.nome))
		return true
	end
	-- adicionar ao PATH
	if #diretorios == 0 then
		notify(string.format('Opt: registrar_path: Executável de programa não encontrado %s', programa.nome))
		return false
	end
	for _, dir in ipairs(diretorios) do
		vim.env.PATH = vim.env.PATH .. ';' .. vim.fn.fnamemodify(dir, ':h')
	end
	if vim.env.PATH:match(busca:gsub('[\\-]', '.')) then
		notify(string.format('Opt: registrar_path: Programa %s registrado no PATH do sistema.', programa.nome))
		if programa.config then -- caso tenha configuração, executá-la
			notify(string.format('Opt: registrar_path: Configurando programa %s.', programa.nome))
			programa.config()
		else
			notify(string.format('Opt: registrar_path: Não foi encontrado configuração para o programa %s.', programa.nome))
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
			if not vim.loop.fs_stat(Opt.DIRETORIO .. arquivo) then
				Curl.download(programa.link, Opt.DIRETORIO.nome)
			else
				notify(string.format('Opt: init: Arquivo %s já existe.', arquivo))
			end
			if #vim.fn.glob(Diretorio:new(diretorio) .. '*', false, true) == 0 then
				-- criar diretório para extrair arquivo
				if vim.fn.isdirectory(diretorio) == 0 then
					vim.fn.mkdir(diretorio, 'p', 0700)
				end
				Curl.extrair(Opt.DIRETORIO .. arquivo, diretorio)
			else
				notify(string.format('Opt: init: Arquivo %s já extraído.', arquivo))
			end
			Opt.registrar(programa)
		end
	end
end

Opt.setup = function(cfg)
	Opt.config(cfg)
	Opt.init()
end

Opt.bootstrap()

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
			local diretorio = Diretorio:new(vim.env.NVIM_OPT) .. 'sumatra'
			local instalado = vim.fn.glob(diretorio .. 'sumatra*.exe')
			if instalado ~= '' then
				if vim.fn.fnamemodify(instalado, ':t') == 'sumatra.exe' then
					notify('Arquivo Sumatra já renomeado.')
					do return end
				end
				vim.fn.system({
					'mv',
					instalado,
					diretorio .. 'sumatra.exe'
				})
			else
				notify('Erro ao renomear executável Sumatra.')
			end
		end
	},{
		nome = 'node',
		link = 'https://nodejs.org/dist/v20.10.0/node-v20.10.0-win-x64.zip',
		cmd = 'node.exe',
		config = function()
			local installed = function(pacote) -- checar se diretório existe
				return not vim.tbl_isempty(vim.fs.find(pacote, {path = Diretorio:new(vim.env.NVIM_OPT) .. 'node', type = 'directory'}))
			end
			-- configurações extras
			if win7 and vim.env.NODE_SKIP_PLATFORM_CHECK ~= 1 then
				vim.env.NODE_SKIP_PLATFORM_CHECK = 1
			end
			if vim.fn.executable('npm') == 1 and not installed('neovim') then
				vim.fn.system({
					'npm',
					'install',
					'-g',
					'neovim'
				})
			end
			if vim.fn.executable('npm') == 1 and not installed('emmet-ls') then
				vim.fn.system({ -- configuração LSP emmet
					'npm',
					'install',
					'-g',
					'emmet-ls'
				})
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
			get_pip.diretorio = Diretorio:new(vim.env.NVIM_OPT) .. 'python'
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
						notify(string.format('Pacote %s já instalado.', pacote))
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
		nome = 'latex',
		link = 'https://github.com/rstudio/tinytex-releases/releases/download/v2023.12/TinyTeX-v2023.12.zip',
		cmd = 'pdflatex.exe',
		config = function()
			if vim.fn.executable('tlmgr') == 0 then
				notify('latex: "tlmgr" não encontrado. Verificar distribuição Latex instalada.')
				do return end
			end
			local instalar = {
				'babel-portuges',
				'datetime2'
			}
			local instalados = vim.fn.systemlist({
				'kpsewhich',
				'brazil.ldf',
				'datetime2.sty'
			})
			if vim.tbl_isempty(instalados) then
				for _, pacote in ipairs(instalar) do
					vim.fn.system({
						'tlmgr.bat',
						'install',
						pacote
					})
				end
			else
				notify('Packages latex já instalados.')
			end
		end
	},{
		nome = 'deno',
		link = 'https://github.com/denoland/deno/releases/download/v1.27.0/deno-x86_64-pc-windows-msvc.zip',
		cmd = 'deno.exe'
	},{
		nome = 'lua',
		link = 'https://github.com/LuaLS/lua-language-server/releases/download/3.7.3/lua-language-server-3.7.3-win32-x64.zip',
		cmd = 'lua-language-server.exe'
	},{
		nome = 'java',
		link = 'https://download.oracle.com/java/21/latest/jdk-21_windows-x64_bin.zip',
		cmd = 'java.exe'
	},{
		nome = 'jdtls',
		link = 'https://www.eclipse.org/downloads/download.php?file=/jdtls/snapshots/jdt-language-server-latest.tar.gz',
		cmd = 'jdtls'
	},{
		nome = 'maven',
		link = 'https://dlcdn.apache.org/maven/maven-3/3.9.6/binaries/apache-maven-3.9.6-bin.zip',
		cmd = 'mvn.cmd'
	}
}

Opt.setup(PROGRAMAS)
Fonte.setup()

