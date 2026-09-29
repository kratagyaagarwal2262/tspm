# Composing with the project's Codex skills

Write task documents that point to the project's existing skills instead of copying their rules.
This keeps the task specific while letting the skills remain the source of truth.

## Skills

Use Codex skill invocations (`$skill-name`) when a task step needs a reusable workflow. Name one
skill per instruction and state what inputs from the task document it should use.

| Skill | Use it for |
|---|---|
| `$flutter-core-architecture` | Shared widgets, themes, dialogs, networking, barrels, and fixtures |
| `$flutter-create-state-layer` | Creating or extending a BLoC |
| `$flutter-create-model` | New DTOs or JSON shapes |
| `$flutter-create-repository` | Wrapping endpoints |
| `$flutter-create-screen` | Building a screen from an approved design |
| `$flutter-write-tests` | Test coverage for logic and widgets |
| `$flutter-security-review` | Changes to storage, networking, secrets, or WebViews |

For a complete feature workflow, use `$flutter-create-feature-e2e` when an API contract exists or
`$flutter-create-screen-e2e` when the screen is being built before its backend. These workflows are
explicitly invoked by the user.

When a task document adds exact requirements or assertions, say which source wins if it differs
from a generated skill default.

## Project guidance

`AGENTS.md` is the repository-wide guidance. `docs/agents/project.md` records the project's actual
stack, integrations, commands, and verification constraints. Read those files when the current task
touches their subject.

Before relying on a shared component or API, inspect `lib/core/`; a skill describes conventions but
does not prove a particular component exists in this project.

## Verification

Use the project commands documented in `docs/agents/project.md`. Report the checks actually run and
distinguish code requirements from environmental limitations.
