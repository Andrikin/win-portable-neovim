---@class Utils
---@field Diretorio Diretorio
---@field SauceCodePro SauceCodePro
---@field Registrador Registrador
---@field Curl Curl
---@field OPT Diretorio
---@field win7 string | nil
local Utils = {}

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

---@class Curl
---@field unzip_link string Url para download de unzip.exe
local Curl = {}

Curl.__index = Curl

Curl.new = function()
    if vim.fn.executable('curl') == 0 then -- verificar se curl está instalado no sistema
        error('curl: instalado: Não foi encontrado curl no sistema. Verificar e realizar a instalação do curl neste computador!\nLink para download: https://curl.se/windows/latest.cgi?p=win64-mingw.zip')
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
		Utils.notify('Curl: bootstrap: Sistema não possui tar.exe! Realizar a instalação do programa.')
		do return end
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

---@param cfg table
Registrador.config = function(self, cfg)
	self.deps = cfg
end

--- Verifica se o programa já está no PATH, busca pelo executável e 
--- realiza o registro no PATH do sistema
---@param programa table
---@return boolean
Registrador.registrar = function(self, programa)
	local diretorio = self.diretorio / programa.nome
	local registrado = vim.env.PATH:match(diretorio.diretorio:gsub('[\\-]', '.'))
	if registrado then
		Utils.notify(string.format('Opt: registrar_path: Programa %s já registrado no sistema!', programa.nome))
		return true
	end
	local limite = vim.tbl_islist(programa.cmd) and #programa.cmd or 1
	local executaveis = vim.fs.find(programa.cmd, {path = diretorio.diretorio, type = 'file', limit = limite})
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

Registrador.init = function(self)
	for _, programa in ipairs(self.deps) do
		local diretorio = self.diretorio / programa.nome
		local arquivo = vim.fn.fnamemodify(programa.link, ':t')
        local executavel = arquivo:match('%.([^_-.]+)$') == 'exe'
        local download = self.diretorio / arquivo
		local registrado = self:registrar(programa)
		if not registrado then
			local download_realizado = vim.fn.getftype(download.diretorio) ~= ''
			local extraido = #vim.fn.glob(tostring(diretorio / '*'), false, true) ~= 0
			if not download_realizado then
				Utils.Curl.download(programa.link, self.diretorio.diretorio)
                download_realizado = true
			else
				Utils.notify(string.format('Opt: init: Arquivo %s já download_realizado.', arquivo))
			end
			if not extraido and download_realizado then
				-- criar diretório para extrair arquivo
				if vim.fn.isdirectory(diretorio.diretorio) == 0 then
					vim.fn.mkdir(diretorio.diretorio, 'p', 0700)
				end
                Utils.Curl.extrair(download.diretorio, diretorio.diretorio)
			else
				Utils.notify(string.format('Opt: init: Arquivo %s já extraído.', arquivo))
			end
			if download_realizado and registrado then
                if executavel then
                    vim.fn.rename(tostring(download), tostring(diretorio / arquivo)) -- mover arquivo para a pasta dele
                else
                    vim.fn.delete(tostring(download)) -- remover arquivo comprimido baixado
                end
			end
			registrado = self:registrar(programa)
		end
	end
end

---@param cfg table
Registrador.setup = function(self, cfg)
	self:config(cfg)
	self:init()
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

return Utils
