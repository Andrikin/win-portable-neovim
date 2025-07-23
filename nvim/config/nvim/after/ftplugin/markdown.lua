vim.treesitter.start()
vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
local buf = vim.api.nvim_get_current_buf()
vim.bo[buf].textwidth = 80
