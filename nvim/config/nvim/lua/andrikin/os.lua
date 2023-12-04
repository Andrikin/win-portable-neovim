-- TODO: Como verificar diretórios e automatizar a adição de novas dependências?
-- refac: resolver a situação onde não exista o diretório '/nvim/deps'?
-- refac: utilizar vim.fs.find para setar os diretórios dos executáveis

local Path = vim.F.npcall(require, 'plenary.path')
if not Path then
	error('Init: Não foi encontrado o plugin Plenary!')
end

local win7 = string.match(vim.loop.os_uname()['version'], 'Windows 7')

local NVIM = Path:new(vim.env.HOME) / Path:new({'nvim', 'deps'})
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
			vim.g.python3_host_prog = NVIM / Path:new(PYTHON) .. '/python.exe'
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

-- TODO: Verificar se está no sistema Windows
-- wip: passar código para plugin da Ouvidoria
-- Inicialização do NexusFont para uso da fonte SauceNerdPro
local check_font_reg = {
	'reg',
	'query',
	'"HKLM\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Fonts"',
	'/s',
	'|',
	'find',
	'"SauceCodePro"'
}
local has_font_reg = vim.fn.system(check_font_reg) ~= ''
local has_font_local = vim.fn.glob(
	'C:/Users/' .. vim.env.USERNAME .. '/AppData/Local/Microsoft/Windows/Fonts/SauceCodePro*',
	false,
	true
)
local has_font = has_font_reg or (#has_font_local > 0)
if not has_font then
	local query = {
		'tasklist',
		'/fo',
		'list',
		'/fi',
		'"STATUS eq running"',
		'|',
		'find',
		'"nexusfont.exe"'
	}
	vim.fn.system(query)
	local has_nexusfont = vim.v.shell_error == 0
	if not has_nexusfont then
		vim.fn.jobstart('nexusfont.exe', { detach = true })
	end
end
