import '../../../core/router/exports.dart';

enum WeightUnit { kg, lb }

enum LengthUnit { cm, inch }

enum EquationSexInput { male, female }

enum ApplicabilityAnswer { unknown, no, yes }

enum RecordOrigin { manuallyEntered, externallyReported }

enum ActivityLevel {
  sedentary,
  lightlyActive,
  moderatelyActive,
  veryActive,
  extremelyActive,
}

enum LossRate { quarterPercent, halfPercent, threeQuarterPercent, onePercent }

enum OnboardingStep {
  purposeAndUnits,
  requiredBaseline,
  measurements,
  activity,
  goalAndApplicability,
}

final class UnitPreferences extends Equatable {
  const UnitPreferences({required this.weight, required this.length});

  final WeightUnit weight;
  final LengthUnit length;

  @override
  List<Object> get props => [weight, length];
}

final class LocalDay extends Equatable {
  const LocalDay._(this.year, this.month, this.day);

  factory LocalDay({required int year, required int month, required int day}) {
    final date = DateTime.utc(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      throw ArgumentError.value('$year-$month-$day', 'day', 'Invalid date');
    }
    return LocalDay._(year, month, day);
  }

  final int year;
  final int month;
  final int day;

  static LocalDay parse(String isoDay) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(isoDay);
    if (match == null) throw FormatException('Invalid local day', isoDay);
    try {
      return LocalDay(
        year: int.parse(match[1]!),
        month: int.parse(match[2]!),
        day: int.parse(match[3]!),
      );
    } on ArgumentError {
      throw FormatException('Invalid local day', isoDay);
    }
  }

  String toIsoDay() =>
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

  @override
  List<Object> get props => [year, month, day];
}

final class ObservationTime extends Equatable {
  ObservationTime({
    required this.instantUtc,
    required this.selectedLocalDay,
    required this.originalUtcOffsetMinutes,
  }) {
    if (!instantUtc.isUtc) throw ArgumentError.value(instantUtc, 'instantUtc');
    final reproduced = instantUtc.add(
      Duration(minutes: originalUtcOffsetMinutes),
    );
    if (reproduced.year != selectedLocalDay.year ||
        reproduced.month != selectedLocalDay.month ||
        reproduced.day != selectedLocalDay.day) {
      throw ArgumentError(
        'Instant and offset do not reproduce selected local day',
      );
    }
    if (originalUtcOffsetMinutes.abs() > 14 * 60) {
      throw ArgumentError.value(
        originalUtcOffsetMinutes,
        'originalUtcOffsetMinutes',
      );
    }
  }

  final DateTime instantUtc;
  final LocalDay selectedLocalDay;
  final int originalUtcOffsetMinutes;

  factory ObservationTime.fromSelectedLocal(DateTime selectedLocal) {
    final offset = selectedLocal.timeZoneOffset.inMinutes;
    final instant = selectedLocal.toUtc();
    return ObservationTime(
      instantUtc: instant,
      selectedLocalDay: LocalDay(
        year: selectedLocal.year,
        month: selectedLocal.month,
        day: selectedLocal.day,
      ),
      originalUtcOffsetMinutes: offset,
    );
  }

  DateTime get selectedLocalDateTime =>
      instantUtc.add(Duration(minutes: originalUtcOffsetMinutes));

  @override
  List<Object> get props => [
    instantUtc,
    selectedLocalDay,
    originalUtcOffsetMinutes,
  ];
}

final class RecordMetadata extends Equatable {
  RecordMetadata({
    required this.id,
    required this.createdAtUtc,
    required this.updatedAtUtc,
    required this.origin,
  }) {
    if (id.trim().isEmpty) throw ArgumentError.value(id, 'id');
    if (!createdAtUtc.isUtc || !updatedAtUtc.isUtc) {
      throw ArgumentError('Record timestamps must be UTC');
    }
    if (updatedAtUtc.isBefore(createdAtUtc)) {
      throw ArgumentError('updatedAtUtc precedes createdAtUtc');
    }
  }

  final String id;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;
  final RecordOrigin origin;

  @override
  List<Object> get props => [id, createdAtUtc, updatedAtUtc, origin];
}

final class ReportedBodyFat extends Equatable {
  ReportedBodyFat({required this.percent, required this.source}) {
    _requirePercent(percent, 'percent');
    if (source.trim().isEmpty) throw ArgumentError.value(source, 'source');
  }

  final double percent;
  final String source;

  @override
  List<Object> get props => [percent, source];
}

final class BaselineProfile extends Equatable {
  BaselineProfile({
    required this.metadata,
    required this.ageYears,
    required this.ageRecordedOn,
    required this.equationInput,
    required this.heightCm,
    required this.originalHeightUnit,
    required this.preferredUnits,
    this.waistCm,
    this.originalWaistUnit,
    this.neckCm,
    this.originalNeckUnit,
    this.hipCm,
    this.originalHipUnit,
    this.reportedBodyFat,
    this.activityLevel,
    this.typicalDailySteps,
    this.trainingDaysPerWeek,
    this.trainingType,
    this.restDaysPerWeek,
    required this.pregnancy,
    required this.breastfeeding,
  }) {
    if (ageYears < 18) throw ArgumentError.value(ageYears, 'ageYears');
    _requirePositive(heightCm, 'heightCm');
    _optionalLength(waistCm, originalWaistUnit, 'waistCm');
    _optionalLength(neckCm, originalNeckUnit, 'neckCm');
    _optionalLength(hipCm, originalHipUnit, 'hipCm');
    if ((typicalDailySteps != null && typicalDailySteps! < 0) ||
        (trainingDaysPerWeek != null &&
            (trainingDaysPerWeek! < 0 || trainingDaysPerWeek! > 7)) ||
        (restDaysPerWeek != null &&
            (restDaysPerWeek! < 0 || restDaysPerWeek! > 7))) {
      throw ArgumentError('Invalid activity count');
    }
  }

  final RecordMetadata metadata;
  final int ageYears;
  final LocalDay ageRecordedOn;
  final EquationSexInput equationInput;
  final double heightCm;
  final LengthUnit originalHeightUnit;
  final UnitPreferences preferredUnits;
  final double? waistCm;
  final LengthUnit? originalWaistUnit;
  final double? neckCm;
  final LengthUnit? originalNeckUnit;
  final double? hipCm;
  final LengthUnit? originalHipUnit;
  final ReportedBodyFat? reportedBodyFat;
  final ActivityLevel? activityLevel;
  final int? typicalDailySteps;
  final int? trainingDaysPerWeek;
  final String? trainingType;
  final int? restDaysPerWeek;
  final ApplicabilityAnswer pregnancy;
  final ApplicabilityAnswer breastfeeding;

  @override
  List<Object?> get props => [
    metadata,
    ageYears,
    ageRecordedOn,
    equationInput,
    heightCm,
    originalHeightUnit,
    preferredUnits,
    waistCm,
    originalWaistUnit,
    neckCm,
    originalNeckUnit,
    hipCm,
    originalHipUnit,
    reportedBodyFat,
    activityLevel,
    typicalDailySteps,
    trainingDaysPerWeek,
    trainingType,
    restDaysPerWeek,
    pregnancy,
    breastfeeding,
  ];
}

final class StartingWeightObservation extends Equatable {
  StartingWeightObservation({
    required this.metadata,
    required this.weightKg,
    required this.originalUnit,
    required this.observedAt,
    required this.source,
  }) {
    _requirePositive(weightKg, 'weightKg');
    if (source.trim().isEmpty) throw ArgumentError.value(source, 'source');
  }

  final RecordMetadata metadata;
  final double weightKg;
  final WeightUnit originalUnit;
  final ObservationTime observedAt;
  final String source;

  @override
  List<Object> get props => [
    metadata,
    weightKg,
    originalUnit,
    observedAt,
    source,
  ];
}

sealed class InitialGoal extends Equatable {
  const InitialGoal({
    required this.metadata,
    required this.effectiveOn,
    this.bodyFatMilestonePercent,
  });

  final RecordMetadata metadata;
  final LocalDay effectiveOn;
  final double? bodyFatMilestonePercent;

  @override
  List<Object?> get props => [metadata, effectiveOn, bodyFatMilestonePercent];
}

final class MaintenanceGoal extends InitialGoal {
  const MaintenanceGoal({
    required super.metadata,
    required super.effectiveOn,
    super.bodyFatMilestonePercent,
  });
}

final class LossGoal extends InitialGoal {
  LossGoal({
    required super.metadata,
    required super.effectiveOn,
    required this.targetWeightKg,
    required this.originalTargetWeightUnit,
    required this.rate,
    super.bodyFatMilestonePercent,
  }) {
    _requirePositive(targetWeightKg, 'targetWeightKg');
    if (bodyFatMilestonePercent != null) {
      _requirePercent(bodyFatMilestonePercent!, 'bodyFatMilestonePercent');
    }
  }

  final double targetWeightKg;
  final WeightUnit originalTargetWeightUnit;
  final LossRate rate;

  @override
  List<Object?> get props => [
    ...super.props,
    targetWeightKg,
    originalTargetWeightUnit,
    rate,
  ];
}

final class CompletedBaseline extends Equatable {
  CompletedBaseline({
    required this.setupId,
    required this.completedAtUtc,
    required this.profile,
    required this.startingWeight,
    required this.goal,
  }) {
    if (setupId.trim().isEmpty) throw ArgumentError.value(setupId, 'setupId');
    if (!completedAtUtc.isUtc) {
      throw ArgumentError('completedAtUtc must be UTC');
    }
    final records = <(RecordMetadata, String)>[
      (profile.metadata, 'profile'),
      (startingWeight.metadata, 'starting-weight'),
      (goal.metadata, 'initial-goal'),
    ];
    for (final (metadata, role) in records) {
      if (metadata.id != '$setupId:$role' ||
          metadata.origin != RecordOrigin.manuallyEntered ||
          metadata.updatedAtUtc.isAfter(completedAtUtc)) {
        throw ArgumentError('Invalid committed record identity or provenance');
      }
    }
    if (goal is MaintenanceGoal && goal.bodyFatMilestonePercent != null) {
      _requirePercent(goal.bodyFatMilestonePercent!, 'bodyFatMilestonePercent');
    }
  }

  final String setupId;
  final DateTime completedAtUtc;
  final BaselineProfile profile;
  final StartingWeightObservation startingWeight;
  final InitialGoal goal;

  @override
  List<Object> get props => [
    setupId,
    completedAtUtc,
    profile,
    startingWeight,
    goal,
  ];
}

void _requirePositive(double value, String name) {
  if (!value.isFinite || value <= 0) throw ArgumentError.value(value, name);
}

void _requirePercent(double value, String name) {
  if (!value.isFinite || value <= 0 || value >= 100) {
    throw ArgumentError.value(value, name);
  }
}

void _optionalLength(double? value, LengthUnit? unit, String name) {
  if ((value == null) != (unit == null)) {
    throw ArgumentError(
      '$name and its original unit must both be absent or present',
    );
  }
  if (value != null) _requirePositive(value, name);
}
