# Sprint 1 verification

**Result:** implementation and emulator acceptance completed 13 October 2026.
Product onboarding is now the default route; `/counter` remains available.
This report covers the continuation from `e670171` on `codex/sprint-1-next`.
Historical checkpoint results are retained below and do not describe current blockers.

## Final gates

| Check | Actual result |
|---|---|
| `flutter analyze` | 13 October: `No issues found! (ran in 2.4s)`. |
| `TZ=America/New_York flutter test` | 13 October: `+97`, `All tests passed!`, zero failures or skipped tests. The timezone enables the real DST widget regression. Before continuation: +64, zero failures. |
| `dart format --output=none --set-exit-if-changed lib test integration_test test_driver` | 13 October: `Formatted 44 files (0 changed)`. |
| `JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home' ./android/gradlew -p android :app:assembleDebugAndroidTest :app:lintDebug` | Final harness compile/lint, 13 October: `BUILD SUCCESSFUL in 13s`. Gradle/Flutter plugin deprecation warnings remain; no lint failure. |
| Independent conventions review | Final read-only review: 0 actionable findings. |
| Independent spec review | Final read-only review: 0 actionable findings. Earlier findings were fixed and checked again. |

The full suite follows the last runtime change: neutral goal wording in an
unacknowledged completion preview. Default-startup tests cover verified absence,
saved draft, completed baseline, read failure, and exactly one storage gate for
explicit `/product` startup. Counter/theme tests select `/counter` explicitly.

## Device evidence (rung 5)

All writes used synthetic local-only data on task-owned disposable emulators.
No backend, account or real user-data reset was involved. APK phase updates
preserved app data; host force-stop was separate from the Flutter runner.

| Surface / date | Result |
|---|---|
| API 33 and minimum API 24, 9 October | Fresh `ProtectedBaselineStoreTest` execution on each: `OK (11 tests)`. Real AndroidKeyStore encryption, conflict handling, malformed/unsupported container preservation, missing key, sync/rename/verification errors and inaccessible-directory handling passed. |
| API 33 and API 24 process boundaries, 9 October | Each ran `prepare → interruptBeforeRename → verifyOld`, `prepare → interruptAfterRename → verifyNew`, and `prepare → host force-stop → verifyAcknowledged`. All verifiers passed (`OK (1 test)` each). Intentional killed runner invocations are expected; their subsequent verifier establishes the result. |
| API 33 Flutter phases, 9 October | `draft → host force-stop → complete → host force-stop → review` passed. Honolulu/Kolkata timezone changes, airplane mode, Wi-Fi/data disabled, 200% text and animations disabled. Maintenance with pregnancy yes/breastfeeding unknown; saved-record assertions, original observation time, landing/Profile and counter checked. |
| API 24 Flutter phases, 9 October | Same three phases passed with force-stop, dark theme, 200% text, Wi-Fi/data disabled, loss goal and unknown applicability. Do not infer successful airplane-mode activation: API 24 rejected the broadcast/connectivity command. Offline behavior is established by disabled Wi-Fi/data. |
| API 33 native accessibility, 13 October | `BaselineAccessibilityTest#ac13NativeLabelsFocusAndFiveStepOrder`, `-e baselineAccessibility true`: `OK (1 test)`. TalkBack enabled, 200% text, airplane mode; all five steps' labels/order, accessibility focus and focused native text entry checked. |
| API 33 real DST picker, 13 October | `integration_test/baseline_time_test.dart` in America/New_York: `+2`, `All tests passed!` (scenario plus teardown). March 8, 2026 02:30 rejected without changing accepted time; 03:30 accepted with correct instant/day/offset. |
| API 33 Android Back/save recovery, 13 October | `BaselineAccessibilityTest#ac8And12SystemBackWarnsOnFailedSaveAndRetryRetainsAnswers`, `-e baselineRecovery true`: `OK (1 test)`, `Time: 5.973`. Temporary read-only test directory causes a real draft-save failure; committed bytes stay intact, Android Back warns, Keep editing retains input, restored permissions plus Retry acknowledge the edit, completion and Profile order/focus pass. Permissions restored in `finally`. |
| API 33 default startup after promotion, 13 October | Host force-stop followed by `BASELINE_PHASE=review`, dark theme: `+2`, `All tests passed!`. Real completed storage opens default landing, Profile retains original time, explicit counter increments. |
| API 33 corrupt ciphertext UI, continuation | Test-owned ciphertext corruption produced the load failure and Retry without a writable replacement form. Corrupt bytes remained untouched. Restoring the exact test fixture bytes and Retry reopened its saved content. This is a fixture restoration check, not a product backup feature. |

Commands used for device phases (serial/phase substitutions select the disposable
device and the separate invocation):

```sh
flutter drive --driver=test_driver/baseline_driver.dart \
  --target=integration_test/baseline_test.dart -d <serial> \
  --dart-define=BASELINE_PHASE=<draft|complete|review> --keep-app-running
# Dark/loss scenarios additionally use BASELINE_DARK=true / BASELINE_LOSS=true.
adb -s <serial> shell am force-stop com.example.tspm
adb -s <serial> shell am instrument -w \
  -e class com.example.tspm.ProtectedBaselineStoreTest \
  com.example.tspm.test/androidx.test.runner.AndroidJUnitRunner
adb -s <serial> shell am instrument -w \
  -e class com.example.tspm.ProtectedBaselineProcessTest -e scenario <scenario> \
  com.example.tspm.test/androidx.test.runner.AndroidJUnitRunner
```

Latest default smoke used `emulator-5558`, `BASELINE_PHASE=review` and
`BASELINE_DARK=true`. The two native interaction tests need an unfinished test
draft and their respective opt-in argument; ordinary instrumentation skips them.
Run the DST harness before completing that draft. Unknown Flutter phase values
throw before binding initialization/storage access, checked by a host self-check.

Local screenshots and process transcripts are ignored build artifacts under
`build/sprint1-evidence/`, including `api24-dark-loss/`,
`android-dst-{rejected,valid}.png`, `review-*.png` and
`emulator-555{4,6}-process-tests.txt`. Generic phase screenshots can be overwritten
by later runs; the dated results above distinguish the actual executions.

## Acceptance criteria and verification rungs

Rung 2 = model/repository/BLoC; rung 3 = widget; rung 5 = real Android execution.
Each row names the tested behavior, rather than treating one device suite title
as proof of every edge case. Test paths are relative to the repository.

| AC | Test seam / evidence | Highest relevant proof |
|---|---|---|
| 1 First run | `test/product_startup_test.dart`; `integration_test/baseline_test.dart` ordered steps, native five-step order | Rung 5 flow; rung 3 startup-state branches. |
| 2 Required baseline | `model/baseline_contract_acceptance_test.dart` adult/integer/finite inputs; device draft under-18 rejection and correction | Rung 5 visible adult rejection; rungs 2–3 numeric edge cases and equation explanation. |
| 3 Confirmation | Contract/BLoC outlier tests; device draft converts inches, shows confirmation and preserves declined value | Rung 5 decline/correction; rungs 2–3 acceptance and exact threshold boundaries. |
| 4 Optional answers | Contract/record tests; device completion asserts omitted values remain null and Profile shows unknown | Rung 5 omission; rung 2 supplied-source round-trip and explicit zero distinctions. |
| 5 Units | Contract tests; device lb/in draft persists canonical kg/cm and resumes preference; native recovery toggles unit | Rung 5 persistence; rungs 2–3 reversible quantity conversion. |
| 6 Time | `model/baseline_validation_edge_test.dart`, view DST regression; native picker and timezone-changed reopen | Rung 5 real DST rejection/acceptance and stored provenance. Repeated clocks retain the platform-resolved offset, with model coverage. |
| 7 Goal/applicability | Contract tests; API 24 loss/unknown and API 33 maintenance/yes completion and stored-record assertions | Rung 5 both goals/limitation copy; rung 2 all applicability tokens. |
| 8 Draft/back | BLoC save ordering; view newest-edit/exit regression; force-stop phases and native Android Back failure | Rung 5 durable resume and Back warning; rung 3 concurrent exit/save race. |
| 9 Completion | Repository/BLoC atomic/idempotent and uncertain-retry tests; device duplicate taps and one completed record set | Rung 5 successful atomic completion; rung 2 uncertain acknowledgment/failure branches. |
| 10 Landing/Profile | View honest landing and candidate-copy tests; device completion/review/default startup | Rung 5 real reopen/navigation; rung 3 absence of fabricated metrics and saved claims on unacknowledged content. |
| 11 Offline/protection | Native encryption/process tests; offline device phases | Rung 5 Keystore storage and disconnected flow; no hardware-backed-key or power-loss claim. |
| 12 Failure | Repository/view corrupt/unsupported and retained-candidate tests; native preservation, real save failure and corrupt UI | Rung 5 actual native read/save preservation; rungs 2–3 retry outcome classification and frozen candidate visibility. |
| 13 Accessibility/theme | View guidelines for five steps/landing/Profile in both themes at 200%, dropdown geometry and step-scroll regressions; native labels/order/focus and disabled animations | Rung 5 native accessibility interaction; rung 3 all-screen geometry/contrast/tap-target checks. Audible TalkBack speech and approved pixel fidelity are not proven. |
| 14 Counter | `test/widget_test.dart`, `test/navigation_test.dart`; device counter increment in both integration scenarios | Rung 5 counter; rung 3 theme/system-UI regressions. |

Model/BLoC/view paths above are under `test/features/baseline/`. Real device
assertions inspect decoded records through the actual protected repository.

## Corrections with red-to-green evidence

- Nonexistent DST clocks: model and timezone-enabled widget tests failed before component validation; real device picker then passed.
- Uncertain completion retry: failed reconciliation reads and failed rewrites of an identical stored completion now retain the frozen candidate. Two BLoC regressions failed before the repository correction; verified-original-draft recovery also passes.
- Exit/save race: a stale draft acknowledgment cannot release Back while a newer failed edit is pending. Delayed-save widget regression failed before the latest-revision flush loop.
- Large-text dropdown clipping and carried step scroll: geometry and next/back tests failed before `isDense: false` and step-keyed reading bodies; both themes pass.
- Default promotion: absence/draft/completed/read-failure startup tests failed while home was the counter, then passed after promotion with one initial route.
- Unacknowledged candidate copy: regression failed on “Saved intention”; shared neutral goal heading now passes. Read-only candidate details remain visible after failure.

## Security review

The changed runtime storage/state and connected native path were reviewed across
the six audit pillars. No actionable findings remain in this scope:

| Pillar | Result / boundary |
|---|---|
| Secrets | Working-tree source/config scan found no credentials; no all-history secret scan claimed. |
| Storage | AndroidKeyStore AES/GCM, authenticated container, fresh IV, no-backup directory, checked replacement and fail-closed reads; native API 24/33 proofs above. No plaintext logging or reset-on-error. |
| Network | No TSPM backend/network path introduced; offline tests use real local data. |
| State | No token/password state; immutable revision/candidate handling preserves unsaved input and completion uncertainty. |
| WebView | No WebView surface introduced. |
| Code quality | Independent conventions/spec findings resolved, analyzer/full suite/native lint pass. |

## Limits and promotion decision

The accepted emulator gates passed before default promotion; startup/counter
smoke passed afterwards. No Sprint 1 criterion was dropped. Coverage is bounded
as the matrix states: edge branches use unit/widget proof where appropriate.
There is no approved golden baseline (rung 4), physical-device execution, audible
screen-off TalkBack review or sudden-power-loss durability proof. Accessibility
labels/order/focus with TalkBack enabled are device-proven; speech quality needs
a human device review. No profile editing, backups, logging, estimates or live
release are claimed. The build workflow creates a local commit and never pushes.

## Historical checkpoint evidence (superseded)

The following was recorded on 9 October before continuation. At that checkpoint
the feature remained on the counter default and the listed device gates were open.

| Check | Result |
|---|---|
| `flutter analyze` | Pass — no issues found. |
| `flutter test` | Pass — 64 tests, 0 failures; covers model, repository, BLoC, widget and counter/theme behavior. |
| `dart format --output=none --set-exit-if-changed lib test integration_test` | Pass — 41 files checked, none changed. |
| `cd android && ./gradlew :app:compileDebugAndroidTestKotlin :app:lintDebug` | Pass — native instrumentation sources compile and Android lint completes. |
| Pixel 3a API 33 install | Blocked: universal APK was 147 MB; emulator had 527 MB free and refused install. |
| Pixel Tablet API 35 draft flow | Pass: arm64 APK, `BASELINE_PHASE=draft`, `--keep-app-running`; flow reached step 3, persisted an encrypted draft, and wrote three screenshots under ignored `build/sprint1-evidence/`. |
| Pixel Tablet completion phase | Blocked: rebuilding with a different compile-time phase required an APK update. Android lacked enough temporary space, so Flutter uninstalled/reinstalled the app and the draft was lost. The completion test then failed at its expected-resume check. No completion behavior is claimed as device-proven. |
| Historical API 33 native storage execution | Saved XML records 11 storage-test passes, zero failures/errors, and one skipped process test. Located during plan reconciliation; not rerun in this session and not yet reproduced against the build under review. |
| Android process-interruption execution | Pending: the saved connected run skipped `ProtectedBaselineProcessTest` because no explicit scenario argument was supplied. Run its host-driven prepare/interruption/verifier sequences separately. |
| API 24 device execution | Pending: no local execution evidence or installed API 24 image. Android lint is separate compatibility evidence. |
| Android accessibility, lifecycle and offline scenarios | Pending: no TalkBack/reduced-motion review, force-stop recovery, timezone change or airplane-mode run. |

The first Android test compile found AndroidX Test version inconsistency between
Flutter's `integration_test` runtime and the app instrumentation configuration.
The debug runtime and test runner now both resolve AndroidX Test Runner 1.6.2;
this keeps the test dependencies out of release configuration. The subsequent
instrumentation compile and lint passed.

The Pixel Tablet draft screenshot shows the optional measurement step with
unknown values left blank and a saved-draft indicator. Three screenshots are in
the ignored build evidence directory. The Pixel 3a had 5.8 GB total `/data` and
527 MB free; trimming caches freed only 27 MB. The Pixel Tablet had 590 MB free
before the first install; later APK replacement failed for space. Both emulators
were stopped after checks. Retry the completion and review phases, then run
`connectedDebugAndroidTest`, on a disposable emulator with enough update space.
Do not promote the product route until device checks and remaining Sprint 1
criteria are recorded.

## Historical native evidence reconciled during planning

The saved report
`build/app/outputs/androidTest-results/connected/debug/TEST-Tspm_Sprint1_API33(AVD) - 13-_app-.xml`
records `tests=12`, `failures=0`, `errors=0`, `skipped=1` at
`2026-10-09T05:52:26` UTC (11:22:26 IST). Eleven
`ProtectedBaselineStoreTest` cases passed; the process-interruption case skipped.
The accompanying textproto identifies UTC. These ignored local artifacts are
historical evidence, not tests executed by the planning review. This corrects
the previous blanket statement that native instrumentation had never executed;
it does not prove every native guarantee or identify the source revision tested.

At that checkpoint, remaining evidence followed section 9 of the technical plan.
The final results above close device recovery, completion/reopen,
minimum-platform coverage and emulator accessibility gates.

## Checkpoint checks, 9 October 2026

Before committing the existing implementation, the current session reran:

- `flutter analyze` → `No issues found! (ran in 2.1s)`.
- `flutter test` → `+64`, `All tests passed!`, zero failures.
- `dart format --output=none --set-exit-if-changed lib test integration_test test_driver`
  → 42 files checked, zero changed.

The first attempts could not write the SDK cache under the sandbox; approved
retries passed. Native builds and device scenarios were not rerun for this
checkpoint. The device limitations above remain open.
