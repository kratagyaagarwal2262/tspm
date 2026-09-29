# Project guidance

This is the `tspm` Flutter app. Keep the existing counter app working while product requirements are added.

## Use the engineering kit

- Project-local skills are in `.agents/skills/`. Invoke a workflow with its Codex skill name, such as `$setup-flutter-project`, `$grill`, `$flutter-plan-change`, `$flutter-implement`, or `$flutter-verify`.
- Read `.agents/skills/project-conventions/SKILL.md` when matching the app's current stack, and `.agents/skills/flutter-core-architecture/SKILL.md` before adding shared architecture.
- Project facts and decisions belong in `docs/agents/project.md`; update it when the actual stack or commands change.
- Kit templates are in `.agents/template/`. These are a local snapshot; edit project files, not copied templates, unless intentionally changing the kit snapshot.

## Current app conventions

- Package: `tspm`; Android application ID: `com.example.tspm`.
- The current app is a single counter screen. Preserve its behavior unless a product requirement replaces it.
- Match the dependencies and patterns already used. Add a package only when a product capability needs it; do not add unused kit defaults automatically.
- Put feature code under `lib/features/<feature>/` and share code through `lib/core/` as the app grows. Avoid speculative layers and cross-feature imports.
- Prefer `const`, explicit types, accessible controls, and adaptive layouts. Centralize repeated theme values and user-facing strings once they become shared.
- Keep secrets out of source control. Use secure storage for sensitive device data; never disable TLS validation.

## Commands

- Dependencies: `flutter pub get`
- Format: `dart format .`
- Analyze: `flutter analyze`
- Tests: `flutter test`

Run the checks relevant to a change and report what was run. Do not claim an unrun check passed.
