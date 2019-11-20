"About compatible - This option has the effect of making Vim either more Vi-compatible, or
"    make Vim behave in a more useful way.
set nocompatible

"modelines allow you to set variables specific to a file. By default, the first and last five lines are read by vim
"                    for variable settings.
set modelines=0

"Set tabs to 4 spaces
"http://vim.wikia.com/wiki/Converting_tabs_to_spaces
set tabstop=4
set shiftwidth=4
set softtabstop=4

"Display line numbers
set number

"To insert space characters whenever the tab key is pressed, set the 'expandtab' option
set expandtab

"Use system-wide clipboard
if has('macunix')
  set clipboard=unnamed
else
  set clipboard=unnamedplus
endif
set clipboard=unnamedplus

"Allow usage of comma as well as ;
let mapleader = ","

set encoding=utf-8

"Keep your cursor centered vertically on the screen
set scrolloff=3

"'autoindent' does nothing more than copy the indentation from the previous line, when starting a new line.
"It can be useful for structured text files, or when you want to control most of the indentation
"manually, without Vim interfering.
set autoindent

"When a file has been detected to have been changed outside of Vim and
"it has not been changed inside of Vim, automatically read it again.
set autoread

"If in Insert, Replace or Visual mode put a message on the last line.
set showmode

"Show (partial) command in the last line of the screen.  Set this
"option off if your terminal is slow.
set showcmd

"from http://usevim.com/2012/10/19/vim101-set-hidden/
"With :set hidden, opening a new file when the current buffer has unsaved changes causes files to be hidden instead of closed
set hidden

"wildmenu and wildmode are used for command line completion
set wildmenu
set wildmode=list:longest

"Simply putting :set cursorline in your vimrc will highlight the current line in every window and update the
"highlight as the cursor moves.
set cursorline
hi clear CursorLineNR
augroup CLClear
    autocmd! ColorScheme * hi clear CursorLineNR
augroup END

"Indicates a fast terminal connection.  More characters will be sent to
"the screen for redrawing, instead of using insert/delete line
"commands.  Improves smoothness of redrawing when there are multiple
"windows and the terminal does not support a scrolling region.
set ttyfast

"When enabled, the ruler is displayed on the right side of the status line at the bottom of the window.
"By default, it displays the line number, the column number, the virtual column number, and the relative
"position of the cursor in the file (as a percentage).
set ruler

"http://vim.wikia.com/wiki/Backspace_and_delete_problems
"Allows deleting using backspace from previous line
set backspace=indent,eol,start

"To display the status line always, set the laststatus option in your vimrc to 2
set laststatus=2

"No backup files when editing
set nobackup
set noswapfile

set history=1000         " remember more commands and search history
set undolevels=1000      " use many muchos levels of undo

set wildignore=*.swp,*.bak,*.pyc,*/.git/*
set wildignore+=*/tmp/*,*.so,*.zip   " Linux/MacOSX

set title                " change the terminal's title

"Disable beeping - from http://vim.wikia.com/wiki/Disable_beeping
set noerrorbells visualbell t_vb=
if has('autocmd')
  autocmd GUIEnter * set visualbell t_vb=
endif

"ignore case for commands
set ignorecase
set smartcase


"When on, the ":substitute" flag 'g' is default on.  This means that
"all matches in a line are substituted instead of one.  When a 'g' flag
"is given to a ":substitute" command, this will toggle the substitution
"of all or one match.
set gdefault

"By default, searching starts after you enter the string. With the option: :set incsearch set, incremental searches
"will be done. The Vim editor will start searching when you type the first character of the search string.
"As you type in more characters, the search is refined.
set incsearch

"The "highlight search option" ('hlsearch') turns on search highlighting. This option is enabled by the command:
set hlsearch

"The showmatch option is also useful: it can reduce the need for %, the cursor will briefly
"jump to the matching brace when you insert one.
"To speed things up, you can set the 'matchtime' option.
set showmatch
set matchtime=3

if exists("+undofile")
  " undofile - This allows you to use undos after exiting and restarting
  " This, like swap and backups, uses .vim-undo first, then ~/.vim/undo
  " :help undo-persistence
  " This is only present in 7.3+
  if isdirectory($HOME . '/.vim-undo') == 0
    :silent !mkdir -p ~/.vim-undo > /dev/null 2>&1
  endif
  set undodir=./.vim-undo//
  set undofile
endif

syntax on
set background=dark

"Red color column after 130 characters
if exists('+colorcolumn')
  set colorcolumn=+1
  " Set up a very dark grey ruler
  highlight ColorColumn ctermbg=232 guibg=DarkGrey
else
  au BufWinEnter * let w:m2=matchadd('ErrorMsg', '\%>130v.\+', -1)
endif

"Split below and right
set splitbelow
set splitright

"" http://vimbits.com/bits/144
"" ****************** SCROLLING *********************

set scrolloff=8         " Number of lines from vertical edge to start scrolling
set sidescrolloff=15    " Number of cols from horizontal edge to start scrolling
set sidescroll=1        " Number of cols to scroll at a time

filetype plugin indent on
autocmd Filetype cpp setlocal ts=2 sw=2 sts=0 expandtab
autocmd Filetype javascript setlocal ts=2 sw=2 sts=0 expandtab
autocmd FileType javascript set formatprg=prettier\ --single-quote\ --trailing-comma\ --stdin
autocmd Filetype typescript setlocal ts=2 sw=2 sts=0 expandtab
autocmd FileType typescript set formatprg=prettier\ --single-quote\ --trailing-comma\ --stdin
autocmd Filetype python setlocal ts=4 sw=4 sts=0 expandtab
autocmd Filetype json setlocal ts=2 sw=2 sts=0 expandtab
autocmd Filetype yaml setlocal ts=2 sw=2 sts=0 expandtab
autocmd Filetype html setlocal ts=2 sw=2 sts=0 expandtab
autocmd Filetype htmldjango setlocal ts=2 sw=2 sts=0 expandtab
autocmd Filetype make setlocal ts=4 sw=4 sts=0 noexpandtab autoindent

:let g:session_autosave = 'yes'
set sessionoptions-=help

set guicursor=
let $NVIM_TUI_ENABLE_CURSOR_SHAPE = 0
" set cursor to a bar on insert mode
au InsertEnter *
  \ if v:insertmode == 'i' |
  \   if exists('$TMUX') |
  \     let &t_SI = "\<Esc>Ptmux;\<Esc>\<Esc>]50;CursorShape=1\x7\<Esc>\\" |
  \     let &t_EI = "\<Esc>Ptmux;\<Esc>\<Esc>]50;CursorShape=0\x7\<Esc>\\" |
  \   else |
  \     let &t_SI = "\<Esc>]50;CursorShape=1\x7" |
  \     let &t_EI = "\<Esc>]50;CursorShape=0\x7" |
  \   endif |
  \ else |
  \   if exists('$TMUX') |
  \     let &t_SI = "\<Esc>Ptmux;\<Esc>\<Esc>]50;CursorShape=0\x7\<Esc>\\" |
  \     let &t_EI = "\<Esc>Ptmux;\<Esc>\<Esc>]50;CursorShape=a\x7\<Esc>\\" |
  \   else |
  \     let &t_SI = "\<Esc>]50;CursorShape=0\x7" |
  \     let &t_EI = "\<Esc>]50;CursorShape=1\x7" |
  \   endif |
  \ endif

" disable paste mode when leaving Insert mode	" disable paste mode when leaving Insert mode
au InsertLeave * set nopaste

"Auto close helper windows on save
:autocmd BufWritePre * :pclose
:autocmd BufWritePre * :cclose
