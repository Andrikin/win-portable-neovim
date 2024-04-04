-- TODO: Verificar se bootstrap do Curl/SauceCodePro deve ser modificado para 
-- ficar em conforme com vim.loop.spawn

---@class Utils
---@field Diretorio Diretorio
---@field SauceCodePro SauceCodePro
---@field Registrador Registrador
---@field Curl Curl
---@field OPT Diretorio
---@field win7 string | nil
local Utils = {}

local Processo = {}

---@type table<uv_process_t, true>
Processo.running = {}

Processo.signals = {
    "HUP",
    "INT",
    "QUIT",
    "ILL",
    "TRAP",
    "ABRT",
    "BUS",
    "FPE",
    "KILL",
    "USR1",
    "SEGV",
    "USR2",
    "PIPE",
    "ALRM",
    "TERM",
    "CHLD",
    "CONT",
    "STOP",
    "TSTP",
    "TTIN",
    "TTOU",
    "URG",
    "XCPU",
    "XFSZ",
    "VTALRM",
    "PROF",
    "WINCH",
    "IO",
    "PWR",
    "EMT",
    "SYS",
    "INFO",
}

---@class ProcessOpts
---@field args string[]
---@field cwd? string
---@field on_line? fun(string)
---@field on_exit? fun(ok:boolean, output:string)
---@field timeout? number
---@field env? table<string,string>

---@param opts? ProcessOpts
---@param cmd string
function Processo.spawn(cmd, opts)
    opts = opts or {}
    opts.timeout = opts.timeout or (120 * 1000) -- finalizar processo que tenham passado de 2 minutos
    ---@type table<string, string>
    local env = vim.tbl_extend("force", {
        GIT_SSH_COMMAND = "ssh -oBatchMode=yes",
    }, vim.loop.os_environ(), opts.env or {})
    env.GIT_DIR = nil
    env.GIT_WORK_TREE = nil
    env.GIT_TERMINAL_PROMPT = "0"
    env.GIT_INDEX_FILE = nil
    ---@type string[]
    local env_flat = {}
    for k, v in pairs(env) do
        env_flat[#env_flat + 1] = k .. "=" .. v
    end
    local stdout = assert(vim.loop.new_pipe())
    local stderr = assert(vim.loop.new_pipe())
    local output = ""
    ---@type uv_process_t?
    local handle = nil
    ---@type uv_timer_t
    local timeout
    local killed = false
    if opts.timeout then
        timeout = assert(vim.loop.new_timer())
        timeout:start(opts.timeout, 0, function()
            if Processo.kill(handle) then
                killed = true
            end
        end)
    end
    -- make sure the cwd is valid
    if not opts.cwd and type(vim.loop.cwd()) ~= "string" then
        opts.cwd = vim.loop.os_homedir()
    end
    handle = vim.loop.spawn(cmd, {
        stdio = { nil, stdout, stderr },
        args = opts.args,
        cwd = opts.cwd,
        env = env_flat,
    }, function(exit_code, signal)
            ---@cast handle uv_process_t
            Processo.running[handle] = nil
            if timeout then
                timeout:stop()
                timeout:close()
            end
            handle:close()
            stdout:close()
            stderr:close()
            local check = assert(vim.loop.new_check())
            check:start(function()
                if not stdout:is_closing() or not stderr:is_closing() then
                    return
                end
                check:stop()
                if opts.on_exit then
                    output = output:gsub("[^\r\n]+\r", "")
                    if killed then
                        output = output .. "\n" .. "Process was killed because it reached the timeout"
                    elseif signal ~= 0 then
                        output = output .. "\n" .. "Process was killed with SIG" .. Processo.signals[signal]
                    end
                    vim.schedule(function()
                        opts.on_exit(exit_code == 0 and signal == 0, output)
                    end)
                end
            end)
        end)
    if not handle then
        if opts.on_exit then
            opts.on_exit(false, "Failed to spawn process " .. cmd .. " " .. vim.inspect(opts))
        end
        return
    end
    Processo.running[handle] = true
    ---@param data? string
    local function on_output(err, data)
        assert(not err, err)
        if data then
            output = output .. data:gsub("\r\n", "\n")
            local lines = vim.split(vim.trim(output:gsub("\r$", "")):gsub("[^\n\r]+\r", ""), "\n")
            if opts.on_line then
                vim.schedule(function()
                    opts.on_line(lines[#lines])
                end)
            end
        end
    end
    vim.loop.read_start(stdout, on_output)
    vim.loop.read_start(stderr, on_output)
    return handle
end

function Processo.kill(handle)
    if handle and not handle:is_closing() then
        Processo.running[handle] = nil
        vim.loop.process_kill(handle, "sigint")
        return true
    end
end

function Processo.abort()
    for handle in pairs(Processo.running) do
        Processo.kill(handle)
    end
end

---@param cmd string[]
---@param opts? {cwd:string, env:table}
function Processo.exec(cmd, opts)
    opts = opts or {}
    ---@type string[]
    local lines
    local job = vim.fn.jobstart(cmd, {
        cwd = opts.cwd,
        pty = false,
        env = opts.env,
        stdout_buffered = true,
        on_stdout = function(_, _lines)
            lines = _lines
        end,
    })
    vim.fn.jobwait({ job })
    return lines
end

---@class Programa
---@field nome string
---@field link string
---@field cmd string | table
---@field arquivo string
---@field diretorio Diretorio
---@field executavel boolean
---@field extracao Diretorio
---@field baixado boolean
---@field config function
Utils.Programa = {
    __index = function(table, key)
        local atributo = rawget(table, key)
        if not atributo then
            local diretorio = Utils.OPT
            if key == 'arquivo' then -- nome do arquivo
                atributo = vim.fn.fnamemodify(table.link, ':t')
            elseif key == 'diretorio' then -- diretório para instalar o programa
                atributo = diretorio / table.nome
            elseif key == 'executavel' then -- arquivo baixado já é um executável .exe
                atributo = table.arquivo:match('%.([^_-.]+)$') == 'exe'
            elseif key == 'extracao' then -- diretório do arquivo do programa baixado pronto para extração
                atributo = diretorio / table.arquivo
            else
                if key == 'extraido' then -- arquivo extraído?
                    atributo = #vim.fn.glob(tostring(table.diretorio / '*'), false, true) ~= 0
                end
                if key == 'baixado' then -- arquivo baixado?
                    atributo = vim.fn.getftype(table.extracao.diretorio) ~= ''
                end
            end
        end
        return atributo
    end
}

---@class Diretorio
---@field diretorio string Caminho completo do diretório
local Diretorio = {}

Diretorio.__index = Diretorio

---@param caminho string | table
---@return Diretorio
Diretorio.new = function(caminho)
    vim.validate({caminho = {caminho, {'table', 'string'}}})
    if type(caminho) == 'table' then
        for _, valor in ipairs(caminho) do
            if type(valor) ~= 'string' then
                error('Diretorio: new: Elemento de lista diferente de "string"!')
            end
        end
    end
    local diretorio = setmetatable({
        diretorio = '',
    }, Diretorio)
    if type(caminho) == 'table' then
        local concatenar = caminho[1]
        for i=2, #caminho do
            concatenar = concatenar .. diretorio._suffix(caminho[i])
        end
        caminho = concatenar
    end
    diretorio.diretorio = diretorio._sanitize(caminho)
    return diretorio
end

---@private
---@param str string
---@return string
Diretorio._sanitize = function(str)
    local sanitarizado = ''
    vim.validate({ str = {str, 'string'} })
    sanitarizado = string.gsub(str, '/', '\\')
    return sanitarizado
end

---@private
---@param str string
---@return string
Diretorio._suffix = function(str)
    vim.validate({ str = {str, 'string'} })
    return (str:match('^[/\\]') or str == '') and str or '\\' .. str
end

---@param caminho string | table
Diretorio.add = function(self, caminho)
    if type(caminho) == 'table' then
        local concatenar = ''
        for _, c in ipairs(caminho) do
            concatenar = concatenar .. Diretorio._suffix(c)
        end
        caminho = concatenar
    end
    self.diretorio = self.diretorio .. Diretorio._suffix(caminho)
end

---@param other Diretorio | string
---@return Diretorio
Diretorio.__div = function(self, other)
    local nome = self.diretorio
    if getmetatable(other) == Diretorio then
        other = other.diretorio
    elseif type(other) ~= 'string' then
        error('Diretorio: __div: Elementos precisam ser do tipo "string".')
    end
    return Diretorio.new(Diretorio._sanitize(nome .. Diretorio._suffix(other)))
end

---@param str string
---@return string
Diretorio.__concat = function(self, str)
    if getmetatable(self) ~= Diretorio then
        error('Diretorio: __concat: Objeto não é do tipo Diretorio.')
    end
    if type(str) ~= 'string' then
        error('Diretorio: __concat: Argumento precisa ser do tipo "string".')
    end
    return Diretorio._sanitize(self.diretorio .. Diretorio._suffix(str))
end

---@return string
Diretorio.__tostring = function(self)
    return self.diretorio
end

Utils.Diretorio = Diretorio

---@type Diretorio
Utils.OPT = Utils.Diretorio.new(vim.env.NVIM_OPT)

--- Criar diretório 'opt' caso não exista
Utils.bootstrap = function(self)
    if vim.fn.isdirectory(self.OPT.diretorio) then
        vim.fn.mkdir(self.OPT.diretorio, 'p', 0700)
    end
end

---@class Curl
---@field unzip_link string Url para download de unzip.exe
local Curl = {}

Curl.__index = Curl

Curl.new = function()
    if vim.fn.executable('curl') == 0 then -- verificar se curl está instalado no sistema
        error([[
        curl: instalado: Não foi encontrado curl no sistema. Verificar e realizar a instalação do curl neste computador!
        Link para download: https://curl.se/windows/latest.cgi?p=win64-mingw.zip
        ]])
    end
    local curl = setmetatable({
        unzip_link = 'http://linorg.usp.br/CTAN/systems/win32/w32tex/unzip.exe'
    }, Curl)
    curl:bootstrap()
    return curl
end

-- FATO: Windows 10 build 17063 or later is bundled with tar.exe which is capable of working with ZIP files 
---@private
Curl.bootstrap = function(self)
    -- Realizar o download da ferramenta unzip
    if Utils.win7 and vim.fn.executable('tar') == 0 then
        Utils.notify('Curl: bootstrap: Sistema não possui tar.exe!')
    end
    if vim.fn.executable('unzip') == 1 then
        Utils.notify('Curl: bootstrap: Sistema já possui Unzip.')
        do return end
    end
    self.download(self.unzip_link, Utils.OPT.diretorio)
    local unzip = vim.fs.find('unzip.exe', {path = Utils.OPT.diretorio, type = 'file'})[1]
    if vim.v.shell_error > 0 then
        error('Curl: bootstrap: Não foi possível realizar o download do unzip.exe')
    elseif unzip == '' then
        error('Curl: bootstrap: Não foi possível encontrar o executável unzip.exe.')
    end
end

---@param link string
---@param diretorio string
---@return uv_process_t download Processo executado async
Curl.download = function(link, diretorio)
    local download
    vim.validate({
        link = {link, 'string'},
        diretorio = {diretorio, 'string'}
    })
    if link == '' or diretorio == '' then
        error('Curl: download: Variável nula')
    end
    local arquivo = vim.fn.fnamemodify(link, ':t')
    diretorio = tostring(Utils.Diretorio.new(diretorio) / arquivo)
    download = Processo.spawn('curl',{
        args = {
            '--fail',
            '--location',
            '--silent',
            '--output',
            diretorio,
            link
        }
    })
    return download
end

---@param arquivo string
---@param diretorio string
---@return uv_process_t extracao Processo executado async
Curl.extrair = function(arquivo, diretorio)
    vim.validate({
        arquivo = {arquivo, 'string'},
        diretorio = {diretorio, 'string'}
    })
    if arquivo == '' or diretorio == '' then
        error('Curl: extrair: Variável nula.')
    end
    local nome = arquivo:match('[/\\]([^/\\]+)$') or arquivo
    local extencao = arquivo:match('%.(tar)%.[a-z.]*$') or arquivo:match('%.([a-z]*)$')
    local extracao
    if extencao == 'zip' then
        extracao = Processo.spawn('unzip', {
            args = {
                arquivo,
                '-d',
                diretorio
            }
        })
    elseif extencao == 'tar' then
        extracao = Processo.spawn('tar', {
            args = {
                '-xf',
                arquivo,
                '-C',
                diretorio
            }
        })
    end
    return extracao
end

Utils.Curl = Curl

---@class Registrador
---@field diretorio Diretorio Onde as dependências ficaram instaladas
---@field deps table Configurações do Registrador
local Registrador = {}

Registrador.__index = Registrador

---@return Registrador
Registrador.new = function()
    local registrador = setmetatable({
        diretorio = Utils.OPT,
    }, Registrador)
    registrador:bootstrap()
    return registrador
end

---@return string
Registrador.__tostring = function(self)
    return self.diretorio.diretorio
end

---@private
Registrador.bootstrap = function(self)
    -- Criar diretório, setar configurações, etc
    if vim.fn.isdirectory(tostring(self)) == 0 then
        vim.fn.mkdir(tostring(self), 'p', 0700)
    end
    if not vim.env.PATH:match(tostring(self):gsub('[\\/-]', '.')) then
        vim.env.PATH = vim.env.PATH .. ';' .. tostring(self)
    end
end

---@param programas table | Programa Lista dos programas que são dependência para o nvim
Registrador.iniciar = function(self, programas)
    for i, programa in ipairs(programas) do
        if getmetatable(programa) ~= Utils.Programa then
            programas[i] = setmetatable(programa, Utils.Programa)
        end
    end
    local timer, baixados, extracoes, downloads, extraidos
    baixados = {}
    extracoes = {}
    downloads = {}
    extraidos = {}
    ::reiniciar::
    timer = vim.loop.new_timer()
    for i, programa in ipairs(programas) do
        local registrado = self.registrar(programa)
        if registrado then
            programas[i] = nil
            goto continuar
        end
        if not baixados[programa] and not Processo.running[downloads[programa]] then
            baixados[programa] = true
            if vim.fn.isdirectory(programa.diretorio.diretorio) == 0 then
                vim.fn.mkdir(programa.diretorio.diretorio, 'p', 0700)
            end
            downloads[programa] = Utils.Curl.download(programa.link, programa.diretorio.diretorio)
            goto continuar
        end
        if baixados[programa] and not Processo.running[downloads[programa]] and not extracoes[programa] and not Processo.running[extraidos[programa]] then
            extracoes[programa] = true
            extraidos[programa] = Utils.Curl.extrair(programa.extracao.diretorio, programa.diretorio.diretorio)
            goto continuar
        end
        if baixados[programa] and extracoes[programa] and not Processo.running[downloads[programa]] and not Processo.running[extraidos[programa]] then
            if programa.executavel then
                vim.fn.rename(programa.extracao.diretorio, (programa.diretorio / programa.arquivo).diretorio) -- mover arquivo para a pasta dele
            else
                vim.fn.delete(programa.extracao.diretorio) -- remover arquivo programa baixado
            end
        end
        ::continuar::
    end
    timer:start(1000, 1000, function()
        if not next(Processo.running) then
            timer:close()
        end
    end)
    if next(programas) then
        goto reiniciar
    end
end

--- Verifica se o programa já está no PATH, busca pelo executável e 
--- realiza o registro no PATH do sistema
---@param programa Programa
---@return boolean
Registrador.registrar = function(programa)
    local registrado = vim.env.PATH:match(programa.diretorio.diretorio:gsub('[\\-]', '.'))
    if registrado then
        Utils.notify(string.format('Opt: registrar_path: Programa %s já registrado no sistema!', programa.nome))
        return true
    end
    local limite
    if type(programa.cmd) == 'table' then
        limite = #programa.cmd
    else
        limite = 1
    end
    local executaveis = vim.fs.find(programa.cmd, {path = programa.diretorio.diretorio, type = 'file', limit = limite})
    local sem_executavel = vim.tbl_isempty(executaveis)
    if not registrado and sem_executavel then
        Utils.notify(string.format('Opt: registrar_path: Baixar programa %s e registrar no sistema.', programa.nome))
        return false
    end
    -- simplesmente adicionar ao PATH
    for _, exe in ipairs(executaveis) do
        vim.env.PATH = vim.env.PATH .. ';' .. vim.fn.fnamemodify(exe, ':h')
    end
    Utils.notify(string.format('Opt: registrar_path: Programa %s registrado no PATH do sistema.', programa.nome))
    if programa.config then -- caso tenha configuração, executá-la
        Utils.notify(string.format('Opt: registrar_path: Configurando programa %s.', programa.nome))
        programa.config()
    end
    return true
end

---@param programas table
Registrador.setup = function(self, programas)
    self:iniciar(programas)
end

Utils.Registrador = Registrador

-- Instalação da fonte SauceCodePro no computador
---@class SauceCodePro
---@field diretorio Diretorio Onde a fonte será instalada
---@field link string Url para download da fonte
---@field arquivo Diretorio Nome do arquivo
---@field registro Diretorio Caminho aonde será instalado a fonte no regedit do sistema
---@field fontes table Lista de fontes encontradas no sistema
local SauceCodePro = {}

SauceCodePro.__index = SauceCodePro

SauceCodePro.registro = Utils.Diretorio.new('HKCU') / 'Software' / 'Microsoft' / 'Windows NT' / 'CurrentVersion' / 'Fonts'

SauceCodePro.diretorio = Utils.OPT / 'fonte'

SauceCodePro.link = 'https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/SourceCodePro.zip'

SauceCodePro.arquivo = SauceCodePro.diretorio / vim.fn.fnamemodify(SauceCodePro.link, ':t')

---@return SauceCodePro
SauceCodePro.new = function()
    local fonte = setmetatable({}, SauceCodePro)
    fonte:bootstrap()
    return fonte
end

---@return string
SauceCodePro.__tostring = function(self)
    return self.diretorio.diretorio
end

---@private
SauceCodePro.bootstrap = function(self)
    if vim.fn.isdirectory(tostring(self)) == 0 then
        vim.fn.mkdir(tostring(self), 'p', 0700)
    end
    vim.api.nvim_create_user_command(
        'FonteRemover',
        function()
            self:remover_regedit()
        end,
        {}
    )
end

SauceCodePro.setup = function(self)
    if not self:instalado() then
        self:instalar()
    else
        Utils.notify('Fonte SauceCodePro já instalada.')
    end
end

SauceCodePro.listar_arquivos = function(self)
    return vim.fn.glob(tostring(self.diretorio / 'SauceCodePro*.ttf'), false, true)
end

---@return boolean
SauceCodePro.fonte_extraida = function(self)
    return #(self:listar_arquivos()) > 0
end

SauceCodePro.download = function(self)
    if vim.fn.isdirectory(tostring(self)) == 0 then
        vim.fn.mkdir(tostring(self), 'p', 0700)
    end
    -- Realizar download da fonte
    Utils.Curl.download(self.link, tostring(self))
    if not self:zip_baixado() then
        error('Fonte: download: Não foi possível realizar o download do arquivo da fonte.')
    end
    Utils.notify('Arquivo fonte .zip baixado!')
end

---Decompressar arquivo zip
SauceCodePro.extrair_zip = function(self)
    Utils.Curl.extrair(self.arquivo.diretorio, tostring(self))
    Utils.notify('Arquivo fonte SauceCodePro.zip extraído!')
    -- remover arquivo .zip
    if vim.fn.getftype(self.arquivo.diretorio) == 'file' then
        vim.fn.delete(self.arquivo.diretorio)
    end
end

---Verificando se a fonte está intalada no computador
---@private
---@return boolean
SauceCodePro.instalado = function(self)
    return #self:query_fontes_regedit() > 0
end

---@private
---@return table
SauceCodePro.query_fontes_regedit = function(self)
    local comando = vim.fn.systemlist({
        'reg',
        'query',
        self.registro.diretorio,
        '/s'
    })
    if comando == '' then
        return {}
    end
    local query = vim.tbl_filter(
        function(entrada)
            return entrada:match('SauceCodePro')
        end,
        comando
    )
    local fontes = vim.tbl_filter(
        function(fonte)
            return fonte:match('(.:.*%.ttf)')
        end,
        query
    )
    return fontes
end

---Registra as fontes no regedit do sistema Windows.
SauceCodePro.regedit = function(self)
    for _, fonte in ipairs(self.fontes) do
        local nome = vim.fn.fnamemodify(fonte, ':t')
        vim.fn.system({
            'reg',
            'add',
            self.registro.diretorio,
            '/v',
            nome:match('(.*)%..*$'),
            '/t',
            'REG_SZ',
            '/d',
            tostring(self.diretorio / nome),
            '/f'
        })
    end
end

--- Verifica se existe o arquivo SourceCodePro
---@return boolean
SauceCodePro.zip_baixado = function(self)
    return vim.fn.getftype(self.arquivo.diretorio) ~= ''
end

--- Desinstala a fonte no regedit do sistema Windows.
SauceCodePro.remover_regedit = function(self)
    for _, fonte in ipairs(self:query_fontes_regedit()) do
        local nome = vim.fn.fnamemodify(fonte, ':t'):match('(.*)%..*$')
        if nome then
            vim.fn.system({
                'reg',
                'delete',
                self.registro.diretorio,
                '/v',
                nome,
                '/f'
            })
        end
    end
end

--- Instala a fonte no sistema Windows.
SauceCodePro.instalar = function(self)
    if not self:fonte_extraida() then
        if not self:zip_baixado() then
            self:download()
        end
        self:extrair_zip()
    end
    self.fontes = self:listar_arquivos()
    self:regedit()
    if self:instalado() then
        Utils.notify('Fonte instalada com sucesso. Reinicie o nvim para carregar a fonte.')
        vim.cmd.quit({bang = true})
    else
        Utils.notify('Erro encontrado. Verificar se é possível executar comandos no regedit.')
    end
end

Utils.SauceCodePro = SauceCodePro

--- Mostra notificação para usuário, registrando em :messages
---@param msg string
Utils.notify = function(msg)
    vim.api.nvim_echo({{msg, 'DiagnosticInfo'}}, true, {})
    vim.cmd.redraw({bang = true})
end

--- Mostra uma notificação para o usuário, mas sem registrar em :messages
---@param msg string
Utils.echo = function(msg)
    vim.api.nvim_echo({{msg, 'DiagnosticInfo'}}, false, {})
    vim.cmd.redraw({bang = true})
end

--- Remove programa da variável PATH do sistema
---@param programa string
Utils.remover_path = function (programa)
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

Utils.npcall = vim.F.npcall

---@type string | nil
Utils.win7 = string.match(vim.loop.os_uname()['version'], 'Windows 7')

Utils.cursorline = {
    toggle = function(cursorlineopt)
        cursorlineopt = cursorlineopt or {'number', 'line'}
        vim.opt.cursorlineopt = cursorlineopt
        vim.o.cursorline = not vim.o.cursorline
    end,
    on = function(cursorlineopt)
        cursorlineopt = cursorlineopt or {'number', 'line'}
        vim.opt.cursorlineopt = cursorlineopt
        vim.o.cursorline = true
    end,
    off = function()
        vim.o.cursorline = false
    end

}

return Utils

