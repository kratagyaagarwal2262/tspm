# TSPM — personal metabolic analytics product blueprint

**Status:** Product decisions confirmed through the grill interview. This is a design and acceptance handoff; it does not claim the app has been built.

Companion documents: [shared vocabulary](../../CONTEXT.md) and [design language](../agents/design.md). The earlier [product vision](product-vision.md) remains background; this document controls release scope and acceptance criteria.

## 1. Product promise and release boundary

The app helps one person answer: **What is changing in my body, how strong is the evidence, and does my current plan appear to be working?** The reading order is **measure → normalize → calculate → compare → interpret**. A weight observation, an estimated fat change, and calorie arithmetic must never be presented as interchangeable facts.

| Release | Included |
|---|---|
| First release | Android; English; no account; full offline operation; onboarding; manual weight, intake, expenditure, activity and body-measurement logs; dashboard; six chart families; time-aware trends; loss and maintenance goals; what-if comparison; protected local data; passphrase-protected export/import. |
| Later implementation | Wearable imports, meal-level logging, weight-gain goals, reverse-TDEE cards, plateau alerts, and future-weight forecasting. Their methods are specified below so first-release records can support them. |

The first release is for adults 18+. A pregnant or breastfeeding user may log and inspect history, but receives no automated weight-loss calorie target. An unanswered pregnancy/breastfeeding question also withholds that target. This matches the applicability boundary of the [NIDDK Body Weight Planner](https://www.niddk.nih.gov/health-information/weight-management/body-weight-planner).

The current counter page remains runnable until the product home and its persistence pass verification. The product dashboard then replaces it as the default route.

## 2. Name and brand direction

| Candidate | Idea | Assessment |
|---|---|---|
| **Velltrace** | A refined, traceable record of change | Recommended working consumer name: analytical without sounding like a calorie counter. |
| **Avenline** | A longer path understood through a clear trend line | Softer and more editorial; meaning needs more explanation. |
| **Tallyform** | Measured inputs connected to body form | Clearer on function, but more utilitarian. |

Keep TSPM as the internal codename and the Dart package name during design. These candidates are creative proposals, not trademark, domain, or app-store clearance. Product copy is composed, specific and nonjudgmental: “Your trend is lower, though measurement times vary” rather than “You crushed your goal.”

## 3. Information architecture and core screens

| Destination | Primary question or action | Essential content |
|---|---|---|
| Onboarding | What can this app responsibly estimate for me? | Age, equation sex input, height, current weight, goal; full optional baseline questionnaire; units; pregnancy/breastfeeding applicability; explanation of estimates. |
| Today | Where am I, and what does the evidence suggest? | Dominant trend interpretation, current reading, eight metric roles expressed through compact visual groups, one plain-language insight, confidence and source links, quick add. |
| Quick add | What do I need to record right now? | Separate Weight, Intake, Expenditure, Activity and Measurements forms; each returns to Today or its originating screen. |
| Trends | What changed over time? | Six selectable chart families, time windows, point tooltips, legends, method/source information. |
| History | What was actually recorded? | Day-grouped timeline, all same-day observations, source labels, edit and delete actions, clear distinction between missing and zero. |
| Goal and what-if | Is the plan feasible, and what would a change imply? | Active goal version, suggested calorie range, assumptions, current-versus-proposed range and pace, accept-suggestion action. |
| Profile | What assumptions and data controls are active? | Baseline edits, preferred units, goal history, estimate methods, encrypted export/import, delete-all-data action. |

Today, Trends, History and Profile are the primary destinations. Incomplete onboarding opens first and resumes at the saved step. Leaving any form saves its draft; saving returns to the originating destination and visibly confirms the entry. The Android back gesture follows the same rule.

The complete onboarding questionnaire also asks for waist, neck and relevant hip circumference; an optional body-fat value and its source; activity level; typical daily steps; training frequency, type and rest days; goal weight; target weekly rate; and an optional target body-fat milestone. Unknown optional answers remain unknown rather than being replaced with guessed profile facts.

The onboarding sequence is: **(1)** purpose, local-data privacy and units; **(2)** required age, equation input, height and a timestamped starting weight; **(3)** optional body measurements and body-fat source; **(4)** optional steps/training pattern; **(5)** goal, pregnancy/breastfeeding applicability and a preview of available estimates. Each step can go back without losing answers.

## 4. Daily logging flow

1. **Open quick add.** The person picks one data type. There is no mandatory all-day form.
2. **Weight.** Default to the current local date and time, both editable. Allow multiple observations on one day. Capture kg/lb; optional fasting/fed, bathroom, clothing, workout and heavy-sweat conditions; optional travel, illness, menstrual-cycle or medication-change context; and a free note. Tags are context, never fixed kilogram corrections.
3. **Intake.** Capture a local calendar day and total kcal. Protein, carbohydrate, fat and fiber are optional daily totals. Entered kcal drives energy calculations. If macros imply a materially different total, show a nonblocking discrepancy note; do not rewrite either value. Meal entry is later scope.
4. **Expenditure and activity.** Capture one optional total daily expenditure with a source label such as “manual estimate” or “copied from device.” Steps and walking, running, cardio or strength sessions are separate activity facts. A session may include a source-labeled calorie estimate, but session calories are **not added** to a reported total expenditure.
5. **Measurements.** Capture dated waist, neck, chest, arm, thigh and hip circumferences plus optional externally obtained body-fat percentage with its method/source. Repeat measurements remain separate observations and are charted over time.
6. **Validate, save, correct.** Reject negative, nonfinite or structurally impossible values. Warn and request confirmation for plausible outliers; do not quietly clamp them. Editing or deleting a past entry recalculates dependent views. A failed save retains the draft and offers retry.

Store the original measurement instant and local UTC offset; group history and daily totals by the local date selected for the entry. Travel does not silently move an old measurement into another calendar day. Unit changes alter presentation, not the stored physical quantity.

## 5. Dashboard concept

The top of Today answers **“What is happening?”** with a trend-weight statement and direction, followed by one sentence of interpretation. Raw current weight sits beside it as the latest observation, labeled by time. Supporting visuals show **Current, Trend, Intake, Expenditure, Deficit, Target, Progress and Confidence** through an interactive weight chart, energy comparison, goal-progress track and coverage marks. Regions without enough evidence show “Not enough data” and the next useful action rather than a placeholder number.

An insight card can say: “Your 7-day trend is lower. Today’s higher reading was taken in the evening; there is not yet enough paired history to adjust for time of day.” A conflict card says that energy logs and observed trend disagree, then names possible explanations without ranking a cause the data cannot establish. The source/method control on each estimate reveals inputs, observation period and confidence basis.

Progress toward goal is based on a supported trend, not a single noisy weigh-in. Before a trend is ready, Today shows the goal and the next logging milestone instead of a progress percentage.

Illustrative Today layout **after sufficient history**, with all values explicitly labeled:

> **TREND** · approximately 76.4 kg · down 0.32 kg/week · Moderate confidence  
> **LATEST SCALE READING** · 76.8 kg at 20:30  
> **INTERPRETATION** · “Tonight's reading is higher than your trend. The time-of-day model suggests these readings are not directly comparable.”  
> **INTAKE** · 2,087 kcal entered today · **EXPENDITURE** · 2,430 kcal manual total  
> **ESTIMATED GAP** · 343 kcal deficit, based on those two entered values  
> **TARGET** · 0.5% bodyweight/week · **PROGRESS** · 42% of goal using trend

The screen does not show the illustrated gap if either daily input is missing. Every card can disclose its source and calculation method.

## 6. Data and provenance model

Persist canonical kg, cm, kcal and instants internally, alongside the unit and local offset originally entered. Every saved record has an ID, creation/update times and an origin. Distinguish these classes of values in types, labels and chart legends:

| Class | Meaning | Examples |
|---|---|---|
| Measured or reported | A reading supplied by a scale, tape, device or external test | Weight, waist, device body-fat reading; source retained. |
| Entered | A user statement, which may itself be an estimate | Calories eaten, manually estimated daily expenditure, condition tag. |
| Calculated estimate | A reproducible formula over supplied inputs | BMI, BMR, equation TDEE, energy gap, body-fat estimate. |
| Inferred trend | A statistical summary of repeated observations | Rolling weight trend, time-of-day adjustment, future reverse TDEE. |

| Record | Minimum fields and invariant |
|---|---|
| Profile | Age at profile date, equation sex input, height, unit preferences, baseline activity/steps/training, optional circumferences and body-fat source, pregnancy/breastfeeding applicability. The equation input is explained as a model parameter, not used to infer gender identity. |
| WeightObservation | Value, instant, original offset/local day, original unit, optional conditions/context/note, source. Multiple records per day are valid. |
| IntakeDay | Local day, entered kcal, optional protein/carbohydrate/fat/fiber grams, note, source. Missing record differs from recorded zero. |
| ExpenditureDay | Local day, total kcal, source and type. Total and active/workout expenditure are distinct types; only a total may drive daily deficit. |
| ActivityDay / Session | Local day, optional steps; session kind, duration and optional source-labeled expenditure. Activity calories never silently augment a daily total. |
| MeasurementObservation | Type, value, unit, instant/local day, method/source; later values do not overwrite baseline. |
| GoalVersion | Effective date, direction, goal weight, selected weekly rate, optional body-fat milestone, accepted target range. Older versions remain available in History. |
| DerivedMetric | Value or range, input IDs, model/version, period, coverage, confidence and explanation. Derived results are recomputed after an input edit. |

Drafts are local and separate from committed observations. Backups are versioned, integrity-checked, encrypted with a user passphrase, and imported transactionally so a wrong passphrase or corrupt file never replaces existing data. Local health records are encrypted at rest with a device-keystore-backed key. No network, sign-in, health-platform, camera, location or notification permission is required in the first release.

## 7. Calculation and interpretation model

### Baseline estimates

- **BMI:** kg divided by height in meters squared. Display as a calculated index, not a direct body-fat measure.
- **BMR:** use the [Mifflin–St Jeor equation](https://pubmed.ncbi.nlm.nih.gov/2305711/) with weight in kg, height in cm and age in years: 10 × weight + 6.25 × height − 5 × age + 5 for the male equation input, or the same expression − 161 for the female input. Estimated TDEE applies the selected activity level to BMR; typical steps and training inform the explanation, not a second additive calorie component. Show the chosen activity assumption.
- **Body fat:** when only age, height, weight and equation input exist, use the adult [Deurenberg BMI-based estimate](https://pubmed.ncbi.nlm.nih.gov/2043597/) as a broad, low-confidence range: 1.20 × BMI + 0.23 × age − 10.8 × male-indicator − 5.4. When waist is available, calculate [relative fat mass](https://pubmed.ncbi.nlm.nih.gov/30030479/) as a second method: 64 − 20 × height/waist + 12 × female-indicator, using the same length unit for height and waist. The indicator encodings differ between these formulas and must be tested. Show whether estimates agree; disagreement widens the presented range, while agreement does not by itself prove accuracy. Neck, hip and other circumferences remain tracked even when an estimator does not use them. A user-entered device or scan value stays separate from both formulas. Fat and lean mass inherit the body-fat range; never turn it into an exact composition reading.

### Weight and time of day

- Plot every raw observation at its actual time. Compute time since the previous reading, measurement frequency and morning/evening summaries for the detail view. For rolling summaries, form one daily representative as the median of that day's observations, adjusting observations to the reference time band only after normalization is ready. A windowed mean needs observations on at least 60% of its calendar days and always shows its actual coverage. Display 3, 7, 14 and 28-day windows, weekly averages, weight-change rate and percentage bodyweight change; acceleration/deceleration needs at least a 28-day window with adequate coverage. Do not connect a missing day as though it had been measured.
- The early trend is labeled provisional when weigh-in times vary. Personal time normalization begins only after at least **14 distinct weighing days**, including **six days with observations in two time-of-day bands** and at least **five observations in each compared band**. Estimate a within-person band offset from same-day differences, anchor to the user's best-sampled band, and show the reference band and data period. If coverage or stability falls below the gate after edits, withdraw the adjustment.
- Measurement conditions can explain why readings are less comparable, but do not create fixed corrections for bathroom use, workouts, sweat, water or glycogen. The 77.0 kg morning / 77.4 kg evening example must not be narrated as a 0.4 kg fat gain.

### Energy, goals and what-if

- For a day with both entered intake and a source-labeled **total** expenditure, estimated deficit = expenditure − intake. Without either daily value, the deficit is unknown. Equation TDEE remains a separate baseline estimate, not a silent fill for a missing day.
- Show 7, 14 and 28-day logged energy sums with complete-days/window-days coverage. A partial sum is labeled as such; missing days are never zero-filled or extrapolated without a separate, explicit model.
- Compare theoretical and observed weight change as **ranges with coverage and uncertainty**, using the published dynamic-model approach behind the [NIDDK Body Weight Planner](https://www.niddk.nih.gov/research-funding/at-niddk/labs-branches/laboratory-biological-modeling/integrative-physiology-section/research/body-weight-planner) rather than a fixed 7,700 kcal/kg conversion. If required model inputs or weight windows are insufficient, show the energy sum and withhold the expected-change comparison.
- Loss-rate choices are 0.25%, 0.5%, 0.75% and 1.0% of current body weight per week; maintenance is 0%. Suggested intake is a rounded **range** generated from the equation-TDEE assumption and a four-week dynamic-model scenario, with the assumptions shown. Withhold automated targets outside supported adult-model conditions or below the conservative 1,200 kcal/day floor noted in [NIDDK guidance](https://www.niddk.nih.gov/health-information/diabetes/overview/preventing-type-2-diabetes/game-plan). That floor is a minimum guardrail, not a claim that every target above it is suitable. Logging remains available. A later supported estimate may propose a new range, but the person must accept it.
- What-if compares current and proposed calorie ranges, their approximate weekly pace, and the assumptions that changed. It does not mutate the active goal or output a precise goal date. The trajectory chart likewise shows actual progress versus a goal marker, without a future-weight line.

These formulas are product-model choices for an informational app, not diagnoses. Before implementation release, document formula version, input range, uncertainty presentation and any population exclusions in tests and an expert review.

### Confidence policy

Confidence applies to a **specific interpretation**, never to the person or to the app as a whole. Show Low when a result depends mainly on a population equation, sparse logs or inconsistent measurement times. Show Moderate only when its minimum window and coverage gates are met and sources are identifiable. Reserve High for a stable, well-covered observed trend; a BMI-derived body-fat estimate cannot become High merely because it has more weight entries. The dashboard confidence indicator inherits the weakest evidence used by its headline interpretation and exposes the reason.

## 8. Chart and visualization system

| Chart | Launch series and visual rule | Empty or partial state |
|---|---|---|
| Weight | Raw observations as points; observed trend as a stronger line; normalized trend as a distinct labeled line only when ready; 3/7/14/28-day selection. | Show raw points first; explain why normalized trend is pending. |
| Energy | Entered intake versus source-labeled daily total expenditure; equation TDEE as a separate reference, never merged into the total series. | Missing daily values leave gaps. |
| Deficit | Complete-day deficit and 7/14/28-day cumulative sums with coverage. | Partial sums carry a visible coverage label. |
| Body composition | Weight and waist on separate axes/panels; estimated body-fat **range** as a band with method label; other measurement trends selectable. | Show individual measurements without drawing an unsupported trend. |
| Activity | Steps and manually logged walking, running/cardio and strength sessions; optional session calories labeled as estimates. | Invite an activity log; no fake zero days. |
| Target trajectory | Actual supported trend against goal marker and dated goal versions; no future line. | Show goal setup or trend-readiness prompt. |

All charts support a date-range selector, accessible legend, and point tooltip containing exact plotted date and values. A separate information control exposes source, method, coverage and confidence. Point taps do **not** open a full day-detail screen; History provides full underlying entries. Color is not the sole distinction between raw, estimated and inferred series: also use line style, markers and labels.

## 9. Plateau detection method — later phase

The detector may say **Possible plateau**, never “failure” or a confirmed physiological cause. Do not evaluate a single unchanged weigh-in. Gate evaluation on at least **28 calendar days**, **14 distinct weigh-in days**, sufficient time-comparable observations for a stable trend, and **21 days of intake entries** if energy adherence is discussed. Examine the 14-day slope against the 28-day trend, goal rate, measurement-time consistency, logged intake, expenditure-source quality and waist trend. If the slope's uncertainty still includes meaningful loss, or data coverage is weak, return **insufficient evidence** rather than a plateau label.

When evidence supports a possible plateau, show the observed trend, expected direction, confidence and several *possible* explanations such as logging error, expenditure uncertainty or temporary fluid variation. Do not identify water retention, glycogen or underreporting as a known cause. No automatic calorie-target change follows the alert.

## 10. Reverse-TDEE method — later phase

Use a rolling **minimum 28-day** window with at least **21 logged intake days**, **14 distinct weigh-in days**, and usable trend estimates near both ends. Infer the daily maintenance expenditure that best reconciles mean intake with modeled trend-weight change under a dynamic energy-balance model; do not equate one kilogram with one fixed calorie amount. Report an approximate range, data period, coverage, model version and Low/Moderate/High confidence. Compare it beside equation-based TDEE and earlier reverse-TDEE windows without replacing either.

Sparse intake, inconsistent measurement times, a recent sharp change in logging pattern, or a trend dominated by short-term noise suppresses the estimate and explains what more data is needed. Recompute after historical edits and refresh the displayed estimate no more often than weekly so the number does not appear to change meaningfully with each weigh-in.

## 11. UX states and recovery

| State | What the person sees | Action |
|---|---|---|
| First run | Short onboarding with saved progress and explanation of which inputs support which estimates. | Continue or resume. |
| No logs after onboarding | Profile-based estimates labeled as such; trend and deficit cards say what to log. | Add weight or intake. |
| Sparse or mixed-time weight | Raw observations and provisional summary; no personal time correction or fat-loss conclusion. | Continue logging at comparable times. |
| Missing intake or expenditure | Known value remains visible; deficit says unknown, with no zero placeholder. | Add the missing daily value. |
| Conflicting trend and energy | Side-by-side evidence and uncertainty; possible explanations phrased as possibilities. | Inspect sources or continue collecting data. |
| Save/storage failure | Existing content remains visible, failed action is named, unsaved draft remains intact. | Retry the specific save or restore from a backup. |
| Import failure | Wrong passphrase, invalid version or corrupt archive named without replacing current data. | Retry or choose another backup. |
| Unsupported goal/model | Explanation of applicability or range limit; manual logging stays available. | Adjust goal or use tracking without a target. |
| Deleted or filtered history | Clear distinction between no records and a filter hiding records. | Add data or clear filter. |

Loading indicators are local to the operation: a save marks its own control busy; reopening an already loaded dashboard keeps its last content visible. Delete-all-data requires explicit confirmation and is distinct from export. An import previews what it will restore before replacing current data.

## 12. Premium visual direction

The design is **light by default, calm, precise and premium**, with a coordinated dark counterpart. Following the 1 October 2026 design review, use warm paper surfaces, burgundy emphasis and sand accents in the default light theme, with a deep burgundy-and-sand dark counterpart, restrained borders, generous space and a limited type scale. The hero trend interpretation is expressed through an interactive weight chart with a concise explanation; compact energy and goal comparisons step down. Preserve the eight information roles without requiring eight repetitive text cards. Detailed charts borrow the clarity of a financial dashboard. Today uses one dominant weight chart and compact energy/goal visuals; deeper analysis stays in Trends. Keep gradients rare and never use gym clichés or motivational copy.

Expressive motion has a purpose: reveal a newly computed comparison, connect a quick-add sheet to its saved result, or show a what-if range changing. Frequent tab switches, keyboard opening and everyday chart scrubbing must remain responsive; motion never delays reading data. Reduced-motion settings remove travel, scale and overshoot while preserving state feedback. Every interactive control has a pressed state; chart series and confidence states have text/shape cues as well as color. Shared token and state decisions live in the design-language document.

## 13. Delivery sequence and verification

1. Settle brand choice and visual tokens; preserve the counter screen while building the product route.
2. Add protected local storage, profile/onboarding, backups and versioned data records. Verify draft recovery and backup failure behavior.
3. Add quick logging and History. Verify multiple weigh-ins, time zones, sources, corrections, missing-versus-zero, and no expenditure double-counting.
4. Add calculations, Today and Trends. Verify the 77.0 kg morning / 77.4 kg evening example, sparse data, model readiness gates, conflicting evidence, all six charts and their empty states.
5. Add goals and what-if, then complete accessibility, reduced-motion, large-text and Android device checks. Switch the home route only after the new flow passes its checks.

Automated tests should cover formulas and unit conversion at the domain seam, aggregation and provenance at the repository seam, and first-run/partial/failure states at the widget seam. Use representative offline end-to-end scenarios for edit/recompute, export/import and delete-all-data. Run the relevant project checks for implementation changes: dart format, flutter analyze and flutter test. Do not claim they passed until run.

The repository has no API contract or Figma node today. For acceptance criteria alone, the Flutter create-feature skill is the available scaffolder. The screen-e2e skill needs a Figma node or CSS plus screenshot before it can be invoked. Future integrations use source-labeled records rather than changing the meaning of existing manual records.

## 14. Numbered acceptance criteria for implementation

1. A first-time adult can finish or resume onboarding with required age, equation input, height, weight and goal, while leaving other baseline fields unknown.
2. A pregnant or breastfeeding user can log but sees no automated weight-loss calorie target.
3. A user can save two or more weights on one day with independent timestamps and optional context, and can inspect both in History.
4. The app preserves the original local day and offset of a backdated entry after device travel or a unit change.
5. A user can log daily kcal with optional macros/fiber; a mismatch produces a nonblocking note and entered kcal remains authoritative.
6. A user can log total expenditure, steps and sessions without session calories being counted twice.
7. A user can repeatedly log all listed body measurements and see their historical values and trends.
8. Drafts survive a killed app; edits/deletes update dependent calculations; failed saves retain the draft.
9. Today distinguishes current observation, supported trend, baseline estimate and unavailable values, with a source/method explanation for each estimate.
10. The weight view keeps raw points visible and does not show a personal time correction before its evidence gate is met.
11. Daily deficit stays unknown if intake or total expenditure is absent, and cumulative energy displays its complete-day coverage.
12. Expected versus observed change is shown only as an uncertainty-aware comparison, never as proof of fat gain/loss or a precise calorie-to-kilogram conversion.
13. Weight-loss and maintenance goals yield a rounded intake range only in supported conditions; later suggestions require the user's acceptance and preserve earlier goal versions.
14. The what-if tool compares current and proposed ranges and approximate pace without changing the goal or claiming a precise date.
15. All six chart families render available data, missing-data gaps, point tooltips and source/method information; the target chart shows actual progress and a goal marker.
16. First-run, sparse, conflicting, validation, save-failure and import-failure states each explain what happened and offer a relevant next action.
17. The app works offline with no account or integration permission and supports encrypted local data, passphrase-protected export/import, and confirmed local deletion.
18. Both dark and light themes remain legible at large text sizes and with reduced motion; raw, estimated and inferred values remain distinguishable without color alone.
