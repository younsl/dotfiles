"------------------------------------
" Basic Settings
"------------------------------------
" Disable Vi compatibility mode and use Vim-specific features
set nocompatible

" Display window title
set title

" Show line numbers
set number
set ruler

" Use spaces instead of tabs
set expandtab

" Set tab width (2 spaces)
set tabstop=2
set shiftwidth=2
set softtabstop=2

" Automatic indentation
set autoindent
set smartindent

" Case-insensitive search
set ignorecase

" Case-sensitive search when using uppercase
set smartcase

" Highlight search results in real-time
set hlsearch
set incsearch

" Prevent cursor from going off-screen
set nowrap

" Always show cursor position (maintain top/bottom margin)
set scrolloff=8

" Don't create backup files
set nobackup
set nowritebackup
set noswapfile

" Enable syntax highlighting
syntax on

" Set file encoding (UTF-8)
set encoding=utf-8

" Automatically update file when modified externally
set autoread

" Share clipboard (copy/paste)
if has('mac')
  set clipboard=unnamed
elseif has('unix')
  set clipboard=unnamedplus
endif

" Enable file type detection, plugins, and indentation settings
filetype on
filetype plugin on
filetype indent on

" Disable .netrwhist file creation
let g:netrw_dirhistmax = 0

"------------------------------------
" Plugin Settings
"------------------------------------
" Auto-install Vim-plug
if empty(glob('$HOME/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

" List of plugins
call plug#begin('$HOME/.vim/plugged')

" CoC (Conquer of Completion): Powerful plugin for autocompletion and LSP support
Plug 'neoclide/coc.nvim', {'branch': 'release'}

" vim-polyglot: Syntax highlighting and indentation for many programming languages
Plug 'sheerun/vim-polyglot'

" indentLine: Display indentation guides
Plug 'Yggdroot/indentLine'

call plug#end()

" Install CoC extensions
let g:coc_global_extensions = ['coc-yaml']

"------------------------------------
" Kubernetes YAML Configuration
"------------------------------------
" Enable indentation guides for YAML files
let g:indentLine_fileTypeExclude = ['markdown']
let g:indentLine_char = '⦙'
let g:indentLine_color_term = 239

" Settings for YAML files
autocmd FileType yaml setlocal ts=2 sts=2 sw=2 expandtab autoindent

" Show indentation guides only for YAML files
autocmd FileType yaml,yml let g:indentLine_enabled=1

" Prevent indentation of comments starting with '#' in YAML files
autocmd FileType yaml setlocal indentkeys-=0#

" Recognize Kubernetes YAML files
autocmd BufNewFile,BufRead *.yaml,*.yml
  \ if getline(1) =~ '^apiVersion:' || getline(2) =~ '^apiVersion:'
  \ | setfiletype yaml.kubernetes
  \ | endif

"------------------------------------
" Conquer of Completion Configuration
"------------------------------------
" Use Tab for autocompletion selection
inoremap <expr> <Tab> pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"

" Use Enter to confirm autocompletion
inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"

"------------------------------------
" UI Settings
"------------------------------------
" Use visual bell instead of sound
set visualbell

" Always show status line
set laststatus=2

" Customize status bar
set statusline=%F%m%r%h%w\ [FORMAT=%{&ff}]\ [TYPE=%Y]
set statusline+=\ [POS=%l,%v][%P]\ [BUFFER=%n]
set statusline+=%=  " Left/right separator
set statusline+=%{strftime('%Y-%m-%d\ (%a)\ %H:%M:%S')}

" Highlight spaces when not using tabs
set listchars=tab:»\ ,trail:·
set list

" Highlight matching brackets
set showmatch

" Set color scheme
colorscheme paramount

" Highlight cursor line
set cursorline

" Set background color (dark or light)
set background=dark

" Enable mouse support
set mouse=a