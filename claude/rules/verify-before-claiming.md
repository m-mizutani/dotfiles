# Verify Before You Claim

The single most frequent failure across this account's sessions is stating something
as true — "safe to remove", "already works", "done", "verified", "no invariant was
weakened", "that's a rule violation" — on the strength of memory, convention, or a
partial check, and having it collapse the moment the real path is exercised (by the
user running a command, or an independent review). This rule puts verification BEFORE
the claim, not after the user's challenge.

## Before any factual claim, verify — then cite what you checked
- Before saying something is safe to remove/change, works, is done, is correct, or
  violates a rule: confirm it against the actual artifact FIRST — read the code, run
  the command, check the doc/source. "It sounds right / I recall / that's the usual
  convention" is NOT grounds.
- State the basis together with the claim ("read X", "ran Y, got Z") so the user can
  catch a bad basis before it propagates into files, specs, or diagrams.
- Answering a code / architecture / layering / behavior question from memory or
  general convention instead of reading the current code is prohibited. The most
  dangerous move is asserting "safe, from memory" (記憶で大丈夫) — that is exactly the
  one to stop and verify.
- Cite a rule's INTENT, not just its literal form, before calling something a
  violation; do not overstate a preference as a hard rule.

## Completeness = every site, not the first one
- A "safe to remove" / "done" / "this works" conclusion must be checked against EVERY
  call site, code path, and flow — not the first match found. Partial evidence is not
  evidence of completeness.
- When a defect is found, sweep it from EVERY artifact it reached (code, docs,
  diagrams, specs, other environments), not only where it was first raised.
- When the evidence already in hand lists several problems, address them all or
  triage them explicitly with the user; never fix the loudest one and declare victory
  while the rest (which you could see) remain.
- A partial success is still a failure: keep the successful items AND report the
  failure; collapsing "some failed" into "all failed" (or "some worked" into "done")
  is itself a bug.

## "Done" requires the real verification path to have actually run
- Proxies are NOT proof: exit code 0, "deployed", a green vet/lint, passing unit
  tests, or "the specific error stopped" do not establish that the system works or
  that its state matches its definition. "Migration succeeded" != "the DB matches the
  schema"; "deployed" != "works".
- Drive the real path the change was meant to fix: run the exact command the user
  will run; exercise the real user/operational flow end to end.
- If the project mandates a verification path (integration/DB tests with no skip
  switch, a second-opinion review, a security scan), it MUST have actually run before
  you say "done" — never report complete with the mandatory check explicitly unrun,
  and never substitute a lighter check for it.
- A blanket assurance ("all green", "no security invariant weakened") carries the
  same evidentiary bar as any other completion claim. Earn it by running the check,
  or do not make it.

## Treat a skeptical question as a demand for evidence
- When the user asks "this is fine to ignore, right?" or challenges a claim, that is a
  signal to verify and answer WITH EVIDENCE, not to reassure in words. If the user is
  repeatedly asking you to prove things, prior unverified "trust me" answers are why.
