" WARNING: Sempre colocar este arquivo no endereço "$VIM/sysinit.vim"
" System variables cofiguration for thumbdriver (Portable NVIM)

lua << EOF
	local fn = vim.fn
	local opt = vim.opt
	local loader = vim.loader
	local env = vim.env

	if fn.has('win32') then
		env.HOME = string.sub(env.VIMRUNTIME, 1, 3) .. [[nvim-portable-win]]
		env.XDG_CONFIG_HOME = env.HOME .. [[\nvim\config]]
		env.XDG_DATA_HOME = env.XDG_CONFIG_HOME
		env.XDG_STATE_HOME = env.XDG_DATA_HOME
		env.NVIM_LOG_FILE = fn.stdpath('data') .. [[\log]]
	end

	opt.rtp:remove(opt.rtp:get())
	opt.rtp:append(fn.stdpath('config'))
	opt.rtp:append(fn.stdpath('data') .. [[\site]])

	loader.enable()
EOF

"if has('win32')
"	let $HOME=$VIMRUNTIME[0:2].'nvim-portable-win' " modificar para obter somente a localização do USB
"	let $XDG_CONFIG_HOME=$HOME.'\nvim\config' " ~/AppData/Local/nvim
"	let $XDG_DATA_HOME=$XDG_CONFIG_HOME " ~/AppData/Local/nvim-data
"	let $XDG_STATE_HOME=$XDG_DATA_HOME
"	let $NVIM_LOG_FILE=stdpath('data').'\log'
"	" Set 'runtimepath' to Neovim look for files to load in runtime
"	set runtimepath=
"	execute 'set runtimepath+='.stdpath('config').','.stdpath('data').'\site'
"endif
""
"" Neovim Loader - aka impatient.nvim (Speed up loading Lua modules in Neovim to improve startup time.)
"lua vim.loader.enable()

