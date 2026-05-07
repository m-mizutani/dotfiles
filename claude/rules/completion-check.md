# Completion Check

Before declaring a task complete:

- **WRITE TESTS FIRST — This is MANDATORY, not optional**
- Run `go vet ./...` and `go fmt ./...` to format Go code
- Run `golangci-lint run ./...` if the project uses it
- Run `gosec -exclude-generated -quiet ./...` if the project uses it
- Run the project's full Go test suite (`go test ./...` or the wrapper the project specifies) — ALL tests must pass
- **NEVER run `go build` to verify code.** Use `go vet ./...` instead to check for compile errors
- **MANDATORY whenever any frontend file changes**:
  - Run the frontend unit-test command (typically `pnpm test`)
  - Run the frontend lint command (typically `pnpm lint`)
  - Both MUST pass before declaring the task complete. Do not skip lint even for "trivial" changes — IME / keyboard policies and similar invariants are enforced here, and silent regressions are exactly what lint is for
- Verify test coverage for your changes — EVERY new function/method MUST be tested
