# Completion Check

Before declaring a task complete:

- Run the relevant project verification gates once and require them to pass.
  Language- and framework-specific rules define their own gates
- When an environmental obstacle blocks a gate, first try the available remedy:
  start the dependency, adjust the host, or request permission. Report the task
  as unverified if the real gate still cannot run
- When changing scripts, migrations, deployment configuration, or task targets,
  exercise the operational path end to end; unit tests are not a substitute
- When changing features, APIs, behavior, configuration, dependencies, scopes,
  or environment variables, confirm that the relevant documentation is current
- After creating or updating a PR, check its CI status and address failures
  before reporting completion. Treat a failure as flaky only after reproducing a
  clean run through the relevant local path
- Reuse the result of a gate that already ran successfully. Completion does not
  require an additional self-review or a duplicate verification pass
