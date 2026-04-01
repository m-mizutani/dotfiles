#!/usr/bin/env python3
"""Dotfiles setup script - creates symlinks from dotfiles repo to home directory."""

import os
import sys
from dataclasses import dataclass
from pathlib import Path

# --- Colors ---

class C:
    RESET = "\033[0m"
    BOLD = "\033[1m"
    DIM = "\033[2m"
    GREEN = "\033[32m"
    YELLOW = "\033[33m"
    RED = "\033[31m"
    CYAN = "\033[36m"
    BLUE = "\033[34m"


def icon_ok():
    return f"{C.GREEN}✓{C.RESET}"

def icon_skip():
    return f"{C.YELLOW}→{C.RESET}"

def icon_fail():
    return f"{C.RED}✗{C.RESET}"

def icon_new():
    return f"{C.GREEN}+{C.RESET}"

def icon_replace():
    return f"{C.YELLOW}↻{C.RESET}"


# --- Data Model ---

@dataclass
class Link:
    """A single symlink: src (relative to repo root) -> dst (absolute)."""
    src: str
    dst: str


@dataclass
class Group:
    """A named group of symlinks."""
    name: str
    links: list[Link]


# --- Configuration ---

HOME = Path.home()
REPO = Path(__file__).resolve().parent


def build_groups() -> list[Group]:
    return [
        Group("Fish Shell", [
            Link("config/fish/config.fish", f"{HOME}/.config/fish/config.fish"),
            Link("config/fish/functions/fish_title.fish", f"{HOME}/.config/fish/functions/fish_title.fish"),
            Link("config/fish/functions/wcd.fish", f"{HOME}/.config/fish/functions/wcd.fish"),
        ]),
        Group("Emacs", [
            Link("emacs.d/init.el", f"{HOME}/.emacs.d/init.el"),
        ]),
        Group("Hammerspoon", [
            Link("hammerspoon/init.lua", f"{HOME}/.hammerspoon/init.lua"),
        ]),
        Group("Terminal & Shell", [
            Link("tmux.conf", f"{HOME}/.tmux.conf"),
            Link("bashrc", f"{HOME}/.bashrc"),
            Link("hyper.js", f"{HOME}/.hyper.js"),
            Link("wezterm.lua", f"{HOME}/.wezterm.lua"),
        ]),
        Group("Git", [
            Link("gitconfig", f"{HOME}/.gitconfig"),
            Link("gitignore", f"{HOME}/.config/git/ignore"),
        ]),
        Group("Claude Code", [
            Link("claude/settings.json", f"{HOME}/.claude/settings.json"),
            Link("claude/sounds", f"{HOME}/.claude/sounds"),
            Link("claude/commands", f"{HOME}/.claude/commands"),
            Link("claude/statusline-command.sh", f"{HOME}/.claude/statusline-command.sh"),
            Link("claude/statusline.mjs", f"{HOME}/.claude/statusline.mjs"),
            Link("claude/skills/check-pr-comment", f"{HOME}/.claude/skills/check-pr-comment"),
            Link("claude/skills/dev", f"{HOME}/.claude/skills/dev"),
            Link("claude/skills/brainstorm", f"{HOME}/.claude/skills/brainstorm"),
        ]),
        Group("Ghostty", [
            Link("config/ghostty/config", f"{HOME}/.config/ghostty/config"),
        ]),
        Group("Bin", [
            Link("bin/gph", f"{HOME}/.local/bin/gph"),
        ]),
    ]


# --- Engine ---

@dataclass
class Stats:
    created: int = 0
    replaced: int = 0
    skipped: int = 0
    failed: int = 0


def remove_existing(dst: Path) -> None:
    """Remove an existing file, symlink, or directory at dst."""
    if dst.is_symlink() or dst.is_file():
        dst.unlink()
    elif dst.is_dir():
        import shutil
        shutil.rmtree(dst)


def create_symlink(link: Link, stats: Stats, dry_run: bool = False, force: bool = False) -> None:
    src = REPO / link.src
    dst = Path(link.dst)

    label = f"{C.DIM}{dst}{C.RESET}"

    if not src.exists():
        print(f"  {icon_fail()} {label}")
        print(f"       source not found: {src}")
        stats.failed += 1
        return

    # Already correctly linked
    if dst.is_symlink() and dst.resolve() == src.resolve():
        print(f"  {icon_skip()} {label} {C.DIM}(already linked){C.RESET}")
        stats.skipped += 1
        return

    # Something else exists at dst
    if dst.exists() or dst.is_symlink():
        if force:
            if dry_run:
                print(f"  {icon_replace()} {label} {C.DIM}(would replace){C.RESET}")
                stats.replaced += 1
                return
            remove_existing(dst)
            dst.parent.mkdir(parents=True, exist_ok=True)
            os.symlink(src, dst)
            print(f"  {icon_replace()} {label} {C.DIM}(replaced){C.RESET}")
            stats.replaced += 1
        else:
            print(f"  {icon_fail()} {label}")
            print(f"       already exists (not a symlink to repo, use -f to overwrite)")
            stats.failed += 1
        return

    if dry_run:
        print(f"  {icon_new()} {label} {C.DIM}(would create){C.RESET}")
        stats.created += 1
        return

    # Create parent directories
    dst.parent.mkdir(parents=True, exist_ok=True)

    os.symlink(src, dst)
    print(f"  {icon_new()} {label}")
    stats.created += 1


def run(dry_run: bool = False, force: bool = False) -> Stats:
    groups = build_groups()
    stats = Stats()

    flags = []
    if dry_run:
        flags.append(f"{C.YELLOW}DRY RUN{C.RESET}")
    if force:
        flags.append(f"{C.RED}FORCE{C.RESET}")
    if not flags:
        flags.append(f"{C.GREEN}LIVE{C.RESET}")
    mode = ", ".join(flags)

    print()
    print(f"{C.BOLD}Dotfiles Setup{C.RESET} [{mode}]")
    print(f"{C.DIM}repo: {REPO}{C.RESET}")
    print(f"{C.DIM}home: {HOME}{C.RESET}")
    print()

    for group in groups:
        print(f"{C.BOLD}{C.CYAN}{group.name}{C.RESET}")
        for link in group.links:
            create_symlink(link, stats, dry_run=dry_run, force=force)
        print()

    # Summary
    print(f"{C.BOLD}Summary{C.RESET}")
    parts = []
    if stats.created > 0:
        verb = "would create" if dry_run else "created"
        parts.append(f"{C.GREEN}{stats.created} {verb}{C.RESET}")
    if stats.replaced > 0:
        verb = "would replace" if dry_run else "replaced"
        parts.append(f"{C.YELLOW}{stats.replaced} {verb}{C.RESET}")
    if stats.skipped > 0:
        parts.append(f"{C.YELLOW}{stats.skipped} skipped{C.RESET}")
    if stats.failed > 0:
        parts.append(f"{C.RED}{stats.failed} failed{C.RESET}")
    if not parts:
        parts.append(f"{C.DIM}nothing to do{C.RESET}")
    print(f"  {', '.join(parts)}")
    print()

    return stats


def main() -> None:
    dry_run = "--dry-run" in sys.argv or "-n" in sys.argv
    force = "--force" in sys.argv or "-f" in sys.argv

    if "--help" in sys.argv or "-h" in sys.argv:
        print("Usage: setup.py [--dry-run|-n] [--force|-f]")
        print()
        print("  --dry-run, -n   Show what would be done without making changes")
        print("  --force, -f     Remove existing files/symlinks and re-create links")
        sys.exit(0)

    stats = run(dry_run=dry_run, force=force)

    if stats.failed > 0:
        sys.exit(1)


if __name__ == "__main__":
    main()
