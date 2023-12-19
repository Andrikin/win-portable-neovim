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

Diretorio.new = function(self, diretorio)
	if type(diretorio) ~= 'string' then
		error('Diretorio: new: Elemento precisa ser do tipo "string".')
	end
	local obj = {}
	setmetatable(obj, self)
	self.dir = diretorio
	return obj
end

Diretorio.__div = function(self, other)
	if getmetatable(self) ~= Diretorio or getmetatable(other) ~= Diretorio then
		return string.gsub(self.dir .. other.dir, '/', '\\')
	else
		error('Diretorio: div: Elementos precisam ser do tipo "string".')
	end
end

Diretorio.__concat = function(self, other)
	if getmetatable(self) ~= Diretorio then
		error('Diretorio: concat: Objeto não é do tipo Diretorio.')
	end
	if type(other) ~= 'string' then
		error('Diretorio: concat: Segundo argumento precisa ser do tipo "string".')
	end
	return string.gsub(self.dir .. other, '/', '\\')
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

Curl.download = function(link, diretorio)
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

Curl.extrair = function(arquivo, diretorio)
	if not arquivo or arquivo == '' then
		notify('lua config: os.lua: Curl: Arquivo não encontrado ou nulo.')
		return
	end
	if not diretorio or diretorio == '' then
		notify('lua config: os.lua: Curl: Diretório não encontrado ou nulo.')
		return
	end
	local extencao = arquivo:match('%.(tar)%..*$') or arquivo:match('%.(.*)$')
	local nome = vim.fn.fnamemodify(arquivo, ':t')
	local extrator = {}
	if extencao == 'zip' then
		extrator = {
			cmd = 'unzip',
			output = '-d'
		}
	elseif extencao == 'tar' then
		extrator = {
			cmd = {'tar', '-xf'},
			output = '-C'
		}
	end
	vim.fn.system({
		type(extrator.cmd) == 'table' and unpack(extrator.cmd) or extrator.cmd,
		arquivo,
		extrator.output,
		diretorio
	})
end

local Opt = {}

Opt.__index = Opt

Opt.OPT = vim.env.HOME .. '/nvim/opt' -- Path:new({vim.env.HOME, 'nvim', 'opt' })

Opt.PROGRAMAS = {
	{
		nome = 'w64devkit',
		link = 'https://github.com/skeeto/w64devkit/releases/download/v1.21.0/w64devkit-1.21.0.zip',
	},{
		nome = 'git',
		link = 'https://github.com/git-for-windows/git/releases/download/v2.43.0.windows.1/MinGit-2.43.0-64-bit.zip',
	},{
		nome = 'fd',
		link = 'https://github.com/sharkdp/fd/releases/download/v8.7.1/fd-v8.7.1-x86_64-pc-windows-gnu.zip',
	},{
		nome = 'ripgrep',
		link = 'https://github.com/BurntSushi/ripgrep/releases/download/14.0.3/ripgrep-14.0.3-i686-pc-windows-msvc.zip',
	},{
		nome = 'sumatra',
		link = 'https://www.sumatrapdfreader.org/dl/rel/3.5.2/SumatraPDF-3.5.2-64.zip',
	},{
		nome = 'node',
		link = 'https://nodejs.org/dist/v20.10.0/node-v20.10.0-win-x64.zip',
	},{
		nome = 'python',
		link = 'https://www.python.org/ftp/python/3.8.9/python-3.8.9-embed-amd64.zip',
	},{
		nome = 'TexLive',
		link = 'http://linorg.usp.br/CTAN/systems/win32/w32tex/TLW64/tl-win64.zip',
	},{
		nome = 'deno',
		link = 'https://github.com/denoland/deno/releases/download/v1.27.0/deno-x86_64-pc-windows-msvc.zip',
	},{
		nome = 'lua_ls',
		link = 'https://github.com/LuaLS/lua-language-server/releases/download/3.7.3/lua-language-server-3.7.3-win32-x64.zip',
	},
}

Opt.bootstrap = function(self)
	-- Criar diretório, setar configurações, etc
	if vim.fn.isdirectory(self.OPT.filename) == 0 then
		vim.fn.mkdir(self.OPT.filename, 'p', 0700)
	end
end

Opt.new = function(self, obj)
	obj = obj or {}
	setmetatable(obj, self)
	self:bootstrap()
	self.curl = Curl:new()
	return obj
end

Opt.registrar_runtime = function(self, programa)
end

Opt.init = function(self)
	for _, programa in ipairs(self.PROGRAMAS) do
		self.curl.download(programa.link, self.OPT.filename)
		-- self.curl.extrair()
	end
end

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

