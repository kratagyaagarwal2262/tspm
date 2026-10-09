---
description: TSPM BLoC events, states and handlers
paths:
  - "lib/features/**/bloc/**/*.dart"
---

# BLoC

- Match the existing triad: the BLoC imports the runtime barrel and owns event/state `part` directives.
- Use immutable, typed events and states; register handlers in the constructor.
- Constructor-inject real collaborators when needed; do not create speculative repository interfaces or fixture health records.
- Keep `BuildContext`, navigation and UI side effects outside the BLoC.
- Preserve optional unknown values and allow nullable fields to be cleared deliberately.
- Model operation progress and errors without discarding loaded content or unsaved answers.
- Claim save success only after persistence succeeds; Sprint 1 completion must resist duplicate taps and preserve answers on failure.
- Use installed `bloc_test` for meaningful state-seam tests when behavior is added.
