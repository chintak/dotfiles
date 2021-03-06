" ALE

" Automatic completion
let g:ale_completion_enabled = 1
let g:ale_lint_on_enter = 1
let g:ale_lint_on_insert_leave = 0
let g:ale_sign_warning = '>'
let g:ale_sign_error = '>>'
let g:ale_fix_on_save = 0
" let b:ale_fix_on_save = 1

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

highlight link ALEWarningSign String
highlight link ALEErrorSign Title

nmap <silent> Q <Plug>(ale_previous_wrap)
nmap <silent> q <Plug>(ale_next_wrap)

" Include the linter name (e.g. 'hack' or 'hhast'), code, and message in errors
let g:ale_echo_msg_format = '[%linter%]% [code]% %s'

nnoremap <Leader>at :call FixOnSaveBufferToggle()<CR>
nnoremap <Leader>af :ALEFix<CR>:w<CR>
nnoremap <Leader>al :ALELint<CR>
autocmd BufWritePost * :ALELint

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
  \   'python': ['flake8', 'pyls'],
  \   'cpp': ['cquery_buck'],
  \   'javascript': ['eslint'],
  \   'javascript.jsx': ['eslint'],
  \   'typescript': ['tslint', 'typecheck', 'tsserver'],
  \   'typescript.tsx': ['tslint', 'typecheck', 'tsserver'],
  \   'zsh': ['shell']
\}

let g:ale_fixers = {
\   '*': ['remove_trailing_lines', 'trim_whitespace'],
\   'python': [
\       'autopep8',
\       'black',
\       'isort'
\   ],
\   'c': ['clang-format'],
\   'cpp': ['clang-format'],
\   'hack': ['hackfmt'],
\   'thrift': ['remove_trailing_lines', 'trim_whitespace'],
\   'javascript': ['prettier'],
\   'javascript.jsx': ['prettier'],
\   'typescript': ['prettier'],
\   'typescript.tsx': ['prettier']
\}
