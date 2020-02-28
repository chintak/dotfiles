" Lightline
let g:lightline = {
\ 'colorscheme': 'wombat',
\ 'active': {
\   'left': [['mode', 'paste'], ['absolutepath', 'modified']],
\   'right': [['lineinfo'], ['percent'], ['readonly', 'linter_warnings', 'linter_errors', 'linter_ok'], ['hack'], ['flow']]
\ },
\ 'component_expand': {
\   'linter_warnings': 'LightlineLinterWarnings',
\   'linter_errors': 'LightlineLinterErrors',
\   'linter_ok': 'LightlineLinterOK'
\ },
\ 'component_type': {
\   'readonly': 'error',
\   'linter_warnings': 'warning',
\   'linter_errors': 'error'
\ },
\ 'component_function': {
\   'hack': 'LightlineHackStatus',
\   'flow': 'LightlineFlowStatus',
\ },
\ }
function! LightlineLinterWarnings() abort
  let l:counts = ale#statusline#Count(bufnr(''))
  let l:all_errors = l:counts.error + l:counts.style_error
  let l:all_non_errors = l:counts.total - l:all_errors
  return l:counts.total == 0 ? '' : printf('%d ◆', all_non_errors)
endfunction
function! LightlineLinterErrors() abort
  let l:counts = ale#statusline#Count(bufnr(''))
  let l:all_errors = l:counts.error + l:counts.style_error
  let l:all_non_errors = l:counts.total - l:all_errors
  return l:counts.total == 0 ? '' : printf('%d ✗', all_errors)
endfunction
function! LightlineLinterOK() abort
  let l:counts = ale#statusline#Count(bufnr(''))
  let l:all_errors = l:counts.error + l:counts.style_error
  let l:all_non_errors = l:counts.total - l:all_errors
  return l:counts.total == 0 ? '✓ ' : ''
endfunction

" Update and show lightline but only if it's visible (e.g., not in Goyo)
autocmd User ALELint call s:MaybeUpdateLightline()
function! s:MaybeUpdateLightline()
  if exists('#lightline')
    call lightline#update()
  end
endfunction

let g:hack_last_result = ""
let g:hack_show_in_lightline = 0

function! LightlineHackStatus()
  if g:hack_show_in_lightline == 0
    return ""
  endif
  return g:hack_last_result
endfunction

function! UpdateHackStatus(channel, msg)
  let g:hack_last_result = "HACK => ".a:msg
  if exists('g:backgroundCommandOutput')
    unlet g:backgroundCommandOutput
  endif
endfunction

function! UpdateHackStatusError(channel, msg)
    let g:hack_last_result = "HACK => Can't find .hhconfig in the root directory"
    if exists('g:backgroundCommandOutput')
      unlet g:backgroundCommandOutput
    endif
endfunction

" let tempHackUpdateStatusTimer = timer_start(1000, 'PeriodicHackStatus')
" function! PeriodicHackStatus(timer_id)
"   if !exists('g:backgroundCommandOutput')
"     let g:backgroundCommandOutput = tempname()
"     let tail = "tail -n1 $(hh_client --logname)"
"     let removeDate = "awk '{$1=\\\"\\\";$2=\\\"\\\"; print $0;}'"
"     let removeSpaces = "sed -e 's/^[[:space:]]*//' | tr -d '\\\\n'"
"     let command = tail." | ".removeDate." | ".removeSpaces
"     let job = job_start("/bin/bash -c \"".command."\"", {"out_cb": "UpdateHackStatus", "err_cb": "UpdateHackStatusError"})
"   else
"     let l:tempHackUpdateStatusTimer = timer_start(1000, 'PeriodicHackStatus')
"   endif
" endfunction

let g:flow_last_result = ""
let g:flow_show_in_lightline = 0

function! LightlineFlowStatus()
  if g:flow_show_in_lightline == 0
    return ""
  endif
  return g:flow_last_result
endfunction

function! UpdateFlowStatus(channel, msg)
  let g:flow_last_result = "FLOW => ".a:msg
  if exists('g:flowCommandOutput')
    unlet g:flowCommandOutput
  endif
endfunction

function! UpdateFlowStatusError(channel, msg)
    let g:flow_last_result = "FLOW => no server is running"
    if exists('g:flowCommandOutput')
      unlet g:flowCommandOutput
    endif
endfunction

" let tempFlowUpdateStatusTimer = timer_start(1000, 'PeriodicFlowStatus')
" function! PeriodicFlowStatus(timer_id)
"   if !exists('g:flowCommandOutput')
"     let g:flowCommandOutput = tempname()
"     let tail = "flow status --no-auto-start --one-line"
"     let removeSpaces = "sed -e 's/^[[:space:]]*//' | tr -d '\\\\n'"
"     let command = tail." | ".removeSpaces
"     let job = job_start("/bin/bash -c \"".command."\"", {"out_cb": "UpdateFlowStatus", "err_cb": "UpdateFlowStatusError"})
"   else
"     let l:tempFlowUpdateStatusTimer = timer_start(1000, 'PeriodicFlowStatus')
"   endif
" endfunction

" let tempTimer = timer_start(1000, 'UpdateLightline')
" function UpdateLightline(timer_id)
"     call lightline#update()
"     let l:tempTimer = timer_start(1000, 'UpdateLightline')
" endfunction
