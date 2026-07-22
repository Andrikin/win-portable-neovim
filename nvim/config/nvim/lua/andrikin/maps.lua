---@diagnostic disable: need-check-nil
if not vim.g.nvy or not vim.g.neovide then
	-- Fix ^\ (nvim-qt/windows 7)
	vim.print('Mapeamento do comando <c-]>: Jump to the definition of the keyword under the cursor.')
	vim.keymap.set('n', '<c-\\>', '<c-]>')
end

-- CTRL-BACKSPACE para apagar palavras
vim.keymap.set({'i', 'c'}, '<c-backspace>', '<c-w>') -- obter mesmo comportamento (firefox)
vim.keymap.set({'i', 'c'}, '<c-v>', '<c-r>+') -- colar clipboard

-- Remover <space> dos modos: NORMAL e VISUAL (em conjunto com mapleader)
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- CTRL-U in insert mode deletes a lot. Use CTRL-G u to first break undo,
-- so that you can undo CTRL-U after inserting a line break.
-- Revert with ":iunmap <C-U>". -> from defaults.vim
-- vim.keymap.set('i', '<c-u>', '<c-g>u<c-u>') -- default in neovim
-- vim.keymap.set('i', '<c-w>', '<c-g>u<c-w>') -- default in neovim
-- Fix & command. Redo :substitute command
-- vim.keymap.set( 'n', '&', function() vim.cmd('&&') end) -- default in neovim
vim.keymap.set('n', '<backspace>', 'X')
vim.keymap.set('n', '<c-h>', 'X')
vim.keymap.set('n', "'", '`')
-- Yank to end of sreen line. Make default in Neovim 0.6.0
-- g$ cursor after last character, g_ cursor at last character
vim.api.nvim_del_keymap('n', 'Y') -- removing default mapping
vim.keymap.set('n', 'Y', 'yg_') -- better than 'y$'
-- Disable <c-z> (:stop)
vim.keymap.set('n', '<c-z>', '<nop>')
-- Join lines in a better way - From a video of ThePrimeagen
vim.keymap.set('n', 'J', 'mzJ`z')
-- Undo better - inserting breaking points, thanks to ThePrimeagen
vim.keymap.set('i', ',', ',<c-g>u')
vim.keymap.set('i', '.', '.<c-g>u')

-- Using gk and gj (screen cursor up/down)
-- nnoremap <expr> k v:count == 0 ? 'gk' : 'k'
-- nnoremap <expr> j v:count == 0 ? 'gj' : 'j'
-- Adding jumps to jumplist - The Primeagen gold apple with gk and gj (screen
-- cursor up/down)
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

-- Moving lines up and down - The Primeagen knowledge word
-- inoremap <c-j> <c-o>:m.+1<cr> -- utilizo muito <c-j> para newlines, seria
-- inviável trocar para essa funcionalidade
-- inoremap <c-k> <c-o>:m.-2<cr>
-- nnoremap <leader>k <cmd>m.-2<cr>
-- nnoremap <leader>j <cmd>m.+1<cr>
vim.keymap.set('i', '<a-k>', "<c-o>:m.-2<cr>", {silent = true})
vim.keymap.set('i', '<a-j>', "<c-o>:m.+1<cr>", {silent = true})
if vim.g.mapleader == ' ' then
	vim.keymap.set('n', '<leader>k', ":m.-2<cr>", {silent = true})
	vim.keymap.set('n', '<leader>j', ":m.+1<cr>", {silent = true})
else
	vim.keymap.set('n', '<space>k', ":m.-2<cr>", {silent = true})
	vim.keymap.set('n', '<space>j', ":m.+1<cr>", {silent = true})
end
vim.keymap.set('v', 'K', ":m'<-2<cr>gv", {silent = true})
vim.keymap.set('v', 'J', ":m'>+1<cr>gv", {silent = true})
-- gJ com o mesmo comportamento de J (juntar linhas removendo espaços)
vim.keymap.set('v', 'gJ', ":<c-u>'<,'>join<cr>", {silent = true})

-- Copy and paste from clipboard (* -> selection register/+ -> primary register)
vim.keymap.set('n', 'gP', '"+P')
vim.keymap.set('n', 'gp', '"+p')
vim.keymap.set({'n', 'v'}, 'gy', '"+y')
vim.keymap.set('n', 'gY', '"+Y')

-- Bracket maps
-- For buffers -- default neovim 0.11
-- vim.keymap.set('n', ']b', vim.cmd.bnext, {desc = 'Next buffer'})
-- vim.keymap.set('n', '[b', vim.cmd.bprevious, {desc = 'Previous buffer'})
-- For arglist -- default neovim 0.11, better my way
vim.keymap.set('n', ']a', function()
    local ok, erro = pcall(vim.cmd.next)
    if not ok then
        if erro:match('Vim:E165:') then
            vim.cmd.previous({range = {vim.fn.argc() - 1 }})
        end
    end
end, {desc = 'Next arglist file'})
vim.keymap.set('n', '[a', function()
    local ok, erro = pcall(vim.cmd.previous)
    if not ok then
        if erro:match('Vim:E164:') then
            vim.cmd.next({range = {vim.fn.argc() - 1 }})
        end
    end
end, {desc = 'Previous arglist file'})

-- --- Mapleader Commands ---

-- open $MYVIMRC
vim.keymap.set(
	'n',
	'<leader>r',
	function()
		if vim.g.loaded_dirvish == 1 then -- plugin ativo
			vim.cmd.Dirvish(
				vim.fn.fnamemodify(vim.env.MYVIMRC, ':h') .. '/lua/andrikin'
			)
		else
			vim.cmd.edit(
				vim.fn.fnamemodify(vim.env.MYVIMRC, ':h') .. '/lua/andrikin/init.lua'
			)
		end
	end
)

-- --- Terminal ---
local toggle_list = function()
	local ttoggler = vim.g.ttoggler
    local tnumber = vim.api.nvim_tabpage_get_number(0)
    if tnumber <= 0 then
        vim.print('toggle_terminal: erro encontrado')
        return
    end
    local binfo = vim.fn.getbufinfo(ttoggler[tnumber] or 0)[1]
    if ttoggler[tnumber] and binfo then
        if binfo.hidden == 0 then
            vim.api.nvim_buf_call(
                ttoggler[tnumber],
                vim.cmd.close
            )
        else
            vim.cmd.split("+b" .. ttoggler[tnumber])
        end
    else
		vim.cmd.split('+terminal')
		local w = vim.api.nvim_get_current_win()
		local winfo = vim.fn.getwininfo(w)[1]
		local t = winfo.terminal == 1
		if t then
			ttoggler[tnumber] = winfo.bufnr
		else
			for win in ipairs(vim.api.nvim_list_wins()) do
				if vim.api.nvim_win_get_tabpage(win) == tnumber then
					local wininfo = vim.fn.getwininfo(win)[1]
					local isterminal = wininfo.terminal == 1
					if isterminal then
						ttoggler[tnumber] = wininfo.bufnr
						break
					end
				end
			end
		end
    end
	vim.g.ttoggler = ttoggler
end
vim.keymap.set('n', '<leader>t', toggle_list)

-- Nvim-Undotree plugin
vim.keymap.set(
	'n',
	'<leader>u',
	vim.cmd.Undotree
)

-- Fugitive maps
vim.keymap.set(
	'n',
	'<leader>g',
	vim.cmd.Git
)

-- mini.pick
-- https://github.com/nvim-mini/mini.nvim/issues/2186
vim.keymap.set( -- custom list for buffers
	'n', '<leader><space>',
    function()
        local choose = function(item)
            MiniPick.default_choose(vim.fn.expand(item))
        end
        local buffers = function()
            local blist = vim.api.nvim_exec2('buffers', {output = true})
            local items = {}
            for _, l in ipairs(vim.split(blist.output, '\n')) do
                local item = l:match('"(.*)"')
                table.insert(items, item)
            end
            return items
        end
        local show = function(buf, items, query)
            local nsid = vim.api.nvim_get_namespaces()['MiniPickBasename'] or vim.api.nvim_create_namespace('MiniPickBasename')
            vim.api.nvim_buf_clear_namespace(buf, nsid, 0, -1)
            MiniPick.default_show(buf, items, query, { show_icons = false })
            local extmark_opts = { virt_text_pos = 'inline' }
            for i = 1, #items do
                local line = i - 1
                local file = items[i]
                local basename = vim.fs.basename(file)
                extmark_opts.virt_text = { { basename .. ' ', 'MiniPickNormal' } }
                vim.api.nvim_buf_set_extmark(buf, nsid, line, 0, extmark_opts)
                local opts = {
                    end_row = i,
                    end_col = 0,
                    hl_mode = 'blend',
                    hl_group = 'Comment',
                    priority = 199
                }
                vim.api.nvim_buf_set_extmark(buf, nsid, line, 0 , opts)
            end
        end
        local pick = { source = {
            show = show,
            name = 'Buffers',
            items = buffers,
            choose = choose,
        } }
        MiniPick.start(pick)
    end
)
vim.keymap.set(
	'n', '<leader>h',
	function()
		vim.cmd.Pick('help')
	end
)

-- autocompletion LSP neovim 0.11
vim.keymap.set('i', '<c-space>',
	vim.lsp.completion.get
)
vim.keymap.set('i', '<c-j>',
	'pumvisible() ? "<c-y>" : "<c-j>"',
	{expr = true}
)

-- Removendo cliques do mouse em todos os modos - Nvy
if vim.g.nvy then
    vim.keymap.set({ 'n', 'v', 'i', 'c', 's', 'o', 't', 'l' },
        '<LeftMouse>',
        '<Nop>',
    { silent = true })
    vim.keymap.set({ 'n', 'v', 'i', 'c', 's', 'o', 't', 'l' },
        '<LeftDrag>',
        '<Nop>',
    { silent = true })
    vim.keymap.set({ 'n', 'v', 'i', 'c', 's', 'o', 't', 'l' },
        '<LeftRelease>',
        '<Nop>',
    { silent = true })
    vim.keymap.set({ 'n', 'v', 'i', 'c', 's', 'o', 't', 'l' },
        '<MiddleRelease>',
        '<Nop>',
    { silent = true })
    vim.keymap.set({ 'n', 'v', 'i', 'c', 's', 'o', 't', 'l' },
        '<RightRelease>',
        '<Nop>',
    { silent = true })
    vim.keymap.set({ 'n', 'v', 'i', 'c', 's', 'o', 't', 'l' },
        '<RightDrag>',
        '<Nop>',
    { silent = true })
    vim.keymap.set({ 'n', 'v', 'i', 'c', 's', 'o', 't', 'l' },
        '<RightMouse>',
        '<Nop>',
    { silent = true })
    vim.keymap.set({ 'n', 'v', 'i', 'c', 's', 'o', 't', 'l' },
        '<MiddleDrag>',
        '<Nop>',
    { silent = true })
    vim.keymap.set({ 'n', 'v', 'i', 'c', 's', 'o', 't', 'l' },
        '<MiddleMouse>',
        '<Nop>',
    { silent = true })
end

