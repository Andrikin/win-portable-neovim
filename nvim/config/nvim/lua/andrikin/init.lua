if vim.g.started_by_firenvim then
    require('andrikin.firenvim')
    do return end
end
-- Inicialização normal neovim
require('andrikin.os')
require('andrikin.lazy')
require('andrikin.lsp')
require('andrikin.options')
require('andrikin.maps')
require('andrikin.commands')
require('andrikin.autocmds')

