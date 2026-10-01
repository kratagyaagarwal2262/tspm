import 'package:flutter_test/flutter_test.dart';
import 'package:tspm/core/router/exports.dart';

double contrastRatio(Color foreground, Color background) {
  final double foregroundLuminance = foreground.computeLuminance();
  final double backgroundLuminance = background.computeLuminance();
  final double brighter = foregroundLuminance > backgroundLuminance
      ? foregroundLuminance
      : backgroundLuminance;
  final double darker = foregroundLuminance < backgroundLuminance
      ? foregroundLuminance
      : backgroundLuminance;
  return (brighter + 0.05) / (darker + 0.05);
}

void main() {
  group('Theme acceptance coverage', () {
    for (final Brightness brightness in Brightness.values) {
      test('$brightness text and action labels retain readable contrast', () {
        final ThemeData theme = brightness == Brightness.light
            ? AppTheme.light
            : AppTheme.dark;
        final ColorScheme colors = theme.colorScheme;

        for (final Color surface in <Color>[
          theme.scaffoldBackgroundColor,
          colors.surface,
          colors.surfaceContainer,
        ]) {
          expect(
            contrastRatio(colors.onSurface, surface),
            greaterThanOrEqualTo(4.5),
          );
          expect(
            contrastRatio(colors.onSurfaceVariant, surface),
            greaterThanOrEqualTo(4.5),
          );
        }
        expect(
          contrastRatio(colors.onPrimary, colors.primary),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          contrastRatio(colors.onError, colors.error),
          greaterThanOrEqualTo(4.5),
        );
      });
    }

    test('chart roles remain available across theme interpolation', () {
      final ThemeData light = AppTheme.light;
      final ThemeData dark = AppTheme.dark;
      final AppChartTheme? lightCharts = light.extension<AppChartTheme>();
      final AppChartTheme? darkCharts = dark.extension<AppChartTheme>();

      expect(lightCharts, isNotNull);
      expect(darkCharts, isNotNull);
      final AppChartTheme? midpoint = ThemeData.lerp(
        light,
        dark,
        0.5,
      ).extension<AppChartTheme>();
      expect(midpoint, isNotNull);
      expect(
        midpoint!.observedTrend,
        Color.lerp(lightCharts!.observedTrend, darkCharts!.observedTrend, 0.5),
      );
    });
  });
}
