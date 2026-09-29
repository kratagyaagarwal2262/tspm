# TSPM product vision (draft)

TSPM is the working codename for a premium personal body-composition analytics app. The consumer name and brand direction are undecided. This document preserves the product brief for planning; it is not an implementation specification or an approved calculation method.

## Purpose

Help a person understand how body weight, measurement time, intake, expenditure, activity, body measurements, and historical trends relate. The daily experience should answer where they are, what is happening, why it may be happening, whether their plan appears to be working, and what the data suggests they could change.

The product sequence is **measure → normalize → calculate → compare → interpret**. Raw logs remain accessible, but the main value is trend interpretation with visible uncertainty.

## Proposed capabilities

- Log weight with exact timestamp, unit, optional measurement conditions, and notes. Log daily calories and macros. Record each expenditure value with its type and source, including manual, wearable, activity, workout, and estimated total expenditure.
- Collect a baseline profile and goals, then show derived values such as BMI, BMR, estimated TDEE, fat mass, lean mass, and target energy balance as estimates with their assumptions.
- Show raw weight separately from short and long trend views. Explore time-of-day normalization only when enough repeated measurements support an individual intraday pattern; label normalized values as statistical estimates.
- Compare estimated intake and expenditure with observed trend change. Reverse TDEE estimation should use sustained intake and weight-trend history, display the data period and confidence, and remain provisional when inputs are sparse or inconsistent.
- Express goal intake as a range. Detect possible plateaus from an adequate observation period and consistency checks, not from a single weigh-in. Treat waist and other body measurements as additional trend signals.
- Provide a simple dashboard and interactive charts for weight, energy, deficit, body composition, activity, and target trajectory, with access to the underlying day's data.

## Interpretation rules

- Distinguish **measured**, **entered**, **calculated**, and **inferred** values in the data model and UI.
- Preserve source and timestamp for each observation or estimate. Do not silently promote wearable expenditure or a calculated trend into ground truth.
- Describe water retention, glycogen, meal timing, and similar causes as possibilities when the evidence cannot isolate them. Do not claim that a single fluctuation proves fat gain or loss.
- State data sufficiency and uncertainty beside conclusions. Conflicting inputs should produce a cautious explanation, not a precise prediction.
- Treat energy-to-weight conversion, BMR, TDEE, body-fat estimates, and plateau thresholds as methodology decisions requiring evidence and review before implementation.

## Experience direction

The interface should feel premium, minimal, analytical, and approachable: clear typography, generous space, elegant charts, restrained motion, and strong hierarchy. Avoid gym clichés, excessive gradients, motivational slogans, and dashboards dominated by large numbers. Trend and interpretation should lead; raw data and provenance should remain easy to inspect.

## Before implementation

Produce and review: product name options and brand direction; information architecture; core screens and daily logging flow; dashboard concept; data and calculation models; chart system; plateau and reverse-TDEE methods; states for insufficient or conflicting data; and a visual design direction. The current Flutter app is still a counter scaffold. Product features are not implemented by this document.
