" search easily
nnoremap / /\v
vnoremap / /\v

" Escape to Normal mode using jj
inoremap jj <ESC>

" remove search highlight
nnoremap <leader><space> :noh<cr>

" cycle through parenthesis
nnoremap <tab> %
vnoremap <tab> %

" no more arrows for you
nnoremap <up> <nop>
nnoremap <down> <nop>
nnoremap <left> :tabp<CR>
nnoremap <right> :tabn<CR>
nnoremap j gjzz
nnoremap k gkzz

" buffer window movement map
nnoremap <bslash> <C-w>
nnoremap <bslash>w <C-w><C-w>

" tabs
" nnoremap { :tabp<CR>
" nnoremap } :tabn<CR>
" nnoremap [ :tabp<CR>
" nnoremap ] :tabn<CR>

nnoremap <F7> :tabp<CR>
nnoremap <F6> :tabn<CR>
inoremap <F7> :tabp<CR>
inoremap <F6> :tabn<CR>

" please no help ever
inoremap <F1> <ESC>
nnoremap <F1> <ESC>
vnoremap <F1> <ESC>

" use ; as leader as well
nnoremap ; :

" linux CTRL+T
map <F1> :tabnew<CR>
map tt :tabnew<CR>
map tc :tabclose<CR>
map td :bdelete<CR>

" show and hide errors
"nmap <silent> q :lnext<CR>
"nmap <silent> Q :lnext<CR>

" Keep search pattern at the center of the screen - http://vimbits.com/bits/92
nnoremap <silent> n nzz
nnoremap <silent> N Nzz
nnoremap <silent> * *zz
vnoremap <silent> * y/<C-r>"<CR>
nnoremap <silent> # #zz
nnoremap <silent> g* g*zz
nnoremap <silent> g# g#zz

nnoremap <silent> ]] ]]zz
nnoremap <silent> [[ [[zz

" close quick tips
map <silent><F12> :cclose<cr>

" whitespace
"
":nnoremap <silent> <Leader>m :let _s=@/<Bar>:%s/\s\+$//e<Bar>:let @/=_s<Bar>:nohl<CR>
":nnoremap <silent> <Leader>m :StripWhitespace

" delete all buffers
function! s:bdelnum(action, args)
    for arg in split(a:args)
        let bounds = split(arg, ',')
        if len(bounds) == 2
            for idx in range(str2nr(bounds[0]), str2nr(bounds[1]))
                execute a:action . " " . bufname(idx)
            endfor
        else
            execute a:action . " " . bufname(str2nr(arg))
        endif
    endfor
endfunction
command! -complete=buffer -nargs=? BWipeout
            \ :call s:bdelnum("Bwipeout", <f-args>)
command! -complete=buffer -nargs=? BDelete
            \ :call s:bdelnum("Bdelete", <f-args>)

nnoremap <Leader>Q :bufdo Bwipeout<CR>
nnoremap <up> :bprevious<CR>
nnoremap <down> :bnext<CR>
nnoremap <Leader>q :Bwipeout<CR>
nnoremap <Leader>d :ls<CR>:BWipeout<Space>

" Multiple cursors
nmap <silent> <C-n> <Plug>(VM-Find-Under)
xmap <silent> <C-n> <Plug>(VM-Find-Subword-Under)

" Scroll in other window
nmap <C-k> <C-w>w<C-y><C-w>w
nmap <C-j> <C-w>w<C-e><C-w>w

" vim-signify
nnoremap <Leader>hd :SignifyDiff<CR>
nnoremap <Leader>hu :SignifyHunkUndo<CR>
"   hunk jumping
" nmap gc <Plug>(signify-next-hunk)
" nmap gp <Plug>(signify-prev-hunk)
"   hunk text object
omap ic <Plug>(signify-motion-inner-pending)
xmap ic <Plug>(signify-motion-inner-visual)
omap ac <Plug>(signify-motion-outer-pending)
xmap ac <Plug>(signify-motion-outer-visual)
