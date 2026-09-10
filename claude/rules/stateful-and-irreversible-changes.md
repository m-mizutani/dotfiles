# Operating on Stateful Systems & Irreversible Changes

These rules govern any action that touches persistent or shared state — databases,
migrations, deployed environments, files you overwrite or delete, external services.
They exist because a wrong action here is not a failed compile you can retry; it can
destroy data that cannot be recovered.

## The root failure to avoid
Treating a failure as "an error to silence" instead of "a signal that the system's
actual state differs from its intended state" — and then closing that difference with
an irreversible, broadly-scoped action whose safety you inferred from the current
condition of the environment in front of you, rather than from a verified
understanding of the correct end state and of every environment the action can reach.

Every rule below states one part of not doing that. When a single rule appears
satisfied but the sentence above is still violated, you have not complied.

## Reconcile to the intended state; do not silence the error
- A failure means actual state != intended state. The task is to eliminate *every*
  difference between them, not to make the specific error message stop.
- Before changing anything, establish three things explicitly: (1) the true current
  state, (2) the intended state (the source of truth), (3) the complete set of
  differences between them. Act on (3), not on the symptom.
- A change that removes the error or makes CI pass while the two states still differ
  is worse than no change: it hides the real defect and consumes a full deploy and
  verify cycle before the next known-but-unaddressed difference appears.

## Enumerate the full gap from the evidence before acting
- When the diagnostic evidence already in hand lists several discrepancies (a diff,
  a batch of skipped or failed items, multiple errors in one log), address the
  entire set — or explicitly triage it with the user — before acting.
- Do not address only the first or most conspicuous item and ship a partial fix. The
  remaining items will fail again on the next cycle, and you could have predicted
  every one of them from the same evidence you already read.

## Verify the end state by running the actual command or flow
- "Exited 0", "the error is gone", "deployed", "migration succeeded", and "tests
  pass" are NOT proof the system is correct. Each is an indirect indicator, and each
  can be true while the system is still incorrect.
- Confirm correctness by running the operational or user-facing flow the change was
  supposed to fix. This matters most right after anything that crosses an environment
  boundary: "deployed" != "works"; "applied" != "the state now matches the
  definition".

## Irreversibility is a first-class constraint
- Before proposing OR building any operation that destroys or irreversibly modifies
  persistent state (drop, delete, truncate, overwrite, in-place data transform,
  force-push), establish first: is it reversible? what is lost if it is wrong? is
  there a backup or undo?
- If the action is irreversible and the loss would be unrecoverable, STOP and make
  it an explicit human decision with the risk stated plainly. Never proceed on the
  basis that the current target happens to be empty, a test environment, or
  disposable.

## Reason about every environment the mechanism can reach, not the one in front of you
- Any mechanism placed in a shared or automated execution path — a migration, a
  startup step, a deploy hook, a cron job, a script others run — will execute against
  *every* environment it is configured into, including production holding real,
  irreplaceable data.
- Design and restrict such a mechanism for the environment where a mistake costs the
  most. "This environment is empty / a test environment" must never permit behavior
  that will also run, unchanged, against one that holds data.

## A default refusal is a decision to escalate, not an obstacle to automate around
- When a tool or design refuses an action by default (a safety switch left off, a
  destructive change it declines to auto-apply, a required-approval step, a
  fail-closed check), that refusal is protecting a decision that belongs to a human.
- State the decision to the user ("there is an unhandled destructive or ambiguous
  change; how should we handle it?") rather than writing automation that performs the
  action the refusal was preventing. Adding a retry with a force flag, or code that
  repairs the state automatically, re-creates the exact risk the default existed to
  prevent.

## Configuring a DB, tool, or service: verify against current docs, never guess
- Before setting ANY configuration touching a database, migration tool, cloud
  service, or library — a flag, a default, a mode, a permission, a connection
  parameter, a version-specific behavior — CONFIRM it against that tool's official
  documentation for the version actually in use (or the pinned version's source /
  CHANGELOG when available). Do not rely on memory, on analogy to another tool, or on
  "it's probably the default".
- A guessed configuration value is a fabrication (see Honesty Over Plausibility): if
  you cannot confirm it, say so and read the documentation — never ship the guess.
- Make the check specific to the exact VERSION in use. Defaults, flags, and behaviors
  change between releases; confirm the behavior for the version the project depends
  on, not "the tool in general".
- This is strictest for anything configuring persistent state or a
  deployed/production environment, where a wrong setting cannot simply be retried. When
  the correct setting is not verifiable from docs/source, STOP and ask — do not
  proceed on an assumption.
