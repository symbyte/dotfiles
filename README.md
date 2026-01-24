# Dotfiles

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Prerequisites

### Linux/WSL

1. **Install build-essential** (required for Homebrew to compile packages):

   ```bash
   sudo apt-get update && sudo apt-get install -y build-essential curl git
   ```

2. **Install Homebrew**:

   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

   After installation, add Homebrew to your PATH by following the instructions shown, or add this to your shell profile:

   ```bash
   eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
   ```

### macOS

Homebrew should work out of the box:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

## Installation

1. **Clone this repository**:

   ```bash
   git clone https://github.com/symbyte/dotfiles.git ~/dotfiles
   cd ~/dotfiles
   ```

2. **Install dependencies via Homebrew**:

   ```bash
   brew bundle --file=homebrew/Brewfile
   ```

   Note: On Linux, macOS-only casks (aerospace, alacritty, kitty, visual-studio-code) will be skipped automatically.

3. **Backup existing dotfiles** (if any):

   ```bash
   # Backup files that would conflict
   [ -f ~/.bashrc ] && mv ~/.bashrc ~/.bashrc.backup
   [ -f ~/.gitconfig ] && mv ~/.gitconfig ~/.gitconfig.backup
   ```

4. **Stow the dotfiles**:

   ```bash
   # Stow all packages
   make

   # Or stow specific packages
   stow --target=$HOME bash bin gitconfig nvim starship lazygit fd pgcli
   ```

## Packages

| Package     | Description                                             |
| ----------- | ------------------------------------------------------- |
| `bash`      | Bash configuration (.bashrc, .aliases, .env, .fzf.bash) |
| `bin`       | Personal scripts                                        |
| `gitconfig` | Git configuration                                       |
| `nvim`      | Neovim configuration                                    |
| `starship`  | Starship prompt configuration                           |
| `lazygit`   | Lazygit configuration                                   |
| `lazynpm`   | Lazynpm configuration                                   |
| `fd`        | fd (find alternative) configuration                     |
| `pgcli`     | PostgreSQL CLI configuration                            |
| `alacritty` | Alacritty terminal configuration (macOS)                |
| `kitty`     | Kitty terminal configuration (macOS)                    |
| `aerospace` | AeroSpace window manager configuration (macOS)          |
| `komorebi`  | Komorebi window manager configuration (Windows)         |

## Makefile Commands

- `make` or `make all` - Stow all packages
- `make delete` - Unstow all packages
- `make adopt` - Adopt existing files into stow packages
- `make add` - Run the add script

## Notes

- The `.bashrc` expects these tools to be installed: `starship`, `zoxide`, `fzf`, `nvim`
- If you use Go, install it separately and the PATH will be configured automatically
- For NVM (Node Version Manager), install it separately: <https://github.com/nvm-sh/nvm>
- Create `~/.env-local` for machine-specific environment variables

## Troubleshooting

### Stow conflicts

If stow reports conflicts, either:

- Backup/remove the conflicting files, or
- Use `stow --adopt` to adopt existing files into the dotfiles repo

### Missing commands after installation

Make sure Homebrew is in your PATH:

```bash
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"  # Linux
eval "$(/opt/homebrew/bin/brew shellenv)"                # macOS (Apple Silicon)
eval "$(/usr/local/bin/brew shellenv)"                   # macOS (Intel)
```
