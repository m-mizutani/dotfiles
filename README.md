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

The setup script manages `~/.codex/config.toml` from `codex/config.toml` and
`~/.codex/AGENTS.md` from `codex/AGENTS.md`. Use `--force` once when replacing
an existing unmanaged Codex file.

## Agent skills

Claude Code loads the managed skills from `~/.claude/skills`. Codex loads the
same managed set from `~/.agents/skills`; start a new Codex session after the
first setup or after changing a skill.

`difit` and `open-mo` use the same source directory for both agents.
`herdr-tab-name` and the remaining skills have Codex-specific versions under
`codex/skills`, because their Claude Code versions depend on Claude-only tools
or storage.

For skills that create an Artifact in Claude Code, the Codex version creates a
Markdown file under `.spec/`, opens it with `mo`, and receives decisions in the
conversation instead of through an Artifact page.

## Claude Code plugins

`setup.py` links each plugin under `claude/plugins` into `~/.claude/skills`,
where Claude Code loads it as `<name>@skills-dir` without a marketplace.

`idle-compact` compacts the conversation once after the main conversation has
been idle for 50 minutes, while the 1-hour prompt cache is still warm, so the
next turn starts from a small context instead of re-caching the whole one. A
new message, `/compact`, or the end of the session cancels the pending
compaction. A timer that fires 58 minutes or more after the last turn (for
example after the Mac slept) does nothing, because the cache may already be
cold. When the timer is set, the conversation shows the planned time; after
the compaction, it shows the cache hit rate of the summary call.

`compact-instructions` adds instructions to every compaction (`/compact`, auto
compaction, `idle-compact`, and subagents). The summary must keep the user's
decisions and corrections with their own words, the content of pasted material
such as emails and screenshots, and the location of each document the work
depends on, and it must carry these forward from an earlier summary. Text typed
after `/compact` is kept and comes first.

The plugins use function hooks, which are early access and need
`CLAUDE_CODE_ENABLE_FUNCTION_HOOKS=1`; `claude/settings.json` sets it. Run the
plugin tests with:

```sh
claude plugin validate claude/plugins/idle-compact
CLAUDE_CODE_ENABLE_FUNCTION_HOOKS=1 claude plugin test claude/plugins/idle-compact
claude plugin validate claude/plugins/compact-instructions
CLAUDE_CODE_ENABLE_FUNCTION_HOOKS=1 claude plugin test claude/plugins/compact-instructions
```
