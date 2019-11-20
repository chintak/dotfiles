let g:deoplete#enable_at_startup = 1

" Use ALE and filesystem as completion sources for all code.
call deoplete#custom#option('sources', {
\ '_': ['ale', 'file'],
\})

" use tab to forward cycle
"inoremap <silent><expr><tab> pumvisible() ? "\<c-n>" : "\<tab>"
" use tab to backward cycle
"inoremap <silent><expr><s-tab> pumvisible() ? "\<c-p>" : "\<s-tab>"

" <CR>: If popup menu visible, expand snippet or close popup with selection,
"       Otherwise, check if within empty pair and use delimitMate.
"inoremap <silent><expr><CR> pumvisible() ?
	"\ (deoplete#close_popup())
"\ : (delimitMate#WithinEmptyPair() ? "\<C-R>=delimitMate#ExpandReturn()\<CR>" : "\<CR>")

inoremap <silent><expr> <TAB>
		\ pumvisible() ? "\<C-n>" :
		\ <SID>check_back_space() ? "\<TAB>" :
		\ deoplete#manual_complete()
		function! s:check_back_space() abort "{{{
		let col = col('.') - 1
		return !col || getline('.')[col - 1]  =~ '\s'
		endfunction"}}}

inoremap <expr> <CR> (pumvisible() ? "\<c-y>\<cr>" : "\<CR>")
