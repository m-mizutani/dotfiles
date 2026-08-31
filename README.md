# dotfiles

## Setup

Run the setup script from the repository root to create the managed symlinks.

```sh
python3 setup.py
```

Use `--dry-run` to inspect the changes without modifying the home directory.

```sh
python3 setup.py --dry-run
```

Use `--force` only when an existing destination should be replaced.

```sh
python3 setup.py --force
```

The setup script manages `~/.codex/config.toml` from `codex/config.toml`. Use
`--force` once when replacing an existing unmanaged Codex configuration file.

## Agent skills

Claude Code loads the managed skills from `~/.claude/skills`. Codex loads the
same managed set from `~/.agents/skills`; start a new Codex session after the
first setup or after changing a skill.

`difit`, `herdr-tab-name`, and `open-mo` use the same source directory for both
agents. The remaining skills have Codex-specific versions under
`codex/skills`, because their Claude Code versions depend on Claude-only tools
or storage.

For skills that create an Artifact in Claude Code, the Codex version creates a
Markdown file under `.spec/`, opens it with `mo`, and receives decisions in the
conversation instead of through an Artifact page.
