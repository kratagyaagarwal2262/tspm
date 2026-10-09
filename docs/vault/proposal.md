# TSPM: project scope and proposal

**Status:** draft for review · **Revision:** 1 · **Date:** 2026-10-07

## Revision history

| Rev | Date | Change | Why | Agreed by |
|---|---|---|---|---|
| 1 | 2026-10-07 | Project modules, phased roadmap and Sprint 1 scope | Establish the basis for upcoming sprint plans and acceptance criteria | Owner confirmed the planning choices in chat; document review pending |

This proposal organizes delivery of the [confirmed product blueprint](../specs/tspm-product-plan.md). The blueprint controls product behavior and release boundaries; this proposal controls module boundaries, delivery order and planning estimates. Each sprint gets its own numbered acceptance criteria in `docs/specs/`. A change to either agreed scope or behavior requires a dated revision and an estimate of its effect.

## Objective

Build an Android app for an adult who wants to understand body change through their own weight, intake, expenditure, activity and measurement records. Preserve the distinction between observations, entered values, calculated estimates and inferred trends, and expose the evidence and uncertainty behind interpretations. The job a person opens TSPM to do is: **understand what is changing and whether their current plan appears to be working.**

## Users

| Role | What they come to do | Needs an account |
|---|---|---|
| Adult tracking themselves | Record, correct and interpret their own data; explore loss or maintenance goals | No |
| Adult with pregnancy/breastfeeding applicability or unknown applicability | Record and inspect history with automated weight-loss targets withheld | No |

The first release is for ages 18+. It is a personal informational tool; clinical workflows and multiple people sharing a profile are outside scope.

## Deliverables

- An English Android app with full offline operation, protected local records and the capabilities below.
- Repository source, versioned scope, sprint acceptance criteria, methodology documentation and verification records.
- An Android emulator demo at the end of each two-week sprint, tied to that sprint's criteria.
- A release candidate after all first-release criteria pass and owner acceptance is recorded. Store publication follows a separate owner release decision; consumer naming and store assets must be settled before publication.

The existing counter and shared light/dark theme are the starting implementation. The theme foundation is completed prior work, not a Sprint 1 deliverable.

## Modules

Point estimates are relative planning estimates, not elapsed days or committed delivery dates. Sizes follow S ≤13 points, M 14–34, L 35–60.

### M1. Onboarding and local profile

**Problem:** A person cannot establish a baseline or resume setup.

**Existing:** Counter app and shared theme; no product profile or persistence.

**Proposed:** Five-step onboarding, optional baseline answers, unit preferences, goal intent, applicability answers, protected local profile and draft recovery, profile review and a minimal completion landing state.

**Size:** M · 21 points. **Design:** [design language](../agents/design.md) and [current concepts](../design/tspm-visual-data-directions.html). **First increment:** [Sprint 1](../specs/tspm-sprint-1.md).

### M2. Backup and local data controls

**Problem:** A person cannot recover, transfer, inspect or safely clear their data.

**Existing:** No persisted product records or backup flow; Sprint 1 supplies the first protected profile store.

**Proposed:** Versioned records, baseline/profile edits, passphrase-protected export, integrity-checked import preview and transactional replacement, confirmed delete-all-data, and recovery from storage or archive failures. Records and drafts remain encrypted at rest.

**Size:** M · 34 points. **Design:** Profile and recovery rules in the design language; detailed screens designed when this phase is planned.

### M3. Daily logging and History

**Problem:** A person cannot record daily evidence or correct past records.

**Existing:** No logging or History feature.

**Proposed:** Independent Weight, Intake, Expenditure, Activity and Measurements forms; saved drafts; multiple observations per day; day-grouped History; source and time labels; edit/delete. Preserve original local days and offsets, missing-versus-zero semantics and the separation of session expenditure from daily total expenditure.

**Size:** M · 34 points. **Design:** Quick add and History rules in the design language.

### M4. Calculations and Today

**Problem:** Records alone cannot explain the supported direction, energy comparison or uncertainty.

**Existing:** No product calculations or dashboard; chart color roles exist.

**Proposed:** Versioned baseline estimates, observed weight summaries, guarded personal time normalization, complete-day energy arithmetic and uncertainty-aware comparisons. Today presents Current, Trend, Intake, Expenditure, Deficit, Target, Progress and Confidence with nearby method/source disclosures. Historical corrections invalidate or recompute dependent results.

**Size:** M · 34 points. **Design:** Visual-first Today concepts. Calculation methods and gates remain those in the product blueprint.

### M5. Trends and six chart families

**Problem:** A person cannot explore relationships over a chosen period.

**Existing:** Theme chart colors only; no charts or chart interaction.

**Proposed:** Weight, energy, deficit, body composition, activity and target-trajectory charts; date ranges, exact-value tooltips, accessible legends and source/method disclosures. Preserve gaps and distinguish observed, estimated and inferred series through labels and marks as well as color.

**Size:** M · 21 points. **Design:** Chart contracts in the product blueprint and design language.

### M6. Goals and what-if

**Problem:** A person cannot compare a proposed plan with the current plan or accept a supported target change.

**Existing:** No goal calculation or comparison; Sprint 1 captures initial goal intent.

**Proposed:** Loss and maintenance goals, supported rounded intake ranges, dated goal versions, actual progress from supported trends and an exploratory current-versus-proposed comparison. Applying a suggestion requires acceptance. Unsupported conditions withhold automated targets while preserving logging.

**Size:** M · 21 points. **Design:** Goal and what-if rules in the design language.

### M7. Release quality and acceptance

**Problem:** Individually working features do not establish a dependable complete app.

**Existing:** Counter/theme tests and a documented Android 13 emulator appearance check; no integration harness or product verification.

**Proposed:** Complete offline scenarios, large-text and screen-reader usability, reduced-motion behavior, both themes, Android lifecycle/storage recovery, data controls and owner acceptance of the release candidate. Accessibility and failure handling are required in every increment; this phase checks the integrated product.

**Size:** M · 21 points. **Design:** Review implemented screens on Android against the shared design language.

## Technical approach

Use the actual Flutter/Dart stack recorded in [project configuration](../agents/project.md): BLoC for behavior, constructor injection, current routing and hand-written serialization unless a capability justifies another mechanism. Android API 23 is the current minimum. Existing secure-storage support is available; health records and drafts require device-keystore-backed protection. Choose the concrete storage format and migration contract during Sprint 1 implementation planning, before storing real records.

There is no API, backend, account, cloud sync or integration permission in this release. All product data is local. Persist canonical physical quantities with original units, instants, selected local days, offsets and provenance. Derived values carry their inputs, method version, period, coverage and confidence. Add dependencies only for a demonstrated capability.

Keep the counter runnable while developing the product route. Promote the product home to the default route only after its flow and persistence pass the relevant checks. The existing prototype contains illustrative data and is a design reference, not a source of real records or calculation results.

## Assumptions and confirmed decisions

| Decision or assumption | Owner | Status |
|---|---|---|
| First release is Android, English, offline and without an account | Product owner | Confirmed product blueprint |
| Sprint 1 is onboarding plus recoverable local profile; logging, charts and backups come later | Product owner | Confirmed in chat, 2026-10-07 |
| Sprints last two weeks and end with an Android emulator demo | Product owner | Confirmed in chat, 2026-10-07 |
| TSPM remains the internal name; permanent consumer branding is deferred | Product owner | Confirmed in chat, 2026-10-07 |
| Initial units are kg/cm; lb/in are available | Product owner | Confirmed in chat, 2026-10-07 |
| Height outside 100–250 cm or weight outside 25–350 kg requires confirmation; these are not hard limits | Product owner | Confirmed in chat, 2026-10-07; operational input checks, not model applicability limits |
| Capacity is approximately 20 points per two-week sprint | Planning coordinator | Unmeasured planning assumption; replace with observed capacity |
| Existing methodology needs documented input ranges, uncertainty and expert review before release | Product owner owns arranging review | Required by confirmed product blueprint; completion not yet established |

## Out of scope for the first release

- iOS, web, desktop, an admin portal, multi-user profiles, accounts and cloud sync.
- Wearable/health-platform imports, meal-level logging and automatic device expenditure collection.
- Weight-gain goals, reverse-TDEE cards, plateau alerts and future-weight forecasting.
- Clinical diagnosis, treatment plans, automatic calorie-target changes and precise goal-date predictions.
- Payments, subscriptions, advertising, push notifications and additional languages.
- Permanent consumer branding and store assets in Sprint 1. These require a later owner decision before publication.

## Phases and provisional timeline

A **phase** groups a product capability; a **sprint** is a two-week delivery increment. Phase 1 is Sprint 1. Larger later phases can span two sprints. Each later sprint is planned against the current proposal revision, the blueprint and the result of the preceding sprint.

| Phase | Planned sprints | Modules | Points | Acceptance gate |
|---|---|---|---:|---|
| 1. Establish a baseline | 1 | M1 | 21 | Adult onboarding completes/resumes, protected profile survives restart, empty landing is honest, counter stays runnable |
| 2. Control and recover data | 2–3 | M2 | 34 | Export/import round trip; wrong passphrase/corruption preserves existing data; edits and confirmed deletion work |
| 3. Collect and correct evidence | 4–5 | M3 | 34 | All five forms and History; multiple weigh-ins; draft recovery; original day/offset; missing-versus-zero; no expenditure double counting |
| 4. Calculate and interpret | 6–7 | M4 | 34 | Formula/method gates, sparse and conflicting evidence, correction/recompute, honest Today; promote home only after verification |
| 5. Explore trends | 8 | M5 | 21 | Six chart families, gaps, ranges, tooltips, accessible legends and source disclosures |
| 6. Compare and accept plans | 9 | M6 | 21 | Supported loss/maintenance ranges, applicability gates, accepted versions and what-if without mutation |
| 7. Accept the release | 10 | M7 | 21 | Integrated offline recovery scenarios, Android usability, accessibility, model review and owner acceptance |
| **Total** | **10 provisional sprints** | | **186** | All 18 blueprint release criteria covered |

Capacity is a guess of 20 points per sprint. The roadmap allows partial-module increments and does not commit exact story allocation for Sprints 2–10. At two weeks per sprint it is approximately 20 weeks of development, followed by a provisional one-week owner acceptance window. No calendar start date or store publication date is committed. Re-estimate after each closed sprint and firm up the timeline after the second; use the latest three closed sprints for measured capacity once available.

## How we work

Before each sprint, select a bounded user outcome, write numbered criteria including failure/empty/recovery states, map them to the blueprint, and estimate the selected work. Do not add later-phase behavior merely because its data structure could support it. Record demo outcomes and checks actually run at sprint close.

Feedback that contradicts this proposal's agreed revision or an agreed criterion is a bug. A new capability or changed behavior is a change request and receives a scope revision, estimate and timeline effect before implementation. Until a tracker is selected, sprint plans and feedback records live in `docs/specs/`.

This is the owner's product. Client-provided materials, agency warranty and commercial terms are deliberately removed from this revision.
