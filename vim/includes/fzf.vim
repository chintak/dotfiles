" FZF (replaces Ctrl-P, FuzzyFinder and Command-T)
set rtp+=~/.fzf

let g:fzf_buffers_jump = 1
let g:fzf_action = {
  \ 'alt-enter': 'tab split',
  \ 'ctrl-t': 'tab split',
  \ 'ctrl-x': 'split',
  \ 'ctrl-v': 'vsplit' }
let g:fzf_history_dir = '~/.local/share/fzf-history'

" Customize fzf colors to match your color scheme
let g:fzf_colors =
\ { 'fg':      ['fg', 'Normal'],
  \ 'bg':      ['bg', 'Normal'],
  \ 'hl':      ['fg', 'Comment'],
  \ 'fg+':     ['fg', 'CursorLine', 'CursorColumn', 'Normal'],
  \ 'bg+':     ['bg', 'CursorLine', 'CursorColumn'],
  \ 'hl+':     ['fg', 'Statement'],
  \ 'info':    ['fg', 'PreProc'],
  \ 'border':  ['fg', 'Ignore'],
  \ 'prompt':  ['fg', 'Conditional'],
  \ 'pointer': ['fg', 'Exception'],
  \ 'marker':  ['fg', 'Keyword'],
  \ 'spinner': ['fg', 'Label'],
  \ 'header':  ['fg', 'Comment'] }

let repo_path = system('hg root')
let repo_initial = 'z'
if repo_path =~# 'configerator'
    let repo_initial = 'c'
elseif repo_path =~# 'www'
    let repo_initial = 't'
elseif repo_path =~# 'fbcode'
    let repo_initial = 'f'
endif

command! -bang -nargs=* Bgs
  \ call fzf#vim#grep(
  \   repo_initial . 'bgs --color=on -s '.shellescape(<q-args>), 1,
  \   <bang>0 ? fzf#vim#with_preview('up:60%')
  \           : fzf#vim#with_preview('up:40%'),
  \   <bang>0)

command! -bang -nargs=* Bgf
  \ call fzf#vim#grep(
  \   repo_initial . 'bgf --color=on -s '.shellescape(<q-args>), 1,
  \   <bang>0 ? fzf#vim#with_preview('up:60%')
  \           : fzf#vim#with_preview('up:40%:hidden', '?'),
  \   <bang>0)

" Likewise, Files command with preview window
command! -bang -nargs=? -complete=dir Files
  \ call fzf#vim#files(
  \   <q-args>,
  \   <bang>0 ? fzf#vim#with_preview('up:60%')
  \           : fzf#vim#with_preview('right:40%:hidden', '?'),
  \   <bang>0)

" nmap <Leader>c :Tags<CR>
nmap <Leader>; :Buffers<CR>
nmap <Leader>t :Files<CR>
nmap <Leader>y :FZF %:h<CR>
nmap <Leader>p :Files %:h
nmap <Leader>r :Rg<CR>
nmap <Leader>g "zyaw:exe "Bgs ".@z.""<CR>
nmap <Leader>bf "zyaw:exe "Bgf ".@z.""<CR>

