import 'package:flutter_test/flutter_test.dart';
import 'package:tspm/core/router/exports.dart';

OnboardingDraft _validDraft() =>
    OnboardingDraft.initial(
          now: DateTime.utc(2026, 10, 9, 12),
          setupId: 'acceptance',
        )
        .withText(OnboardingField.age, '30')
        .withQuantity(OnboardingField.height, _quantity('175', 175, 'cm'))
        .withQuantity(OnboardingField.startingWeight, _quantity('80', 80, 'kg'))
        .copyWith(
          equationInput: EquationSexInput.female,
          goalIntent: GoalIntent.maintenance,
        );

DraftQuantity _quantity(
  String raw,
  double? canonical,
  String unit, {
  String? displayUnit,
}) => DraftQuantity(
  rawText: raw,
  canonicalValue: canonical,
  originalUnitToken: unit,
  displayUnitToken: displayUnit ?? unit,
);

CompletedBaseline _complete(OnboardingDraft draft, {LocalDay? profileDay}) =>
    BaselineValidation.prepareCompletion(
      draft,
      DateTime.utc(2026, 10, 10, 8),
      profileDay ?? LocalDay.parse('2026-10-10'),
    ).getOrElse(() => throw StateError('Expected a valid baseline'));

Map<String, dynamic> _object(Object? value) =>
    (value! as Map).cast<String, dynamic>();

void main() {
  group('AC coverage', () {
    group('AC 2–3: required inputs and converted outlier confirmations', () {
      test(
        'adult integer age and finite positive physical values are required',
        () {
          final OnboardingDraft base = _validDraft().copyWith(
            step: OnboardingStep.requiredBaseline,
          );

          expect(BaselineValidation.checkStep(base).isEmpty, isTrue);
          expect(
            BaselineValidation.checkStep(
              base.withText(OnboardingField.age, '17'),
            ).fields[OnboardingField.age],
            InputIssue.adultOnly,
          );
          expect(
            BaselineValidation.checkStep(
              base.withText(OnboardingField.age, '18.0'),
            ).fields[OnboardingField.age],
            InputIssue.invalidNumber,
          );
          for (final (OnboardingField field, String unit) in [
            (OnboardingField.height, 'cm'),
            (OnboardingField.startingWeight, 'kg'),
          ]) {
            for (final String raw in ['0', '-1', 'NaN', 'Infinity']) {
              final OnboardingDraft invalid = base.withQuantity(
                field,
                _quantity(raw, null, unit),
              );
              expect(
                BaselineValidation.checkStep(invalid).fields[field],
                InputIssue.positiveFiniteRequired,
                reason:
                    '$field input $raw must be rejected as a physical value',
              );
            }
          }
        },
      );

      test('height and weight threshold endpoints need no confirmation', () {
        for (final (double height, double weight) in [(100, 25), (250, 350)]) {
          final OnboardingDraft draft = _validDraft()
              .copyWith(step: OnboardingStep.requiredBaseline)
              .withQuantity(
                OnboardingField.height,
                _quantity('$height', height, 'cm'),
              )
              .withQuantity(
                OnboardingField.startingWeight,
                _quantity('$weight', weight, 'kg'),
              );

          expect(
            BaselineValidation.checkStep(draft).confirmationsRequired,
            isEmpty,
            reason:
                'inclusive endpoints $height cm and $weight kg are in range',
          );
        }
      });

      test(
        'converted inch and pound entries confirm only outside canonical bands',
        () {
          final OnboardingDraft belowHeight = _validDraft()
              .copyWith(step: OnboardingStep.requiredBaseline)
              .withQuantity(
                OnboardingField.height,
                _quantity('99', 99 * 2.54, 'inch'),
              );
          final OnboardingDraft aboveWeight = _validDraft()
              .copyWith(step: OnboardingStep.requiredBaseline)
              .withQuantity(
                OnboardingField.startingWeight,
                _quantity('800', 800 * 0.45359237, 'lb'),
              );
          final OnboardingDraft insideConvertedBands = _validDraft()
              .copyWith(step: OnboardingStep.requiredBaseline)
              .withQuantity(
                OnboardingField.height,
                _quantity('98', 98 * 2.54, 'inch'),
              )
              .withQuantity(
                OnboardingField.startingWeight,
                _quantity('56', 56 * 0.45359237, 'lb'),
              );

          expect(
            BaselineValidation.checkStep(belowHeight).confirmationsRequired,
            containsPair(OutlierField.height, 99 * 2.54),
          );
          expect(
            BaselineValidation.checkStep(aboveWeight).confirmationsRequired,
            containsPair(OutlierField.startingWeight, 800 * 0.45359237),
          );
          expect(
            BaselineValidation.checkStep(
              insideConvertedBands,
            ).confirmationsRequired,
            isEmpty,
          );
        },
      );
    });

    group(
      'AC 4: optional observations preserve unknown and reported values',
      () {
        test('zero activity counts remain distinct from unanswered fields', () {
          final CompletedBaseline baseline = _complete(
            _validDraft()
                .withText(OnboardingField.typicalSteps, '0')
                .withText(OnboardingField.trainingDays, '0')
                .withText(OnboardingField.trainingType, '  '),
          );

          expect(baseline.profile.typicalDailySteps, 0);
          expect(baseline.profile.trainingDaysPerWeek, 0);
          expect(baseline.profile.restDaysPerWeek, isNull);
          expect(baseline.profile.trainingType, isNull);
          expect(baseline.profile.activityLevel, isNull);
          expect(baseline.profile.waistCm, isNull);
          expect(baseline.profile.neckCm, isNull);
          expect(baseline.profile.hipCm, isNull);
          expect(baseline.profile.reportedBodyFat, isNull);
        });

        test(
          'body-fat observation keeps its external source through reload',
          () {
            final CompletedBaseline baseline = _complete(
              _validDraft()
                  .withText(OnboardingField.bodyFatPercent, '22.4')
                  .withText(
                    OnboardingField.bodyFatSource,
                    'DEXA report, 2026-10-08',
                  ),
            );
            final String stored = BaselineCodec.encode(
              CompletedBaselineSnapshot(baseline: baseline),
            );
            final CompletedBaseline restored =
                (BaselineCodec.decode(stored).getOrElse(
                          () => throw StateError('Expected valid saved data'),
                        )
                        as CompletedBaselineSnapshot)
                    .baseline;

            expect(restored.profile.reportedBodyFat?.percent, 22.4);
            expect(
              restored.profile.reportedBodyFat?.source,
              'DEXA report, 2026-10-08',
            );
            expect(restored.profile.reportedBodyFat, isA<ReportedBodyFat>());
          },
        );
      },
    );

    group('AC 5–6: unit and observation provenance survive completion', () {
      test(
        'entry units and selected observation day survive a timezone change',
        () {
          final ObservationTime observation = ObservationTime(
            instantUtc: DateTime.utc(2026, 10, 8, 19, 30),
            selectedLocalDay: LocalDay.parse('2026-10-09'),
            originalUtcOffsetMinutes: 330,
          );
          final OnboardingDraft draft = _validDraft()
              .withQuantity(
                OnboardingField.height,
                _quantity('70', 177.8, 'inch'),
              )
              .withQuantity(
                OnboardingField.startingWeight,
                _quantity('${80 / 0.45359237}', 80, 'lb'),
              )
              .withStartingTime(observation)
              .changeUnits(
                const UnitPreferences(
                  weight: WeightUnit.kg,
                  length: LengthUnit.cm,
                ),
              );
          final LocalDay profileDay = LocalDay.parse('2026-10-10');
          final CompletedBaseline baseline = _complete(
            draft,
            profileDay: profileDay,
          );

          expect(baseline.profile.heightCm, 177.8);
          expect(baseline.profile.originalHeightUnit, LengthUnit.inch);
          expect(baseline.profile.preferredUnits.length, LengthUnit.cm);
          expect(baseline.startingWeight.weightKg, 80);
          expect(baseline.startingWeight.originalUnit, WeightUnit.lb);
          expect(
            baseline.startingWeight.observedAt.instantUtc,
            observation.instantUtc,
          );
          expect(
            baseline.startingWeight.observedAt.selectedLocalDay,
            LocalDay.parse('2026-10-09'),
          );
          expect(
            baseline.startingWeight.observedAt.originalUtcOffsetMinutes,
            330,
          );
          expect(baseline.profile.ageRecordedOn, profileDay);
          expect(baseline.goal.effectiveOn, profileDay);

          final CompletedBaseline restored =
              (BaselineCodec.decode(
                        BaselineCodec.encode(
                          CompletedBaselineSnapshot(baseline: baseline),
                        ),
                      ).getOrElse(
                        () => throw StateError('Expected valid saved data'),
                      )
                      as CompletedBaselineSnapshot)
                  .baseline;
          expect(
            restored.startingWeight.observedAt.selectedLocalDay,
            observation.selectedLocalDay,
          );
          expect(
            restored.startingWeight.observedAt.originalUtcOffsetMinutes,
            330,
          );
          expect(restored.goal.effectiveOn, profileDay);
          expect(restored.completedAtUtc, baseline.completedAtUtc);
          expect(restored.profile.metadata, baseline.profile.metadata);
          expect(
            restored.startingWeight.metadata,
            baseline.startingWeight.metadata,
          );
          expect(restored.goal.metadata, baseline.goal.metadata);
        },
      );

      test(
        'loss stores its selected rate while maintenance has no target or rate',
        () {
          final OnboardingDraft lossDraft = _validDraft()
              .withQuantity(
                OnboardingField.goalWeight,
                _quantity('150', 150 * 0.45359237, 'lb'),
              )
              .copyWith(
                goalIntent: GoalIntent.loss,
                lossRate: LossRate.threeQuarterPercent,
              );
          final CompletedBaseline loss = _complete(lossDraft);

          expect(loss.goal, isA<LossGoal>());
          expect((loss.goal as LossGoal).targetWeightKg, 150 * 0.45359237);
          expect(
            (loss.goal as LossGoal).originalTargetWeightUnit,
            WeightUnit.lb,
          );
          expect((loss.goal as LossGoal).rate, LossRate.threeQuarterPercent);

          final OnboardingDraft missingRate = lossDraft.copyWith(
            clearLossRate: true,
          );
          expect(
            BaselineValidation.checkStep(
              missingRate.copyWith(step: OnboardingStep.goalAndApplicability),
            ).missingLossRate,
            isTrue,
          );

          final CompletedBaseline maintenance = _complete(
            _validDraft().copyWith(
              goalIntent: GoalIntent.maintenance,
              clearLossRate: true,
            ),
          );
          expect(maintenance.goal, isA<MaintenanceGoal>());
          expect(maintenance.goal, isNot(isA<LossGoal>()));
          expect(
            BaselineCodec.encode(
              CompletedBaselineSnapshot(baseline: maintenance),
            ),
            isNot(contains('targetWeightKg')),
          );
          expect(
            BaselineCodec.encode(
              CompletedBaselineSnapshot(baseline: maintenance),
            ),
            isNot(contains('"rate"')),
          );
          final Map<String, dynamic> maintenanceWithRate = _object(
            jsonDecode(
              BaselineCodec.encode(
                CompletedBaselineSnapshot(baseline: maintenance),
              ),
            ),
          );
          _object(_object(maintenanceWithRate['payload'])['goal'])['rate'] =
              LossRate.halfPercent.name;
          expect(
            BaselineCodec.decode(jsonEncode(maintenanceWithRate)).isLeft(),
            isTrue,
          );
        },
      );
    });

    group('AC 7: applicability stays explicit and limits automated targets', () {
      test(
        'unknown and yes are retained; either keeps target availability limited',
        () {
          for (final (
                ApplicabilityAnswer pregnancy,
                ApplicabilityAnswer nursing,
              )
              in [
                (ApplicabilityAnswer.unknown, ApplicabilityAnswer.no),
                (ApplicabilityAnswer.yes, ApplicabilityAnswer.no),
                (ApplicabilityAnswer.no, ApplicabilityAnswer.unknown),
                (ApplicabilityAnswer.no, ApplicabilityAnswer.yes),
              ]) {
            final CompletedBaseline baseline = _complete(
              _validDraft().copyWith(
                pregnancy: pregnancy,
                breastfeeding: nursing,
              ),
            );

            expect(baseline.profile.pregnancy, pregnancy);
            expect(baseline.profile.breastfeeding, nursing);
            expect(
              baselineApplicability(pregnancy, nursing),
              AppStrings.applicabilityLimited,
            );
          }

          final CompletedBaseline allNo = _complete(
            _validDraft().copyWith(
              pregnancy: ApplicabilityAnswer.no,
              breastfeeding: ApplicabilityAnswer.no,
            ),
          );
          expect(allNo.profile.pregnancy, ApplicabilityAnswer.no);
          expect(allNo.profile.breastfeeding, ApplicabilityAnswer.no);
          expect(
            baselineApplicability(
              allNo.profile.pregnancy,
              allNo.profile.breastfeeding,
            ),
            AppStrings.applicabilityClear,
          );
        },
      );
    });

    group('AC 2–7: malformed persisted contracts fail closed', () {
      test('draft with a cross-family unit or unknown enum is corrupt', () {
        final OnboardingDraft withWeight = _validDraft().withQuantity(
          OnboardingField.startingWeight,
          _quantity('80', 80, 'kg'),
        );
        final Map<String, dynamic> root = _object(
          jsonDecode(
            BaselineCodec.encode(DraftBaselineSnapshot(draft: withWeight)),
          ),
        );
        final Map<String, dynamic> payload = _object(root['payload']);
        final Map<String, dynamic> quantity = _object(
          _object(payload['quantities'])['startingWeight'],
        );
        quantity['originalUnitToken'] = 'cm';
        quantity['displayUnitToken'] = 'inch';

        expect(BaselineCodec.decode(jsonEncode(root)).isLeft(), isTrue);

        final Map<String, dynamic> badEnumRoot = _object(
          jsonDecode(
            BaselineCodec.encode(DraftBaselineSnapshot(draft: _validDraft())),
          ),
        );
        _object(badEnumRoot['payload'])['pregnancy'] = 'maybe';
        expect(BaselineCodec.decode(jsonEncode(badEnumRoot)).isLeft(), isTrue);
      });

      test(
        'completed data rejects mismatched setup identity and metadata provenance',
        () {
          final CompletedBaseline baseline = _complete(_validDraft());
          final String encoded = BaselineCodec.encode(
            CompletedBaselineSnapshot(baseline: baseline),
          );
          final Map<String, dynamic> badSetup = _object(jsonDecode(encoded));
          _object(badSetup['payload'])['setupId'] = 'another-setup';
          expect(BaselineCodec.decode(jsonEncode(badSetup)).isLeft(), isTrue);

          final Map<String, dynamic> badMetadata = _object(jsonDecode(encoded));
          final Map<String, dynamic> payload = _object(badMetadata['payload']);
          final Map<String, dynamic> profile = _object(payload['profile']);
          final Map<String, dynamic> metadata = _object(profile['metadata']);
          metadata['origin'] = 'external';
          expect(
            BaselineCodec.decode(jsonEncode(badMetadata)).isLeft(),
            isTrue,
          );

          final Map<String, dynamic> badRecordId = _object(jsonDecode(encoded));
          final Map<String, dynamic> badProfile = _object(
            _object(badRecordId['payload'])['profile'],
          );
          _object(badProfile['metadata'])['id'] = 'acceptance:other';
          expect(
            BaselineCodec.decode(jsonEncode(badRecordId)).isLeft(),
            isTrue,
          );

          final OnboardingDraft lossDraft = _validDraft()
              .withQuantity(
                OnboardingField.goalWeight,
                _quantity('150', 150 * 0.45359237, 'lb'),
              )
              .copyWith(
                goalIntent: GoalIntent.loss,
                lossRate: LossRate.halfPercent,
              );
          final CompletedBaseline loss = _complete(lossDraft);
          final Map<String, dynamic> badGoalEnum = _object(
            jsonDecode(
              BaselineCodec.encode(CompletedBaselineSnapshot(baseline: loss)),
            ),
          );
          final Map<String, dynamic> goal = _object(
            _object(badGoalEnum['payload'])['goal'],
          );
          goal['rate'] = 'unspecified';
          expect(
            BaselineCodec.decode(jsonEncode(badGoalEnum)).isLeft(),
            isTrue,
          );
        },
      );
    });
  });
}
