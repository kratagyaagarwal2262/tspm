# ADR 0002: versioned baseline snapshot and explicit read failures

**Status:** accepted by owner on 2026-10-09. **Date:** 2026-10-07.
**Scope:** [Sprint 1 technical sketch](../specs/tspm-sprint-1-technical-plan.md),
criteria 4–9 and 12.

## Context

Drafts may contain incomplete or invalid text. Committed records must be valid,
but optional health/activity facts must remain unknown when omitted. Completion
must not produce a profile without its starting observation/goal, and retry must
not duplicate either. Unsupported or corrupt stored data must remain intact.

The project table's nullable read convention is planned, not implemented. Returning
null for both missing data and errors would incorrectly authorize first-run setup
over existing data.

## Alternatives and decision

| Choice | Decision and cost |
|---|---|
| Separate keys plus an independently written completion flag | Reject: multi-write interruption creates partial committed records. |
| One envelope with nullable draft/profile/goal/observation fields | Reject: permits invalid completed combinations. |
| Versioned envelope with draft/completed variants | Choose: a completed payload requires all three records; completion is its variant, not a separate flag. |
| Nullable repository reads where failure also returns null | Reject: absence and failure need different UI and overwrite behavior. |
| `Either<BaselineFailure, BaselineSnapshot?>` | Choose: Right(null) is verified absence; Left identifies operation/reason. Writes use Either as already planned. |

Wire v1 is `{schemaVersion: 1, kind: draft|completed, setupId, payload}`. Hand-written
checked serialization uses stable named tokens. Separate raw draft and validated
committed types preserve invalid editing text without weakening the saved-record
invariants. Unknown optional values are null; applicability has an explicit unknown
enum value. Maintenance and loss goals have different types.

Each committed record has stable role-derived ID, origin and UTC creation/update
times. Starting weight preserves canonical kg, original unit, original instant,
selected local day and offset. Profile retains canonical cm, original entry units
and preferred display units. Reported body-fat source never becomes a formula result.

The repository serializes mutations, rejects stale draft revisions and blocks a
late draft from replacing a completed snapshot. Native expected-value replace
protects read/replace conflicts. BLoC freezes one completion candidate including
IDs/timestamps, retries it unchanged and acknowledges success only after durable
replace succeeds. An uncertain completion retains its frozen candidate until
retry/reconciliation establishes the saved variant; it cannot go back to editing
over a potentially committed completion. A fresh process can load a valid
completed snapshot normally.

Decoder failure or unsupported version blocks writes; defaults are not recovery.
No migration is needed before v1 has users. The first future schema change must
include a preservation-tested migration; simply renaming a persisted enum token
or adding assumed defaults is not an acceptable migration.

## Consequences

This is a scoped exception to the kit's nullable-read failure convention. Update
the Architecture table when implementation lands; until then it remains proposed.
Models/repository stay in one `baseline` feature because Sprint 1 has no second
data consumer. Future logging/shared access may move stable record types/repository
into core without introducing cross-feature imports.

A snapshot rewrite is appropriate for the small baseline, not an agreement to
put every future log into one growing JSON document. No backup/import, history,
calculation, account or synchronization record family is scaffolded now.

Tests must prove invalid draft round-trip, unknown-versus-zero preservation, unit
and time provenance, strict corrupt/version rejection, failure-versus-absence,
old-or-new completion, stale writes and identical retry. Passing those tests is
required before accepting the implemented contract.
