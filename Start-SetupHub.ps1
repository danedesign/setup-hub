param(
    [switch]$NoGui
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$CatalogPath = Join-Path $Root "catalog\software.json"

if (-not (Test-Path -LiteralPath $CatalogPath)) {
    throw "Catalog not found: $CatalogPath"
}

if ($NoGui) {
    & (Join-Path $Root "scripts\Show-CatalogSummary.ps1") -CatalogPath $CatalogPath
    return
}

& (Join-Path $Root "src\SetupHub.ps1") -CatalogPath $CatalogPath
