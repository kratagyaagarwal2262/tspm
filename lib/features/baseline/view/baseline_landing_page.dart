import '../../../core/router/exports.dart';

class BaselineLandingPage extends StatelessWidget {
  const BaselineLandingPage({
    super.key,
    required this.baseline,
    required this.onReviewProfile,
    this.justCompleted = false,
  });
  final CompletedBaseline baseline;
  final VoidCallback onReviewProfile;
  final bool justCompleted;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text(AppStrings.landingTitle)),
    body: BaselineReadingBody(
      children: [
        if (justCompleted)
          Semantics(liveRegion: true, child: const Text(AppStrings.setupSaved)),
        const SizedBox(height: AppDimensions.medium),
        BaselineSection(
          title: AppStrings.startingWeight,
          children: [
            Text(
              baselineQuantity(
                baseline.startingWeight.weightKg,
                baseline.profile.preferredUnits.weight.name,
              ),
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: AppDimensions.small),
            Text(baselineTimeLabel(baseline.startingWeight.observedAt)),
            const Text(AppStrings.reportedSource),
          ],
        ),
        const Text(AppStrings.landingEvidence),
        const SizedBox(height: AppDimensions.large),
        FilledButton(
          onPressed: onReviewProfile,
          child: const Text(AppStrings.reviewProfile),
        ),
      ],
    ),
  );
}
