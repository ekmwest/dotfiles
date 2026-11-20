#Requires -Version 7
<#
.SYNOPSIS
    Hooks the dotfiles PowerShell profile into your pwsh profile.

.DESCRIPTION
    Adds a line that dot-sources powershell\profile.ps1 from this repo to your
    pwsh profile. Safe to run again: it never removes or overwrites anything,
    and does nothing if the line is already there.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$ProfilePath = $PROFILE.CurrentUserCurrentHost
)

$source = Join-Path $PSScriptRoot 'powershell\profile.ps1'
$line = ". `"$source`""

if (-not (Test-Path $source)) {
    Write-Error "Can't find '$source'."
    return
}

if (-not (Test-Path $ProfilePath)) {
    if ($PSCmdlet.ShouldProcess($ProfilePath, "Create profile with: $line")) {
        New-Item -ItemType File -Path $ProfilePath -Force | Out-Null
        Set-Content -Path $ProfilePath -Value $line
        Write-Host "Created $ProfilePath"
    }
    return
}

$existing = Get-Content -Path $ProfilePath

# Already installed if any line dot-sources this file, quoted or not.
$installed = $existing | Where-Object {
    if ($_.Trim() -notmatch '^\.\s+["'']?(.+?)["'']?$') { return $false }
    try { [IO.Path]::GetFullPath($Matches[1]) -eq [IO.Path]::GetFullPath($source) }
    catch { $false }
}

if ($installed) {
    Write-Host "Already installed in $ProfilePath"
    return
}

if ($PSCmdlet.ShouldProcess($ProfilePath, "Append: $line")) {
    # Start on a new line if the file doesn't end with one.
    $raw = Get-Content -Path $ProfilePath -Raw
    if ($raw -and -not $raw.EndsWith("`n")) {
        Add-Content -Path $ProfilePath -Value ''
    }
    Add-Content -Path $ProfilePath -Value $line
    Write-Host "Added to ${ProfilePath}: $line"
}
