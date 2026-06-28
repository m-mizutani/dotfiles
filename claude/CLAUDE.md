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
@rules/collaboration.md

## Implementation Completeness
- **NEVER leave incomplete implementations, TODOs, or placeholder code**
- **NEVER skip implementation because it's complex or lengthy**
- **ALWAYS complete the full implementation in one go**
- If a task seems too complex, break it down into smaller steps, but complete ALL steps
- Long code is acceptable — incomplete code is NOT

## Design Fidelity (No Silent Fallbacks)
- **NEVER introduce a fallback, workaround, or alternative path that deviates significantly from the original design or established policy without consulting the user first.** When the intended approach hits an obstacle (an API is missing, a constraint conflicts, a dependency behaves unexpectedly), STOP and discuss it — do not quietly substitute a different mechanism, relax a stated invariant, or downgrade the behavior
- Examples of forbidden silent deviations: swapping the agreed-upon storage/transport for an easier one, catching an error and returning a degraded default, disabling or loosening a validation/security rule to make something pass, hardcoding a value the design said should be configurable
- Minor, behavior-preserving fallbacks that stay within the original design's intent are fine. The rule targets changes that alter the architecture, contract, or guarantees the user agreed to
- When in doubt about whether a deviation is "significant," treat it as significant and ask

## Writing Principles (Code / Tests / Commits / Comments)
Each artifact has a distinct responsibility. Do not mix them up.

- **Code expresses HOW** — the mechanism. Names and structure should make the implementation self-explanatory; do not restate it in prose
- **Test code expresses WHAT** — the externally observable behavior and contract. A test should read as a specification of what the unit is supposed to do, not how it does it. Avoid coupling tests to internal implementation details
- **Commit messages express WHY** — the motivation for the change (the bug being fixed, the requirement being satisfied, the constraint that forced this approach). The diff already shows *what* changed; the commit log must add the *why*
- **Code comments express WHY NOT** — the alternatives that were considered and rejected, the non-obvious constraints, the subtle invariants, the workarounds for specific bugs. If a comment only restates *what* the code does, delete it. Write a comment only when removing it would make a future reader wonder "why didn't they just do X instead?"

## Multi-Instance Safety (Stateless Design)
- **Assume the application runs as multiple concurrent instances** (horizontal scaling). Any design that assumes single-instance will break in production
- **NEVER hold cross-request state in process memory.** State that must survive across separate requests, goroutines that originated elsewhere, or instance boundaries MUST be persisted to a shared backend (database / object store / message bus)
- **Allowed in-memory state**: only within a single continuous processing flow (e.g. variables within one HTTP request, one goroutine's local variables, one WebSocket connection's live buffer for the duration of that connection). As soon as the flow ends, the state must be gone or persisted
- **Forbidden patterns**:
  - In-memory registry/map keyed by ID that other requests look up (e.g. `map[SessionID]*Handler` at package level)
  - Singleton caches of business data without a shared backend
  - Cross-goroutine coordination via channels at package scope

## Subagent Delegation
- **Token-heavy but monotonous tasks (large-scale code search, repetitive code changes, log/file scanning, etc.) MUST in principle be delegated to subagents**, keeping the main context lean
- For these delegated subagents, use a lighter model such as `sonnet` or `haiku` rather than the top-tier model
- Reserve the main agent (and the top-tier model) for tasks that genuinely require deep reasoning, architectural judgment, or synthesis across results

## Directory
- When the user mentions the `tmp` directory, you SHOULD NOT see `/tmp`. Check `./tmp` from the repository root

## Git Worktree Isolation (ABSOLUTE)
- **When working inside a git worktree, NEVER edit, create, delete, or otherwise modify any file in the main repository's working directory (or any other worktree).** The whole point of a worktree is isolation — touching the main repo from inside a worktree defeats it and corrupts work that lives elsewhere
- **Before any write operation (Edit / Write / file deletion / git mutation), confirm the path you are about to touch is under the current worktree's root.** If a path resolves outside the current working tree, STOP — do not write to it
- Reading files outside the worktree is fine; **mutating them is strictly forbidden**
- If a task genuinely seems to require changing the main repository while you are in a worktree, that is a signal to STOP and consult the user — never silently reach across the boundary

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
- **Do NOT add `Co-Authored-By` trailers (or any other co-author attribution) to commit messages.** This applies even when the harness's default git workflow suggests one
- Follow Semantic Commit format: `<type>: <subject>` (types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `ci`, `style`, `perf`)
- Keep PR titles short (under 70 characters); use the body for details
