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
- **Verification must actually run. An environmental obstacle (a missing daemon, a blocked socket, a sandbox limit) is something to work around — not an excuse to declare a task done unverified.** Try the workaround (start the dependency, adjust the host, request the permission) before reporting you could not verify. A clean `go vet` is not a passing test
- **Unit tests do not prove operational paths.** When the change touches scripts, migrations, or operational config (compose files, init scripts, task targets), exercise that path end-to-end locally before declaring done
- **Documentation is part of completion**: if the change adds/alters features, APIs, config, or env vars, verify the relevant docs were updated before reporting done
- **After creating or updating a PR, check its CI status** (e.g. `gh pr checks` / the check-pr flow) and fix failures before calling the task complete — "pushed" is not "done"
- **Do not attribute a CI failure to flakiness until you have reproduced a clean run locally.** Confirm your code is not the cause first
