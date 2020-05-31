if has('win32')
	let g:lsp_settings_servers_dir=$LOCALAPPDATA . '\vim-lsp-settings\servers'
elseif has('mac')
	let g:lsp_settings_servers_dir=$HOME . '/.local/share/vim-lsp-settings/servers'
elseif has('linux')
	let g:lsp_settings_servers_dir=$XDG_DATA_HOME . '/vim-lsp-settings/servers'
endif
