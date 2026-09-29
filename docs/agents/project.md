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
| Startup gates before `runApp` | None |

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
| Barrel | `lib/core/router/exports.dart` |
| Other deviations | Keep dependencies feature-driven; no backend is connected |

## Documents

| Purpose | Location |
|---|---|
| Specs and acceptance criteria | `docs/specs/` |
| Domain glossary | `CONTEXT.md` (create when domain terms are settled) |
| Architecture decisions | `docs/adr/` |
| Design language | `docs/agents/design.md` (settled direction and proposed visual defaults; device review pending) |
| Product plan and acceptance criteria | `docs/specs/tspm-product-plan.md` (confirmed product handoff; release scope source) |
| Product vision | `docs/specs/product-vision.md` (draft; not implementation acceptance criteria) |

## Verification

| Field | Value |
|---|---|
| Integration harness | None |
| Known test baseline | Not recorded during kit installation |
| Commands | `flutter pub get`; `dart format .`; `flutter analyze`; `flutter test` |

The app has no API, authentication, analytics, push, maps, or payment integrations yet. Do not infer them from the starter scaffold.
