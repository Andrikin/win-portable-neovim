if vim.g.started_by_firenvim then
    require('andrikin.firenvim')
    return
end

-- Inicialização normal neovim
require('andrikin.win')
require('andrikin.pack')
require('andrikin.lsp')
require('andrikin.options')
require('andrikin.maps')
require('andrikin.commands')
require('andrikin.autocmds')

