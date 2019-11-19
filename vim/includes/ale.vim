" ALE

let g:ale_lint_on_text_changed = 'never'
let g:ale_lint_on_enter = 0
let g:ale_lint_on_insert_leave = 1
let g:ale_sign_warning = '▲'
let g:ale_sign_error = '✗'
let g:ale_fix_on_save = 1
let b:ale_fix_on_save = 1

function! FixOnSaveBufferToggle()
    if !exists("b:ale_fix_on_save")
        let b:ale_fix_on_save = 1
    endif

    if b:ale_fix_on_save == 1
        echo "ALE Auto fix on save disabled for this buffer!!!"
        let b:ale_fix_on_save = 0
    else
        echo "ALE Auto fix on save enabled for this buffer!!!"
        let b:ale_fix_on_save = 1
    endif
endfunction

nnoremap <silent> <leader>m :call FixOnSaveBufferToggle()<CR>

highlight link ALEWarningSign String
highlight link ALEErrorSign Title

nmap <silent> Q <Plug>(ale_previous_wrap)
nmap <silent> q <Plug>(ale_next_wrap)

" Automatic completion
let g:ale_completion_enabled = 1
" Include the linter name (e.g. 'hack' or 'hhast'), code, and message in errors
let g:ale_echo_msg_format = '[%linter%]% [code]% %s'

" Press `K` to view the type in the gutter
nnoremap <silent> K :ALEHover<CR>
" Type `gd` to go to definition
nnoremap <silent> gd :ALEGoToDefinitionInTab<CR>
" Meta-click (command-click) to go to definition
nnoremap <M-LeftMouse> <LeftMouse>:ALEGoToDefinitionInTab<CR>

" show type on hover in a floating bubble
if v:version >= 801
  set balloonevalterm
  let g:ale_set_balloons = 1
  let balloondelay = 250
endif

set omnifunc=ale#completion#OmniFunc

let g:ale_linters = {
  \   'go': ['gofmt', 'gometalinter'],
  \   'hack': ['hack', 'hhast'],
  \   'python': ['flake8'],
  \   'javascript': ['eslint'],
  \   'javascript.jsx': ['eslint'],
  \   'typescript': ['tslint', 'typecheck', 'tsserver'],
  \   'typescript.tsx': ['tslint', 'typecheck', 'tsserver'],
  \   'zsh': ['shell']
\}

let g:ale_fixers = {
\   'python': [
\       'black',
\       'isort',
\       'remove_trailing_lines',
\       'trim_whitespace'
\   ],
\   'hack': [
\       'hackfmt',
\       'remove_trailing_lines',
\       'trim_whitespace'
\   ],
\   'javascript': [
\       'prettier',
\       'remove_trailing_lines',
\       'trim_whitespace'
\   ],
\   'javascript.jsx': [
\       'prettier',
\       'remove_trailing_lines',
\       'trim_whitespace'
\   ],
\   'typescript': [
\	    'prettier',
\       'remove_trailing_lines',
\       'trim_whitespace'
\   ],
\   'typescript.tsx': [
\	    'prettier',
\       'remove_trailing_lines',
\       'trim_whitespace'
\   ]
\}


