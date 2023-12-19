-- TODO: Verificar se existe as dependências e, caso contrário, realizar o download com o curl.
--
-- INFO: Lista de links para download das dependências:
-- curl: https://curl.se/windows/latest.cgi?p=win64-mingw.zip
-- w64devkit-compiler: https://github.com/skeeto/w64devkit/releases/download/v1.21.0/w64devkit-1.21.0.zip
-- git: https://github.com/git-for-windows/git/releases/download/v2.43.0.windows.1/Git-2.43.0-64-bit.tar.bz2 -- Full Version
-- git: https://github.com/git-for-windows/git/releases/download/v2.43.0.windows.1/MinGit-2.43.0-64-bit.zip
-- fd: https://github.com/sharkdp/fd/releases/download/v8.7.1/fd-v8.7.1-x86_64-pc-windows-gnu.zip
-- ripgrep: https://github.com/BurntSushi/ripgrep/releases/download/14.0.3/ripgrep-14.0.3-i686-pc-windows-msvc.zip
-- sumatra: https://www.sumatrapdfreader.org/dl/rel/3.5.2/SumatraPDF-3.5.2-64.zip
-- node: https://nodejs.org/dist/v20.10.0/node-v20.10.0-win-x64.zip
-- HOW PORTABLE PYTHON: https://chrisapproved.com/blog/portable-python-for-windows.html
-- python 3.8.9 (Windows 7): https://www.python.org/ftp/python/3.8.9/python-3.8.9-embed-amd64.zip
-- python 3.12.1: https://www.python.org/ftp/python/3.12.1/python-3.12.1-embed-amd64.zip
-- pip installer: https://bootstrap.pypa.io/get-pip.py
-- TexLive: (2021) http://linorg.usp.br/CTAN/systems/win32/w32tex/TLW64/tl-win64.zip
-- TexLive: (Windows 7) https://ftp.math.utah.edu/pub/tex/historic/systems/texlive/2017/texlive-20170524-bin.tar.xz
-- rust: TODO
--
-- LSPs:
-- emmet: npm install -g emmet-ls
-- javascript: (deno 1.27.0) https://github.com/denoland/deno/releases/download/v1.27.0/deno-x86_64-pc-windows-msvc.zip
-- lua: https://github.com/LuaLS/lua-language-server/releases/download/3.7.3/lua-language-server-3.7.3-win32-x64.zip
-- python: pip install pyright | npm -g install pyright
-- java: TODO
-- rust: TODO

local notify = function(msg)
	vim.notify(msg)
	vim.cmd.redraw({bang = true})
end
local Path = vim.F.npcall(require, 'plenary.path')
if not Path then
	error('Init: Não foi encontrado o plugin Plenary!')
end

local win7 = string.match(vim.loop.os_uname()['version'], 'Windows 7')

local NVIM = Path:new({vim.env.HOME, 'nvim', 'deps' })
if vim.fn.isdirectory(NVIM.filename) == 0 then -- bootstrap para diretório de dependências
	vim.fn.mkdir(NVIM.filename, 'p', 0700)
end
local function set_binary_folder(dependencia)
	dependencia = Path:new(dependencia)
	if not string.find(vim.env.PATH, dependencia.filename) then
		local dir = NVIM / dependencia
		vim.env.PATH = vim.env.PATH .. ';' .. dir.filename
	end
end

local Diretorio = {}

Diretorio.__index = Diretorio

Diretorio.separador = '\\'

Diretorio.sanitize = function(str)
	return string.gsub(str, '/', '\\')
end

Diretorio.suffix = function(str)
	return (str:match('^[/\\]') or str == '') and str or Diretorio.separador .. str
end

Diretorio.new = function(self, diretorio)
	if type(diretorio) ~= 'string' then
		error('Diretorio: new: Elemento precisa ser do tipo "string".')
	end
	local obj = {}
	setmetatable(obj, self)
	self.dir = self.sanitize(diretorio)
	return obj
end

Diretorio.__div = function(self, other)
	if getmetatable(self) ~= Diretorio or getmetatable(other) ~= Diretorio then
		error('Diretorio: div: Elementos precisam ser do tipo "string".')
	end
	return self.sanitize(self.dir .. Diretorio.suffix(other.dir))
end

Diretorio.__concat = function(self, str)
	if getmetatable(self) ~= Diretorio then
		error('Diretorio: concat: Objeto não é do tipo Diretorio.')
	end
	if type(str) ~= 'string' then
		error('Diretorio: concat: Argumento precisa ser do tipo "string".')
	end
	return self.sanitize(self.dir .. Diretorio.suffix(str))
end

Diretorio.__tostring = function(self)
	return self.dir
end

local Curl = {}

Curl.__index = Curl

Curl.new = function(self, obj)
	obj = obj or {}
	setmetatable(obj, self)
	if not self:exist() then
		error('Não foi encontrado curl no sistema. Verificar e realizar a instalação do curl neste computador!\nLink para download: https://curl.se/windows/latest.cgi?p=win64-mingw.zip')
	end
	return obj
end

Curl.exist = function()
	return vim.fn.executable('curl') == 1
end

-- @param link string
-- @param diretorio Diretorio
Curl.download = function(link, diretorio)
	if getmetatable(diretorio) == Diretorio then
		diretorio = tostring(diretorio)
	end
	if not link or link == '' then
		notify('lua config: os.lua: Curl: Link não encontrado ou nulo.')
		return
	end
	if not diretorio or diretorio == '' then
		notify('lua config: os.lua: Curl: Diretório não encontrado ou nulo.')
		return
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
end

-- TODO: Verificar extração concluída com sucesso
-- @param arquivo string
-- @param pasta string
-- @param diretorio Diretorio
Curl.extrair = function(arquivo, pasta, diretorio)
	if not arquivo or arquivo == '' then
		notify('lua config: os.lua: Curl: Arquivo não encontrado ou nulo.')
		return
	elseif not diretorio or getmetatable(diretorio) ~= Diretorio then
		notify('lua config: os.lua: Curl: Objeto Diretorio não encontrado ou nulo.')
		return
	elseif not pasta or pasta == '' then
		notify('lua config: os.lua: Curl: Nome para diretório de extração não encontrado ou nulo.')
		return
	end
	local extencao = arquivo:match('%.(tar)%..*$') or arquivo:match('%.(.*)$')
	local extrator = {}
	if extencao == 'zip' then
		extrator = {
			cmd = 'unzip',
			diretorio = '-d'
		}
	elseif extencao == 'tar' then
		extrator = {
			cmd = {'tar', '-xf'},
			diretorio = '-C'
		}
	end
	-- criar diretório para extrair arquivo
	if vim.fn.isdirectory(pasta) == 0 then
		vim.fn.mkdir(pasta, 'p', 0700)
	end
	vim.fn.system({
		type(extrator.cmd) == 'table' and unpack(extrator.cmd) or extrator.cmd,
		diretorio .. arquivo,
		extrator.diretorio,
		pasta
	})
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
		cmd = 'sumatra.exe'
	},{
		nome = 'node',
		link = 'https://nodejs.org/dist/v20.10.0/node-v20.10.0-win-x64.zip',
		cmd = 'node.exe',
		config = function()
		end
	},{
		nome = 'python',
		link = 'https://www.python.org/ftp/python/3.8.9/python-3.8.9-embed-amd64.zip',
		cmd = 'python.exe',
		config = function()
			-- configurações extras
		end
	},{
		nome = 'latex',
		link = 'http://linorg.usp.br/CTAN/systems/win32/w32tex/TLW64/tl-win64.zip',
		cmd = 'pdflatex.exe',
		config = function()
		end
	},{
		nome = 'deno',
		link = 'https://github.com/denoland/deno/releases/download/v1.27.0/deno-x86_64-pc-windows-msvc.zip',
		cmd = 'deno.exe'
	},{
		nome = 'lua',
		link = 'https://github.com/LuaLS/lua-language-server/releases/download/3.7.3/lua-language-server-3.7.3-win32-x64.zip',
		cmd = '.exe'
	},
}

local Opt = {}

Opt.__index = Opt

Opt.DIRETORIO = Diretorio:new(vim.env.HOME .. '/nvim/opt')

Opt.new = function(self, obj)
	obj = obj or {}
	setmetatable(obj, self)
	self:bootstrap()
	self.curl = Curl:new()
	return obj
end

Opt.bootstrap = function(self)
	-- Criar diretório, setar configurações, etc
	if vim.fn.isdirectory(tostring(self.DIRETORIO)) == 0 then
		vim.fn.mkdir(tostring(self.DIRETORIO), 'p', 0700)
	end
end

Opt.config = function(self, opt)
	self.PROGRAMAS = opt
end

Opt.registrar_path = function(self, programa)
	-- verificar se programa já está no PATH
	if not vim.env.PATH:match(programa.nome) then
		local busca = self.DIRETORIO .. programa.nome
		local diretorio = vim.fs.find(programa.cmd, {path = busca, type = 'file'})[1]
		-- adicionar ao PATH
		if diretorio ~= '' then
			vim.env.PATH = vim.env.PATH .. ';' .. vim.fn.fnamemodify(diretorio, ':h')
		else
			notify(string.format('Opt: registrar_path: Executável de programa não encontrado %s', programa.nome))
		end
	end
	if programa.config and vim.env.PATH:match(programa.nome) then
		programa.config()
	end
end

Opt.init = function(self)
	for _, programa in ipairs(self.PROGRAMAS) do
		local arquivo = vim.fn.fnamemodify(programa.link, ':t')
		self.curl.download(programa.link, self.DIRETORIO)
		self.curl.extrair(arquivo, programa.nome, self.DIRETORIO)
		self:registrar_path(programa)
	end
end

local dependencias = Opt:new()
dependencias.config(PROGRAMAS)
-- dependencias.init()

local DEPENDENCIAS = {
	{
		config = set_binary_folder,
		args = {'git', 'cmd'}
	},
	{
		config = set_binary_folder,
		args = {'curl', 'bin'}
	},
	{
		config = set_binary_folder,
		args = {'win64devkit', 'bin'}
	},
	{
		config = set_binary_folder,
		args = {'fd'}
	},
	{
		config = set_binary_folder,
		args = {'ripgrep'}
	},
	{
		config = set_binary_folder,
		args = {'rust', 'bin'}
	},
	{
		config = set_binary_folder,
		args = {'nexusfont'}
	},
	{
		config = set_binary_folder,
		args = {'sumatra'}
	},
	{
		config = function()
			set_binary_folder({'node'})
			-- Somente para Windows 7
			if win7 and vim.env.NODE_SKIP_PLATFORM_CHECK ~= 1 then
				vim.env.NODE_SKIP_PLATFORM_CHECK = 1
			end
		end,
	},
	{
		config = function()
			local PYTHON = {'python', 'python3.8.9'} -- windows 7, 3.12 windows 10+
			local PYTHON_SCRIPTS = {PYTHON[1], PYTHON[2], 'Scripts'}
			set_binary_folder(PYTHON) -- python.exe
			set_binary_folder(PYTHON_SCRIPTS) -- pip.exe
			-- Python 
			vim.g.python3_host_prog = NVIM / Path:new(PYTHON) .. '\\python.exe'
		end,
	},
	-- Adicionar os binários dos lsp's aqui
	{
		config = function() -- Configuração de LSP servers
			set_binary_folder({'lsp-servers', 'javascript'})
			set_binary_folder({'lsp-servers', 'lua', 'bin'})
			set_binary_folder({'lsp-servers', 'rust'})
		end,
	},
	{
		config = function() -- latex
			local latex = vim.fs.find('x64', {path = vim.env.HOME, type = 'directory'})[1]
			if not string.find(vim.env.PATH, latex) then
				vim.env.PATH = vim.env.PATH .. ';' .. latex
			end
		end,
	}
}

for _, dep in ipairs(DEPENDENCIAS) do
	dep.config(dep.args)
end

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
	if self:fonte_extraida() then
		notify('Encontrado fonte SauceCodePro neste computador!')
		return
	end
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
		return
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
	if self:fonte_intalada_regedit() then
		notify('Fonte já registrada no sistema regedit deste computador!')
		return
	end
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
	self:download()
	self:extrair()
	self:registrar()
	if self:fonte_intalada_regedit() then
		notify('Fonte SauceCodePro instalada com sucesso. Reinicie o nvim para carregar a fonte.')
	end
end

local has_curl = vim.fn.executable('curl') == 1
if has_curl then
	SauceCodePro:instalar()
else
	notify('Não foi possível instalar a fonte SauceCodePro neste computador. Instale curl para continuar.')
end

