-- Como resolver a situação onde não exista o diretório '\nvim\deps'?
-- TODO: Como verificar diretórios e automatizar a adição de novas dependências?
local function set_dep(dependencia)
	if not string.find(vim.env.PATH, dependencia) then
		local NVIM = vim.env.HOME .. [[\nvim\deps]]
		vim.env.PATH = vim.env.PATH .. ';' .. NVIM .. dependencia
	end
end

local NVIM_DEPS = {
	{
		config = set_dep,
		args = [[\git\bin]]
	},
	{
		config = set_dep,
		args = [[\curl\bin]]
	},
	{
		config = set_dep,
		args = [[\win64devkit\bin]]
	},
	{
		config = set_dep,
		args = [[\fd]]
	},
	{
		config = set_dep,
		args = [[\ripgrep]]
	},
	{
		config = set_dep,
		args = [[\rust\bin]]
	},
	{
		config = function()
			set_dep([[\node]])
			-- Somente para Windows 7
			if vim.env.NODE_SKIP_PLATFORM_CHECK ~= 1 then
				vim.env.NODE_SKIP_PLATFORM_CHECK = 1
			end
		end,
	},
	{
		config = function()
			local PYTHON = [[\python-win7]]
			set_dep(PYTHON)
			set_dep(PYTHON .. [[\Scripts]])
			-- Python 
			vim.g.python3_host_prog = PYTHON
		end,
	},
	-- Adicionar os binários dos lsp's aqui
	{
		config = function()
			local LSP = [[\lsp-servers]]
			set_dep(LSP .. [[\javascript]])
			set_dep(LSP .. [[\lua\bin]])
		end,
	}
}

for _, dep in ipairs(NVIM_DEPS) do
	dep.config(dep.args)
end

