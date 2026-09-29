# TSPM design language

Product direction settled through the grill interview. Read with the [product blueprint](../specs/tspm-product-plan.md) before designing or building a screen. The current counter page and purple Flutter seed are starter UI, not this product's visual source.

## Personality

| Field | Decision |
|---|---|
| Reads as | Calm, precise, premium personal analytics; approachable rather than clinical or gym-oriented. |
| Theme | Dark first with a complete light theme. Follow the user's explicit theme choice; permit a manual override. |
| Hierarchy | One dominant interpretation per view. On Today, trend and its explanation outrank the latest raw observation and supporting cards. |
| Copy | Nonjudgmental and explicit about uncertainty. Say what was observed, what is estimated, and what remains unknown. |
| Motion budget | Expressive where it explains a comparison or marks an occasional milestone; instant for frequent navigation and logging. |

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

Values below are **proposed defaults**, not changes to the current app. Text/background pairs listed here have calculated contrast ratios of at least 6:1; chart combinations still need device review.

| Role | Dark default | Light default | Use |
|---|---|---|---|
| Background | #0E1519 | #F7F9F8 | Page ground. |
| Surface | #172126 | #FFFFFF | Cards and grouped regions. |
| Primary text | #F2F6F5 | #182529 | Titles, figures and body. |
| Secondary text | #AEBDBB | #52605E | Source, period and support copy. |
| Primary action | #68D6C4 | #17695F | Main action and focus emphasis. |

Use borders rather than heavy shadows on cards. Warning and error colors are semantic roles to define with contrast checks when their screens are implemented. Chart series use distinct markers and line styles as well as color: raw observations are points, observed trend is a solid line, normalized trend is a dashed labeled line, and uncertainty is a bounded band. Do not use the primary-action accent to mean “good weight change.”

## Motion decisions

| Interaction | Frequency tier | Purpose and default |
|---|---|---|
| Tab switch, keyboard, scroll, return to Today | Frequent | Instant; no added content transition. |
| Pressable control | Any | Visible pressed state while held; no persistent decorative animation. |
| Quick-add sheet | Tens of times daily | Spatial consistency; 150 ms ceiling. |
| Saved entry confirmation | Tens of times daily | Feedback; changed content plus brief state cue, 150 ms ceiling. |
| What-if range change | Occasional | Explanation; approximately 180–220 ms, interruptible. |
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
