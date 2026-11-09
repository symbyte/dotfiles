# Komorebi Windows Setup (Aerospace-Style)

A guide to setting up [komorebi](https://github.com/LGUG2Z/komorebi) on Windows with keybindings that match [aerospace](https://github.com/nikitabobko/AeroSpace) on macOS, using the hyper key (Alt+Shift+Ctrl+Win).

## Prerequisites

- Windows 10/11
- [komorebi](https://github.com/LGUG2Z/komorebi) installed
- [AutoHotkey v2](https://www.autohotkey.com/) installed

## Installation

### 1. Install Dependencies

```powershell
winget install LGUG2Z.komorebi
winget install AutoHotkey.AutoHotkey
```

The Windows installation was upgraded to komorebi **0.1.41**. For future upgrades, stop the manager with `komorebic stop`, run `winget upgrade --id LGUG2Z.komorebi --exact --source winget`, then restart with `komorebic start --config "$env:USERPROFILE\komorebi.json"`. Stopping and restarting can change focus or window placement; do not use `--clean-state` unless intentionally discarding saved placement.

### 2. Copy Configuration Files

Copy the following files to your user directory (`C:\Users\<username>\`):

- `komorebi.json` - Main komorebi configuration
- `komorebi.ahk` - AutoHotkey keybindings script
- `applications.json` - App-specific window rules (optional, use komorebi's default)

### 3. Add to Startup

Register both programs in the current user's Windows Startup folder. They run at Windows sign-in, including after a reboot, without requiring WSL or a terminal session:

```powershell
komorebic enable-autostart --config "$env:USERPROFILE\komorebi.json"

$startup = [Environment]::GetFolderPath('Startup')
$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut((Join-Path $startup 'komorebi-keys.lnk'))
$shortcut.TargetPath = Join-Path $env:ProgramFiles 'AutoHotkey\v2\AutoHotkey64.exe'
$shortcut.Arguments = '"' + (Join-Path $env:USERPROFILE 'komorebi.ahk') + '"'
$shortcut.WorkingDirectory = $env:USERPROFILE
$shortcut.WindowStyle = 7
$shortcut.Description = 'Load Komorebi workspace hotkeys at Windows sign-in'
$shortcut.Save()
```

These commands save startup entries; they do not launch or reload either program. `komorebi.lnk` loads the active `komorebi.json`, while `komorebi-keys.lnk` loads the active `komorebi.ahk`. Future edits to those files are used on the next sign-in; `komorebi.pending.json` is not loaded.

For Komorebi 0.1.40, do not use the obsolete `--ahk` argument on `komorebic start`; AutoHotkey starts independently through its own shortcut. The bindings launcher must target `AutoHotkey64.exe`, not `AutoHotkey.exe`.

When replacing the old batch-file launcher, remove it to avoid duplicate AutoHotkey startup entries:

```powershell
Remove-Item -LiteralPath (Join-Path $startup 'komorebi-keys.bat') -ErrorAction SilentlyContinue
```

## Critical Windows Fixes

### Disable Office Key (REQUIRED)

The hyper key combo (Alt+Shift+Ctrl+Win) triggers Windows' "Office Key" handler, which opens Copilot/Office apps. **You must disable this:**

Run in PowerShell:
```powershell
New-Item -Path 'HKCU:\Software\Classes\ms-officeapp\Shell\Open\Command' -Force
Set-ItemProperty -Path 'HKCU:\Software\Classes\ms-officeapp\Shell\Open\Command' -Name '(Default)' -Value 'rundll32'
```

To undo:
```powershell
Remove-Item -Path 'HKCU:\Software\Classes\ms-officeapp\Shell' -Recurse
```

### Disable Windows Copilot (Optional)

Run in **elevated** PowerShell (Run as Administrator):
```powershell
New-Item -Path 'HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot' -Force
Set-ItemProperty -Path 'HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot' -Name 'TurnOffWindowsCopilot' -Value 1 -Type DWord
```

Then sign out and back in.

## Keybindings

### Window Focus (Hyper + HJKL)
| Key | Action |
|-----|--------|
| `Alt+Shift+Ctrl+Win+H` | Focus left |
| `Alt+Shift+Ctrl+Win+J` | Focus down |
| `Alt+Shift+Ctrl+Win+K` | Focus up |
| `Alt+Shift+Ctrl+Win+L` | Focus right |

### Window Movement (Alt+Shift+Ctrl + HJKL)
| Key | Action |
|-----|--------|
| `Alt+Shift+Ctrl+H` | Move window left |
| `Alt+Shift+Ctrl+J` | Move window down |
| `Alt+Shift+Ctrl+K` | Move window up |
| `Alt+Shift+Ctrl+L` | Move window right |

### Workspace Focus (Hyper + Number/Letter)
| Key | Action |
|-----|--------|
| `Alt+Shift+Ctrl+Win+1-9` | Focus workspace 1-9 |
| `Alt+Shift+Ctrl+Win+B/C/D/E/I/M/N/O/P/Q/R/S/T/U/W/Y` | Focus named workspace |

### Move to Workspace (Alt+Shift+Ctrl + Number/Letter)
| Key | Action |
|-----|--------|
| `Alt+Shift+Ctrl+1-9` | Move window to workspace 1-9 |
| `Alt+Shift+Ctrl+B/C/D/E/I/M/N/O/P/Q/R/S/T/U/W/Y` | Move to named workspace |

### Layout & Resize
| Key | Action |
|-----|--------|
| `Alt+/` | Cycle layout |
| `Alt+,` | Toggle monocle |
| `Alt+Shift+Ctrl+-` | Resize smaller |
| `Alt+Shift+Ctrl+=` | Resize larger |

### Other
| Key | Action |
|-----|--------|
| `Win+W` | Close focused window |
| `Alt+`` ` | Cycle to previous workspace |
| `Alt+Shift+Ctrl+Win+Tab` | Move workspace to next monitor |
| `Alt+Shift+Ctrl+Win+;` | Toggle float |
| `Alt+Shift+Ctrl+Win+F` | Retile |
| `Alt+O` | Reload AHK script |
| `Alt+Shift+O` | Reload komorebi config |

### Preserved Windows Shortcuts
| Key | Action |
|-----|--------|
| `Win+L` | Lock screen |
| `Win+Space` | Input language switching |

All other Win key combinations are blocked.

## Configuration Details

### komorebi.json

Key settings matching aerospace behavior:

```json
{
  "default_workspace_padding": 0,
  "default_container_padding": 0,
  "mouse_follows_focus": true,
  "resize_delta": 50
}
```

### Workspaces

Configured workspaces: `1-9, B, C, D, E, I, M, N, O, P, Q, R, S, T, U, W, Y`

### App-to-Workspace Rules

Apps are automatically moved to designated workspaces:

| Workspace | Apps |
|-----------|------|
| B | Chrome |
| C | Slack |
| M | Zoom |
| N | Obsidian, Notion |
| P | Figma, Linear |
| S | Todoist |
| T | Ghostty |
| U | WaveLink, StreamDeck, Cisco AnyConnect |
| Y | Cypress |

## Why AutoHotkey Instead of whkd?

[whkd](https://github.com/LGUG2Z/whkd) is komorebi's companion hotkey daemon, but it **cannot use the Windows key as a modifier** due to Microsoft's restrictions on global hotkey registration. AutoHotkey v2 can intercept these keys using a low-level keyboard hook.

## Troubleshooting

### Hotkeys not working
1. Check if AutoHotkey is running (system tray icon)
2. Press `Alt+O` to reload the AHK script
3. Verify komorebi is running: `komorebic state`

### Browser/Copilot opening on hyper key
You forgot to disable the Office Key handler. See [Disable Office Key](#disable-office-key-required).

### Windows shortcuts still triggering
The AHK script blocks most Win key combos. If something slips through, add it to the block list in `komorebi.ahk`.

### Focus not following workspace switch
The AHK script includes a `SwitchWorkspace` helper that cycles focus after switching. If focus is still lost, increase the `Sleep(50)` delay.

## Files

- `komorebi.json` - Komorebi configuration
- `komorebi.ahk` - AutoHotkey keybindings
- `applications.json` - App-specific rules (optional)

## Credits

- [komorebi](https://github.com/LGUG2Z/komorebi) by LGUG2Z
- [aerospace](https://github.com/nikitabobko/AeroSpace) by nikitabobko (keybinding inspiration)
- [AutoHotkey](https://www.autohotkey.com/)
