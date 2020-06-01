nmap <Leader><Leader> <Plug>BookmarkToggle
nmap <Leader>i <Plug>BookmarkAnnotate
nmap <Leader>a <Plug>BookmarkShowAll
nmap <Leader>j <Plug>BookmarkNext
nmap <Leader>k <Plug>BookmarkPrev
nmap <Leader>c <Plug>BookmarkClear
nmap <Leader>x <Plug>BookmarkClearAll

if (has('win32') || has('win64'))
  let g:bookmark_auto_save_file = $HOME . '\vimfiles\.bookmarks'
else
  let g:bookmark_auto_save_file = $HOME . '\.vim\.bookmarks'
endif
let g:bookmark_location_list = 1
let g:bookmark_sign = ''
let g:bookmark_annotation_sign = ''
