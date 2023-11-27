-- TODO: Como verificar diretórios e automatizar a adição de novas dependências?
-- refac: resolver a situação onde não exista o diretório '/nvim/deps'?
-- refac: utilizar vim.fs.find para setar os diretórios dos executáveis
-- refac: vim.loop.os_uname para obter informação do sistema

local win7 = string.match(vim.loop.os_uname()['version'], 'Windows 7')

local function set_binary_folder(dependencia)
	if not string.find(vim.env.PATH, dependencia) then
		local NVIM = vim.env.HOME .. '/nvim/deps'
		vim.env.PATH = vim.env.PATH .. ';' .. NVIM .. dependencia
	end
end

local NVIM_DEPS = {
	{
		config = set_binary_folder,
		args = '/git/bin'
	},
	{
		config = set_binary_folder,
		args = '/git/cmd'
	},
	{
		config = set_binary_folder,
		args = '/curl/bin'
	},
	{
		config = set_binary_folder,
		args = '/win64devkit/bin'
	},
	{
		config = set_binary_folder,
		args = '/fd'
	},
	{
		config = set_binary_folder,
		args = '/ripgrep'
	},
	{
		config = set_binary_folder,
		args = '/rust/bin'
	},
	{
		config = set_binary_folder,
		args = '/nexusfont'
	},
	{
		config = function()
			set_binary_folder('/node')
			-- Somente para Windows 7
			if win7 and vim.env.NODE_SKIP_PLATFORM_CHECK ~= 1 then
				vim.env.NODE_SKIP_PLATFORM_CHECK = 1
			end
		end,
	},
	{
		config = function()
			local PYTHON = '/python/python3.8.9' -- windows 7, 3.12 windows 10+
			set_binary_folder(PYTHON) -- python.exe
			set_binary_folder(PYTHON .. '/Scripts') -- pip.exe
			-- Python 
			vim.g.python3_host_prog = vim.env.HOME .. '/nvim/deps/' .. PYTHON .. '/python.exe'
		end,
	},
	-- Adicionar os binários dos lsp's aqui
	{
		config = function()
			local LSP = '/lsp-servers'
			set_binary_folder(LSP .. '/javascript')
			set_binary_folder(LSP .. '/lua/bin')
			set_binary_folder(LSP .. '/rust')
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

-- Inicialização do NexusFont para uso da fonte SauceNerdPro
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
local nexusfont = vim.v.shell_error == 0
if not nexusfont then
	vim.fn.jobstart('nexusfont.exe', { detach = true })
end

