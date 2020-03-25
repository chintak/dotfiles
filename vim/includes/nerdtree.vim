" NERDTree
map <Leader>/ :NERDTreeToggle<CR>

let g:NERDTreeDirArrowExpandable = '+'
let g:NERDTreeDirArrowCollapsible = '-'

" NERDTress File highlighting
function! NERDTreeHighlightFile(extension, fg, bg, guifg, guibg)
    exec 'autocmd filetype nerdtree highlight ' . a:extension .' ctermbg='. a:bg .' ctermfg='. a:fg .' guibg='. a:guibg .' guifg='. a:guifg
    exec 'autocmd filetype nerdtree syn match ' . a:extension .' #^\s\+.*'. a:extension .'$#'
endfunction

call NERDTreeHighlightFile('ini', 'gray', 'none', 'gray', '#151515')
call NERDTreeHighlightFile('yml', 'gray', 'none', 'gray', '#151515')
call NERDTreeHighlightFile('config', 'gray', 'none', 'gray', '#151515')
call NERDTreeHighlightFile('conf', 'gray', 'none', 'gray', '#151515')
call NERDTreeHighlightFile('json', 'gray', 'none', 'gray', '#151515')
call NERDTreeHighlightFile('html', 'gray', 'none', 'gray', '#151515')
call NERDTreeHighlightFile('styl', 'cyan', 'none', 'cyan', '#151515')
call NERDTreeHighlightFile('css', 'cyan', 'none', 'cyan', '#151515')

call NERDTreeHighlightFile('cpp', 'red', 'none', 'red', '#151515')
call NERDTreeHighlightFile('cc', 'red', 'none', '#ffa500', '#151515')
call NERDTreeHighlightFile('c', 'red', 'none', '#ffa500', '#151515')
call NERDTreeHighlightFile('hpp', 'cyan', 'none', '#ffa500', '#151515')
call NERDTreeHighlightFile('h', 'cyan', 'none', '#ffa500', '#151515')
call NERDTreeHighlightFile('thrift', 'yellow', 'none', 'yellow', '#151515')
call NERDTreeHighlightFile('py', 'Magenta', 'none', 'Magenta', '#151515')
call NERDTreeHighlightFile('php', 'green', 'none', 'green', '#151515')
