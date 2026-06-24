local M = {}

-- INITIALIZATION

local function executable(exe)
	return vim.fn.executable(exe) == 1
end

local function findexecutables(dir)
	return vim.fs.find(
		function(n, _)
			return (n:match('.*%.exe$')
				or n:match('.*%.bat$')
				or n:match('.*%.cmd$')
			)
		end,
		{limit = math.huge, type = 'file', path = dir}
	)
end

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

-- append to the last
local add_path = function(dir)
    if not vim.env.PATH:match(dir) then
        vim.env.PATH = vim.env.PATH .. ';' .. dir
    end
end

-- extração de arquivos
local extractit = function (file, dir, async, removefile)
	removefile = removefile ~= nil and removefile or false
    local arquivo = vim.fs.joinpath(dir, file)
    async = async or false
    if not vim.uv.fs_stat(dir) then
        error("extractit: não existe diretório.")
    end
    local it = vim.system({
        'tar', '-xf', arquivo, '-C', dir
    }, function ()
		if removefile then
			vim.fs.rm(arquivo)
		end
    end)
    if not async then
        vim.schedule(function() it:wait() end)
    end
end

-- download e extração de arquivos
local downloadit = function (dir, link, addpath, config)
	addpath = addpath ~= nil and addpath or false
    local arquivo = vim.fs.basename(link)
    vim.net.request(
        link, {
            outpath = vim.fs.joinpath( dir, arquivo ),
        },
        -- extrair arquivo
        function(err, _)
            if err then
                vim.print(('Erro ao realizar download de %s.\nErro: %s'):format(arquivo, err))
                return
            end
            if vim.uv.fs_stat(vim.fs.joinpath( dir, arquivo )) and (
                arquivo:match('zip$')
                or arquivo:match('tar%.[a-z]+$')
            ) then
                extractit(arquivo, dir, false, true)
            end
            if addpath then
                local dirs = findexecutables(dir)
                for _, d in ipairs(dirs) do
                    -- adicionar no $PATH e também no arquivo OPTFILE
                    vim.schedule(function()
                        add_path(d)
                        vim.fn.writefile({d}, M.OPTFILE, 'a')
                    end)
                end
            end
            if config then
                config()
            end
        end
    )
end

-- Check folders initialization
_ = (function()
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
    local optlist = findexecutables(opt)
    optlist = vim.tbl_map(function(programa)
        return vim.fs.dirname(vim.trim(programa))
    end, optlist)
    optlist = vim.list.unique(optlist)
    vim.fn.writefile(optlist, M.OPTFILE)
    vim.print('Arquivo OPTFILE criado com sucesso!')
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
M.init_path()

vim.api.nvim_create_user_command("UpdateOptfile",
    function()
        M.init_path(true)
    end, {}
)

-- Check git, install it
_ = (function()
    if executable('git.exe') then
        vim.print("Git já instalado!")
        return
    end
    local GITLINK = "https://github.com/git-for-windows/git/releases/download/v2.54.0.windows.1/MinGit-2.54.0-64-bit.zip"
    local GITDIR = vim.fs.joinpath(M.OPT, 'git')
    downloadit(GITDIR, GITLINK, true)
end)()

-- Check font, install it
_ = (function()
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
    }):wait().stdout
    SAUCEFONTES = vim.iter(vim.fn.split(SAUCEFONTES)):filter(function(fonte)
        return fonte:match('^C:.*ttf$')
    end):totable()
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
_ = (function()
    local copyq = '\\\\.\\pipe\\copyq'
    local ok, _ = pcall(vim.fn.serverstart, copyq)
    if not ok then
        vim.print("Server copyq já existe.")
    end
end)()

-- IMPORTANT(Windows 10+): Desabilitar python.exe e python3.exe em "Gerenciar
-- aliases de execução de aplicativo". Windows executa este alias antes de
-- executar python declarado em $PATH.
-- ALTERNATIVE FIX: Remover WindowsApps do $PATH
_ = (function()
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
_ = (function ()
    if not executable('git.exe') then
        vim.print('Não foi encontrado git! Verificar instalação de shhhhuuuhhh.')
        return
    end
    local SSHDIR = vim.fs.joinpath(vim.env.HOME, '.ssh')
    local shuuush = "Z2l0QGdpdGxhYi5jb206QW5kcmlraW4vc2h1dXVzaC5naXQ="
    if not vim.uv.fs_stat(SSHDIR) then
        vim.fn.mkdir(SSHDIR, 'p', '0755')
    end
    vim.cmd.cd(SSHDIR)
    vim.cmd['!']('git clone ' .. vim.base64.decode(shuuush) .. ' ' .. SSHDIR)
end)()

-- win-portable-neovim git init
_ = (function ()
    if not executable('git.exe') then
        vim.print('Não foi encontrado git! Verificar instalação de win-portable-neovim.')
        return
    end
    if not vim.uv.fs_stat(vim.fs.joinpath(vim.env.HOME, '.git')) then
        vim.cmd.cd(vim.env.HOME)
        vim.cmd['!']('git init')
        vim.cmd['!']('git remote add win git@github.com:Andrikin/win-portable-neovim')
        vim.cmd['!']('git fetch')
        vim.cmd['!']('git add .')
        vim.cmd['!']('git commit -m "dummy commit"')
        vim.cmd['!']('git checkout --track win/main')
        vim.cmd['!']('git branch -d master')
    else
        vim.print("Git: diretório '.git' já existe!")
        vim.system({'git', 'pull'}, {cwd = vim.env.HOME}, function (obj)
            if obj.stdout:match('^Updating') then
                vim.defer_fn(function ()
                    vim.cmd.restart()
                end, 5000)
                vim.print('win-portable-neovim: Atualizado! Preparando para reiniciar Neovim!')
            end
        end)
    end
end)()

-- Compilar arquivos latex
_ = (function ()
    local ouvidoria_latex = false
    if vim.pack._get_names then
        for plugin in ipairs(vim.pack._get_names()) do
            if plugin == 'ouvidoria-latex' then
                ouvidoria_latex = true
                break
            end
        end
    end
    if ouvidoria_latex then
        vim.api.nvim_create_user_command('CompilarOuvidoria',
            function()
                ---@diagnostic disable-next-line: missing-parameter
                require('ouvidoria-latex.latex'):compilar(nil, nil, true)
            end,
            {}
        )
    end
end)()

-- criar diretório em OPT, baixar programa e adicionar no $PATH
local function add_dependencia(dep)
	local dir = vim.fs.joinpath(M.OPT, dep.nome)
	if not vim.uv.fs_stat(dir) then
        vim.fn.mkdir(dir, 'p', '0755')
	end
	downloadit(dir, dep.link, true, dep.config)
end

-- Os programas dependências init
_ = (function ()
	for _, dep in ipairs(require('andrikin.deps')) do
		local dir = vim.fs.joinpath(M.OPT, dep.nome)
		if not executable(dep.nome) or not vim.uv.fs_stat(dir) then
			add_dependencia(dep)
		end
	end
	-- comando para adicionar mais 
	vim.api.nvim_create_user_command("DependenciaAdd",
		-- nome, link
		function(args)
            local dep = {
                nome = args.fargs[1],
                link = args.fargs[2],
            }
            if dep.nome == nil or dep.nome == '' then
                error('Não foi encontrado valor para a variável "nome"')
            end
            if dep.link == nil or dep.link == '' then
                error('Não foi encontrado valor para a variável "link"')
            end
			add_dependencia(dep)
		end, { nargs = '+' }
	)
end)()

-- iniciar sessão neovim em Desktop
vim.cmd.cd(vim.fs.joinpath(vim.env.USERPROFILE, '/Desktop'))

return M

