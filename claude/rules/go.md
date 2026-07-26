---
paths:
  - "**/*.go"
  - "**/go.mod"
---

# Go

## Default Tooling
When the project has no existing code to follow, and no explicit instruction dictates otherwise, default to these libraries:

- **Error handling**: `github.com/m-mizutani/goerr` — see the Error Handling section below
- **Test suite / assertions**: `github.com/m-mizutani/gt`
- **Logging masking (PII / secret redaction)**: `github.com/m-mizutani/masq`

If the project already standardizes on a different library (existing imports, `go.mod`, or an explicit project rule), follow the project's choice instead — these are only the fallback defaults.

## Constructors & Options
- Initialize components with `New()` + the Functional Option Pattern
- **Required parameters go in `New()`'s signature; only optional ones go through `WithX()` options.** A required value hidden behind an option is a design error — the compiler can no longer enforce it

## Module Versions
- **Do not run `go get ...@latest` blindly.** It resolves to the latest version *within the major you named*; check whether a newer major (`/v2`, `/v3`, …) exists and choose the intended major explicitly

## Error Handling
- Use `github.com/m-mizutani/goerr/v2` for error handling
- Must wrap errors with `goerr.Wrap` to maintain error context
- **Always propagate the variables needed to debug the failure via `goerr.V`** (key IDs, sizes, states, the offending input shape). An error without the context to diagnose it is half an error
  - **BUT never attach PII or secrets via `goerr.V` blindly.** Whether attaching raw values is acceptable depends on whether this is an internal-only tool or an externally-facing one (where the error may surface to users or third parties / be logged where others can read it). Judge this carefully per project; when in doubt, attach an identifier or a masked form (see `masq`) rather than the raw value
- Propagate operation failures to the caller with `goerr.Wrap` or return them
  directly, including from GraphQL resolvers and partial-success paths. A
  default or empty result with a nil error incorrectly hides the failure. In a
  batch, preserving successful items and reporting failed items are independent
  duties
- Use `errors.Is(err, targetErr)` or `errors.As(err, &target)` for error
  discrimination; error message parsing with `strings.Contains` is not a stable
  contract
- Error discrimination must be done by error types, not by parsing error messages
- Route non-fatal errors that require neither rollback nor propagation through
  the project's standard non-fatal error handler, which typically logs and
  reports to the error tracker

## Logging
- **Never call `slog.Info()`, `slog.Error()`, `slog.Debug()`, `slog.Warn()` or other global slog logger functions directly.** Always obtain a context-scoped logger from the project's logging helper
- Attribute constructors (`slog.String()`, `slog.Any()`, `slog.Int64()`, etc.) are fine — use them as-is

## Resource Cleanup
- Close `io.Closer` resources through the project's nil-safe `Close` helper so
  nil receivers and close errors are handled

## Background Goroutines
- Background goroutines launch via the project's async-dispatch helper (panic recovery + logger context propagation + error reporting), never raw `go func(){...}()`
- Tests that exercise async tails must wait deterministically (e.g. via the helper's `Wait()` primitive). Do not rely on `time.Sleep`

## Code Visibility
- Do not export methods, structs, or variables that outside consumers do not need. Assume anything exported will be depended on and changed
- **Prefer unexporting over an `internal/` package.** Reach for `internal/` only when the boundary must span packages
- Use `export_test.go` to expose items needed only for testing
- Keep default values at the caller boundary rather than in internal or private
  functions
  - Default values should be controlled at the caller's level (e.g., CLI flags, configuration)
  - Internal functions should receive all necessary parameters from their callers
  - This ensures configurability and avoids hidden magic values
- Use `os.LookupEnv` instead of `os.Getenv` whenever "unset" and "empty" must be distinguished

## Testing
- Write tests before implementation and cover every new function, method, and
  handler
- Use the standard Go testing package with `github.com/m-mizutani/gt` for
  assertions
- Keep tests independent of real external domains and services. Use `httptest`
  servers or clearly fake hosts. Live-service integration tests are the
  exception: gate them behind `TEST_`-prefixed environment variables and cover
  every method of the client they exercise
- Use `package {name}_test`, and keep all tests for `xyz.go` in `xyz_test.go`
  rather than separate feature, e2e, or integration-suffixed files
- Keep repository tests at the repository package's top level rather than in a
  backend-specific subdirectory
- Run repository tests against every supported backend through a shared helper
- Give repository fixtures random IDs, compare every returned field with its
  expected value, and use a tolerance for timestamps when storage precision can
  differ
- Use `t.Skip()` only when a required environment variable for an integration
  test is absent. Repair missing infrastructure and implement missing behavior
  instead of skipping those cases

## Verification
- Run `go fmt ./...` and `go vet ./...`
- Run the project's complete Go test suite (`go test ./...` or its wrapper)
- Run `golangci-lint run ./...` and `gosec -exclude-generated -quiet ./...` when
  the project uses them
- Use `go vet`, rather than `go build`, as the compile check in this environment
