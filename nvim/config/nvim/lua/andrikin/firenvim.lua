-- FIRENVIM CONFIG --
local enable = {
    content = 'text',
    selector = 'textarea',
    priority = 1,
    takeover = 'always',
}
vim.g.firenvim_config = {
    globalSettings = { alt = "all" },
    localSettings = {
        ['<C-w>'] = 'noop',
        ['<C-n>'] = 'noop',
        ['.*'] = {
            cmdline = 'neovim',
            -- Desabilitar firenvim por padrão
            content = 'text',
            selector = 'textarea',
            takeover = 'never',
            priority = 0,
            -- filename = '{hostname}_{pathname%10}.{extension}',
        },
        -- ENABLE FIRENVIM IN URLS --
        -- ['https?://[^/]*somesite.com/*'] = enable,
        ['https?://[^/]*falabr.cgu.gov.br/*'] = enable,
    }
}

-- LSP --
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
-- Inicializando caminho para git
---@diagnostic disable-next-line: undefined-field
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

local plugins = {
    -- Configuração de tema
	{
        'https://github.com/Andrikin/awesome-pairing',
        config = function()
            -- Awesome Pairing
            vim.g.awesome_pairing_chars = [[({['"]]
        end,
    },
	'https://github.com/Andrikin/awesome-substitute',
	-- Fork Tim Pope vim-capslock
	'https://github.com/Andrikin/vim-capslock',
	'https://github.com/tpope/vim-surround.git',
	-- Vim Cool,
	'https://github.com/romainl/vim-cool.git',
	-- Traces.vim,
	'https://github.com/markonm/traces.vim.git',
    -- dressing -- change vim.ui.select
    'https://github.com/stevearc/dressing.nvim',
    -- spellfile.nvim -- Lua port of spellfile.vim
    'https://github.com/cuducos/spellfile.nvim',
    -- Firenvim
    {
        'https://github.com/glacambre/firenvim',
        build = function()
            if vim.fn.isdirectory(vim.fn.expand('$HOME') .. '\\nvim\\config\\firenvim') == 0 then
                vim.fn["firenvim#install"](1)
            else
                vim.fn["firenvim#install"](0)
            end
        end,
    },
}

local opts = {
	performance = {
		rtp = {
			disabled_plugins = {
				-- "gzip",
				-- "matchit",
				-- "matchparen",
				"netrwPlugin",
				-- "tarPlugin",
				-- "tohtml",
				"tutor",
				-- "zipPlugin",
                "man", -- man.lua
			},
		},
	},
    rocks = {
        hererocks = false,
        enabled = false,
    }
}

require("lazy").setup(plugins, opts)

-- Colorscheme --
-- vim.cmd.colorscheme('vim')
vim.cmd.colorscheme('zellner')

-- spellfile.nvim -- Lua port of spellfile.vim
vim.opt.spelllang = 'pt_br'

-- Configurações Windows
vim.opt.fileformat = 'dos'
vim.opt.eol = false
vim.opt.fixeol = false

-- Indicadores - números nas linhas
vim.opt.rnu = true
vim.opt.nu = true

-- Tamanho da indentação
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.expandtab = true -- ThePrimeagen way

-- Configurações para search
vim.opt.incsearch = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = true

-- Configurações gerais
vim.opt.autochdir = false
vim.opt.scrolloff = 999
vim.opt.lazyredraw = true
vim.opt.backspace = 'indent,eol,start'
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.helpheight = 15
-- Problems that can occur in vim session can be avoid using this configuration
vim.opt.sessionoptions:remove('options')
vim.opt.encoding = 'utf-8'
vim.opt.autoread = true
vim.opt.tabpagemax = 50
vim.opt.wildmenu = true
-- usar <tab> para cmdline completion em macros
if vim.o.wildcharm ~= 9 then
    vim.opt.wildcharm = 9
end
-- vim.opt.completeopt = 'menu,menuone,noselect'
vim.opt.completeopt = 'menu,popup,fuzzy'
vim.opt.complete:remove('t')
vim.opt.title = true
vim.opt.hidden = true
vim.opt.mouse = ''
vim.opt.mousemodel = 'extend'
if vim.fn.has('persistent_undo') == 1 then
    local path = vim.fs.joinpath(
        ---@diagnostic disable-next-line: param-type-mismatch
        vim.fn.stdpath('data'),
        'undotree'
    )
	if vim.fn.isdirectory(path) == 0 then
		vim.fn.mkdir(path, 'p', '0755')
	end
	vim.opt.undodir = path
	vim.opt.undofile = true
end
vim.opt.swapfile = false
vim.opt.textwidth = 70

-- Statusline
vim.opt.laststatus = 0
vim.opt.showtabline = 0
vim.opt.showmode = false

-- NeoVim configurations
vim.opt.guicursor = 'i-n-v-c:block'
vim.opt.guifont = 'SauceCodePro NFM:h9'
vim.opt.winborder = 'none'
vim.opt.inccommand = '' -- conflict with traces.vim
vim.opt.fillchars = 'vert:|,fold:*,foldclose:+,diff:-'

-- Matchit
-- TODO: Criar arquivos ftplugin para cada linguagem, definindo b:match_words
vim.opt.matchpairs:append('<:>')

-- --- Netrw ---
-- Disable Netrw
vim.g.loaded_netrwPlugin = 1

-- Vim-Surround (Tim Pope)
-- Latex
vim.g['surround_' .. vim.fn.char2nr('\\')] = ''
vim.g['surround_' .. vim.fn.char2nr('l')] = ''
-- Html
vim.g['surround_' .. vim.fn.char2nr('t')] = ''

-- --- Traces ---
vim.g.traces_num_range_preview = 0

-- Removendo providers: Perl
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0

-- MAPPINGS --
vim.keymap.set({'i', 'c'}, '<c-backspace>', '<c-w>')
vim.keymap.set({'i', 'c'}, '<c-v>', '<c-r>+')

-- COMMANDS --
local command = vim.api.nvim_create_user_command
command(
    'Resposta',
    function()
        local greetings = vim.fn.getline(1):match('Boa tarde,')
        local endings = vim.fn.getline(vim.fn.line('$')):match('Ouvidoria da Prefeitura de Itajaí')
        if greetings and endings then
            do return end
        end
        local range = {1, vim.fn.line('$')}
        vim.cmd.substitute({"/\\([º°ª]\\)\\([a-zA-Z0-9]\\)/\\1 \\2/ge", range = range})
        vim.cmd.substitute({'/[“”]/"/ge', range = range})
        -- Formatar espaços e pontuações
        vim.cmd.substitute({'/\\s\\+\\([.,]\\)\\s\\?/\\1 /ge', range = range})
        vim.cmd.substitute({'/\\s\\+/ /ge', range = range})
        -- Evitando linhas com e-mail, adicionar espaço depois de pontuações
        vim.cmd('v/@\\|gov\\.br\\|\\.com\\|\\.br/s/\\([a-zA-Z]\\)\\s\\{,}\\([:.,]\\)\\s\\{,}\\([a-zA-Z0-9]\\)/\\1\\2 \\3/ge')
        vim.cmd('v/^$/normal gqip') -- ajuste para textwidth
        vim.cmd.normal('gg[ [ ')
        vim.cmd.normal('G] ] ')
        vim.fn.setline(1, 'Boa tarde,\r\rSegue resposta do setor responsável à sua manifestação:\r\r---')
        vim.fn.setline(vim.fn.line('$'), '---\r\rAtenciosamente,\rOuvidoria da Prefeitura de Itajaí')
    end,
    {}
)

local Copyq = require('andrikin.utils').Copyq

command(
	'Clipboard',
    function(arg)
        Copyq.clipboard(arg)
    end,
	{
		nargs = "?",
		complete = function(arg, _, _) return Copyq:tab_complete(arg) end,
	}
)

-- AUTOCOMMANDS --
local autocmd = vim.api.nvim_create_autocmd
local Andrikin = require('andrikin.utils').Andrikin
local cursorline = require('andrikin.utils').cursorline

-- Auto Insert Mode
autocmd({'BufEnter'}, {
    pattern = "*.txt",
    command = 'call feedkeys("i")'
})

-- Highlight linha quando entrar em INSERT MODE
autocmd(
    'InsertEnter',
    {
        group = Andrikin,
        pattern = '*',
        callback = function()
            cursorline.on()
        end,
    }
)
autocmd(
    'InsertLeave',
    {
        group = Andrikin,
        pattern = '*',
        callback = function()
            local dirvish = vim.o.ft == 'dirvish' -- não desativar quando for Dirvish
            if not dirvish then
                cursorline.off()
            end
        end,
    }
)

-- Resize windows automatically
-- Tim Pope goodness
autocmd(
    'VimResized',
    {
        group = Andrikin,
        pattern = '*',
        callback = function()
            vim.cmd.wincmd('=')
        end,
    }
)

-- Highlight configuração
autocmd(
    'TextYankPost',
    {
        group = Andrikin,
        pattern = '*',
        callback = function()
            vim.hl.on_yank({
                higroup = 'IncSearch',
                timeout = 300,
            })
        end,
    }
)

-- Remover textwidth da página de tratamento da manifestação
-- do Fala.BR
autocmd(
    'BufEnter',
    {
        group = Andrikin,
        pattern = {
            'falabr.cgu.gov.br_festacao-TratarManifestacao-aspx_teudoFormComAjax-txtContribuicao_*.txt',
            'falabr.cgu.gov.br_stacao-TramitarManifestacao-aspx_-ConteudoFormComAjax-txtMensagem*.txt',
        },
        command = "set textwidth=0",
    }
)
-- RESPOSTA FALA.BR
-- Incluir Prefixos e Sufixos da resposta
autocmd(
    'BufEnter',
    {
        group = Andrikin,
        pattern = {
            'falabr.cgu.gov.br_stacao-AnalisarManifestacao-aspx_-ConteudoFormComAjax-txtResposta_*.txt',
            'falabr.cgu.gov.br_web-manifestacao-analisar_TEXTAREA-id-txtResposta-textarea_*.txt',
        },
        callback = function()
            if vim.cmd.Resposta then
                vim.cmd.Resposta()
            end
            vim.cmd.set('lines=25')
        end,
    }
)

-- Configurações de ortografia e tamanho do frame no Fala.BR
autocmd(
    'BufEnter',
    {
        group = Andrikin,
        pattern = 'falabr.cgu.gov.br*.txt',
        command = "set spell",
    }
)

-- FIXME: força a página do Fala.BR a recarregar...
-- -- Automatically syncing changes to the page
-- autocmd({'TextChanged', 'TextChangedI'}, {
--     callback = function(e)
--         if vim.g.timer_started == true then
--             return
--         end
--         vim.g.timer_started = true
--         vim.fn.timer_start(10000, function()
--             vim.g.timer_started = false
--             vim.cmd('silent write')
--         end)
--     end
-- })
