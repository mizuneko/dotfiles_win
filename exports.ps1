# Make vim the default editor
Set-Environment "EDITOR" "gvim --nofork"
Set-Environment "GET_EDITOR" $env:EDITOR

# Disable the Progress Bar
$ProgressPreference='SilentlyContinue'