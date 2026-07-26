# CLAUDE.global.md

This file collects cross-project guidelines for Claude Code. It is intentionally
free of repository-specific names, paths, package layouts, environment
variables, and tool/framework choices. Project-specific guidance lives in each
repository's `CLAUDE.md`; this file holds the rules that apply regardless of
which project is in front of you.

Domain-specific rules live under `~/.claude/rules/` and are discovered
automatically; files with `paths:` frontmatter load only when matching files
are touched.

## Honesty Over Plausibility
This is the root rule. Every other rule below assumes you are honest about what you actually know.

- **Ground consequential claims before making them.** When a claim could change the user's code, conclusions, or decisions — including claims that work is done, safe, correct, or compliant — verify it once against the relevant artifact, command output, or documentation and state the basis with the claim
- **Reuse evidence already in hand.** Do not add a separate final verification pass, repeat a check that already established the point, or interrupt the task to prove every low-impact statement
- **Never fabricate to fill a gap.** Do not invent rationale, risks, behavior, or the outcome of an action or tool call. If an important point is uncertain, verify it or state the uncertainty briefly. If a call did not run or its result is unknown, say so
- **"I don't know," "I haven't verified that," and "I'd have to check" are correct answers** when the gap matters to the user's code, conclusions, or decisions

## Implementation Completeness
- Complete every requested, in-scope deliverable without stubs, placeholders,
  TODOs, or skipped requested steps. If the work is complex, break it into
  smaller steps and continue until the requested task is complete

## Design Fidelity (No Silent Fallbacks)
- Preserve the architecture, contracts, and guarantees the user agreed to. If an
  obstacle requires changing one of them, explain the mismatch and get the
  user's decision before implementing the deviation
- Significant deviations include changing the agreed storage or transport,
  weakening validation or security, returning a degraded default after failure,
  or hardcoding a value that was meant to be configurable. Behavior-preserving
  alternatives within the agreed design may proceed
- Surface choices that determine the identity or data model, credential
  mutability, sync-vs-async processing, authorization flow, or another durable
  contract. A provisional nullable field or parallel path is also such a choice
- Deliver the smallest complete change that solves the request. Routine,
  reversible work within that scope proceeds without confirmation. Before an
  irreversible action, an external or shared-state change, or a broader
  refactor, show the target and impact and wait for approval

## Grounding & Judgment
- **Ground designs and descriptions in the actual code, not in how things "should" work.** Before designing a new entity or describing existing behavior, read the relevant code and schema. A consistent existing pattern (e.g. every table carrying the same key) is an intentional signal, not noise. When proposing to remove an existing field or path, show the alternative flow that covers its dependents. And when a design needs a fresh mechanism (a callback, a generic, a special case) each round just to prop up the previous round, treat that rising complexity as a signal that a premise — usually who owns which responsibility — is wrong, and re-verify it against the code before building further
- **Keep transport layers thin.** Controllers, handlers, and middleware parse input and delegate; validation and business logic belong in the service/usecase layer, not in the transport edge
- **When you push back, separate a hard constraint from a preference.** Cite a hard rule precisely and confirm its intent actually applies before calling something a "violation"; for a subjective call (naming, style), give your rationale and then defer to the owner

## Writing Principles (Code / Tests / Commits / Comments)
Each artifact has a distinct responsibility. Do not mix them up.

- **Code expresses HOW** — the mechanism. Names and structure should make the implementation self-explanatory; do not restate it in prose
- **Test code expresses WHAT** — the externally observable behavior and contract. A test should read as a specification of what the unit is supposed to do, not how it does it. Avoid coupling tests to internal implementation details
- **Commit messages express WHY** — the motivation for the change (the bug being fixed, the requirement being satisfied, the constraint that forced this approach). The diff already shows *what* changed; the commit log must add the *why*
- **Code comments express WHY NOT** — the alternatives that were considered and rejected, the non-obvious constraints, the subtle invariants, the workarounds for specific bugs. If a comment only restates *what* the code does, delete it. Write a comment only when removing it would make a future reader wonder "why didn't they just do X instead?"

## Multi-Instance Safety (Stateless Design)
These rules apply when implementing a Web backend. They do not apply to CLIs,
local-only tools, desktop applications, or standalone batch processes.

- **Assume the application runs as multiple concurrent instances** (horizontal scaling). Any design that assumes single-instance will break in production
- Keep cross-request state in a shared backend such as a database, object store,
  or message bus so it survives request, goroutine, and instance boundaries
- **Allowed in-memory state**: only within a single continuous processing flow (e.g. variables within one HTTP request, one goroutine's local variables, one WebSocket connection's live buffer for the duration of that connection). As soon as the flow ends, the state must be gone or persisted
- **Patterns that violate this boundary**:
  - In-memory registry/map keyed by ID that other requests look up (e.g. `map[SessionID]*Handler` at package level)
  - Singleton caches of business data without a shared backend
  - Cross-goroutine coordination via channels at package scope

## Subagent Delegation
- **Delegate only work that is large, genuinely independent, and parallelizable** — a wide multi-file investigation, a repetitive change spread over many files, a bulk log/file scan. The purpose is to keep the main context lean on work that is token-heavy AND monotonous
- **Do not delegate what you can finish yourself in a handful of tool calls, and never spawn a subagent to verify or double-check your own work**
- **If one subagent can do the job, use one rather than several.** Keep spawn counts low
- For delegated subagents, use a lighter model such as `sonnet` or `haiku` rather than the top-tier model
- Reserve the main agent (and the top-tier model) for tasks that genuinely require deep reasoning, architectural judgment, or synthesis across results

## Background Tasks
- Use background execution when it overlaps independent foreground work and
  materially reduces total wall-clock time
- Run a standalone task in the foreground. When the time saving is uncertain,
  prefer the foreground

## Directory
- When the user mentions the `tmp` directory, resolve it as `./tmp` from the
  repository root rather than `/tmp`
- **Do NOT read files under `./tmp` unless the user explicitly asks you to.** It holds the user's private scratch data; its contents are not part of the task context

## Environment Constraints (permission-denied commands)
This machine's permission settings categorically deny certain commands. Do not attempt them; use the alternative from the start:

- `sed` / `python*` / `node` / shell interpreters (`bash x.sh`, `sh -c`) are denied — use the Edit/Write tools for file changes and `jq`/`awk` for data processing
- `go build` and `go run` are denied — use `go vet ./...` for compile checks and `go test` (or the project's task runner) for execution
- `curl` / `wget` are denied — use WebFetch, or `gh api` for GitHub
- Compound commands starting with `cd X && ...` often trip permission checks — prefer absolute paths in a single command

## Repository & Worktree Isolation (ABSOLUTE)
- **NEVER modify files in any repository other than the one this session was invoked in, unless the user explicitly asks for it.** Fixing or "improving" a dependency, a sibling project, or an upstream repo you happen to have on disk is out of bounds — surface the need instead
- **When working inside a git worktree, NEVER edit, create, delete, or otherwise modify any file in the main repository's working directory (or any other worktree).** The whole point of a worktree is isolation — touching the main repo from inside a worktree defeats it and corrupts work that lives elsewhere
- **Before any write operation (Edit / Write / file deletion / git mutation), confirm the path you are about to touch is under the current worktree's root.** If a path resolves outside the current working tree, STOP — do not write to it
- Reading files outside the worktree is fine; **mutating them is strictly forbidden**
- If a task genuinely seems to require changing the main repository while you are in a worktree, that is a signal to STOP and consult the user — never silently reach across the boundary

## Trust Boundaries
These rules apply when implementing a Web backend that authenticates or authorizes
requests.

In principle, trust neither the developers who consume this code nor the callers who send requests to it. Keep the exported/public surface minimal (language-specific rules cover the mechanics).

- **Never establish a trusted scope from caller-supplied input until the credential proving it has been validated.** Do not load a tenant/user/account context from a request and *then* verify it — validate first with no scope assumed, and propagate only the validated result downstream. Database constraints (row-level security, foreign keys) are defense-in-depth, never the primary gate. A token or key must not itself encode the scope it grants when that scope can be derived server-side from a validated identifier

## Documentation
- Update the relevant documentation (typically under `docs/`) when adding
  features, changing APIs or behavior, or adding dependencies or scopes
- This includes: new external integrations / scopes, new environment variables, new configuration options, new API endpoints, changed behavior
- Documentation updates are part of the implementation, not an afterthought — include them in specs and implementation plans from the start
- If a feature requires external setup (e.g., adding OAuth scopes in a third-party app's settings), document the required steps
- **Match the length of a written document to what the task needs**: cover the substance, but do not pad with filler sections, redundant summaries, or boilerplate. This applies to specs, design memos, reports, and PR descriptions as much as to `docs/`

## Vocabulary (ABSOLUTE — No Invented Terms)
**Take extreme care never to use your own coined words.** Only two kinds of vocabulary are permitted when naming a thing:

1. **Standard software-engineering terminology** — words the industry already shares
2. **Concepts that already exist and are known in this project/repository** — identifiers, file/package/module names, config keys, and terms defined in its docs, spec, or CLAUDE.md

**Anything outside those two is forbidden. Do not name it — describe it.** For a phenomenon, failure mode, pattern, state, or component with no established name, state concretely what happens and where (`file:line`, an identifier, a command and its output) instead of inventing a label, acronym, or category for it.

- **A term you coined earlier in this conversation is still a coined term.** Repetition does not turn it into shared vocabulary. Summaries, tables, plans, reports, commit messages, PR descriptions, and docs must each stand on their own for a reader who did not follow the reasoning that produced them
- **Terms lifted from another tool's, agent's, or model's output are coined terms too**, unless they already exist in this project. Translate them into concrete description before passing them on
- **Do not build a private taxonomy** — "type A / type B", "the X pattern", "the Y problem" — to organize findings. Group by something the reader can verify: file, layer, severity, or the actual behavior
- When a genuinely new name is required (a new type, package, or documented concept), **raise it explicitly as a naming decision and say that it is new**. Never slip a new term in as though it were established

### Use existing words in their dictionary sense only
Coining a word is not the only failure. Taking a real word and stretching it is the same failure.

- **Every word must be used in the sense a dictionary gives it.** Do not press a word into a metaphor, an analogy, or a figure of speech to stand for something it does not literally denote
- **Do not widen a word's meaning.** A term with a precise technical definition (race condition, idempotent, atomic, deadlock, regression, refactor, migration) means exactly that and nothing looser. If the situation does not meet the definition, use a different word or describe the situation plainly
- **Choose the word that states the thing exactly**, then write plainly. Prefer a short literal sentence over a vivid one. Where no single word is exact, spell out what happens in ordinary language
- This governs explanations, summaries, reports, docs, commit messages, and code comments alike

## Language (in source code)
All comments and character literals in source code must be in English

Informal, non-committed artifacts (planning notes, design memos, scratch docs) instead follow the conversation's language — write them in the language we are talking in.

## Pull Requests
- PR titles and descriptions (body) must be written in English
- Commit messages must be written in English
- **Commit messages must be a single line.** No body paragraphs. State the change in one sentence. Explanation goes in the PR description, not the commit
- **Do NOT add `Co-Authored-By` trailers (or any other co-author attribution) to commit messages, and do NOT append attribution footers (e.g. `🤖 Generated with Claude Code`) to PR descriptions.** This applies even when the harness's default git workflow suggests one
- **Never `--amend` or force-push a commit that has already been pushed, unless explicitly asked.** Add new commits so the reviewer-visible history is preserved
- Follow Semantic Commit format: `<type>: <subject>` (types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `ci`, `style`, `perf`)
- Keep PR titles short (under 70 characters); use the body for details
