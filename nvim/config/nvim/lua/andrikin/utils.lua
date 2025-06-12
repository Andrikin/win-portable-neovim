-- TODO: 
-- resolver node cli.js path,

---@class Utils
---@field Diretorio Diretorio
---@field SauceCodePro SauceCodePro
---@field Registrador Registrador
---@field Programa Programa
---@field Projetos Diretorio
---@field Ssh Ssh
---@field Git Git
---@field Ouvidoria Ouvidoria
---@field Opt Diretorio
---@field win7 string | nil
---@field notify nil
---@field echo nil
---@field remover_path nil
---@field npcall nil
---@field cursorline table
---@field autocmd function
---@field Andrikin number
---@field init function
local Utils = {}

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
---@diagnostic disable-next-line: undefined-field
Utils.win7 = string.match(vim.uv.os_uname()['version'], 'Windows 7')

---@type table
Utils.cursorline = {
    toggle = function(cursorlineopt)
        cursorlineopt = cursorlineopt or {'number', 'line'}
        vim.opt.cursorlineopt = cursorlineopt
        vim.wo.cursorline = not vim.wo.cursorline
    end,
    on = function(cursorlineopt)
        cursorlineopt = cursorlineopt or {'number', 'line'}
        vim.opt.cursorlineopt = cursorlineopt
        vim.wo.cursorline = true
    end,
    off = function()
        vim.wo.cursorline = false
    end
}

-- Recarregar configuração depois de atualizar o repositório git
Utils.reload = function()
    for name,_ in pairs(package.loaded) do
        if name:match('^andrikin') then
            package.loaded[name] = nil
        end
    end
    require('andrikin')
end

Utils.Andrikin = vim.api.nvim_create_augroup('Andrikin', {clear = true})

Utils.renomear_executavel = function(programa)
    local nome = programa.nome
    local diretorio = Utils.Opt / nome
    local antigo = vim.fn.glob(tostring(diretorio / ('%s*.exe'):format(nome)))
    local novo = tostring(diretorio / ('%s.exe'):format(nome))
    if antigo ~= '' then
        if vim.fn.filereadable(novo) == 1 then
            Utils.notify(('Arquivo %s já renomeado.'):format(nome))
            do return end
        end
        Utils.notify(('Renomeando executável %s.'):format(nome))
        vim.fn.rename(antigo, novo)
    else
        Utils.notify(('Não foi encontrado executável %s.'):format(nome))
    end
end

--- Wrap envolta do vim.fn.jobstart
---@class Job
---@field clear_env boolean
---@diagnostic disable-next-line: duplicate-doc-field
---@field cwd string
---@field detach boolean
---@diagnostic disable-next-line: duplicate-doc-field
---@field env table
---@field height number
---@diagnostic disable-next-line: duplicate-doc-field
---@field on_exit function
---@diagnostic disable-next-line: duplicate-doc-field
---@field on_stdout function
---@diagnostic disable-next-line: duplicate-doc-field
---@field on_stderr function
---@diagnostic disable-next-line: duplicate-doc-field
---@field overlapped boolean
---@field pty boolean
---@field rpc boolean
---@field stderr_buffered boolean
---@field stdout_buffered boolean
---@field stdin string
---@field width number
---@field new Job
---@field id number
---@field ids table
---@field start function
---@field wait function
---@field running function
local Job = {}

Job.__index = Job

---@param opts table
---@return Job
---@diagnostic disable-next-line: assign-type-mismatch
Job.new = function(opts)
    local job = {}
    opts = opts or {}
    if not vim.tbl_isempty(opts) then
        for k, v in pairs(opts) do
            job[k] = v
        end
    end
    job.env = {
        NVIM = vim.env.NVIM,
        NVIM_LISTEN_ADDRESS = vim.env.NVIM_LISTEN_ADDRESS,
        NVIM_LOG_FILE = vim.env.NVIM_LOG_FILE,
        VIM = vim.env.VIM,
        VIMRUNTIME = vim.env.VIMRUNTIME,
        PATH = vim.env.PATH,
        NVIM_OPT = vim.env.NVIM_OPT,
    }
    job.id = 0 -- last created job
    job.ids = {} -- list of ids jobs
    job = setmetatable(job, Job)
    return job
end

---@param cmd table
---@return Job
Job.start = function(self, cmd)
    local id = vim.fn.jobstart(cmd, self)
	self.id = id
    table.insert(self.ids, id)
    return self
end

--- Espera a execução do último job
Job.wait = function(self)
    if self.id == 0 then
        error('Job: argumentos inválidos', 2)
    elseif self.id == -1 then
        error('Job: comando não executável', 2)
    end
    vim.fn.jobwait({self.id})
end

Job.wait_all = function(self)
	local status_job = {}
	if not vim.tbl_isempty(self.ids) then
		status_job = vim.fn.jobwait(self.ids)
	end
	return status_job
end

---@return boolean
Job.running = function(self)
    return vim.fn.jobwait({self.id}, 0)[1] == -1
end

Utils.Job = Job

---@class Programa
---@field nome string
---@field link string
---@field cmd string | table
---@field config function
---@field baixado boolean
---@field extraido boolean
---@field processo thread
---@field concluido boolean
---@field job Job
local Programa = {}

Programa.__index = Programa

---@type boolean
Programa.baixado = false

---@type boolean
Programa.extraido = false

---@type boolean
Programa.concluido = false

---@type Job
Programa.job = Utils.Job.new()

---@param self Programa
---@return string
Programa.__tostring = function(self)
    return self:diretorio().diretorio
end

---@return Diretorio diretorio
Programa.diretorio = function(self)
    return Utils.Opt / self.nome
end

---@return string nome
Programa.nome_arquivo = function(self)
	return vim.fn.fnamemodify(self.link, ':t')
end

---@return string ext
---@param self Programa
Programa.extencao = function(self)
	local ext = vim.fn.fnamemodify(self.link, ':e')
	if ext == '' then
		error('Programa: extencao: Não foi encontrado extenção para o arquivo.')
	end
	return ext
end

--- Verifica se programa é um executável .exe
---@return boolean executavel
Programa.executavel = function(self)
    return self:extencao() == 'exe'
end

-- FIX: verificar se arquivo baixado existe, antes 
-- de extraí-lo
Programa.baixar = function(self)
	local diretorio = tostring(self:diretorio())
    self.job.on_exit = function()
        self.baixado = true
        Utils.notify(('Programa %s baixado!'):format(self.nome))
        self:extrair()
        self.job.on_exit = nil
    end
	self.job:start({
		'curl',
		'--fail',
		'--location',
		'--silent',
        '--output-dir',
		diretorio,
        '-O',
		self.link
	})
end

-- TODO: refazer lógica de extração
-- ideia: continuar extração até não haver mais
-- arquivos compactados.
Programa.extrair = function(self)
     -- arquivo extraído já é um executável
    if self:extencao() == 'exe' then
        if not self:registrar() then
            Utils.notify(('Não foi possível realizar a instalação do programa %s.'):format(self.nome))
            do return end
        else
            if self.config then
                self.config()
            end
        end
        do return end
    end
    local diretorio = tostring(self:diretorio())
    local arquivo = tostring(self:diretorio() / self:nome_arquivo())
    local cmd = {
        '7za',
        'x',
        arquivo,
        '-o' .. diretorio,
    }
    -- se tar.gz, extrair duas vezes
    local tar_gz = vim.fn.fnamemodify(self.link, ':e:e') == 'tar.gz' or vim.fn.fnamemodify(self.link, ':e') == 'tgz'
    if tar_gz then
        -- https://superuser.com/questions/80019/how-can-i-unzip-a-tar-gz-in-one-step-using-7-zip
        cmd = {
            '7za',
            'x',
            arquivo,
            '-so',
            '|',
            '7za',
            'x',
            '-aoa',
            '-si',
            '-ttar',
            '-o' .. diretorio,
        }
    end
    self.job.on_exit = function()
        self.extraido = true
        Utils.notify(('Programa %s extraído!'):format(self.nome))
        if vim.fn.filereadable(arquivo) ~= 0 then -- arquivo existe
            vim.fn.delete(arquivo) -- remover arquivo baixado
        end
        if not self:registrar() then
            Utils.notify(('Não foi possível realizar a instalação do programa %s.'):format(self.nome))
            do return end
        else
            if self.config then
                self.config()
            end
        end
        self.job.on_exit = nil
        self.concluido = true
    end
    self.job:start(cmd)
end

--- Verifica se o programa já está no PATH, busca pelo executável e 
--- realiza o registro na variável PATH do sistema
---@return boolean
Programa.registrar = function(self)
    local registrado = vim.env.PATH:match(self:diretorio().diretorio:gsub('[\\-]', '.'))
    if registrado then
        Utils.notify(('Programa: registrar_path: Programa %s já registrado no sistema!'):format(self.nome))
        return true
    end
    local limite = 1
    if type(self.cmd) == 'table' then
        limite = #self.cmd
    end
    local executaveis = vim.fs.find(self.cmd, {path = self:diretorio().diretorio, type = 'file', limit = limite})
    local sem_executavel = vim.tbl_isempty(executaveis)
    if not registrado and sem_executavel then
        return false
    end
    -- simplesmente adicionar diretório dos executáveis ao PATH
    for _, exe in ipairs(executaveis) do
        vim.env.PATH = vim.env.PATH .. ';' .. vim.fn.fnamemodify(exe, ':h')
    end
    Utils.notify(('Programa: registrar_path: Programa %s registrado no PATH do sistema.'):format(self.nome))
    return true
end

--- Verifica se programa já está baixado ou se já encontra-se
--- extraído
Programa.checar_instalacao = function(self)
    if vim.fn.getftype(tostring(self:diretorio() / self:nome_arquivo())) ~= '' then
        self.baixado = true
    end
    if #vim.fn.glob(tostring(self:diretorio() / '*'), false, true) > 1 and self.baixado then
        self.extraido = true
    end
end

-- TODO: verificar quando utilizar esta método
Programa.resetar = function(self)
    local concluido = nil
    local diretorio = self:diretorio().diretorio
    if vim.fn.isdirectory(diretorio) == 1 then
        concluido = vim.fn.delete(diretorio) == 0
    end
    if not concluido then
        error(('Programa: %s não foi possível resetar diretório'):format(self.nome))
    end
end

Programa.criar_diretorio = function(self)
    if vim.fn.isdirectory(self:diretorio().diretorio) then
        vim.fn.mkdir(self:diretorio().diretorio, 'p', '0755')
    end
end

--- Instalação do programa.
--- Realiza duas tentativas de inclusão no PATH, baixando e extraindo programa
--- na primeira falha. Na segunda, retorna mensagem de erro.
Programa.instalar = function(self)
    if self:registrar() then
		if self.config then
			self.config()
		end
        self.concluido = true
        do return end
    end
    self:criar_diretorio()
    self:baixar()
end

Utils.Programa = Programa

---@class Diretorio
---@field diretorio string Caminho completo do diretório
---@field add function
local Diretorio = {}

Diretorio.__index = Diretorio

---@param caminho string | table
---@return Diretorio
Diretorio.new = function(caminho)
    caminho = caminho or ''
    vim.validate({caminho = {caminho, {'table', 'string'}}})
    if type(caminho) == 'table' then
        for _, valor in ipairs(caminho) do
            if type(valor) ~= 'string' then
                error('Diretorio: new: Elemento de lista diferente de "string"!')
            end
        end
        caminho = table.concat(caminho, '/')
    end
    local diretorio = setmetatable({
        diretorio = Diretorio._sanitize(caminho),
    }, Diretorio)
    return diretorio
end

---@private
---@param str string
---@return string
---@return _
Diretorio._sanitize = function(str)
    vim.validate({ str = {str, 'string'} })
    return vim.fs.normalize(str):gsub('//+', '/')
end

---@param dir Diretorio | string
---@return boolean
Diretorio.validate = function(dir)
    local isdirectory = function(d)
        return vim.fn.isdirectory(d) == 1
    end
    local valido = false
    if type(dir) == 'Diretorio' then
        valido = isdirectory(dir.diretorio)
    elseif type(dir) == 'string' then
        valido = isdirectory((Diretorio.new(dir)).diretorio)
    else
        error('Diretorio: validate: variável não é do tipo "Diretorio" ou "string"')
    end
    return valido
end

---@return Diretorio
--- Realiza busca nas duas direções pelo 
Diretorio.buscar = function(dir, start)
    vim.validate({ dir = {dir,{'table', 'string'}} })
    vim.validate({ start = {start, 'string'} })
    if type(dir) == 'table' then
        dir = vim.fs.normalize(table.concat(dir, '/'))
    else
        dir = vim.fs.normalize(dir)
    end
    if dir:match('^' .. vim.env.HOMEDRIVE) then
        error('Diretorio: buscar: argumento deve ser um trecho de diretório, não deve conter "C:/" no seu início.')
    end
    start = start and Diretorio._sanitize(start) or Diretorio._sanitize(vim.env.HOMEPATH)
    local diretorio = ''
    local diretorios = vim.fs.dir(start, {depth = math.huge})
    for d, t in diretorios do
        if not t == 'directory' then
            goto continue
        end
        if d:match('.*' .. dir:gsub('-', '.')) then
            diretorio = d
            break
        end
        ::continue::
    end
    if diretorio == '' then
        error('Diretorio: buscar: não foi encontrado o caminho do diretório informado.')
    end
    diretorio = vim.fs.normalize(start .. '/' .. diretorio):gsub('//+', '/')
    return Diretorio.new(diretorio)-- valores de vim.fs.dir já são normalizados
end

---@private
---@param str string
---@return string
Diretorio._suffix = function(str)
    vim.validate({ str = {str, 'string'} })
    return (str:match('^[/\\]') or str == '') and str or vim.fs.normalize('/' .. str)
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
Utils.Opt = Diretorio.new(vim.env.NVIM_OPT)

--- Criar diretório 'opt' caso não exista
Utils.init = function()
    local projetos = (Diretorio.new(vim.fn.fnamemodify(vim.env.HOME, ':h')) / 'projetos').diretorio
    if vim.fn.isdirectory(projetos) == 0 then
        vim.fn.mkdir(projetos, 'p', '0755')
    end
    if vim.fn.isdirectory(Utils.Opt.diretorio) == 0 then
        vim.fn.mkdir(Utils.Opt.diretorio, 'p', '0755')
    end
    vim.env.PATH = vim.env.PATH .. ';' .. Utils.Opt.diretorio
    -- extrator padrão 7zip Packing / unpacking: 7z, XZ, BZIP2, GZIP, TAR, ZIP and WIM
    local diretorio = (Utils.Opt / '7zip')
    if vim.fn.isdirectory(tostring(diretorio)) == 0 then
        vim.fn.mkdir(tostring(diretorio), 'p', '0755')
    end
    vim.env.PATH = vim.env.PATH .. ';' .. tostring(Utils.Opt / '7zip')
    local link_7zr = 'https://7-zip.org/a/7zr.exe'
    local link_7za = 'https://7-zip.org/a/7z2409-extra.7z'
    local has_7zip = vim.fn.executable('7zr.exe') == 1 and vim.fn.executable('7za.exe') == 1
    local job = Utils.Job.new()
    if not has_7zip then
		job:start({
            'curl',
            '--fail',
            '--location',
            '--silent',
            '--output-dir',
            tostring(diretorio),
            '-O',
            link_7zr,
        })
        job.on_exit = function()
            job.on_exit = nil
            job:start({
                '7zr.exe',
                'x',
                tostring(diretorio / vim.fn.fnamemodify(link_7za, ':t')),
                '-o' .. tostring(diretorio),
            }):wait()
        end
		job:start({
            'curl',
            '--fail',
            '--location',
            '--silent',
            '--output-dir',
            tostring(diretorio),
            '-O',
            link_7za,
        })
        job:wait_all()
    end
    -- adicionar 7za.exe no PATH
    vim.env.PATH = vim.env.PATH .. ';' .. tostring(Utils.Opt / '7zip' / 'x64')
end

---@class Registrador
---@field diretorio Diretorio Onde as dependências ficaram instaladas
local Registrador = {}

Registrador.__index = Registrador

Registrador.running = {}

---@return Registrador
Registrador.new = function()
    local registrador = setmetatable({
        diretorio = Utils.Opt,
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
        vim.fn.mkdir(tostring(self), 'p', '0755')
    end
    if not vim.env.PATH:match(tostring(self):gsub('[\\/-]', '.')) then
        vim.env.PATH = vim.env.PATH .. ';' .. tostring(self)
    end
end

---@param programas table Lista dos programas que são dependência para o nvim
Registrador.iniciar = function(programas)
    for i, programa in ipairs(programas) do
        if getmetatable(programa) ~= Programa then
            programas[i] = setmetatable(programa, Programa)
        end
        programas[i]:instalar()
    end
end

Utils.Registrador = Registrador

-- Instalação da fonte SauceCodePro no computador
---@class SauceCodePro
---@field diretorio Diretorio Onde a fonte será instalada
---@field link string Url para download da fonte
---@field arquivo Diretorio Nome do arquivo
---@field registro Diretorio Caminho aonde será instalado a fonte no regedit do sistema
---@field fontes table Lista de fontes encontradas no sistema
---@field job Job
local SauceCodePro = {}

SauceCodePro.__index = SauceCodePro

SauceCodePro.registro = Diretorio.new('HKCU') / 'Software' / 'Microsoft' / 'Windows NT' / 'CurrentVersion' / 'Fonts'

SauceCodePro.diretorio = Utils.Opt / 'fonte'

SauceCodePro.link = 'https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/SourceCodePro.zip'

SauceCodePro.arquivo = SauceCodePro.diretorio / vim.fn.fnamemodify(SauceCodePro.link, ':t')

SauceCodePro.job = Utils.Job.new()

---@return SauceCodePro
SauceCodePro.new = function()
    local fonte = setmetatable({}, SauceCodePro)
    fonte:bootstrap()
    fonte:setup()
    return fonte
end

---@return string
SauceCodePro.__tostring = function(self)
    return tostring(self.diretorio)
end

---@private
SauceCodePro.bootstrap = function(self)
    if vim.fn.isdirectory(tostring(self)) == 0 then
        vim.fn.mkdir(tostring(self), 'p', '0755')
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
        vim.fn.mkdir(tostring(self), 'p', '0755')
    end
    -- Realizar download da fonte
	local diretorio = tostring(Diretorio.new(tostring(self)) / vim.fn.fnamemodify(self.link, ':t'))
    self.job.on_exit = function()
        if not self:zip_baixado() then
            error('Fonte: download: Não foi possível realizar o download do arquivo da fonte.')
        end
        Utils.notify('Arquivo fonte .zip baixado!')
    end
    self.job:start({
        'curl',
        '--fail',
        '--location',
        '--silent',
        '--output-dir',
        diretorio,
        '-O',
        self.link,
    })
end

---Decompressar arquivo zip
SauceCodePro.extrair_zip = function(self)
    self.job.on_exit = function()
        Utils.notify('Arquivo fonte SauceCodePro.zip extraído!')
        -- remover arquivo .zip
        if vim.fn.getftype(self.arquivo.diretorio) == 'file' then
            vim.fn.delete(self.arquivo.diretorio)
        end
    end
    self.job:start({
        '7za',
        'x',
        self.arquivo.diretorio,
        '-o' .. tostring(self),
    })
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
        tostring(self.registro):gsub('/', '\\'),
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
            tostring(self.registro):gsub('/', '\\'),
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
    return vim.fn.getftype(tostring(self.arquivo)) ~= ''
end

--- Desinstala a fonte no regedit do sistema Windows.
SauceCodePro.remover_regedit = function(self)
    for _, fonte in ipairs(self:query_fontes_regedit()) do
        local nome = vim.fn.fnamemodify(fonte, ':t'):match('(.*)%..*$')
        if nome then
            vim.fn.system({
                'reg',
                'delete',
                tostring(self.registro):gsub('/', '\\'),
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

---WARNING: classe para instalar as credenciais .ssh
---TODO: como resolver esta questão de proteção
---@class Ssh
---@field destino Diretorio
---@field arquivos table
local Ssh = {}

Ssh.__index = Ssh

---@type Diretorio
Ssh.destino = Diretorio.new(vim.env.HOME) / '.ssh'

---@type table
Ssh.arquivos = {
    {
        nome = 'id_ed25519',
        valor = "LS0tLS1CRUdJTiBPUEVOU1NIIFBSSVZBVEUgS0VZLS0tLS0KYjNCbGJuTnphQzFyWlhrdGRqRUFBQUFBQkc1dmJtVUFBQUFFYm05dVpRQUFBQUFBQUFBQkFBQUFNd0FBQUF0emMyZ3RaVwpReU5UVXhPUUFBQUNCTTBXQTZXdWFsYzg0QkF0YTF2bHFFM2JDMHBrM3hkNzUxSm9HV01OcmFCUUFBQUtqdkYzZ2E3eGQ0CkdnQUFBQXR6YzJndFpXUXlOVFV4T1FBQUFDQk0wV0E2V3VhbGM4NEJBdGExdmxxRTNiQzBwazN4ZDc1MUpvR1dNTnJhQlEKQUFBRUFZVEtmSzBEZUFzOWFKbkdqMVRCaWhUMnV3MXQrTlZ2SzdrU3hQdEFHNTRFelJZRHBhNXFWenpnRUMxclcrV29UZApzTFNtVGZGM3ZuVW1nWll3MnRvRkFBQUFJV052Ym5SaGMyVmpjbVYwWVdGc2RHVnlibUYwYVhaaFFHZHRZV2xzTG1OdmJRCkVDQXdRPQotLS0tLUVORCBPUEVOU1NIIFBSSVZBVEUgS0VZLS0tLS0K",
    },
    {
        nome = 'id_ed25519.pub',
        valor = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSUV6UllEcGE1cVZ6emdFQzFyVytXb1Rkc0xTbVRmRjN2blVtZ1pZdzJ0b0YgY29udGFzZWNyZXRhYWx0ZXJuYXRpdmFAZ21haWwuY29tCg==",
    },
    {
        nome = 'known_hosts',
        valor = "Z2l0aHViLmNvbSBzc2gtZWQyNTUxOSBBQUFBQzNOemFDMWxaREkxTlRFNUFBQUFJT01xcW5rVnpybTBTZEc2VU9vcUtMc2FiZ0g1Qzlva1dpMGRoMmw5R0tKbApnaXRodWIuY29tIHNzaC1yc2EgQUFBQUIzTnphQzF5YzJFQUFBQURBUUFCQUFBQmdRQ2o3bmROeFFvd2djUW5qc2hjTHJxUEVpaXBobnQrVlRUdkRQNm1IQkw5ajFhTlVrWTRVZTFndnduR0xWbE9oR2VZcm5aYU1nUks2K1BLQ1VYYURiQzdxdGJXOGdJa2hMN2FHQ3NPci9DNTZTSk15L0JDWmZ4ZDFuV3pBT3hTRFBnVnNtZXJPQllmTnFsdFY5L2hXQ3FCeXdJTklSKzVkSWc2SlRKNzJwY0VwRWpjWWdYa0UyWUVGWFYxSkhuc0tnYkxXTmxoU2NxYjJVbXlSa1F5eXRSTHRMKzM4VEd4a3hDZmxtTys1WjhDU1NOWTdHaWRqTUlaN1E0ek1qQTJuMW5HcmxURGt6d0RDc3crd3FGUEdRQTE3OWNuZkdXT1dSVnJ1ajE2ejZYeXZ4dmpKd2J6MHdRWjc1WEs1dEtTYjdGTnllSUVzNFRUNGprK1M0ZGhQZUFVQzV5K2JEWWlyWWdNNEdDN3VFbnp0blp5YVZXUTdCMzgxQUs0UWRyd3Q1MVpxRXhLYlFwVFVObitFanFvVHd2cU5qNGtxeDVRVUNJMFRoUy9Za094SkNYbVBVV1piaGpwQ2c1NmkrMmFCNkNtSzJKR2huNTdLNW1qME1OZEJYQTQvV253SDZYb1BXSnpLNU55dTJ6QjNuQVpwK1M1aHBRcytwMXZOMS93c2prPQpnaXRodWIuY29tIGVjZHNhLXNoYTItbmlzdHAyNTYgQUFBQUUyVmpaSE5oTFhOb1lUSXRibWx6ZEhBeU5UWUFBQUFJYm1semRIQXlOVFlBQUFCQkJFbUtTRU5qUUVlek9teGtaTXk3b3BLZ3dGQjlua3Q1WVJyWU1qTnVHNU44N3VSZ2c2Q0xyYm81d0FkVC95NnYwbUtWMFUydzBXWjJZQi8rK1Rwb2NrZz0K",
    },
    {
        nome = 'known_hosts.old',
        valor = "Z2l0aHViLmNvbSBzc2gtZWQyNTUxOSBBQUFBQzNOemFDMWxaREkxTlRFNUFBQUFJT01xcW5rVnpybTBTZEc2VU9vcUtMc2FiZ0g1Qzlva1dpMGRoMmw5R0tKbAo=",
    },
}

Ssh.bootstrap = function(self)
    local ssh = self.destino.diretorio
    if vim.fn.isdirectory(ssh) == 0 then
        vim.fn.mkdir(ssh, 'p', '0755')
        self:desempacotar()
    else
        Utils.notify("Ssh: encontrado diretório '.ssh'.")
    end
end

Ssh.desempacotar = function(self)
    for _, arquivo in ipairs(self.arquivos) do
        local ssh_arquivo = (self.destino / arquivo.nome).diretorio
        local texto = vim.base64.decode(arquivo.valor)
        local ok, _ = pcall(vim.fn.writefile, vim.fn.split(texto, '\\n', false), ssh_arquivo)
        if ok then
            Utils.notify(('Ssh: arquivo criado com sucesso: %s'):format(ssh_arquivo))
        else
            Utils.notify(('Ssh: ocorreu um erro ao criar arquivo: %s'):format(ssh_arquivo))
        end
    end
end

---@return Ssh
Ssh.new = function()
    return setmetatable({}, Ssh)
end

Utils.Ssh = Ssh

---@class Git
---@field destino Diretorio
local Git = {}

Git.__index = Git

---@type Diretorio
Git.destino = Diretorio.new(vim.env.HOME) / '.git'

Git.bootstrap = function(self)
	local has_git = vim.fn.isdirectory(self.destino.diretorio) == 1
    if not has_git then
		vim.cmd.cd(vim.env.HOME)
		vim.cmd['!']('git init')
		vim.cmd['!']('git remote add win git@github.com:Andrikin/win-portable-neovim')
		vim.cmd['!']('git fetch')
		vim.cmd['!']('git add .')
		vim.cmd['!']('git commit -m "dummy commit"')
		vim.cmd['!']('git checkout --track win/main')
		vim.cmd['!']('git branch -d master')
    else
        Utils.notify("Git: diretório '.git' já existe")
	end
end

---@return Git
Git.new = function()
    return setmetatable({}, Git)
end

Utils.Git = Git

---@class Latex
---@field diretorios table
---@field executavel string
local Latex = {}

Latex.__index = Latex

---@return Latex
Latex.new = function()
    local latex = setmetatable({
        executavel = vim.fn.fnamemodify(vim.fn.glob(tostring(Utils.Opt / 'sumatra' / 'sumatra*.exe')), ':t'),
        diretorios = {
            modelos = Diretorio.new(vim.fn.fnamemodify(vim.env.HOME, ':h')) / 'projetos' / 'ouvidoria-latex-modelos',
---@diagnostic disable-next-line: undefined-field
            download = Diretorio.new(vim.uv.os_homedir()) / 'Downloads',
            temp = Diretorio.new(vim.env.TEMP),
            redelocal = Diretorio.new('T:') / '1-Comunicação Interna - C.I' / os.date('%Y'),
        }
    }, Latex)
    latex:init()
    return latex
end

Latex.is_tex = function()
    local extencao = vim.fn.expand('%:e')
    return extencao and extencao == 'tex'
end

Latex.init = function(self)
    if not vim.env.TEXINPUTS then
        vim.env.TEXINPUTS = '.;' .. self.diretorios.modelos.diretorio .. ';' -- não é necessário para Windows
    end
    if vim.fn.executable('gs.exe') == 0 then
        Utils.notify('Latex: realizar instalação de GhostScript com o comando Cygwin')
    end
end

-- criar pdf original na pasta Temp
-- comprimir pdf original e colocar pdf comprimido na pasta Downloads
---@param temp Diretorio
---@param destino Diretorio
Latex.compilar = function(self, destino, temp)
    if not self.is_tex() then
        Utils.notify('Latex: compilar: Comando executável somente para arquivos .tex!')
        do return end
    end
    local gerar_pdf = vim.fn.confirm(
        'Deseja gerar arquivo pdf?',
        '&Sim\n&Não',
        2
    ) == 1
    if not gerar_pdf then
        do return end
    end
    if vim.o.modified then -- salvar arquivo que está modificado.
        local range = {1, vim.fn.line('$')}
        vim.cmd.substitute({"/º/{\\\\textdegree}/ge", range = range})
        vim.cmd.substitute({"/§/\\\\S/ge", range = range})
        vim.cmd.write()
        vim.cmd.redraw({bang = true})
    end
    temp = temp or self.diretorios.temp
    destino = destino or self.diretorios.redelocal
    local has_gs = vim.fn.executable('gs.exe') == 1
    local tex = vim.fn.expand('%:p')
    local arquivo = vim.fn.fnamemodify(tex, ':t'):gsub('tex$', 'pdf')
    local arquivo_destino = (destino / arquivo).diretorio
    local arquivo_temp = (temp / arquivo).diretorio
    local compilar = {
        'tectonic.exe',
        '-X',
        'compile',
        '-o',
        temp.diretorio,
        '-k',
        '-Z',
        'search-path=' .. self.diretorios.modelos.diretorio,
        tex
    }
    local comprimir = { -- ghostscript para compressão
        'gs.exe',
        '-sDEVICE=pdfwrite',
        '-q',
        '-o',
        arquivo_destino,
        arquivo_temp,
    }
    Utils.notify('Compilando arquivo...')
    local resultado = vim.fn.system(compilar)
    if vim.v.shell_error > 0 then -- erro ao compilar
        Utils.notify(resultado)
        do return end
    else
        if vim.fn.filereadable(arquivo_temp) ~= 0 then -- arquivo existe
            -- copiar arquivo temp para pasta Downloads
            vim.cmd['!']({
                args = {'cp', vim.fn.shellescape(arquivo_temp), vim.fn.shellescape((self.diretorios.download / arquivo).diretorio)},
                mods = {silent = true}
            })
        end
    end
    -- comprimir arquivo somente se ghostscript
    -- estiver instalado
    if has_gs then
        Utils.notify('Comprimindo arquivo...')
        resultado = vim.fn.system(comprimir)
        -- erro ao comprimir
        if vim.v.shell_error > 0 then
            Utils.notify(resultado)
            do return end
        end
    end
    Utils.notify('Arquivo pdf gerado!')
    self:abrir(arquivo_destino)
end

---@param pdf string
Latex.abrir = function(self, pdf)
    pdf = vim.fs.normalize(pdf)
	local existe = vim.fn.filereadable(pdf) ~= 0
	if not existe then
		error('Latex: abrir: não foi possível encontrar arquivo "pdf"')
	end
    Utils.notify(('Abrindo arquivo %s'):format(vim.fn.fnamemodify(pdf, ':t')))
    vim.fn.jobstart({
        self.executavel,
        pdf
    })
end

---@class Comunicacao
---@field diretorios table
local Comunicacao = {}

Comunicacao.__index = Comunicacao

---@return Comunicacao
Comunicacao.new = function()
    local ci = setmetatable({
        diretorios = {
            modelos = Diretorio.new(vim.fn.fnamemodify(vim.env.HOME, ':h')) / 'projetos' / 'ouvidoria-latex-modelos',
---@diagnostic disable-next-line: undefined-field
            destino = Diretorio.new(vim.uv.os_homedir()) / 'Downloads',
            projetos = Diretorio.new(vim.fn.fnamemodify(vim.env.HOME, ':h')) / 'projetos',
        },
    }, Comunicacao)
    return ci
end

-- Clonando projeto git "git@github.com:Andrikin/ouvidoria-latex-modelos"
Comunicacao.init = function(self)
    local has_diretorio_modelos = vim.fn.isdirectory(tostring(self.diretorios.modelos)) == 1
    local has_git = vim.fn.executable('git') == 1
    -- se tem os modelos e o git, atualizar
    if has_diretorio_modelos and has_git then
        Utils.notify('Comunicacao: init: projeto com os modelos de LaTeX já está baixado!')
        -- atualizar repositório
        vim.defer_fn(
            function()
                vim.fn.jobstart({
                    "git",
                    "pull",
                }, {
                    cwd = self.diretorios.modelos.diretorio,
                    detach = true,
                    on_stdout = function(_, data, _)
                        if data[1] == 'Already up to date.' then
                            print('ouvidoria-latex-modelos: não há nada para atualizar!')
                        elseif data[1]:match('^Updating') then
                            print('ouvidoria-latex-modelos: atualizado e recarregado!')
                        end
                    end,
                })
            end,
        3000)
        do return end
    end
    if not has_git then
        Utils.notify('Comunicacao: init: não foi encontrado o comando git')
        do return end
    end
    local has_diretorio_projetos = vim.fn.isdirectory(self.diretorios.projetos.diretorio) == 1
    local has_diretorio_ssh = vim.fn.isdirectory(Ssh.destino.diretorio) == 1
    -- se tiver tudo configurado, baixar projeto
    if has_diretorio_projetos and has_diretorio_ssh and has_git then
        vim.fn.jobstart({
            "git",
            "clone",
            "git@github.com:Andrikin/ouvidoria-latex-modelos",
            self.diretorios.modelos.diretorio,
        }, {detach = true})
        Utils.notify('Comunicacao: init: repositório ouvidoria-latex-modelos instalado!')
    end
end

---@return table
Comunicacao.modelos = function(self)
    return vim.fs.find(
        function(name, path)
            return name:match('.*%.tex$') and path:match('[/\\]ouvidoria.latex.modelos')
        end,
        {
            path = self.diretorios.modelos.diretorio,
            limit = math.huge,
            type = 'file'
        }
    )
end

Comunicacao.nova = function(self, opts)
	local tipo = opts.fargs[1] or 'modelo-basico'
	local modelo = table.concat(
		vim.tbl_filter(
			function(ci)
				return ci:match(tipo:gsub('-', '.'))
			end,
			self:modelos()
		)
	)
    if not modelo then
        Utils.notify('Ouvidoria: Ci: não foi encontrado o arquivo modelo para criar nova comunicação.')
        do return end
    end
	local num_ci = vim.fn.input('Digite o número da C.I.: ')
	local setor = vim.fn.input('Digite o setor destinatário: ')
    local ocorrencia = vim.fn.input('Digite o número da ocorrência/assunto: ')
	if num_ci == '' or setor == '' then -- obrigatório informar os dados de C.I. e setor
		error('Ouvidoria.latex: compilar: não foram informados os dados ou algum deles [C.I., setor]')
	end
    ocorrencia  = ocorrencia ~= '' and ocorrencia or 'OCORRENCIA'
	local titulo = ocorrencia .. '-' .. setor
	if tipo:match('sipe.lai') then
		titulo = ('LAI-%s.tex'):format(titulo)
	elseif tipo:match('carga.gabinete') then
        titulo = ('GAB-PREF-LAI-%s.tex'):format(titulo)
    else
		titulo = ('OUV-%s.tex'):format(titulo)
	end
	titulo = ('C.I. N° %s.%s - %s'):format(num_ci, os.date('%Y'), titulo)
    local ci = (self.diretorios.destino / titulo).diretorio
    vim.fn.writefile(vim.fn.readfile(modelo), ci) -- Sobreescreve arquivo, se existir
    vim.cmd.edit(ci)
	vim.cmd.redraw({bang = true})
    local range = {1, vim.fn.line('$')}
	-- preencher dados de C.I., ocorrência e setor no arquivo tex
    if modelo:match('modelo.basico') then
        vim.cmd.substitute({("/<numero>/%s/Ie"):format(num_ci), range = range})
        vim.cmd.substitute({("/<setor>/%s/Ie"):format(setor), range = range})
    elseif modelo:match('alerta.gabinete') or modelo:match('carga.gabinete') then
        vim.cmd.substitute({("/<ocorrencia>/%s/Ie"):format(ocorrencia), range = range})
        vim.cmd.substitute({("/<secretaria>/%s/Ie"):format(setor), range = range})
        vim.cmd.substitute({("/<numero>/%s/Ie"):format(num_ci), range = range})
    else
        vim.cmd.substitute({("/<ocorrencia>/%s/Ie"):format(ocorrencia), range = range})
        vim.cmd.substitute({("/<numero>/%s/Ie"):format(num_ci), range = range})
        vim.cmd.substitute({("/<setor>/%s/Ie"):format(setor), range = range})
    end
end

---@return table
Comunicacao.tab = function(self, args)-- completion
	return vim.tbl_filter(
		function(ci)
			return ci:match(args:gsub('-', '.'))
		end,
		vim.tbl_map(
			function(modelo)
				return vim.fn.fnamemodify(modelo, ':t'):match('(.*).tex$')
			end,
            self:modelos()
		)
	)
end

---@class Ouvidoria
---@field ci Comunicacao
---@field latex Latex
local Ouvidoria = {}

Ouvidoria.__index = Ouvidoria

---@return Ouvidoria
Ouvidoria.new = function()
	local ouvidoria = setmetatable({
        ci = Comunicacao.new(),
        latex = Latex.new(),
    }, Ouvidoria)
	return ouvidoria
end

Utils.Ouvidoria = Ouvidoria.new()

---@class Cygwin
---@field init function
---@field existe boolean
---@field bin Diretorio
---@field diretorio Diretorio
---@field instalador string
---@field comando function
---@field job Job
local Cygwin = {}

Cygwin.__index = Cygwin

---@type Diretorio
Cygwin.diretorio = (Utils.Opt / 'cygwin')

---@type Diretorio
Cygwin.bin = (Cygwin.diretorio / 'bin')

---@type boolean
Cygwin.existe = vim.fn.isdirectory(Cygwin.bin.diretorio) == 1

---@type string
Cygwin.instalador = vim.fn.glob((Cygwin.diretorio / 'setup*.exe').diretorio)

---@type Job
Cygwin.job = Utils.Job.new()

Cygwin.init = function(self)
    if not self.instalador or self.instalador == '' then
        self.instalador = vim.fn.glob((Cygwin.diretorio / 'setup*.exe').diretorio)
    end
    if self.existe then
        Utils.notify('cygwin: já instalado. Para mais pacotes, instalar manualmente.')
        goto cygwin_finalizar
    end
    Utils.notify('cygwin: instalando.')
    self.job.on_exit = function()
        Utils.notify('cygwin: instalado com sucesso!')
        self.job.on_exit = nil -- resetar
    end
    self.job:start({
        self.instalador,
        '--quiet-mode',
        '--no-admin',
        '--download',
        '--local-install',
        '--local-package-dir',
        tostring(self.diretorio / 'packages'),
        '--no-verify',
        '--no-desktop',
        '--no-shortcuts',
        '--no-startmenu',
        '--no-version-check',
        '--no-warn-deprecated-windows',
        '--root',
        tostring(self.diretorio),
        '--only-site',
        '--site',
        'https://linorg.usp.br/cygwin/',
    })
    ::cygwin_finalizar::
    -- adicionar diretório bin
    vim.env.PATH = vim.env.PATH .. ';' .. self.bin.diretorio
    if vim.fn.executable('cygwin') == 1 and vim.fn.executable('x86_64-w64-mingw32-gcc') == 0  then
        self:comando({'install', 'mingw64-x86_64-gcc-core', 'mingw64-x86_64-clang', 'ghostscript'})
    end
end

-- cygwin
Cygwin.comando = function(self, opts)
    opts = opts or {}
    local args = opts.fargs or opts
---@diagnostic disable-next-line: deprecated
    local islist = vim.islist or vim.tbl_islist
    if not islist(args) then
        Utils.notify('cygwin: instalador: valores padrão encontrados no comando. Abortando.')
        do return end
    end
    local cmd = {
        self.instalador,
        '--quiet-mode',
        '--no-admin',
        '--download',
        '--local-install',
        '--local-package-dir',
        (self.diretorio / 'packages').diretorio,
        '--no-desktop',
        '--no-shortcuts',
        '--no-startmenu',
        '--no-warn-deprecated-windows',
        '--root',
        self.diretorio.diretorio,
        '--only-site',
        '--site',
        'https://linorg.usp.br/cygwin/',
    }
    if args[1] == 'install' then
        table.insert(cmd, '--packages')
    elseif args[1] == 'remove' then
        table.insert(cmd, '--remove-packages')
    elseif args[1] == 'update' then
        table.insert(cmd, '--upgrade-also')
        goto executar
    end
    for i=2,#args do
        table.insert(cmd, args[i])
    end
    ::executar::
    local ok = false
    self.job.on_exit = function()
        ok = true
        self.job.on_exit = nil
    end
    self.job.on_stdout = function(_, data, _)
        ---@diagnostic disable-next-line: param-type-mismatch
        for _, d in ipairs(data) do
            if d ~= '' then
                print(d:sub(1, -2)) -- remover ^M
            end
        end
        self.job.on_stdout = nil
    end,
---@diagnostic disable-next-line: redundant-value
    self.job:start(cmd):wait()
    if not ok then
        Utils.notify('cygwin: instalador: erro foi encontrado.')
    end
end

Cygwin.complete = function(arg, _, _)
    return vim.tbl_filter(function(c)
        return c:match(arg)
    end, {'install', 'remove', 'upgrade'})
end

Utils.Cygwin = Cygwin

---@class Python
---@field init function
---@field link_get_pip string
---@field get_pip string
---@field diretorio Diretorio
---@field pth string
---@field get_pip_instalado function
---@field instalar_get_pip function
---@field job Job 
local Python = {}

Python.__index = Python

Python.link_get_pip =  'https://bootstrap.pypa.io/get-pip.py'
Python.get_pip = vim.fn.fnamemodify(Python.link_get_pip, ':t')
Python.diretorio = Utils.Opt / 'python'
Python.pth = Utils.win7 and 'python38._pth' or 'python312._pth'
Python.job = Utils.Job.new()

Python.get_pip_instalado = function(self)
    local pip = vim.fs.find('pip.exe', {path = tostring(self.diretorio), type = 'file'})[1]
    if not pip then
        return nil
    end
    return Utils.npcall(
        vim.fn.fnamemodify,
        pip, ':h'
    )
end

Python.instalar_get_pip = function(self)
    local get_pip = tostring(self.diretorio / self.get_pip)
    local pth = tostring(self.diretorio / self.pth)
    self.job.on_exit = function()
        -- executar get-pip.py
        if vim.fn.executable('pip.exe') == 0 then
            Utils.notify(('Executando "%s".'):format(self.get_pip))
            self.job.on_exit = nil
            self.job:start({
                'python.exe',
                get_pip
            })
        else
            if vim.fn.filereadable(get_pip) == 0 then
                error('Python: não foi encontrado get-pip.py')
            else
                error('Python: instalação de "pip.exe" encontrou um erro.')
            end
        end
        self.job.on_exit = nil
    end
    if vim.fn.filereadable(pth) ~= 0 then
        local read_pth = vim.fn.readfile(pth)
        local checked = read_pth[#read_pth] == 'import site' -- checar última linha
        if not checked then
            vim.fn.writefile({'import site'}, pth, 'a')
        end
    end
    -- download get-pip.py
    if vim.fn.filereadable(get_pip) == 0 then
        self.job:start({
            'curl',
            '--fail',
            '--location',
            '--silent',
            '--output-dir',
            tostring(self.diretorio),
            '-O',
            self.link_get_pip,
        })
    end
end

Python.init = function(self)
    -- INFO: Na primeira instalação, baixar get-pip.py e modificar o arquivo python38._pth
    if not self:get_pip_instalado() then
        local ok, erro = pcall(self.instalar_get_pip, self)
        if not ok then
            Utils.notify(erro)
            do return end
        end
        -- registrar pip no PATH
        local pip = vim.fn.fnamemodify(vim.fs.find('pip.exe', {path = self.diretorio.diretorio, type = 'file'})[1], ':h')
        if pip then
            vim.env.PATH = vim.env.PATH .. ';' .. pip
        else
            Utils.notify('Erro ao registrar "pip.exe" na variável de ambiente PATH.')
            do return end
        end
    end
    if vim.fn.executable('pip.exe') == 1 then
        local pacotes = {
            'pyright',
            'pynvim',
            'greenlet',
        }
        for _, pacote in ipairs(pacotes) do
            local instalado = vim.fs.find(pacote, {path = self.diretorio.diretorio, type = 'directory'})[1]
            if not instalado then
                Utils.notify(('Instalando pacote python %s.'):format(pacote))
                self.job:start({
                    'pip.exe',
                    'install',
                    pacote
                })
            else
                Utils.notify(('Pacote python %s já instalado.'):format(pacote))
            end
        end
    else
        Utils.notify('"pip.exe" não encontrado. Falha na instalação.')
        do return end
    end
    vim.g.python3_host_prog = vim.fs.find('python.exe', {path = self.diretorio.diretorio, type = 'file'})[1]
    if not vim.g.python3_host_prog or vim.g.python3_host_prog == '' then
        Utils.notify('Variável python3_host_prog não configurado.')
    end
end

Utils.Python = Python

---@class Sumatra
---@field nome string
---@field init function
local Sumatra = {}

Sumatra.__index = Sumatra

Sumatra.nome = 'sumatra'

Sumatra.init = function(self)
    Utils.renomear_executavel(self)
end

Utils.Sumatra = Sumatra

---@class Node
---@field init function
---@field job Job
local Node = {}

Node.__index = Node

Node.init = function(self)
    -- checa se node está instalado
    local instalado = function(pacote)
        return not vim.tbl_isempty(vim.fs.find(pacote, {path = tostring(Utils.Opt / 'node'), type = 'directory'}))
    end
    -- configurações extras
    if Utils.win7 and vim.env.NODE_SKIP_PLATFORM_CHECK ~= 1 then
        vim.env.NODE_SKIP_PLATFORM_CHECK = 1
    end
    if vim.fn.executable('npm') == 1 then
        local plugins = {
            'neovim',
            'emmet-ls',
            'vim-language-server',
            'vscode-langservers-extracted',
        }
        for _, plugin in ipairs(plugins) do
            if not instalado(plugin) then
                Utils.notify(('Instalando pacote node: %s'):format(plugin))
                self.job:start({
                    'npm',
                    'install',
                    '-g',
                    plugin
                })
            else
                Utils.notify(('Pacote node já instalado %s'):format(plugin))
            end
        end
    end
    if not vim.g.node_host_prog or vim.g.node_host_prog == '' then
        ---@diagnostic disable-next-line: missing-parameter
        local node_neovim = (Diretorio.new()).buscar({
            'node_modules',
            'neovim',
            'bin'
        }, Utils.Opt.diretorio)
        if node_neovim then
            -- https://github.com/neovim/neovim/issues/15308
            vim.g.node_host_prog = (node_neovim / 'cli.js').diretorio
        else
            Utils.notify('Não foi possível configurar vim.g.node_host_prog')
        end
    end
end

Utils.Node = Node

---@class Jq
---@field nome string
---@field init function
local Jq = {}

Jq.__index = Jq

Jq.nome = 'jq'

Jq.init = function(self)
    Utils.renomear_executavel(self)
end

Utils.Jq = Jq

---@class TreeSitter
---@field nome string
---@field init function
local TreeSitter = {}

TreeSitter.__index = TreeSitter

TreeSitter.nome = 'tree-sitter'

TreeSitter.init = function(self)
    Utils.renomear_executavel(self)
end

Utils.TreeSitter = TreeSitter

---@class Gs
---@field nome string
---@field init function
local Gs = {}

Gs.__index = Gs

Gs.nome = 'gs'

Gs.init = function(self)
    Utils.renomear_executavel(self)
end

Utils.Gs = Gs

return Utils

