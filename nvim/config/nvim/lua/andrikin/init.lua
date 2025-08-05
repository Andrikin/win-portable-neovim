if not vim.g.started_by_firenvim then
    -- Inicialização normal neovim
    require('andrikin.os')
    require('andrikin.lazy')
    require('andrikin.lsp')
    require('andrikin.options')
    require('andrikin.maps')
    require('andrikin.commands')
    require('andrikin.autocmds')
else
    require('andrikin.firenvim')
end

