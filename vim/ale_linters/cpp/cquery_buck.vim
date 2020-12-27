" Author: Ben Falconer <ben@falconers.me.uk>, Gabriel Wicke <gwicke@fb.com>
" Description: A wrapper for buck & cquery, for use with fbcode.
" Usage: ln -s or copy to ~/.vim/bundle/ale/ale_linters/cpp/. ALE should pick up
" the linter automatically.

call ale#Set('cpp_cquery_buck_executable',
    \ expand('/data/users/$USER/fbsource/fbcode/experimental/gwicke/vim/fbcode_cquery_wrapper'))
call ale#Set('cpp_cquery_buck_cache_directory', expand('/tmp/cquery_cache'))

function! ale_linters#cpp#cquery_buck#GetProjectRoot(buffer) abort
    let l:project_root = ale#path#FindNearestFile(a:buffer, '.buckconfig')

    return !empty(l:project_root) ? fnamemodify(l:project_root, ':h') : ''
endfunction

function! ale_linters#cpp#cquery_buck#GetInitializationOptions(buffer) abort
    return {
      \  'cacheDirectory': ale#Var(a:buffer, 'cpp_cquery_buck_cache_directory'),
      \  'index': {
      \    'blacklist': ['.*/buck-out/.*', '.*/third-party-buck/.*']
      \  },
      \  'completion': {
      \    'includeBlacklist': ['.*/buck-out/.*', '.*/third-party-buck/.*'],
      \    'enableSnippets': v:true,
      \  },
      \  'diagnostics': {
      \    'blacklist': ['.*/buck-out/.*', '.*/third-party-buck/.*'],
      \    'onParse': v:true,
      \    'onType': v:true,
      \  },
      \  'resourceDirectory': '',
      \  'discoverSystemIncludes': v:false,
      \  'showDocumentLinksOnIncludes': v:false,
      \  'disableInitialIndex': v:true,
      \  'clientVersion': 3,
      \  'codeLens': {
      \       'localVariables': v:false,
      \  }
      \}
endfunction

call ale#linter#Define('cpp', {
\   'name': 'cquery_buck',
\   'lsp': 'stdio',
\   'executable': {b -> ale#Var(b, 'cpp_cquery_buck_executable')},
\   'command': '%e',
\   'project_root_callback': 'ale_linters#cpp#cquery_buck#GetProjectRoot',
\   'initialization_options_callback': 'ale_linters#cpp#cquery_buck#GetInitializationOptions',
\})
