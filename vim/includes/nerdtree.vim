" NERDTree
map <Leader>/ :NERDTreeToggle<CR>

let g:NERDTreeDirArrowExpandable = '+'
let g:NERDTreeDirArrowCollapsible = '-'

" NERDTress File highlighting
function! NERDTreeHighlightFile(extension, fg, bg, guifg, guibg)
    exec 'autocmd filetype nerdtree highlight ' . a:extension .' ctermbg='. a:bg .' ctermfg='. a:fg .' guibg='. a:guibg .' guifg='. a:guifg
    exec 'autocmd filetype nerdtree syn match ' . a:extension .' #^\s\+.*'. a:extension .'$#'
endfunction

call NERDTreeHighlightFile('ini', 'yellow', 'none', 'yellow', '#151515')
call NERDTreeHighlightFile('yml', 'yellow', 'none', 'yellow', '#151515')
call NERDTreeHighlightFile('config', 'yellow', 'none', 'yellow', '#151515')
call NERDTreeHighlightFile('conf', 'yellow', 'none', 'yellow', '#151515')
call NERDTreeHighlightFile('json', 'yellow', 'none', 'yellow', '#151515')
call NERDTreeHighlightFile('html', 'yellow', 'none', 'yellow', '#151515')
call NERDTreeHighlightFile('styl', 'cyan', 'none', 'cyan', '#151515')
call NERDTreeHighlightFile('css', 'cyan', 'none', 'cyan', '#151515')
call NERDTreeHighlightFile('cpp', 'Red', 'none', 'red', '#151515')
call NERDTreeHighlightFile('cc', 'Red', 'none', '#ffa500', '#151515')
call NERDTreeHighlightFile('c', 'Red', 'none', '#ffa500', '#151515')
call NERDTreeHighlightFile('hpp', 'Red', 'none', '#ffa500', '#151515')
call NERDTreeHighlightFile('h', 'Red', 'none', '#ffa500', '#151515')
call NERDTreeHighlightFile('python', 'blue', 'none', '#ff00ff', '#151515')
call NERDTreeHighlightFile('php', 'green', 'none', 'green', '#151515')
