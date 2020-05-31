function HasCommand {
    param (
        [string]$command
    )
    try {
        if (Get-Command $command -ErrorAction SilentlyContinue | Test-Path) {
            return $true
        }
    }
    catch {
        return $false
    }
}

if (HasCommand "scoop") {
    Write-Host "Already installed Scoop" -ForegroundColor Green
} else {
    Write-Host "Installing Scoop..."
    Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
    Invoke-WebRequest -useb get.scoop.sh | Invoke-Expression
}

if (HasCommand "scoop") {
    scoop update
    scoop update *

    $desired_formulae=@{
        "7zip" = "7z"
        "git" = "git"
        "innounp" = "innounp"
        "gsudo" = "gsudo"
        "pwsh" = "pwsh"
        "ripgrep" = "rg"
        "openssh" = "ssh"
        "gow" = "wget.exe"
        "tailblazer" = "tailblazer.exe"
        "winmerge" = "winmergeu.exe"
    }

    foreach ($key in $desired_formulae.Keys) {
        if (-Not(HasCommand $desired_formulae[$key])) {
            scoop install $key
        }
    }

    Write-Host "Installed Scoop complete." -ForegroundColor Green

    scoop cleanup *
    scoop cache rm *

    Write-Host "Cleanup Scoop complete." -ForegroundColor Green
}