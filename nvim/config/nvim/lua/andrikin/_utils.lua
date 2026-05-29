-- REFAZER UTILS.LUA
local M = {}

vim.env.MYVIMDIR = vim.fs.joinpath(
	vim.env.HOME, 'nvim'
)

M.optsfile = vim.fs.joinpath(
	vim.env.MYVIMDIR,
	'opts', 'optsfile'
)

-- append to the last
local add_path = function(dir)
	vim.env.PATH = vim.env.PATH .. ';' .. dir
end

local create_optsfile = function()
	local opts = vim.fs.dirname(M.optsfile)
	if not vim.uv.fs_stat(opts) then
		error('Não foi encontrado diretório "opts" do Neovim')
	end
	-- ponto crítico, de mais demora no primeiro 'run'
	local optslist = vim.fn.glob((opts .. '/*/**/*.exe'),
		false, true, false
	)
	optslist = vim.tbl_map(function(programa)
		return vim.fs.dirname(programa)
	end, optslist)
	optslist = vim.list.unique(optslist)
	vim.fn.writefile(optslist, M.optsfile)
	vim.notify('Arquivo OPTSFILE criado com sucesso!')
end

-- inicializar variavéis do ambiente $PATH
M.init_path = function(force)
	if not vim.uv.fs_stat(M.optsfile) or force then
		create_optsfile()
	end
	local opts = vim.fn.readfile(M.optsfile)
	for _, o in ipairs(opts) do
		add_path(o)
	end
end

return M
