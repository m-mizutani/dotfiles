# Public Repositories: Never Write Internal Identifiers

These rules apply whenever the target repository is public — anything published
under the user's personal account or the open-source organizations they maintain
(for example repositories under `m-mizutani`, `secmon-lab`, `gollem-dev`). When
you are not sure whether the current repository is public, check it with
`gh repo view --json visibility,isPrivate` **before** writing anything that
leaves the machine.

## The rule (absolute)

**Never write a proper noun that originates inside the user's employer into a
public repository.** No exception for "it looks harmless", "it is only a commit
message", "it is just a comment", or "the term is probably already known".

Treat all of the following as forbidden:

- the employer's own name, its brand names, and its product or service names
- internal system, application, repository, database, table, dataset, and job names
- internal team, department, and role names; colleagues' names, handles, and email addresses
- internal jargon, abbreviations, and project code names — including any term obtained
  from an internal knowledge base, ontology server, chat workspace, wiki, or ticket system
- internal hostnames, domains, URLs, cloud project/account IDs, bucket names,
  chat channel names, document IDs, and ticket IDs
- customer, partner, and vendor names learned through work
- data samples, fixtures, logs, screenshots, or configuration copied from internal systems

## Where it applies

Everything directed at a public repository: source code and identifiers, code
comments, test fixtures and testdata, commit messages, branch names, PR titles
and bodies, issue titles and bodies, review and discussion comments, release
notes, documentation, `CLAUDE.md` and rule files stored in that repository, and
any file attached to those.

## How to comply

- When the change is motivated by something at work, state the technical need in
  generic terms ("a service that fans requests out to a downstream API") and never
  the internal setting that produced it
- Use neutral placeholders in examples: `example.com`, `my-service`, `alice` / `bob`,
  synthetic IDs
- Before `git commit`, `git push`, `gh pr create`, `gh issue create`, or posting any
  comment to a public repository, re-read the exact text being sent and strip anything
  whose origin is internal
- **If you cannot tell whether a term is public or internal, treat it as internal**:
  describe the thing instead of naming it. If a generic description is not enough to
  convey the point, ask the user before writing the term
- A term already present in that public repository's history is not automatically
  safe to reuse. If it reads as internal, raise it with the user rather than
  propagating it further
- This constraint never justifies inventing a substitute term. Follow the vocabulary
  rules: describe the thing in plain words instead of coining a codename for it
