param(
    [Parameter(Mandatory)]
    [string]$CatalogPath
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$catalog = [System.IO.File]::ReadAllText((Resolve-Path -LiteralPath $CatalogPath), [System.Text.Encoding]::UTF8) | ConvertFrom-Json
$apps = @($catalog.apps)

$apps |
    Group-Object { $_.install.type } |
    Sort-Object Name |
    ForEach-Object {
        "{0}: {1}" -f $_.Name, $_.Count
    }

"Total: {0}" -f $apps.Count
