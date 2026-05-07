# CLAUDE.global.md

This file collects cross-project guidelines for Claude Code. It is intentionally
free of repository-specific names, paths, package layouts, environment
variables, and tool/framework choices. Project-specific guidance lives in each
repository's `CLAUDE.md`; this file holds the rules that apply regardless of
which project is in front of you.

Domain-specific rules live alongside this file under `~/.claude/rules/` and are
imported below:

@rules/go.md
@rules/frontend.md
@rules/testing.md
@rules/completion-check.md

## Implementation Completeness
- **NEVER leave incomplete implementations, TODOs, or placeholder code**
- **NEVER skip implementation because it's complex or lengthy**
- **ALWAYS complete the full implementation in one go**
- If a task seems too complex, break it down into smaller steps, but complete ALL steps
- Long code is acceptable — incomplete code is NOT

## Multi-Instance Safety (Stateless Design)
- **Assume the application runs as multiple concurrent instances** (horizontal scaling). Any design that assumes single-instance will break in production
- **NEVER hold cross-request state in process memory.** State that must survive across separate requests, goroutines that originated elsewhere, or instance boundaries MUST be persisted to a shared backend (database / object store / message bus)
- **Allowed in-memory state**: only within a single continuous processing flow (e.g. variables within one HTTP request, one goroutine's local variables, one WebSocket connection's live buffer for the duration of that connection). As soon as the flow ends, the state must be gone or persisted
- **Forbidden patterns**:
  - In-memory registry/map keyed by ID that other requests look up (e.g. `map[SessionID]*Handler` at package level)
  - Singleton caches of business data without a shared backend
  - Cross-goroutine coordination via channels at package scope

## Directory
- When the user mentions the `tmp` directory, you SHOULD NOT see `/tmp`. Check `./tmp` from the repository root

## Exposure Policy
In principle, do not trust developers who use this code from outside.

- Do not export unnecessary methods, structs, and variables
- Assume that exposed items will be changed. Never expose fields that would be problematic if changed
- Use language-appropriate test-only exposure (e.g. Go's `export_test.go`) for items needed only for testing

## Documentation
- **When adding new features, changing APIs, or adding new dependencies/scopes, ALWAYS update the relevant documentation** (typically the `docs/` directory)
- This includes: new external integrations / scopes, new environment variables, new configuration options, new API endpoints, changed behavior
- Documentation updates are part of the implementation, not an afterthought — include them in specs and implementation plans from the start
- If a feature requires external setup (e.g., adding OAuth scopes in a third-party app's settings), document the required steps

## Language (in source code)
All comments and character literals in source code must be in English

## Pull Requests
- PR titles and descriptions (body) must be written in English
- Commit messages must be written in English
- **Commit messages must be a single line.** No body paragraphs. State the change in one sentence. Explanation goes in the PR description, not the commit
- Follow Semantic Commit format: `<type>: <subject>` (types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `ci`, `style`, `perf`)
- Keep PR titles short (under 70 characters); use the body for details
