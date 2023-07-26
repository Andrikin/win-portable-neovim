" Automatic pairing for ({['""']})
" Autor: André Alexandre Aguiar
" Version: 0.1

if exists("g:loaded_awesome_pairing")
  finish
endif

let g:loaded_awesome_pairing = 1

let s:save_cpo = &cpo
set cpo&vim

function! s:forbided_cmd() abort
	" Don't pair char in those cmd modes
	return getcmdtype() =~ '[=?/]'
endfunction

function! s:get_char_before_cursor() abort
	let char = ''
	let col = col('.')
	if col > 1
		let char = getline('.')[col - 2]
	else
		let char = getline('.')[0]
	endif
	return char
endfunction

function! s:is_comment_line(line) abort
	if &l:commentstring == ''
		return 0
	endif
	let comment = substitute(
				\ substitute(
				\ substitute(&l:commentstring, '/', '\/', 'g'),
				\ '\*', '\\*', 'g'),
				\ '%s', '.*', '')
	let commented_line = join(
				\ ['^\(\|\s\{1,}\)', comment, '$', '\|', '^\(\|\t\{1,}\)', comment, '$' ],
				\ '') 
	return a:line =~ commented_line
endfunction

function! s:get_closing_char(c) abort
	let pair = ''
	let left = "\<left>"
	if a:c =~ "[\[{<]"
		let pair = join([a:c, nr2char(char2nr(a:c) + 2), left], '')
	elseif a:c == '('
		let pair = join(['()', left], '')
	elseif a:c =~ "['\"`]"
		let pair = join([a:c, a:c, left], '')
	else
		let pair = a:c
	endif
	return pair
endfunction

function! s:cmd_pairing_char(c) abort
	let line = getcmdline()
	if s:forbided_cmd() || (a:c =~ "[`']" && empty(line)) || line =~ "^[`']"
		return a:c
	endif
	let pair = ''
	if line =~ '^g\/\|^[0-9]\{1,},[0-9]\{1,}s[\/:]\|^.s[\/:]\|^[0-9]\{1,},[0-9]\{1,}g\/'
		let pair = a:c
	else
		let pair = s:get_closing_char(a:c)
	endif
	return pair
endfunction

" TODO: Compreender as situações em que não se deve inserir o caracter complementado
function! s:ins_pairing_char(c) abort
	" Verify if we are in a comment line
	let pair = ''
	let bchar = s:get_char_before_cursor()
	let line = getline('.')
	if s:is_comment_line(line) && a:c =~ "['\"]" && bchar =~ '\w'
		let pair = a:c
	else
		if bchar =~ '\w'
			" HACK: Não incluir c duplicado nos códigos Python, tanto em comentários
			" como para doc string's
			" TODO: Identificar situação em que o comentário é uma multistring
			if &filetype == 'python' 
						\ && (bchar !~ 'f\|b\|r' 
						\ && (line =~ "'" . '\{3}.*' . "'" . '\{,3}' 
						\ || line =~ '"\{3}.*"\{,3}'))
				let pair = a:c
			endif
		endif
		" HACK: Don't put double caracters when start a comment
		if &filetype == 'vim' && a:c =~ "['\"]"
			if len(str2list(line)) == 0 || line =~ '^\s\{1,}$'
				let pair = a:c
			endif
		endif
	endif
	return pair == '' ? s:get_closing_char(a:c) : pair
endfunction

function! s:pair(c) abort
	let cmd = ''
	if len(getcmdtype())
		let cmd = s:cmd_pairing_char(a:c)
	elseif mode() =~ 'i'
		let cmd = s:ins_pairing_char(a:c)
	endif
	return cmd
endfunction

if !hasmapto('<plug>(AwesomePairing)', 'ci')

	augroup awesomepairing
		autocmd!
	augroup END

	autocmd awesomepairing FileType html noremap! <expr> < <SID>pair('<')
	autocmd awesomepairing FileType javascript,html noremap! <expr> ` <SID>pair('`')

	noremap! <expr> ( <SID>pair('(')
	noremap! <expr> [ <SID>pair('[')
	noremap! <expr> { <SID>pair('{')
	noremap! <expr> " <SID>pair('"')
	noremap! <expr> ' <SID>pair("'")

endif

let &cpo = s:save_cpo
unlet s:save_cpo
