# Project configuration

Project facts read by the Flutter Engineering Kit skills. Update this file when the app's real stack changes.

## Identity

| Field | Value |
|---|---|
| App display name | Android launcher: `tspm`; in-app title: Flutter Demo (placeholders; consumer branding deferred) |
| Dart package | `tspm` |
| Android application ID | `com.example.tspm` (placeholder) |
| Platforms present | Android only; `flutter.minSdkVersion` currently resolves to API 24 in the installed Flutter SDK |
| Repository remote | `git@github.com:kratagyaagarwal2262/tspm.git` |
| Ownership | Owner's existing app; history contains four commits by Kratagya; proposal identifies it as the owner's product |

## Environment

| Field | Value |
|---|---|
| Flavors | None |
| Backend and integrations | None wired |
| Safe verification surface | Unit/widget tests, Android instrumentation and an `integration_test` driver using local-only data. A disposable emulator is required; no backend or account |
| Design source | Confirmed product plan in `docs/specs/tspm-product-plan.md`; design language in `docs/agents/design.md`; draft vision in `docs/specs/product-vision.md` |
| Issue tracker | None; sprint criteria and feedback in `docs/specs/`, proposal in `docs/vault/`. GitHub remote exists, but `gh auth status` is signed out |
| Sprint cadence | Two weeks; Android emulator demo at close. Sprint 1 starts 9 October 2026, confirmed by owner |
| Test account | None |
| Startup gates before `runApp` | Flutter binding initialization and Android edge-to-edge system UI setup; no external startup gates |

## Architecture

| Field | Current value |
|---|---|
| Logic seam | `Bloc<Event, State>` for counter and baseline (`lib/features/{counter,baseline}/bloc/`) |
| Logic test tool | `bloc_test` with `flutter_test`; repository and model tests use `flutter_test` (`test/features/baseline/`) |
| Widget-test wrapper | `MyApp` for app and route tests; `BlocProvider<BaselineBloc>` on the baseline route |
| Dependency injection | `BaselinePage` accepts a repository and creates one BLoC; counter page creates its BLoC directly |
| Serialization | Hand-written strict, versioned JSON in `BaselineCodec` (`lib/features/baseline/model/baseline_snapshot.dart`) |
| Navigation | `AppRouter.onGenerateRoute` |
| Data return contract | Baseline reads `Future<Either<BaselineFailure, BaselineSnapshot?>>`; writes return `Either<BaselineFailure, Snapshot>`. Only a successful read may report absence (`lib/features/baseline/repo/baseline_repository.dart`) |
| Sizing strategy | Logical-pixel `AppDimensions` and unscaled `AppTextStyles`; adaptive breakpoints are planned for product layouts |
| Theme | `AppTheme.light` / `AppTheme.dark` in `lib/core/theme/`; explicit light default in `MyApp`; Material 3; typed `AppChartTheme` chart colors |
| Barrel | `lib/core/router/exports.dart` |
| Other deviations | Keep dependencies feature-driven; no backend is connected |

## Documents

| Purpose | Location |
|---|---|
| Specs and acceptance criteria | `docs/specs/` |
| Project memory | `docs/vault/`; start with `index.md` and `memory.md` |
| Project scope and delivery roadmap | `docs/vault/proposal.md` (revision 1 draft for review; confirmed product blueprint remains the behavior source) |
| Phase 1 / Sprint 1 | `docs/specs/tspm-sprint-1.md` (onboarding and recoverable local profile; two-week cadence and scope choices confirmed 7 October 2026) |
| Sprint 1 technical sketch | `docs/specs/tspm-sprint-1-technical-plan.md` (owner-approved 9 October 2026; implementation in progress; see ADRs 0001–0002) |
| Sprint 1 verification | `docs/specs/tspm-sprint-1-verification.md` |
| Domain glossary | `CONTEXT.md` (create when domain terms are settled) |
| Architecture decisions | `docs/adr/` |
| Design language | `docs/agents/design.md` (settled direction and proposed visual defaults; device review pending) |
| Visual exploration and detailed brief | `docs/specs/tspm-design-exploration.md`; current concept in `docs/design/tspm-visual-data-directions.html` (burgundy/sand selected; visual-first composition review pending); original alternatives retained in `docs/design/tspm-design-directions.html` |
| Product plan and acceptance criteria | `docs/specs/tspm-product-plan.md` (confirmed product handoff; release scope source) |
| Product vision | `docs/specs/product-vision.md` (draft; not implementation acceptance criteria) |

## Verification

| Field | Value |
|---|---|
| Integration harness | `integration_test/baseline_test.dart` with `test_driver/baseline_driver.dart`; Android native instrumentation under `android/app/src/androidTest/` |
| Known test baseline | Before theme foundation: `flutter test` passed (+1, -0). |
| Current verified checks | 9 October 2026: `flutter analyze` clean; `flutter test` +64, -0; Dart formatting clean; Android instrumentation compilation and `lintDebug` pass; Pixel Tablet API 35 draft integration phase passed and saved screenshots. Completion phase remains unverified because updating the APK ran out of emulator space. See `docs/specs/tspm-sprint-1-verification.md` |
| Commands | `flutter pub get`; `dart format .`; `flutter analyze`; `flutter test` |

The app has no API, authentication, analytics, push, maps, or payment integrations yet. Do not infer them from the starter scaffold.

## Sprint 1 setup boundary

Use `docs/specs/tspm-sprint-1.md` for the five-step onboarding, recoverable draft,
protected local profile, minimal landing and profile-review criteria. Its implementation is
in progress under `lib/features/baseline/` and `lib/core/services/protected_baseline_store.dart`;
Android storage is implemented in `ProtectedBaselineStore.kt`. The Pixel Tablet draft phase passed,
but completion and remaining device acceptance are pending because the emulator lacked space to
update the integration APK. Preserve the counter route.
No API, fixture health data, logging, charts, backups or numerical estimates are added in Sprint 1.

Design is written-spec based; no Figma node or API contract exists. Reuse the existing shared
theme and design language. No human-fetched integration keys or test credentials are needed.
