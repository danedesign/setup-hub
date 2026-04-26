param(
    [Parameter(Mandatory)]
    [string]$CatalogPath,

    [Parameter(Mandatory)]
    [string[]]$AppIds,

    [switch]$WhatIf
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$catalog = [System.IO.File]::ReadAllText((Resolve-Path -LiteralPath $CatalogPath), [System.Text.Encoding]::UTF8) | ConvertFrom-Json
$apps = @($catalog.apps) | Where-Object { $AppIds -contains $_.id }
$root = Split-Path -Parent (Split-Path -Parent (Resolve-Path -LiteralPath $CatalogPath))
$downloadDir = Join-Path $root "downloads"

if (-not $apps) {
    Write-Host "No matching apps selected."
    exit 0
}

function Test-InstallerUrl([string]$url) {
    if ([string]::IsNullOrWhiteSpace($url)) { return $false }
    $path = ([uri]$url).AbsolutePath
    return $path -match '\.(exe|msi|msix|appx)$'
}

function Get-DownloadFileName([string]$url, [string]$fallbackName) {
    $fileName = [System.IO.Path]::GetFileName(([uri]$url).AbsolutePath)
    if ([string]::IsNullOrWhiteSpace($fileName) -or $fileName -notmatch '\.(exe|msi|msix|appx)$') {
        $fileName = ($fallbackName -replace '[\\/:*?"<>|]+', '-') + ".exe"
    }
    return $fileName
}

foreach ($app in $apps) {
    if ($app.install.type -eq "winget") {
        $winget = Get-Command winget -ErrorAction SilentlyContinue
        if (-not $winget) {
            throw "winget was not found on this computer."
        }

        if ([string]::IsNullOrWhiteSpace($app.install.packageId)) {
            Write-Host ("Skipping {0}: missing winget package id" -f $app.name)
            continue
        }

        $args = @(
            "install",
            "--id", $app.install.packageId,
            "--exact",
            "--accept-package-agreements",
            "--accept-source-agreements"
        )

        if (-not [string]::IsNullOrWhiteSpace($app.install.scope)) {
            $args += @("--scope", $app.install.scope)
        }

        Write-Host ("Installing {0} ({1})" -f $app.name, $app.install.packageId)

        if ($WhatIf) {
            Write-Host ("winget {0}" -f ($args -join " "))
        }
        else {
            & winget @args
            if ($LASTEXITCODE -ne 0) {
                Write-Warning ("Install failed for {0} with exit code {1}" -f $app.name, $LASTEXITCODE)
            }
        }
        continue
    }

    if ($app.install.type -eq "manual") {
        if ([string]::IsNullOrWhiteSpace($app.install.url)) {
            Write-Host ("Skipping {0}: missing manual URL" -f $app.name)
            continue
        }

        if ($app.install.action -eq "download" -or (Test-InstallerUrl $app.install.url)) {
            $fileName = Get-DownloadFileName $app.install.url $app.name
            $downloadPath = Join-Path $downloadDir $fileName

            Write-Host ("Downloading {0}" -f $app.name)
            if ($WhatIf) {
                Write-Host ("Download {0} -> {1}" -f $app.install.url, $downloadPath)
                Write-Host ("Run {0}" -f $downloadPath)
            }
            else {
                if (-not (Test-Path -LiteralPath $downloadDir)) {
                    New-Item -ItemType Directory -Path $downloadDir -Force | Out-Null
                }
                Invoke-WebRequest -Uri $app.install.url -OutFile $downloadPath -UseBasicParsing
                Start-Process -FilePath $downloadPath -Wait
            }
        }
        else {
            Write-Host ("Opening download page for {0}" -f $app.name)
            if ($WhatIf) {
                Write-Host ("Open {0}" -f $app.install.url)
            }
            else {
                Start-Process $app.install.url
            }
        }
        continue
    }

    if ($app.install.type -eq "offline") {
        if ([string]::IsNullOrWhiteSpace($app.install.installer)) {
            Write-Host ("Skipping {0}: missing local installer path" -f $app.name)
            continue
        }

        $installerPath = Join-Path $root $app.install.installer
        if (-not (Test-Path -LiteralPath $installerPath)) {
            Write-Warning ("Installer not found for {0}: {1}" -f $app.name, $installerPath)
            continue
        }

        Write-Host ("Running local installer for {0}" -f $app.name)
        if ($WhatIf) {
            Write-Host ("Run {0}" -f $installerPath)
        }
        else {
            Start-Process -FilePath $installerPath -Wait
        }
        continue
    }

    Write-Host ("Skipping {0}: unknown install type {1}" -f $app.name, $app.install.type)
}
