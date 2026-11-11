# Dotfiles

Personal configuration in GNU Stow packages, plus explicit Windows configuration copies.

## One-step setup

Prerequisites: Git, Make, and [Homebrew](https://brew.sh). On Linux/WSL, install
`build-essential`, `curl`, and `git` with the system package manager before installing
Homebrew. Put Homebrew on PATH using `brew shellenv` from its installation prefix.

```bash
git clone https://github.com/symbyte/dotfiles.git ~/dotfiles
cd ~/dotfiles
make
```

`make` (also `make setup` or `make all`) runs these steps in order:

1. Setup grants **formula-specific** Homebrew trust to the fully qualified recipes
   declared in the Brewfile, then runs
   `brew bundle install --no-upgrade --file=homebrew/Brewfile`. This installs missing
   committed dependencies without an unrelated bulk upgrade. Mac-only taps, casks,
   fonts, and VS Code extensions are conditional on macOS.
2. Bun installs the locked dependencies of the personal OMP Delta extension.
3. GNU Stow links the selected packages into your home directory. Existing files
   are moved to a timestamped backup under `~/.local/state/dotfiles/backups/`;
   unexpected directory/file collisions fail before any files are moved.
4. Zellij's **directory** is linked to `zellij/.config/zellij`. Zellij replaces its
   config when saving preferences; a directory link keeps those saves in Git rather
   than allowing a replaced file symlink to drift away from the repository.
5. Under WSL, Windows configs are copied to the detected Windows user profile.
   Unchanged copies are not rewritten. Changed copies are backed up alongside the
   Linux backups. Windows Developer Mode or elevation is not required.

Setup does not start/restart applications, change the login shell, or install
native Windows applications. Windows applications must already be installed;
see [Komorebi setup](komorebi/README.md). Writing a changed config can trigger an
application's own automatic reload, so run setup when such changes are appropriate.

Existing Homebrew packages can still be upgraded if required by a newly installed
dependency. Trust is limited to the named third-party formulae in the selected
Brewfile (OMP, Bun, CockroachDB, kt, Vault, Lazynpm, Snyk, and Graphite in the default
list), not entire taps or all Homebrew code. Review new third-party recipes before
adding them: running setup authorizes their installation code.

## Commands

| Command | Behavior |
| --- | --- |
| `make` / `make setup` | Install dependencies, then link/copy configurations |
| `make deps` | Install Brewfile and locked OMP extension dependencies only |
| `make link` | Link/copy configurations without installing dependencies |
| `make check` | Fail if a managed home link is missing/broken or a Windows copy differs |
| `make capture-windows` | Copy Windows-side edits back into tracked sources; review and commit afterward |
| `make delete` | Remove managed home links; keep backups, Windows copies, and application data |
| `make add ARGS='package path/relative/to/home'` | Collect another configuration using the existing add helper |

Windows capture refuses to overwrite uncommitted repository changes to the same
file. It does not silently discard a missing Windows config. Run `make check`
before setup when you want to detect Windows edits before deploying repository
versions over them.

Overrides:

```bash
make link TARGET=/tmp/dotfiles-home WINDOWS_HOME=  # Linux-only staging home
make link WINDOWS_HOME=/mnt/c/Users/steve          # Explicit Windows profile
make deps BREWFILE=/path/to/Brewfile               # Alternate dependency list
```

`WINDOWS_HOME=auto` is the default. Auto-detection is enabled only under WSL when
installing into the current user's actual home. Empty `WINDOWS_HOME` disables
Windows deployment. Never use `stow --restow */`: `komorebi`, `windows`, and
`scripts` are not home-directory Stow packages.

## Configuration coverage

| Package / source | Active destination and purpose |
| --- | --- |
| `bash`, `zsh`, `gitconfig` | Home shell startup, aliases, environment, and Git configuration |
| `linux` | Linux-only `.profile`, `.bash_aliases`, `.XmodMap`, GTK and Monaspace fontconfig preferences |
| `bin`, `local-bin` | Home helpers and `~/.local/bin`, including `delta-adaptive` |
| `nvim` | `~/.config/nvim`; matches the active plugin overrides, not removed or backup Lua files |
| `zellij` | `~/.config/zellij`; Tokyo Night Moon palette, locked-mode bindings, `Alt+t` for a new tab in normal/locked modes, pane-only `Alt+h`/`Alt+l` navigation in normal/locked/scroll modes, and saved layouts |
| `kitty`, `alacritty`, `starship`, `wezterm` | Linux/macOS terminal/prompt configurations; Kitty includes the Rustlings session |
| `gh`, `lazygit`, `fd`, `pgcli`, `glow`, `graphite`, `vite-plus` | Developer CLI preferences; authentication and database history remain local |
| `claude` | `~/.claude` settings and personal agents/commands/plugins |
| `omp` | `~/.omp/agent` preferences, LSP settings, personal instructions, extensions, and review skill |
| `homebrew` | Committed `Brewfile`, also linked as `~/Brewfile` |
| `aerospace`, `lazynpm` | macOS-only Stow packages |
| `komorebi` | Windows profile: manager JSON, AHK bindings, bar settings, and customized application rules |
| `windows/.wezterm.lua` | Windows-specific VS Code Dark palette, WSL/GPU settings, and AHK shortcut bridge |
| `windows/.config`, `windows/.glzr` | Whkd, GlazeWM, and Zebar settings with the referenced starter widgets |
| `windows/AppData` | Windows Terminal profiles/actions and PowerToys preferences/custom layouts |

Windows and non-Windows WezTerm configs are intentionally distinct: the Windows
file selects the installed WSL distribution and GPU. Other device-specific paths
and preferences are preserved rather than guessed; review them when moving to a
different machine.

## Deliberately local data

Do not collect credentials, OAuth hosts, private keys, database query history,
logs, session transcripts, caches, node_modules, browser profiles, game saves, or
application databases. In particular:

- GitHub `hosts.yml`, Claude credentials, OMP databases/secrets/sessions, and
  PowerToys Mouse Without Borders credentials stay outside version control.
- Zellij backups and duplicate Windows `*.pending.json` files are not active
  configurations and are not deployed.
- Generated Vite+/Cargo environment scripts belong to their installers. Startup
  files source them only if present; Vite+ and Cargo themselves remain optional.
- Blank/default-only Ghostty, Spacemacs, and WSL templates, telemetry identifiers,
  update-check timestamps, and browser/game/hardware application state are not
  configuration sources for this repository.
- `pgcli` history/log files are ignored even if an older local checkout still has
  them. Existing local data is not deleted by setup.

To add another maintained package, preserve its home-relative directory layout
and add it to `PACKAGES` (or the platform-specific selection) in `scripts/setup.py`.
Windows files belong under `windows/` using Windows-profile-relative paths. Keep
settings separate from secrets and generated state before adding either.
