# Verify Before You Claim

Apply `CLAUDE.md`'s Verified Claims rules. The requirements below specify the
scope of evidence for completion and safety claims; they do not add another
review process or require repeating a check that already established the claim.

## Evidence and Scope

- Read the actual code, schema, test, output, or documentation before describing
  behavior. Memory and general conventions do not establish the current behavior.
- Before calling something a rule violation, check both the text and the rule's
  intended scope. Do not present a preference as a mandatory constraint.
- A claim about every affected call site, code path, or flow requires evidence
  covering that scope. The first matching file does not establish completeness.
- When a defect affects several artifacts or locations, address all affected
  locations in scope. If the available evidence lists several problems, resolve
  them or identify the remaining ones before reporting completion.
- Report successful and failed items separately. Do not describe partial success
  as complete success, or partial failure as complete failure.
- For counts, define the scope and enumerate it once. Do not reuse a count from a
  different scope or classification.

## Verification Results

- Match the check to the claim. A passing lint command or unit test does not prove
  an operational or user-facing flow works. Run that flow before claiming it works.
- Required checks must actually run. A lighter check does not replace a required
  integration test, security scan, or review. The user's later instructions control
  which workflows are authorized; do not run a rejected review or add a new one.
- If a check cannot run, identify what remains unverified. Do not report an
  unexecuted check or an assistant's assertion as evidence.
- When the user challenges a consequential claim, verify the disputed fact and
  answer with the evidence. Reuse evidence already obtained when it answers the
  challenge.
