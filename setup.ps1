Param (
    [string]$SubCommand
)

$account = "mizuneko"
$repo    = "dotfiles_win"
$branch  = "master"
$homepath = ${HOME}
$dotDirectory = "${homepath}\dotfiles_win"
$remoteUrl = "git@github.com:$account/$repo.git"

$dotfilesTempDir = Join-Path $env:TEMP "dotfiles"

if (![System.IO.Directory]::Exists($dotfilesTempDir)) {[System.IO.Directory]::CreateDirectory($dotfilesTempDir)}
$sourceFile = Join-Path $dotfilesTempDir "dotfiles_win.zip"

# 使い方
# .\setup.ps1 deploy      シンボリックリンクの付け直し
# .\setup.ps1 initialize  初期導入時
function Write-Usage {
    Write-Host "Usgae:"
    Write-Host "  .\setup.ps1 [subcommand]"
    Write-Host "SubCommands:"
    Write-Host "  deploy"
    Write-Host "  initialize"
}

# dotfilesをダウンロードします。
function Download-File {
    param (
        [string]$url,
        [string]$file
    )

    Write-Host "Download $url to $file"
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $url -OutFile $file
}

# zipファイルを解凍します。
function Unzip-File {
    param (
        [string]$file,
        [string]$destination = (Get-Location).Path
    )

    $filePath = Resolve-Path $file
    $destinationPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($destination)

    if (($PSVersionTable.PSVersion.Major -ge 3) -and 
        (
            [version](Get-ItemProperty -Path "HKLM:\Software\Microsoft\NET Framework Setup\NDP\v4\Full" -ErrorAction SilentlyContinue).Version -ge [version]"4.5" -or
            [version](Get-ItemProperty -Path "HKLM:\Software\Microsoft\NET Framework Setup\NDP\v4\Client" -ErrorAction SilentlyContinue).Version -ge [version]"4.5"
        )
    ) {
        try {
            [System.Reflection.Assembly]::LoadWithPartialName("System.IO.Compression.FileSystem") | Out-Null
            [System.IO.Compression.ZipFile]::ExtractToDirectory("$filePath", "$destinationPath")
        } catch {
            Write-Warning -Message "Unexpected Error. Error details: $_.Exception.Message"
        }
    } else {
        try {
            $shell = New-Object -ComObject Shell.Application
            $shell.Namespace($destinationPath).copyhere(($shell.Namespace($filePath)).items())
        } catch {
            Write-Warning -Message "Unexpected Error. Error details: $_.Exception.Message"
        }
    }
}

# 指定されたコマンドの存在有無を判定します。
function HasCommand {
    param (
        [string]$command
    )
    try {
        Get-Command $command | Out-Null
        return $true
    } catch {
        return $false
    }
}

# 管理者権限で実行されているか判定します。
function Test-Administrator {
    [OutputType([bool])]
    param()
    process {
        [Security.Principal.WindowsPrincipal]$user = [Security.Principal.WindowsIdentity]::GetCurrent();
        return $user.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator);
    }
}

# dotfilesのフォルダがなければgithubから download または git clone します。
if (-Not(Test-Path -Path $dotDirectory)) {
    if (HasCommand "git") {
        git clone --recursive "$remoteUrl" "$dotDirectory"
    } else {
        Download-File "https://github.com/$account/$repo/archive/$branch.zip" $sourceFile
        Unzip-File $sourceFile $dotDirectory
    }

    Write-Host "Download dotfiles complete!" -ForegroundColor Green
}

# dotfiles のデプロイを実行します。
function Deploy-Dotfiles {
    $profileDir = Split-Path -parent $profile
    $componentDir = Join-Path $profileDir "components"

    New-Item $profileDir -ItemType Directory -Force -ErrorAction SilentlyContinue
    New-Item $componentDir -ItemType Directory -Force -ErrorAction SilentlyContinue


    if (-Not(Test-Administrator)) {
        Write-Warning "Symlink must be run with Administrator privileges."
        return
    }
    
    $excluded = @("setup.ps1")
    Get-ChildItem -File -Path $dotDirectory -Filter *.ps1 `
        | Where-Object { (-not $_.PSIsContainer) -and ($excluded -notcontains $_.Name) } `
        | ForEach-Object {
            New-Symlink "F" $_.FullName $profileDir\$_
        }
    Get-ChildItem -File -Path $dotDirectory\home `
        | ForEach-Object {
            New-Symlink "F" $_.FullName $homepath\$_
        }
    New-Symlink "D" (Join-Path $dotDirectory "components") (Join-Path $profileDir "components")
    New-Symlink "D" (Join-Path $dotDirectory "vimfiles") (Join-Path $homepath "vimfiles")

    Write-Host "Deploy dotfiles complete!" -ForegroundColor Green
}

# dotfiles の初期化を実行します。
function Initialize-Dotfiles {
    try {
        .\lib\Install-ScoopApps.ps1

        Write-Host "Initialize complete!" -ForegroundColor Green
    } catch {
        Write-Warning -Message "Unexpected Error. Error details: $_"
    }
}

# シンボリックリンクを作成します。
function New-Symlink {
    param (
        [string]$FileType,
        [string]$sourcePath,
        [string]$destinationPath
    )

    if (-Not(Test-Path $destinationPath)) {
        if ($FileType -eq "D") {
            cmd /C mklink /D $destinationPath $sourcePath
        } else {
            cmd /C mklink $destinationPath $sourcePath
        }
    }
}

Push-Location $dotDirectory

switch -Wildcard ($SubCommand) {
    "deploy" {
        Deploy-Dotfiles
    }
    "init*" {
        Initialize-Dotfiles
    }
    default {
        Write-Usage
    }
}

Pop-Location
