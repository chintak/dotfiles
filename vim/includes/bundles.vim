" Many themes
Plug 'vim-scripts/Colour-Sampler-Pack'
Plug 'vim-scripts/ScrollColors'
Plug 'morhetz/gruvbox'

" FZF File finder
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'

" Syntax Highlight and IDE-Like features
Plug 'w0rp/ale'
Plug 'scrooloose/nerdcommenter'

if has('nvim')
  Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
else
  Plug 'Shougo/deoplete.nvim', { 'do': 'pip3 install pynvim' }
  Plug 'roxma/nvim-yarp'
  Plug 'roxma/vim-hug-neovim-rpc'
endif

" Multiple cursors / Motion
Plug 'mg979/vim-visual-multi'
Plug 'easymotion/vim-easymotion'

" Light and configurable status line
Plug 'itchyny/lightline.vim'

" Language dependent
Plug 'hhvm/vim-hack'
Plug 'flowtype/vim-flow'

" Background execution
Plug 'skywind3000/asyncrun.vim'

" Language pack
Plug 'sheerun/vim-polyglot'

if filereadable("$HOME/.bundles.vim") == 1
  source "$HOME/.bundles.vim"
endif
