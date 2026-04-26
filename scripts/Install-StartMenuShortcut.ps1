param(
    [string]$ShortcutName = "Personal Windows Setup Hub"
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$startScript = Join-Path $root "Start-SetupHub.ps1"

if (-not (Test-Path -LiteralPath $startScript)) {
    throw "Start script not found: $startScript"
}

$programsPath = [Environment]::GetFolderPath("Programs")
$shortcutPath = Join-Path $programsPath ($ShortcutName + ".lnk")
$powershellPath = Join-Path $env:SystemRoot "System32\WindowsPowerShell\v1.0\powershell.exe"

$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = $powershellPath
$shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$startScript`""
$shortcut.WorkingDirectory = $root
$shortcut.Description = "Open the personal Windows setup checklist."
$shortcut.IconLocation = "$powershellPath,0"
$shortcut.Save()

Write-Host "Created Start Menu shortcut: $shortcutPath"

