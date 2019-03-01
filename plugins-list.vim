"" Plugins
if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/.vim/plugged')

" Markdown highlighting
Plug 'https://github.com/godlygeek/tabular'
Plug 'https://github.com/plasticboy/vim-markdown'
let g:vim_markdown_math = 1
let g:vim_markdown_frontmatter = 1

" git diff gutter to show changes
Plug 'https://github.com/airblade/vim-gitgutter'

" Linting
Plug 'https://github.com/w0rp/ale'
let g:ale_enabled = 0

" Editor Config
Plug 'https://github.com/editorconfig/editorconfig-vim'

" " Multiple Cursors
" Plug 'https://github.com/terryma/vim-multiple-cursors'

" Swapping windows
Plug 'https://github.com/wesQ3/vim-windowswap'

"" Tim Pope Plugins <3

" Unix Commands
Plug 'https://github.com/tpope/vim-eunuch'

" Sensible Vim
Plug 'https://github.com/tpope/vim-sensible'

" Asynchronous Dispatch
Plug 'https://github.com/tpope/vim-dispatch'

call plug#end()


