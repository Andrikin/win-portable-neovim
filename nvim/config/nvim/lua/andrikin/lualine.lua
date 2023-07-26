-- Configuração padrão lualine - THEMES.md
local tema = 'dracula'

require('lualine').setup(
	{
		options = { theme = tema },
		winbar = {
			lualine_a = {},
			lualine_b = {},
			lualine_c = {'filename'},
			lualine_x = {},
			lualine_y = {},
			lualine_z = {}
		}
	}
)
