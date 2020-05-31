nnoremap <silent><Esc><Esc> :<C-u>set nohlsearch!<CR>

augroup MyXML
	autocmd!
	autocmd Filetype xml inoremap <buffer> </ </<C-x><C-o>
	autocmd Filetype html inoremap <buffer> </ </<C-x><C-o>
augroup END

nnoremap <down> gj
nnoremap <up> gk

nnoremap <Leader>w :w<CR>
nnoremap <Leader>re :%s;\<<C-R><C-W>\>;g<Left><Left>;
nnoremap <Leader>. :new ~/_vimrc<CR>

nnoremap <silent> <C-j> :bprev<CR>
nnoremap <silent> <C-k> :bnext<CR>

nnoremap <Leader>h ^
nnoremap <Leader>l $

nnoremap ; :
nnoremap : ;
vnoremap ; :
vnoremap : ;

nnoremap <Space>o  :<C-u>for i in range(v:count1) \| call append(line('.'), '') \| endfor<CR>
nnoremap <Space>O  :<C-u>for i in range(v:count1) \| call append(line('.')-1, '') \| endfor<CR>

inoremap jk <Esc>

nnoremap gs :<C-u>%s///g<Left><Left><Left>
vnoremap gs :s///g<Left><Left><Left>

nnoremap <Tab> za
nnoremap x "_x

" Open `:terminal` in vertical split with current directory.
nnoremap <silent> <Leader>t :50vsplit +enew\ <Bar>\ call\ termopen('cd\ $PWD\ &&\ $SHELL')<CR>
