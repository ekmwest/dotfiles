Set-PSReadLineOption -PredictionSource None
$PSStyle.FileInfo.Directory = $PSStyle.Foreground.BrightCyan

if ((Get-Location).Path -eq $HOME) {
    Set-Location "C:\src"
}


function Get-GitHead {
    if ($PWD.Provider.Name -ne 'FileSystem') { return }

    try {
        $dir = $PWD.ProviderPath
        while ($dir) {
            $dotGit = Join-Path $dir '.git'

            if ([IO.Directory]::Exists($dotGit)) {
                $gitDir = $dotGit
                break
            }

            if ([IO.File]::Exists($dotGit)) {
                $line = [IO.File]::ReadAllText($dotGit).Trim()
                if ($line -notmatch '^gitdir:\s*(.+)$') { return }
                $gitDir = $Matches[1]
                if (-not [IO.Path]::IsPathRooted($gitDir)) {
                    $gitDir = [IO.Path]::GetFullPath((Join-Path $dir $gitDir))
                }
                break
            }

            $dir = [IO.Path]::GetDirectoryName($dir)
        }

        if (-not $gitDir) { return }

        $head = [IO.File]::ReadAllText((Join-Path $gitDir 'HEAD')).Trim()

        if ($head -match '^ref:\s*refs/heads/(.+)$') {
            return $Matches[1]
        }

        if ($head.Length -ge 7) {
            return $head.Substring(0, 7)
        }
    }
    catch {
        return
    }
}


function prompt {
    $ok = $?
    $exitCode = $LASTEXITCODE
    $location = Get-Location
    $branch = Get-GitHead

    Write-Host ""
    Write-Host "$location " -NoNewline -ForegroundColor Green

    if ($branch) {
        Write-Host "($branch) " -NoNewline -ForegroundColor Cyan
    }

    if (-not $ok -and $exitCode -is [int] -and $exitCode -ne 0) {
        Write-Host "[$exitCode]" -NoNewline -ForegroundColor Red
    }

    Write-Host ""
    Write-Host '$' -NoNewline -ForegroundColor ($ok ? 'Gray' : 'Red')
    $global:LASTEXITCODE = $exitCode
    return " "
}


function share {
    param(
        [Parameter(Mandatory)]
        [ValidateRange(1, 65535)]
        [int]$Port
    )

    if (-not (Get-Command cloudflared -ErrorAction SilentlyContinue)) {
        Write-Error "cloudflared not found on PATH."
        return
    }

    cloudflared tunnel --url "localhost:$Port" --http-host-header "localhost:$Port"
}


Set-Variable KitRepo -Value "C:\src\github\learnpoint\kit" -Option ReadOnly -Force

function kid {
    go build -C $KitRepo
    if (-not $?) { Write-Error "kid: build failed, kit not run."; return }

    & (Join-Path $KitRepo "kit.exe") @args
}


Set-Variable PlaygroundRoot -Value "C:\src\playground" -Option ReadOnly -Force

function play {
    param(
        [Parameter(Mandatory)]
        [ValidateScript({
            -not [string]::IsNullOrWhiteSpace($_) -and
            $_ -ne '.' -and $_ -ne '..' -and
            $_.IndexOfAny([IO.Path]::GetInvalidFileNameChars()) -lt 0
        }, ErrorMessage = "'{0}' is not valid. Name must be a single folder name.")]
        [string]$Name
    )

    if (-not (Get-Command kit -ErrorAction SilentlyContinue)) {
        Write-Error "kit not found on PATH."
        return
    }

    $path = Join-Path $PlaygroundRoot $Name

    if (Test-Path $path) {
        Write-Error "'$path' already exists."
        return
    }

    New-Item -ItemType Directory -Path $path | Out-Null
    Push-Location $path

    kit copy ekmwest/empty
    if ($LASTEXITCODE -ne 0) {
        Pop-Location
        Remove-Item $path -Recurse -Force
        Write-Error "kit copy failed."
        return
    }

    code . index.html style.css script.js
}