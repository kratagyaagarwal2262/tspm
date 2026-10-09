import 'package:flutter_test/flutter_test.dart';
import 'package:tspm/core/router/exports.dart';

void main() {
  test('draft snapshot preserves invalid text and optional unknown state', () {
    final draft =
        OnboardingDraft.initial(
              now: DateTime.utc(2026, 10, 9),
              setupId: 'setup-a',
            )
            .withText(OnboardingField.age, 'not a number')
            .withText(OnboardingField.typicalSteps, '0');
    final snapshot = DraftBaselineSnapshot(draft: draft);
    final decoded = BaselineCodec.decode(BaselineCodec.encode(snapshot));

    expect(decoded.isRight(), isTrue);
    final restored =
        (decoded.toOption().toNullable() as DraftBaselineSnapshot).draft;
    expect(restored.text[OnboardingField.age], 'not a number');
    expect(restored.text[OnboardingField.typicalSteps], '0');
    expect(restored.activityLevel, isNull);
    expect(restored.pregnancy, ApplicabilityAnswer.unknown);
  });

  test(
    'snapshot rejects unsupported schema versions without interpreting payload',
    () {
      final result = BaselineCodec.decode(
        '{"schemaVersion":2,"kind":"draft","setupId":"x","payload":{}}',
      );

      expect(result.isLeft(), isTrue);
      final failure = result.swap().toOption().toNullable()!;
      expect(failure.reason, BaselineFailureReason.unsupportedVersion);
      expect(failure.unsupportedVersion, 2);
    },
  );

  test(
    'snapshot rejects canonical quantity inconsistent with displayed text',
    () {
      final draft =
          OnboardingDraft.initial(
            now: DateTime.utc(2026),
            setupId: 'setup-a',
          ).withQuantity(
            OnboardingField.startingWeight,
            DraftQuantity(
              rawText: '100',
              canonicalValue: 45.359237,
              originalUnitToken: 'kg',
              displayUnitToken: 'lb',
            ),
          );
      final json = BaselineCodec.encode(DraftBaselineSnapshot(draft: draft));
      final tampered = json.replaceFirst('45.359237', '55');

      final result = BaselineCodec.decode(tampered);
      expect(result.isLeft(), isTrue);
      expect(
        result.swap().toOption().toNullable()!.reason,
        BaselineFailureReason.corrupt,
      );
    },
  );
}
