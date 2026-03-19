" WARNING: Sempre colocar este arquivo no endereço "$VIM/sysinit.vim"
" Configuração de variáveis do nvim para uso em pendrive (modo portable)

lua << EOF
    -- mkdir function
	local mkdir = function(path)
		-- check for directory and create it if not found
		if vim.fn.isdirectory(path) == 0 then
			vim.fn.mkdir(path, 'p', '0755')
		end
	end
    -- XDG variables
	vim.env.HOME = string.match(vim.env.VIMRUNTIME, '^(.*win.portable.neovim).*$')
	vim.env.XDG_CONFIG_HOME = vim.env.HOME .. '\\nvim\\config'
	mkdir(vim.env.XDG_CONFIG_HOME)
	vim.env.XDG_DATA_HOME = vim.env.XDG_CONFIG_HOME
	vim.env.XDG_STATE_HOME = vim.env.XDG_DATA_HOME
	-- vim.env.NVIM_LOG_FILE = vim.fn.stdpath('data') .. '\\log'
	-- mkdir(vim.env.NVIM_LOG_FILE)
    -- runtimepaths
	local site = vim.fn.stdpath('data') .. '\\site' -- custom vim plugins
	local after = vim.fn.stdpath('config') .. '\\after'
	local lsp = vim.fn.stdpath('config') .. '\\lsp'
	mkdir(site)
	mkdir(after)
	mkdir(lspsite)
    -- AppLocal directory
    local applocal = vim.tbl_filter(function(opt) return opt:match('AppLocal') end, vim.opt.rtp:get())
	vim.opt.rtp:remove(applocal) -- remove only AppLocal from runtime
    vim.opt.runtimepath:prepend(after)
    vim.opt.runtimepath:prepend(lsp)
	vim.opt.runtimepath:prepend(site)
    -- add $XDG_CONFIG_HOME/after/ftplugin
	vim.opt.runtimepath:append(vim.fn.stdpath('config'))
    -- vim.pack paths
	vim.opt.packpath:prepend(site)
    -- utils.lua
	if not vim.env.NVIM_OPT then
		vim.env.NVIM_OPT = vim.env.HOME .. '\\nvim\\opt'
	end
    -- load them all!
    if vim.loader then vim.loader.enable() end
EOF

