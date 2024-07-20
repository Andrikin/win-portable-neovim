---@class Utils
---@field Diretorio Diretorio
---@field SauceCodePro SauceCodePro
---@field Registrador Registrador
---@field Curl Curl
---@field OPT Diretorio
---@field win7 string | nil
local Utils = {}

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

Programa.baixado = false

Programa.extraido = false

Programa.finalizado = false

Programa.timeout = 120 * 1000

Programa.__tostring = function(self)
    return self:diretorio().diretorio
end

---@return Diretorio diretorio
Programa.diretorio = function(self)
    return Utils.OPT / self.nome
end

---@return string nome
Programa.nome_arquivo = function(self)
	return vim.fn.fnamemodify(self.link, ':t')
end

---@return string ext
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
                print(string.format('Tempo para download excedido. Encerrando download de %s', self.nome))
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
                print(string.format('Tempo para extração excedido. Encerrando extração de %s', self.nome))
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
        Utils.notify(string.format('Programa: Algum erro ocorreu ao realizar a instalação do programa %s.', self.nome))
        do return end
    end
    if not self:registrar() then
        Utils.notify(string.format('Programa: instalar: Não foi possível realizar a instalação do programa %s.', self.nome))
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
        Utils.notify(string.format('Programa: registrar_path: Programa %s já registrado no sistema!', self.nome))
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
    Utils.notify(string.format('Programa: registrar_path: Programa %s registrado no PATH do sistema.', self.nome))
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
        do return end
    end
    self:criar_diretorio()
    self:checar_instalacao()
    if not self.baixado and not self.extraido then
        self:baixar()
    elseif not self.extraido then
        self:extrair()
    else
        Utils.notify(string.format('Programa: Algum erro ocorreu ao realizar a instalação do programa %s.', self.nome))
        do return end
    end
    if not self:registrar() then
        Utils.notify(string.format('Programa: instalar: Não foi possível realizar a instalação do programa %s.', self.nome))
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
Curl.download = function(link, diretorio)
	vim.validate({
		link = {link, 'string'},
		diretorio = {diretorio, 'string'}
	})
	if link == '' or diretorio == '' then
		error('Curl: download: Variável nula')
	end
	local arquivo = vim.fn.fnamemodify(link, ':t')
	diretorio = tostring(Utils.Diretorio.new(diretorio) / arquivo)
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
		Utils.notify(string.format('Curl: download: Arquivo %s baixado!', arquivo))
	else
		Utils.notify(string.format('Curl: download: Não foi possível realizar o download do arquivo %s!', arquivo))
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
		error('Curl: extrair: Variárvel nula.')
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
            Utils.notify(string.format('Curl: extrair: Arquivo %s extraído com sucesso!', nome))
        else
            Utils.notify(string.format('Curl: extrair: Erro encontrado! Não foi possível extrair o diretorio_arquivo %s', nome))
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

-- TODO: FINALIZAR
---@param programas table Lista dos programas que são dependência para o nvim
Registrador.iniciar = function(programas)
    for i, programa in ipairs(programas) do
        if getmetatable(programa) ~= Utils.Programa then
            programas[i] = setmetatable(programa, Utils.Programa)
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

Utils.PROJETOS = Utils.Diretorio.new(vim.fn.fnamemodify(vim.env.HOME, ':h')) / 'projetos'

---WARNING: classe para instalar as credenciais .ssh
---@class Ssh
---@field destino Diretorio
---@field arquivos table
local Ssh = {}

Ssh.__index = Ssh

Ssh.destino = Utils.Diretorio.new(vim.env.HOME) / '.ssh'

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
        self.desempacotar()
    else
        Utils.notify("Ssh: encontrado diretório '.ssh'.")
    end
end

Ssh.desempacotar = function(self)
    for _, arquivo in ipairs(self.arquivos) do
        vim.fn.system({-- TODO: rever segundo argumento da função 'system'
            'printf.exe',
            arquivo.valor,
            '|',
            'base64.exe',
            '-d',
            '>',
            (self.destino / arquivo.nome).diretorio,
        })
    end
end

---@return Ssh
Ssh.new = function()
    local ssh = setmetatable({}, Ssh)
    return ssh
end

Utils.Ssh = Ssh

return Utils

