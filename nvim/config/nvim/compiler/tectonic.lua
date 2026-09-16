if not vim.fn.executable('tectonic.exe') == 1 then
    return
end

local MODELOS = vim.fs.joinpath(
    vim.fn.fnamemodify(vim.env.MYVIMRC, ':h:h:h:h:h'),
    'projetos',
    'ouvidoria-latex',
    'modelos'
)
if vim.uv.fs_stat(MODELOS) then
    vim.bo.makeprg = 'tectonic -X compile -o %:h:S -Z search-path='
    .. MODELOS
    .. ' -Z continue-on-errors %:S'
else
    vim.bo.makeprg = 'tectonic -X compile -o %:h:S -Z continue-on-errors %:S'
end

-- single file compilation
-- tectonic don't give absolute paths in his error messages
vim.bo.errorformat={
    '%+Awarning: %f:%l: %m',
    '%+N%>note: Writing `%f` %m',
    '%-Gnote: "version 2" Tectonic command-line interface activated',
    '%-Gnote: Running TeX ...',
    '%-Gnote: Rerunning TeX because "ata-ouvidoria-lai.aux" changed ...',
    '%-GFontconfig error: Cannot load default config file: No such file: (null)',
    '%-Gwarning: accessing absolute path%m',
    '%-Gwarning: open of input%m',
    '%-Gcaused by: access to the path%m',
    '%-Gwarning: ICC profile%m',
    '%-Gwarning: warnings were issued by the TeX engine%m',
    '%-Nnote: Running xdvipdfmx ...',
    '%-Nnote: Skipped writing %m',
}
