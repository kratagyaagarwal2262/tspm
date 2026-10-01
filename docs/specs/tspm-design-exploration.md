# TSPM visual exploration and detailed design brief

Status: warm precision and burgundy/sand confirmed; light theme selected as the default; shared Flutter theme foundation implemented. Visual-first product concepts remain the screen-design reference. This document extends the [design language](../agents/design.md) without replacing the [confirmed product plan](tspm-product-plan.md). TSPM remains the working name. These are design concepts, not implemented product screens.

## Current direction: visual data in burgundy and sand

The user found the initial palette generic and the screens too text heavy. The revised direction makes data visual and interactive: a dominant weight chart, paired energy bars, goal progress and compact coverage marks. Long prose and eight repetitive metric cards yield to these visual groups. The user selected deep burgundy and sand; the four concept states still cover dark sufficient history, dark sparse history, onboarding and a light counterpart.

The [revised interactive concept](../design/tspm-visual-data-directions.html) is the current review surface. It demonstrates pointer/touch and keyboard inspection, deliberate comparison motion and a user-triggered onboarding explanation. All values are illustrative; the preview saves no health records. Exact palette values and composition remain proposed defaults pending review.

## Earlier exploration (historical)

Compare the same four screens in every direction: dark Today with sufficient history, dark Today with sparse history, dark onboarding opening, and light Today with sufficient history. Keep content, evidence and sample values identical across directions. Label sample data illustrative. Variations may change composition, type treatment, surface shape and illustration, but never the meaning or availability of evidence.

| Direction | Visual hypothesis | Warmth and tradeoff |
|---|---|---|
| Quiet Observatory | Ink surfaces, muted teal action accent, open composition and fine analytical lines | Calm and closely related to existing defaults; avoid becoming impersonal by keeping interpretation prominent. |
| Warm Editorial | Charcoal surfaces, warm ivory text, amber action accent and an editorial heading treatment | Soft abstract illustration and narrative grouping; explanations must not push daily actions too far down. |
| Clear Instrument | Deep navy surfaces, cool neutrals, blue action accent and aligned evidence groups | Geometric points and paths; compact structure must not turn Today into a wall of equally weighted metrics. |

All alternatives include a complete light-theme concept. Chart marks use independent semantic roles; the action accent never means weight loss is good. Illustration remains abstract: no ideal-body silhouette, before/after body, food morality, flame motif or muscular avatar.

The [original interactive comparison](../design/tspm-design-directions.html) preserves all twelve initial concepts for reference; it is superseded by the revised concept above. Its logging, units and navigation controls demonstrate local prototype interactions; they save no health records. The original comparison focused on hierarchy, surfaces, type and illustration. The revised concept makes the data interactions visible; implemented chart behavior still needs Android review.

## Shared detailed brief

These behavioral rules apply to the selected direction. Numerical values below are proposed defaults for later implementation and device review, not new Dart constants or approved accessibility measurements.

### Typography, grouping and surfaces

- Start from the existing 32/22/16/14/12 logical-pixel type scale. Use the display step once per main view, section titles for major groups, body for explanations and fields, supporting text for labels, and captions for supplementary metadata. Never make a caption the only disclosure of uncertainty.
- Use 400 for body and 500 for emphasis by default. Align numeric comparisons and use tabular figures where values change. Use sans serif labels, chart annotations and forms. An editorial serif is optional in rare introductory headings, never required to explain data. The final font choice remains a visual default pending review.
- Use 4/8/16/24/32 spacing steps. Default phone page inset is 24; group separation is 24 or 32; related content uses 8 or 16. At larger text sizes, wrap and stack rather than shrinking labels or truncating the interpretation.
- Page content is the ground. Group with whitespace or a restrained border. Avoid nested cards and decorative shadows. A sheet has an opaque surface and scrim; floating chrome may gain separation when content passes beneath it.
- Candidate surface radii are 16 for grouped regions, 12 for fields and controls, and 24 for sheets. These are defaults pending concept selection; reserve pill forms for genuinely compact status or selector controls.
- Use a consistent outline icon family. Keep essential actions labeled; icon-only controls require explicit accessible labels. Illustration is decorative, has no data meaning and yields space to text on small screens.

### Color semantics

The selected direction must supply dark/light pairs for page, surface, raised surface, primary text, secondary text, border, action, action foreground, pressed overlay, focus, error and warning. Separately define observation, observed trend, normalized trend and uncertainty-band chart roles. Every role is checked against the actual surface where it is used during implementation.

Use one primary action accent. Warning/error colors describe an operation or input state, not the desirability of a weight change. Confidence uses a written level and reason; color alone never communicates it. Selection and pressed appearance are distinct: a held control changes surface immediately; selected content remains marked after release.

### Screen hierarchy and interactions

| Screen | Dominant element | Supporting structure and behavior |
|---|---|---|
| Today | One trend interpretation, or the evidence-readiness message | Dominant interactive weight chart with Current/Trend, selected exact reading and time; compact confidence/coverage beside it; paired Intake/Expenditure bars and labeled Deficit; a Target/Progress track; quick add. Preserve all eight information roles without eight repetitive cards. Use at most one short interpretation in the main flow, with source/method detail on demand. |
| Trends | The selected chart and its question | Six chart families, date-range control, accessible legend, point tooltip and nearby source/method information. A point tap does not open a day-detail screen. |
| History | Day-grouped actual records | Preserve multiple same-day entries and their sources/times. Put edit/delete near the record. Explain active filters and distinguish no record from recorded zero. |
| Quick add | The active form and Save action | Separate Weight, Intake, Expenditure, Activity and Measurements forms. Place units by inputs, keep date/time editable, make optional context secondary, retain drafts on Back, and return to the originating destination after saving. |
| Onboarding | One step's purpose and next action | Five resumable steps from the confirmed plan. Opening explains the app, local privacy and units. Illustration supports the promise without displacing it. Back preserves answers; optional answers can remain unknown. |
| Goal and what-if | Current-versus-proposed comparison | Show calorie ranges, approximate pace and changed assumptions. Applying a suggestion is separate from adjusting the preview. Unsupported targets explain why and retain logging. No precise goal date or forecast line. |
| Profile | The task within each clearly named group | Separate baseline/units, goals/methods and data controls. Explain equation inputs as model parameters. Give import a preview and separate export from confirmed delete-all-data. |

Primary destinations remain Today, Trends, History and Profile. Goal and what-if are subordinate destinations. On tablets, reflow related evidence into columns and cap explanation width rather than enlarging the phone layout.

### Chart contract

| Family | Required visual meaning |
|---|---|
| Weight | Raw points at actual times, solid observed trend, dashed labeled normalized trend only after readiness, and a bounded uncertainty band where available. Sparse history shows real points without an unsupported trend. |
| Energy | Intake and source-labeled total expenditure are separate series. Equation TDEE is a separate labeled reference. Missing entries remain gaps. |
| Deficit | Show only complete-day differences and visibly label cumulative coverage. Missing inputs produce unknown, not zero. |
| Body composition | Weight and waist use separate axes/panels. Estimated body fat is a method-labeled range; reported external measurements remain distinct. |
| Activity | Distinguish steps and session facts. Optional session calories remain labeled estimates and never augment a daily total silently. |
| Target trajectory | Actual supported trend, goal marker and dated goal versions. No predicted future-weight line. |

Every chart provides visible units/period, exact plotted values and dates in a point tooltip, and method/source/coverage/confidence access. A series must survive grayscale through its marks, line style or labels. Avoid smoothing that implies unsupported precision. Today carries one dominant weight chart and two compact visual comparisons. Detailed multiseries analysis belongs in Trends. The visual and its short interpretation are one unit, not competing headlines.

### Pressed, selected and operation states

Default press behavior: immediately tint the held control's surface with the named pressed overlay; preserve its label, shape and size. Primary actions darken or lighten within their own color role. Navigation, rows, chips and icon controls use the same surface-feedback principle. Chart points use an enlarged visible marker and tooltip as feedback so the underlying evidence remains recognizable. Keyboard focus remains separately visible. No scale bounce or haptic-only feedback.

| State | Content and recovery |
|---|---|
| First load | Hold the expected layout; show a matching static skeleton only when perceptible. Proposed indicator delay: 300 ms. No decorative shimmer or invented values. |
| Refresh/recompute | Retain previous content, mark the affected section busy and avoid presenting stale interpretation as current. If an edit invalidates an estimate, withdraw that estimate rather than keep a misleading number. |
| Saving | Mark and disable the Save control, retain the form and prevent duplicate submission. Confirm success visibly when returning. |
| First-run empty | Explain the screen's value and offer the first relevant logging action. Keep navigation available. |
| Sparse/mixed-time observations | Show raw readings, coverage and any permitted provisional summary. Explain readiness; never apply an ungated personal time correction. |
| Missing energy input | Preserve the known value, mark the gap unknown and offer to add the missing daily value. |
| Conflicting evidence | Present trend and energy evidence together, name uncertainty and offer source inspection. Possible explanations remain possibilities. |
| Validation/outlier | Put actionable validation next to the field. Plausible outliers get a confirmation; do not silently clamp. Macro discrepancy is a nonblocking note. |
| Save/storage failure | Preserve the draft and existing records. Name the failed save and offer retry of that operation; provide a way back. |
| Import failure | Name wrong passphrase, unsupported archive or corruption as applicable. Preserve current data; offer retry or another backup. |
| Unsupported goal/model | Explain the unavailable estimate, retain known data and logging, and offer an applicable goal adjustment. |
| Filtered empty | Name the filter and offer Clear filter. |
| Cleared history | Confirm there are no records without alarm, and offer Add entry. |
| Offline | Normal operation in the first release. No connection warning or sign-in gate. |
| Destructive action | Confirm the specific deletion and its consequence before committing. Offer undo only where implementation can actually support it. |

These are product-state designs; product BLoCs do not exist yet. Future state-layer contracts must map their emitted states to these treatments rather than claiming this document covers states implemented today.

### Motion contract

| Interaction | Frequency | Purpose | Proposed duration/curve |
|---|---|---|---|
| Held press appearance | Any | Feedback | Instant surface change, only while held. |
| Quick-add sheet | Tens daily | Spatial consistency | 150 ms maximum; ease-out entrance, matching exit path. |
| Save confirmation | Tens daily | Feedback | Content change plus at most a 150 ms cue. |
| What-if comparison change | Occasional; repeated drag is frequent | Explanation | 200 ms ease-in-out for a discrete change; continuous scrubbing updates immediately. Interruptible. |
| Onboarding step | Rare/first-run | Spatial consistency | 240 ms ease-out; never blocks input. |
| Chart period selection | Tens daily | Explanation | Geometry change in at most 150 ms; no initial or automatic-refresh drawing. |
| Chart point scrub | Frequent | State indication | Instant selected point and exact-date/value update. |
| Onboarding noise-versus-trend demonstration | Rare/first-run | Explanation | User-triggered 240 ms transition; immediate under reduced motion. |
| Optional milestone illustration | Rare | Delight | Static by default. Any later motion requires a separate purpose/frequency decision and must not reward weight loss universally. |

Reject added tab transitions, keyboard animation, chart-scrub easing, chart-refresh drawing and returning-home entrances through the frequency gate. Reject animated backgrounds, breathing illustrations, bouncing metric cards, count-up numbers and confetti through the purpose gate. The original concepts had no added motion. Revised concepts include user-triggered data comparison and onboarding explanation; no animation runs merely because a screen becomes visible.

Reduced motion removes translation, scale and overshoot. Keep changed labels and visible state feedback; opacity/color cues are optional, not a prerequisite to understanding. Preserve Android's native back behavior. Custom gesture physics and haptics are not added by this design exploration.

### Token mapping for later Flutter implementation

| Family | Intended named roles |
|---|---|
| AppColors | Theme-paired surfaces/text/actions, pressed/focus/error/warning, and semantic chart-series roles. Burgundy/sand theme family selected; exact values are defaults pending review. |
| AppTextStyles | display, sectionTitle, body, supporting, caption; selected font family and corresponding weight/leading. |
| AppDimensions | Spacing steps, pageInset, groupRadius, controlRadius, sheetRadius and responsive content limits. |
| AppStrings | Interpretation, provenance, readiness, action, validation and recovery copy. |
| AppAssets | Selected onboarding/milestone illustration paths if packaged assets are needed. |
| AppDurations | quickAdd (150 ms), saveFeedback (150 ms), chartComparison (150 ms), comparison (200 ms), onboarding (240 ms), loadingIndicatorDelay (300 ms). |
| AppCurves | entrance (easeOutQuint), comparison (easeInOutQuart); custom sheet/gesture values only if later implementation requires them. |

The theme foundation implements AppColors, AppDimensions, AppTextStyles, AppDurations and AppCurves, alongside the existing AppStrings. AppChartTheme exposes chart colors as a typed theme extension; AppTheme provides light/dark Material themes. MyApp defaults to light and accepts an explicit ThemeMode. Product components, charts and motion paths remain to be implemented; no dependency or route was added.

## Selection and validation

Review the selected burgundy/sand direction for hierarchy, warmth, chart readability, daily-action visibility and light theme. An accent or illustration preference alone is insufficient: the chosen composition must work with sparse evidence as well as complete history.

The selected color family and visual-first philosophy are integrated into the design document. Refine exact palette, typography, surface geometry and illustration after the revised composition review, retaining these behavior rules. Record any adjustments made during selection explicitly.

Concept checks cover responsive browser layout, local prototype controls, identical sample content and consistency with the confirmed acceptance criteria. Android device appearance, accessibility measurements, large-text Flutter layouts and motion feel remain implementation checks; browser review does not prove them. No formula correctness or medical suitability is claimed by illustrative sample values.

### Review record — 1 October 2026

- Product-criteria review of this brief and the philosophy additions: no actionable contradictions found against the confirmed product plan.
- Browser review: all twelve concepts present; no horizontal overflow in the reviewed 736, 360 and 320 px content layouts; no JavaScript runtime errors. Reviewed dark, light and onboarding compositions visually.
- Local interactions checked: invalid weight feedback, valid preview confirmation without storage, source disclosure, onboarding weight-unit change and return to the concept.
- Every concept control has pressed feedback; shared product states and each proposed animation's frequency/purpose are specified above. Rejected motion is recorded explicitly.
- Proposed values map to named token families; no Dart tokens were added. No Flutter source changed and no Flutter tests were run for this artifact/documentation pass.
- This initial review predates the burgundy/sand revision. Revised composition review, palette measurements, Android accessibility, text scaling and motion feel remain pending. This is not a claim that all product UI states have been implemented or device-verified.

### Burgundy/sand revision review — 1 October 2026

- Four visual-first screens replace the original text-card composition for current review; the initial twelve screens remain archived exploration.
- Browser layout passed at 736, 360 and 320 px content widths with no horizontal overflow or JavaScript runtime errors. SVG view boxes matched their actual container widths. The complete dark, sparse, onboarding and light compositions were inspected visually.
- Verified 7/14-day mean switching (77.0/77.3 kg), derived goal progress (43%/39%), keyboard observation inspection and pointer inspection. The illustrative means derive from the supplied observations; goal progress uses the disclosed 80 kg starting value and 73 kg goal.
- Sparse history renders two raw points, no inferred trend, and unknown energy gap/progress. Coverage marks match the selected period in supported views.
- Verified the user-triggered onboarding animation changes through an intermediate state, and both comparison and onboarding resolve immediately with reduced motion. Checked local form validation and confirmation without saving records.
- Product-criteria review found no unintended changes to methodology, evidence gates, release scope or the eight required information roles. Changes to the product plan are presentation changes authorized by this design feedback.
- Visual defaults are synchronized with the revised concept. User review of this composition, palette measurements, Android text scaling/accessibility and physical-device motion feel remain pending. No Flutter source changed; Flutter tests were not run.

### Theme foundation follow-up

The user selected light as the default and authorized shared Flutter theme files. The light concept is now the primary theme reference; the dark concept remains its counterpart. This implements color/type/control infrastructure and preserves the counter screen, not the product dashboard. See the [theme foundation contract](tspm-theme-foundation.md) for interfaces and verification scope.
