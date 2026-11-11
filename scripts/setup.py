#!/usr/bin/env python3
"""Back up conflicts, deploy Stow packages, and check/capture Windows copies."""

import argparse
from datetime import datetime
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import uuid

ROOT = Path(__file__).resolve().parent.parent
PACKAGES = (
    "alacritty", "bash", "bin", "claude", "fd", "gh", "gitconfig", "glow",
    "graphite", "homebrew", "kitty", "lazygit", "local-bin", "nvim", "omp",
    "pgcli", "starship", "vite-plus", "wezterm", "zsh",
)
KOMOREBI_FILES = ("komorebi.json", "komorebi.ahk", "komorebi.bar.json", "applications.json")
IGNORES = (
    r"(^|/)(node_modules|__pycache__|cache|sessions|blobs|predict|terminal-sessions|custom-session-files)(/|$)",
    r"\.bak(\..*)?$", r"\.db(-shm|-wal)?$",
    r"(^|/)(history|log|hosts\.yml|secret-placeholder\.key|last-changelog-version)$",
)


def git(*args):
    return subprocess.check_output(["git", "-C", str(ROOT), *args])


def package_files(packages):
    paths = git("ls-files", "-z", "--cached", "--others", "--exclude-standard", "--", *packages)
    return [ROOT / p.decode() for p in paths.split(b"\0") if p
            and (ROOT / p.decode()).is_file()
            and not any(re.search(pattern, p.decode()) for pattern in IGNORES)]


def linked(source, destination):
    return destination.exists() and destination.resolve() == source.resolve()


def same_contents(source, destination):
    return destination.is_file() and source.read_bytes() == destination.read_bytes()


def windows_home(value, target):
    if value != "auto":
        return Path(value).expanduser().absolute() if value else None
    if target != Path.home().resolve() or not os.environ.get("WSL_DISTRO_NAME"):
        return None
    profile = subprocess.check_output([
        "powershell.exe", "-NoProfile", "-NonInteractive", "-Command", "$env:USERPROFILE",
    ], text=True).strip()
    return Path(subprocess.check_output(["wslpath", "-u", profile], text=True).strip())


def windows_files(home):
    if home is None:
        return []
    return [(source, home / source.relative_to(ROOT / "windows"))
            for source in package_files(["windows"])] + [
        (ROOT / "komorebi" / name, home / name) for name in KOMOREBI_FILES
    ]


def preflight(destinations, roots, directory):
    for destination in destinations:
        if destination != directory and destination.is_dir():
            raise SystemExit(f"Refusing to replace a directory with a file: {destination}")
        for parent in destination.parents:
            if parent in roots:
                break
            if os.path.lexists(parent) and not parent.is_dir():
                raise SystemExit(f"Not a directory: {parent}")


def backup(destination, root, backup_root, move):
    if not os.path.lexists(destination):
        return
    saved = backup_root / destination.relative_to(root)
    saved.parent.mkdir(parents=True, exist_ok=True)
    if move:
        shutil.move(str(destination), saved)
    else:
        shutil.copy2(destination, saved)
    print(f"Backed up {destination} -> {saved}")


def stow(action, target, packages):
    subprocess.run([
        "stow", "--dir", str(ROOT), "--target", str(target), "--no-folding",
        *[f"--ignore={pattern}" for pattern in IGNORES], action, *packages,
    ], check=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=("link", "check", "capture-windows", "delete"))
    parser.add_argument("--target", type=Path, default=Path.home())
    parser.add_argument("--windows-home", default="auto", help="WSL auto-detection; empty disables Windows copies")
    args = parser.parse_args()
    target = args.target.expanduser().resolve()
    win_home = windows_home(args.windows_home, target)
    packages = (*PACKAGES, *(('aerospace', 'lazynpm') if sys.platform == 'darwin' else ('linux',)))
    linux = [(source, target / Path(*source.relative_to(ROOT).parts[1:]))
             for source in package_files(packages)]
    zellij = (ROOT / "zellij/.config/zellij", target / ".config/zellij")
    copies = windows_files(win_home)
    if args.action == "capture-windows":
        if win_home is None:
            raise SystemExit("No Windows home; set WINDOWS_HOME=/mnt/c/Users/<name>.")
        changed = [(source, live) for source, live in copies if not same_contents(source, live)]
        for source, live in changed:
            if not live.is_file():
                raise SystemExit(f"Missing Windows configuration: {live}")
            if git("status", "--porcelain", "--", str(source.relative_to(ROOT))).strip():
                raise SystemExit(f"Commit or save repository edits before capturing: {source}")
        for source, live in changed:
            shutil.copyfile(live, source)
            print(f"Captured {live} -> {source}")
        print(f"Captured {len(changed)} Windows configuration changes; review and commit them.")
        return
    if args.action == "check":
        drift = [str(dst) for src, dst in [*linux, zellij] if not linked(src, dst)]
        drift += [str(dst) for src, dst in copies if not same_contents(src, dst)]
        for path in drift:
            print(f"Not synchronized: {path}")
        if drift:
            raise SystemExit(1)
        print(f"All {len(linux) + 1} Linux/macOS links and {len(copies)} Windows copies are synchronized.")
        return
    if args.action == "delete":
        stow("--delete", target, packages)
        if zellij[1].is_symlink() and linked(*zellij):
            zellij[1].unlink()
        print("Removed managed home-directory links; Windows copies and backups were retained.")
        return
    if shutil.which("stow") is None:
        raise SystemExit("GNU Stow is missing; run make deps first.")
    roots = {target, win_home}
    preflight([dst for _, dst in [*linux, zellij, *copies]], roots, zellij[1])
    backup_root = target / ".local/state/dotfiles/backups" / (datetime.now().strftime("%Y%m%d-%H%M%S-") + uuid.uuid4().hex[:8])
    target.mkdir(parents=True, exist_ok=True)
    for source, destination in linux:
        if not linked(source, destination):
            backup(destination, target, backup_root / "home", move=True)
    stow("--restow", target, packages)
    if not linked(*zellij):
        backup(zellij[1], target, backup_root / "home", move=True)
        zellij[1].parent.mkdir(parents=True, exist_ok=True)
        zellij[1].symlink_to(zellij[0], target_is_directory=True)
        print(f"Linked {zellij[1]} -> {zellij[0]}")
    for source, destination in copies:
        if not same_contents(source, destination):
            backup(destination, win_home, backup_root / "windows", move=False)
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(source, destination)
            print(f"Copied {source} -> {destination}")
    print("Configuration setup complete. Run make check to detect drift.")


if __name__ == "__main__":
    try:
        main()
    except (OSError, subprocess.CalledProcessError) as error:
        raise SystemExit(str(error)) from error
