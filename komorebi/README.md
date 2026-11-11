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

From WSL, `make link` in the repository copies the following files to the Windows user directory (`C:\Users\<username>\`), backing up changed destinations. `make capture-windows` brings later Windows-side edits back into Git. Native Windows applications and startup registration remain separate prerequisites.

- `komorebi.json` - Main komorebi configuration
- `komorebi.ahk` - AutoHotkey keybindings script
- `applications.json` - Customized app-specific window rules, including the Zoom exception
- `komorebi.bar.json` - Bar appearance and widgets

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
| `Alt+Shift+Ctrl+Win+B/C/D/E/G/I/M/N/O/P/Q/R/S/T/U/W/Y` | Focus named workspace |

### Move to Workspace (Alt+Shift+Ctrl + Number/Letter)
| Key | Action |
|-----|--------|
| `Alt+Shift+Ctrl+1-9` | Move window to workspace 1-9 |
| `Alt+Shift+Ctrl+B/C/D/E/G/I/M/N/O/P/Q/R/S/T/U/W/Y` | Move to named workspace |

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
| `Win+M` | Minimize focused window |

### Terminal-specific Windows shortcuts

In WezTerm, `Win+D` / `Win+Shift+D` split right/down, `Win+W` closes a pane,
`Win+T` opens a tab, `Win+Shift+[` / `Win+Shift+]` switch tabs, and `Win+=` /
`Win+-` change font size. AutoHotkey forwards these through Ctrl+Shift+F13–F20;
the matching bindings and VS Code Dark palette live in `windows/.wezterm.lua`.
The existing Windows Terminal Ctrl+Alt shortcut bridge is retained separately.
Outside these terminals, the existing Show Desktop and minimize shortcuts remain.

### Preserved Windows Shortcuts
| Key | Action |
|-----|--------|
| `Win+L` | Lock screen |
| `Win+Space` | Input language switching |
| `Win+Shift+S` | Open Snipping Tool screenshot selection |
| `Win+PrintScreen` | Save a full-screen screenshot |
| `PrintScreen` | Windows-configured Print Screen action: Snipping Tool or clipboard capture |
| `Alt+PrintScreen` | Copy the active window screenshot to the clipboard |
| `Win+Alt+PrintScreen` | Xbox Game Bar screenshot capture, when available |

`Win+Shift+S` explicitly launches `ms-screenclip:`; the other screenshot combinations pass through. Other Win combinations explicitly listed in the script remain blocked unless assigned to window-management actions.

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

Configured workspaces: `1-9, B, C, D, E, I, M, N, O, P, Q, R, S, T, U, W, Y, G`. G is appended so existing workspace indices stay unchanged.

### App-to-Workspace Rules

All app mappings use `initial_workspace_rules`: applications open on their assigned workspace, but manual moves remain in effect. Do not replace these with permanent `workspace_rules`; those re-enforce placement on managed-window events and prevent moving different apps together for tiling. BSP splits multiple windows on the same workspace; a workspace with one window fills the screen without native maximization.

| Workspace | Apps |
|-----------|------|
| B | Normal Chrome, Edge, and Arc windows, regardless of the current website; unmatched standalone web apps |
| C | Slack, Discord, Teams, Skype, email, Google Messages, and other configured messaging apps |
| D | Windows Terminal, WezTerm, Ghostty, Alacritty, Kitty, and configured terminal hosts |
| E | Other video and music streaming services formerly assigned to M, excluding YouTube and Twitch |
| G | Final Fantasy XIV and its launchers |
| M | Zoom and standalone Google Meet web-app windows |
| N | Obsidian, Notion |
| P | Figma, Linear |
| S | Calendar, Notion Calendar, Cron, Todoist; standalone calendar web apps |
| T | Twitch |
| U | SteelSeries GG, WaveLink, StreamDeck, Cisco AnyConnect |
| Y | YouTube, YouTube Music, Cypress |

Normal Chrome and Edge windows are recognized by the ` - Google Chrome` and ` - Microsoft Edge` title suffixes and initially route to B regardless of the active website. Arc windows also initially route to B. Service-title rules apply only to standalone Chrome/Edge web-app windows without those browser suffixes: Messages opens in C, Calendar in S, YouTube in Y, Twitch in T, Google Meet/Zoom in M, and other configured streaming services in E. Later title changes and manual workspace moves do not continuously reclassify an already-routed window.

Within standalone web apps, Zoom/Google Meet app-title prefixes take precedence over the other service categories. Calendar/Todoist titles then take precedence over communication and streaming titles. YouTube takes precedence over Twitch if both names appear; other communication titles take precedence over other streaming titles in E. The Google Messages rule includes its initial `Messages` title, before the conversation title finishes loading after sign-in. Rules move entire windows, not individual tabs. New services need an explicit identifier in `komorebi.json`; there is no automatic streaming-service classification.

Windows Terminal is identified by `CASCADIA_HOSTING_WINDOW_CLASS`, rather than force-managing every window owned by `WindowsTerminal.exe`. This excludes its `IME` and `MSCTFIME UI` helper windows. Final Fantasy XIV uses `FFXIVGAME` so its borderless game window remains managed.

The vendor `applications.json` ignores `Zoom.exe` by default. The committed `applications.json` contains the customized active rules with that application entry removed, so Zoom's normal windows can be managed and routed to M without force-managing every Zoom helper window. Fetching a fresh vendor rules file may restore the Zoom ignore entry; retain this customization.

#### Komorebi 0.1.40 regex handling

This version does not populate the shared regex cache from workspace rules alone. The browser executable and service-title regexes are also registered in `tray_and_multi_window_applications`. Keep those regex strings identical to their corresponding workspace-rule strings. A single service-title regex avoids overlapping workspace rules matching the same browser window more than once.

#### Applying changes under your control

Writing the active `komorebi.json` triggers an automatic reload and can move windows or change focus. To avoid disruption, prepare changes separately and apply them only when ready.

The active and pending copies on this computer were identical when collected. The repository now owns the active files; pending copies are not deployed. To apply repository changes, run `make link` from WSL when ready. It only copies changed files and never stops the manager or discards saved placements.

Press `Alt+O` to activate updated AutoHotkey bindings. Use `--clean-state` only when intentionally discarding cached placement; it will rearrange windows.

## Why AutoHotkey Instead of whkd?

[whkd](https://github.com/LGUG2Z/whkd) is komorebi's companion hotkey daemon, but it **cannot use the Windows key as a modifier** due to Microsoft's restrictions on global hotkey registration. AutoHotkey v2 can intercept these keys using a low-level keyboard hook.

## Troubleshooting

### Hotkeys not working
1. Check if AutoHotkey is running (system tray icon)
2. Press `Alt+O` to reload the AHK script
3. Verify komorebi is running: `komorebic state`

### Workspace shortcuts do nothing after a display change
The AHK script debounces `WM_DISPLAYCHANGE` for five seconds and checks the running single-monitor state. It reapplies JSON only when named workspaces are missing, skips paused/multi-monitor setups, and reports recovery failures through a tray notification.

If `komorebic state` shows only an unnamed workspace, the named destinations are missing from the running monitor state. Press `Alt+Shift+O` to reapply the active `komorebi.json` beside the AHK script, or run:

```powershell
komorebic replace-configuration "$env:USERPROFILE\komorebi.json"
```

This can change window placement or focus. `reload-configuration` only reloads legacy AHK/PowerShell configuration; it does not reload JSON. After updating the bindings script, press `Alt+O` once to activate the corrected JSON-reload shortcut.

### Browser/Copilot opening on hyper key
You forgot to disable the Office Key handler. See [Disable Office Key](#disable-office-key-required).

### Windows shortcuts still triggering
The AHK script blocks most Win key combos. If something slips through, add it to the block list in `komorebi.ahk`.

### Focus not following workspace switch
The AHK script includes a `SwitchWorkspace` helper that cycles focus after switching. If focus is still lost, increase the `Sleep(50)` delay.

## Files

- `komorebi.json` - Komorebi configuration
- `komorebi.ahk` - AutoHotkey keybindings
- `applications.json` - Customized app-specific rules
- `komorebi.bar.json` - Bar configuration

## Credits

- [komorebi](https://github.com/LGUG2Z/komorebi) by LGUG2Z
- [aerospace](https://github.com/nikitabobko/AeroSpace) by nikitabobko (keybinding inspiration)
- [AutoHotkey](https://www.autohotkey.com/)
