-- NEOVIM --

-- TODO: how build neovim/zig: !zig build install --prefix ./zig-out/ -Doptimize=ReleaseFast
-- TODO: cygwin gcc don't work for compile parsers in treesitter...

local novo_alerta = function(titulo)
    local progresso = {
        kind = 'progress',
        source = 'andrikin',
        status = 'running',
        title = titulo,
    }
    local headless = #vim.api.nvim_list_uis() == 0
    return vim.schedule_wrap(function(status, percentual, msg)
        progresso.status = status == 'fim' and 'success' or 'running'
        progresso.percent = percentual
        progresso.id = vim.api.nvim_echo({ { msg } }, true, progresso)
        if not headless then
            vim.cmd.redraw({ bang = true })
        end
    end)
end

-- verify directory exists, if not, create it
local function mkdir(dir)
    if not vim.uv.fs_stat(dir) then
        vim.fs.mkdir(dir, { parents = true })
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
        { limit = limit, type = 'file', path = dir }
    )
end

-- IMPORTANT(Windows 10+): Desabilitar python.exe e python3.exe em "Gerenciar
-- aliases de execução de aplicativo". Windows executa este alias antes de
-- executar python declarado em $PATH.
-- ALTERNATIVE FIX: Remover WindowsApps do $PATH
do
    local windowsapps = { 'WindowsApps', 'Oracle', 'LibreOffice' }
    local paths = vim.iter(vim.split(vim.env.PATH, ';')):filter(function(apps)
        for _, wapp in ipairs(windowsapps) do
            if apps:match(wapp) then
                return false -- remover
            end
        end
        return true
    end):totable()
    vim.env.PATH = vim.fn.join(paths, ';')
end

vim.env.MYVIMDIR = vim.fs.joinpath(
    vim.env.HOME, 'nvim'
)

OPTFILE = vim.fs.joinpath(
    vim.env.MYVIMDIR,
    'opt', 'optfile'
)
-- Editar arquivo 'optfile'
vim.api.nvim_create_user_command("Optfile",
    function()
        vim.cmd.edit(OPTFILE)
    end, {}
)

local OPT = ''
if not vim.env.NVIMOPT then
    OPT = vim.fs.joinpath(
        vim.env.HOME,
        'nvim', 'opt'
    )
else
    OPT = vim.env.NVIMOPT
end
if OPT == '' then
    vim.print('OPT: variável não inicializada!')
end

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

local search_paths_to_add = vim.schedule_wrap(function(dir)
    local exelist = findexecutables(dir)
    exelist = vim.tbl_map(function(programa)
        return vim.fs.dirname(programa)
    end, exelist)
    local finallist = vim.tbl_filter(function(diretorio)
        local d = dir:gsub('-', '%%-')
        return diretorio:match('/[sb]in$')
            -- apenas um diretório de profundidade
            or diretorio:match(d .. '/[^/]*$')
            -- ou o próprio diretório do programa
            or diretorio:match(d .. '$')
    end, exelist)
    finallist = vim.list.unique(finallist)
    if #finallist == 0 then
        finallist = vim.list.unique(exelist)
    end
    vim.fn.writefile(finallist, OPTFILE, 'a')
    -- update PATH
    for _, p in ipairs(finallist) do
        add_path(p)
    end
end)

-- extração de arquivos
local extractit = function(file, dir, addpath, progresso)
    addpath = addpath or false
    local arquivo = vim.fs.joinpath(dir, file)
    local alerta = progresso or novo_alerta(file)
    if not vim.uv.fs_stat(dir) then
        error("extractit: não existe diretório.")
    end
    vim.system({
        'tar', '-xf', arquivo, '-C', dir
    }, {}, function(out)
        if out.code > 0 then
            vim.print((
                'Erro ao realizar extração de %s.\nErro: %s'):format(
                arquivo, out.stderr
            ))
            return
        end
        alerta('extraindo', 75, 'extraído!')
        if vim.uv.fs_stat(arquivo) then
            vim.fs.rm(arquivo)
        end
        if addpath then
            search_paths_to_add(dir)
            alerta('registrando', 95, 'adicionado ao PATH!')
        end
        alerta('fim', 100, 'concluído instalação!')
    end)
end

-- download e extração de arquivos
local downloadit = function(dir, link, addpath, config, progresso)
    local nome = vim.fs.basename(dir)
    local arquivo = vim.fs.basename(link)
    local alerta = progresso or novo_alerta(nome)
    alerta('reportando', 25, 'baixando...')
    addpath = addpath or false
    vim.net.request(
        link, {
            outpath = vim.fs.joinpath(dir, arquivo),
        },
        -- extrair arquivo
        function(err, _)
            if err then
                vim.print(('Erro ao realizar download de %s.\nErro: %s'):format(arquivo, err))
                return
            end
            alerta('reportando', 50, 'baixado!')
            if vim.uv.fs_stat(vim.fs.joinpath(dir, arquivo)) and (
                    arquivo:match('zip$')
                    or arquivo:match('7z$')
                    or arquivo:match('tar%.[a-z]+$')
                ) then
                extractit(arquivo, dir, addpath, alerta)
            else
                alerta('fim', 100, 'concluído instalação!')
            end
            if config then
                vim.schedule(config)
                alerta('fim', 100, 'concluído instalação!')
            end
        end
    )
end

-- Check folders initialization
do
    mkdir(OPT)
    local PROJETOS = vim.fs.joinpath(vim.fs.dirname(vim.env.HOME), 'projetos')
    mkdir(PROJETOS)
    add_path(OPT)
end

-- HACK: melhorar para obter todos os executáveis
local check_opts = function()
    -- must have in $PATH
    local deps = {
        "C:/Windows",
        "C:/Windows/System32",
        "C:/Windows/System32/WindowsPowerShell/v1.0",
        "C:/Windows/System32/OpenSSH",
        -- HACK: forçar reconhecimento de git
        vim.fs.joinpath(OPT, 'git', 'cmd')
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
    vim.fn.writefile(deps, OPTFILE)
end

local create_optfile = function()
    local criado = false
    for programa, tipo, err in vim.fs.dir(OPT, { err = true }) do
        if err then
            vim.print('optfile: Erro encontrado ' .. err)
        end
        if tipo == "directory" then
            search_paths_to_add(vim.fs.joinpath(OPT, programa))
            criado = criado == true or true
        end
    end
    if criado then
        vim.print('optfile: arquivo OPTFILE criado com sucesso!')
    else
        vim.print('optfile: erro ocorrido, criando arquivo OPTFILE vazio.')
        vim.fn.writefile({}, OPTFILE)
    end
end

-- inicializar variavéis do ambiente $PATH
local init_path = function(force)
    force = force or false
    local alerta = novo_alerta('optfile')
    local optfile_criado = false
    if not vim.uv.fs_stat(OPTFILE) or force then
        create_optfile()
        optfile_criado = true
    end
    if not optfile_criado then
        local opts = vim.fn.readfile(OPTFILE)
        alerta('inicialização', 0, 'iniciando dependências...')
        for p, o in ipairs(opts) do
            add_path(o)
            local percentual = math.floor(p / #opts * 100)
            local msg = ('%s: concluído...'):format(o:match('opt/([^/]*)'))
            alerta('inicialização', percentual, msg)
        end
        alerta('fim', 100, 'inicialização concluída!')
    end
    if force then
        check_opts()
    end
    -- https://github.com/neovim/neovim/blob/master/src/nvim/os/env.c#L1152
    if #vim.env.PATH > 8199 then
        vim.print('init_path: Limite de caracteres do $PATH alcançado!')
    end
end
init_path()

vim.api.nvim_create_user_command("UpdateOptfile",
    function()
        init_path(true)
    end, {}
)

-- Check git, install it
if not executable('git.exe') then
    local GITLINK = "https://github.com/git-for-windows/git/releases/download/v2.54.0.windows.1/MinGit-2.54.0-64-bit.zip"
    local GITDIR = vim.fs.joinpath(OPT, 'git')
    local alerta = novo_alerta('git-install')
    alerta('instalação', 0, 'iniciando instalação git.')
    downloadit(GITDIR, GITLINK, true, nil, alerta)
else
    vim.print("Git já instalado!")
end

-- Check font, install it
do
    local SAUCEREGCMD = vim.fs.joinpath(
        'HKCU', 'Software', 'Microsoft',
        'Windows NT', 'CurrentVersion', 'Fonts'
    ):gsub('/', '\\')
    local SAUCEDIR = vim.fs.joinpath(
        OPT, 'fontes', 'saucecodepro'
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
            vim.system({
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
                        vim.system({
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
    else
        -- realizar download e instalar
        if not vim.uv.fs_stat(SAUCEDIR) then
            mkdir(SAUCEDIR)
        else
            vim.fs.rm(SAUCEDIR, { recursive = true })
            mkdir(SAUCEDIR)
        end
        -- download
        local alerta = novo_alerta('saucecodepro-install')
        alerta('instalação', 0, 'iniciando instalação SauceCodePro.')
        downloadit(SAUCEDIR, SAUCELINK, nil, nil, alerta)
        ---@diagnostic disable-next-line: cast-local-type
        SAUCEFONTES = listarfontes()
        instalar(SAUCEFONTES)
        vim.print('Fonte SauceCodePro instalada. Reiniciar para obter a fonte.')
    end
end

-- Copyq integration
-- https://copyq.readthedocs.io/en/latest/known-issues.html
-- On Windows, CopyQ does not print anything on console Use Action dialog in
-- CopyQ (F5 shortcut) and set "Store standard output" to "text/plain" to save
-- the output as new item in current tab. selecionar qual tab - default
-- 'clipboard'
if executable('copyq') then
    vim.api.nvim_create_user_command('Clipboard',
        function(args)
            local tab = args.fargs[1] or 'clipboard'
            local clipboard = vim.system({ "copyq", "eval", "--", ([[
                let indent = 4;
                let tamanho = size() <= 50 && size() || 50;
                tab('%s');
                let c = [];
                for(i=0;i<tamanho;i++) c.push(str(read(i)));
                print(JSON.stringify(c, null, indent));
            ]]):format(tab) }):wait().stdout
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
                local lista = vim.system({ "copyq", "eval", "--", [[
                    let indent = 4;
                    let tabs = tab();
                    print(JSON.stringify(tabs, null, indent));
                ]] }):wait().stdout
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
else
    vim.print('Não foi encontrado "copyq". Realize a instalação ou adicione no PATH.')
    local COPYQDIR = vim.fs.joinpath(vim.env.HOMEDRIVE, vim.env.HOMEPATH, 'Documents', 'copyq')
    if vim.uv.fs_stat(COPYQDIR) then
        add_path(COPYQDIR)
    end
end

-- SSH --
-- TODO: ativar conexão ssh-add, caso não esteja conectada
if executable('git.exe') then
    local SSHDIR = vim.fs.joinpath(vim.env.HOME, '.ssh')
    local shuuush = "aHR0cHM6Ly9naXRsYWIuY29tL0FuZHJpa2luL3NodXV1c2guZ2l0"
    if not vim.uv.fs_stat(SSHDIR) then
        mkdir(SSHDIR)
        vim.system({ 'git', 'clone', vim.base64.decode(shuuush), SSHDIR })
    else
        vim.print('ssh: diretório já existe.')
    end
else
    vim.print('Não foi encontrado git! Verificar instalação de shhhhuuuhhh.')
end

-- win-portable-neovim git init
if executable('git.exe') then
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
        vim.system({ 'git', 'pull' }, { cwd = vim.env.HOME }, function(obj)
            if obj.stdout:match('^Updating') then
                vim.defer_fn(function()
                    vim.cmd.restart()
                end, 5000)
                vim.print('win-portable-neovim: Atualizado! Preparando para reiniciar Neovim!')
            elseif obj.stdout:match("^Already up to date") then
                vim.print('win-portable-neovim: não há atualizações para realizar.')
            end
        end)
    end
else
    vim.print('Não foi encontrado git! Verificar instalação de win-portable-neovim.')
end

-- NODE --
if executable('node.exe') and executable('npm') then
    -- configurações extras
    local win7 = vim.uv.os_uname()['version']:match('Windows 7')
    if win7 and vim.env.NODE_SKIP_PLATFORM_CHECK ~= 1 then
        vim.env.NODE_SKIP_PLATFORM_CHECK = 1
    end
    --
    local NODEQUERY = vim.json.decode(vim.system({
            'npm', 'ls', '-g', '--depth=0', '--json'
        }):wait().stdout)
    local NODEDIR = vim.fs.joinpath(OPT, 'node')
    local installed = function(pacote)
        local check = NODEQUERY.dependencies[pacote]
        if check then
            return true
        end
        -- remove directory to install again, if exists
        local dir = vim.fs.find(pacote, { path = NODEDIR, type = 'directory' })
        local has_dir = not vim.tbl_isempty(dir)
        if has_dir then
            local d = dir[1]
            if d and vim.uv.fs_stat(d) then
                vim.fs.rm(d, { recursive = true })
            end
        end
        return false
    end
    -- NODE DEPENDENCIES
    local plugins = {
        'neovim',
        'emmet-ls',
        'vim-language-server',
        'vscode-langservers-extracted',
    }
    for _, plugin in ipairs(plugins) do
        if not installed(plugin) then
            vim.print(('Instalando pacote node: %s'):format(plugin))
            vim.system({
                'npm',
                'install',
                '-g',
                plugin
            }, { detach = true })
        else
            vim.print(('Pacote [%s] node já instalado.'):format(plugin))
        end
    end
    if not vim.g.node_host_prog or vim.g.node_host_prog == '' then
        local node_neovim = vim.fs.find(function(n, p)
                return n:match('bin') and p:match('neovim$')
            end,
            { path = NODEDIR, limit = math.huge, type = 'directory' })
        if node_neovim[1] then
            ---@diagnostic disable-next-line: cast-local-type
            node_neovim = node_neovim[1]
            if vim.uv.fs_stat(node_neovim) then
                -- https://github.com/neovim/neovim/issues/15308
                vim.g.node_host_prog = vim.fs.joinpath(node_neovim, 'cli.js')
            end
        else
            vim.print('Não foi possível configurar vim.g.node_host_prog')
        end
    end
end

-- CIGWIN --
do
    local DIR = vim.fs.joinpath(OPT,
        vim.fs.basename('https://cygwin.com/setup-x86_64.exe'):match('^(.-)%..*$')
    )
    local PACKAGES = vim.fs.joinpath(DIR, 'packages')
    local SETUP = vim.fs.joinpath(DIR, 'setup-x86_64.exe')
    if not vim.uv.fs_stat(SETUP) then
        error('Não foi localizado cygwin. Verificar instalação!')
    end
    local CMD = {
        SETUP,
        '--quiet-mode',
        '--no-admin',
        '--download',
        '--local-install',
        '--local-package-dir',
        PACKAGES,
        '--no-verify',
        '--no-desktop',
        '--no-shortcuts',
        '--no-startmenu',
        '--no-version-check',
        '--no-warn-deprecated-windows',
        '--root',
        DIR,
        '--only-site',
        '--site',
        'https://linorg.usp.br/cygwin/',
    }
    if not vim.uv.fs_stat(vim.fs.joinpath(DIR, 'bin')) then
        -- inicializar instalação do cygwin
        vim.system(CMD, { detach = true })
    end
    -- create Cygwin command
    vim.api.nvim_create_user_command("Cygwin",
        function(opts)
            opts = opts or {}
            local args = opts.fargs or opts
            if not vim.islist(args) then
                vim.print('Valores padrão encontrados no comando. Abortando.')
                return
            end
            local cmd = vim.deepcopy(CMD)
            if args[1] == 'install' or args[1] == 'remove' then
                if args[1] == 'install' then
                    table.insert(cmd, '--packages')
                elseif args[1] == 'remove' then
                    table.insert(cmd, '--remove-packages')
                end
                for i = 2, #args do
                    table.insert(cmd, args[i])
                end
            end
            if args[1] == 'update' then
                table.insert(cmd, '--upgrade-also')
            end
            vim.system(cmd, { text = true, detach = true }, function(out)
                if out.code == 0 then
                    local programas = table.concat(args, '; ', 2, #args)
                    vim.print(('Instalação concluída com sucesso!: %s'):format(programas))
                else
                    vim.print('Instalador cygwin encontrou um erro.')
                end
            end)
        end, {
            nargs = '+',
            complete = function(arg, _, _)
                return vim.tbl_filter(function(c)
                    return c:match(arg)
                end, { 'install', 'remove', 'upgrade' })
            end
        }
    )
end

-- CYGWIN DEPENDENCIES --
if executable('setup-x86_64.exe') then
    if vim.fn.exists(':Cygwin') then
        if not executable('gs.exe') then
            vim.cmd.Cygwin({ args = { 'install', 'ghostscript' } })
        end
        if not executable('gcc.exe') then
            vim.cmd.Cygwin({
                args = {
                    'install',
                    'gcc-core',
                    'gcc-g++',
                    'mingw64-x86_64-gcc-core',
                    'mingw64-x86_64-gcc-g++'
                }
            })
        end
        -- for Neovim build
        if not executable('cmake.exe') then
            vim.cmd.Cygwin({ args = { 'install', 'cmake' } })
        end
        if not executable('gettext.exe') then
            vim.cmd.Cygwin({ args = { 'install', 'gettext' } })
        end
        if not executable('ninja.exe') then
            vim.cmd.Cygwin({ args = {'install', 'ninja'}})
        end
        if not executable('magick.exe') then -- convert jpeg/png to pdf 
            vim.cmd.Cygwin({ args = {'install', 'ImageMagick'}})
        end
    end
end

-- PYTHON --
if executable('uv') then
    local DIR = vim.fs.joinpath(
        OPT, 'python'
    )
    local UV = vim.fs.joinpath(DIR, 'uv')
    local UVCACHE = vim.fs.joinpath(UV, 'cache')
    mkdir(DIR)
    mkdir(UV)
    mkdir(UVCACHE)
    vim.env.UV_PYTHON_INSTALL_DIR = UV
    vim.env.UV_TOOL_BIN_DIR = UV
    vim.env.UV_TOOL_DIR = UV
    vim.env.UV_CACHE_DIR = UVCACHE
    if not executable('python') and not executable('python3.14') then
        vim.system(
            {'uv', 'python', 'install', '--default', '3.14'},
            {detach = true}
        ):wait()
    end
    -- Erro no comando se existir o diretório '.temp'
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
                -- uv pip install --system --break-system-packages neovim
                if d == 'pynvim' then
                    vim.system(
                        { 'uv', 'pip', 'install',
                            '--system', '--break-system-packages',
                            'neovim'
                        },
                        {detach = true}
                    )
                end
            end
        end
    end
    vim.g.python3_host_prog = vim.fs.normalize(vim.fn.exepath('python3'))
    if not vim.g.python3_host_prog or vim.g.python3_host_prog == '' then
        vim.print('Variável python3_host_prog não configurado.')
    end
end
-- criar diretório em OPT, baixar programa e adicionar no $PATH
local function add_dependencia(dep)
    local dir = vim.fs.joinpath(OPT, dep.nome)
    mkdir(dir)
    downloadit(dir, dep.link, true, dep.config)
end
-- Os programas dependências init
do
    for _, dep in ipairs(require('andrikin.deps')) do
        local dir = vim.fs.joinpath(OPT, dep.nome)
        if (not executable(dep.nome)) or (not vim.uv.fs_stat(dir)) then
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
end

-- remove duplicates in $PATH
do
    local paths = vim.split(vim.env.PATH, ';')
    paths = vim.list.unique(paths)
    vim.env.PATH = vim.fn.join(paths, ';')
end

-- iniciar sessão neovim em Desktop
vim.cmd.cd(vim.fs.joinpath(vim.env.USERPROFILE, '/Desktop'))
