if vim.b.did_markdown then
    do return end
end
local buf = vim.api.nvim_get_current_buf()
vim.bo[buf].textwidth = 80
vim.b.did_markdown = true
