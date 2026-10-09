import '../../../core/router/exports.dart';

class BaselineProfilePage extends StatelessWidget {
  const BaselineProfilePage({super.key, required this.baseline});
  final CompletedBaseline baseline;
  @override
  Widget build(BuildContext context) {
    final BaselineProfile p = baseline.profile;
    final InitialGoal g = baseline.goal;
    final String length = p.preferredUnits.length.name;
    final String weight = p.preferredUnits.weight.name;
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.profileTitle)),
      body: BaselineReadingBody(
        children: [
          const Text(AppStrings.readOnly),
          const SizedBox(height: AppDimensions.large),
          BaselineSection(
            title: AppStrings.reportedInputs,
            children: [
              BaselineReviewValue(
                label: AppStrings.age,
                value: '${p.ageYears}',
              ),
              Text(AppStrings.ageDate(p.ageRecordedOn.toIsoDay())),
              BaselineReviewValue(
                label: AppStrings.equationInput,
                value: p.equationInput == EquationSexInput.male
                    ? AppStrings.male
                    : AppStrings.female,
              ),
              BaselineReviewValue(
                label: AppStrings.height,
                value: baselineQuantity(p.heightCm, length),
              ),
              BaselineReviewValue(
                label: AppStrings.waist,
                value: baselineQuantity(p.waistCm, length),
              ),
              BaselineReviewValue(
                label: AppStrings.neck,
                value: baselineQuantity(p.neckCm, length),
              ),
              BaselineReviewValue(
                label: AppStrings.hip,
                value: baselineQuantity(p.hipCm, length),
              ),
              BaselineReviewValue(
                label: AppStrings.bodyFat,
                value: p.reportedBodyFat == null
                    ? AppStrings.unknown
                    : '${p.reportedBodyFat!.percent}%',
              ),
              BaselineReviewValue(
                label: AppStrings.bodyFatSource,
                value: p.reportedBodyFat?.source ?? AppStrings.unknown,
              ),
            ],
          ),
          BaselineSection(
            title: AppStrings.startingWeight,
            children: [
              Text(baselineQuantity(baseline.startingWeight.weightKg, weight)),
              Text(baselineTimeLabel(baseline.startingWeight.observedAt)),
              const Text(AppStrings.reportedSource),
              BaselineReviewValue(
                label: AppStrings.originalUnits,
                value: AppStrings.originalEntry(
                  baseline.startingWeight.originalUnit.name,
                  p.originalHeightUnit.name,
                ),
              ),
            ],
          ),
          BaselineSection(
            title: AppStrings.activity,
            children: [
              BaselineReviewValue(
                label: AppStrings.activityLevel,
                value: p.activityLevel == null
                    ? AppStrings.unknown
                    : AppStrings.activityLabels[p.activityLevel!.index],
              ),
              BaselineReviewValue(
                label: AppStrings.steps,
                value: p.typicalDailySteps?.toString() ?? AppStrings.unknown,
              ),
              BaselineReviewValue(
                label: AppStrings.trainingDays,
                value: p.trainingDaysPerWeek?.toString() ?? AppStrings.unknown,
              ),
              BaselineReviewValue(
                label: AppStrings.trainingType,
                value: p.trainingType ?? AppStrings.unknown,
              ),
              BaselineReviewValue(
                label: AppStrings.restDays,
                value: p.restDaysPerWeek?.toString() ?? AppStrings.unknown,
              ),
            ],
          ),
          BaselineSection(
            title: AppStrings.goal,
            children: [
              BaselineReviewValue(
                label: AppStrings.goalDate,
                value: g.effectiveOn.toIsoDay(),
              ),
              BaselineReviewValue(
                label: AppStrings.goalIntent,
                value: g is LossGoal ? AppStrings.loss : AppStrings.maintenance,
              ),
              if (g is LossGoal) ...[
                BaselineReviewValue(
                  label: AppStrings.targetWeight,
                  value: baselineQuantity(g.targetWeightKg, weight),
                ),
                BaselineReviewValue(
                  label: AppStrings.lossRate,
                  value: AppStrings.rateLabels[g.rate.index],
                ),
              ],
              BaselineReviewValue(
                label: AppStrings.milestone,
                value:
                    g.bodyFatMilestonePercent?.toString() ?? AppStrings.unknown,
              ),
            ],
          ),
          BaselineSection(
            title: AppStrings.applicability,
            children: [
              BaselineReviewValue(
                label: AppStrings.pregnancy,
                value: baselineAnswer(p.pregnancy),
              ),
              BaselineReviewValue(
                label: AppStrings.breastfeeding,
                value: baselineAnswer(p.breastfeeding),
              ),
              Text(baselineApplicability(p.pregnancy, p.breastfeeding)),
            ],
          ),
        ],
      ),
    );
  }
}
