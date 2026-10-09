import '../../../core/router/exports.dart';

enum OnboardingField {
  age,
  height,
  startingWeight,
  waist,
  neck,
  hip,
  bodyFatPercent,
  bodyFatSource,
  typicalSteps,
  trainingDays,
  trainingType,
  restDays,
  goalWeight,
  bodyFatMilestone,
}

enum GoalIntent { loss, maintenance }

enum OutlierField { height, startingWeight }

final class DraftQuantity extends Equatable {
  DraftQuantity({
    required this.rawText,
    required this.canonicalValue,
    required this.originalUnitToken,
    required this.displayUnitToken,
  }) {
    if (canonicalValue != null &&
        (!canonicalValue!.isFinite || canonicalValue! <= 0)) {
      throw ArgumentError.value(canonicalValue, 'canonicalValue');
    }
  }

  final String rawText;
  final double? canonicalValue;
  final String originalUnitToken;
  final String displayUnitToken;

  DraftQuantity copyWith({
    String? rawText,
    double? canonicalValue,
    bool clearCanonicalValue = false,
    String? originalUnitToken,
    String? displayUnitToken,
  }) => DraftQuantity(
    rawText: rawText ?? this.rawText,
    canonicalValue: clearCanonicalValue
        ? null
        : canonicalValue ?? this.canonicalValue,
    originalUnitToken: originalUnitToken ?? this.originalUnitToken,
    displayUnitToken: displayUnitToken ?? this.displayUnitToken,
  );

  @override
  List<Object?> get props => [
    rawText,
    canonicalValue,
    originalUnitToken,
    displayUnitToken,
  ];
}

final class OnboardingDraft extends Equatable {
  OnboardingDraft({
    required this.setupId,
    required this.createdAtUtc,
    required this.updatedAtUtc,
    required this.revision,
    required this.step,
    required this.units,
    required Map<OnboardingField, String> text,
    required Map<OnboardingField, DraftQuantity> quantities,
    required this.startingTime,
    required this.pregnancy,
    required this.breastfeeding,
    this.equationInput,
    this.activityLevel,
    this.goalIntent,
    this.lossRate,
    Map<OutlierField, double> confirmedCanonicalValues = const {},
  }) : text = Map.unmodifiable(text),
       quantities = Map.unmodifiable(quantities),
       confirmedCanonicalValues = Map.unmodifiable(confirmedCanonicalValues) {
    if (setupId.trim().isEmpty) throw ArgumentError.value(setupId, 'setupId');
    if (!createdAtUtc.isUtc ||
        !updatedAtUtc.isUtc ||
        updatedAtUtc.isBefore(createdAtUtc)) {
      throw ArgumentError('Draft timestamps must be ordered UTC instants');
    }
    if (revision < 0) throw ArgumentError.value(revision, 'revision');
    if (this.text.keys.any(this.quantities.containsKey)) {
      throw ArgumentError('A field cannot be both text and a quantity');
    }
    if (this.confirmedCanonicalValues.values.any(
      (v) => !v.isFinite || v <= 0,
    )) {
      throw ArgumentError(
        'Outlier confirmations must be finite positive values',
      );
    }
    if (this.quantities.values.any((quantity) {
      final value = quantity.canonicalValue;
      return value != null && (!value.isFinite || value <= 0);
    })) {
      throw ArgumentError('Canonical quantities must be finite and positive');
    }
    for (final entry in this.confirmedCanonicalValues.entries) {
      final field = entry.key == OutlierField.height
          ? OnboardingField.height
          : OnboardingField.startingWeight;
      final value = this.quantities[field]?.canonicalValue;
      final inRange = entry.key == OutlierField.height
          ? entry.value >= 100 && entry.value <= 250
          : entry.value >= 25 && entry.value <= 350;
      if (value != entry.value || inRange) {
        throw ArgumentError(
          'Outlier confirmation must match an out-of-range value',
        );
      }
    }
  }

  final String setupId;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;
  final int revision;
  final OnboardingStep step;
  final UnitPreferences units;
  final Map<OnboardingField, String> text;
  final Map<OnboardingField, DraftQuantity> quantities;
  final EquationSexInput? equationInput;
  final ObservationTime startingTime;
  final ActivityLevel? activityLevel;
  final GoalIntent? goalIntent;
  final LossRate? lossRate;
  final ApplicabilityAnswer pregnancy;
  final ApplicabilityAnswer breastfeeding;
  final Map<OutlierField, double> confirmedCanonicalValues;

  factory OnboardingDraft.initial({required DateTime now, String? setupId}) {
    final utcNow = now.toUtc();
    return OnboardingDraft(
      setupId: setupId ?? _newSetupId(),
      createdAtUtc: utcNow,
      updatedAtUtc: utcNow,
      revision: 0,
      step: OnboardingStep.purposeAndUnits,
      units: const UnitPreferences(
        weight: WeightUnit.kg,
        length: LengthUnit.cm,
      ),
      text: const {},
      quantities: const {},
      startingTime: ObservationTime.fromSelectedLocal(now),
      pregnancy: ApplicabilityAnswer.unknown,
      breastfeeding: ApplicabilityAnswer.unknown,
    );
  }

  OnboardingDraft copyWith({
    DateTime? updatedAtUtc,
    int? revision,
    OnboardingStep? step,
    UnitPreferences? units,
    Map<OnboardingField, String>? text,
    Map<OnboardingField, DraftQuantity>? quantities,
    EquationSexInput? equationInput,
    bool clearEquationInput = false,
    ObservationTime? startingTime,
    ActivityLevel? activityLevel,
    bool clearActivityLevel = false,
    GoalIntent? goalIntent,
    bool clearGoalIntent = false,
    LossRate? lossRate,
    bool clearLossRate = false,
    ApplicabilityAnswer? pregnancy,
    ApplicabilityAnswer? breastfeeding,
    Map<OutlierField, double>? confirmedCanonicalValues,
  }) => OnboardingDraft(
    setupId: setupId,
    createdAtUtc: createdAtUtc,
    updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
    revision: revision ?? this.revision,
    step: step ?? this.step,
    units: units ?? this.units,
    text: text ?? this.text,
    quantities: quantities ?? this.quantities,
    equationInput: clearEquationInput
        ? null
        : equationInput ?? this.equationInput,
    startingTime: startingTime ?? this.startingTime,
    activityLevel: clearActivityLevel
        ? null
        : activityLevel ?? this.activityLevel,
    goalIntent: clearGoalIntent ? null : goalIntent ?? this.goalIntent,
    lossRate: clearLossRate ? null : lossRate ?? this.lossRate,
    pregnancy: pregnancy ?? this.pregnancy,
    breastfeeding: breastfeeding ?? this.breastfeeding,
    confirmedCanonicalValues:
        confirmedCanonicalValues ?? this.confirmedCanonicalValues,
  );

  OnboardingDraft withText(OnboardingField field, String value) {
    final nextText = Map<OnboardingField, String>.of(text)..[field] = value;
    final nextQuantities = Map<OnboardingField, DraftQuantity>.of(quantities)
      ..remove(field);
    return copyWith(text: nextText, quantities: nextQuantities);
  }

  OnboardingDraft withQuantity(OnboardingField field, DraftQuantity value) {
    final nextQuantities = Map<OnboardingField, DraftQuantity>.of(quantities)
      ..[field] = value;
    final nextText = Map<OnboardingField, String>.of(text)..remove(field);
    final nextConfirmed = Map<OutlierField, double>.of(
      confirmedCanonicalValues,
    );
    if (field == OnboardingField.height) {
      nextConfirmed.remove(OutlierField.height);
    }
    if (field == OnboardingField.startingWeight) {
      nextConfirmed.remove(OutlierField.startingWeight);
    }
    return copyWith(
      text: nextText,
      quantities: nextQuantities,
      confirmedCanonicalValues: nextConfirmed,
    );
  }

  OnboardingDraft withStartingTime(ObservationTime value) =>
      copyWith(startingTime: value);

  OnboardingDraft changeUnits(UnitPreferences value) {
    final converted = Map<OnboardingField, DraftQuantity>.of(quantities);
    for (final entry in quantities.entries) {
      final quantity = entry.value;
      if (quantity.canonicalValue == null) continue;
      final targetUnit = _displayTokenFor(entry.key, value);
      if (targetUnit == null) continue;
      final displayValue = _fromCanonical(quantity.canonicalValue!, targetUnit);
      converted[entry.key] = quantity.copyWith(
        rawText: displayValue.toString(),
        displayUnitToken: targetUnit,
      );
    }
    return copyWith(units: value, quantities: converted);
  }

  OnboardingDraft confirmOutlier(OutlierField field, double canonicalValue) {
    final value =
        quantities[field == OutlierField.height
                ? OnboardingField.height
                : OnboardingField.startingWeight]
            ?.canonicalValue;
    if (value == null || value != canonicalValue) {
      throw ArgumentError('Confirmation must match the current field value');
    }
    return copyWith(
      confirmedCanonicalValues: {
        ...confirmedCanonicalValues,
        field: canonicalValue,
      },
    );
  }

  bool isOutlierConfirmed(OutlierField field) {
    final canonical =
        quantities[field == OutlierField.height
                ? OnboardingField.height
                : OnboardingField.startingWeight]
            ?.canonicalValue;
    return canonical != null && confirmedCanonicalValues[field] == canonical;
  }

  @override
  List<Object?> get props => [
    setupId,
    createdAtUtc,
    updatedAtUtc,
    revision,
    step,
    units,
    text,
    quantities,
    equationInput,
    startingTime,
    activityLevel,
    goalIntent,
    lossRate,
    pregnancy,
    breastfeeding,
    confirmedCanonicalValues,
  ];
}

String _newSetupId() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
}

String? _displayTokenFor(OnboardingField field, UnitPreferences units) =>
    switch (field) {
      OnboardingField.height ||
      OnboardingField.waist ||
      OnboardingField.neck ||
      OnboardingField.hip => units.length.name,
      OnboardingField.startingWeight ||
      OnboardingField.goalWeight => units.weight.name,
      _ => null,
    };

double _fromCanonical(double value, String unit) => switch (unit) {
  'kg' => value,
  'lb' => value / 0.45359237,
  'cm' => value,
  'inch' => value / 2.54,
  _ => throw ArgumentError.value(unit, 'unit'),
};
