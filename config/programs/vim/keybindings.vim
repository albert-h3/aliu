"" Keybindings

noremap <C-C> <Esc>
noremap! <C-C> <Esc>
snoremap <C-C> <Esc>
nnoremap r<C-C> <Nop>
cunmap <C-C>

" Mapping <C-H> to escape
"   NOTE: To get this mapping to work in NeoVim, you may need to run
"   something like:
"      infocmp $TERM | sed 's/kbs=^[hH]/kbs=\\177/' > $TERM.ti && tic $TERM.ti
"
"                               - Albert Liu, Jun 18, 2023 Sun 18:09
snoremap <C-H> <Esc>
noremap <C-H> <Esc>
noremap! <C-H> <Esc>
cnoremap <C-H> <C-C>
nnoremap r<C-H> <Nop>

" Terminal keybindings
if exists(':terminal')
  tnoremap <C-H> <C-\><C-N>
  tnoremap <C-W><C-H> <C-W>h
endif

" Change Leader key
let mapleader=" "
nnoremap <SPACE> <Nop>

" Leader Mappings
nnoremap <Leader>r :!
nnoremap <Leader>R :read !
nnoremap <Leader>f /
nnoremap <Leader>F :RG<CR>
nnoremap <Leader>O :FZF<CR>

" Placeholder
nnoremap <Leader><Tab> /<++><CR>cf>
nnoremap <Leader><S-Tab> ?<++><CR>cf>

" Setting up Ctrl-K in normal mode
" https://github.com/tpope/vim-rsi/issues/15#issuecomment-198632142
cnoremap <C-A> <Home>
cnoremap <C-K> <C-\>e getcmdpos() == 1 ? '' : getcmdline()[:getcmdpos()-2]<CR>
cnoremap <C-B> <C-Left>
cnoremap <C-F> <C-Right>
cnoremap <Up> <C-P>
cnoremap <Down> <C-N>

" Screw that man pages stuff
nnoremap <S-K> gk
vnoremap <S-K> gk
vnoremap <S-J> gj

" What the heck is Select mode?
nnoremap <silent> gh :call LanguageClient#textDocument_hover()<CR>
nnoremap g<C-H> <Nop>

" Using <C-J> and <C-K> for navigating the pop-up menu
" inoremap <C-N><C-O> <C-N>
inoremap <C-N><C-O> <C-X><C-O>
inoremap <C-N> <Nop>
inoremap <C-N><C-T> <C-N>
inoremap <expr> <C-D> pumvisible() ? "\<C-N>\<C-N>\<C-N>\<C-N>\<C-N>" : "\<C-D>"
inoremap <expr> <C-U> pumvisible() ? "\<C-P>\<C-P>\<C-P>\<C-P>\<C-P>" : "\<C-U>"
inoremap <expr> <C-J> pumvisible() ? "\<C-N>" : "\<C-J>"
inoremap <expr> <C-K> pumvisible() ? "\<C-P>" : "\<C-K>"

" Using <C-T> to put in a lil thing with my name and stuff in it
if Flag('aliu')
  nnoremap <C-T> a<C-R>=strftime("- Albert Liu, %b %d, %Y %a %H:%M")<CR><Esc>
  inoremap <C-T> <C-R>=strftime("- Albert Liu, %b %d, %Y %a %H:%M")<CR>
endif

" Unmapping <C-Q>
nnoremap <C-Q> <Nop>

" Mapping semicolon to colon
nnoremap ; :

" Disabling ex mode
nnoremap <S-Q> <Nop>

" Go to definition
nnoremap <silent> gd :call LanguageClient#textDocument_definition()<CR>

" Control left/right in command mode
cnoremap <Esc>[1;5D <C-Left>
cnoremap <Esc>[1;5C <C-Right>

"" Tabs
nnoremap <C-W><C-t> :tabnew<Enter>
nnoremap <C-W><C-e> :tabNext<Enter>
nnoremap <C-W><C-r> :tabnext<Enter>
nnoremap <C-W>t :tabnew<Enter>
nnoremap <C-W>e :tabNext<Enter>
nnoremap <C-W>r :tabnext<Enter>

" Getting back jump list functionality
nnoremap <C-P> <C-I>


"" VSCode keys
" 1. Toggle the file viewer
" 2. File name search
" 3. File content search
nnoremap <C-B> :NERDTreeToggle<CR>
if has('gui_macvim')
  " NOTE: these commands map to CMD+SHIFT+O and etc. even though this
  " doesn't say it. MacVim actually has native handling of CMD+O and
  " CMD+F, so even though Vim can't tell whether Shift was pressed, MacVim
  " will only run these mappings when shift is pressed.
  nnoremap <D-O> :FZF<CR>
  nnoremap <D-F> :RG<CR>
endif

" Better Screen Repaint
" Taken shamelessly verbatim from vim-sensible
nnoremap <silent> <C-L> :ReadBgFlag<CR>:nohlsearch<C-R>=has('diff')?'<Bar>diffupdate':''<CR><CR><C-L>

" New buffer in window to the right
nnoremap <C-W>v <C-W>v:enew<CR>
nnoremap <C-W><S-V> :aboveleft :vsplit<CR>:enew<CR>
nnoremap <C-W><S-N> :aboveleft :split<CR>:enew<CR>

" Pressing j and k go up and down the sections of a soft-wrapped line
" https://statico.github.io/vim.html
" https://statico.github.io/vim2.html
nnoremap j gj
nnoremap k gk

