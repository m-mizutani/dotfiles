# Verify Before You Claim

The single most frequent failure across this account's sessions is making a
consequential claim — "safe to remove", "already works", "done", "verified", "no
invariant was weakened", "that's a rule violation" — on the strength of memory,
convention, or a partial check, and having it contradicted as soon as the command or
flow is actually run (by the user running a command, or an independent review). This
rule puts verification BEFORE claims that could change the user's code, conclusions, or
decisions, not after the user's challenge.

**What this rule is NOT.** It does not require proving every low-impact statement or
adding extra passes. For a consequential claim, verify once by running the actual
command or flow, and reuse evidence already in hand. Do not append a separate "final
verification step" to every task, re-check work you have already checked, or spawn a
subagent to review your own output. Re-verification nobody asked for costs tokens and
produces no new evidence.

## Before a consequential claim, verify — then cite what you checked
- Before saying something is safe to remove/change, works, is done, is correct, or
  violates a rule: confirm it against the actual artifact FIRST — read the code, run
  the command, check the doc/source. "It sounds right / I recall / that's the usual
  convention" is NOT grounds.
- State the basis together with the claim ("read X", "ran Y, got Z") so the user can
  reject an incorrect basis before it is written into files, specs, or diagrams.
- For a low-impact statement that does not affect the user's code, conclusions, or
  decisions, do not interrupt the task merely to prove it. If uncertainty matters,
  state it briefly and continue.
- Answering a code / architecture / layering / behavior question from memory or
  general convention instead of reading the current code is prohibited. The case that
  causes the most damage is asserting "safe, from memory" (記憶で大丈夫) — that is
  exactly the one to stop and verify.
- Cite a rule's INTENT, not just its literal form, before calling something a
  violation; do not overstate a preference as a hard rule.

## Completeness = every site, not the first one
- A "safe to remove" / "done" / "this works" conclusion must be checked against EVERY
  call site, code path, and flow — not the first match found. Partial evidence is not
  evidence of completeness.
- When a defect is found, correct it in EVERY artifact it reached (code, docs,
  diagrams, specs, other environments), not only where it was first raised.
- When the evidence already in hand lists several problems, address them all or
  triage them explicitly with the user; never fix the most conspicuous one and report
  the task complete while the rest (which you could see) remain.
- When some items succeeded and others failed, keep the successful items AND report
  the failures. Reporting "some failed" as "all failed", or "some worked" as "done",
  is itself a defect.
- A number you report — "all N", a test count, a set of affected sites — is a claim
  like any other. Settle the scope and the counting method, enumerate once, and state
  the figure from that enumeration. A count produced under a different scope or
  classification is a different number — never carry it forward as if it still
  applied.

## "Done" requires the verification command or flow to have actually run
- Indirect indicators are NOT proof: exit code 0, "deployed", a passing vet/lint,
  passing unit tests, or "the specific error stopped" do not establish that the system
  works or that its state matches its definition. "Migration succeeded" != "the DB
  matches the schema"; "deployed" != "works".
- Run the command or flow the change was meant to fix: the exact command the user will
  run; the user-facing or operational flow, end to end.
- A project-mandated verification step (integration or DB tests without a skip
  switch, a second-opinion review, or a security scan) must have actually run
  before a completion claim. A lighter check does not establish the same result.
- A claim covering everything at once ("all green", "no security invariant weakened")
  requires the same evidence as any other completion claim. Run the check, or do not
  make the claim.

## Treat a skeptical question as a demand for evidence
- When the user asks "this is fine to ignore, right?" or challenges a claim, that is a
  signal to verify and answer WITH EVIDENCE, not to reassure in words. If the user is
  repeatedly asking you to prove things, prior unverified "trust me" answers are why.
