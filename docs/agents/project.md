# Project configuration

Project facts read by the Flutter Engineering Kit skills. Update this file when the app's real stack changes.

## Identity

| Field | Value |
|---|---|
| App display name | Flutter Demo (placeholder) |
| Dart package | `tspm` |
| Android application ID | `com.example.tspm` (placeholder) |
| Platforms present | Android (minimum API 23) |
| Repository remote | Not configured in this workspace |

## Environment

| Field | Value |
|---|---|
| Flavors | None |
| Backend and integrations | None wired |
| Safe verification surface | Widget tests only; no backend or real data |
| Design source | Confirmed product plan in `docs/specs/tspm-product-plan.md`; design language in `docs/agents/design.md`; draft vision in `docs/specs/product-vision.md` |
| Issue tracker | None; use `docs/specs/` for specs |
| Test account | None |
| Startup gates before `runApp` | Flutter binding initialization and Android edge-to-edge system UI setup; no external startup gates |

## Architecture

| Field | Current value |
|---|---|
| Logic seam | `Bloc<Event, State>` (`lib/features/counter/bloc/`) |
| Logic test tool | `bloc_test` |
| Widget-test wrapper | `BlocProvider` |
| Dependency injection | Constructor injection as features need collaborators |
| Serialization | Hand-written unless a feature justifies code generation |
| Navigation | `AppRouter.onGenerateRoute` |
| Data return contract | Reads `Future<T?>`; writes `Future<Either<Failure, T>>` when repositories exist |
| Sizing strategy | Logical-pixel tokens plus layout breakpoints |
| Theme | `AppTheme.light` / `AppTheme.dark` in `lib/core/theme/`; explicit light default in `MyApp`; Material 3; typed `AppChartTheme` chart colors |
| Barrel | `lib/core/router/exports.dart` |
| Other deviations | Keep dependencies feature-driven; no backend is connected |

## Documents

| Purpose | Location |
|---|---|
| Specs and acceptance criteria | `docs/specs/` |
| Domain glossary | `CONTEXT.md` (create when domain terms are settled) |
| Architecture decisions | `docs/adr/` |
| Design language | `docs/agents/design.md` (settled direction and proposed visual defaults; device review pending) |
| Visual exploration and detailed brief | `docs/specs/tspm-design-exploration.md`; current concept in `docs/design/tspm-visual-data-directions.html` (burgundy/sand selected; visual-first composition review pending); original alternatives retained in `docs/design/tspm-design-directions.html` |
| Product plan and acceptance criteria | `docs/specs/tspm-product-plan.md` (confirmed product handoff; release scope source) |
| Product vision | `docs/specs/product-vision.md` (draft; not implementation acceptance criteria) |

## Verification

| Field | Value |
|---|---|
| Integration harness | None |
| Known test baseline | Before theme foundation: `flutter test` passed (+1, -0). |
| Current verified checks | 1 October 2026: formatting clean; `flutter analyze` no issues; `flutter test` +12, -0. Global system-bar fix also checked by before/after screenshots on Android 13 emulator (no integration-test harness). |
| Commands | `flutter pub get`; `dart format .`; `flutter analyze`; `flutter test` |

The app has no API, authentication, analytics, push, maps, or payment integrations yet. Do not infer them from the starter scaffold.
