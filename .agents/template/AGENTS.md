# Project guidance

This repository uses the Flutter Engineering Kit skills under `.agents/skills/`.

## Project facts

Read [docs/agents/project.md](docs/agents/project.md) for the stack, integrations, platforms, commands, and verification baseline. Update it when those facts change.

## Architecture

Read `$flutter-core-architecture` before creating or extending shared UI, constants, services, or other `lib/core/` infrastructure. Resolve the project's real stack with `$project-conventions` before generating feature code.

Features belong under `lib/features/<feature>/`; shared code belongs under `lib/core/`. A feature should not import another feature directly.

## Product and quality

- Clarify thin requirements before building; record settled acceptance criteria in `docs/specs/`.
- Keep secrets out of source control and sensitive values in platform secure storage.
- Preserve existing behavior unless an agreed requirement changes it.
- Use `$flutter-verify` when the user requests verification, and report the checks actually run.
