---@class Utils
---@field Diretorio Diretorio
---@field SauceCodePro SauceCodePro
---@field Registrador Registrador
---@field Curl Curl
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
---@field Andrikin table
---@field bootstrap function
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
Utils.win7 = string.match(vim.loop.os_uname()['version'], 'Windows 7')

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

Utils.autocmd = vim.api.nvim_create_autocmd

Utils.Andrikin = vim.api.nvim_create_augroup('Andrikin', {clear = true})

---@class Programa
---@field nome string
---@field link string
---@field cmd string | table
---@field config function
---@field baixado boolean
---@field extraido boolean
---@field finalizado boolean
---@field timeout number
---@field processo thread
local Programa = {}

Programa.__index = Programa

---@type boolean
Programa.baixado = false

---@type boolean
Programa.extraido = false

---@type boolean
Programa.finalizado = false

---@type number
Programa.timeout = 120 * 1000

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

Programa.baixar = function(self)
	local diretorio = tostring(self:diretorio())
	vim.fn.system({
		'curl',
		'--fail',
		'--location',
		'--silent',
        '--output-dir',
		diretorio,
        '-O',
		self.link
	})
	if vim.v.shell_error == 0 then
        self.baixado = true
        self:extrair() -- realizar extração do arquivo 
	end
end

Programa.extrair = function(self)
    local diretorio = tostring(self:diretorio())
    local arquivo = tostring(self:diretorio() / self:nome_arquivo())
    local zip = self:extencao() == 'zip'
    if zip then
		vim.fn.system({
			'unzip',
			arquivo,
			'-d',
			diretorio
		})
    elseif self:extencao() == 'gz' then
        vim.fn.system({
            'gzip',
            '-d',
            tostring(arquivo),
        })
    else
		vim.fn.system({
			'tar',
			'-xf',
			arquivo,
			'-C',
			diretorio
		})
    end
	if vim.v.shell_error == 0 then
        self.extraido = true
        vim.fn.delete(arquivo) -- remover arquivo comprimido baixado
	end
end

-- TODO: Refazer utilizando vim.loop.spawn e coroutines
Programa.baixar2 = function(self)
	local diretorio = tostring(self:diretorio())
	local handler
    local timeout
    if self.timeout then
        timeout = assert(vim.loop.new_timer())
        timeout:start(self.timeout, 0, function()
            if handler and not handler:is_closing() then
                print(('Tempo para download excedido. Encerrando download de %s'):format(self.nome))
                vim.loop.process_kill(handler, 'sigint')
            end
        end)
    end
	handler = vim.loop.spawn('curl',
		{
			args = {
				'--fail',
				'--location',
				'--silent',
				'--output-dir',
				diretorio,
				'-O',
				self.link
			}
		}, function()
            if timeout then
                timeout:stop()
                timeout:close()
            end
            handler:close()
            self.baixado = true
	end)
end

Programa.extrair2 = function(self)
    local diretorio = tostring(self:diretorio())
    local arquivo = tostring(self:diretorio() / self:nome_arquivo())
    local zip = self:extencao() == 'zip'
	local handler
    local timeout
    if self.timeout then
        timeout = assert(vim.loop.new_timer())
        timeout:start(self.timeout, 0, function()
            if handler and not handler:is_closing() then
                print(('Tempo para extração excedido. Encerrando extração de %s'):format(self.nome))
                vim.loop.process_kill(handler, 'sigint')
            end
        end)
    end
    local on_exit = function()
        if timeout then
            timeout:stop()
            timeout:close()
        end
        handler:close()
        self.extraido = true
    end
    if zip then
		handler = vim.loop.spawn('unzip', {
			args = {
				arquivo,
				'-d',
				diretorio
			}
		}, on_exit)
    else
		handler = vim.loop.spawn('tar', {
			args = {
				'-xf',
				arquivo,
				'-C',
				diretorio
			}
		}, on_exit)
    end
end

--- Instalação do programa.
--- Realiza duas tentativas de inclusão no PATH, baixando e extraindo programa
--- na primeira falha. Na segunda, retorna mensagem de erro.
Programa.instalar2 = function(self)
    if self:registrar() then
        do return end
    end
    self:criar_diretorio()
    self:checar_instalacao()
    if not self.baixado and not self.extraido then
		self:baixar2()
		coroutine.yield(self)
    elseif not self.extraido then
        self:extrair2()
		coroutine.yield(self)
    else
        Utils.notify(('Programa: Algum erro ocorreu ao realizar a instalação do programa %s.'):format(self.nome))
        do return end
    end
    if not self:registrar() then
        Utils.notify(('Programa: instalar: Não foi possível realizar a instalação do programa %s.'):format(self.nome))
		do return end
    else
        self.finalizado = true -- instalação concluída
		if self.config then
			self.config()
		end
    end
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

Programa.criar_diretorio = function(self)
    if vim.fn.isdirectory(self:diretorio().diretorio) then
        vim.fn.mkdir(self:diretorio().diretorio, 'p', 0700)
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
        do return end
    end
    self:criar_diretorio()
    self:checar_instalacao()
    if not self.baixado and not self.extraido then
        self:baixar()
    elseif not self.extraido then
        self:extrair()
    else
        Utils.notify(('Programa: Algum erro ocorreu ao realizar a instalação do programa %s.'):format(self.nome))
        do return end
    end
    if not self:registrar() then
        Utils.notify(('Programa: instalar: Não foi possível realizar a instalação do programa %s.'):format(self.nome))
		do return end
    else
        self.finalizado = true -- instalação concluída
		if self.config then
			self.config()
		end
    end
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
Diretorio._sanitize = function(str)
    vim.validate({ str = {str, 'string'} })
    return vim.fs.normalize(str)
end

---@private
---@return string
--- Realiza busca nas duas direções pelo 
Diretorio.buscar = function(dir, start)
    vim.validate({ dir = {dir,{'table', 'string'}} })
    vim.validate({ start = {start, 'string'} })
    if dir:match('^' .. vim.env.HOMEDRIVE) then
        error('Diretorio: _search: argumento deve ser um trecho de diretório, não deve conter "C:/" no seu início.')
    end
    if type(dir) == 'table' then
        dir = vim.fs.normalize(table.concat(dir, '/'))
    else
        dir = vim.fs.normalize(dir)
    end
    start = Diretorio._sanitize(start) or Diretorio._sanitize(vim.env.HOMEPATH)
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
        error('Diretorio: _search: não foi encontrado o caminho do diretório informado.')
    end
    return diretorio-- valores de vim.fs.dir já são normalizados
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
Utils.bootstrap = function(self)
    if vim.fn.isdirectory(self.Opt.diretorio) then
        vim.fn.mkdir(self.Opt.diretorio, 'p', 0700)
    end
end

---@class Curl
---@field unzip_link string Url para download de unzip.exe
local Curl = {}

Curl.__index = Curl

---@return Curl
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
    self.download(self.unzip_link, Utils.Opt.diretorio)
    local unzip = vim.fs.find('unzip.exe', {path = Utils.Opt.diretorio, type = 'file'})[1]
    if vim.v.shell_error > 0 then
        error('Curl: bootstrap: Não foi possível realizar o download do unzip.exe')
    elseif unzip == '' then
        error('Curl: bootstrap: Não foi possível encontrar o executável unzip.exe.')
    end
end

---@param link string
---@param diretorio string
Curl.download = function(link, diretorio)
	vim.validate({
		link = {link, 'string'},
		diretorio = {diretorio, 'string'}
	})
	if link == '' or diretorio == '' then
		error('Curl: download: Variável nula')
	end
	local arquivo = vim.fn.fnamemodify(link, ':t')
	diretorio = tostring(Diretorio.new(diretorio) / arquivo)
	vim.fn.system({
		'curl',
		'--fail',
		'--location',
		'--silent',
		'--output',
		diretorio,
		link
	})
	if vim.v.shell_error == 0 then
		Utils.notify(('Curl: download: Arquivo %s baixado!'):format(arquivo))
	else
		Utils.notify(('Curl: download: Não foi possível realizar o download do arquivo %s!'):format(arquivo))
	end
end

---@param arquivo string
---@param diretorio string
Curl.extrair = function(arquivo, diretorio)
	vim.validate({
		arquivo = {arquivo, 'string'},
		diretorio = {diretorio, 'string'}
	})
	if arquivo == '' or diretorio == '' then
		error('Curl: extrair: Variável nula.')
	end
	local extencao = arquivo:match('%.(tar)%.[a-z.]*$') or arquivo:match('%.([a-z]*)$')
    local extracao = false
	if extencao == 'zip' then
		vim.fn.system({
			'unzip',
			arquivo,
			'-d',
			diretorio
		})
        extracao = true
	elseif extencao == 'tar' then
		vim.fn.system({
			'tar',
			'-xf',
			arquivo,
			'-C',
			diretorio
		})
        extracao = true
	end
    if extracao then
        local nome = arquivo:match('[/\\]([^/\\]+)$') or arquivo
        if vim.v.shell_error == 0 then
            Utils.notify(('Curl: extrair: Arquivo %s extraído com sucesso!'):format(nome))
        else
            Utils.notify(('Curl: extrair: Erro encontrado! Não foi possível extrair o diretorio_arquivo %s'):format(nome))
        end
    end
end

Utils.Curl = Curl

---@class Registrador
---@field diretorio Diretorio Onde as dependências ficaram instaladas
local Registrador = {}

Registrador.__index = Registrador

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
        vim.fn.mkdir(tostring(self), 'p', 0700)
    end
    if not vim.env.PATH:match(tostring(self):gsub('[\\/-]', '.')) then
        vim.env.PATH = vim.env.PATH .. ';' .. tostring(self)
    end
end

-- TODO: FINALIZAR
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
local SauceCodePro = {}

SauceCodePro.__index = SauceCodePro

SauceCodePro.registro = Diretorio.new('HKCU') / 'Software' / 'Microsoft' / 'Windows NT' / 'CurrentVersion' / 'Fonts'

SauceCodePro.diretorio = Utils.Opt / 'fonte'

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
    Curl.download(self.link, tostring(self))
    if not self:zip_baixado() then
        error('Fonte: download: Não foi possível realizar o download do arquivo da fonte.')
    end
    Utils.notify('Arquivo fonte .zip baixado!')
end

---Decompressar arquivo zip
SauceCodePro.extrair_zip = function(self)
    Curl.extrair(self.arquivo.diretorio, tostring(self))
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

Utils.Projetos = Diretorio.new(vim.fn.fnamemodify(vim.env.HOME, ':h')) / 'projetos'

---WARNING: classe para instalar as credenciais .ssh
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
        valor = [[
LS0tLS1CRUdJTiBPUEVOU1NIIFBSSVZBVEUgS0VZLS0tLS0KYjNCbGJuTnphQzFyWlhrdGRqRUFB
QUFBQkc1dmJtVUFBQUFFYm05dVpRQUFBQUFBQUFBQkFBQUFNd0FBQUF0emMyZ3RaVwpReU5UVXhP
UUFBQUNCTTBXQTZXdWFsYzg0QkF0YTF2bHFFM2JDMHBrM3hkNzUxSm9HV01OcmFCUUFBQUtqdkYz
Z2E3eGQ0CkdnQUFBQXR6YzJndFpXUXlOVFV4T1FBQUFDQk0wV0E2V3VhbGM4NEJBdGExdmxxRTNi
QzBwazN4ZDc1MUpvR1dNTnJhQlEKQUFBRUFZVEtmSzBEZUFzOWFKbkdqMVRCaWhUMnV3MXQrTlZ2
SzdrU3hQdEFHNTRFelJZRHBhNXFWenpnRUMxclcrV29UZApzTFNtVGZGM3ZuVW1nWll3MnRvRkFB
QUFJV052Ym5SaGMyVmpjbVYwWVdGc2RHVnlibUYwYVhaaFFHZHRZV2xzTG1OdmJRCkVDQXdRPQot
LS0tLUVORCBPUEVOU1NIIFBSSVZBVEUgS0VZLS0tLS0K
    ]],
    },
    {
        nome = 'id_ed25519.pub',
        valor = [[
c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSUV6UllEcGE1cVZ6emdFQzFyVytX
b1Rkc0xTbVRmRjN2blVtZ1pZdzJ0b0YgY29udGFzZWNyZXRhYWx0ZXJuYXRpdmFAZ21haWwuY29t
Cg==
    ]],
    },
    {
        nome = 'known_hosts',
        valor = [[
Z2l0aHViLmNvbSBzc2gtZWQyNTUxOSBBQUFBQzNOemFDMWxaREkxTlRFNUFBQUFJT01xcW5rVnpy
bTBTZEc2VU9vcUtMc2FiZ0g1Qzlva1dpMGRoMmw5R0tKbApnaXRodWIuY29tIHNzaC1yc2EgQUFB
QUIzTnphQzF5YzJFQUFBQURBUUFCQUFBQmdRQ2o3bmROeFFvd2djUW5qc2hjTHJxUEVpaXBobnQr
VlRUdkRQNm1IQkw5ajFhTlVrWTRVZTFndnduR0xWbE9oR2VZcm5aYU1nUks2K1BLQ1VYYURiQzdx
dGJXOGdJa2hMN2FHQ3NPci9DNTZTSk15L0JDWmZ4ZDFuV3pBT3hTRFBnVnNtZXJPQllmTnFsdFY5
L2hXQ3FCeXdJTklSKzVkSWc2SlRKNzJwY0VwRWpjWWdYa0UyWUVGWFYxSkhuc0tnYkxXTmxoU2Nx
YjJVbXlSa1F5eXRSTHRMKzM4VEd4a3hDZmxtTys1WjhDU1NOWTdHaWRqTUlaN1E0ek1qQTJuMW5H
cmxURGt6d0RDc3crd3FGUEdRQTE3OWNuZkdXT1dSVnJ1ajE2ejZYeXZ4dmpKd2J6MHdRWjc1WEs1
dEtTYjdGTnllSUVzNFRUNGprK1M0ZGhQZUFVQzV5K2JEWWlyWWdNNEdDN3VFbnp0blp5YVZXUTdC
MzgxQUs0UWRyd3Q1MVpxRXhLYlFwVFVObitFanFvVHd2cU5qNGtxeDVRVUNJMFRoUy9Za094SkNY
bVBVV1piaGpwQ2c1NmkrMmFCNkNtSzJKR2huNTdLNW1qME1OZEJYQTQvV253SDZYb1BXSnpLNU55
dTJ6QjNuQVpwK1M1aHBRcytwMXZOMS93c2prPQpnaXRodWIuY29tIGVjZHNhLXNoYTItbmlzdHAy
NTYgQUFBQUUyVmpaSE5oTFhOb1lUSXRibWx6ZEhBeU5UWUFBQUFJYm1semRIQXlOVFlBQUFCQkJF
bUtTRU5qUUVlek9teGtaTXk3b3BLZ3dGQjlua3Q1WVJyWU1qTnVHNU44N3VSZ2c2Q0xyYm81d0Fk
VC95NnYwbUtWMFUydzBXWjJZQi8rK1Rwb2NrZz0K
    ]],
    },
    {
        nome = 'known_hosts.old',
        valor = [[
Z2l0aHViLmNvbSBzc2gtZWQyNTUxOSBBQUFBQzNOemFDMWxaREkxTlRFNUFBQUFJT01xcW5rVnpy
bTBTZEc2VU9vcUtMc2FiZ0g1Qzlva1dpMGRoMmw5R0tKbAo=
    ]],
    },
}

Ssh.bootstrap = function(self)
    local ssh = self.destino.diretorio
    if vim.fn.isdirectory(ssh) == 0 then
        vim.fn.mkdir(ssh, 'p', 0700)
        self:desempacotar()
    else
        Utils.notify("Ssh: encontrado diretório '.ssh'.")
    end
end

Ssh.desempacotar = function(self)
    for _, arquivo in ipairs(self.arquivos) do
        local ssh_arquivo = (self.destino / arquivo.nome).diretorio
        local texto = vim.fn.systemlist({
            'base64.exe',
            '-d',
        }, { arquivo.valor })
        local ok, _ = pcall(vim.fn.writefile, texto, ssh_arquivo)
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
		vim.cmd('!git init')
		vim.cmd('!git remote add win git@github.com:Andrikin/win-portable-neovim')
		vim.cmd('!git fetch')
		vim.cmd('!git add .')
		vim.cmd('!git commit -m "dummy commit"')
		vim.cmd('!git checkout --track win/main')
		vim.cmd('!git checkout --track win/registrador')
		vim.cmd('!git branch -d master')
    else
        Utils.notify("Git: diretório '.git' já existe")
	end
end

---@return Git
Git.new = function()
    return setmetatable({}, Git)
end

Utils.Git = Git

---@class Ouvidoria
local Ouvidoria = {}

Ouvidoria.__index = Ouvidoria

---@return Ouvidoria
Ouvidoria.new = function()
	local ouvidoria = setmetatable({}, Ouvidoria)
	ouvidoria.ci:bootstrap()
	ouvidoria.latex:bootstrap()
	return ouvidoria
end

---@type string
Ouvidoria.tex = '.tex'

---@type table
Ouvidoria.ci = {}

---@type table
Ouvidoria.ci.diretorios = {-- diretório onde os modelos de comunicação interna estão (projeto git)
    modelos = Diretorio.new(vim.fn.fnamemodify(vim.env.HOME, ':h')) / 'projetos' / 'ouvidoria-latex-modelos',
    downloads = Diretorio.new(vim.loop.os_homedir()) / 'Downloads',
    projetos = Diretorio.new(vim.fn.fnamemodify(vim.env.HOME, ':h')) / 'projetos',
}

---@return table
Ouvidoria.ci.modelos = function()
    return vim.fs.find(
        function(name, path)
            return name:match('.*%.tex$') and path:match('[/\\]ouvidoria.latex.modelos')
        end,
        {
            path = tostring(Ouvidoria.ci.diretorios.modelos),
            limit = math.huge,
            type = 'file'
        }
    )
end

Ouvidoria.ci.nova = function(opts)
	local tipo = opts.fargs[1] or 'modelo-basico'
	local modelo = table.concat(
		vim.tbl_filter(
			function(ci)
				return ci:match(tipo:gsub('-', '.'))
			end,
			Ouvidoria.ci.modelos()
		)
	)
    if not modelo then
        Utils.notify('Ouvidoria: Ci: não foi encontrado o arquivo modelo para criar nova comunicação.')
        do return end
    end
	local num_ci = vim.fn.input('Digite o número da C.I.: ')
	local setor = vim.fn.input('Digite o setor destinatário: ')
    local ocorrencia = ''
    if not modelo:match('modelo.basico') then
        ocorrencia = vim.fn.input('Digite o número da ocorrência: ')
    end
	if num_ci == '' or ocorrencia == '' or setor == '' then -- obrigatório informar os dados
		error('Ouvidoria.latex: compilar: não foram informados os dados ou algum deles [C.I., ocorrência, setor].')
	end
	local titulo = ocorrencia .. '-' .. setor
	if tipo:match('sipe.lai') then
		titulo = 'LAI-' .. titulo .. Ouvidoria.tex
	elseif tipo:match('carga.gabinete') then
        titulo = 'GAB-PREF-LAI-' .. titulo .. Ouvidoria.tex
    else
		titulo = 'OUV-' .. titulo .. Ouvidoria.tex
	end
	titulo = ('C.I. N° %s.%s - '):format(num_ci, os.date('%Y')) .. titulo
    local ci = (Ouvidoria.ci.diretorios.downloads / titulo).diretorio
    vim.fn.writefile(vim.fn.readfile(modelo), ci) -- Sobreescreve arquivo, se existir
    vim.cmd.edit(ci)
	vim.cmd.redraw({bang = true})
    local range = {1, vim.fn.line('$')}
	-- preencher dados de C.I., ocorrência e setor no arquivo tex
    if modelo:match('modelo.basico') then
        vim.cmd.substitute({("/Cabecalho{}{[A-Z-]\\{-}}/Cabecalho{%s}{%s}/I"):format(num_ci, setor), range = range})
    elseif modelo:match('alerta.gabinete') or modelo:match('carga.gabinete') then
        vim.cmd.substitute({("/Ocorrencia{}/Ocorrencia{%s}/I"):format(ocorrencia), range = range})
        vim.cmd.substitute({("/Secretaria{}/Secretaria{%s}/I"):format(setor), range = range})
        vim.cmd.substitute({("/Cabecalho{}/Cabecalho{%s}/I"):format(num_ci), range = range})
    else
        vim.cmd.substitute({("/Ocorrencia{}/Ocorrencia{%s}/I"):format(ocorrencia), range = range})
        vim.cmd.substitute({("/Cabecalho{}{[A-Z-]\\{-}}/Cabecalho{%s}{%s}/I"):format(num_ci, setor), range = range})
    end
end

---@return table
Ouvidoria.ci.tab = function(args)-- tab completion
	return vim.tbl_filter(
		function(ci)
			return ci:match(args:gsub('-', '.'))
		end,
		vim.tbl_map(
			function(modelo)
				return vim.fn.fnamemodify(modelo, ':t'):match('(.*).tex$')
			end,
            Ouvidoria.ci.modelos()
		)
	)
end

-- Clonando projeto git "git@github.com:Andrikin/ouvidoria-latex-modelos"
Ouvidoria.ci.bootstrap = function(self)
    local has_diretorio_modelos = vim.fn.isdirectory(tostring(self.diretorios.modelos)) == 1
    if has_diretorio_modelos then
        Utils.notify('Ouvidoria: bootstrap: projeto com os modelos de LaTeX já está baixado!')
        do return end
    end
    local has_git = vim.fn.executable('git') == 1
    if not has_git then
        Utils.notify('Ouvidoria: bootstrap: não foi encontrado o comando git')
        do return end
    end
    local has_diretorio_projetos = vim.fn.isdirectory(self.diretorios.projetos.diretorio) == 1
    local has_diretorio_ssh = vim.fn.isdirectory(Ssh.destino.diretorio) == 1
    if has_diretorio_projetos and has_diretorio_ssh then
        vim.fn.system({
            "git",
            "clone",
            "git@github.com:Andrikin/ouvidoria-latex-modelos",
            tostring(self.diretorios.modelos),
        })
    else
        if not has_diretorio_ssh then
            Utils.notify("Git: não foi encontrado o diretório '.ssh'")
        end
        if not has_diretorio_projetos then
            Utils.notify("Git: não foi encontrado o diretório 'projetos'")
        end
    end
end

Ouvidoria.latex = {}

Ouvidoria.latex.diretorios = {
    opt = Utils.Opt,
    downloads = Ouvidoria.ci.diretorios.downloads,
    auxiliar = Diretorio.new(vim.env.TEMP),
}

Ouvidoria.latex.arquivo_tex = function()
    local extencao = vim.fn.expand('%'):match('%.([a-zA-Z0-9]*)$')
    return extencao and extencao == 'tex'
end

Ouvidoria.latex.bootstrap = function()
    if vim.fn.executable('tectonic') == 0 then
        error('Latex: bootstrap: não foi encontrado executável "tectonic"')
    end
	vim.env.TEXINPUTS = '.;' .. Ouvidoria.ci.diretorios.modelos.diretorio .. ';'
end

Ouvidoria.latex.pdf = {
    executavel = vim.fn.fnamemodify(vim.fn.glob(tostring(Ouvidoria.latex.diretorios.opt / 'sumatra' / 'sumatra*.exe')), ':t')
}

Ouvidoria.latex.pdf.abrir = function(arquivo)
    arquivo = arquivo:gsub('tex$', 'pdf')
	local existe = vim.fn.filereadable(arquivo) ~= 0
	if not existe then
		error('Ouvidoria: pdf.abrir: não foi possível encontrar arquivo "pdf"')
	end
    Utils.notify(('Abrindo arquivo %s'):format(vim.fn.fnamemodify(arquivo, ':t')))
    vim.fn.jobstart({
        Ouvidoria.latex.pdf.executavel,
        arquivo
    })
end

Ouvidoria.latex.compilar = function(self)
	if not self.arquivo_tex() then
		Utils.notify('Ouvidoria.latex: compilar: Comando executável somente para arquivos .tex!')
		do return end
	end
	local in_downloads = vim.fn.expand('%'):match(tostring(self.diretorios.downloads))
    if not in_downloads then
        Utils.notify('Ouvidoria.latex: compilar: arquivo "tex" não está na pasta $HOMEPATH/Downloads')
        do return end
    end
	if vim.o.modified then -- salvar arquivo que está modificado.
		vim.cmd.write()
		vim.cmd.redraw({bang = true})
	end
	local arquivo = vim.fn.expand('%')
    local comando = {
        'tectonic.exe',
        '-X',
        'compile',
        '-o',
        self.diretorios.downloads.diretorio,
        '-k',
        '-Z',
        'search-path=' .. tostring(Ouvidoria.ci.diretorios.modelos),
        arquivo
    }
	Utils.notify('Compilando arquivo...')
    local resultado = vim.fn.system(comando)
    if vim.v.shell_error > 0 then
        Utils.notify(resultado)
        do return end
    end
	Utils.notify('Arquivo pdf compilado!')
	self.pdf.abrir(arquivo)
end

Utils.Ouvidoria = Ouvidoria

return Utils

