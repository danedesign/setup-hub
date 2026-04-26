# Agent Notes

This project is a personal Windows setup and software checklist tool.

## User Intent

The user wants a personal Windows setup hub, not just a bulk installer. It should act like a checklist and lightweight software-management console:

- Maintain a custom catalog of recommended software.
- Install online apps through winget when possible.
- Handle non-winget apps through direct downloads, download pages, or local installers.
- Show what is installed and what is missing.
- Keep useful app descriptions and config paths.
- Open config paths directly from the GUI.
- Eventually support backup/restore for app configs.
- Be convenient to launch from the Start Menu.
- Be distributable from GitHub to a fresh Windows install with a one-line bootstrap command.

## Current Shape

Main files:

- `Start-SetupHub.ps1`: normal GUI launcher.
- `Start-SetupHub-Debug.ps1`: debug launcher that keeps the console open and writes logs under `logs\`.
- `src\SetupHub.ps1`: WPF GUI.
- `catalog\software.json`: software catalog.
- `scripts\Install-Apps.ps1`: install/open handler for selected apps.
- `scripts\Install-StartMenuShortcut.ps1`: creates Start Menu shortcut.
- `scripts\Bootstrap-SetupHub.ps1`: GitHub bootstrap installer.
- `README.md`: user-facing usage notes.

The GUI currently supports:

- Search.
- Category filter.
- Installed-state filter.
- Clickable column sorting.
- Installed checklist state: `Unchecked`, `Installed`, `Not installed`, `Unknown`.
- `Check installed` for winget-backed apps.
- `Install / open selected`.
- `Open config path`.
- Export install plan and preview commands.

## Install Behavior

`scripts\Install-Apps.ps1` handles app types from `catalog\software.json`:

- `winget`: runs `winget install --id ... --exact --accept-package-agreements --accept-source-agreements`.
- `winget` with `"scope": "machine"`: appends `--scope machine`.
- `manual` with `"action": "download"`: downloads URL to `downloads\` and runs it.
- `manual` without download action: opens the URL in the browser.
- `offline`: runs a local installer path from the catalog.

Examples:

- iCloud: manual download from Apple direct URL.
- iTunes: manual download from Apple direct URL.
- Visual Studio Installer: manual download action even though URL ends in `.aspx`.
- Apollo: opens `https://github.com/ClassicOldSong/Apollo`.
- StartAllBack: winget package `StartIsBack.StartAllBack` with machine scope.
- VMware Workstation: opens TechSpot page.

## Important Fixes Already Made

- PowerShell UTF-8 handling was fixed by reading JSON with `[System.IO.File]::ReadAllText(..., [System.Text.Encoding]::UTF8)`.
- Avoid non-ASCII UI separators like `·`, because they showed as `Â·` in Windows PowerShell. Use ASCII separators like ` | `.
- The list once only showed VMware because a local `$category` variable polluted the filter state. Filters now use script-scoped state variables.
- Column sorting should listen to native GridView column header clicks. Avoid replacing headers with custom header controls unless carefully tested.
- Mixed installs such as iCloud + F3D should use `-AppIdsFile`, not direct multiple positional IDs. The GUI writes selected IDs to `output\selected-app-ids.txt`.
- `Start-SetupHub-Debug.ps1` exists for crash/error capture.

## GitHub Bootstrap

Configured GitHub repo:

```text
https://github.com/danedesign/setup-hub.git
```

Current branch is `master`, not `main`.

IEX command:

```powershell
irm https://raw.githubusercontent.com/danedesign/setup-hub/master/scripts/Bootstrap-SetupHub.ps1 | iex
```

`scripts\Bootstrap-SetupHub.ps1` has:

```powershell
$DefaultRepo = "danedesign/setup-hub"
$DefaultBranch = "master"
```

If the IEX command returns 404 or `Invoke-WebRequest : 404`, check:

- The latest local fixes were committed and pushed.
- The remote branch is still `master`.
- The repo is public or credentials are available.
- The raw GitHub URL contains `/master/`, not `/main/`.

## User Preferences

- The user prefers Chinese explanations.
- Keep replies practical and not overly technical unless needed.
- The user wants a commit message after every code change.
- Keep this `AGENTS.md` file updated whenever a new feature, important implementation detail, known issue, workflow change, GitHub/bootstrap detail, or user preference is added.
- If asked, commit locally when possible; if Git fails because of permissions or lock issues, provide exact commands and a commit message.
- Do not remove user changes.
- The user likes the idea of a polished but transparent tool, not necessarily a compiled EXE yet.
- The current preferred distribution method is GitHub plus one-line bootstrap.

## Known Local Issue

At one point `git add` failed with:

```text
fatal: Unable to create '.git/index.lock': Permission denied
```

If this happens again, check for Git locks/processes. If no lock file exists, the environment may not allow writing `.git`; ask the user to commit locally or provide commands.

## Useful Commands

Run normal GUI:

```powershell
.\Start-SetupHub.ps1
```

Run debug GUI:

```powershell
.\Start-SetupHub-Debug.ps1
```

Create Start Menu shortcut:

```powershell
.\scripts\Install-StartMenuShortcut.ps1
```

Preview install actions:

```powershell
.\scripts\Install-Apps.ps1 -CatalogPath .\catalog\software.json -AppIdsFile .\output\selected-app-ids.txt -WhatIf
```

Check catalog summary:

```powershell
.\Start-SetupHub.ps1 -NoGui
```
