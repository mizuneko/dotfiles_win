"インサートモードで開始しない
let g:unite_enable_start_insert = 0
"file_mruの表示フォーマットを指定。空にすると表示スピードが高速化される
let g:unite_source_file_mru_filename_format = ''
"data_directory はramdiskを指定
if has('win32')
  let g:unite_data_directory = '~/.unite'
elseif  has('macunix')
  let g:unite_data_directory = '/Volumes/RamDisk/.unite'
else
  let g:unite_data_directory = '/mnt/ramdisk/.unite'
endif
"bookmarkだけホームディレクトリに保存
let g:unite_source_bookmark_directory = '~/.unite/bookmark'
if executable('rg')
	let g:unite_source_grep_command = 'rg'
	let g:unite_source_grep_default_opts = '-n --no-heading --color never'
	let g:unite_source_grep_recursive_opt = ''
	let g:unite_source_grep_encoding = 'utf-8'
endif
let g:webdevicons_enable_unite=1

nnoremap [unite] <Nop>
nmap <Space>f [unite]
"現在開いているファイルのディレクトリ下のファイル一覧。
"開いていない場合はカレントディレクトリ
nnoremap <silent> [unite]f :<C-u>UniteWithBufferDir -buffer-name=files file<CR>
"バッファ一覧
nnoremap <silent> [unite]b :<C-u>Unite buffer<CR>
"レジスタ一覧
nnoremap <silent> [unite]r :<C-u>Unite -buffer-name=register register<CR>
"最近使用したファイル一覧
nnoremap <silent> [unite]m :<C-u>Unite file_mru<CR>
"ブックマーク一覧
nnoremap <silent> [unite]c :<C-u>Unite bookmark<CR>
"ブックマークに追加
nnoremap <silent> [unite]a :<C-u>UniteBookmarkAdd<CR>
"uniteを開いている間のキーマッピング
augroup vimrc
  autocmd FileType unite call s:unite_my_settings()
augroup END
function! s:unite_my_settings()
  "ESCでuniteを終了
  nmap <buffer> <ESC> <Plug>(unite_exit)
  "入力モードのときjkでノーマルモードに移動
  imap <buffer> jk <Plug>(unite_insert_leave)
  "入力モードのときctrl+wでバックスラッシュも削除
  imap <buffer> <C-w> <Plug>(unite_delete_backward_path)
  "sでsplit
  nnoremap <silent><buffer><expr> s unite#smart_map('s', unite#do_action('split'))
  inoremap <silent><buffer><expr> s unite#smart_map('s', unite#do_action('split'))
  "vでvsplit
  nnoremap <silent><buffer><expr> v unite#smart_map('v', unite#do_action('vsplit'))
  inoremap <silent><buffer><expr> v unite#smart_map('v', unite#do_action('vsplit'))
  "fでvimfiler
  nnoremap <silent><buffer><expr> f unite#smart_map('f', unite#do_action('vimfiler'))
  inoremap <silent><buffer><expr> f unite#smart_map('f', unite#do_action('vimfiler'))
endfunction

