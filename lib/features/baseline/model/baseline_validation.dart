import '../../../core/router/exports.dart';

enum InputIssue {
  required,
  invalidNumber,
  adultOnly,
  positiveFiniteRequired,
  invalidDateTime,
  percentageRange,
  dayCountRange,
  sourceRequired,
}

final class FormProblems extends Equatable {
  FormProblems({
    Map<OnboardingField, InputIssue> fields = const {},
    this.invalidStartingTime = false,
    this.missingEquationInput = false,
    this.missingGoalIntent = false,
    this.missingLossRate = false,
    Map<OutlierField, double> confirmationsRequired = const {},
  }) : fields = Map.unmodifiable(fields),
       confirmationsRequired = Map.unmodifiable(confirmationsRequired);

  final Map<OnboardingField, InputIssue> fields;
  final bool invalidStartingTime;
  final bool missingEquationInput;
  final bool missingGoalIntent;
  final bool missingLossRate;
  final Map<OutlierField, double> confirmationsRequired;

  bool get isEmpty =>
      fields.isEmpty &&
      !invalidStartingTime &&
      !missingEquationInput &&
      !missingGoalIntent &&
      !missingLossRate &&
      confirmationsRequired.isEmpty;

  @override
  List<Object?> get props => [
    fields,
    invalidStartingTime,
    missingEquationInput,
    missingGoalIntent,
    missingLossRate,
    confirmationsRequired,
  ];
}

abstract final class BaselineValidation {
  static FormProblems checkStep(OnboardingDraft draft) {
    final issues = <OnboardingField, InputIssue>{};
    var badTime = false;
    var missingEquation = false;
    var missingGoal = false;
    var missingRate = false;
    final confirmations = <OutlierField, double>{};
    switch (draft.step) {
      case OnboardingStep.purposeAndUnits:
        break;
      case OnboardingStep.requiredBaseline:
        final age = _readNumber(draft, OnboardingField.age, issues);
        if (age != null) {
          if (int.tryParse(draft.text[OnboardingField.age]?.trim() ?? '') ==
              null) {
            issues[OnboardingField.age] = InputIssue.invalidNumber;
          } else if (age < 18) {
            issues[OnboardingField.age] = InputIssue.adultOnly;
          }
        }
        missingEquation = draft.equationInput == null;
        final height = draft.quantities[OnboardingField.height]?.canonicalValue;
        _requiredPositive(
          height,
          OnboardingField.height,
          issues,
          rawText: draft.quantities[OnboardingField.height]?.rawText,
        );
        if (height != null &&
            (height < 100 || height > 250) &&
            !draft.isOutlierConfirmed(OutlierField.height)) {
          confirmations[OutlierField.height] = height;
        }
        final weight =
            draft.quantities[OnboardingField.startingWeight]?.canonicalValue;
        _requiredPositive(
          weight,
          OnboardingField.startingWeight,
          issues,
          rawText: draft.quantities[OnboardingField.startingWeight]?.rawText,
        );
        if (weight != null &&
            (weight < 25 || weight > 350) &&
            !draft.isOutlierConfirmed(OutlierField.startingWeight)) {
          confirmations[OutlierField.startingWeight] = weight;
        }
        badTime = draft.startingTime.originalUtcOffsetMinutes.abs() > 14 * 60;
      case OnboardingStep.measurements:
        _optionalPositive(draft, OnboardingField.waist, issues);
        _optionalPositive(draft, OnboardingField.neck, issues);
        _optionalPositive(draft, OnboardingField.hip, issues);
        final bodyFat = _readNumber(
          draft,
          OnboardingField.bodyFatPercent,
          issues,
          optional: true,
        );
        if (bodyFat != null && (bodyFat <= 0 || bodyFat >= 100)) {
          issues[OnboardingField.bodyFatPercent] = InputIssue.percentageRange;
        }
        if (bodyFat != null &&
            (draft.text[OnboardingField.bodyFatSource]?.trim().isEmpty ??
                true)) {
          issues[OnboardingField.bodyFatSource] = InputIssue.sourceRequired;
        }
      case OnboardingStep.activity:
        _optionalNonNegativeInteger(
          draft,
          OnboardingField.typicalSteps,
          issues,
        );
        _optionalDays(draft, OnboardingField.trainingDays, issues);
        _optionalDays(draft, OnboardingField.restDays, issues);
      case OnboardingStep.goalAndApplicability:
        if (draft.goalIntent == null) {
          missingGoal = true;
        } else if (draft.goalIntent == GoalIntent.loss) {
          final goalWeight =
              draft.quantities[OnboardingField.goalWeight]?.canonicalValue;
          _requiredPositive(
            goalWeight,
            OnboardingField.goalWeight,
            issues,
            rawText: draft.quantities[OnboardingField.goalWeight]?.rawText,
          );
          missingRate = draft.lossRate == null;
        }
        final milestone = _readNumber(
          draft,
          OnboardingField.bodyFatMilestone,
          issues,
          optional: true,
        );
        if (milestone != null && (milestone <= 0 || milestone >= 100)) {
          issues[OnboardingField.bodyFatMilestone] = InputIssue.percentageRange;
        }
    }
    return FormProblems(
      fields: issues,
      invalidStartingTime: badTime,
      missingEquationInput: missingEquation,
      missingGoalIntent: missingGoal,
      missingLossRate: missingRate,
      confirmationsRequired: confirmations,
    );
  }

  static Either<FormProblems, CompletedBaseline> prepareCompletion(
    OnboardingDraft draft,
    DateTime completedAtUtc,
    LocalDay profileDay,
  ) {
    final problems = _completionProblems(draft);
    if (!problems.isEmpty) return left(problems);
    final now = completedAtUtc.toUtc();
    final profileMetadata = _metadata(draft.setupId, 'profile', now);
    final weightMetadata = _metadata(draft.setupId, 'starting-weight', now);
    final goalMetadata = _metadata(draft.setupId, 'initial-goal', now);
    final preferred = draft.units;
    final bodyFat = _optionalDouble(draft, OnboardingField.bodyFatPercent);
    final goal = draft.goalIntent == GoalIntent.loss
        ? LossGoal(
            metadata: goalMetadata,
            effectiveOn: profileDay,
            targetWeightKg:
                draft.quantities[OnboardingField.goalWeight]!.canonicalValue!,
            originalTargetWeightUnit: _weightUnit(
              draft.quantities[OnboardingField.goalWeight]!.originalUnitToken,
            ),
            rate: draft.lossRate!,
            bodyFatMilestonePercent: _optionalDouble(
              draft,
              OnboardingField.bodyFatMilestone,
            ),
          )
        : MaintenanceGoal(
            metadata: goalMetadata,
            effectiveOn: profileDay,
            bodyFatMilestonePercent: _optionalDouble(
              draft,
              OnboardingField.bodyFatMilestone,
            ),
          );
    return right(
      CompletedBaseline(
        setupId: draft.setupId,
        completedAtUtc: now,
        profile: BaselineProfile(
          metadata: profileMetadata,
          ageYears: int.parse(draft.text[OnboardingField.age]!.trim()),
          ageRecordedOn: profileDay,
          equationInput: draft.equationInput!,
          heightCm: draft.quantities[OnboardingField.height]!.canonicalValue!,
          originalHeightUnit: _lengthUnit(
            draft.quantities[OnboardingField.height]!.originalUnitToken,
          ),
          preferredUnits: preferred,
          waistCm: draft.quantities[OnboardingField.waist]?.canonicalValue,
          originalWaistUnit: _optionalLengthUnit(draft, OnboardingField.waist),
          neckCm: draft.quantities[OnboardingField.neck]?.canonicalValue,
          originalNeckUnit: _optionalLengthUnit(draft, OnboardingField.neck),
          hipCm: draft.quantities[OnboardingField.hip]?.canonicalValue,
          originalHipUnit: _optionalLengthUnit(draft, OnboardingField.hip),
          reportedBodyFat: bodyFat == null
              ? null
              : ReportedBodyFat(
                  percent: bodyFat,
                  source: draft.text[OnboardingField.bodyFatSource]!.trim(),
                ),
          activityLevel: draft.activityLevel,
          typicalDailySteps: _optionalInt(draft, OnboardingField.typicalSteps),
          trainingDaysPerWeek: _optionalInt(
            draft,
            OnboardingField.trainingDays,
          ),
          trainingType: _optionalText(draft, OnboardingField.trainingType),
          restDaysPerWeek: _optionalInt(draft, OnboardingField.restDays),
          pregnancy: draft.pregnancy,
          breastfeeding: draft.breastfeeding,
        ),
        startingWeight: StartingWeightObservation(
          metadata: weightMetadata,
          weightKg:
              draft.quantities[OnboardingField.startingWeight]!.canonicalValue!,
          originalUnit: _weightUnit(
            draft.quantities[OnboardingField.startingWeight]!.originalUnitToken,
          ),
          observedAt: draft.startingTime,
          source: 'manual scale entry',
        ),
        goal: goal,
      ),
    );
  }

  static double weightToKg(double value, WeightUnit unit) =>
      unit == WeightUnit.kg ? value : value * 0.45359237;

  static double weightFromKg(double value, WeightUnit unit) =>
      unit == WeightUnit.kg ? value : value / 0.45359237;

  static double lengthToCm(double value, LengthUnit unit) =>
      unit == LengthUnit.cm ? value : value * 2.54;

  static double lengthFromCm(double value, LengthUnit unit) =>
      unit == LengthUnit.cm ? value : value / 2.54;

  static FormProblems _completionProblems(OnboardingDraft draft) {
    FormProblems at(OnboardingStep step) =>
        checkStep(draft.copyWith(step: step));
    final required = at(OnboardingStep.requiredBaseline);
    final measurements = at(OnboardingStep.measurements);
    final activity = at(OnboardingStep.activity);
    final goal = at(OnboardingStep.goalAndApplicability);
    return FormProblems(
      fields: {
        ...required.fields,
        ...measurements.fields,
        ...activity.fields,
        ...goal.fields,
      },
      invalidStartingTime: required.invalidStartingTime,
      missingEquationInput: required.missingEquationInput,
      missingGoalIntent: goal.missingGoalIntent,
      missingLossRate: goal.missingLossRate,
      confirmationsRequired: {
        ...required.confirmationsRequired,
        ...measurements.confirmationsRequired,
        ...activity.confirmationsRequired,
        ...goal.confirmationsRequired,
      },
    );
  }
}

void _requiredPositive(
  double? value,
  OnboardingField field,
  Map<OnboardingField, InputIssue> issues, {
  String? rawText,
}) {
  if (value == null) {
    issues[field] = rawText == null || rawText.trim().isEmpty
        ? InputIssue.required
        : InputIssue.positiveFiniteRequired;
  } else if (!value.isFinite || value <= 0) {
    issues[field] = InputIssue.positiveFiniteRequired;
  }
}

void _optionalPositive(
  OnboardingDraft draft,
  OnboardingField field,
  Map<OnboardingField, InputIssue> issues,
) {
  final value = draft.quantities[field];
  if (value == null || value.rawText.trim().isEmpty) return;
  if (value.canonicalValue == null ||
      !value.canonicalValue!.isFinite ||
      value.canonicalValue! <= 0) {
    issues[field] = InputIssue.positiveFiniteRequired;
  }
}

double? _readNumber(
  OnboardingDraft draft,
  OnboardingField field,
  Map<OnboardingField, InputIssue> issues, {
  bool optional = false,
}) {
  final raw = draft.text[field];
  if (raw == null || raw.trim().isEmpty) {
    if (!optional) issues[field] = InputIssue.required;
    return null;
  }
  final value = double.tryParse(raw.trim());
  if (value == null || !value.isFinite) {
    issues[field] = InputIssue.invalidNumber;
    return null;
  }
  return value;
}

void _optionalNonNegativeInteger(
  OnboardingDraft draft,
  OnboardingField field,
  Map<OnboardingField, InputIssue> issues,
) {
  final value = _readNumber(draft, field, issues, optional: true);
  if (value != null && (value < 0 || value != value.truncateToDouble())) {
    issues[field] = InputIssue.dayCountRange;
  }
}

void _optionalDays(
  OnboardingDraft draft,
  OnboardingField field,
  Map<OnboardingField, InputIssue> issues,
) {
  final value = _readNumber(draft, field, issues, optional: true);
  if (value != null &&
      (value < 0 || value > 7 || value != value.truncateToDouble())) {
    issues[field] = InputIssue.dayCountRange;
  }
}

RecordMetadata _metadata(String setupId, String role, DateTime now) =>
    RecordMetadata(
      id: '$setupId:$role',
      createdAtUtc: now,
      updatedAtUtc: now,
      origin: RecordOrigin.manuallyEntered,
    );

double? _optionalDouble(OnboardingDraft draft, OnboardingField field) {
  final quantity = draft.quantities[field];
  if (quantity != null) return quantity.canonicalValue;
  final raw = draft.text[field];
  return raw == null || raw.trim().isEmpty ? null : double.parse(raw.trim());
}

int? _optionalInt(OnboardingDraft draft, OnboardingField field) {
  final value = _optionalDouble(draft, field);
  return value?.toInt();
}

String? _optionalText(OnboardingDraft draft, OnboardingField field) {
  final value = draft.text[field]?.trim();
  return value == null || value.isEmpty ? null : value;
}

WeightUnit _weightUnit(String token) => switch (token) {
  'kg' => WeightUnit.kg,
  'lb' => WeightUnit.lb,
  _ => throw ArgumentError.value(token),
};

LengthUnit _lengthUnit(String token) => switch (token) {
  'cm' => LengthUnit.cm,
  'inch' => LengthUnit.inch,
  _ => throw ArgumentError.value(token),
};

LengthUnit? _optionalLengthUnit(OnboardingDraft draft, OnboardingField field) {
  final quantity = draft.quantities[field];
  return quantity?.canonicalValue == null
      ? null
      : _lengthUnit(quantity!.originalUnitToken);
}
