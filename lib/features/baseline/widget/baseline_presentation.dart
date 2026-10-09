import '../../../core/router/exports.dart';

/// Formats the original observation clock, independent of the current timezone.
String baselineTimeLabel(ObservationTime time) {
  final DateTime clock = time.selectedLocalDateTime;
  final int offset = time.originalUtcOffsetMinutes;
  final String hours = (offset.abs() ~/ 60).toString().padLeft(2, '0');
  final String minutes = (offset.abs() % 60).toString().padLeft(2, '0');
  return AppStrings.weightClock(
    time.selectedLocalDay.toIsoDay(),
    '${clock.hour.toString().padLeft(2, '0')}:${clock.minute.toString().padLeft(2, '0')}',
    AppStrings.offsetLabel(offset < 0 ? '-' : '+', hours, minutes),
  );
}

String baselineQuantity(double? canonical, String unit) {
  if (canonical == null) return AppStrings.unknown;
  final double value = switch (unit) {
    'lb' => canonical / 0.45359237,
    'inch' => canonical / 2.54,
    _ => canonical,
  };
  return '${value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '')} $unit';
}

String baselineAnswer(ApplicabilityAnswer answer) => switch (answer) {
  ApplicabilityAnswer.unknown => AppStrings.unknown,
  ApplicabilityAnswer.no => AppStrings.no,
  ApplicabilityAnswer.yes => AppStrings.yes,
};
String baselineApplicability(
  ApplicabilityAnswer pregnancy,
  ApplicabilityAnswer breastfeeding,
) =>
    pregnancy != ApplicabilityAnswer.no ||
        breastfeeding != ApplicabilityAnswer.no
    ? AppStrings.applicabilityLimited
    : AppStrings.applicabilityClear;

class BaselineReadingBody extends StatelessWidget {
  const BaselineReadingBody({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.pageInset),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppDimensions.readingMaxWidth,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    ),
  );
}

class BaselineSection extends StatelessWidget {
  const BaselineSection({
    super.key,
    required this.title,
    required this.children,
  });
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppDimensions.large),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        const SizedBox(height: AppDimensions.medium),
        ...children,
      ],
    ),
  );
}

class BaselineReviewValue extends StatelessWidget {
  const BaselineReviewValue({
    super.key,
    required this.label,
    required this.value,
  });
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppDimensions.medium),
    child: MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          Text(value, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    ),
  );
}
