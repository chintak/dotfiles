map <Leader> <Plug>(easymotion-prefix)

"map  <Leader><Leader> <Plug>(easymotion-bd-f)
"nmap <Leader><Leader> <Plug>(easymotion-overwin-f)

" <Leader>f{char} to move to {char}
"map  <Leader><Leader> f(easymotion-bd-f)
"nmap <Leader><Leader> f(easymotion-overwin-f)

" s{char}{char} to move to {char}{char}
nmap s <Plug>(easymotion-overwin-f2)

" Move to line
map \ <Plug>(easymotion-bd-jk)
nmap \ <Plug>(easymotion-overwin-line)

" Move to word
map  <Leader>w <Plug>(easymotion-bd-w)
nmap <Leader>w <Plug>(easymotion-overwin-w)

" JK motions: Line motions
" map ] <Plug>(easymotion-j)
" map [ <Plug>(easymotion-k)

" Motion
nmap f <Plug>(easymotion-bd-f)
nmap F <Plug>(easymotion-overwin-f)

let g:EasyMotion_startofline = 0 " keep cursor column when JK motion
let g:EasyMotion_smartcase = 1
