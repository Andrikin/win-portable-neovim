" WARNING: Sempre colocar este arquivo no endereço "$VIM/sysinit.vim"
" Configuração de variáveis do nvim para uso em pendrive (modo portable)

lua << EOF
	vim.env.HOME = string.match(vim.env.VIMRUNTIME, '^(.*nvim.portable.win).*$')
	vim.env.XDG_CONFIG_HOME = vim.env.HOME .. [[\nvim\config]]
	vim.env.XDG_DATA_HOME = vim.env.XDG_CONFIG_HOME
	vim.env.XDG_STATE_HOME = vim.env.XDG_DATA_HOME
	vim.env.NVIM_LOG_FILE = vim.fn.stdpath('data') .. [[\log]]
	vim.opt.rtp:remove(vim.opt.rtp:get())
	vim.opt.rtp:append(vim.fn.stdpath('config'))
	vim.opt.rtp:append(vim.fn.stdpath('data') .. [[\site]])
	vim.loader.enable()
EOF

