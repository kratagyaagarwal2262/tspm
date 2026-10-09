---
description: TSPM immutable models and protected local serialization
paths:
  - "lib/features/**/model/**/*.dart"
---

# Models

- Resolve serialization from `docs/agents/project.md`; no code generation is currently configured.
- Prefer immutable classes with final, explicitly typed fields and `Equatable` where value equality is needed.
- Use typed `fromJson` and `toJson` only for records that are actually serialized; prefer `Map<String, Object?>` with explicit boundary validation.
- Missing optional health values remain unknown; never default them to zero or an assumed activity level.
- Validate required fields and schema versions. Corrupt or unsupported data must produce a recoverable error, not a reset or overwrite.
- Persist canonical quantities with original entered units. Retain the starting observation instant, selected local day and original UTC offset.
- Keep draft and committed records separate; implement only record families required by the agreed sprint.
