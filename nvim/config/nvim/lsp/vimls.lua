return {
    cmd = { 'vim-language-server', '--stdio' },
    filetypes = { 'vim' },
    root_markers = function(fname)
        return vim.fs.dirname(vim.fs.find('.git', { path = fname, upward = true })[1])
    end,
    single_file_support = true,
    init_options = {
        isNeovim = true,
        iskeyword = '@,48-57,_,192-255,-#',
        vimruntime = '',
        runtimepath = '',
        diagnostic = { enable = true },
        indexes = {
            runtimepath = true,
            gap = 100,
            count = 3,
            projectRootPatterns = { 'runtime', 'nvim', '.git', 'autoload', 'plugin' },
        },
        suggest = { fromVimruntime = true, fromRuntimepath = true },
    },
}
