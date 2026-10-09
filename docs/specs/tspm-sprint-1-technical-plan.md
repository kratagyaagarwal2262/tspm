# Sprint 1 technical sketch: onboarding and recoverable baseline

**Status:** approved by owner on 2026-10-09; implementation in progress. **Plan date:** 2026-10-07.

Behavior source: [Sprint 1 criteria 1–14](tspm-sprint-1.md), refined by the
[confirmed blueprint](tspm-product-plan.md). Conventions:
[project configuration](../agents/project.md), [design language](../agents/design.md).
The `tspm_architect` supplied a read-only storage/state consultation; this sketch
integrates it with inspection of the actual app and installed Android plugin.

## 1. Grounded decisions

| Concern | Evidence and decision |
|---|---|
| State | `lib/features/counter/bloc/counter_bloc.dart` uses BLoC with event/state parts and Equatable. Retain that pattern. |
| Injection | Counter constructs its BLoC locally. Product page owns one repository and BLoC through constructor injection; no service locator. |
| Serialization | No persisted models exist. Use hand-written JSON with checked parsing and stable string tokens, not enum indexes or code generation. |
| Repository returns | The project table marks nullable reads as planned. They cannot distinguish absence from read failure. Use `Either<BaselineFailure, BaselineSnapshot?>` here; null means verified absence only. |
| Navigation | Extend `AppRouter.onGenerateRoute` and `AppRoutes`; preserve counter and unknown-route behavior. |
| UI reuse | Reuse `AppTheme`, `AppSystemUi`, `AppDimensions`, `AppTextStyles` and `AppStrings`. `core/components`, `utils`, `services`, `models`, `repositories` and `error` contain no implementations to reuse. Use themed Material controls, private widgets and native date/time dialogs. |
| Imports | Runtime Dart files use `lib/core/router/exports.dart`; BLoC parts use `part of`. Export new files and needed SDK libraries through the existing barrel. |
| Tests | `flutter_test` is used now; `bloc_test` and `mocktail` are installed. Inject the storage channel for unit tests; real native persistence still needs Android checks. |
| Platform | Android only. Installed Flutter resolves the current minimum to API 24, as recorded in project configuration. The proposal's API 23 sentence is stale; do not lower the minimum as part of this work. |
| Prior decisions | Before this planning pass, `docs/adr/` contained only `.gitkeep`. The owner accepted storage/schema ADRs 0001–0002 on 9 October 2026. |

One `baseline` feature owns onboarding, landing and read-only Profile. These are
three views of one saved baseline, so separate features, repositories and BLoCs
would add cross-feature coordination without a Sprint 1 benefit. Only the
platform storage bridge belongs in core.

No calculations are introduced. Availability copy describes supplied inputs
and future limitations; it does not assert that a formula is applicable merely
because fields exist. No analytics agent consultation is needed for a new method,
because this increment chooses no physiological or statistical method.

## 2. Owned files and boundaries

Paths below are proposed implementation files, not generated scaffolding.

| Files | Responsibility |
|---|---|
| `lib/features/baseline/model/baseline_records.dart` | Units, time/provenance, validated profile, starting weight and initial goal. |
| `lib/features/baseline/model/onboarding_draft.dart` | Recoverable raw form, step, revision, field-entry units and value-specific confirmations. |
| `lib/features/baseline/model/baseline_snapshot.dart` | Draft/completed variants and strict versioned codec. |
| `lib/features/baseline/model/baseline_validation.dart` | Parsing, unit conversion and form/completion checks; no health estimates. |
| `lib/features/baseline/repo/baseline_repository.dart` | One concrete repository, local failure types, serialized writes and idempotent completion. |
| `lib/features/baseline/bloc/baseline_bloc.dart` plus `baseline_event.dart`, `baseline_state.dart` parts | Loading, editing, persistence acknowledgments, confirmation, completion and retry. |
| `lib/features/baseline/view/baseline_page.dart` | Product route, BLoC lifetime, lifecycle/back handling and five private step widgets. |
| `lib/features/baseline/view/baseline_landing_page.dart`, `baseline_profile_page.dart` | Honest completion landing and saved-profile inspection. Profile receives a committed immutable bundle; no second BLoC. |
| `lib/core/services/protected_baseline_store.dart` | Concrete MethodChannel adapter; no storage interface with a single production implementation. |
| `android/app/src/main/kotlin/com/example/tspm/ProtectedBaselineStore.kt` | Platform encryption and atomic file read/replace on one background executor. |
| Existing `MainActivity.kt` | Register/dispose the channel; avoid putting persistence bodies in the activity. |
| Existing `lib/core/router/{app_routes,app_router,exports}.dart`, `lib/main.dart` | Route registration, exports and explicit injectable initial-route choice. |
| Existing `lib/core/constants/app_strings.dart` | Product, validation, privacy, save/retry and unknown-value copy. Extend dimensions only for an actual layout need. |
| `test/features/baseline/{model,repo,bloc,widget}/` | Criterion-focused tests at the matching seam. |
| `android/app/src/androidTest/kotlin/com/example/tspm/ProtectedBaselineStoreTest.kt` and `android/app/build.gradle.kts` if needed | Real native storage round-trip/failure tests and minimum Android test-runner configuration. |
| Existing `test/widget_test.dart` | Keep counter/theme coverage explicit when app startup becomes injectable. |
| `docs/specs/tspm-sprint-1-verification.md` | Actual check results, emulator evidence and promotion decision at implementation close. |

All model types below live in the four named feature model files; events/states
live in their parts and repository failures in the repository file. Native helper
types remain private in the Kotlin storage file. Do not create a file per enum.

## 3. Types and wire schema

The following are declarations/signatures only, not method implementations.
`get` notation describes immutable fields; constructors are omitted where they
would only repeat the table. Validated record constructors are private to their
model library; parsing/completion factories enforce the invariants.

### Primitive choices and provenance

```dart
enum WeightUnit { kg, lb }
enum LengthUnit { cm, inch }
enum EquationSexInput { male, female }
enum ApplicabilityAnswer { unknown, no, yes }
enum RecordOrigin { manuallyEntered, externallyReported }
enum ActivityLevel { sedentary, lightlyActive, moderatelyActive, veryActive, extremelyActive }
enum LossRate { quarterPercent, halfPercent, threeQuarterPercent, onePercent }
enum OnboardingStep { purposeAndUnits, requiredBaseline, measurements, activity, goalAndApplicability }

final class UnitPreferences extends Equatable {
  WeightUnit get weight;
  LengthUnit get length;
}

final class LocalDay extends Equatable {
  int get year;
  int get month;
  int get day;
  static LocalDay parse(String isoDay);
  String toIsoDay();
}

final class ObservationTime extends Equatable {
  DateTime get instantUtc;
  LocalDay get selectedLocalDay;
  int get originalUtcOffsetMinutes;
  static ObservationTime fromSelectedLocal(DateTime selectedLocal);
}

final class RecordMetadata extends Equatable {
  String get id;
  DateTime get createdAtUtc;
  DateTime get updatedAtUtc;
  RecordOrigin get origin;
}

final class ReportedBodyFat extends Equatable {
  double get percent;
  String get source;
}
```

`LocalDay` rejects invalid dates rather than allowing DateTime normalization.
`ObservationTime` validates that instant plus original offset reproduces the
saved local day; its local clock is derived using that offset, never the current
device zone. No timezone package is needed. Editing date/time captures the
selected zone's offset again; merely reopening or toggling units never does.
Show the selected clock and offset before completion. Reject normalized nonexistent
local clock times. For a repeated daylight-saving clock time, the proposal uses
Dart's resolved instant with its offset visible; selecting the other occurrence
is an explicitly deferred capability, subject to owner review below.

### Committed records

```dart
final class BaselineProfile extends Equatable {
  RecordMetadata get metadata;
  int get ageYears;
  LocalDay get ageRecordedOn;
  EquationSexInput get equationInput;
  double get heightCm;
  LengthUnit get originalHeightUnit;
  UnitPreferences get preferredUnits;
  double? get waistCm;
  LengthUnit? get originalWaistUnit;
  double? get neckCm;
  LengthUnit? get originalNeckUnit;
  double? get hipCm;
  LengthUnit? get originalHipUnit;
  ReportedBodyFat? get reportedBodyFat;
  ActivityLevel? get activityLevel;
  int? get typicalDailySteps;
  int? get trainingDaysPerWeek;
  String? get trainingType;
  int? get restDaysPerWeek;
  ApplicabilityAnswer get pregnancy;
  ApplicabilityAnswer get breastfeeding;
}

final class StartingWeightObservation extends Equatable {
  RecordMetadata get metadata;
  double get weightKg;
  WeightUnit get originalUnit;
  ObservationTime get observedAt;
  String get source;
}

sealed class InitialGoal extends Equatable {
  RecordMetadata get metadata;
  LocalDay get effectiveOn;
  double? get bodyFatMilestonePercent;
}
final class MaintenanceGoal extends InitialGoal {}
final class LossGoal extends InitialGoal {
  double get targetWeightKg;
  WeightUnit get originalTargetWeightUnit;
  LossRate get rate;
}

final class CompletedBaseline extends Equatable {
  String get setupId;
  DateTime get completedAtUtc;
  BaselineProfile get profile;
  StartingWeightObservation get startingWeight;
  InitialGoal get goal;
}
```

Age is an integer ≥18, recorded on the completion profile date; no invented birth
date. Physical values are finite and positive. Optional circumferences are either
absent (including their unit) or positive values with original units. Supplied
body-fat percentages and milestones are finite and strictly between 0 and 100;
reported body fat requires a nonblank source. These are structural input checks,
not model eligibility claims. Steps accept explicit integer zero and positive
integers; omission is null. Training/rest days accept integers 0–7; do not derive
one from the other. Activity omissions stay null.

Loss stores a positive finite target and one of the four selected rates;
maintenance cannot accidentally carry a target/loss-rate pair. A lower-than-start
loss target rule is not explicit in Sprint 1, so the proposal imposes no new
relation check pending review. All optional target body-fat values stay user
intent, not measured body fat.

Starting weight source is the user's manual scale report. Profile/goal metadata
are entered; an externally sourced body-fat value retains its own source and is
labeled reported in Profile. IDs derive from a random, persisted `setupId` plus
record role (`profile`, `starting-weight`, `initial-goal`); use SDK secure randomness,
not a UUID dependency. Creation/update times are UTC and frozen for retry.

### Drafts keep invalid input recoverable

```dart
enum OnboardingField {
  age, height, startingWeight, waist, neck, hip, bodyFatPercent, bodyFatSource,
  typicalSteps, trainingDays, trainingType, restDays, goalWeight, bodyFatMilestone
}
enum GoalIntent { loss, maintenance }
enum OutlierField { height, startingWeight }

final class DraftQuantity extends Equatable {
  String get rawText;
  double? get canonicalValue;
  String get originalUnitToken;
  String get displayUnitToken;
}

final class OnboardingDraft extends Equatable {
  String get setupId;
  DateTime get createdAtUtc;
  DateTime get updatedAtUtc;
  int get revision;
  OnboardingStep get step;
  UnitPreferences get units;
  Map<OnboardingField, String> get text;
  Map<OnboardingField, DraftQuantity> get quantities;
  EquationSexInput? get equationInput;
  ObservationTime get startingTime;
  ActivityLevel? get activityLevel;
  GoalIntent? get goalIntent;
  LossRate? get lossRate;
  ApplicabilityAnswer get pregnancy;
  ApplicabilityAnswer get breastfeeding;
  Map<OutlierField, double> get confirmedCanonicalValues;
}
```

Maps are immutable copies. Quantity fields occur only in `quantities`, other
text only in `text`; do not keep two authoritative strings for one field.
DraftQuantity unit tokens are checked against the field's weight/length family.
It allows blank/invalid text with null parsed value; it never loses the text to
make the draft look valid. `rawText` is always interpreted in `displayUnitToken`,
not `originalUnitToken`. Decoder verifies a supplied canonical value is finite
and positive and matches that representation within relative tolerance 1e-12
(scaled by max(1, absolute canonical value)). Toggle-generated editable text uses
Dart's round-trip `double.toString()`; only read-only labels may round. The codec
never regenerates canonical values from display text. Test toggle/save/reload.

On a unit toggle, convert only valid quantities from their retained canonical
value for display. Do not reparse rounded display text into the canonical value.
Invalid text retains its existing display unit and an explanatory label until
corrected; the preference change does not silently reinterpret it. A numeric
edit captures its current entry unit and updates canonical value. Original
entry unit changes on a real edit, not on toggling presentation. Exact conversion
constants: 1 lb = 0.45359237 kg and 1 in = 2.54 cm.

Outlier acceptance is tied to the exact canonical height/starting weight and
cleared on numeric edit. Inclusive 100–250 cm and 25–350 kg bands need no
confirmation; finite positive values outside require it. Declining retains
the field and blocks advance. No clamp. Changing equation input never clears
optional hip or applicability answers. Switching goal intent retains draft
text for switching back, but completion serializes only the active goal variant.

### Snapshot and codec

```dart
sealed class BaselineSnapshot extends Equatable {
  int get schemaVersion;
  String get setupId;
}
final class DraftBaselineSnapshot extends BaselineSnapshot {
  OnboardingDraft get draft;
}
final class CompletedBaselineSnapshot extends BaselineSnapshot {
  CompletedBaseline get baseline;
}

abstract final class BaselineCodec {
  static Either<BaselineFailure, BaselineSnapshot> decode(String json);
  static String encode(BaselineSnapshot snapshot);
}

enum InputIssue { required, invalidNumber, adultOnly, positiveFiniteRequired, invalidDateTime, percentageRange, dayCountRange, sourceRequired }
final class FormProblems extends Equatable {
  Map<OnboardingField, InputIssue> get fields;
  bool get invalidStartingTime;
  bool get missingEquationInput;
  bool get missingGoalIntent;
  bool get missingLossRate;
  Map<OutlierField, double> get confirmationsRequired;
}
abstract final class BaselineValidation {
  static FormProblems checkStep(OnboardingDraft draft);
  static Either<FormProblems, CompletedBaseline> prepareCompletion(
    OnboardingDraft draft, DateTime completedAtUtc, LocalDay profileDay);
  static double weightToKg(double value, WeightUnit unit);
  static double weightFromKg(double value, WeightUnit unit);
  static double lengthToCm(double value, LengthUnit unit);
  static double lengthFromCm(double value, LengthUnit unit);
}
```

Wire format v1: `{schemaVersion: 1, kind: draft|completed, setupId, payload}`.
Only a completed payload contains the three committed records. Setup completion
is derived from this variant, never a separately written flag. Empty storage is
not an empty JSON object. Reject malformed JSON, duplicate/invalid identifiers,
bad types, invalid enums/dates/quantities and impossible committed combinations.
Reject unsupported schema versions before interpreting their payload; never
replace them with v1 defaults. A draft can be incomplete or numerically invalid
without being corrupt. No migration exists yet; later schema changes require
explicit migrations and preservation tests. See [ADR 0002](../adr/0002-baseline-snapshot-contract.md).

## 4. Protected storage and repository signatures

```dart
final class ProtectedBaselineStore {
  ProtectedBaselineStore({MethodChannel? channel});
  Future<String?> read();
  Future<void> replace({required String? expectedJson, required String nextJson});
}

enum BaselineOperation { load, saveDraft, complete }
enum BaselineFailureReason { io, keyUnavailable, corrupt, unsupportedVersion, conflict }
enum WriteOutcome { notCommitted, unknown }
final class BaselineFailure extends Equatable {
  BaselineOperation get operation;
  BaselineFailureReason get reason;
  int? get unsupportedVersion;
  WriteOutcome? get writeOutcome;
}

final class BaselineRepository {
  BaselineRepository({required ProtectedBaselineStore store});
  Future<Either<BaselineFailure, BaselineSnapshot?>> load();
  Future<Either<BaselineFailure, DraftBaselineSnapshot>> saveDraft(OnboardingDraft draft);
  Future<Either<BaselineFailure, CompletedBaselineSnapshot>> complete(CompletedBaseline candidate);
}
```

Native channel `tspm/protected_baseline`: `read` returns plaintext JSON or null;
`replace` takes expected JSON (null for verified absence) and next JSON. Both
execute serially off the UI thread. Kotlin methods in the single store file:

```kotlin
fun read(): String?
fun replace(expectedJson: String?, nextJson: String): Unit
fun register(messenger: BinaryMessenger): Unit
fun close(): Unit
```

Use platform AES/GCM with a generated AndroidKeyStore key and fresh cipher IV.
The binary container has a fixed magic/format version, IV and authenticated
ciphertext/tag; bind the header/store identity as authenticated additional data.
Keep it in `context.noBackupFilesDir/tspm-baseline.bin`. No plaintext health file,
preferences or log; plaintext exists only in process/channel memory. No biometrics,
account, network or runtime permission is introduced. Do not promise hardware
backing on every device; the requirement is AndroidKeyStore protection.

Read the committed base file directly; never promote a leftover `.pending` file
on startup. Return null only for a verified accessible parent with no committed
file. Permission/I/O, malformed container, authentication failure and missing key
are failures. A leftover first-write temporary file is unacknowledged work, not a
completed profile; never create a new key over existing encrypted artifacts.
Do not delete corrupt base data, regenerate a lost key, or expose a reset button.

For replacement: read/decrypt current bytes, compare expected JSON, write the
encrypted candidate to a same-directory `.pending` file, check stream sync and
close, then use checked `android.system.Os.rename(pending, base)` to replace the
base atomically. Sync the containing directory with checked `Os.fsync` and verify
the base ciphertext before acknowledgment. Never open/truncate the base for writing.
Failure before replacement is `notCommitted`; any failure after replacement or
lost channel response is `unknown`. Preserve committed files on both paths and
retry the identical candidate on uncertainty. Pending-file cleanup never deletes
the base. All accesses share one native background executor.

Platform AtomicFile is not selected: its API 24 implementation can truncate the
base after a failed backup rename. This plan uses checked standard file/OS calls
so that behavior is consistent at the app minimum; it does not add a file journal
or backup format. See [API 24 source](https://raw.githubusercontent.com/aosp-mirror/platform_frameworks_base/android-7.0.0_r1/core/java/android/util/AtomicFile.java)
and [Android OS operations](https://developer.android.com/reference/android/system/Os).

This choice deliberately avoids the installed plugin's `apply()` acknowledgment
and reset defaults. It also avoids SharedPreferences corrupt XML appearing as
absence. The [storage ADR](../adr/0001-protected-baseline-storage.md) records the
alternatives, sources and native verification gate. It is an Android adapter,
not a new cross-platform persistence framework.

Repository operations also serialize in one instance. Each mutation rereads and
decodes current storage before replacing it. Native expected-value comparison
protects against changes between read and replace. Reject writes over corrupt,
unsupported or unreadable data; reject stale draft revisions and any draft write
after completion. A failed load cannot authorize a default/new draft overwrite.

Prepare one frozen completion candidate with stable IDs/times, then persist it as
one completed snapshot. Duplicate taps are blocked in BLoC and cannot append
observations in storage. Retry rewrites the same candidate and checks durable
success, including when the earlier operation may have finished before returning
failure. Do not infer acknowledged success from in-process equality alone.
After a fresh process successfully loads a valid completed snapshot, it opens
landing directly. A different setup ID or incompatible completion is conflict,
not permission to replace it. Failed writes retain answers and name the operation.

Single-snapshot rewrites fit one profile/draft. Revisit storage when daily logs,
history, backup import or measured write volume need indexed/transactional records;
do not extend this snapshot into the entire future database.

## 5. BLoC seam

```dart
sealed class BaselineEvent extends Equatable {}
final class BaselineLoadRequested extends BaselineEvent {}
final class BaselineDraftChanged extends BaselineEvent { OnboardingDraft Function(OnboardingDraft) get update; }
final class BaselineUnitsChanged extends BaselineEvent { UnitPreferences get units; }
final class BaselineNextPressed extends BaselineEvent {}
final class BaselineBackPressed extends BaselineEvent {}
final class BaselineOutlierAnswered extends BaselineEvent {
  OutlierField get field; double get canonicalValue; bool get accepted;
}
final class BaselineFlushRequested extends BaselineEvent {}
final class BaselineCompletePressed extends BaselineEvent {}
final class BaselineRetryPressed extends BaselineEvent {}
// Internal completion message; never dispatched by a widget.
final class BaselineWriteFinished extends BaselineEvent {
  int get revision;
  BaselineOperation get operation;
  Either<BaselineFailure, BaselineSnapshot> get result;
}

sealed class BaselineState extends Equatable {}
final class BaselineLoading extends BaselineState {}
final class BaselineLoadFailed extends BaselineState { BaselineFailure get failure; }
final class BaselineEditing extends BaselineState {
  OnboardingDraft get draft;
  FormProblems get validation;
  int get persistedRevision;
  bool get saving;
  BaselineFailure? get saveFailure;
}
final class BaselineCompleting extends BaselineState {
  OnboardingDraft get draft;
  CompletedBaseline get candidate;
  bool get saving;
  BaselineFailure? get saveFailure;
}
final class BaselineCompleted extends BaselineState {
  CompletedBaseline get baseline;
  bool get justCompleted;
  BaselineFailure? get refreshFailure;
}

final class BaselineBloc extends Bloc<BaselineEvent, BaselineState> {
  BaselineBloc({required BaselineRepository repository, DateTime Function()? now});
}
```

The UI sends an immutable update function on each change; BLoC applies it to the
latest draft, validates its setup ID/revision, owns revision increments and discards any attempted edit
outside Editing. Text controllers hold what the user types immediately. BLoC
updates editing state synchronously before scheduling repository I/O. Save futures
report internal acknowledgments, carrying the captured revision; do not let an
old response replace newer answers or label them saved. Repository writes are
ordered; no extra debounce package or reliance on a lifecycle-only save.

`persistedRevision == draft.revision` means current answers were acknowledged.
Show Saving or Unsaved/Retry otherwise. Next validates its step and saves the
new step/revision; Back saves the earlier step. Process death resumes the last
acknowledged revision, never a falsely claimed latest save. Flush on lifecycle
inactive/paused and route exit, but continuously saved edits provide recovery
when Android gives no final callback. Process death during unacknowledged typing
may lose those edits; the UI must show that they are still being saved.

Completion freezes input/candidate, queues after pending drafts and emits Completed
only on acknowledged success. Retry from Completing uses that same candidate;
Back after a confirmed `notCommitted` failure returns to Editing with retained
answers and permits correction. An `unknown` outcome keeps the frozen candidate;
Retry reconciles/replaces it before any editing is allowed. A matching completed
snapshot is rewritten and acknowledged, not converted into an editable draft.
Only a successful read establishing that the original draft is authoritative
allows returning to Editing. New edits then invalidate the previous candidate.
Outlier responses for stale
values are ignored. First-load retry remains a first-load operation; no writable
form is shown over unreadable storage. Refresh failure retains existing completed
content, and a failed draft save retains Editing content.

Navigation, confirmations, keyboard handling, snackbars, lifecycle observation
and BuildContext stay in UI. Confirmation dialogs are triggered by validation
state; decline changes no numeric answer. No platform access from BLoC.

## 6. Widgets and routes

```dart
BaselinePage({BaselineRepository? repository, Key? key})
BaselineLandingPage({required CompletedBaseline baseline, required VoidCallback onReviewProfile, Key? key})
BaselineProfilePage({required CompletedBaseline baseline, Key? key})
ProfileRouteArgs({required CompletedBaseline baseline})
_BaselineFormHost({required BaselineEditing state, Key? key})

// Private stateless presentation widgets inside baseline_page.dart:
_OnboardingShell({required OnboardingStep step, required Widget child,
  required VoidCallback onBack, required VoidCallback onNext,
  required bool saving, required bool canAdvance, required Widget saveStatus})
_PurposeAndUnitsStep({required OnboardingDraft draft, required ValueChanged<UnitPreferences> onChanged})
_RequiredBaselineStep({required OnboardingDraft draft, required FormProblems problems,
  required ValueChanged<OnboardingDraft> onChanged, required VoidCallback onEditTime})
_MeasurementsStep({required OnboardingDraft draft, required FormProblems problems,
  required ValueChanged<OnboardingDraft> onChanged})
_ActivityStep({required OnboardingDraft draft, required FormProblems problems,
  required ValueChanged<OnboardingDraft> onChanged})
_GoalAndApplicabilityStep({required OnboardingDraft draft, required FormProblems problems,
  required ValueChanged<OnboardingDraft> onChanged})
```

A private `_BaselineFormHost` StatefulWidget with `_BaselineFormHostState`
owns/disposes text controllers and the lifecycle observer. It passes values and
callbacks to the stateless step layouts and
synchronizes restored/unit-converted text without moving the cursor on save-only
acknowledgments. Use ScrollView, SafeArea and constrained reading width, reachable
buttons above keyboard insets, normal OS text scaling and ≥48px tap targets.
Use native `showDatePicker`/`showTimePicker`, labeled unknown choices and inline
field errors. Standard Material pressed/focus behavior comes from the existing
theme; no shared component suite or decorative motion is introduced.

Purpose explains local-only data and observations versus future estimates. The
last step previews supplied inputs, missing optional inputs and applicability
limits in words. Both pregnancy and breastfeeding are explicit yes/no/unknown
controls independent of equation input. Hip is optional for anyone who supplies
it; do not hide or discard it based on the equation choice. No multiplier,
calorie range, body-fat estimate or confidence value is shown.

Landing visibly confirms newly completed setup, explains future logging is needed
for trends, and offers only a working Review profile action. Profile shows saved
canonical quantities in preferred units, original weight date/clock/offset,
sources, baseline/activity/goal choices, unknown values and applicability limits.
It is read-only; later baseline edits/backups/delete-all are not stubbed here.

Routes: add `/product`, `/profile`, `/counter`. `/` retains the counter during
development; `/counter` is its permanent explicit alias. Profile uses typed
`ProfileRouteArgs({required CompletedBaseline baseline})` validated in AppRouter;
missing/wrong arguments render existing unknown-route treatment, never a crash.
Expose working product entry from the counter while developing. Preserve theme
and global system-bar builder across all routes.

`MyApp({ThemeMode themeMode = ThemeMode.light, String initialRoute = AppRoutes.home})`
allows tests to select the counter/product explicitly. Default-route promotion
is a separate final change only after all applicable acceptance gates pass; retain
the explicit counter smoke/theme tests. The final entry reuses BaselinePage's
storage gate and opens onboarding or landing according to the saved variant.

Android/system back follows the same draft-flush path as labeled Back/exit.
Use PopScope to wait for the latest flush before popping when an exit can be
intercepted. A save failure retains the screen and offers Retry or explicit exit
with Unsaved warning; an OS kill cannot be blocked. Stepping back stays in the
same product route and does not create duplicate route/BLoC stacks.

## 7. Sequence and proof

Every implementation step also runs relevant formatting and analysis (rung 1).
Do not call a mocked channel test proof of encrypted Android persistence.

| Step | Deliverable and verifiable stopping point | Required evidence |
|---|---|---|
| 1. Model/codec | Raw incomplete/invalid draft round-trips; committed records validate; goal variants, units and original day/offset are retained. | Rung 2: `flutter test test/features/baseline/model/`; test kg/lb/cm/in toggles without canonical drift, exact threshold edges, edit invalidation, unknown/zero distinction, date normalization, schema corruption/version cases. Criteria 2–7, 12 at domain seam. |
| 2. Native store/repository | Durable encrypted draft survives process restart; one completion snapshot replaces it; I/O/key/corruption failures preserve records and input. No product UI is required to demonstrate it. | Rung 2 repository tests plus native instrumentation on disposable Android emulator. Test file/directory sync, rename and verification failures, interruption before/after replacement, missing key, inaccessible parent, corrupt bytes, expected-value conflict, late draft and identical completion retry. Inspect disk for absence of plaintext. Criteria 8, 9, 11, 12. Stop here if native guarantees fail; amend ADR/plan before feature UI. |
| 3. BLoC | Load/resume, optimistic editing, latest-revision acknowledgments, back/next, confirmation and frozen completion/retry can be driven directly. | Rung 2: `flutter test test/features/baseline/bloc/`; include out-of-order acknowledgments, background flush, duplicate complete taps and failures that retain input. Criteria 1–9, 12. |
| 4. UI/routes | All five steps, landing, typed Profile and explicit counter route are functional without fake data. | Rung 3: `flutter test test/features/baseline/widget/`; required/optional flows, both goals, applicability yes/unknown, warnings/decline, saved/unsaved copy, back, landing/profile, both themes, 200% text, keyboard reachability and semantics. Existing `flutter test` suite protects counter/theme/system bars. Criteria 1–14 at widget seam. |
| 5. Device acceptance | Product route boots offline, resumes real stored answers after force-stop and preserves time provenance after zone change. Storage errors and accessibility work on Android. | Device-level evidence: boot/run on Android emulator, airplane mode, mid-flow force-stop/relaunch after Saved, completed reopen, duplicate completion, timezone change, native failure scenarios, both themes/200% text, TalkBack and reduced-motion review. Record screenshots/scenario results and native test output. Criteria 1–14 in the integrated app. |
| 6. Promote only after pass | Product becomes startup default; explicit counter remains runnable. | Repeat full `flutter analyze`, `flutter test`, format check and startup/counter device smoke after this routing change. Record promotion in verification report. No promotion while persistence/device acceptance is unproven. |

The Flutter rung-5 `integration_test` harness is present in `integration_test/`
with its driver in `test_driver/`; Android instrumentation is in
`android/app/src/androidTest/`. Manual device scenarios and Android instrumentation
are separate evidence from the Flutter integration run. Use `flutter devices`,
`flutter run -d <emulator-id>` and the actual Gradle
connected-test task/device selected during implementation; record exact commands
then. An automated Flutter integration harness can be added only if selected work
requires it; it is not scaffolded by this planning pass. There is no approved
pixel baseline, so rung 4 goldens are not a completion claim.

## 8. Subtraction, decisions and review

Replace the counter-only routing assumption and counter-specific startup test
assumption when promotion is verified; keep the counter feature and its increment
behavior. There is no existing persistence, failed component abstraction or
fixture data to delete. Remove any temporary native fault-injection hooks before
shipping; tests must not expose a production reset/corruption UI.

Hard-to-reverse decisions are accepted by the owner: [ADR 0001, encrypted native snapshot](../adr/0001-protected-baseline-storage.md)
and [ADR 0002, versioned atomic baseline/read contract](../adr/0002-baseline-snapshot-contract.md).
State management and routing do not change technologies and need no new ADR.

Accepted defaults and their limits:

- Activity uses the five descriptive choices above, without numerical factors.
  Different labels can be settled now; numerical mappings remain later methodology.
- Pregnancy and breastfeeding are separate unknown/no/yes answers. Either yes or
  unknown withholds future automated loss-target availability in the summary.
- Loss target requires a positive finite value, with no extra below-start rule.
  A stricter relation requires a product criterion before implementation.
- Repeated DST clock times use the displayed resolved offset. An explicit choice
  between both occurrences would add a timestamp-input requirement.
- Native durability is a required implementation proof, not established by this
  document. Failure of the step-2 spike requires re-sketching storage, not weakening
  the save-success claim. Sudden device power loss is not promised by Sprint 1's
  process-death requirement.

No unanswered question blocks implementation. The owner confirmed a 9 October 2026
start and two-week duration. The 21-point estimate remains provisional.

## Planning-session checks

On 7 October 2026, `flutter analyze` reported `No issues found! (ran in 1.7s)`;
`flutter test` reported `+12`, `All tests passed!`, no failures. The first analyzer
attempt was blocked by SDK-cache sandbox access; the approved retry completed.
These are the existing counter/theme baseline only. No Sprint 1 implementation,
native instrumentation, format command or emulator scenario was run in this pass.

Implementation is in progress. Use this sketch to finish the planned verification
sequence; the current results and remaining emulator storage constraint are in
`tspm-sprint-1-verification.md`.

## Implementation refinements (9 October 2026)

- Draft changes carry immutable update functions so rapid edits apply to the latest BLoC state rather than an older captured form snapshot. This preserves the planned revision/acknowledgment contract.
- The initial goal takes effect on the completion local day. A backdated starting observation retains its independent day/instant/offset; age recording also uses the completion day.
- Directory validation uses public `Os.fstat`/`S_ISDIR`; file opens avoid `O_CLOEXEC`, whose public field appeared after API 24. Native Android lint checks the actual minimum.
- The Flutter SDK integration harness exercises disposable local-only Android data. No backend, staging account, credentials or external startup gates exist. Device evidence and remaining limitations are recorded separately.
