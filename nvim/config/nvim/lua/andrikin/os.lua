-- TODO: Verificar se existe as dependências e, caso contrário, realizar o download com o curl.
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

local NVIM_DEPS = {
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

for _, dep in ipairs(NVIM_DEPS) do
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
end

local has_curl = vim.fn.executable('curl') == 1
if has_curl then
	SauceCodePro:instalar()
else
	notify('Não foi possível instalar a fonte SauceCodePro neste computador.')
end

