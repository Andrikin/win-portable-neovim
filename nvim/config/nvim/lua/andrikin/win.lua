-- TODO: como obter todos os executáveis em $PATH?
-- TODO: refac terminal_toggle map
local M = {}

-- verify directory exists, if not, create it
local function mkdir(dir)
    if not vim.uv.fs_stat(dir) then
        vim.fn.mkdir(dir, 'p', '0755')
    end
end

local function executable(exe)
	return vim.fn.executable(exe) == 1
end

local function findexecutables(dir, limit)
    limit = limit or math.huge
	return vim.fs.find(
		function(n, _)
			return (n:match('.*%.exe$')
				or n:match('.*%.bat$')
				or n:match('.*%.cmd$')
			)
		end,
		{limit = limit, type = 'file', path = dir}
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
    local search = dir:gsub(
        -- https://www.lua.org/pil/20.2.html -> 'magic characters'
        '[%(%)%.%+%*%?%[%^%$%%-]',
        function(m) return '%' .. m end
    )
    if not vim.env.PATH:match('(' .. search .. ')') then
        vim.env.PATH = vim.env.PATH .. ';' .. dir
    end
end

-- extração de arquivos
local extractit = function (file, dir, async, removefile, progresso)
	removefile = removefile ~= nil and removefile or false
    local arquivo = vim.fs.joinpath(dir, file)
    async = async or false
    if not vim.uv.fs_stat(dir) then
        error("extractit: não existe diretório.")
    end
    local it = vim.system({
        'tar', '-xf', arquivo, '-C', dir
    }, {}, function (out)
        if out.code > 0 then
            vim.print(
                ('Erro ao realizar extração de %s.\nErro: %s'):format(
                    arquivo, out.stderr
            ))
            return
        end
        if progresso then
            progresso.percent = 75
            vim.api.nvim_echo(
                {{('%s extraído!'):format(vim.fs.basename(dir))}},
                true, progresso
            )
        end
		if removefile then
			vim.fs.rm(arquivo)
		end
    end)
    if not async then
        vim.schedule(function() it:wait() end)
    end
end

-- download e extração de arquivos
local downloadit = function (dir, link, addpath, config, progresso)
    local nomedir = vim.fs.basename(dir)
    if progresso then
        progresso.percent = 25
        vim.api.nvim_echo({{('baixando %s'):format(nomedir)}}, true, progresso)
    end
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
            if progresso then
                progresso.percent = 50
                vim.api.nvim_echo({{('%s baixado!'):format(nomedir)}}, true, progresso)
            end
            if vim.uv.fs_stat(vim.fs.joinpath(dir, arquivo)) and (
                arquivo:match('zip$')
                or arquivo:match('tar%.[a-z]+$')
            ) then
                if progresso then
                    extractit(arquivo, dir, false, true, progresso)
                else
                    extractit(arquivo, dir, false, true)
                end
            end
            -- WIP: refazer para simplificar, se possível
            if addpath then
                vim.schedule(function ()
                    -- backup PATH
                    local path = vim.env.PATH
                    vim.env.PATH = vim.fn.join(findexecutables(dir), ';')
                    local exe = vim.fs.basename(dir)
                    local programa = vim.fs.dirname(vim.fn.exepath(exe))
                    -- update PATH
                    vim.env.PATH = path
                    if programa ~= "" and programa ~= '.' then
                        vim.fn.writefile({programa}, M.OPTFILE, 'a')
                        add_path(programa)
                        if progresso then
                            progresso.percent = 100
                            progresso.status = 'success'
                            vim.api.nvim_echo(
                                {{('%s adicionado ao PATH!'):format(nomedir)}},
                                true, progresso
                            )
                        end
                    end
                end)
            end
            if config then
                vim.schedule(config)
            end
            if progresso and progresso.percent < 100 then
                progresso.percent = 100
                progresso.status = 'success'
                vim.api.nvim_echo(
                    {{('concluído instalação: %s!'):format(nomedir)}},
                    true, progresso
                )
            end
        end
    )
end

-- Check folders initialization
_ = (function()
    mkdir(M.OPT)
    local PROJETOS = vim.fs.joinpath(vim.fs.dirname(vim.env.HOME), 'projetos')
    mkdir(PROJETOS)
    add_path(M.OPT)
end)()

-- HACK: melhorar para obter todos os executáveis
local check_opts = function ()
    -- must have in $PATH
    local deps = {
        "C:/Windows",
        "C:/Windows/System32",
        "C:/Windows/System32/WindowsPowerShell/v1.0",
        "C:/Windows/System32/OpenSSH",
        -- HACK: forçar reconhecimento de git
        vim.fs.joinpath(M.OPT, 'git', 'cmd')
    }
    local opts = require('andrikin.deps')
    for _, o in ipairs(opts) do
        local exe = vim.fn.exepath(o.nome)
        local programa = ""
        if exe ~= "." and exe ~= "" then
            programa = vim.fs.dirname(exe)
        end
        if programa ~= "" then
            table.insert(deps, programa)
        end
    end
    vim.env.PATH = vim.fn.join(deps, ';')
    vim.fn.writefile(deps, M.OPTFILE)
end

local create_optfile = function()
    -- ponto crítico, de mais demora na primeira execução
    -- local optlist = vim.fn.glob((opts .. '/*/**/*.{exe,bat,cmd}'),
    -- 	false, true, false
    -- )
    local optlist = findexecutables(M.OPT)
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
    local progresso = {
      kind = 'progress',
      percent = 0,
      source = 'andrikin',
      status = 'running',
      title = 'optfile',
    }
    progresso.id = vim.api.nvim_echo({{'iniciando...'}}, true, progresso)
    for p, o in ipairs(opts) do
        add_path(o)
        progresso.percent = math.floor(p/#opts*100)
        if o:match('[wW]indows') then
            vim.api.nvim_echo({{('%s: concluído...'):format(
                vim.fs.basename(o)
            )}}, true, progresso)
        else
            vim.api.nvim_echo({{('%s: concluído...'):format(
                o:match('opt/([^/]*)')
            )}}, true, progresso)
        end
        if p == #opts then
            progresso.status = 'success'
            vim.api.nvim_echo({{'inicialização concluída!'}}, true, progresso)
        end
    end
    if force then
        check_opts()
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
    local progresso = {
      kind = 'progress',
      percent = 0,
      source = 'andrikin',
      status = 'running',
      title = 'git-install',
    }
    progresso.id = vim.api.nvim_echo({{'instalando: git'}}, true, progresso)
    downloadit(GITDIR, GITLINK, true, nil, progresso)
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
    ---@diagnostic disable-next-line: cast-local-type, param-type-mismatch
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
    local progresso = {
      kind = 'progress',
      percent = 0,
      source = 'andrikin',
      status = 'running',
      title = 'font-saucecodepro',
    }
    progresso.id = vim.api.nvim_echo({{'instalando: saucecodepro'}}, true, progresso)
    downloadit(SAUCEDIR, SAUCELINK, nil, nil, progresso)
    ---@diagnostic disable-next-line: cast-local-type
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

-- Copyq integration
-- https://copyq.readthedocs.io/en/latest/known-issues.html
-- On Windows, CopyQ does not print anything on console Use Action dialog in
-- CopyQ (F5 shortcut) and set "Store standard output" to "text/plain" to save
-- the output as new item in current tab. selecionar qual tab - default
-- 'clipboard'
_ = (function()
    if not executable('copyq') then
        vim.print('Não foi encontrado "copyq". Por gentileza, realize a instalação.')
        return
    end
    vim.api.nvim_create_user_command('Clipboard',
        function(args)
            local tab = args.fargs[1] or 'clipboard'
            local clipboard = vim.system({"copyq","eval","--",([[
                let indent = 4;
                let tamanho = size() <= 50 && size() || 50;
                tab('%s');
                let c = [];
                for(i=0;i<tamanho;i++) c.push(str(read(i)));
                print(JSON.stringify(c, null, indent));
            ]]):format(tab)}):wait().stdout
            -- transformar JSON
            clipboard = vim.json.decode(clipboard)
            local temp = {}
            local index = 1
            for i, _ in ipairs(clipboard) do -- remover strings vazias
                if clipboard[i] ~= "" then
                    temp[index] = clipboard[i]
                    index = index + 1
                end
            end
            ---@diagnostic disable-next-line: cast-local-type
            clipboard = temp
            vim.ui.select(clipboard, {
                prompt = 'Selecione uma entrado do clipboard:',
                format_item = function(item)
                    if #item <= 75 then
                        return item
                    end
                    return item:sub(1, 75)
                end,
            }, function(choice)
                    if choice then
                        vim.fn.setreg('"', choice)
                        vim.cmd.normal('P')
                    end
                end
            )
        end,
        {
            nargs = "?",
            complete = function(arg, _, _)
                local lista = vim.system({"copyq", "eval", "--", [[
                    let indent = 4;
                    let tabs = tab();
                    print(JSON.stringify(tabs, null, indent));
                ]]}):wait().stdout
                local ok = nil
                ok, lista = pcall(vim.json.decode, lista)
                if not ok then
                    return {}
                end
                return vim.tbl_filter(function(copyqtab)
                    return copyqtab:lower():match(arg:gsub('-', '.'):lower())
                end, lista)
            end,
        }
    )
end
)()

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
    mkdir(SSHDIR)
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
        local cmd = vim.cmd['!']
        vim.cmd.cd(vim.env.HOME)
        cmd('git init')
        cmd('git remote add win git@github.com:Andrikin/win-portable-neovim')
        cmd('git fetch')
        cmd('git add .')
        cmd('git commit -m "dummy commit"')
        cmd('git checkout --track win/main')
        cmd('git branch -d master')
    else
        vim.print("win-portable-neovim: já instalado.")
        vim.system({'git', 'pull'}, {cwd = vim.env.HOME}, function (obj)
            if obj.stdout:match('^Updating') then
                vim.defer_fn(function ()
                    vim.cmd.restart()
                end, 5000)
                vim.print('win-portable-neovim: Atualizado! Preparando para reiniciar Neovim!')
            elseif obj.stdout:match("^Already up to date") then
                vim.print('win-portable-neovim: não há atualizações para realizar.')
            end
        end)
    end
end)()

-- Install Cygwin dependencies
_ = (function ()
    if vim.fn.exists(':Cygwin') then
        if not executable('gs.exe') then
            vim.cmd.Cygwin('install ghostscript')
        end
        if not executable('gcc.exe') then
            vim.cmd.Cygwin(
                'install gcc mingw64-x86_64-gcc mingw64-x86_64-gcc-core mingw64-x86_64-gcc-g++'
            )
        end
    end
end)()

-- nvim-treesitter compilation
_ = (function ()
    if executable('gcc.exe') then
        vim.env.CC = vim.fs.normalize(vim.fn.exepath('gcc.exe'))
    else
        vim.env.CC = vim.fs.normalize(vim.fn.exepath('x86_64-pc-cygwin-gcc.exe'))
    end
end)()

-- Python config
_ = (function ()
    if not executable('uv') then
        return
    end
    local DIR = vim.fs.joinpath(
        M.OPT, 'python'
    )
    local UV = vim.fs.joinpath(DIR, 'uv')
    local UVCACHE = vim.fs.joinpath(UV, 'cache')
    mkdir(DIR)
    mkdir(UV)
    mkdir(UVCACHE)
    if not executable('python') and not executable('python3.14') then
        vim.system(
            {'uv', 'python', 'install', '--default', '3.14'},
            {detach = true}
        ):wait()
    end
    vim.env.UV_PYTHON_INSTALL_DIR = UV
    vim.env.UV_TOOL_DIR = vim.fs.joinpath(vim.env.HOME, 'nvim', 'bin')
    vim.env.UV_CACHE_DIR = UVCACHE
    vim.system({ 'uv', 'python', 'install' }):wait()
    local packages = vim.system({
        'uv', 'tool', 'list'
    }):wait().stdout
    if packages then
        for _, d in ipairs({
            -- python dependências
            'pyright',
            'basedpyright',
            'pynvim',
        }) do
            if not packages:match('([%W]' .. d .. '[%W])') then
                vim.system({ 'uv', 'tool', 'install', d }, {detach = true})
            end
        end
    end
    vim.g.python3_host_prog = vim.fs.normalize(vim.fn.exepath('python3'))
    if not vim.g.python3_host_prog or vim.g.python3_host_prog == '' then
        vim.print('Variável python3_host_prog não configurado.')
    end
end)()

-- criar diretório em OPT, baixar programa e adicionar no $PATH
local function add_dependencia(dep)
	local dir = vim.fs.joinpath(M.OPT, dep.nome)
    local progresso = {
      kind = 'progress',
      percent = 0,
      source = 'andrikin',
      status = 'running',
      title = 'add_dependencia',
    }
    progresso.id = vim.api.nvim_echo({{('instalando: %s'):format(dep.nome)}}, true, progresso)
    mkdir(dir)
	downloadit(dir, dep.link, true, dep.config, progresso)
end
-- Os programas dependências init
_ = (function ()
	for _, dep in ipairs(require('andrikin.deps')) do
		local dir = vim.fs.joinpath(M.OPT, dep.nome)
		if not executable(dep.nome) or not vim.uv.fs_stat(dir) then
			add_dependencia(dep)
        else
            if dep.config then
                vim.schedule(dep.config)
            end
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

