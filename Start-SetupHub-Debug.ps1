$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$LogDir = Join-Path $Root "logs"
if (-not (Test-Path -LiteralPath $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

$LogPath = Join-Path $LogDir ("setup-hub-" + (Get-Date -Format "yyyyMMdd-HHmmss") + ".log")

try {
    Start-Transcript -Path $LogPath -Force | Out-Null
    & (Join-Path $Root "Start-SetupHub.ps1")
}
catch {
    Write-Host ""
    Write-Host "Setup Hub crashed. Error details:"
    Write-Host $_.Exception.Message
    Write-Host ""
    Write-Host "Full error:"
    Write-Host ($_ | Out-String)
}
finally {
    try { Stop-Transcript | Out-Null } catch {}
    Write-Host ""
    Write-Host "Log saved to: $LogPath"
    Write-Host "Press Enter to close this window."
    [void][Console]::ReadLine()
}
