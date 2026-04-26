param(
    [string]$Repo = "",
    [string]$Branch = "main",
    [string]$ZipUrl = "",
    [string]$InstallDir = "$env:LOCALAPPDATA\PersonalWindowsSetupHub",
    [switch]$CreateStartMenuShortcut
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Edit these before publishing if you want the short IEX command to work.
$DefaultRepo = "OWNER/REPO"
$DefaultBranch = "main"
$DefaultCreateStartMenuShortcut = $true

if ([string]::IsNullOrWhiteSpace($Repo) -and $DefaultRepo -ne "OWNER/REPO") {
    $Repo = $DefaultRepo
}

if ($Branch -eq "main" -and $DefaultBranch -ne "main") {
    $Branch = $DefaultBranch
}

if ([string]::IsNullOrWhiteSpace($ZipUrl)) {
    if ([string]::IsNullOrWhiteSpace($Repo)) {
        throw "Set `$DefaultRepo inside this script before publishing, or provide -Repo owner/name."
    }

    $ZipUrl = "https://github.com/$Repo/archive/refs/heads/$Branch.zip"
}

$tempRoot = Join-Path $env:TEMP ("setup-hub-bootstrap-" + [guid]::NewGuid().ToString("N"))
$zipPath = Join-Path $tempRoot "source.zip"
$extractPath = Join-Path $tempRoot "extract"

New-Item -ItemType Directory -Path $tempRoot, $extractPath -Force | Out-Null

try {
    Write-Host "Downloading Setup Hub..."
    Invoke-WebRequest -Uri $ZipUrl -OutFile $zipPath -UseBasicParsing

    Write-Host "Extracting Setup Hub..."
    Expand-Archive -LiteralPath $zipPath -DestinationPath $extractPath -Force

    $sourceRoot = Get-ChildItem -LiteralPath $extractPath -Directory | Select-Object -First 1
    if (-not $sourceRoot) {
        throw "Downloaded archive did not contain a project folder."
    }

    if (Test-Path -LiteralPath $InstallDir) {
        $backupDir = $InstallDir + ".backup-" + (Get-Date -Format "yyyyMMdd-HHmmss")
        Write-Host "Backing up existing install to $backupDir"
        Move-Item -LiteralPath $InstallDir -Destination $backupDir
    }

    Write-Host "Installing to $InstallDir"
    New-Item -ItemType Directory -Path (Split-Path -Parent $InstallDir) -Force | Out-Null
    Copy-Item -LiteralPath $sourceRoot.FullName -Destination $InstallDir -Recurse -Force

    if ($CreateStartMenuShortcut -or $DefaultCreateStartMenuShortcut) {
        $shortcutScript = Join-Path $InstallDir "scripts\Install-StartMenuShortcut.ps1"
        if (Test-Path -LiteralPath $shortcutScript) {
            & $shortcutScript
        }
    }

    $startScript = Join-Path $InstallDir "Start-SetupHub.ps1"
    if (-not (Test-Path -LiteralPath $startScript)) {
        throw "Start script not found after install: $startScript"
    }

    Write-Host "Starting Setup Hub..."
    & $startScript
}
finally {
    if (Test-Path -LiteralPath $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}
