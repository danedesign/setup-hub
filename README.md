# Personal Windows Setup Hub

This is a personal Windows setup assistant for a custom app catalog, online installs, offline installers, and future config backup/restore.

## Start the GUI

Run this from PowerShell:

```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force
.\Start-SetupHub.ps1
```

If the window closes unexpectedly, run the debug launcher instead:

```powershell
.\Start-SetupHub-Debug.ps1
```

It keeps the console open and writes logs under `logs\`.

The first version reads `catalog\software.json`, lets you select apps, exports an install plan, and can run winget installs for selected winget-backed apps.

Use `Check installed` in the GUI to turn it into a checklist. Apps with winget package IDs can be marked `Installed` or `Not installed`; manual and offline entries stay `Unknown` until specific detection rules are added.

## Add to Start Menu

Run this once:

```powershell
.\scripts\Install-StartMenuShortcut.ps1
```

Then open "Personal Windows Setup Hub" from the Start Menu.

## Bootstrap On A New Computer

After this project is on GitHub, a new computer can install and run it with one command.

Before publishing, edit `scripts\Bootstrap-SetupHub.ps1` and replace:

```powershell
$DefaultRepo = "OWNER/REPO"
```

with your GitHub repo, for example:

```powershell
$DefaultRepo = "danedesign/setup-hub"
```

Fast IEX pattern:

```powershell
irm https://raw.githubusercontent.com/danedesign/setup-hub/master/scripts/Bootstrap-SetupHub.ps1 | iex
```

Safer inspectable pattern:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "iwr https://raw.githubusercontent.com/danedesign/setup-hub/master/scripts/Bootstrap-SetupHub.ps1 -OutFile $env:TEMP\Bootstrap-SetupHub.ps1; & $env:TEMP\Bootstrap-SetupHub.ps1 -Repo danedesign/setup-hub -Branch master -CreateStartMenuShortcut"
```

The repo is configured as `danedesign/setup-hub`.

The IEX pattern is shortest. The inspectable pattern downloads the bootstrap script first, then runs it locally, which is easier to inspect and debug.

## Catalog Rules

- `install.type = "winget"`: installed through winget.
- `install.type = "manual"`: opens a download page or reminds you to install manually.
- `install.type = "offline"`: expected to use a local installer later.
- `status = "ready"`: likely ready to run.
- `status = "verify"`: needs package ID/source confirmation before unattended use.
- `status = "manual"`: intentionally not automated yet.
