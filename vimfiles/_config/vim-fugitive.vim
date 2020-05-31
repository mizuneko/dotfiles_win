nnoremap [fugitive]  <Nop>
nmap <space>g [fugitive]
nnoremap <silent> [fugitive]s :tab sp<CR>:Gstatus<CR>:only<CR>
nnoremap <silent> [fugitive]a :Gwrite<CR>
nnoremap <silent> [fugitive]c :Gcommit<CR>
nnoremap <silent> [fugitive]b :Gblame<CR>
nnoremap <silent> [fugitive]l :Git log<CR>
nnoremap <silent> [fugitive]h :tab sp<CR>:0Glog<CR>
nnoremap <silent> [fugitive]p :Gpush<CR>
nnoremap <silent> [fugitive]f :Gfetch<CR>
nnoremap <silent> [fugitive]d :Gdiff<CR>
nnoremap <silent> [fugitive]r :Grebase -i<CR>
nnoremap <silent> [fugitive]g :Ggrep 
nnoremap <silent> [fugitive]m :Gmerge<CR>

