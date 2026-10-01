# TSPM theme foundation

Implement the selected burgundy-and-sand design language as shared Material 3 themes, with **light as the explicit default** regardless of the system appearance. Retain a coordinated dark theme and keep the counter screen's behavior and copy unchanged.

## Contracts

- `AppTheme.light` and `AppTheme.dark` provide fully configured `ThemeData`. `MyApp` accepts `ThemeMode themeMode`, defaulting to `ThemeMode.light`; callers may explicitly request dark or system mode. No preference storage or settings screen is introduced.
- Existing `AppColors`, `AppDimensions` and the single barrel remain the shared integration path. Remove the purple seed and centralize the selected semantic palette, text styles, interaction dimensions and motion durations/curves.
- `AppChartTheme extends ThemeExtension<AppChartTheme>` supplies observation, observed trend, normalized trend, uncertainty-band and grid colors for future charts, with `copyWith` and `lerp`. It does not implement a chart, a normalization model or a readiness rule.
- Material components receive coordinated page/surface colors, borders, typography, pressed/focused/disabled states and accessible touch sizing. The counter app bar inherits its shared theme rather than selecting an inverse seed color.
- Use platform sans-serif typography offline. No font dependency, illustration asset, speculative shared widget, new skill or feature-state layer is required. Existing design skills read `docs/agents/design.md` for future work.

## Verification

Keep the original counter smoke test. Add widget coverage for light mode under a dark system setting, explicit dark mode, 200% text scaling and counter tap-target/label/contrast guidelines. Check semantic text/action contrast against actual theme surfaces and availability of chart roles in each theme. Run formatting, analysis and the complete test suite. Device appearance, screen-reader usability and future product-chart rendering are not established by these tests.

## Verification record — 1 October 2026

- Baseline before theme wiring: `flutter test` → +1, -0.
- `dart format --output=none --set-exit-if-changed lib test` → 18 files, 0 changes.
- `flutter analyze` → No issues found.
- `flutter test` → +10, -0. Coverage includes light default under a dark system, explicit dark override, counter behavior, 200% text scaling, tap-target/label/contrast guidelines in both themes, semantic palette contrast and chart-theme interpolation.
- Verification stopped at rung 3 (widget). No Android device, TalkBack or rendered product-chart check was performed. Theme tokens are infrastructure; they do not implement the proposed product animations.

## Global system-bar follow-up

The reported black bottom strip was reproduced on Android 13. Enable `SystemUiMode.edgeToEdge` before `runApp`, apply `AppSystemUi` through the root builder and shared app-bar theme, and retain normal control safe insets. All routes inherit transparent system bars and theme-aware system icon colors.

Verification: `flutter analyze` clean; `flutter test` +12, -0. Route regression tests cover pages with and without app bars in both themes. `flutter run -d emulator-5554` and an adb screenshot comparison confirmed the bottom area changed from RGB (0, 0, 0) to page RGB (247, 241, 232). This is an emulator visual check, not a new integration-test harness or physical-device verification.
