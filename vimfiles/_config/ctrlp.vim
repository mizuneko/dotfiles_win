let g:ctrlp_match_window='order:ttb,min:20,max:20,results:100'
let g:ctrlp_show_hidden=1
let g:ctrlp_types=['fil']
let g:ctrlp_extensions=['funky', 'commandline']
let g:ctrlp_funky_matchtype='path'
command! CtrlPCommandLine call ctrlp#init(ctrlp#commandline#id())
let g:ctrlp_use_migemo=1
let g:webdevicons_enable_ctrlp=1

if executable('rg')
	let g:ctrlp_use_caching=0
	let g:ctrlp_user_command='rg %s --files --color=never --glob ""'
endif
