# Project guidance

This is the `tspm` Flutter app. Keep the existing counter app working while product requirements are added.

## Use the engineering kit

- Project-local skills are in `.agents/skills/`. Invoke a workflow with its Codex skill name, such as `$setup-flutter-project`, `$grill`, `$flutter-plan-change`, `$flutter-implement`, or `$flutter-verify`.
- Read `.agents/skills/project-conventions/SKILL.md` when matching the app's current stack, and `.agents/skills/flutter-core-architecture/SKILL.md` before adding shared architecture.
- Project facts and decisions belong in `docs/agents/project.md`; update it when the actual stack or commands change.
- For TSPM product work, read the confirmed product plan linked from `docs/agents/project.md`. Use the draft vision for background; the confirmed plan controls release scope and acceptance criteria. Keep estimates, observations, and inferred trends distinct.
- For substantial work that splits cleanly, use the project Codex agents described in `docs/agents/agent-routing.md`. The selected task model remains the coordinator; delegate only a bounded part with clear inputs and file ownership.
- Kit templates are in `.agents/template/`. These are a local snapshot; edit project files, not copied templates, unless intentionally changing the kit snapshot.

## Current app conventions

- Package: `tspm`; Android application ID: `com.example.tspm`.
- The current app is a single counter screen. Preserve its behavior unless a product requirement replaces it.
- Match the dependencies and patterns already used. The kit baseline is installed; add future packages when a product capability needs them rather than following a checklist blindly.
- Put feature code under `lib/features/<feature>/` and share code through `lib/core/` as the app grows. Avoid speculative layers and cross-feature imports.
- Prefer `const`, explicit types, accessible controls, and adaptive layouts. Centralize repeated theme values and user-facing strings once they become shared.
- Keep secrets out of source control. Use secure storage for sensitive device data; never disable TLS validation.

## Commands

- Dependencies: `flutter pub get`
- Format: `dart format .`
- Analyze: `flutter analyze`
- Tests: `flutter test`

Run the checks relevant to a change and report what was run. Do not claim an unrun check passed.

## Project configuration and Sprint 1

- Read `docs/agents/project.md` for the actual stack, verification baseline and document pointers.
- Sprint 1 criteria live in `docs/specs/tspm-sprint-1.md`; its confirmed scope controls this increment.
- `CLAUDE.md` and `AGENTS.md` carry the same conventions; keep them in sync.

## Architecture

- Use `lib/core/router/exports.dart` for runtime imports. Match the existing BLoC event/state parts.
- Keep navigation, dialogs, snackbars and `BuildContext` out of BLoCs; emit state and react in the UI.
- Use private `StatelessWidget` classes to split complex layouts. Keep font sizes unscaled for OS text scaling.
- Read the Architecture table before writing serialization or repository contracts; planned conventions are marked separately from implemented behavior.
- Preserve missing optional health values as unknown. Never replace corrupt or unsupported stored data with defaults.

## Kit workflows

- `/fk-plan`: settle scope and a proposal or spec; Sprint 1 next uses `$flutter-plan-change`.
- `/fk-sprint`: plan, verify or close an increment.
- `/fk-build`: implement and verify an agreed ticket or spec.
- `/fk-feedback`: classify feedback; `/fk-release`: verify release readiness.
- `/fk-setup`: configure this project; it does not implement Sprint 1.

## Memory and verification

- Project memory lives in `docs/vault/`; preserve existing notes. Read `index.md` and `memory.md` when present; `$project-memory` owns their maintenance.
- Keep current sprint criteria and feedback in `docs/specs/` while the issue tracker is `none`.
- `$flutter-verify` owns the verification ladder. Name the checks actually run and distinguish pre-existing failures from new ones.
