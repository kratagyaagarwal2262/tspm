# TSPM design language

Product direction settled through the grill interview. Read with the [product blueprint](../specs/tspm-product-plan.md) before designing or building a screen. The current counter page and purple Flutter seed are starter UI, not this product's visual source.

## Design philosophy: warm precision

**Help people understand what is changing, how strong the evidence is, and what they can do next, while keeping daily tracking calm and easy.**

The user selected warm precision, a detailed design brief, exploration of visual alternatives before selection, and subtle visual personality. Warmth comes from considerate language, comfortable reading, and restrained illustration in onboarding and occasional milestones. Precision comes from the identity, period, source and uncertainty of the evidence, not the number of decimal places.

| Principle | Practical rule |
|---|---|
| Understanding comes first | Give each view one dominant answer or action. Today leads with a supported interpretation; when evidence is sparse, explain what is known and the next useful observation. |
| Show the relationship before explaining it | Make weight history, energy comparison and goal progress directly explorable. Use short labels and one concise interpretation; put longer explanations behind nearby disclosures. Preserve source, period and confidence where the visual is read. |
| Evidence stays visible | Distinguish measured/reported observations, entered values, calculated estimates and inferred trends. Show confidence and coverage beside the conclusion; reveal inputs and methods through a nearby control. |
| Body change carries no moral judgment | Describe direction without praising loss, blaming missing logs, or assigning a physiological cause to a fluctuation. Color must not grade a person's body or adherence. |
| Tracking accommodates real life | Keep the five logging forms independent. Preserve drafts, editable timestamps and corrections. Incomplete records still provide useful information. |
| Charts explain honestly | Keep observations visible, retain gaps, distinguish series with marks and labels, and use ranges for uncertain estimates. Full records belong in History; point selection exposes a tooltip. |
| The person remains in control | Explain goal assumptions. What-if is exploration; applying a suggestion requires acceptance. Keep previous goal versions inspectable. |
| Premium means protecting attention | Use limited typography, generous grouping space and restrained surfaces. Every illustration, accent and animation must earn its attention through a clear purpose. |

Review each screen by asking: Is its main message clear? Is its evidence visible? Does the language preserve agency? Is the next action useful? Does every visual element earn its attention?

### Visual direction: burgundy and sand

The user rejected the initial palettes as generic and the composition as too text heavy, then selected **deep burgundy and sand**. The revised [design exploration and brief](../specs/tspm-design-exploration.md) leads with interactive data: a weight chart, paired energy bars, goal-progress track and compact coverage marks. The earlier three alternatives remain historical exploration, not the current visual direction. Color family and visual-first presentation are selected; exact visual values are proposed defaults pending review. The shared Flutter theme foundation now adopts this palette with light as the default. Product charts and screens remain concept work; the counter behavior is preserved.

## Personality

| Field | Decision |
|---|---|
| Reads as | Calm, precise, premium personal analytics; approachable rather than clinical or gym-oriented. |
| Theme | Light by default, as selected by the user. Keep the coordinated dark counterpart. The app defaults explicitly to light even when the device is dark; an explicit theme choice may override it. |
| Hierarchy | One dominant interpretation per view, expressed visually. Today leads with the supported trend and raw observations on an interactive weight chart; compact energy and goal comparisons follow. |
| Copy | Nonjudgmental and explicit about uncertainty. Say what was observed, what is estimated, and what remains unknown. |
| Motion budget | Responsive, interactive data visuals. Animate deliberate comparisons where motion explains change; keep scrubbing and frequent navigation immediate. No decorative looping motion. |

## Type and spacing tokens

These are **design defaults** to be implemented as named AppTextStyles and AppDimensions values, then checked on a device with text scaling.

| Token | Default size | Use |
|---|---:|---|
| Display | 32 logical px | One hero trend value or interpretation. |
| Section title | 22 logical px | Screen and major group titles. |
| Body | 16 logical px | Explanations, forms and actions. |
| Supporting | 14 logical px | Card labels and chart annotations. |
| Caption | 12 logical px | Provenance and secondary metadata, never the only disclosure. |

Use existing 8, 16 and 24 logical-pixel spacing steps; add 4 and 32 only where a real layout needs them. Default page inset is 24 on phone. Space between groups exceeds space within a group. Cap long-form explanation width on tablets rather than scaling the whole phone layout.

## Color roles

Use warm burgundy surfaces and sand emphasis, with a warm paper light counterpart. The previous teal/ink palette is superseded. Values below are centralized in the Flutter theme foundation. Automated contrast and counter-widget checks cover the implemented roles; product chart and device review remain pending.

| Role | Dark default | Light default | Use |
|---|---|---|---|
| Background | #251B20 | #F7F1E8 | Page ground. |
| Surface | #34262D | #EEE3DA | Grouped regions. |
| Primary text | #F7ECDD | #39242D | Titles, figures and body. |
| Secondary text | #C7B6B9 | #735E67 | Source, period and support copy. |
| Primary action | #E8CE9F | #753B50 | Main action and focus emphasis. |
| Action foreground | #39242D | #FFF5E6 | Labels on filled actions. |
| Border | #58414B | #D6C3C5 | Region and input separation. |

Use borders rather than heavy shadows on cards. Warning and error colors are semantic roles to define with contrast checks when their screens are implemented. Chart series use distinct markers and line styles as well as color: raw observations are points, observed trend is a solid line, normalized trend is a dashed labeled line, and uncertainty is a bounded band. Do not use the primary-action accent to mean “good weight change.”

## Motion decisions

| Interaction | Frequency tier | Purpose and default |
|---|---|---|
| Tab switch, keyboard, scroll, return to Today | Frequent | Instant; no added content transition. |
| Pressable control | Any | Visible pressed state while held; no persistent decorative animation. |
| Quick-add sheet | Tens of times daily | Spatial consistency; 150 ms ceiling. |
| Saved entry confirmation | Tens of times daily | Feedback; changed content plus brief state cue, 150 ms ceiling. |
| Chart period selection | Tens of times daily | Explanation; geometry changes in at most 150 ms. No initial chart drawing animation. |
| Chart scrubbing or point inspection | Frequent | Instant pointer, selected mark and exact-value update. |
| What-if range change | Occasional | Explanation; approximately 180–220 ms, interruptible. |
| Onboarding noise-versus-trend demonstration | Rare/first-run | Explanation; 240 ms user-triggered change, with an immediate reduced-motion alternative. |
| Onboarding step or rare milestone | Rare | Spatial consistency or delight; 220–280 ms, never blocking interaction. |

Every animation must name its purpose and tier before implementation. Reduced motion removes translation, scale and overshoot while retaining a brief opacity/color cue. No animation is added to a chart merely because data refreshed; the visual result and source label provide feedback.

## Shared state patterns

| State | Treatment |
|---|---|
| First load | Preserve the known page shape with a matching skeleton only if loading is perceptible; no brief spinner flash. |
| Refresh | Keep prior content visible; show progress near the affected section. |
| First-run empty | Explain the value of the screen and offer its first logging action. |
| Sparse data | Show real observations, label provisional summaries, and say what additional data unlocks a trend. |
| Filtered empty | Name the active filter and offer Clear filter. |
| Conflicting evidence | Present both observations and uncertainty; avoid assigning a cause. |
| Validation | Put the message beside the field as soon as it is knowable; unusual-but-valid entries can be confirmed. |
| Save failure | Keep the draft and prior content, name the failed operation, offer Retry. |
| Backup failure | Never replace local data; explain wrong passphrase or invalid archive and offer another attempt. |
| Offline | Normal operation; first-release features do not depend on a connection. |

All pressable elements use a visible pressed appearance. Destructive actions confirm before deletion. Each state provides a way forward, and no estimate is represented by an unlabeled blank or zero.

## Validation on device

Review Today, all six charts, quick-add forms, large-text layouts, light and dark themes, and reduced-motion paths on an Android device. Verify that the hero trend remains dominant, chart series remain distinguishable without color, and expressive motion does not delay frequent use. The visual defaults can be tuned after that review without changing their semantic roles.

## Implemented theme foundation

`AppTheme.light` and `AppTheme.dark` supply Material 3 themes. `MyApp` defaults to `ThemeMode.light` and accepts an explicit theme mode for future preference wiring. No theme settings or persistence feature is added by this foundation.

Colors, text styles, dimensions, durations and curves resolve through the named App families. `AppChartTheme` is a typed theme extension for chart colors; future chart widgets must still distinguish series through marks and labels and honor evidence-readiness gates. System sans-serif typography works offline; no font download is required. The existing design skill reads this document, so a second project-specific theme skill is unnecessary.

The counter app bar inherits the shared theme. Theme configuration provides pressed/focused/disabled control treatments; reduced-motion handling remains a responsibility of widgets that use the motion tokens. Defining durations does not implement the chart or onboarding animations. See the [theme foundation contract](../specs/tspm-theme-foundation.md).

## System bars and screen edges

All routes draw their backgrounds behind transparent Android status/navigation bars using edge-to-edge mode. `AppSystemUi.overlayStyleFor` supplies theme-aware icon brightness and disables automatic system-bar contrast scrims. `MyApp.builder` applies this policy globally, including routes without an app bar; the shared app-bar theme uses the same policy. Keep gesture bars visible and retain system safe insets for controls and scroll content. Do not compensate for the system area with a black bottom container or remove safe insets globally.

The light counter screen was verified on an Android 13 emulator: the bottom navigation background changed from black to the exact page color. Light/dark route styling is regression-tested; newer Android versions and physical-device interaction have not been checked in this pass.
