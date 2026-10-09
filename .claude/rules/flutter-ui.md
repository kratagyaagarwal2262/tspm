---
description: TSPM Flutter UI conventions
paths:
  - "lib/features/**/view/**/*.dart"
  - "lib/features/**/widget/**/*.dart"
---

# UI

- Read `docs/agents/project.md` and the current sprint criteria before implementing a screen.
- Runtime imports use `package:tspm/core/router/exports.dart`.
- Reuse the existing Material theme, `AppDimensions`, `AppTextStyles` and shared strings. Use native Material controls where no shared component exists.
- Keep text sizes unscaled, touch targets accessible and forms reachable at 200% text scaling.
- Split complex layouts into private `StatelessWidget` classes.
- Use `BlocBuilder` for rendering and `BlocListener` for navigation or other UI effects. Check `context.mounted` after awaits.
- Register routes through `AppRoutes` and `AppRouter.onGenerateRoute`; use typed arguments when needed.
- Keep saved content and unsaved input visible during recoverable failures; provide a retry for the named operation.
- Follow `.agents/skills/flutter-core-architecture/SKILL.md` before adding shared UI.
