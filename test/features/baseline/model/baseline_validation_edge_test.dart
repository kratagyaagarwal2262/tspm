import 'package:flutter_test/flutter_test.dart';
import 'package:tspm/core/router/exports.dart';

OnboardingDraft validDraft() =>
    OnboardingDraft.initial(
          now: DateTime.utc(2026, 10, 9),
          setupId: 'edge-test',
        )
        .withText(OnboardingField.age, '30')
        .withQuantity(
          OnboardingField.height,
          DraftQuantity(
            rawText: '175',
            canonicalValue: 175,
            originalUnitToken: 'cm',
            displayUnitToken: 'cm',
          ),
        )
        .withQuantity(
          OnboardingField.startingWeight,
          DraftQuantity(
            rawText: '80',
            canonicalValue: 80,
            originalUnitToken: 'kg',
            displayUnitToken: 'kg',
          ),
        )
        .copyWith(
          equationInput: EquationSexInput.male,
          goalIntent: GoalIntent.maintenance,
        );

void main() {
  group('AC 2–6: validation remains safe through corrections and reload', () {
    test(
      'decimal age text cannot pass validation then throw during completion',
      () {
        final OnboardingDraft draft = validDraft().withText(
          OnboardingField.age,
          '18.0',
        );
        final Either<FormProblems, CompletedBaseline> result =
            BaselineValidation.prepareCompletion(
              draft,
              DateTime.utc(2026, 10, 9),
              LocalDay.parse('2026-10-09'),
            );
        expect(result.isLeft(), isTrue);
      },
    );
    test(
      'clearing an optional measurement restores unknown, including its unit',
      () {
        final OnboardingDraft draft = validDraft().withQuantity(
          OnboardingField.waist,
          DraftQuantity(
            rawText: '',
            canonicalValue: null,
            originalUnitToken: 'cm',
            displayUnitToken: 'cm',
          ),
        );
        final Either<FormProblems, CompletedBaseline> result =
            BaselineValidation.prepareCompletion(
              draft,
              DateTime.utc(2026, 10, 9),
              LocalDay.parse('2026-10-09'),
            );
        expect(result.isRight(), isTrue);
        expect(
          result
              .getOrElse(() => throw StateError('failed'))
              .profile
              .originalWaistUnit,
          isNull,
        );
      },
    );
    test(
      'zero physical input gets positive-value feedback rather than required',
      () {
        final OnboardingDraft draft = validDraft()
            .copyWith(step: OnboardingStep.requiredBaseline)
            .withQuantity(
              OnboardingField.height,
              DraftQuantity(
                rawText: '0',
                canonicalValue: null,
                originalUnitToken: 'cm',
                displayUnitToken: 'cm',
              ),
            );
        expect(
          BaselineValidation.checkStep(draft).fields[OnboardingField.height],
          InputIssue.positiveFiniteRequired,
        );
      },
    );
    test('impossible stored instant is rejected instead of normalized', () {
      final String json = BaselineCodec.encode(
        DraftBaselineSnapshot(draft: validDraft()),
      );
      final String changed = json.replaceFirst(
        '2026-10-09T00:00:00.000Z',
        '2026-02-30T00:00:00.000Z',
      );
      expect(BaselineCodec.decode(changed).isLeft(), isTrue);
    });
    test(
      'toggle save reload retains exact canonical quantity and original units',
      () {
        final OnboardingDraft draft = validDraft().changeUnits(
          const UnitPreferences(weight: WeightUnit.lb, length: LengthUnit.inch),
        );
        final BaselineSnapshot restored = BaselineCodec.decode(
          BaselineCodec.encode(DraftBaselineSnapshot(draft: draft)),
        ).getOrElse(() => throw StateError('failed'));
        final OnboardingDraft changed =
            (restored as DraftBaselineSnapshot).draft;
        expect(changed.quantities[OnboardingField.height]!.canonicalValue, 175);
        expect(
          changed.quantities[OnboardingField.height]!.originalUnitToken,
          'cm',
        );
        expect(
          changed.quantities[OnboardingField.startingWeight]!.canonicalValue,
          80,
        );
      },
    );
  });
}
