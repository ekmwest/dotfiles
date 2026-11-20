Set-PSReadLineOption -PredictionSource None
$PSStyle.FileInfo.Directory = $PSStyle.Foreground.BrightCyan

if ((Get-Location).Path -eq $HOME) {
    Set-Location "C:\src"
}


function prompt {
    $exitCode = $LASTEXITCODE
    $location = Get-Location
    $branch = git rev-parse --abbrev-ref HEAD 2>$null

    Write-Host ""
    Write-Host "$location " -NoNewline -ForegroundColor Green

    if ($branch) {
        Write-Host "($branch)" -NoNewline -ForegroundColor Cyan
    }

    Write-Host ""
    $global:LASTEXITCODE = $exitCode
    return "$ "
}


function share($port) {
    cloudflared tunnel --url "localhost:$port" --http-host-header "localhost:$port"
}


Set-Variable KitRepo -Value "C:\src\github\learnpoint\kit" -Option ReadOnly -Force

function kid {
    go build -C $KitRepo

    if ($LASTEXITCODE -eq 0) {
        & (Join-Path $KitRepo "kit.exe") @args
    }
}


function play {
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    $path = Join-Path "C:\src\playground" $Name

    if (Test-Path $path) {
        Write-Error "'$path' already exists."
        return
    }

    New-Item -ItemType Directory -Path $path | Out-Null
    Set-Location $path

    kit copy ekmwest/empty
    if ($LASTEXITCODE -ne 0) {
        Write-Error "kit copy failed."
        return
    }

    code . index.html style.css script.js
}