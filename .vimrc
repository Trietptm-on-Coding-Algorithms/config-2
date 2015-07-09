set nocompatible
if has("gui_macvim")
  let macvim_hig_shift_movement = 1
else
  source $VIMRUNTIME/vimrc_example.vim
  source $VIMRUNTIME/mswin.vim
  behave mswin
endif

:syntax on
:set incsearch
:set ignorecase smartcase
:set wildmenu

:set history=50

:set showmatch " show matching brackets

"Set tabs to 4 spaces
:set tabstop=4
:set shiftwidth=4
:set softtabstop=4
:set smarttab
:set expandtab
:set autoindent

"vividchalk theme, consolas font

syntax enable
set background=dark
colorscheme solarized

set gfn=Consolas:h9:cANSI

"make sure that bottom status bar is running.
:set ruler
:set laststatus=2

"backups
au BufWritePre * let &bex = '-' . strftime("%Y%m%d-%H%M%S") . '.vimbackup'
set backupdir=~/.vim/tmp,.
set directory=~/.vim/tmp,.
set backup

set guioptions-=T  "remove toolbar

