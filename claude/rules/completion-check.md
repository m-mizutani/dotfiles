# Completion Check

Before declaring a task complete:

- Run the project's verification commands (format, vet/lint, test, and any others
  the project defines) once and require them to pass. Language- and
  framework-specific rules name the commands for their own ecosystem
- When something in the environment prevents a command from running, first try the
  available remedy: start the dependency, adjust the host, or request permission.
  Report the task as unverified if the command still cannot run
- When changing scripts, migrations, deployment configuration, or task targets,
  run the operational flow end to end; unit tests are not a substitute
- When changing features, APIs, behavior, configuration, dependencies, scopes,
  or environment variables, confirm that the relevant documentation is current
- After creating or updating a PR, check its CI status and address failures
  before reporting completion. Treat a failure as a flaky test only after the same
  check passes when run locally
- Reuse the result of a verification command that already passed. Completion does
  not require an additional self-review or a second run of the same check
