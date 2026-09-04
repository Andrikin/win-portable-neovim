vim.g.mapleader = ' '
vim.g.maplocalleader = vim.g.mapleader

-- terminal toggler
vim.g.ttoggler = {}

-- set path to find files recursivelly
vim.opt.path:prepend('**')

-- Indicadores - números nas linhas
vim.o.rnu = true
vim.o.nu = true
vim.o.signcolumn = 'number'

-- Tamanho da indentação
vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.o.softtabstop = 4
-- ThePrimeagen way
vim.o.expandtab = true

-- Configurações para search
vim.o.incsearch = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.hlsearch = true

-- Configurações gerais
-- set linebreak
-- set wrapmargin = 5
vim.o.hidden = true
vim.o.mouse = ''
vim.o.mousemodel = 'extend'
vim.o.swapfile = false
vim.o.textwidth = 0
vim.o.more = false
vim.o.scrolloff = 999
vim.o.lazyredraw = true
vim.o.splitbelow = true
vim.o.splitright = true
-- Problems that can occur in vim session can be avoid using this configuration
vim.opt.sessionoptions:remove('options')
-- https://jkrl.me/2025/09/02/nvim-fuzzy-find.html
-- https://aymenhafeez.github.io/posts/2026-02-27-cmdline-fuzzy-finding/
vim.o.wildmode = 'lastused,full'
vim.o.wildoptions = {'pum', 'fuzzy'}
-- usar <tab> para cmdline completion em macros
vim.o.wildcharm = vim.o.wildchar
vim.o.wildignore = '**/.git/**'
vim.o.findfunc = function (cmdargs, cmdcomplete)
    cmdargs = vim.fs.normalize(cmdargs)
    local arquivo = vim.uv.fs_stat(cmdargs)
    if arquivo and arquivo.type == 'file' then
        return {cmdargs}
    end
    local query = '%:h'
    if vim.o.filetype == 'dirvish' then
        query = '%'
    end
    local cwd = vim.fs.normalize(vim.fn.expand(query))
    if not cmdargs:match(cwd) then
        query = vim.fs.joinpath(cwd, '**', cmdargs)
    end
    if cmdcomplete then
        local ftype = vim.uv.fs_stat(cmdargs)
        if ftype and ftype.type == 'directory' then
            query = vim.fs.joinpath(cmdargs, '*')
        end
    end
    local files = vim.npcall(function ()
        return vim.fn.glob(query, false, true)
    end)
    if files and #files == 0 then
        files = vim.fn.glob(query .. '*', false, true)
    end
    return vim.fn.matchfuzzy(files, cmdargs)
end
vim.opt.complete:remove('u')
-- vim.opt.completeopt = 'menu,menuone,noselect'
vim.o.completeopt = 'menu,noinsert,noselect,popup,fuzzy'
if vim.fn.has('win32') then
	vim.g.shell = vim.env.COMSPEC
else
	vim.g.shell = vim.env.TERM
end
if vim.fn.has('persistent_undo') == 1 then
    local path = vim.fs.joinpath(
        vim.fn.stdpath('data'),
        'undotree'
    )
	if vim.fn.isdirectory(path) == 0 then
		vim.fn.mkdir(path, 'p', '0755')
	end
	vim.o.undodir = path
	vim.o.undofile = true
end
if vim.fn.executable('rg.exe') then
    vim.go.grepprg = "rg --vimgrep -uuu --smart-case "
end

-- Statusline
vim.o.laststatus = 3
vim.o.showtabline = 1
vim.o.showmode = false

-- NeoVim configurations
vim.o.inccommand = 'split' -- empty string to use with traces.vim
vim.o.winborder = 'single'
-- vim.opt.guicursor = 'i-n-v-c:block' -- sem blink
vim.o.guicursor = "i-n-v-c:block,n-v-c:blinkwait700-blinkoff400-blinkon250"
vim.o.guifont = 'SauceCodePro NFM:h11'
if vim.g.nvy or vim.g.neovide then
	vim.o.guifont = 'SauceCodePro Nerd Font Mono:h12'
end

-- Dirvish
vim.defer_fn(function()
    if vim.fn.exists(':SortingDirvish') > 0 then
        vim.g.dirvish_mode = ':SortingDirvish'
    else
        -- diretórios primeiro, depois arquivos
        vim.g.dirvish_mode = ':%sort /.*\\\\\\|.*[^\\\\]/'
    end
end, 1000)
vim.g.dirvish_dbg = 1

-- Configurações Windows
vim.o.fileformat = 'dos'
vim.o.eol = false
vim.o.fixeol = false

-- Vim-Surround (Tim Pope)
-- Latex
vim.g['surround_' .. vim.fn.char2nr('\\')] = ''
vim.g['surround_' .. vim.fn.char2nr('l')] = ''
-- Html
vim.g['surround_' .. vim.fn.char2nr('t')] = ''

-- Matchit
-- TODO: Criar arquivos ftplugin para cada linguagem, definindo b:match_words
vim.opt.matchpairs:append('<:>')

-- spellfile.nvim -- Lua port of spellfile.vim
vim.o.spelllang = 'pt_br'
-- obter dicionário pt_br e como instalá-lo no neovim
-- https://vimbook.com.br/capitulo_10/dicionario_de_termos/#dicionario-portugues-segundo-o-acordo-ortografico

-- Neovide
-- Mais lightweight possível
if vim.g.neovide then
	vim.g.neovide_cursor_animation_length = 0
	vim.g.neovide_cursor_antialiasing = false
	vim.g.neovide_cursor_animate_in_insert_mode = false
	vim.g.neovide_cursor_animate_command_line = false
	vim.g.neovide_cursor_vfx_mode = ""
end

-- --- Emmet ---
vim.g.user_emmet_install_global = 0
-- vim.g.user_emmet_leader_key = '<m-space>'

-- --- Netrw ---
-- Disable Netrw
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Andrikin/awesome-pairing
vim.g.awesome_pairing_chars = [[({['"]]

-- Removendo providers: Perl
vim.g.loaded_perl_provider = 0

-- disable dir plugin
vim.g.loaded_nvim_dir_plugin = 1

-- disable old-zip
-- vim.g.loaded_zipPlugin = 1

