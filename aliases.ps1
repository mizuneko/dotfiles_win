# Correct PowerShell Aliases if tools are available (aliases win if set)
# WGet: Use `wget.exe` if available
if (Get-Command wget.exe -ErrorAction SilentlyContinue | Test-Path) {
    rm alias:wget -ErrorAction SilentlyContinue
}

# Directory Listing: Use `ls.exe` if available

if (Get-Command ls.exe -ErrorAction SilentlyContinue | Test-Path) {
    rm alias:ls -ErrorAction SilentlyContinue
    if ($PSVersionTable.PSVersion -gt [Version]::new(7,0,0)) {
        # Set `ls` to call `ls.exe` and always use --color
        ${function:ls} = { ls.exe --color @args }
    } else {
        # Set `ls` to call `ls.exe`
        ${function:ls} = { ls.exe @args }
    }
    # List all files in long format
    ${function:l} = { ls -lF @args }
    # List all files in long format, including hidden files
    ${function:la} = { ls -laF @args }
    # List only directories
    ${function:lsd} = { Get-ChildItem -Directory -Force @args }
}
if (-Not(Get-Command ls.exe -ErrorAction SilentlyContinue | Test-Path)) {
    # List all files, including hidden files
    ${function:la} = { ls -Force @args }
    # List only directories
    ${function:lsd} = { Get-ChildItem -Directory -Force @args }
}

# curl: Use `curl.exe` if available
if (Get-Command curl.exe -ErrorAction SilentlyContinue | Test-Path) {
    rm alias:curl -ErrorAction SilentlyContinue
    ${function:curl} = { curl.exe @args }
    # Gzip-enabled `curl`
    ${function:gurl} = { curl --compressed @args }
} else {
    # Gzip-enabled `curl`
    ${function:gurl} = { curl -TransferEncoding GZip }
}

# Create a new directory and enter it
Set-Alias mkd CreateAndSet-Directory

# Reload the shell
Set-Alias reload Reload-Powershell