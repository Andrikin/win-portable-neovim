-- Como resolver caso não exista o diretório '\nvim\deps'?
-- TODO: Como verificar diretórios e automatizar a adição de novas dependências?
local function set_dep(dependencia)
	if not string.find(vim.env.PATH, dependencia) then
		local NVIM = vim.env.HOME .. [[\nvim\deps]]
		vim.env.PATH = vim.env.PATH .. ';' .. NVIM .. dependencia
	end
end

local NVIM_DEPS = {
	git = function() set_dep([[\git\bin]]) end,
	curl = function() set_dep([[\curl\bin]]) end,
	win64devkit = function() set_dep([[\win64devkit\bin]]) end,
	node = function()
		set_dep([[\node]])
		-- Somente para Windows 7
		if vim.env.NODE_SKIP_PLATFORM_CHECK ~= 1 then
			vim.env.NODE_SKIP_PLATFORM_CHECK = 1
		end
	end,
	fd = function() set_dep([[\fd]]) end,
	ripgrep = function() set_dep([[\ripgrep]]) end,
	rust = function() set_dep([[\rust\bin]]) end,
	python = function()
		local PYTHON = [[\python-win7]]
		set_dep(PYTHON)
		set_dep(PYTHON .. [[\Scripts]])
	end,
	-- Adicionar os binários dos lsp's aqui
	lspservers = function()
		local LSP = [[\lsp-servers]]
		set_dep(LSP .. [[\javascript]])
		set_dep(LSP .. [[\lua\bin]])
	end
}

for _,d in pairs(NVIM_DEPS) do
	d()
end

