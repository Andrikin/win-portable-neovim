-- MORE: 
-- lista de programas unix executáveis para Win32
-- https://sitsa.dl.sourceforge.net/project/unxutils/unxutils/current/UnxUtils.zip

local OPT = vim.env.NVIMOPT
if not vim.env.NVIMOPT then
    OPT = vim.fs.joinpath(
        vim.env.HOME,
        'nvim', 'opt'
    )
end

return {
	{
        nome = 'unzip', -- https://infozip.sourceforge.net/
        link = 'https://linorg.usp.br/CTAN/systems/windows/w32tex/unzip.exe',
    },{
        nome = 'setup-x86_64', -- cygwin
        link = 'https://cygwin.com/setup-x86_64.exe',
        config = function()
            local DIR = vim.fs.joinpath(OPT,
                vim.fs.basename('https://cygwin.com/setup-x86_64.exe'):match('^(.-)%..*$')
            )
            local PACKAGES = vim.fs.joinpath(DIR, 'packages')
            local SETUP = vim.fs.joinpath(DIR, 'setup-x86_64.exe')
            if not vim.uv.fs_stat(SETUP) then
                error('Não foi localizado cygwin. Verificar instalação!')
            end
            if not vim.uv.fs_stat(vim.fs.joinpath(DIR, 'bin')) then
                vim.system({
                    SETUP,
                    '--quiet-mode',
                    '--no-admin',
                    '--download',
                    '--local-install',
                    '--local-package-dir',
                    PACKAGES,
                    '--no-verify',
                    '--no-desktop',
                    '--no-shortcuts',
                    '--no-startmenu',
                    '--no-version-check',
                    '--no-warn-deprecated-windows',
                    '--root',
                    DIR,
                    '--only-site',
                    '--site',
                    'https://linorg.usp.br/cygwin/',
                }, {detach = true})
            end
            -- create Cygwin command
            vim.api.nvim_create_user_command("Cygwin",
                function(opts)
                    opts = opts or {}
                    local args = opts.fargs or opts
                    if not vim.islist(args) then
                        vim.print('Valores padrão encontrados no comando. Abortando.')
                        return
                    end
                    local cmd = {
                        SETUP,
                        '--quiet-mode',
                        '--no-admin',
                        '--download',
                        '--local-install',
                        '--local-package-dir',
                        PACKAGES,
                        '--no-desktop',
                        '--no-shortcuts',
                        '--no-startmenu',
                        '--no-warn-deprecated-windows',
                        '--root',
                        DIR,
                        '--only-site',
                        '--site',
                        'https://linorg.usp.br/cygwin/',
                    }
                    if args[1] == 'install' or args[1] == 'remove' then
                        if args[1] == 'install' then
                            table.insert(cmd, '--packages')
                        elseif args[1] == 'remove' then
                            table.insert(cmd, '--remove-packages')
                        end
                        for i=2,#args do
                            table.insert(cmd, args[i])
                        end
                    end
                    if args[1] == 'update' then
                        table.insert(cmd, '--upgrade-also')
                    end
                    vim.system(cmd, {text = true, detach = true}, function (out)
                        if out.code == 0 then
                            vim.print('Instalação concluída com sucesso!')
                        else
                            vim.print('Instalador cygwin encontrou um erro.')
                        end
                    end)
                end, {nargs = '+', complete = function (arg, _, _)
                    return vim.tbl_filter(function(c)
                        return c:match(arg)
                    end, {'install', 'remove', 'upgrade'})
                end}
            )
        end,
    },{
        nome = 'lessmsi', -- Utilizar o lessmsi-gui.exe
        link = 'https://github.com/activescott/lessmsi/releases/download/v2.7.3/lessmsi-v2.7.3.zip',
    },{
		nome = 'fd',
		link = 'https://github.com/sharkdp/fd/releases/download/v10.3.0/fd-v10.3.0-x86_64-pc-windows-gnu.zip',
	},{
		nome = 'rg',
		link = 'https://github.com/BurntSushi/ripgrep/releases/download/15.1.0/ripgrep-15.1.0-x86_64-pc-windows-msvc.zip',
	},{
		nome = 'SumatraPDF-3.6.1-64',
		link = 'https://www.sumatrapdfreader.org/dl/rel/3.6.1/SumatraPDF-3.6.1-64.zip',
	},{
		nome = 'node',
		link = 'https://nodejs.org/dist/v20.10.0/node-v20.10.0-win-x64.zip',
        config = function()
            local NODEDIR = vim.fs.joinpath(OPT, 'node')
            local installed = function(pacote)
                return not vim.tbl_isempty(vim.fs.find(pacote,
                    {path = NODEDIR, type = 'directory'})
                )
            end
            -- configurações extras
            local win7 = vim.uv.os_uname()['version']:match('Windows 7')
            if win7 and vim.env.NODE_SKIP_PLATFORM_CHECK ~= 1 then
                vim.env.NODE_SKIP_PLATFORM_CHECK = 1
            end
            if vim.fn.executable('npm') == 1 then
                -- NODE DEPENDENCIES
                local plugins = {
                    'neovim',
                    'emmet-ls',
                    'vim-language-server',
                    'vscode-langservers-extracted',
                }
                for _, plugin in ipairs(plugins) do
                    if not installed(plugin) then
                        vim.print(('Instalando pacote node: %s'):format(plugin))
                        vim.system({
                            'npm',
                            'install',
                            '-g',
                            plugin
                        }, {detach = true})
                    else
                        vim.print(('Pacote node já instalado %s'):format(plugin))
                    end
                end
            end
            if not vim.g.node_host_prog or vim.g.node_host_prog == '' then
                local node_neovim = vim.fs.joinpath(NODEDIR,
                    'node-v20.10.0-win-x64',
                    'node_modules',
                    'neovim',
                    'bin'
                )
                if vim.uv.fs_stat(node_neovim) then
                    -- https://github.com/neovim/neovim/issues/15308
                    vim.g.node_host_prog = vim.fs.joinpath(node_neovim, 'cli.js')
                else
                    vim.print('Não foi possível configurar vim.g.node_host_prog')
                end
            end
        end,
	},{
		nome = 'tectonic',
		link = 'https://github.com/tectonic-typesetting/tectonic/releases/download/tectonic%400.14.1/tectonic-0.14.1-x86_64-pc-windows-msvc.zip',
	},{
		nome = 'texlab',
		link = 'https://github.com/latex-lsp/texlab/releases/download/v5.25.1/texlab-x86_64-windows.zip',
	},{
		nome = 'deno',
		link = 'https://github.com/denoland/deno/releases/download/v2.1.3/deno-x86_64-pc-windows-msvc.zip',
	},{
		nome = 'lua-language-server',
		link = 'https://github.com/LuaLS/lua-language-server/releases/download/3.10.0/lua-language-server-3.18.2-win32-x64.zip',
	},{
		nome = 'java',
		link = 'https://download.java.net/java/GA/jdk26/c3cc523845074aa0af4f5e1e1ed4151d/35/GPL/openjdk-26_windows-x64_bin.zip', -- openjdk
	},{
		nome = 'jdtls',
		link = 'https://download.eclipse.org/jdtls/snapshots/jdt-language-server-latest.tar.gz',
	},{
		nome = 'mvn',
		link = 'https://dlcdn.apache.org/maven/maven-4/4.0.0-rc-5/binaries/apache-maven-4.0.0-rc-5-bin.zip',
	},{
		nome = 'jq',
		link = 'https://github.com/jqlang/jq/releases/download/jq-1.8.1/jq-windows-i386.exe',
	},{
        nome = 'tree-sitter',
        link = 'https://github.com/tree-sitter/tree-sitter/releases/download/v0.26.9/tree-sitter-cli-windows-x64.zip',
    },{
		nome = 'sqlite3',
		link = 'https://www.sqlite.org/2024/sqlite-tools-win-x64-3460000.zip',
    },{
        nome = 'gradle',
        link = 'https://services.gradle.org/distributions/gradle-8.10.2-bin.zip',
    },{
        nome = 'pandoc',
        link = 'https://github.com/jgm/pandoc/releases/download/3.5/pandoc-3.5-windows-x86_64.zip',
    },{
        nome = 'cmail',
        link = 'https://www.inveigle.net/downloads/CMail_0.8.11_x86.zip',
    },{
        nome = 'cargo',
        link = 'https://static.rust-lang.org/dist/rust-nightly-x86_64-pc-windows-msvc.tar.xz',
    },{
        nome = 'rust-analyzer',
        link = 'https://github.com/rust-lang/rust-analyzer/releases/download/2026-01-19/rust-analyzer-aarch64-pc-windows-msvc.zip',
    }
    -- ,{
    --     nome = 'lua5.1', -- version 5.1 (https://sourceforge.net/projects/luabinaries/files/)
    --     link = 'https://sitsa.dl.sourceforge.net/project/luabinaries/5.1.5/Tools%20Executables/lua-5.1.5_Win64_bin.zip',
    -- },{
    --     nome = 'lua5.1.lib', -- libs for version 5.1 (build for msvc 14)
    --     link = 'https://sinalbr.dl.sourceforge.net/project/luabinaries/5.1.5/Windows%20Libraries/Static/lua-5.1.5_Win64_vc14_lib.zip',
    -- }
    ,{
        nome = 'zig',
        link = 'https://ziglang.org/download/0.16.0/zig-x86_64-windows-0.16.0.zip',
    },{
        nome = 'cpdf', -- pdf tools: merge, split, etc
        link = 'https://github.com/coherentgraphics/cpdf-binaries/archive/refs/heads/master.zip',
    },{
        nome = 'fzf',
        link = 'https://github.com/junegunn/fzf/releases/download/v0.72.0/fzf-0.72.0-windows_amd64.zip',
    }
}

