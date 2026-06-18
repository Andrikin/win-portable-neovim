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
    async = async or false
    if not vim.uv.fs_stat(dir) then
        error("extractit: não existe diretório.")
    end
    local it = vim.system({ 'tar', '-xf', file, '-C', dir })
    if not async then
        it:wait()
    end
end

local downloadit = function (dir, link)
    vim.net.request(
        link,
        { outpath = dir },
        -- extrair arquivo
        function(err, _)
            if err then
                vim.print(('Erro ao realizar download de %s.'):format(vim.fs.basename(link)))
                return
            end
            local arquivo = vim.fs.joinpath( dir, vim.fs.basename(link) )
            if vim.uv.fs_stat(arquivo) and (
                arquivo:match('zip$')
                or arquivo:match('tar$')
                or arquivo:match('gz$')
            ) then
                extractit( arquivo, dir )
            end
        end
    )
end

-- append to the last
local add_path = function(dir)
    if not vim.env.PATH:match(dir) then
        vim.env.PATH = vim.env.PATH .. ';' .. dir
    end
end

-- Check folders initialization
(function()
    if not vim.uv.fs_stat(M.OPT) then
        vim.fn.mkdir(M.OPT, 'p', '0755')
    end
    local PROJETOS = vim.fs.joinpath(vim.fs.dirname(vim.env.HOME), 'projetos')
    if not vim.uv.fs_stat(PROJETOS) then
        vim.fn.mkdir(PROJETOS, 'p', '0755')
    end
    add_path(M.OPT)
    -- WIP: Check unzip, install it
    -- 'https://linorg.usp.br/CTAN/systems/windows/w32tex/unzip.exe'
    -- downloadit(M.OPT, 'https://linorg.usp.br/CTAN/systems/windows/w32tex/unzip.exe')
end)()

local create_optfile = function()
	local opt = vim.fs.dirname(M.OPTFILE)
	if not vim.uv.fs_stat(opt) then
		error('Não foi encontrado diretório "opt" do Neovim')
	end
	-- ponto crítico, de mais demora na primeira execução
	-- local optlist = vim.fn.glob((opts .. '/*/**/*.{exe,bat,cmd}'),
	-- 	false, true, false
	-- )
    local optlist = vim.fs.find(
        function(n, _)
            return n:match('.*%.exe$') or n:match('.*%.bat$') or n:match('.*%.cmd$')
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

vim.api.nvim_create_user_command("UpdateOptfile",
    function()
        M.init_path(true)
    end, {}
)

-- Check git, install it
(function()
    if vim.fn.executable('git') then
        vim.print("Git já instalado!")
        return
    end
    local GITLINK = "https://github.com/git-for-windows/git/releases/download/v2.54.0.windows.1/MinGit-2.54.0-64-bit.zip"
    local GITDIR = vim.fs.joinpath(M.OPT, 'git')
    downloadit(GITDIR, GITLINK)
    add_path(GITDIR)
end)()

-- Check font, install it
(function()
    local SAUCEREGCMD = vim.fs.joinpath(
        'HKCU','Software', 'Microsoft',
        'Windows NT', 'CurrentVersion', 'Fonts'
    ):gsub('/', '\\')
    local SAUCEDIR = vim.fs.joinpath(
        M.OPT, 'fontes', 'saucecodepro'
    )
    local SAUCELINK = 'https://github.com/ryanoasis/nerd-fonts/releases/latest/download/SourceCodePro.zip'
    local SAUCEFONTES = vim.system({
        'reg',
        'query',
        vim.fs.joinpath(
            'HKCU', 'Software', 'Microsoft',
            'Windows NT', 'CurrentVersion', 'Fonts'
        ):gsub('/', '\\'),
        '/s'
    }):wait()
    SAUCEFONTES = vim.iter(vim.fn.split(SAUCEFONTES.stdout)):filter(function(fonte)
        return fonte:match('^C:.*SauceCodePro.*$')
    end)
    local instalar = function(fontes)
        for _, fonte in ipairs(fontes) do
            local nome = vim.fs.basename(fonte)
            vim.fn.system({
                'reg',
                'add',
                SAUCEREGCMD,
                '/v',
                nome:match('(.*)%..*$'),
                '/t',
                'REG_SZ',
                '/d',
                vim.fs.joinpath(SAUCEDIR, nome),
                '/f'
            })
        end
    end
    local listarfontes = function()
        return vim.fs.find(
            function(n, _) return n:match('.*%.ttf') end,
            { limit = math.huge, type = 'file', path = SAUCEDIR }
        )
    end
    -- fonte já resgistrada no REG do sistema?
    if #SAUCEFONTES > 0 then
        vim.print('Fonte SauceCodePro já instalada!')
        vim.api.nvim_create_user_command(
            'FonteRemover',
            function()
                for _, fonte in ipairs(listarfontes()) do
                    local nome = vim.fs.basename(fonte):match('(.*)%..*$')
                    if nome then
                        vim.fn.system({
                            'reg',
                            'delete',
                            SAUCEREGCMD,
                            '/v',
                            nome,
                            '/f'
                        })
                    end
                end
            end, {}
        )
        return
    end
    -- realizar download e instalar
    if not vim.uv.fs_stat(SAUCEDIR) then
        -- vim.uv.fs_mkdir(SAUCEDIR, tonumber('755', 8))
        vim.fn.mkdir(SAUCEDIR, 'p', '0755')
    else
        vim.fs.rm(SAUCEDIR, {recursive = true})
        vim.fn.mkdir(SAUCEDIR, 'p', '0755')
    end
    -- download
    downloadit(SAUCEDIR, SAUCELINK)
    SAUCEFONTES = listarfontes()
    instalar(SAUCEFONTES)
    vim.print('Fonte SauceCodePro instalada. Reiniciar para obter a fonte.')
end)()

-- Check remote server, initialize it
(function()
    local copyq = '\\\\.\\pipe\\copyq'
    local ok, _ = pcall(vim.fn.serverstart, copyq)
    if not ok then
        vim.print("Server copyq já existe.")
    end
end)()

-- IMPORTANT(Windows 10+): Desabilitar python.exe e python3.exe em "Gerenciar
-- aliases de execução de aplicativo". Windows executa este alias antes de
-- executar python declarado em PATH.
-- ALTERNATIVE FIX: Remover WindowsApps do PATH
(function()
    local remove = function (programa)
        if vim.env.PATH:match(programa) then
            local PATH = ''
            for path in vim.env.PATH:gmatch('([^;]+)') do
                if not path:match(programa) then
                    PATH = PATH ..  ';' .. path
                end
            end
            PATH = PATH:match('^.(.*)$')
            vim.env.PATH = PATH
        end
    end
    for _, programa in ipairs({'WindowsApps', 'Oracle', 'LibreOffice'}) do
        remove(programa)
    end
end)()

-- Ssh bootstrap
(function ()
    return
end)()

-- win-portable-neovim init
(function ()
    return
end)()

-- Dependencies init
(function ()
    return
end)()

return M

