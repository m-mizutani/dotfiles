# Go

## Error Handling
- Use `github.com/m-mizutani/goerr/v2` for error handling
- Must wrap errors with `goerr.Wrap` to maintain error context
- Add helpful variables with `goerr.V` for debugging
- **NEVER silently swallow errors** — returning a default/empty value while discarding the error (e.g., `return emptyResult, nil` in an `if err != nil` block) is strictly prohibited. Errors MUST always be propagated to the caller via `goerr.Wrap` or returned directly. This applies to ALL contexts including GraphQL resolvers — do not justify swallowing errors with "graceful degradation" or "it's just auxiliary data". If an operation fails, the caller must know about it
- **NEVER check error messages using `strings.Contains(err.Error(), ...)`**
- **ALWAYS use `errors.Is(err, targetErr)` or `errors.As(err, &target)` for error type checking**
- Error discrimination must be done by error types, not by parsing error messages
- **Non-fatal errors (errors that don't require rollback or propagation) MUST be funneled through the project's standard non-fatal error handler** (typically a small wrapper that logs + reports to the error tracker). Never use raw `logger.Error` or describe error handling as "log only"

## Logging
- **Never call `slog.Info()`, `slog.Error()`, `slog.Debug()`, `slog.Warn()` or other global slog logger functions directly.** Always obtain a context-scoped logger from the project's logging helper
- Attribute constructors (`slog.String()`, `slog.Any()`, `slog.Int64()`, etc.) are fine — use them as-is

## Resource Cleanup
- **ALWAYS use the project's nil-safe `Close` helper** to close `io.Closer` resources
- **NEVER use `_ = x.Close()` or bare `x.Close()`** — these silently drop errors and crash on nil receivers

## Background Goroutines
- Background goroutines launch via the project's async-dispatch helper (panic recovery + logger context propagation + error reporting), never raw `go func(){...}()`
- Tests that exercise async tails must wait deterministically (e.g. via the helper's `Wait()` primitive). Do not rely on `time.Sleep`

## Code Visibility
- Use `export_test.go` to expose items needed only for testing
- **NEVER place default values inside internal/private functions**
  - Default values should be controlled at the caller's level (e.g., CLI flags, configuration)
  - Internal functions should receive all necessary parameters from their callers
  - This ensures configurability and avoids hidden magic values
