---@class Utils
---@field Diretorio Diretorio
---@field SauceCodePro SauceCodePro
---@field Registrador Registrador
---@field Curl Curl
---@field OPT Diretorio
---@field win7 string | nil
local Utils = {}

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
    Registrador.bootstrap()
    return registrador
end

---@return string
Registrador.__tostring = function(self)
    return self.diretorio.diretorio
end

---@private
Registrador.bootstrap = function()
	-- Criar diretório, setar configurações, etc
	if vim.fn.isdirectory(tostring(Registrador)) == 0 then
		vim.fn.mkdir(tostring(Registrador), 'p', 0700)
	end
	if not vim.env.PATH:match(tostring(Registrador):gsub('[\\/-]', '.')) then
		vim.env.PATH = vim.env.PATH .. ';' .. tostring(Registrador)
	end
end

---@param cfg table
Registrador.config = function(self, cfg)
	self.deps = cfg
end

---@param programa table
---@return boolean
---Verifica se o programa já está no PATH
Registrador.registrar = function(self, programa)
	local diretorio = self.diretorio .. programa.nome
	local registrado = vim.env.PATH:match(diretorio:gsub('[\\-]', '.'))
	if registrado then
		Utils.notify(string.format('Opt: registrar_path: Programa %s já registrado no sistema!', programa.nome))
		return true
	end
	local limite = vim.tbl_islist(programa.cmd) and #programa.cmd or 1
	local executaveis = vim.fs.find(programa.cmd, {path = diretorio, type = 'file', limit = limite})
    local sem_executavel = vim.tbl_isempty(executaveis)
	if not registrado and sem_executavel then
		Utils.notify(string.format('Opt: registrar_path: Baixar programa %s e registrar no sistema.', programa.nome))
		return false
	end
	-- simplesmente adicionar ao PATH
	for _, exe in ipairs(executaveis) do
		vim.env.PATH = vim.env.PATH .. ';' .. vim.fn.fnamemodify(exe, ':h')
	end
	registrado = vim.env.PATH:match(diretorio:gsub('[\\-]', '.'))
	if registrado then
		Utils.notify(string.format('Opt: registrar_path: Programa %s registrado no PATH do sistema.', programa.nome))
		if programa.config then -- caso tenha configuração, executá-la
			Utils.notify(string.format('Opt: registrar_path: Configurando programa %s.', programa.nome))
			programa.config()
		end
	end
	return true
end

Registrador.init = function(self)
	for _, programa in ipairs(self.deps) do
		local arquivo = vim.fn.fnamemodify(programa.link, ':t')
		local diretorio = self.diretorio .. programa.nome
		local registrado = self:registrar(programa)
		if not registrado then
			local baixado = vim.fn.getftype(self.diretorio .. arquivo) ~= ''
			local extraido = #vim.fn.glob((Utils.Diretorio.new(diretorio) / '*').nome, false, true) ~= 0
			if not baixado then
				Utils.Curl.download(programa.link, self.diretorio.diretorio)
                baixado = true
			else
				Utils.notify(string.format('Opt: init: Arquivo %s já existe.', arquivo))
			end
			if not extraido and baixado then
				-- criar diretório para extrair arquivo
				if vim.fn.isdirectory(diretorio) == 0 then
					vim.fn.mkdir(diretorio, 'p', 0700)
				end
				Utils.Curl.extrair(self.diretorio .. arquivo, diretorio)
			else
				Utils.notify(string.format('Opt: init: Arquivo %s já extraído.', arquivo))
			end
			self:registrar(programa)
			-- Remover arquivo baixado (não é mais necessário) 
			if baixado then
				vim.fn.delete(self.diretorio .. arquivo)
			end
		end
	end
end

---@param cfg table
Registrador.setup = function(self, cfg)
	self:config(cfg)
	self:init()
end

-- Instalação da fonte SauceCodePro no computador
---@class SauceCodePro
---@field diretorio Diretorio Onde a fonte será instalada
---@field link string Url para download da fonte
---@field arquivo string Nome do arquivo
---@field registro Diretorio Caminho aonde será instalado a fonte no regedit do sistema
---@field fontes table Lista de fontes encontradas no sistema
local SauceCodePro = {}

SauceCodePro.__index = SauceCodePro

---@return SauceCodePro
SauceCodePro.new = function()
    local diretorio = Utils.OPT / 'fonte'
    local link = 'https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/SourceCodePro.zip'
    local fonte = setmetatable({
        diretorio = diretorio,
        link = link,
        arquivo = diretorio .. vim.fn.fnamemodify(link, ':t'),
        registro = Utils.Diretorio.new('HKCU') / 'Software' / 'Microsoft' / 'Windows NT' / 'CurrentVersion' / 'Fonts',
        fontes = vim.fn.glob(tostring(diretorio / 'SauceCodePro*.ttf'), false, true),
    }, SauceCodePro)
    SauceCodePro.bootstrap()
    return fonte
end

---@return string
SauceCodePro.__tostring = function(self)
    return self.diretorio.diretorio
end

---@private
SauceCodePro.bootstrap = function()
	if vim.fn.isdirectory(tostring(SauceCodePro)) == 0 then
		vim.fn.mkdir(tostring(SauceCodePro), 'p', 0700)
	end
	vim.api.nvim_create_user_command(
		'FonteRemover',
		SauceCodePro.remover_regedit,
		{}
	)
end

SauceCodePro.setup = function(self)
	self:bootstrap()
	if not self:instalado() then
        self:instalar()
    else
		Utils.notify('Fonte SauceCodePro já instalada.')
	end
end

---@return boolean
SauceCodePro.fonte_extraida = function(self)
	return #(vim.fn.glob(self.diretorio .. 'SauceCodePro*.ttf', false, true)) > 0
end

SauceCodePro.download = function(self)
	if vim.fn.isdirectory(tostring(self)) == 0 then
		vim.fn.mkdir(tostring(self), 'p', 0700)
	end
	-- Realizar download da fonte
	Utils.Curl.download(self.link, tostring(self))
	if not self:baixada() then
		error('Fonte: download: Não foi possível realizar o download do arquivo da fonte.')
	end
	Utils.notify('Arquivo fonte .zip baixado!')
end

---Decompressar arquivo zip
SauceCodePro.extrair = function(self)
	if not self:baixada() then
		error('Fonte: extrair: Arquivo .zip não encontrado! Realizar o download do arquivo de fonte para continuar a intalação.')
	end
	Utils.Curl.extrair(self.arquivo, tostring(self))
	if self:fonte_extraida() then
		Utils.notify('Arquivo fonte SauceCodePro.zip extraído!')
		self.fontes = vim.fn.glob(tostring(self.diretorio / 'SauceCodePro*.ttf'), false, true)
        -- remover arquivo .zip
        vim.fn.delete(self.arquivo)
	else
		error('Fonte: extrair: Não foi possível extrair os arquivo de fonte.')
	end
end

---Verificando se a fonte está intalada no computador
---@return boolean
SauceCodePro.instalado = function(self)
	local lista = vim.tbl_filter(
		function(elemento)
			return elemento:match('SauceCodePro')
		end,
		vim.fn.systemlist({
			'reg',
			'query',
			self.registro.diretorio,
			'/s'
	}))
	return #lista > 0
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

---@return boolean
SauceCodePro.baixada = function(self)
    return vim.fn.getftype(self.arquivo) ~= ''
end

---Desinstala a fonte do regedit do sistema Windows.
SauceCodePro.remover_regedit = function(self)
	for _, fonte in ipairs(self.fontes) do
		local nome = vim.fn.fnamemodify(fonte, ':t')
		nome = nome:match('(.*)%..*$')
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

---Instalar a Fonte no sistema Windows.
SauceCodePro.instalar = function(self)
	if not self:fonte_extraida() then
        if not self:baixada() then
            self:download()
        end
		self:extrair()
	end
	if not self:instalado() then
		self:regedit()
		if self:instalado() then
			Utils.notify('Fonte instalada com sucesso. Reinicie o nvim para carregar a fonte.')
			vim.cmd.quit({bang = true})
		else
			Utils.notify('Erro encontrado. Verificar se é possível executar comandos no regedit.')
		end
	else
		Utils.notify('Fonte self já instalada no sistema!')
	end
end

---@class Curl
---@field unzip_link string Url para download de unzip.exe
local Curl = {}

Curl.__index = Curl

Curl.new = function()
    if vim.fn.executable('curl') == 1 then -- verificar se curl está instalado no sistema
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
	diretorio = (Utils.Diretorio.new(diretorio) / arquivo).nome
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
	if extencao == 'zip' then
		vim.fn.system({
			'unzip',
			arquivo,
			'-d',
			diretorio
		})
	elseif extencao == 'tar' then
		vim.fn.system({
			'tar',
			'-xf',
			arquivo,
			'-C',
			diretorio
		})
	end
	local nome = arquivo:match('[/\\]([^/\\]+)$') or arquivo
	if vim.v.shell_error == 0 then
		Utils.notify(string.format('Curl: extrair: Arquivo %s extraído com sucesso!', nome))
	else
		Utils.notify(string.format('Curl: extrair: Erro encontrado! Não foi possível extrair o diretorio_arquivo %s', nome))
	end
end

---@class Diretorio
---@field _sep string Separador de pastas no caminho do diretório
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
        _sep = '\\',
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
	return (str:match('^[/\\]') or str == '') and str or Diretorio._sep .. str
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

Utils.win7 = string.match(vim.loop.os_uname()['version'], 'Windows 7')

Utils.Diretorio = Diretorio

Utils.Curl = Curl

Utils.SauceCodePro = SauceCodePro

Utils.Registrador = Registrador

Utils.OPT = Utils.Diretorio.new(vim.env.NVIM_OPT)

return Utils
