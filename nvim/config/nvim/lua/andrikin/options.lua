vim.g.mapleader = ' '
vim.g.maplocalleader = vim.g.mapleader

-- terminal toggler
vim.g.ttoggler = {}

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
vim.o.more = false
vim.o.scrolloff = 999
vim.o.lazyredraw = true
vim.o.splitbelow = true
vim.o.splitright = true
-- Problems that can occur in vim session can be avoid using this configuration
vim.opt.sessionoptions:remove('options')
vim.o.wildmode = 'noselect:longest:lastused,full'
vim.o.findfunc = function (cmdargs, _)
    local query = vim.fs.abspath(
        "**/*",
        -- três diretórios para trás
        {cwd = vim.fn.expand('%:h:h:h'):gsub('"', '')}
    )
    local files = vim.fn.glob(query, true, true)
    return vim.fn.matchfuzzy(files, cmdargs)
end
-- usar <tab> para cmdline completion em macros
if vim.o.wildcharm ~= 9 then
    vim.opt.wildcharm = 9
end
vim.opt.complete:remove('u')
-- vim.opt.completeopt = 'menu,menuone,noselect'
vim.o.completeopt = 'menu,noinsert,noselect,popup,fuzzy'
if vim.fn.has('win32') then
	vim.g.shell = vim.env.COMSPEC
else
	vim.g.shell = vim.env.TERM
end
vim.o.hidden = true
vim.o.mouse = ''
vim.o.mousemodel = 'extend'
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
vim.o.swapfile = false
vim.o.textwidth = 0
-- set linebreak
-- set wrapmargin = 5

-- Statusline
vim.o.laststatus = 3
vim.o.showtabline = 1
vim.o.showmode = false

-- NeoVim configurations
-- vim.opt.guicursor = 'i-n-v-c:block' -- sem blink
vim.o.guicursor = "i-n-v-c:block,n-v-c:blinkwait700-blinkoff400-blinkon250"
vim.o.guifont = 'SauceCodePro NFM:h11'
vim.o.winborder = 'single'
if vim.g.nvy or vim.g.neovide then
	vim.o.guifont = 'SauceCodePro Nerd Font Mono:h12'
end
vim.o.inccommand = 'split' -- empty string to use with traces.vim

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

-- --- Emmet ---
vim.g.user_emmet_install_global = 0
-- vim.g.user_emmet_leader_key = '<m-space>'

-- spellfile.nvim -- Lua port of spellfile.vim
vim.o.spelllang = 'pt_br'
-- obter dicionário pt_br e como instalá-lo no neovim
-- https://vimbook.com.br/capitulo_10/dicionario_de_termos/#dicionario-portugues-segundo-o-acordo-ortografico

-- --- Netrw ---
-- Disable Netrw
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Neovide
-- Mais lightweight possível
if vim.g.neovide then
	vim.g.neovide_cursor_animation_length = 0
	vim.g.neovide_cursor_antialiasing = false
	vim.g.neovide_cursor_animate_in_insert_mode = false
	vim.g.neovide_cursor_animate_command_line = false
	vim.g.neovide_cursor_vfx_mode = ""
end

-- Andrikin/awesome-pairing
vim.g.awesome_pairing_chars = [[({['"]]

-- Removendo providers: Perl
vim.g.loaded_perl_provider = 0

-- disable dir plugin
vim.g.loaded_nvim_dir_plugin = 1

-- disable old-zip
-- vim.g.loaded_zipPlugin = 1

