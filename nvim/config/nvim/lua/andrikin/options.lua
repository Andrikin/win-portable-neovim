vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Search recursively
vim.opt.path:append('**')

-- Sem numeração de linhas para comando TOHtml
vim.g.html_number_lines = 0

-- Indicadores - números nas linhas
vim.o.rnu = true
vim.o.nu = true

-- Tamanho da indentação
vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.o.softtabstop = 4
vim.o.expandtab = true -- ThePrimeagen way

-- Configurações para search
vim.o.incsearch = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.hlsearch = true

-- Configurações gerais
vim.o.autochdir = false
vim.o.scrolloff = 999
vim.o.lazyredraw = true
vim.o.backspace = 'indent,eol,start'
vim.o.splitbelow = true
vim.o.splitright = true
vim.o.helpheight = 15
-- Problems that can occur in vim session can be avoid using this configuration
vim.opt.sessionoptions:remove('options')
vim.o.encoding = 'utf-8'
vim.o.autoread = true
vim.o.tabpagemax = 50
vim.o.wildmenu = true
-- usar <tab> para cmdline completion em macros
if vim.o.wildcharm ~= 9 then
    vim.opt.wildcharm = 9
end
-- vim.opt.completeopt = 'menu,menuone,noselect'
vim.o.completeopt = 'menu,noinsert,noselect,popup,fuzzy'
if vim.fn.has('win32') then
	vim.g.shell = vim.env.COMSPEC
else
	vim.g.shell = vim.env.TERM
end
--let &g:shellpipe = '2>&1 | tee' -- default in Windows
vim.opt.complete:remove('t')
vim.o.title = true
vim.o.hidden = true
vim.o.mouse = ''
vim.o.mousemodel = 'extend'
if vim.fn.has('persistent_undo') == 1 then
    local path = vim.fs.joinpath(
        ---@diagnostic disable-next-line: param-type-mismatch
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
-- set linebreak
-- set wrapmargin = 5
vim.g.textwidth = 0

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
vim.o.fillchars = 'vert:|,fold:*,foldclose:+,diff:-'

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
vim.g.dirvish_mode = '%sort /.*\\\\\\|.*[^\\\\]/' -- diretórios primeiro, depois arquivos

-- --- Emmet ---
vim.g.user_emmet_install_global = 0
-- vim.g.user_emmet_leader_key = '<m-space>'

-- spellfile.nvim -- Lua port of spellfile.vim
vim.o.spelllang = 'pt_br'

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

-- Removendo providers: Perl
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0

-- Andrikin/awesome-pairing
vim.g.awesome_pairing_chars = [[({['"]]

