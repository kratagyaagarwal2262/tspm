import 'package:flutter_test/flutter_test.dart';
import 'package:tspm/core/router/exports.dart';

void main() {
  test('LocalDay rejects normalized calendar dates', () {
    expect(() => LocalDay.parse('2026-02-30'), throwsFormatException);
    expect(LocalDay.parse('2024-02-29').toIsoDay(), '2024-02-29');
  });

  test('initial draft freezes setup time and creates an identifier', () {
    final now = DateTime.utc(2026, 10, 9, 12);
    final draft = OnboardingDraft.initial(now: now);
    expect(draft.setupId, isNotEmpty);
    expect(draft.createdAtUtc, now);
    expect(draft.updatedAtUtc, now);
    expect(draft.startingTime.instantUtc, now);
    expect(draft.startingTime.selectedLocalDay.toIsoDay(), '2026-10-09');
  });

  test(
    'unit change converts display while preserving canonical and entry units',
    () {
      final draft = OnboardingDraft.initial(now: DateTime.utc(2026));
      final withHeight = draft.withQuantity(
        OnboardingField.height,
        DraftQuantity(
          rawText: '180',
          canonicalValue: 180,
          originalUnitToken: 'cm',
          displayUnitToken: 'cm',
        ),
      );
      final changed = withHeight.changeUnits(
        const UnitPreferences(weight: WeightUnit.lb, length: LengthUnit.inch),
      );
      expect(changed.quantities[OnboardingField.height]!.canonicalValue, 180);
      expect(
        changed.quantities[OnboardingField.height]!.originalUnitToken,
        'cm',
      );
      expect(
        changed.quantities[OnboardingField.height]!.displayUnitToken,
        'inch',
      );
      expect(
        double.parse(changed.quantities[OnboardingField.height]!.rawText),
        closeTo(70.866, 0.001),
      );
    },
  );

  test('outlier confirmation is exact-value and numeric edits clear it', () {
    final draft = OnboardingDraft.initial(now: DateTime.utc(2026)).withQuantity(
      OnboardingField.height,
      DraftQuantity(
        rawText: '270',
        canonicalValue: 270,
        originalUnitToken: 'cm',
        displayUnitToken: 'cm',
      ),
    );
    final confirmed = draft.confirmOutlier(OutlierField.height, 270);
    expect(confirmed.isOutlierConfirmed(OutlierField.height), isTrue);
    expect(
      () => confirmed.confirmOutlier(OutlierField.height, 271),
      throwsArgumentError,
    );
    expect(
      confirmed
          .withQuantity(
            OnboardingField.height,
            DraftQuantity(
              rawText: '271',
              canonicalValue: 271,
              originalUnitToken: 'cm',
              displayUnitToken: 'cm',
            ),
          )
          .isOutlierConfirmed(OutlierField.height),
      isFalse,
    );
  });

  test('completion preserves unknown optional values separately from zero', () {
    final draft =
        OnboardingDraft.initial(
              now: DateTime.utc(2026, 10, 9),
              setupId: 'setup-a',
            )
            .copyWith(
              step: OnboardingStep.goalAndApplicability,
              equationInput: EquationSexInput.female,
              goalIntent: GoalIntent.maintenance,
            )
            .withText(OnboardingField.age, '30')
            .withText(OnboardingField.typicalSteps, '0')
            .withQuantity(
              OnboardingField.height,
              DraftQuantity(
                rawText: '170',
                canonicalValue: 170,
                originalUnitToken: 'cm',
                displayUnitToken: 'cm',
              ),
            )
            .withQuantity(
              OnboardingField.startingWeight,
              DraftQuantity(
                rawText: '70',
                canonicalValue: 70,
                originalUnitToken: 'kg',
                displayUnitToken: 'kg',
              ),
            );

    final result = BaselineValidation.prepareCompletion(
      draft,
      DateTime.utc(2026, 10, 9, 12),
      LocalDay.parse('2026-10-09'),
    );
    expect(result.isRight(), isTrue);
    final baseline = result.toOption().toNullable()!;
    expect(baseline.profile.typicalDailySteps, 0);
    expect(baseline.profile.trainingDaysPerWeek, isNull);
    expect(baseline.profile.pregnancy, ApplicabilityAnswer.unknown);
    expect(baseline.goal, isA<MaintenanceGoal>());
    final restored = BaselineCodec.decode(
      BaselineCodec.encode(CompletedBaselineSnapshot(baseline: baseline)),
    );
    expect(restored.isRight(), isTrue);
    final restoredBaseline =
        (restored.toOption().toNullable() as CompletedBaselineSnapshot)
            .baseline;
    expect(restoredBaseline, baseline);
  });
}
