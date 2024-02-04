---@class Utils
---@field Diretorio Diretorio
local Utils = {}

---@class Diretorio
---@field _sep string Separador de pastas no caminho do diretório
---@field nome string Caminho completo do diretório
local Diretorio = {}

Diretorio.__index = Diretorio

Diretorio._sep = '\\'

Diretorio.nome = ''

---@param diretorio string | table
---@return Diretorio
Diretorio.new = function(self, diretorio)
	vim.validate({diretorio = {diretorio, {'table', 'string'}}})
	if type(diretorio) == 'table' then
		for _, valor in ipairs(diretorio) do
			if type(valor) ~= 'string' then
				error('Diretorio: new: Elemento de lista diferente de "string"!')
			end
		end
	end
	local obj = {}
	setmetatable(obj, self)
	if type(diretorio) == 'table' then
		local concatenar = diretorio[1]
		for i=2,#diretorio do
			concatenar = concatenar .. obj._suffix(diretorio[i])
		end
		diretorio = concatenar
	end
	obj.nome = self._sanitize(diretorio)
	return obj
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

---@param diretorio string | table
Diretorio.add = function(self, diretorio)
	if type(diretorio) == 'table' then
		local concatenar = ''
		for _, p in ipairs(diretorio) do
			concatenar = concatenar .. self._suffix(p)
		end
		diretorio = concatenar
	end
	self.nome = self.nome .. self._suffix(diretorio)
end

---@param other Diretorio | string
---@return Diretorio
Diretorio.__div = function(self, other)
    local nome = self.nome
	if getmetatable(other) == Diretorio then
        other = other.nome
    elseif type(other) ~= 'string' then
		error('Diretorio: __div: Elementos precisam ser do tipo "string".')
	end
	return Diretorio:new(self._sanitize(nome .. self._suffix(other)))
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
	return self._sanitize(self.nome .. self._suffix(str))
end

---@return string
Diretorio.__tostring = function(self)
	return self.nome
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

Utils.npcall = vim.F.npcall

Utils.Diretorio = Diretorio

return Utils
