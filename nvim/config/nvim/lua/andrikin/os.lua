---@diagnostic disable: need-check-nil
-- BOOTSTRAP: baixar win-portable-neovim, baixar neovim.zip, baixar neovim-qt.zip, extrair tudo na mesmo diretório

-- INFO: Lista de links para download das dependências:
-- curl: https://curl.se/windows/latest.cgi?p=win64-mingw.zip
-- unzip: http://linorg.usp.br/CTAN/systems/win32/w32tex/unzip.exe
-- w64devkit-compiler: https://github.com/skeeto/w64devkit/releases/download/v1.21.0/w64devkit-1.21.0.zip -- removido em favor do cygwin
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
-- cmail: https://www.inveigle.net/downloads/CMail_0.8.11_x86.zip
-- rust: TODO

-- LSPs:
-- javascript: (deno 1.27.0 Windows 7) https://github.com/denoland/deno/releases/download/v1.27.0/deno-x86_64-pc-windows-msvc.zip
-- lua: https://github.com/LuaLS/lua-language-server/releases/download/3.7.3/lua-language-server-3.7.3-win32-x64.zip
-- emmet: npm install -g emmet-ls
-- python: pip install pyright | npm -g install pyright
-- rust: TODO

-- TODO: Para downloads no github, utilizar API para baixar o arquivo mais recente:
-- https://api.github.com/repos/<usuario>/<repositorio>/releases/latest

if vim.loader then vim.loader.enable() end

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
            require('andrikin.lazy') -- plugins neovim
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
		config = function() require('andrikin.utils').Python:init() end,
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
		link = 'https://dlcdn.apache.org/maven/maven-3/3.9.6/binaries/apache-maven-3.9.6-bin.zip',
		cmd = 'mvn.cmd'
	},{
		nome = 'jq',
		link = 'https://github.com/jqlang/jq/releases/download/jq-1.7.1/jq-windows-i386.exe',
		cmd = {'jq.exe', 'jq-windows-i386.exe'},
        config = function() require('andrikin.utils').Jq:init() end,
	},{
        nome = 'tree-sitter',
        link = 'https://github.com/tree-sitter/tree-sitter/releases/download/v0.25.5/tree-sitter-windows-x64.gz',
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
    }
}

Registrador.iniciar(programas)
Ssh:bootstrap()
Git:bootstrap()

