let g:WebDevIconsUnicodeDecorateFolderNodes=v:true
let g:DevIconsEnableFoldersOpenClose=1
let g:webdevicons_enable_vimfiler=1

" Custom icons.
let g:WebDevIconsUnicodeDecorateFileNodesExtensionSymbols = {} " Initialize the custom icons object.
let g:WebDevIconsUnicodeDecorateFolderNodesDefaultSymbol = '' " Disable folder icons.
let g:WebDevIconsUnicodeDecorateFileNodesDefaultSymbol = '' " Default icon in case there no match found.
let g:WebDevIconsUnicodeDecorateFileNodesExtensionSymbols['html'] = '' " Default HTML icon.
let g:WebDevIconsUnicodeDecorateFileNodesExtensionSymbols['css'] = '' " Default CSS icon.
let g:WebDevIconsUnicodeDecorateFileNodesExtensionSymbols['md'] = '' " Default Markdown icon.

if exists('g:loaded_webdevicons')
	call webdevicons#refresh()
endif
