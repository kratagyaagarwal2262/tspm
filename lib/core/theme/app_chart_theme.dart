import 'package:tspm/core/router/exports.dart';

/// Chart colors carry provenance, not a judgment about weight direction.
/// Views must also distinguish points, solid/dashed lines and labeled bands.
@immutable
class AppChartTheme extends ThemeExtension<AppChartTheme> {
  const AppChartTheme({
    required this.rawObservation,
    required this.observedTrend,
    required this.normalizedTrend,
    required this.uncertaintyBand,
    required this.grid,
  });

  final Color rawObservation;
  final Color observedTrend;
  final Color normalizedTrend;
  final Color uncertaintyBand;
  final Color grid;

  @override
  AppChartTheme copyWith({
    Color? rawObservation,
    Color? observedTrend,
    Color? normalizedTrend,
    Color? uncertaintyBand,
    Color? grid,
  }) => AppChartTheme(
    rawObservation: rawObservation ?? this.rawObservation,
    observedTrend: observedTrend ?? this.observedTrend,
    normalizedTrend: normalizedTrend ?? this.normalizedTrend,
    uncertaintyBand: uncertaintyBand ?? this.uncertaintyBand,
    grid: grid ?? this.grid,
  );

  @override
  AppChartTheme lerp(covariant AppChartTheme? other, double t) {
    if (other == null) return this;
    return AppChartTheme(
      rawObservation: Color.lerp(rawObservation, other.rawObservation, t)!,
      observedTrend: Color.lerp(observedTrend, other.observedTrend, t)!,
      normalizedTrend: Color.lerp(normalizedTrend, other.normalizedTrend, t)!,
      uncertaintyBand: Color.lerp(uncertaintyBand, other.uncertaintyBand, t)!,
      grid: Color.lerp(grid, other.grid, t)!,
    );
  }
}
