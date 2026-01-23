-- Inicializar variavel de ambiente para remote server (Windows 11)
local copyq = '\\\\.\\pipe\\copyq'
local servers = vim.fn.serverlist()
local encontrado = false
for _, server in ipairs(servers) do
    if server == copyq then
        encontrado = true
        break
    end
end
if not encontrado then
    vim.fn.serverstart(copyq)
end


-- IMPORTANT(Windows 10+): Desabilitar python.exe e python3.exe em "Gerenciar aliases de execução de aplicativo".
-- Windows executa este alias antes de executar python declarado em PATH.
-- ALTERNATIVE FIX: Remover WindowsApps do PATH
local desabilitar = require('andrikin.utils').remover_path
for _, programa in ipairs({'WindowsApps', 'Oracle', 'LibreOffice'}) do
    desabilitar(programa)
end

require('andrikin.utils').init()

---@type Registrador
local Registrador = require('andrikin.utils').Registrador.new()
---@type Ssh
local Ssh = require('andrikin.utils').Ssh.new()
---@type Git
local Git = require('andrikin.utils').Git.new()
---@type SauceCodePro
local _ = require('andrikin.utils').SauceCodePro.new()

local programas = {
	{
        nome = 'cygwin',
        link = 'https://cygwin.com/setup-x86_64.exe',
        cmd = 'setup-x86_64.exe',
        config = function() require('andrikin.utils').Cygwin:init() end,
    },{
		nome = 'git',
		link = 'https://github.com/git-for-windows/git/releases/download/v2.43.0.windows.1/MinGit-2.43.0-64-bit.zip',
		cmd = 'git.exe',
        config = function()
            require('andrikin.utils').Ouvidoria.ci:init() -- modelos latex
        end,
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
		config = function() require('andrikin.utils').Sumatra:init() end,
	},{
		nome = 'node',
		link = 'https://nodejs.org/dist/v20.10.0/node-v20.10.0-win-x64.zip',
		cmd = 'node.exe',
		config = function() require('andrikin.utils').Node:init() end,
	},{
		nome = 'python',
		link = 'https://www.python.org/ftp/python/3.12.2/python-3.12.2-embed-amd64.zip',
		cmd = {'python.exe', 'pip.exe'},
		config = function() 
            require('andrikin.utils').Python:init()
            require('andrikin.utils').Msvc:instalacao()
        end,
    },{
		nome = 'tectonic',
		link = 'https://github.com/tectonic-typesetting/tectonic/releases/download/tectonic%400.14.1/tectonic-0.14.1-x86_64-pc-windows-msvc.zip',
		cmd = 'tectonic.exe',
	},{
		nome = 'texlab-latex-lsp',
		link = 'https://github.com/latex-lsp/texlab/releases/download/v5.22.1/texlab-x86_64-windows.zip',
		cmd = 'texlab.exe'
	},{
		nome = 'deno-javascript-lsp',
		link = 'https://github.com/denoland/deno/releases/download/v2.1.3/deno-x86_64-pc-windows-msvc.zip',
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
		link = 'https://dlcdn.apache.org/maven/maven-4/4.0.0-rc-5/binaries/apache-maven-4.0.0-rc-5-bin.zip',
		cmd = 'mvn.cmd'
	},{
		nome = 'jq',
		link = 'https://github.com/jqlang/jq/releases/download/jq-1.7.1/jq-windows-i386.exe',
		cmd = {'jq.exe', 'jq-windows-i386.exe'},
        config = function() require('andrikin.utils').Jq:init() end,
	},{
        nome = 'tree-sitter',
        link = 'https://github.com/tree-sitter/tree-sitter/releases/download/v0.25.8/tree-sitter-windows-x64.gz',
        cmd = {'tree-sitter.exe', 'tree-sitter-windows-x64'},
        config = function() require('andrikin.utils').TreeSitter:init() end,
    },{
		nome = 'sqlite',
		link = 'https://www.sqlite.org/2024/sqlite-tools-win-x64-3460000.zip',
		cmd = 'sqlite3.exe',
    },{
        nome = 'gradle',
        link = 'https://services.gradle.org/distributions/gradle-8.10.2-bin.zip',
        cmd = 'gradle.bat',
    },{
        nome = 'pandoc',
        link = 'https://github.com/jgm/pandoc/releases/download/3.5/pandoc-3.5-windows-x86_64.zip',
        cmd = 'pandoc.exe',
    },{
        nome = 'cmail',
        link = 'https://www.inveigle.net/downloads/CMail_0.8.11_x86.zip',
        cmd = 'cmail.exe',
    },{
        nome = 'lessmsi', -- Utilizar o lessmsi-gui.exe
        link = 'https://github.com/activescott/lessmsi/releases/download/v2.7.3/lessmsi-v2.7.3.zip',
        cmd = 'lessmsi.exe',
    },{
        nome = 'unzip', -- https://infozip.sourceforge.net/
        link = 'https://linorg.usp.br/CTAN/systems/windows/w32tex/unzip.exe',
        cmd = 'unzip.exe',
    },{
        nome = 'rust',
        link = 'https://static.rust-lang.org/dist/rust-nightly-x86_64-pc-windows-msvc.msi',
        cmd = 'cargo.exe',
    },{
        nome = 'rust-analyzer',
        link = 'https://github.com/rust-lang/rust-analyzer/releases/download/2026-01-19/rust-analyzer-aarch64-pc-windows-msvc.zip',
        cmd = 'rust-analyzer.exe',
    }
}

Registrador.iniciar(programas)
Ssh:bootstrap()
Git:bootstrap()

