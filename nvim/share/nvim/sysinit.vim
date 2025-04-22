" WARNING: Sempre colocar este arquivo no endereço "$VIM/sysinit.vim"
" Configuração de variáveis do nvim para uso em pendrive (modo portable)

lua << EOF
	local init = function(path)
		-- check for directory and create it if not found
		if vim.fn.isdirectory(path) == 0 then
			vim.fn.mkdir(path, 'p', '0755')
		end
	end
	vim.env.HOME = string.match(vim.env.VIMRUNTIME, '^(.*win.portable.neovim).*$')
	vim.env.XDG_CONFIG_HOME = vim.env.HOME .. '\\nvim\\config'
	init(vim.env.XDG_CONFIG_HOME)
	vim.env.XDG_DATA_HOME = vim.env.XDG_CONFIG_HOME
	vim.env.XDG_STATE_HOME = vim.env.XDG_DATA_HOME
	vim.env.NVIM_LOG_FILE = vim.fn.stdpath('data') .. '\\log'
	init(vim.env.NVIM_LOG_FILE)
	local site = vim.fn.stdpath('data') .. '\\site' -- custom vim plugins
	init(site)
    local applocal = vim.tbl_filter(function(opt) return opt:match('AppLocal') end, vim.opt.rtp:get())
	vim.opt.rtp:remove(applocal) -- remove only AppLocal from runtime
	vim.opt.rtp:append(vim.fn.stdpath('config'))
	vim.opt.rtp:append(site)
	vim.loader.enable()
	if not vim.env.NVIM_OPT then
		vim.env.NVIM_OPT = vim.env.HOME .. '\\nvim\\opt'
	end
EOF

