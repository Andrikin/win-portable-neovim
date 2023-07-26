" substitute.vim - %s///g automatic cmdline fill
" Autor: André Alexandre Aguiar
" Version: 0.1
" Dependences: traces.vim

if exists("g:loaded_awesome_substitute")
  finish
endif
let g:loaded_awesome_substitute = 1

let s:save_cpo = &cpo
set cpo&vim

function! s:spreadtheword() abort
	let word = expand('<cword>')
	let cmd = ":\<c-u>'<,'>s:\\v<" . word . ">\\C::g\<left>\<left>"
	return cmd
endfunction

" Stealing idea from Tim Pope
function! s:startthething(...) abort
	" When first start, function call itself passing motion args
	if !a:0
		let s:word = expand('<cword>')
		let &operatorfunc = matchstr(expand('<sfile>'), '[^. ]*$')
		return 'g@'
	elseif a:1 == 'line'
		let cmd = ":'[,']s:\\v<" . s:word . ">\\C::g\<left>\<left>"
	elseif a:1 == 'char'
		normal! `[v`]y
		let s:word = getreg('0')
		let cmd = ":%s:\\v<" . s:word . ">\\C::g\<left>\<left>"
	else
		return ''
	endif
	" When calling 'g@', 'return cmd' (to populate command line) don't work. Have to use feedkeys()
	call feedkeys(cmd)
endfunction

nnoremap <expr> <plug>(AwesomeSubstitute) <SID>startthething()
xnoremap <expr> <plug>(AwesomeSubstitute) <SID>spreadtheword()

if !hasmapto('<plug>(AwesomeSubstitute)')
	nmap s <plug>(AwesomeSubstitute)
	xmap s <plug>(AwesomeSubstitute)
	" In the line
	nnoremap ss :s:\<<c-r><c-w>\>\C::g<left><left>
endif

let &cpo = s:save_cpo
unlet s:save_cpo

" I can call functions that returns no value, but can do something
" xnoremap <expr> <plug>(AwesomeSubstitute) ":\<c-u>" . (<SID>get_word()) . (<SID>spreadtheword()) . "\<c-r>=<SID>set_cur_pos()\<cr>"
