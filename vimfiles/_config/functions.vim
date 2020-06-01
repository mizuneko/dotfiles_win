" 編集箇所のカーソルを記憶
if has("autocmd")
  augroup redhat
    " In text files, always limit the width of text to 78 characters
    "autocmd BufRead *.txt set tw=78
    " When editing a file, always jump to the last cursor position
    autocmd BufReadPost *
    \ if line("'\"") > 0 && line ("'\"") <= line("$") |
    \   exe "normal! g'\"" |
    \ endif
  augroup END
endif

" Undoの永続化
if has('persistent_undo')
  if (has('win32') || has('win64'))
    let undo_path = expand('~/vimfiles/undo')
  else
	  let undo_path = expand('~/.vim/undo')
  endif
	exe 'set undodir=' .. undo_path
	set undofile
endif

if executable('rg')
	set grepprg=rg\ --vimgrep\ --no-heading
	set grepformat=%f:%l:%c:%m,%f:%l:%m
endif

