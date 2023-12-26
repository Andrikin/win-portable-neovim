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

local notify = function(msg)
	vim.notify(msg)
	vim.cmd.redraw({bang = true})
end

local win7 = string.match(vim.loop.os_uname()['version'], 'Windows 7')

local Diretorio = {}

Diretorio.__index = Diretorio

Diretorio.separador = '\\'

Diretorio.new = function(self, path)
	if type(path) ~= 'string' then
		error('Diretorio: new: Elemento precisa ser do tipo "string".')
	end
	local diretorio = {}
	setmetatable(diretorio, self)
	diretorio.dir = self.sanitize(path)
	return diretorio
end

Diretorio.sanitize = function(str)
	return string.gsub(str, '/', '\\')
end

Diretorio.suffix = function(str)
	return (str:match('^[/\\]') or str == '') and str or Diretorio.separador .. str
end

Diretorio.__div = function(self, other)
	if getmetatable(self) ~= Diretorio or getmetatable(other) ~= Diretorio then
		error('Diretorio: __div: Elementos precisam ser do tipo "string".')
	end
	return self.sanitize(self.dir .. Diretorio.suffix(other.dir))
end

Diretorio.__concat = function(self, str)
	if getmetatable(self) ~= Diretorio then
		error('Diretorio: __concat: Objeto não é do tipo Diretorio.')
	end
	if type(str) ~= 'string' then
		error('Diretorio: __concat: Argumento precisa ser do tipo "string".')
	end
	return self.sanitize(self.dir .. Diretorio.suffix(str))
end

Diretorio.__tostring = function(self)
	return self.dir
end

local OPT = Diretorio:new(vim.env.HOME .. '/nvim/opt')

local Curl = {}

Curl.__index = Curl

Curl.UNZIP = 'http://linorg.usp.br/CTAN/systems/win32/w32tex/unzip.exe'

Curl.new = function(self, obj)
	obj = obj or {}
	setmetatable(obj, self)
	if not self:exist() then
		error('Não foi encontrado curl no sistema. Verificar e realizar a instalação do curl neste computador!\nLink para download: https://curl.se/windows/latest.cgi?p=win64-mingw.zip')
	end
	self:bootstrap()
	return obj
end

-- FATO: Windows 10 build 17063 or later is bundled with tar.exe which is capable of working with ZIP files 
Curl.bootstrap = function(self)
	-- Realizar o download das ferramentas unzip
	-- e adicioná-las ao PATH
	if win7 and vim.fn.executable('tar') then
		notify('Curl: bootstrap: Sistema não possui tar.exe! Realizar a instalação do programa.')
		do return end
	end
	if vim.fn.executable('unzip') == 1 then
		notify('Curl: bootstrap: Sistema já possui Unzip.')
		do return end
	end
	self.download(self.UNZIP, OPT)
	local unzip = vim.fs.find('unzip.exe', {path = OPT.dir, type = 'file'})[1]
	if unzip == '' then
		error('Curl: bootstrap: Não foi possível encontrar o executável unzip.exe.')
	end
	vim.env.PATH = vim.env.PATH .. ';' .. OPT.dir
end

Curl.exist = function()
	return vim.fn.executable('curl') == 1
end

-- @param link string
-- @param diretorio Diretorio
Curl.download = function(link, diretorio)
	local arquivo = vim.fn.fnamemodify(link, ':t')
	if getmetatable(diretorio) == Diretorio then
		diretorio = tostring(diretorio .. arquivo)
	else
		error('Curl: download: Argumento deve ser do tipo "Diretorio".')
	end
	if not link or link == '' then
		notify('lua config: os.lua: Curl: Link não encontrado ou nulo.')
		do return end
	end
	if not diretorio or diretorio == '' then
		notify('lua config: os.lua: Curl: Diretório não encontrado ou nulo.')
		do return end
	end
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
-- @param pasta string
-- @param opt Diretorio
Curl.extrair = function(arquivo, pasta, opt)
	if not arquivo or arquivo == '' then
		notify('Curl: extrair: Arquivo não encontrado ou nulo.')
		do return end
	end
	if not pasta or pasta == '' then
		notify('Curl: extrair: Nome para diretório de extração não encontrado ou nulo.')
		do return end
	end
	if not opt or getmetatable(opt) ~= Diretorio then
		error('Curl: extrair: Objeto Diretorio não encontrado ou nulo.')
		do return end
	end
	local extencao = arquivo:match('%.(tar)%.[a-z]*$') or arquivo:match('%.([a-z]*)$')
	pasta = opt .. pasta
	if extencao == 'zip' then
		vim.fn.system({
			'unzip',
			opt .. arquivo,
			'-d',
			pasta
		})
	elseif extencao == 'tar' then
		vim.fn.system({
			'tar',
			'-xf',
			opt .. arquivo,
			'-C',
			pasta
		})
	end
	if vim.v.shell_error == 0 then
		notify(string.format('Curl: extrair: Arquivo %s extraído com sucesso!', arquivo))
	else
		notify(string.format('Curl: extrair: Erro encontrado! Não foi possível extrair o arquivo %s', arquivo))
	end
end

local Opt = {}

Opt.__index = Opt

Opt.DIRETORIO = OPT

Opt.new = function(self, obj)
	obj = obj or {}
	setmetatable(obj, self)
	obj:bootstrap()
	obj.curl = Curl:new()
	return obj
end

Opt.bootstrap = function(self)
	-- Criar diretório, setar configurações, etc
	if vim.fn.isdirectory(tostring(self.DIRETORIO)) == 0 then
		vim.fn.mkdir(tostring(self.DIRETORIO), 'p', 0700)
	end
end

Opt.config = function(self, cfg)
	self.DEPS = cfg
end

-- @param programa table
Opt.registrar_path = function(self, programa)
	-- verificar se programa já está no PATH
	local busca = self.DIRETORIO .. programa.nome
	local limite = vim.tbl_islist(programa.cmd) and #programa.cmd or 1
	local diretorios = vim.fs.find(programa.cmd, {path = busca, type = 'file', limit = limite})
	local registrado = vim.env.PATH:match(busca:gsub('\\', '.'))
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
	if vim.env.PATH:match(busca:gsub('\\', '.')) then
		notify(string.format('Opt: registrar_path: Programa %s registrado no PATH do sistema.', programa.nome))
		if programa.config then -- caso tenha configuração, executá-la
			programa.config()
		end
	end
	return true
end

Opt.init = function(self)
	for _, programa in ipairs(self.DEPS) do
		local arquivo = vim.fn.fnamemodify(programa.link, ':t')
		local diretorio = self.DIRETORIO .. programa.nome
		local registrar = self:registrar_path(programa)
		if not registrar then
			if not vim.loop.fs_stat(self.DIRETORIO .. arquivo) then
				self.curl.download(programa.link, self.DIRETORIO)
			else
				notify(string.format('Opt: init: Arquivo %s já existe. Abortando download.', arquivo))
			end
			if #vim.fn.glob(Diretorio:new(diretorio) .. '*', false, true) == 0 then
				-- criar diretório para extrair arquivo
				if vim.fn.isdirectory(diretorio) == 0 then
					vim.fn.mkdir(diretorio, 'p', 0700)
				end
				self.curl.extrair(arquivo, programa.nome, self.DIRETORIO)
			else
				notify(string.format('Opt: init: Arquivo %s já extraído.', arquivo))
			end
			self:registrar_path(programa)
		else
			notify(string.format('Opt: registrar_path: Realizando o registro do programa %s.', arquivo))
		end
	end
end

Opt.setup = function(self, cfg)
	self:config(cfg)
	self:init()
end

vim.env.PATH = vim.env.PATH .. ';' .. OPT.dir

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
		cmd = 'SumatraPDF-3.5.2-64.exe'
	},{
		nome = 'node',
		link = 'https://nodejs.org/dist/v20.10.0/node-v20.10.0-win-x64.zip',
		cmd = 'node.exe',
		config = function()
			-- configurações extras
			if win7 and vim.env.NODE_SKIP_PLATFORM_CHECK ~= 1 then
				vim.env.NODE_SKIP_PLATFORM_CHECK = 1
			end
		end
	},{
		nome = 'python',
		link = 'https://www.python.org/ftp/python/3.8.9/python-3.8.9-embed-amd64.zip',
		cmd = {'python.exe', 'pip.exe'},
		config = function()
			-- TODO: Na primeira instalação, baixar get-pip.py e modificar o arquivo python38._pth
			-- descomentando a linha 4
			vim.g.python3_host_prog = vim.fs.find('python.exe', {path = vim.env.HOME, type = 'file'})
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
			for _, pacote in ipairs(instalar) do
				vim.fn.system({
					'tlmgr.bat',
					'install',
					pacote
				})
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
		nome = 'jdtls',
		link = 'https://www.eclipse.org/downloads/download.php?file=/jdtls/snapshots/jdt-language-server-latest.tar.gz',
		cmd = 'jdtls'
	}
}

local deps = Opt:new()
deps:setup(PROGRAMAS)

-- TODO: Reformatar para utilizar o objeto Diretorio
-- Instalação da fonte SauceCodePro no computador
local SauceCodePro = {}

SauceCodePro.DIRECTORY = vim.env.LOCALAPPDATA .. '/Microsoft/Windows/Fonts'
SauceCodePro.ZIP = SauceCodePro.DIRECTORY .. '/SauceCodePro.zip'
SauceCodePro.REGISTRY = 'HKCU\\Software\\Microsoft\\Windows NT\\CurrentVersion\\Fonts'

SauceCodePro.fonte_extraida = function(self)
	return #(vim.fn.glob(self.DIRECTORY .. '/SauceCodePro*.ttf', false, true)) > 0
end

SauceCodePro.zip_encontrado = function(self)
	return vim.loop.fs_stat(self.ZIP)
end

SauceCodePro.download = function(self)
	-- Realiza download em AppData/Local/Microsoft/Windows/Fonts
	if vim.fn.isdirectory(self.DIRECTORY) == 0 then
		vim.fn.mkdir(self.DIRECTORY, 'p', 0700)
	end
	-- Realizar download da fonte
	vim.fn.system({
		'curl',
		'--fail',
		'--location',
		'--silent',
		'--output',
		self.ZIP,
		'https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/SourceCodePro.zip'
	})
	if not self:zip_encontrado() then
		error('Não foi possível realizar o download do arquivo da fonte.')
	end
	notify('Arquivo fonte SauceCodePro baixado!')
end

SauceCodePro.extrair = function(self)
	-- Decompressar arquivo zip
	-- Appdata/Local
	if not self:zip_encontrado() then
		notify('Arquivo SauceCodePro.zip não encontrado! Realizar o download do arquivo para continuar a intalação.')
		do return end
	end
	vim.fn.system({
		'unzip',
		self.ZIP,
		'-d',
		self.DIRECTORY
	})
	if self:fonte_extraida() then
		notify('Arquivo fonte SauceCodePro.zip extraído!')
		self.FILES = vim.fn.glob(self.DIRECTORY .. '/SauceCodePro*.ttf', false, true)
	else
		error('Não foi possível extrair os arquivo de fonte SauceCodePro.')
	end
end

SauceCodePro.fonte_intalada_regedit = function(self)
	-- Verificando se a fonte SauceCodePro está intalada no computador
	local lista = vim.tbl_filter(
		function(elemento)
			return elemento:match('SauceCodePro')
		end,
		vim.fn.systemlist({
			'reg',
			'query',
			self.REGISTRY,
			'/s'
	}))
	return #lista > 0
end

SauceCodePro.registrar = function(self)
	-- Registra as fontes no RegEdit do sistema.
	for _, fonte in ipairs(self.FILES) do
		local arquivo = vim.fn.fnamemodify(fonte, ':t')
		local diretorio = string.gsub(self.DIRECTORY .. '/' .. arquivo, '/', '\\')
		vim.fn.system({
			'reg',
			'add',
			self.REGISTRY,
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

SauceCodePro.instalar = function(self)
	if self:fonte_extraida() then
		notify('Encontrado fonte SauceCodePro extraída neste computador!')
		do return end
	else
		self:download()
		self:extrair()
	end
	if self:fonte_intalada_regedit() then
		notify('Fonte já registrada no sistema regedit deste computador!')
		do return end
	else
		self:registrar()
		if self:fonte_intalada_regedit() then
			notify('Fonte SauceCodePro instalada com sucesso. Reinicie o nvim para carregar a fonte.')
		end
	end
end

local has_curl = vim.fn.executable('curl') == 1
if has_curl then
	SauceCodePro:instalar()
else
	notify('Não foi possível instalar a fonte SauceCodePro neste computador. Instale curl para continuar.')
end

