-- INFO: Lista de links para download das dependências:
-- curl: https://curl.se/windows/latest.cgi?p=win64-mingw.zip
-- unzip: http://linorg.usp.br/CTAN/systems/win32/w32tex/unzip.exe
-- w64devkit-compiler: https://github.com/skeeto/w64devkit/releases/download/v1.21.0/w64devkit-1.21.0.zip
-- git: https://github.com/git-for-windows/git/releases/download/v2.43.0.windows.1/Git-2.43.0-64-bit.tar.bz2 -- Full Version
-- git: https://github.com/git-for-windows/git/releases/download/v2.43.0.windows.1/MinGit-2.43.0-64-bit.zip -- Minimal Version
-- fd: https://github.com/sharkdp/fd/releases/download/v8.7.1/fd-v8.7.1-x86_64-pc-windows-gnu.zip
-- ripgrep: https://github.com/BurntSushi/ripgrep/releases/download/14.0.3/ripgrep-14.0.3-i686-pc-windows-msvc.zip
-- sumatra: https://www.sumatrapdfreader.org/dl/rel/3.5.2/SumatraPDF-3.5.2-64.zip
-- node: https://nodejs.org/dist/v20.10.0/node-v20.10.0-win-x64.zip
-- HOW PORTABLE PYTHON: https://chrisapproved.com/blog/portable-python-for-windows.html
-- python 3.8.9 (Windows 7): https://www.python.org/ftp/python/3.8.9/python-3.8.9-embed-amd64.zip
-- python 3.12.1: https://www.python.org/ftp/python/3.12.1/python-3.12.1-embed-amd64.zip
-- pip installer: https://bootstrap.pypa.io/get-pip.py
-- TinyTex: https://github.com/rstudio/tinytex-releases/releases/download/v2023.12/TinyTeX-1-v2023.12.zip
-- TinyTex: https://yihui.org/tinytex/
-- Tectonic: https://github.com/tectonic-typesetting/tectonic/releases/download/tectonic%400.14.1/tectonic-0.14.1-x86_64-pc-windows-msvc.zip
-- Java: https://download.oracle.com/java/21/latest/jdk-21_windows-x64_bin.zip -- oracle
-- Java: https://download.java.net/java/GA/jdk21.0.1/415e3f918a1f4062a0074a2794853d0d/12/GPL/openjdk-21.0.1_windows-x64_bin.zip -- openjdk
-- Jdtls: https://www.eclipse.org/downloads/download.php?file=/jdtls/snapshots/jdt-language-server-latest.tar.gz
-- Maven: https://dlcdn.apache.org/maven/maven-3/3.9.6/binaries/apache-maven-3.9.6-bin.zip
-- rust: TODO

-- LSPs:
-- javascript: (deno 1.27.0 Windows 7) https://github.com/denoland/deno/releases/download/v1.27.0/deno-x86_64-pc-windows-msvc.zip
-- lua: https://github.com/LuaLS/lua-language-server/releases/download/3.7.3/lua-language-server-3.7.3-win32-x64.zip
-- emmet: npm install -g emmet-ls
-- python: pip install pyright | npm -g install pyright
-- rust: TODO

-- WIP: Utilizar multithreads para realizar os downloads

-- IMPORTANT(Windows 10+): Desabilitar python.exe e python3.exe em "Gerenciar aliases de execução de aplicativo".
-- Windows executa este alias antes de executar python declarado em PATH.
-- ALTERNATIVE FIX: Remover WindowsApps do PATH
local desabilitar_path = require('andrikin.utils').remover_path
for _, programa in ipairs({'WindowsApps', 'Oracle'}) do
    desabilitar_path(programa)
end

local npcall = require('andrikin.utils').npcall
local notify = require('andrikin.utils').notify
local win7 = require('andrikin.utils').win7
---@type Curl
local Curl = require('andrikin.utils').Curl.new()
---@type SauceCodePro
local SauceCodePro = require('andrikin.utils').SauceCodePro.new()
SauceCodePro:setup()
---@type Registrador
local Registrador = require('andrikin.utils').Registrador.new()
---@type Diretorio
local OPT = require('andrikin.utils').OPT

require('andrikin.utils'):bootstrap()

local programas = {
	{
		nome = 'w64devkit',
		link = 'https://github.com/skeeto/w64devkit/releases/download/v1.21.0/w64devkit-1.21.0.zip',
		cmd = 'gcc.exe'
	},{
		nome = 'git',
		link = 'https://github.com/git-for-windows/git/releases/download/v2.43.0.windows.1/MinGit-2.43.0-64-bit.zip',
		cmd = 'git.exe'
	},{
		nome = 'fd',
		link = 'https://github.com/sharkdp/fd/releases/download/v8.7.1/fd-v8.7.1-x86_64-pc-windows-gnu.zip',
		cmd = 'fd.exe'
	},{
		nome = 'ripgrep',
		link = 'https://github.com/BurntSushi/ripgrep/releases/download/14.0.3/ripgrep-14.0.3-i686-pc-windows-msvc.zip',
		cmd = 'rg.exe'
	},{
		nome = 'sumatra',
		link = 'https://www.sumatrapdfreader.org/dl/rel/3.5.2/SumatraPDF-3.5.2-64.zip',
		cmd = 'sumatra.exe',
		config = function()
			local diretorio = OPT / 'sumatra'
			local executavel = vim.fn.glob(tostring(diretorio / 'sumatra*.exe'))
			if executavel ~= '' then
				if vim.fn.fnamemodify(executavel, ':t') == 'sumatra.exe' then
					notify('Arquivo Sumatra já renomeado.')
					do return end
				end
                notify('Renomeando executável Sumatra.')
				vim.fn.system({
					'mv',
					executavel,
					diretorio .. 'sumatra.exe'
				})
			else
				notify('Não foi encontrado executável Sumatra.')
			end
		end
	},{
		nome = 'node',
		link = 'https://nodejs.org/dist/v20.10.0/node-v20.10.0-win-x64.zip',
		cmd = 'node.exe',
		config = function()
			local installed = function(pacote) -- checar se diretório existe
				return not vim.tbl_isempty(vim.fs.find(pacote, {path = tostring(OPT / 'node'), type = 'directory'}))
			end
			-- configurações extras
			if win7 and vim.env.NODE_SKIP_PLATFORM_CHECK ~= 1 then
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
					if not installed(plugin) then
                        notify(string.format('Instalando pacote node: %s', plugin))
						vim.fn.system({
							'npm',
							'install',
							'-g',
							plugin
						})
                        if vim.v.shell_error ~= 0 then
                            notify('Aconteceu um erro ao instalar o programa %s', plugin)
                        end
                    else
                        notify(string.format('Pacote node já instalado %s', plugin))
					end
				end
			end
		end
	},{
		nome = 'python',
		link = 'https://www.python.org/ftp/python/3.8.9/python-3.8.9-embed-amd64.zip',
		cmd = {'python.exe', 'pip.exe'},
		config = function()
			-- INFO: Na primeira instalação, baixar get-pip.py e modificar o arquivo python38._pth
			-- descomentando a linha 4
			local get_pip = {}
			get_pip.link =  'https://bootstrap.pypa.io/get-pip.py'
			get_pip.nome = vim.fn.fnamemodify(get_pip.link, ':t')
			get_pip.diretorio = OPT / 'python'
			get_pip.instalado = function(self)
				local pip = vim.fs.find('pip.exe', {path = tostring(self.diretorio), type = 'file'})[1]
				if not pip then
					return nil
				end
				return npcall(
					vim.fn.fnamemodify,
					pip,
					':h'
				)
			end
			get_pip.instalar = function(self)
				if vim.fn.executable('sed') == 1 then
					if vim.fn.executable('pip.exe') == 0 then
						vim.fn.system({
							'sed',
							'-i',
							'$s/^#\\(.*\\)$/\\1/',
							tostring(self.diretorio / 'python38._pth') -- versão 3.8.9
						})
					end
				else
					notify('"sed" não encontrado nas dependências. Abortando configuração de python.')
					do return end
				end
				-- download get-pip.py
				if not vim.fs.find(self.nome, {path = self.diretorio.diretorio, type = 'file'})[1] then
					Curl.download(self.link, self.diretorio.diretorio)
				end
				-- executar get-pip.py
				if vim.fn.executable('pip.exe') == 0 then
					notify(string.format('Executando "%s".', self.nome))
					vim.fn.system({
						'python.exe',
						tostring(self.diretorio / self.nome)
					})
				else
					notify('Instalação de "pip.exe" encontrou um erro.')
					do return end
				end
			end
			if not get_pip:instalado() then
				get_pip:instalar()
				-- instalar lsp
				local pip = vim.fn.fnamemodify(vim.fs.find('pip.exe', {path = get_pip.diretorio.diretorio, type = 'file'})[1], ':h')
				if pip then
					vim.env.PATH = vim.env.PATH .. ';' .. pip
				else
					notify('Erro ao registrar "pip.exe" na variável de ambiente PATH.')
					do return end
				end
			end
			if vim.fn.executable('pip.exe') == 1 then
				local instalar = function(pacote)
					local instalado = vim.fs.find(pacote, {path = get_pip.diretorio.diretorio, type = 'directory'})[1]
					if not instalado then
						notify(string.format('Instalando pacote python %s.', pacote))
						vim.fn.system({
							'pip.exe',
							'install',
							pacote
						})
					else
						notify(string.format('Pacote python %s já instalado.', pacote))
					end
				end
				instalar('pyright')
				instalar('pynvim')
				instalar('greenlet')
			else
				notify('"pip.exe" não encontrado. Falha na instalação.')
				do return end
			end
			vim.g.python3_host_prog = vim.fs.find('python.exe', {path = get_pip.diretorio.diretorio, type = 'file'})[1]
			if not vim.g.python3_host_prog or vim.g.python3_host_prog == '' then
				notify('Variável python3_host_prog não configurado.')
			end
		end
	},{
		nome = 'tectonic',
		link = 'https://github.com/tectonic-typesetting/tectonic/releases/download/tectonic%400.14.1/tectonic-0.14.1-x86_64-pc-windows-msvc.zip',
		cmd = 'tectonic.exe',
	},{
		nome = 'texlab-latex-lsp',
		link = 'https://github.com/latex-lsp/texlab/releases/download/v5.12.1/texlab-x86_64-windows.zip',
		cmd = 'texlab.exe'
	},{
		nome = 'deno-javascript-lsp',
		link = 'https://github.com/denoland/deno/releases/download/v1.27.0/deno-x86_64-pc-windows-msvc.zip',
		cmd = 'deno.exe'
	},{
		nome = 'lua-lsp',
		link = 'https://github.com/LuaLS/lua-language-server/releases/download/3.7.3/lua-language-server-3.7.3-win32-x64.zip',
		cmd = 'lua-language-server.exe'
	},{
		nome = 'java',
		link = 'https://download.java.net/java/GA/jdk21.0.1/415e3f918a1f4062a0074a2794853d0d/12/GPL/openjdk-21.0.1_windows-x64_bin.zip', -- openjdk
		cmd = 'java.exe'
	},{
		nome = 'jdtls-java-lsp',
		link = 'https://www.eclipse.org/downloads/download.php?file=/jdtls/snapshots/jdt-language-server-latest.tar.gz',
		cmd = 'jdtls'
	},{
		nome = 'maven',
		link = 'https://dlcdn.apache.org/maven/maven-3/3.9.6/binaries/apache-maven-3.9.6-bin.zip',
		cmd = 'mvn.cmd'
	},{
		nome = 'jq',
		link = 'https://github.com/jqlang/jq/releases/download/jq-1.7.1/jq-windows-i386.exe',
		cmd = 'jq-windows-i386.exe',
	}
}

Registrador:setup(programas)

