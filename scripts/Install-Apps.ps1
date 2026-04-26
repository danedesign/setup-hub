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

if (-not $apps) {
    Write-Host "No matching apps selected."
    exit 0
}

$winget = Get-Command winget -ErrorAction SilentlyContinue
if (-not $winget) {
    throw "winget was not found on this computer."
}

foreach ($app in $apps) {
    if ($app.install.type -ne "winget") {
        Write-Host ("Skipping {0}: install type is {1}" -f $app.name, $app.install.type)
        continue
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
}
