-- FIRENVIM CONFIG --
vim.pack.add({
    'https://github.com/Andrikin/awesome-pairing',
	'https://github.com/Andrikin/awesome-substitute',
	-- Fork Tim Pope vim-capslock
	'https://github.com/Andrikin/vim-capslock',
	'https://github.com/tpope/vim-surround.git',
	-- auto nohlsearch
	'https://github.com/romainl/vim-cool.git',
    -- change vim.ui.select
    'https://github.com/stevearc/dressing.nvim',
    -- Firenvim
    'https://github.com/glacambre/firenvim',
}, {confirm = false})

-- vim.pack autocmds:
vim.api.nvim_create_autocmd('PackChanged', { -- install firenvim
    callback = function (ev)
        local nome, tipo = ev.data.spec.name, ev.data.kind
        if nome == 'firenvim' and (tipo == 'install' or tipo == 'update') then
            if not ev.data.active then vim.cmd.packadd('firenvim') end
            if vim.fn.isdirectory(vim.fn.expand('$HOME') .. '/nvim/config/firenvim') == 0 then
                vim.cmd("silent! call firenvim#install(0)")
            end
        end
    end
})
-- vim.cmd.packadd("firenvim")

vim.cmd.packadd('nvim.undotree')
-- vim.cmd.packadd('justify')

-- spellfile.vim
require('nvim.spellfile').config()

local enable = {
    content = 'text',
    selector = 'textarea:not([readonly], [aria-readonly])',
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

-- Colorscheme --
vim.cmd.colorscheme('zellner')

vim.g.awesome_pairing_chars = [[({['"]]

-- spellfile.nvim -- Lua port of spellfile.vim
vim.o.spelllang = 'pt_br'

-- Configurações Windows
vim.o.fileformat = 'dos'
vim.o.eol = true
vim.o.fixeol = true

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
vim.o.autocomplete = true
vim.o.autochdir = false
vim.o.scrolloff = 999
vim.o.lazyredraw = true
vim.o.backspace = 'indent,eol,start'
vim.o.splitbelow = true
vim.o.splitright = true
vim.o.helpheight = 15
-- usar <tab> para cmdline completion em macros
if vim.o.wildcharm ~= 9 then
    vim.o.wildcharm = 9
end
vim.opt.complete:remove('t')
vim.o.title = false
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
vim.o.textwidth = 70

-- Statusline
vim.o.laststatus = 0
vim.o.showtabline = 0
vim.o.showmode = false

-- NeoVim configurations
vim.o.guicursor = 'i-n-v-c:block'
vim.o.guifont = 'SauceCodePro NFM:h9'
vim.o.winborder = 'single'
vim.o.inccommand = 'split'
vim.o.fillchars = 'vert:|,fold:*,foldclose:+,diff:-'

-- Matchit
-- TODO: Criar arquivos ftplugin para cada linguagem, definindo b:match_words
vim.opt.matchpairs:append('<:>')

-- --- Netrw ---
-- Disable Netrw
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Removendo providers:
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_node_provider = 0

-- MAPPINGS --
vim.keymap.set({'i', 'c'}, '<c-backspace>', '<c-w>')
vim.keymap.set({'i', 'c'}, '<c-v>', '<c-r>+')

-- 'gk' e 'gj' ThePrimeagen way
local van_halen = function(acao)
    local contador = vim.v.count
    local marcador = ''
    if contador > 1 then
        marcador = 'm`' .. contador
    end
    if contador == 0 then
        return marcador .. 'g' .. acao
    end
    return marcador .. acao
end
vim.keymap.set( 'n', 'k',
    function () return van_halen('k') end,
	{ expr = true, silent = true }
)
vim.keymap.set( 'n', 'j',
    function () return van_halen('j') end,
	{ expr = true, silent = true }
)

-- COMMANDS --
local command = vim.api.nvim_create_user_command
command(
    'Resposta',
    function()
        local greetings = vim.fn.getline(1):match('Boa tarde,')
        local endings = vim.fn.getline(vim.fn.line('$')):match('Ouvidoria da Prefeitura de Itajaí')
        if greetings and endings then
            return
        end
        local range = {1, vim.fn.line('$')}
        vim.cmd.substitute({"/\\([º°ª]\\)\\([a-zA-Z0-9]\\)/\\1 \\2/ge", range = range, mods = { silent = true }})
        vim.cmd.substitute({'/[“”]/"/ge', range = range, mods = { silent = true }})
        -- Formatar espaços e pontuações
        vim.cmd.substitute({'/\\s\\+\\([.,]\\)\\s\\?/\\1 /ge', range = range, mods = { silent = true }})
        vim.cmd.substitute({'/\\s\\+/ /ge', range = range, mods = { silent = true }})
        -- Evitando linhas com e-mail, adicionar espaço depois de pontuações
        vim.cmd('v/@\\|gov\\.br\\|\\.com\\|\\.br/s/\\([a-zA-Z]\\)\\s\\{,}\\([:.,]\\)\\s\\{,}\\([a-zA-Z0-9]\\)/\\1\\2 \\3/ge')
        vim.cmd('v/^$/normal gqip') -- ajuste para textwidth
        -- package justify
        -- vim.cmd('%Justify 70 4') -- justifica o texto
        vim.cmd('%left')
        vim.fn.append(0, 'Boa tarde,\r\rSegue resposta do setor responsável à sua manifestação:\r\r---\r\r')
        vim.fn.append(vim.fn.line('$'), '\rAtenciosamente,\r\r\r---\r\rAtenciosamente,\rOuvidoria da Prefeitura de Itajaí')
        vim.cmd.set('lines=25')
        -- remover linhas em branco desnecessárias
        vim.cmd.substitute({'/[\\n\\r]\\{3,}/\\r\\r/ge', range = {1, vim.fn.line('$')}, mods = { silent = true }})
        vim.cmd.substitute({[[/\r/\r/ge]], range = {1, vim.fn.line('$')}, mods = { silent = true }})
    end,
    {}
)

-- Copyq integration
_ = (function()
    if vim.fn.executable('copyq') ~= 1 then
        vim.print('Não foi encontrado "copyq". Por gentileza, realize a instalação.')
        return
    end
    vim.api.nvim_create_user_command('Clipboard',
        function(args)
            local tab = args.fargs[1] or 'clipboard'
            local clipboard = vim.system({"copyq","eval","--",([[
                let indent = 4;
                let tamanho = size() <= 50 && size() || 50;
                tab('%s');
                let c = [];
                for(i=0;i<tamanho;i++) c.push(str(read(i)));
                print(JSON.stringify(c, null, indent));
            ]]):format(tab)}):wait().stdout
            -- transformar JSON
            clipboard = vim.json.decode(clipboard)
            local temp = {}
            local index = 1
            for i, _ in ipairs(clipboard) do -- remover strings vazias
                if clipboard[i] ~= "" then
                    temp[index] = clipboard[i]
                    index = index + 1
                end
            end
            ---@diagnostic disable-next-line: cast-local-type
            clipboard = temp
            vim.ui.select(clipboard, {
                prompt = 'Selecione uma entrado do clipboard:',
                format_item = function(item)
                    if #item <= 75 then
                        return item
                    end
                    return item:sub(1, 75)
                end,
            }, function(choice)
                    if choice then
                        vim.fn.setreg('"', choice)
                        vim.cmd.normal('P')
                    end
                end
            )
        end,
        {
            nargs = "?",
            complete = function(arg, _, _)
                local lista = vim.system({"copyq", "eval", "--", [[
                    let indent = 4;
                    let tabs = tab();
                    print(JSON.stringify(tabs, null, indent));
                ]]}):wait().stdout
                local ok = nil
                ok, lista = pcall(vim.json.decode, lista)
                if not ok then
                    return {}
                end
                return vim.tbl_filter(function(copyqtab)
                    return copyqtab:lower():match(arg:gsub('-', '.'):lower())
                end, lista)
            end,
        }
    )
end
)()

-- Mensagens automáticas
command('Anexos',
    function()
        vim.cmd('%d')
        vim.fn.setline(1, [[Boa tarde,

Segue no anexo, resposta do setor responsável à sua manifestação.

Atenciosamente,
Ouvidoria da Prefeitura de Itajaí
        ]])
        vim.cmd.normal("ZZ")
    end,
{})

-- AUTOCOMMANDS --
local autocmd = vim.api.nvim_create_autocmd
local Andrikin = vim.api.nvim_create_augroup('Andrikin', {clear = true})

-- Auto Insert Mode
autocmd({'BufEnter'}, {
    pattern = '*.txt',
    command = 'startinsert'
})

-- Highlight linha quando entrar em INSERT MODE
autocmd('InsertEnter',
    {
        group = Andrikin,
        pattern = '*',
        callback = function()
            local id = vim.api.nvim_get_current_win()
            vim.wo[id][0].cursorline = true
        end,
})
autocmd('InsertLeave',
    {
        group = Andrikin,
        pattern = '*',
        callback = function()
            local dirvish = vim.o.ft == 'dirvish' -- não desativar quando for Dirvish
            if not dirvish then
                local id = vim.api.nvim_get_current_win()
                vim.wo[id][0].cursorline = false
            end
        end,
})

-- Resize windows automatically
-- Tim Pope goodness
autocmd('VimResized',
    {
        group = Andrikin,
        pattern = '*',
        callback = function()
            vim.cmd.wincmd('=')
        end,
})

-- Highlight configuração
autocmd('TextYankPost',
    {
        group = Andrikin,
        pattern = '*',
        callback = function()
            vim.hl.hl_op({
                higroup = 'IncSearch',
                timeout = 300,
            })
        end,
})

-- Remover textwidth da página de tratamento da manifestação
-- do Fala.BR
autocmd('BufEnter',
    {
        group = Andrikin,
        pattern ={
            'falabr.cgu.gov.br_festacao-TratarManifestacao-aspx_teudoFormComAjax-txtContribuicao_*.txt',
            'falabr.cgu.gov.br_stacao-TramitarManifestacao-aspx_-ConteudoFormComAjax-txtMensagem*.txt',
        },
        command = "set textwidth=0",
})
-- RESPOSTA FALA.BR
-- Incluir Prefixos e Sufixos da resposta
autocmd('BufEnter',
    {
        group = Andrikin,
        pattern = {
            'falabr.cgu.gov.br_stacao-AnalisarManifestacao-aspx_-ConteudoFormComAjax-txtResposta_*.txt',
            'falabr.cgu.gov.br_web-manifestacao-analisar_TEXTAREA-id-txtResposta-textarea_*.txt',
        },
        callback = function()
        if vim.fn.exists(':Resposta') > 0 then
                vim.cmd.Resposta()
            end
        end,
})

autocmd('BufEnter',
    {
        group = Andrikin,
        pattern = {
            'falabr.cgu.gov.br_web-manifestacao-criar_icao-texto-manifestacao-textarea_*.txt',
        },
        callback = function()
            vim.cmd.set('lines=25')
        end,
})

-- Configurações de ortografia e tamanho do frame no Fala.BR
autocmd('BufEnter',
    {
        group = Andrikin,
        pattern = 'falabr.cgu.gov.br*.txt',
        command = "set spell",
})

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

