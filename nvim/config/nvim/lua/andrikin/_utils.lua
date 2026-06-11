-- REFAZER UTILS.LUA
local M = {}

vim.env.MYVIMDIR = vim.fs.joinpath(
	vim.env.HOME, 'nvim'
)

M.optfile = vim.fs.joinpath(
	vim.env.MYVIMDIR,
	'opt', 'optfile'
)

-- append to the last
local add_path = function(dir)
	vim.env.PATH = vim.env.PATH .. ';' .. dir
end

local create_optfile = function()
	local opt = vim.fs.dirname(M.optfile)
	if not vim.uv.fs_stat(opt) then
		error('Não foi encontrado diretório "opt" do Neovim')
	end
	-- ponto crítico, de mais demora na primeira execução
	-- local optlist = vim.fn.glob((opts .. '/*/**/*.exe'),
	-- 	false, true, false
	-- )
    local optlist = vim.fs.find(
        function(n, _)
            return n:match('.*%.exe$')
        end,
        {limit = math.huge, type = 'file', path = opt}
    )
	optlist = vim.tbl_map(function(programa)
		return vim.fs.dirname(programa)
	end, optlist)
	optlist = vim.list.unique(optlist)
	vim.fn.writefile(optlist, M.optfile)
	vim.notify('Arquivo OPTSFILE criado com sucesso!')
end

-- inicializar variavéis do ambiente $PATH
M.init_path = function(force)
	if not vim.uv.fs_stat(M.optfile) or force then
		create_optfile()
	end
	local opts = vim.fn.readfile(M.optfile)
	for _, o in ipairs(opts) do
		add_path(o)
	end
end

return M
