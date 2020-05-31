##################################################
# Basic commands
##################################################
function which($name) { Get-Command $name -ErrorAction SilentlyContinue | Select-Object Definition }
function touch($file) { "" | Out-File $file -Encoding ASCII }

##################################################
# Common Editing needs
##################################################
function Edit-Hosts { Invoke-Expression "sudo $(if($env:EDITOR -ne $null)  { $env:EDITOR } else { 'notepad' }) $env:windir\system32\drivers\etc\hosts" }
function Edit-Profile { Invoke-Expression "$(if($env:EDITOR -ne $null)  { $env:EDITOR } else { 'notepad' }) $profile" }

##################################################
# Reload the Shell
##################################################
function Reload-Powershell {
    $newProcess = new-object System.Diagnostics.ProcessStartInfo "PowerShell";
    $newProcess.Arguments = "-nologo";
    [System.Diagnostics.Process]::Start($newProcess);
    exit
}

##################################################
# Download a file into a temporary folder
##################################################
function curlex($url) {
    $uri = new-object system.uri $url
    $filename = $uri.segments | Select-Object -Last 1
    $path = join-path $env:Temp $filename
    if( test-path $path ) { Remove-Item -force $path }

    (new-object net.webclient).DownloadFile($url, $path)

    return new-object io.fileinfo $path
}

##################################################
# Empty the Recycle Bin on all drives
##################################################
function Empty-RecycleBin {
    $RecBin = (New-Object -ComObject Shell.Application).Namespace(0xA)
    $RecBin.Items() | %{Remove-Item $_.Path -Recurse -Confirm:$false}
}

##################################################
# Create a new directory and enter it
##################################################
function CreateAndSet-Directory([String] $path) { New-Item $path -ItemType Directory -ErrorAction SilentlyContinue; Set-Location $path}

##################################################
# Reload the $env object from the registry
##################################################
function Refresh-Environment {
    $locations = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment',
                 'HKCU:\Environment'

    $locations | ForEach-Object {
        $k = Get-Item $_
        $k.GetValueNames() | ForEach-Object {
            $name  = $_
            $value = $k.GetValue($_)
            Set-Item -Path Env:\$name -Value $value
        }
    }

    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

##################################################
# Set a permanent Environment variable, and reload it into $env
##################################################
function Set-Environment([String] $variable, [String] $value) {
    Set-ItemProperty "HKCU:\Environment" $variable $value
    # Manually setting Registry entry. SetEnvironmentVariable is too slow because of blocking HWND_BROADCAST
    #[System.Environment]::SetEnvironmentVariable("$variable", "$value","User")
    Invoke-Expression "`$env:${variable} = `"$value`""
}

##################################################
# Add a folder to $env:Path
##################################################
function Prepend-EnvPath([String]$path) { $env:PATH = $env:PATH + ";$path" }
function Prepend-EnvPathIfExists([String]$path) { if (Test-Path $path) { Prepend-EnvPath $path } }
function Append-EnvPath([String]$path) { $env:PATH = $env:PATH + ";$path" }
function Append-EnvPathIfExists([String]$path) { if (Test-Path $path) { Append-EnvPath $path } }

##################################################
# Extract a .zip file
##################################################
function Unzip-File {
    <#
    .SYNOPSIS
       Extracts the contents of a zip file.
    .DESCRIPTION
       Extracts the contents of a zip file specified via the -File parameter to the
    location specified via the -Destination parameter.
    .PARAMETER File
        The zip file to extract. This can be an absolute or relative path.
    .PARAMETER Destination
        The destination folder to extract the contents of the zip file to.
    .PARAMETER ForceCOM
        Switch parameter to force the use of COM for the extraction even if the .NET Framework 4.5 is present.
    .EXAMPLE
       Unzip-File -File archive.zip -Destination .\d
    .EXAMPLE
       'archive.zip' | Unzip-File
    .EXAMPLE
        Get-ChildItem -Path C:\zipfiles | ForEach-Object {$_.fullname | Unzip-File -Destination C:\databases}
    .INPUTS
       String
    .OUTPUTS
       None
    .NOTES
       Inspired by:  Mike F Robbins, @mikefrobbins
       This function first checks to see if the .NET Framework 4.5 is installed and uses it for the unzipping process, otherwise COM is used.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string]$File,

        [ValidateNotNullOrEmpty()]
        [string]$Destination = (Get-Location).Path
    )

    $filePath = Resolve-Path $File
    $destinationPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Destination)

    if (($PSVersionTable.PSVersion.Major -ge 3) -and
       ((Get-ItemProperty -Path "HKLM:\Software\Microsoft\NET Framework Setup\NDP\v4\Full" -ErrorAction SilentlyContinue).Version -like "4.5*" -or
       (Get-ItemProperty -Path "HKLM:\Software\Microsoft\NET Framework Setup\NDP\v4\Client" -ErrorAction SilentlyContinue).Version -like "4.5*")) {

        try {
            [System.Reflection.Assembly]::LoadWithPartialName("System.IO.Compression.FileSystem") | Out-Null
            [System.IO.Compression.ZipFile]::ExtractToDirectory("$filePath", "$destinationPath")
        } catch {
            Write-Warning -Message "Unexpected Error. Error details: $_.Exception.Message"
        }
    } else {
        try {
            $shell = New-Object -ComObject Shell.Application
            $shell.Namespace($destinationPath).copyhere(($shell.NameSpace($filePath)).items())
        } catch {
            Write-Warning -Message "Unexpected Error. Error details: $_.Exception.Message"
        }
    }
}

##################################################
# シンボリックリンクを作成する
###################################################
function Get-SymbolicLink
{
    [cmdletBinding()]
    param
    (
        [parameter(
            Mandatory = 1,
            Position  = 0,
            ValueFromPipeline =1,
            ValueFromPipelineByPropertyName = 1)]
        [Alias('FullName')]
        [String[]]
        $Path
    )
    
    process
    {
        try
        {
            $Path `
            | %{
                if ($file = IsFile -Path $_)
                {
                    if (IsFileReparsePoint -Path $file.FullName)
                    {
                        return $file
                    }
                }
                elseif ($directory = IsDirectory -Path $_)
                {
                    if (IsDirectoryReparsePoint -Path $directory.FullName)
                    {
                        return $directory
                    }
                }
            }
        }
        catch
        {
            throw $_
        }
    }    

    begin
    {
        $script:ErrorActionPreference = 'Stop'

        function IsFile ([string]$Path)
        {
            if ([System.IO.File]::Exists($Path))
            {
                Write-Verbose ("Input object : '{0}' detected as File." -f $Path)
                return [System.IO.FileInfo]($Path)
            }
        }

        function IsDirectory ([string]$Path)
        {
            if ([System.IO.Directory]::Exists($Path))
            {
                Write-Verbose ("Input object : '{0}' detected as Directory." -f $Path)
                return [System.IO.DirectoryInfo] ($Path)
            }
        }

        function IsFileReparsePoint ([System.IO.FileInfo]$Path)
        {
            Write-Verbose ('File attribute detected as ReparsePoint')
            $fileAttributes = [System.IO.FileAttributes]::Archive, [System.IO.FileAttributes]::ReparsePoint -join ', '
            $attribute = [System.IO.File]::GetAttributes($Path)
            $result = $attribute -eq $fileAttributes
            if ($result)
            {
                Write-Verbose ('Attribute detected as ReparsePoint. : {0}' -f $attribute)
                return $result
            }
            else
            {
                Write-Verbose ('Attribute detected as NOT ReparsePoint. : {0}' -f $attribute)
                return $result
            }
        }

        function IsDirectoryReparsePoint ([System.IO.DirectoryInfo]$Path)
        {
            $directoryAttributes = [System.IO.FileAttributes]::Directory, [System.IO.FileAttributes]::ReparsePoint -join ', '
            $result = $Path.Attributes -eq $directoryAttributes
            if ($result)
            {
                Write-Verbose ('Attribute detected as ReparsePoint. : {0}' -f $Path.Attributes)
                return $result
            }
            else
            {
                Write-Verbose ('Attribute detected as NOT ReparsePoint. : {0}' -f $Path.Attributes)
                return $result
            }
        }
    }
}

##################################################
# シンボリックリンクを作成する
##################################################
function Set-SymbolicLink
{
    [cmdletBinding(DefaultParameterSetName = "ForceFile")]
    param
    (
        [parameter(
            Mandatory = 1,
            Position  = 0,
            ValueFromPipeline =1,
            ValueFromPipelineByPropertyName = 1)]
        [Alias('TargetPath')]
        [Alias('FullName')]
        [String[]]
        $Path,

        [parameter(
            Mandatory = 1,
            Position  = 1,
            ValueFromPipelineByPropertyName = 1)]
        [String[]]
        $SymbolicPath,

        [parameter(
            Mandatory = 0,
            Position  = 2,
            ValueFromPipelineByPropertyName = 1,
            ParameterSetName = "ForceFile")]
        [bool]
        $ForceFile = $false,

        [parameter(
            Mandatory = 0,
            Position  = 2,
            ValueFromPipelineByPropertyName = 1,
            ParameterSetName = "ForceDirectory")]
        [bool]
        $ForceDirectory = $false
    )
    
    process
    {
        # Work as like LINQ Zip() method
        $zip = New-ZipPairs -key $Path -value $SymbolicPath
        foreach ($x in $zip)
        {
            # reverse original key
            $targetPath = $x.item1
            $SymbolicNewPath = $x.item2

            if ($ForceFile -eq $true)
            {
                [SymbolicLink.Utils]::CreateSymLink($SymbolicNewPath, $Path, $false)
            }
            elseif ($ForceDirectory -eq $true)
            {
                [SymbolicLink.Utils]::CreateSymLink($SymbolicNewPath, $Path, $true)
            }
            elseif ($file = IsFile -Path $targetPath)
            {
                # Check File Type
                if (IsFileAttribute -Path $file)
                {
                    Write-Verbose ("symbolicPath : '{0}',  target : '{1}', isDirectory : '{2}'" -f $SymbolicNewPath, $file.fullname, $false)
                    [SymbolicLink.Utils]::CreateSymLink($SymbolicNewPath, $file.fullname, $false)
                }
            }
            elseif ($directory = IsDirectory -Path $targetPath)
            {
                # Check Directory Type
                if (IsDirectoryAttribute -Path $directory)
                {
                    Write-Verbose ("symbolicPath : '{0}',  target : '{1}', isDirectory : '{2}'" -f $SymbolicNewPath, $directory.fullname, $true)
                    # [SymbolicLink.Utils]::CreateSymLink()
                    [SymbolicLink.Utils]::CreateSymLink($SymbolicNewPath, $directory.fullname, $true)
                }
            } 
            
            # increment prefix length
            $i++
        }
    }    

    begin
    {
        $script:ErrorActionPreference = 'Stop'
        try
        {
            Add-Type -Namespace SymbolicLink -Name Utils -MemberDefinition @"
internal static class Win32
{
    [DllImport("kernel32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.I1)]
    public static extern bool CreateSymbolicLink(string lpSymlinkFileName, string lpTargetFileName, SymLinkFlag dwFlags);
 
    internal enum SymLinkFlag
    {
        File = 0,
        Directory = 1
    }
}
public static void CreateSymLink(string name, string target, bool isDirectory = false)
{
    if (!Win32.CreateSymbolicLink(name, target, isDirectory ? Win32.SymLinkFlag.Directory : Win32.SymLinkFlag.File))
    {
        throw new System.ComponentModel.Win32Exception();
    }
}
"@
        }
        catch
        {
            # catch Exception and ignore it
        }

        function IsFile ([string]$Path)
        {
            if ([System.IO.File]::Exists($Path))
            {
                Write-Verbose ("Input object : '{0}' detected as File." -f $Path)
                return [System.IO.FileInfo]($Path)
            }
        }

        function IsDirectory ([string]$Path)
        {
            if ([System.IO.Directory]::Exists($Path))
            {
                Write-Verbose ("Input object : '{0}' detected as Directory." -f $Path)
                return [System.IO.DirectoryInfo] ($Path)
            }
        }

        function IsFileAttribute ([System.IO.FileInfo]$Path)
        {
            $fileAttributes = [System.IO.FileAttributes]::Archive
            $attribute = [System.IO.File]::GetAttributes($Path.fullname)
            $result = $attribute -eq $fileAttributes
            if ($result)
            {
                Write-Verbose ('Attribute detected as File Archive. : {0}' -f $attribute)
                return $result
            }
            else
            {
                Write-Verbose ('Attribute detected as NOT File archive. : {0}' -f $attribute)
                return $result
            }
        }

        function IsDirectoryAttribute ([System.IO.DirectoryInfo]$Path)
        {
            $directoryAttributes = [System.IO.FileAttributes]::Directory
            $result = $Path.Attributes -eq $directoryAttributes
            if ($result)
            {
                Write-Verbose ('Attribute detected as Directory. : {0}' -f $Path.Attributes)
                return $result
            }
            else
            {
                Write-Verbose ('Attribute detected as NOT Directory. : {0}' -f $Path.Attributes)
                return $result
            }
        }

        function New-ZipPairs
        {
            [CmdletBinding()]
            param
            (
                [parameter(
                    Mandatory = 1,
                    Position = 0,
                    ValueFromPipelineByPropertyName = 1)]
                $key,
 
                [parameter(
                    Mandatory = 1,
                    Position = 1,
                    ValueFromPipelineByPropertyName = 1)]
                $value
             )
 
            begin
            {
                if ($null -eq $key)
                {
                    throw "Key Null Reference Exception!!"
                }

                if ($null -eq $value)
                {
                    throw "Value Null Reference Exception!!"
                }

                function ToListEx ($InputArray, $type)
                {
                    $list = New-Object "System.Collections.Generic.List[$type]"
                    $InputArray | %{$list.Add($_)}
                    return $list
                }

                function GetType ($Object)
                {
                    @($Object) | select -First 1 | %{$_.GetType().FullName}
                }
            }
 
            process
            {
                # Get Type
                $keyType = GetType -Object $key
                $valueType = GetType -Object $value

                # Create Typed container
                $list = New-Object "System.Collections.Generic.List[System.Tuple[$keyType, $valueType]]"

                # To Typed List
                $keys = ToListEx -InputArray $key -type $keyType
                $values = ToListEx -InputArray $value -type $valueType
 
                # Element Count Check
                $keyElementsCount = ($keys | measure).count
                $valueElementsCount = ($values | measure).count
                if ($valueElementsCount -eq 0)
                {
                    # TagValue auto fill with "*" when Value is empty
                    $values = 1..$keyElementsCount | %{"*"}
                }
 
                # Get shorter list
                $length = if ($keyElementsCount -le $valueElementsCount)
                {
                    $keyElementsCount
                }
                else
                {
                    $valueElementsCount
                }
 
                # Make Element Pair
                if ($length -eq 1)
                {
                    $list.Add($(New-Object "System.Tuple[[$keyType],[$valueType]]" ($keys, $values)))
                }
                else
                {
                    $i = 0
                    do
                    {
                        $list.Add($(New-Object "System.Tuple[[$keyType],[$valueType]]" ($keys[$i], $values[$i])))
                        $i++
                    }
                    while ($i -lt $length)
                }
            }
 
            end
            {
                return $list
            }
        }
    }
}

##################################################
# シンボリックリンクを削除する
##################################################
function Remove-SymbolicLink
{
    [cmdletBinding()]
    param
    (
        [parameter(
            Mandatory = 1,
            Position  = 0,
            ValueFromPipeline =1,
            ValueFromPipelineByPropertyName = 1)]
        [Alias('FullName')]
        [String[]]
        $Path
    )
    
    process
    {
        try
        {
            $Path `
            | %{
                if ($file = IsFile -Path $_)
                {
                    if (IsFileReparsePoint -Path $file)
                    {
                        RemoveFileReparsePoint -Path $file
                    }
                }
                elseif ($directory = IsDirectory -Path $_)
                {
                    if (IsDirectoryReparsePoint -Path $directory)
                    {
                        RemoveDirectoryReparsePoint -Path $directory
                    }
                }           
            }
        }
        catch
        {
            throw $_
        }
    }    

    begin
    {
        $script:ErrorActionPreference = 'Stop'

        function IsFile ([string]$Path)
        {
            if ([System.IO.File]::Exists($Path))
            {
                Write-Verbose ("Input object : '{0}' detected as File." -f $Path)
                return [System.IO.FileInfo]($Path)
            }
        }

        function IsDirectory ([string]$Path)
        {
            if ([System.IO.Directory]::Exists($Path))
            {
                Write-Verbose ("Input object : '{0}' detected as Directory." -f $Path)
                return [System.IO.DirectoryInfo] ($Path)
            }
        }

        function IsFileReparsePoint ([System.IO.FileInfo]$Path)
        {
            Write-Verbose ('File attribute detected as ReparsePoint')
            $fileAttributes = [System.IO.FileAttributes]::Archive, [System.IO.FileAttributes]::ReparsePoint -join ', '
            $attribute = [System.IO.File]::GetAttributes($Path.fullname)
            $result = $attribute -eq $fileAttributes
            if ($result)
            {
                Write-Verbose ('Attribute detected as ReparsePoint. : {0}' -f $attribute)
                return $result
            }
            else
            {
                Write-Verbose ('Attribute detected as NOT ReparsePoint. : {0}' -f $attribute)
                return $result
            }
        }

        function IsDirectoryReparsePoint ([System.IO.DirectoryInfo]$Path)
        {
            $directoryAttributes = [System.IO.FileAttributes]::Directory, [System.IO.FileAttributes]::ReparsePoint -join ', '
            $result = $Path.Attributes -eq $directoryAttributes
            if ($result)
            {
                Write-Verbose ('Attribute detected as ReparsePoint. : {0}' -f $Path.Attributes)
                return $result
            }
            else
            {
                Write-Verbose ('Attribute detected as NOT ReparsePoint. : {0}' -f $Path.Attributes)
                return $result
            }
        }

        function RemoveFileReparsePoint ([System.IO.FileInfo]$Path)
        {
            [System.IO.File]::Delete($Path.FullName)
        }
        
        function RemoveDirectoryReparsePoint ([System.IO.DirectoryInfo]$Path)
        {
            [System.IO.Directory]::Delete($Path.FullName)
        }
    }
}

##################################################
# ランダム文字列生成
##################################################
function CreateRandomString( $ByteSize ) {
    # アセンブリロード
    Add-type -AssemblyName System.Web
    # 鍵サイズ分のランダムな文字列を生成
    $RandomString = [System.Web.Security.Membership]::GeneratePassword($ByteSize, 0)
    return $RandomString
}

##################################################
# セッション鍵生成
##################################################
function CreateRandomKey( $BitSize ) {
    if( ($BitSize % 8) -ne 0 ) {
        Write-Output "Key size Error"
        return $null
    }

    # アセンブリロード
    Add-Type -AssemblyName System.Security
    # バイト数にする
    $ByteSize = $BitSize / 8
    # 入れ物作成
    $KeyBytes = New-Object byte[] $ByteSize
    # オブジェクト 作成
    $RNG = New-Object System.Security.Cryptography.RNGCryptoServiceProvider
    # 鍵サイズ分の乱数を生成
    $RNG.GetNonZeroBytes($KeyBytes)
    # オブジェクト削除
    $RNG.Dispose()

    return $KeyBytes
}

##################################################
# AES 暗号化
##################################################
function AESEncrypto($Key, $PlainString) {
    $KeySize = 256
    $BlockSize = 128
    $Mode = "CBC"
    $Padding = "PKCS7"

    if( $Key.Length * 8 -ne $KeySize ) {
        Write-Output "Key size error"
        return $null
    }

    # 平文をバイト配列にする
    $ByteString = [System.Text.Encoding]::UTF8.GetBytes($PlainString)
    # 鍵をバイト配列にする
    $ByteKey = [System.Text.Encoding]::UTF8.GetBytes($Key)
    # アセンブリロード
    Add-Type -AssemblyName System.Security
    # AES オブジェクトの生成
    $AES = New-Object System.Security.Cryptography.AesCryptoServiceProvider
    # 各値セット
    $AES.KeySize = $KeySize
    $AES.BlockSize = $BlockSize
    $AES.Mode = $Mode
    $AES.Padding = $Padding
    # IV 生成
    $AES.GenerateIV()
    # 生成した IV
    $IV = $AES.IV
    # 鍵セット
    $AES.Key = $ByteKey
    # 暗号化オブジェクト生成
    $Encryptor = $AES.CreateEncryptor()
    # 暗号化
    $EncryptoByte = $Encryptor.TransformFinalBlock($ByteString, 0, $ByteString.Length)
    # IV と暗号化した文字列を結合
    $DataByte = $IV + $EncryptoByte
    # 暗号化した文字列
    $EncryptoString = [System.Convert]::ToBase64String($DataByte)

    # オブジェクト削除
    $Encryptor.Dispose()
    $AES.Dispose()

    return $EncryptoString
}

##################################################
# AES 復号化
##################################################
function AESDecrypto($Key, $EncryptoString) {
    $KeySize = 256
    $BlockSize = 128
    $IVSize = $BlockSize / 8
    $Mode = "CBC"
    $Padding = "PKCS7"

    if( $Key.Length * 8 -ne $KeySize ) {
        Write-Output "Key size error"
        return $null
    }

    # 暗号文をバイト配列にする
    $ByteString = [System.Convert]::FromBase64String($EncryptoString)
    # 鍵をバイト配列にする
    $ByteKey = [System.Text.Encoding]::UTF8.GetBytes($Key)

    # IV を取り出す
    $IV = @()
    for( $i = 0; $i -lt $IVSize; $i++) {
        $IV += $ByteString[$i]
    }

    # アセンブリロード
    Add-Type -AssemblyName System.Security
    # オブジェクトの生成
    $AES = New-Object System.Security.Cryptography.AesCryptoServiceProvider
    # 各値セット
    $AES.KeySize = $KeySize
    $AES.BlockSize = $BlockSize
    $AES.Mode = $Mode
    $AES.Padding = $Padding
    # IV セット
    $AES.IV = $IV
    # 鍵セット
    $AES.Key = $ByteKey
    # 復号化オブジェクト生成
    $Decryptor = $AES.CreateDecryptor()
    # 復号化
    $DecryptoByte = $Decryptor.TransformFinalBlock($ByteString, $IVSize, $ByteString.Length - $IVSize)
    # 平文にする
    $PlainString = [System.Text.Encoding]::UTF8.GetString($DecryptoByte)

    # オブジェクト削除
    $Decryptor.Dispose()
    $AES.Dispose()

    return $PlainString
}

##################################################
# Windowsでファイル名に使用できない禁止文字を全角に変換する
# 引数  ：FileName ファイル名
# 戻り値：変換後のファイル名
##################################################
# function ConvertTo-UsedFileName([String]$FileName) {
#     # 禁止文字(半角記号)
#     $CannotUsedFileName = "\/:*?`"><|"
#     # 禁止文字(全角記号)
#     $UsedFileName = "￥／：＊？`”＞＜｜"

#     for ($i = 0; $i -lt $UsedFileName.Length; $i++) {
#         $FileName = $FileName.Replace($CannotUsedFileName[$i], $UsedFileName[$i])
#     }

#     return $FileName
# }
