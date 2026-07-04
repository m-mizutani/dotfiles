# Testing

## Best Practices
- ALWAYS write tests for ALL code you create. This is NON-NEGOTIABLE
- Writing code without tests is UNACCEPTABLE
- Use the standard Go testing package
- For repositories with multiple backends (e.g. memory + persistent), test both implementations when applicable
- Every function, method, and handler MUST have corresponding tests
- Tests must be written BEFORE declaring the task complete
- **Tests MUST NOT depend on real external domains or services** (no `example.com`, no live URLs) — use `httptest` servers or clearly fake hosts. Live-service integration tests are the one exception: gate them behind `TEST_`-prefixed environment variables (skip when unset), and when you write them, cover ALL methods of the client under test — a partial live test gives false confidence

## Conventions
- Test files should use `package {name}_test`. Do not use the same package name as the production code
- Test file naming convention: `xyz.go` → `xyz_test.go`. Other test file names (e.g., `xyz_e2e_test.go`) are not allowed
- Repository tests should run against every backend the repository supports (typically memory + persistent), via a shared helper
- Repository test best practices:
  - Always use random IDs (e.g., using `time.Now().UnixNano()`) to avoid test conflicts
  - Never use hardcoded IDs like `"msg-001"`, `"user-001"` — they cause failures when running in parallel
  - Always verify ALL fields of returned values, not just nil/existence
  - Compare expected values properly — don't just check that something exists, verify it matches what was saved
  - For timestamp comparisons, use tolerance (e.g., `< time.Second`) to account for storage precision
- Test skip policy:
  - **NEVER use `t.Skip()` for anything other than missing environment variables**
  - If a test requires infrastructure (like a database index), fix the infrastructure, don't skip the test
  - If a feature is not implemented, write the code, don't skip the test
  - The only acceptable skip pattern: checking for missing environment variables at the beginning of a test

## Test File Checklist (use this EVERY time)
Before creating or modifying tests:
1. ✓ Is there a corresponding source file for this test file?
2. ✓ Does the test file name match exactly? (`xyz.go` → `xyz_test.go`)
3. ✓ Are all tests for a source file in ONE test file?
4. ✓ No standalone feature/e2e/integration test files?
5. ✓ For repository tests: placed at the repository package's top level, NOT inside backend-specific subdirectories?
