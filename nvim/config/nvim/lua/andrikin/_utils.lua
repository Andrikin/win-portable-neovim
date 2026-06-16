-- REFAZER UTILS.LUA
local M = {}

-- INITIALIZATION

vim.env.MYVIMDIR = vim.fs.joinpath(
	vim.env.HOME, 'nvim'
)

M.OPTFILE = vim.fs.joinpath(
	vim.env.MYVIMDIR,
	'opt', 'optfile'
)

if not vim.env.NVIMOPT then
    M.OPT = vim.fs.joinpath(
        vim.env.HOME,
        'nvim', 'opt'
    )
else
    M.OPT = vim.env.NVIMOPT
end

-- Editar arquivo 'optfile'
vim.api.nvim_create_user_command("Optfile",
    function()
        vim.cmd.edit(M.OPTFILE)
    end, {}
)

local extractit = function (file, dir, async)
    if not vim.uv.fs_stat(dir) then
        error("extractit: não existe diretório.")
    end
    local it = vim.system({ 'tar', '-xf', file, '-C', dir })
    if not async then
        it:wait()
    end
end

-- append to the last
local add_path = function(dir)
    if not vim.env.PATH:match(dir) then
        vim.env.PATH = vim.env.PATH .. ';' .. dir
    end
end

local create_optfile = function()
	local opt = vim.fs.dirname(M.OPTFILE)
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
	vim.fn.writefile(optlist, M.OPTFILE)
	vim.notify('Arquivo OPTFILE criado com sucesso!')
end

-- inicializar variavéis do ambiente $PATH
M.init_path = function(force)
	if not vim.uv.fs_stat(M.OPTFILE) or force then
		create_optfile()
	end
	local opts = vim.fn.readfile(M.OPTFILE)
	for _, o in ipairs(opts) do
		add_path(o)
	end
end

-- Check git, install it
(function()
    if vim.fn.executable('git') then
        vim.print("Git já instalado!")
        return
    end
    local link = "https://github.com/git-for-windows/git/releases/download/v2.54.0.windows.1/MinGit-2.54.0-64-bit.zip"
    local dir = vim.fs.joinpath(M.OPT, 'git')
    vim.net.request(
        link,
        { outpath = dir },
        -- extrair arquivo
        function(err, _)
            if err then
                vim.print('Erro ao realizar download de git.')
            end
            extractit(
                vim.fs.joinpath( dir, vim.fs.basename(link) ),
                dir, false
            )
        end
    )
    add_path(dir)
end)()

return M
