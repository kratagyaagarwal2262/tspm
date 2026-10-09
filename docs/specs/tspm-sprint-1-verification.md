# Sprint 1 verification (in progress)

Date: 9 October 2026. The feature implementation remains on the counter default
route; product-default promotion is not part of this verification yet.

| Check | Result |
|---|---|
| `flutter analyze` | Pass — no issues found. |
| `flutter test` | Pass — 64 tests, 0 failures; covers model, repository, BLoC, widget and counter/theme behavior. |
| `dart format --output=none --set-exit-if-changed lib test integration_test` | Pass — 41 files checked, none changed. |
| `cd android && ./gradlew :app:compileDebugAndroidTestKotlin :app:lintDebug` | Pass — native instrumentation sources compile and Android lint completes. |
| Pixel 3a API 33 install | Blocked: universal APK was 147 MB; emulator had 527 MB free and refused install. |
| Pixel Tablet API 35 draft flow | Pass: arm64 APK, `BASELINE_PHASE=draft`, `--keep-app-running`; flow reached step 3, persisted an encrypted draft, and wrote three screenshots under ignored `build/sprint1-evidence/`. |
| Pixel Tablet completion phase | Blocked: rebuilding with a different compile-time phase required an APK update. Android lacked enough temporary space, so Flutter uninstalled/reinstalled the app and the draft was lost. The completion test then failed at its expected-resume check. No completion behavior is claimed as device-proven. |
| Android instrumentation execution | Not run: instrumentation sources compile, but connected native tests have not executed. |
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

## Checkpoint checks, 9 October 2026

Before committing the existing implementation, the current session reran:

- `flutter analyze` → `No issues found! (ran in 2.1s)`.
- `flutter test` → `+64`, `All tests passed!`, zero failures.
- `dart format --output=none --set-exit-if-changed lib test integration_test test_driver`
  → 42 files checked, zero changed.

The first attempts could not write the SDK cache under the sandbox; approved
retries passed. Native builds and device scenarios were not rerun for this
checkpoint. The device limitations above remain open.
