if vim.loader then vim.loader.enable() end

if vim.g.started_by_firenvim then
    require('andrikin.firenvim')
    do return end
end
-- Inicialização normal neovim
require('andrikin.os')
if not package.loaded["andrikin.lazy"] then
    require('andrikin.lazy')
end
require('andrikin.lsp')
require('andrikin.options')
require('andrikin.maps')
require('andrikin.commands')
require('andrikin.autocmds')

