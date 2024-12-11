-- BOOTSTRAP: baixar win-portable-neovim, baixar neovim.zip, baixar neovim-qt.zip, extrair tudo na mesmo diretório

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
-- Java: https://services.gradle.org/distributions/gradle-8.10.2-bin.zip
-- Jdtls: https://www.eclipse.org/downloads/download.php?file=/jdtls/snapshots/jdt-language-server-latest.tar.gz
-- Maven: https://dlcdn.apache.org/maven/maven-3/3.9.6/binaries/apache-maven-3.9.6-bin.zip
-- sqlite: https://www.sqlite.org/2024/sqlite-tools-win-x64-3460000.zip
-- Himalaya: https://github.com/pimalaya/himalaya/releases/download/v1.0.0-beta.4/himalaya.x86_64-windows.zip -- e-mail cli
-- fzf: https://github.com/junegunn/fzf/releases/download/v0.56.3/fzf-0.56.3-windows_amd64.zip
-- pandoc: https://github.com/jgm/pandoc/releases/download/3.5/pandoc-3.5-windows-x86_64.zip
-- cygwin: https://cygwin.com/setup-x86_64.exe -- replace w64devkit?
-- rust: TODO

-- LSPs:
-- javascript: (deno 1.27.0 Windows 7) https://github.com/denoland/deno/releases/download/v1.27.0/deno-x86_64-pc-windows-msvc.zip
-- lua: https://github.com/LuaLS/lua-language-server/releases/download/3.7.3/lua-language-server-3.7.3-win32-x64.zip
-- emmet: npm install -g emmet-ls
-- python: pip install pyright | npm -g install pyright
-- rust: TODO

-- IMPORTANT(Windows 10+): Desabilitar python.exe e python3.exe em "Gerenciar aliases de execução de aplicativo".
-- Windows executa este alias antes de executar python declarado em PATH.
-- ALTERNATIVE FIX: Remover WindowsApps do PATH
local desabilitar = require('andrikin.utils').remover_path
for _, programa in ipairs({'WindowsApps', 'Oracle', 'LibreOffice'}) do
    desabilitar(programa)
end

local npcall = require('andrikin.utils').npcall
local notify = require('andrikin.utils').notify
local win7 = require('andrikin.utils').win7
---@type Registrador
local Registrador = require('andrikin.utils').Registrador.new()
---@type Ssh
local Ssh = require('andrikin.utils').Ssh.new()
---@type Git
local Git = require('andrikin.utils').Git.new()
---@type Curl
local Curl = require('andrikin.utils').Curl.new()
---@type SauceCodePro
local _ = require('andrikin.utils').SauceCodePro.new()
---@type Diretorio
local Diretorio = require('andrikin.utils').Diretorio
---@type Diretorio
local Opt = require('andrikin.utils').Opt

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
		cmd = {'sumatra.exe', 'SumatraPDF-3.5.2-64.exe'},
		config = function()
			local diretorio = Opt / 'sumatra'
			local executavel = vim.fn.glob(tostring(diretorio / 'sumatra*.exe'))
			if executavel ~= '' then
				if vim.fn.fnamemodify(executavel, ':t') == 'sumatra.exe' then
					notify('Arquivo Sumatra já renomeado.')
					do return end
				end
                notify('Renomeando executável Sumatra.')
				vim.fn.rename(
                    executavel,
                    tostring(diretorio / 'sumatra.exe')
                )
			else
				notify('Não foi encontrado executável Sumatra.')
			end
		end
	},{
		nome = 'node',
		link = win7 and 'https://nodejs.org/dist/v13.14.0/node-v13.14.0-win-x64.zip' or 'https://nodejs.org/dist/v20.10.0/node-v20.10.0-win-x64.zip',-- v12.22.12(win7)?
		cmd = 'node.exe',
		config = function()
			local installed = function(pacote) -- checar se diretório existe
				return not vim.tbl_isempty(vim.fs.find(pacote, {path = tostring(Opt / 'node'), type = 'directory'}))
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
                        notify(('Instalando pacote node: %s'):format(plugin))
						vim.fn.system({
							'npm',
							'install',
							'-g',
							plugin
						})
                        if vim.v.shell_error ~= 0 then
                            notify(('Aconteceu um erro ao instalar o programa %s'):format(plugin))
                        end
                    else
                        notify(('Pacote node já instalado %s'):format(plugin))
					end
				end
			end
            if not vim.g.node_host_prog or vim.g.node_host_prog == '' then
                local node_neovim = (Diretorio.new()).buscar({
                    'node_modules',
                    'neovim',
                    'bin'
                }, Opt.diretorio)
                if node_neovim then
                    vim.g.node_host_prog = (node_neovim / 'cli.js').diretorio
                else
                    notify('Não foi possível configurar vim.g.node_host_prog')
                end
            end
		end
	},{
		nome = 'python',
		link = win7 and 'https://www.python.org/ftp/python/3.8.9/python-3.8.9-embed-amd64.zip' or 'https://www.python.org/ftp/python/3.12.2/python-3.12.2-embed-amd64.zip',
		cmd = {'python.exe', 'pip.exe'},
		config = function()
			-- INFO: Na primeira instalação, baixar get-pip.py e modificar o arquivo python38._pth
			-- descomentando a linha 4
			local get_pip = {}
			get_pip.link =  'https://bootstrap.pypa.io/get-pip.py'
			get_pip.nome = vim.fn.fnamemodify(get_pip.link, ':t')
			get_pip.diretorio = Opt / 'python'
			get_pip.pth = win7 and 'python38._pth' or 'python312._pth'
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
                local pth = tostring(self.diretorio / self.pth)
                if vim.fn.filereadable(pth) ~= 0 then
                    vim.fn.writefile({'import site'}, pth, 'a')
                end
				-- download get-pip.py
				if not vim.fs.find(self.nome, {path = self.diretorio.diretorio, type = 'file'})[1] then
					Curl.download(self.link, self.diretorio.diretorio)
				end
				-- executar get-pip.py
				if vim.fn.executable('pip.exe') == 0 then
					notify(('Executando "%s".'):format(self.nome))
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
						notify(('Instalando pacote python %s.'):format(pacote))
						vim.fn.system({
							'pip.exe',
							'install',
							pacote
						})
					else
						notify(('Pacote python %s já instalado.'):format(pacote))
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
		link = 'https://github.com/LuaLS/lua-language-server/releases/download/3.10.0/lua-language-server-3.10.0-win32-x64.zip',
		cmd = 'lua-language-server.exe'
	},{
		nome = 'java',
		link = 'https://download.java.net/java/GA/jdk21.0.1/415e3f918a1f4062a0074a2794853d0d/12/GPL/openjdk-21.0.1_windows-x64_bin.zip', -- openjdk
		cmd = 'java.exe'
	},{
		nome = 'jdtls-java-lsp',
		link = 'https://download.eclipse.org/jdtls/snapshots/jdt-language-server-latest.tar.gz',
		cmd = 'jdtls'
	},{
		nome = 'maven',
		link = 'https://dlcdn.apache.org/maven/maven-3/3.9.6/binaries/apache-maven-3.9.6-bin.zip',
		cmd = 'mvn.cmd'
	},{
		nome = 'jq',
		link = 'https://github.com/jqlang/jq/releases/download/jq-1.7.1/jq-windows-i386.exe',
		cmd = {'jq.exe', 'jq-windows-i386.exe'},
        config = function()
			local diretorio = Opt / 'jq'
			local executavel = vim.fn.glob(tostring(diretorio / 'jq*.exe'))
			if executavel ~= '' then
				if vim.fn.fnamemodify(executavel, ':t') == 'jq.exe' then
					notify('Arquivo jq já renomeado.')
					do return end
				end
                notify('Renomeando executável jq.')
                vim.fn.rename(
                    executavel,
                    tostring(diretorio / 'jq.exe')
                )
			else
				notify('Não foi encontrado executável jq.')
			end
        end,
	},{
        nome = 'tree-sitter',
        link = 'https://github.com/tree-sitter/tree-sitter/releases/download/v0.22.6/tree-sitter-windows-x64.gz',
        cmd = {'tree-sitter.exe', 'tree-sitter-windows-x64'},
        config = function()
			local diretorio = Opt / 'tree-sitter'
			local executavel = vim.fn.glob(tostring(diretorio / 'tree-sitter*'))
			if executavel ~= '' then
				if vim.fn.fnamemodify(executavel, ':t') == 'tree-sitter.exe' then
					notify('Arquivo tree-sitter já renomeado.')
					do return end
				end
                notify('Renomeando executável tree-sitter.')
				vim.fn.rename(
                    executavel,
                    (diretorio / 'tree-sitter.exe').diretorio
				)
			else
				notify('Não foi encontrado executável jq.')
			end
        end,
    },{
		nome = 'sqlite',
		link = 'https://www.sqlite.org/2024/sqlite-tools-win-x64-3460000.zip',
		cmd = 'sqlite3.exe',
    },{
        nome = 'gradle',
        link = 'https://services.gradle.org/distributions/gradle-8.10.2-bin.zip',
        cmd = 'gradle.bat',
    },{
        nome = 'himalaya',
        link = 'https://github.com/pimalaya/himalaya/releases/download/v1.0.0-beta.4/himalaya.x86_64-windows.zip',
        cmd = 'himalaya.exe',
        config = require('andrikin.utils').Himalaya.init
    },{
        nome = 'fzf',
        link = 'https://github.com/junegunn/fzf/releases/download/v0.56.3/fzf-0.56.3-windows_amd64.zip',
        cmd = 'fzf.exe',
    },{
        nome = 'pandoc',
        link = 'https://github.com/jgm/pandoc/releases/download/3.5/pandoc-3.5-windows-x86_64.zip',
        cmd = 'pandoc.exe',
    },{
        nome = 'cygwin',
        link = 'https://cygwin.com/setup-x86_64.exe',
        cmd = 'mintty.exe',
        config = require('andrikin.utils').Cygwin.init
    }
}

Registrador.iniciar(programas)
Ssh:bootstrap()
Git:bootstrap()

