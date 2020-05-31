# Profile for the Microsoft.Powershell Shell, only. (Not Visual Studio or other PoSh instances)
# ===========
Push-Location (Split-Path -parent $profile)
"components-shell" | Where-Object { Test-Path "$_.ps1" } | ForEach-Object -process { Invoke-Expression ". .\$_.ps1" }
Pop-Location

##################################################
# プロンプトを良い感じに
##################################################
function git_branch {
    git branch 2>$null |
        Where-Object { -not [System.String]::IsNullOrEmpty($_.Split()[0]) } |
        ForEach-Object { $bn = $_.Split()[1]
        Write-Output "(git:$bn)" }
}

function prompt {
    # カレントディレクトリをウィンドウタイトルにする
    (Get-Host).UI.RawUI.WindowTitle = "Windows PowerShell " + (new-object "IO.FileInfo" $pwd.ProviderPath).Name

    # GitBash っぽく表示
    # カレントディレクトリを取得
    $idx = $pwd.ProviderPath.LastIndexOf("\") + 1
    $cdn = $pwd.ProviderPath.Remove(0, $idx)

    # 現在時刻を取得
    $t = (Get-Date).ToLongTimeString()

    # ブランチ名を取得
    $gitBranch = git_branch
  
    # プロンプトをセット
    Write-Host "[" -NoNewline -ForegroundColor White
    Write-Host "$t " -NoNewline -ForegroundColor Green
    Write-Host $env:USERNAME -NoNewline -ForegroundColor Cyan
    Write-Host "@$env:USERDOMAIN " -NoNewline -ForegroundColor White
    Write-Host $cdn -NoNewline -ForegroundColor Green
    Write-Host "] " -NoNewline -ForegroundColor White
    Write-Host $gitBranch -NoNewline -ForegroundColor White
    Write-Host "
$" -NoNewline -ForegroundColor White
    return " "
}