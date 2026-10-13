# TSPM Phase 1 / Sprint 1: onboarding and recoverable local profile

**Status:** scope confirmed; implementation and emulator acceptance completed 2026-10-13 · **Original date:** 2026-10-07

**Start:** 9 October 2026, confirmed by owner. **Duration:** two weeks. **Estimate:** 21 points, provisional. **Review:** Android emulator demo against the numbered criteria below.

Sources: [project proposal, revision 1](../vault/proposal.md), [confirmed product blueprint](tspm-product-plan.md), [design language](../agents/design.md), and [project configuration](../agents/project.md).

Outcome: product onboarding is the startup default and the explicit counter route remains.
[Verification](tspm-sprint-1-verification.md) maps criteria 1–14 to actual checks,
device dates and limits; physical-device, audible TalkBack and approved pixel-baseline
reviews are not claimed.

## Goal and boundary

An adult can establish a baseline, leave optional answers unknown, close the app mid-flow and resume, complete onboarding and review the saved profile. Deliver a minimal product landing state that acknowledges setup completion and explains that trends require future logging. Its visible actions must work; do not add inactive logging/chart navigation.

Use real protected local persistence. There is no endpoint or fixture repository for saved user data. Preserve the counter route and its behavior during this increment. Daily logging, History, numerical estimates, interactive charts, export/import and permanent consumer branding belong to later phases.

## Onboarding sequence

| Step | Content | Required to continue |
|---|---|---|
| 1. Purpose, privacy and units | Explain observations versus estimates and local storage; choose kg/lb and cm/in, initially kg/cm | Unit selections have defaults |
| 2. Required baseline | Age, explained equation sex input, height and starting weight with editable local date/time | Adult age, equation input and valid height/weight/date/time |
| 3. Optional measurements | Waist, neck, relevant hip circumference and externally obtained body-fat percentage with source | None; unanswered values stay unknown |
| 4. Optional activity | Activity level, typical steps, training frequency/type and rest days | None; no guessed activity facts |
| 5. Goal and applicability | Loss or maintenance intent; goal weight/rate where relevant; optional body-fat milestone; pregnancy/breastfeeding applicability; explain which future estimates the supplied inputs can support | Goal intent; loss goal requires its weight and one of the blueprint's rate choices |

Maintenance does not require a lower target weight or a loss rate. Loss rates offered are 0.25%, 0.5%, 0.75% and 1.0% bodyweight/week. Applicability can remain unanswered/unknown; preserve that state. The final preview explains availability and limitations without displaying unimplemented numerical estimates or suggested calorie ranges.

## Numbered acceptance criteria

1. **First run:** A user can enter the product onboarding route and complete the five steps in the stated order. Each step has a clear purpose, progress indication and labeled next/back actions. The product route is developed alongside the counter; default-route promotion requires the flow and persistence checks to pass.
2. **Required baseline:** Completion requires integer age of at least 18, equation input, finite positive height and weight, a valid starting measurement date/time and goal intent. Under-18 input receives an explanation of the adult-only scope and cannot complete onboarding. Explain the equation input as a model parameter without inferring gender identity.
3. **Input confirmation:** Height outside 100–250 cm or starting weight outside 25–350 kg triggers explicit confirmation after conversion to canonical units. Declining preserves the entered value for correction; confirming permits it. Zero, negative and nonfinite physical values are rejected with a field message. These bands are input confirmation thresholds and do not establish eligibility for later calculations.
4. **Optional answers:** A user can skip all optional baseline fields. Saved records retain unknown values; they do not replace missing steps, training, body fat or circumferences with zero or an assumed activity level. Supplied body-fat values retain their source and remain reported observations.
5. **Units:** Onboarding initially uses kg/cm and offers lb/in. Changing units preserves the physical quantity, and reopening restores the preference. Persist canonical kg/cm together with the originally entered units; unit changes do not create additional observations.
6. **Time provenance:** The starting weight retains its original instant, selected local calendar day and UTC offset. Editing its date/time is possible before completion. Reopening after a device time-zone change does not move the saved observation into a different local day.
7. **Goal and applicability:** Initial loss/maintenance intent and applicable goal fields persist. Pregnancy/breastfeeding yes or unanswered/unknown is retained explicitly. The completion summary explains that automated weight-loss targets are withheld in those states. No automated target is calculated in this sprint for any user.
8. **Back and drafts:** Going back, leaving onboarding or backgrounding preserves entered answers. Reopening after process death resumes at the last saved step with its saved answers. Draft-save failure is visible and does not claim that the draft was persisted. Drafts remain separate from committed profile/observation records.
9. **Completion:** Completing onboarding commits the profile, starting observation and initial goal intent consistently, marks setup complete and visibly confirms success. Repeated taps cannot create duplicate starting observations or goals. A failed commit leaves onboarding incomplete and retains the answers for retry.
10. **Landing and profile review:** After completion, reopening the product route reaches the minimal landing state rather than restarting onboarding. The user can inspect the saved baseline, units and goal intent in Profile. The landing shows no fabricated trend, energy gap, progress percentage, confidence score or calculation. It offers a working action to review the profile.
11. **Offline and protection:** The complete flow and profile review work without a network connection, account or integration permission. Profile, health observations and drafts are encrypted at rest using device-keystore-backed protection. Reopening reads real saved records rather than illustrative prototype data.
12. **Storage failure:** A failed read or save names the operation and offers retry. Existing successfully loaded content stays visible when available; unsaved input remains available. Corrupt or unsupported saved data is not silently reset or overwritten. Recovery must not claim backup restoration because backups are outside this sprint.
13. **Accessible presentation:** Onboarding, landing and Profile use the shared light-default burgundy/sand theme and coordinated dark theme. Controls have labels, visible pressed/focus states and accessible touch targets. At 200% text scaling, essential fields and actions remain reachable without clipped meaning. Screen-reader order follows the form; reduced motion preserves feedback and does not delay navigation.
14. **Counter regression:** The existing counter route remains runnable with its increment behavior intact throughout Sprint 1. Its shared theme and system-bar policy continue to apply.

Criteria 1–14 refine blueprint criteria 1, 2, 8, 16, 17 and 18 for this increment. They establish portions of those release criteria; backups, final Today, logging availability and integrated release verification remain later work.

## Work order and dependencies

| Order | Work package | Completion evidence |
|---|---|---|
| 1 | Plan the profile, draft, starting-observation and initial-goal contracts; choose protected persistence and failure behavior | Contracts cover only this sprint, including atomic completion and schema version |
| 2 | Implement real persistence and onboarding state/resume behavior | Saved answers and completion state survive restart; failures retain input |
| 3 | Build the five steps, minimal landing and profile review using existing theme/routes | Criteria are demonstrable without fixture health data |
| 4 | Verify the full increment and demo it | Record criterion results, commands run, emulator scenarios and remaining failures |

Later sprint estimates and stories are selected at the preceding sprint close. Sprint 1 does not scaffold all future record families or build unused navigation destinations.

## State contract

These states apply to the numbered criteria above and retain the approved technical
plan's recovery behavior. They add no new product scope.

| Criteria | Loading or operation in progress | Empty or unanswered | Failure and next action |
|---|---|---|---|
| 1, 10 | Resolve protected storage before choosing onboarding or landing. A loaded landing remains visible during refresh. | Verified absence starts step 1; a saved draft resumes; a completed snapshot opens landing. No logs means no trend or numerical summary. | Failed initial read names the operation and offers Retry, without a writable replacement form. Failed refresh retains loaded content. |
| 2, 3 | Validation is local; persistence uses the draft status in criterion 8. | Required answers block advancement with field messages. | Invalid input stays editable; declining confirmation preserves the value. Confirmations apply only to that exact value. |
| 4–7 | Conversion and availability explanations are local; persistence uses criterion 8. | Optional answers stay unknown. Maintenance has no loss target/rate; unknown applicability stays explicit. | Supplied invalid optional values receive field messages. A body-fat value requires its reported source. Corrections never create another observation. |
| 8 | Keep the form usable during saves; distinguish Saving, Saved and Unsaved. Saved means the acknowledged revision. | A new draft has unit defaults and unknown optional answers. | Retain edits and offer Retry. After a failed exit flush, permit staying or explicitly leaving with an unsaved warning. Reopening loads the last valid committed snapshot. Recovery is promised for acknowledged edits; uncommitted pending files are never promoted. |
| 9 | Freeze the candidate and block duplicate submissions while committing. | Incomplete required answers remain in onboarding with validation messages. | A known uncommitted failure permits retry or correction. An uncertain outcome retains the candidate and requires reconciliation before editing; success requires acknowledgment. |
| 11, 12 | Offline is normal operation, with no account or connection loading state. | Only verified absence means no saved records. | I/O, key, corruption and version errors are failures, never absence. Retry preserves data; reset and backup restoration are unavailable. |
| 13, 14 | Labels, focus, reachable actions and reduced-motion feedback apply in every state. Counter increments are immediate. | Unknown values are labeled; a fresh counter starts at zero. | Large text keeps errors and recovery actions reachable. The counter works independently of baseline storage success. |

## Testing decisions

Retain the approved seams: model/codec validation and provenance; repository
absence/failure and replace semantics; BLoC events/revisions/completion retry;
page widgets and typed routes; the real Android store and app lifecycle.
Mock channel tests prove Dart behavior, not encryption or native durability.

Criteria 2–7 and state/repository portions of 8, 9 and 12 reach unit/state tests.
Visible copy, validation and actions reach widget tests. Criteria 1, 5, 6 and
8–14 additionally need integrated Android evidence for persistence, reopen,
offline, system interaction and accessibility. No API or account blocks that
evidence; use a disposable emulator with enough installation/update space.
No approved pixel baseline exists, so goldens are not an acceptance claim.

## Assumptions and open questions

No unanswered product question blocks continuing the approved scope. The start
is confirmed as 9 October 2026; 21 points remains a provisional estimate.
Activity choices, positive loss-target validation, separate applicability answers
and the displayed resolved DST offset are owner-approved defaults in the technical
plan. Selecting the other occurrence of a repeated DST time is deferred. Native
durability and accessible presentation require evidence, not assumptions of success.

## Out of scope

- Daily logging, History, charts, numerical estimates, calorie suggestions,
  trend/confidence scores and progress percentages.
- Profile editing after completion, backup/export/import, reset/delete-all,
  accounts, sync and integrations.
- Permanent consumer branding, store publication and a dashboard with illustrative data.
- Additional record families for later sprints, selection of both occurrences
  of a repeated DST time and sudden device-power-loss guarantees.

## Continuation from the checkpoint

The baseline models, protected store, repository, BLoC, five-step UI and review
routes exist at checkpoint `e670171`. Continue on `codex/sprint-1-next`; resolve
the remaining acceptance gaps rather than regenerating the feature. The approved
[technical plan](tspm-sprint-1-technical-plan.md) specifies the remaining sequence;
the [verification report](tspm-sprint-1-verification.md) owns actual evidence.

## Sprint close evidence

Implementation verification must cover first run, all-optional-skipped completion, loss/maintenance selection, applicability unknown/yes, unit conversion, outlier confirmation, mid-flow process death, timezone preservation, duplicate completion, read/save failure and counter regression. Include Android emulator restart/offline scenarios, large text and screen-reader review. Run relevant formatting, analysis and tests and record actual outcomes; no check is claimed as run by this planning document.

Handoff: run `/fk-build` with this spec and `tspm-sprint-1-technical-plan.md` to
continue the existing implementation and complete its acceptance gates. This
planning pass changes documents only.
