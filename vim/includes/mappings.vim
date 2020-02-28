" search easily
nnoremap / /\v
vnoremap / /\v

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

" show and hide errors
"nmap <silent> q :lnext<CR>
"nmap <silent> Q :lnext<CR>

" Keep search pattern at the center of the screen - http://vimbits.com/bits/92
nnoremap <silent> n nzz
nnoremap <silent> N Nzz
nnoremap <silent> * *zz
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
map <Leader>b :bufdo bd<CR>
nnoremap <up> :bprevious<CR>
nnoremap <down> :bnext<CR>

set nofoldenable    " disable folding

" Multiple cursors
nmap <silent> <C-n> <Plug>(VM-Find-Under)
xmap <silent> <C-n> <Plug>(VM-Find-Subword-Under)

" Motion
nmap f <Plug>(easymotion-bd-f)
nmap F <Plug>(easymotion-overwin-f)
