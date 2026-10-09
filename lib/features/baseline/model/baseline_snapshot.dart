import '../../../core/router/exports.dart';

sealed class BaselineSnapshot extends Equatable {
  const BaselineSnapshot({required this.setupId});

  final int schemaVersion = 1;
  final String setupId;

  @override
  List<Object> get props => [schemaVersion, setupId];
}

final class DraftBaselineSnapshot extends BaselineSnapshot {
  DraftBaselineSnapshot({required this.draft}) : super(setupId: draft.setupId);

  final OnboardingDraft draft;

  @override
  List<Object> get props => [...super.props, draft];
}

final class CompletedBaselineSnapshot extends BaselineSnapshot {
  CompletedBaselineSnapshot({required this.baseline})
    : super(setupId: baseline.setupId);

  final CompletedBaseline baseline;

  @override
  List<Object> get props => [...super.props, baseline];
}

abstract final class BaselineCodec {
  static String encode(BaselineSnapshot snapshot) => jsonEncode({
    'schemaVersion': 1,
    'kind': switch (snapshot) {
      DraftBaselineSnapshot() => 'draft',
      CompletedBaselineSnapshot() => 'completed',
    },
    'setupId': snapshot.setupId,
    'payload': switch (snapshot) {
      DraftBaselineSnapshot(:final draft) => _draftJson(draft),
      CompletedBaselineSnapshot(:final baseline) => _baselineJson(baseline),
    },
  });

  static Either<BaselineFailure, BaselineSnapshot> decode(String json) {
    try {
      final root = _object(jsonDecode(json), 'snapshot');
      _keys(root, const {'schemaVersion', 'kind', 'setupId', 'payload'});
      final version = _integer(root['schemaVersion'], 'schemaVersion');
      if (version != 1) {
        return left(
          BaselineFailure(
            operation: BaselineOperation.load,
            reason: BaselineFailureReason.unsupportedVersion,
            unsupportedVersion: version,
          ),
        );
      }
      final kind = _string(root['kind'], 'kind');
      final setupId = _string(root['setupId'], 'setupId');
      final payload = _object(root['payload'], 'payload');
      final BaselineSnapshot snapshot = switch (kind) {
        'draft' => DraftBaselineSnapshot(draft: _readDraft(payload)),
        'completed' => CompletedBaselineSnapshot(
          baseline: _readBaseline(payload),
        ),
        _ => throw FormatException('Invalid snapshot kind'),
      };
      if (snapshot.setupId != setupId) {
        throw FormatException('Snapshot and payload setup IDs differ');
      }
      return right(snapshot);
    } on Object {
      return left(
        const BaselineFailure(
          operation: BaselineOperation.load,
          reason: BaselineFailureReason.corrupt,
        ),
      );
    }
  }
}

Map<String, Object?> _draftJson(OnboardingDraft draft) => {
  'setupId': draft.setupId,
  'createdAtUtc': draft.createdAtUtc.toIso8601String(),
  'updatedAtUtc': draft.updatedAtUtc.toIso8601String(),
  'revision': draft.revision,
  'step': draft.step.name,
  'units': {
    'weight': draft.units.weight.name,
    'length': draft.units.length.name,
  },
  'text': {for (final e in draft.text.entries) e.key.name: e.value},
  'quantities': {
    for (final e in draft.quantities.entries)
      e.key.name: {
        'rawText': e.value.rawText,
        'canonicalValue': e.value.canonicalValue,
        'originalUnitToken': e.value.originalUnitToken,
        'displayUnitToken': e.value.displayUnitToken,
      },
  },
  'equationInput': draft.equationInput?.name,
  'startingTime': _observationTimeJson(draft.startingTime),
  'activityLevel': draft.activityLevel?.name,
  'goalIntent': draft.goalIntent?.name,
  'lossRate': draft.lossRate?.name,
  'pregnancy': draft.pregnancy.name,
  'breastfeeding': draft.breastfeeding.name,
  'confirmedCanonicalValues': {
    for (final e in draft.confirmedCanonicalValues.entries) e.key.name: e.value,
  },
};

Map<String, Object?> _baselineJson(CompletedBaseline baseline) => {
  'setupId': baseline.setupId,
  'completedAtUtc': baseline.completedAtUtc.toIso8601String(),
  'profile': _profileJson(baseline.profile),
  'startingWeight': _startingWeightJson(baseline.startingWeight),
  'goal': _goalJson(baseline.goal),
};

Map<String, Object?> _profileJson(BaselineProfile profile) => {
  'metadata': _metadataJson(profile.metadata),
  'ageYears': profile.ageYears,
  'ageRecordedOn': profile.ageRecordedOn.toIsoDay(),
  'equationInput': profile.equationInput.name,
  'heightCm': profile.heightCm,
  'originalHeightUnit': profile.originalHeightUnit.name,
  'preferredUnits': {
    'weight': profile.preferredUnits.weight.name,
    'length': profile.preferredUnits.length.name,
  },
  'waistCm': profile.waistCm,
  'originalWaistUnit': profile.originalWaistUnit?.name,
  'neckCm': profile.neckCm,
  'originalNeckUnit': profile.originalNeckUnit?.name,
  'hipCm': profile.hipCm,
  'originalHipUnit': profile.originalHipUnit?.name,
  'reportedBodyFat': profile.reportedBodyFat == null
      ? null
      : {
          'percent': profile.reportedBodyFat!.percent,
          'source': profile.reportedBodyFat!.source,
        },
  'activityLevel': profile.activityLevel?.name,
  'typicalDailySteps': profile.typicalDailySteps,
  'trainingDaysPerWeek': profile.trainingDaysPerWeek,
  'trainingType': profile.trainingType,
  'restDaysPerWeek': profile.restDaysPerWeek,
  'pregnancy': profile.pregnancy.name,
  'breastfeeding': profile.breastfeeding.name,
};

Map<String, Object?> _startingWeightJson(StartingWeightObservation weight) => {
  'metadata': _metadataJson(weight.metadata),
  'weightKg': weight.weightKg,
  'originalUnit': weight.originalUnit.name,
  'observedAt': _observationTimeJson(weight.observedAt),
  'source': weight.source,
};

Map<String, Object?> _goalJson(InitialGoal goal) => {
  'metadata': _metadataJson(goal.metadata),
  'effectiveOn': goal.effectiveOn.toIsoDay(),
  'bodyFatMilestonePercent': goal.bodyFatMilestonePercent,
  'kind': goal is LossGoal ? 'loss' : 'maintenance',
  if (goal case LossGoal loss) 'targetWeightKg': loss.targetWeightKg,
  if (goal case LossGoal loss)
    'originalTargetWeightUnit': loss.originalTargetWeightUnit.name,
  if (goal case LossGoal loss) 'rate': loss.rate.name,
};

Map<String, Object?> _metadataJson(RecordMetadata metadata) => {
  'id': metadata.id,
  'createdAtUtc': metadata.createdAtUtc.toIso8601String(),
  'updatedAtUtc': metadata.updatedAtUtc.toIso8601String(),
  'origin': metadata.origin.name,
};

Map<String, Object?> _observationTimeJson(ObservationTime time) => {
  'instantUtc': time.instantUtc.toIso8601String(),
  'selectedLocalDay': time.selectedLocalDay.toIsoDay(),
  'originalUtcOffsetMinutes': time.originalUtcOffsetMinutes,
};

OnboardingDraft _readDraft(Map<String, dynamic> json) {
  _keys(json, const {
    'setupId',
    'createdAtUtc',
    'updatedAtUtc',
    'revision',
    'step',
    'units',
    'text',
    'quantities',
    'equationInput',
    'startingTime',
    'activityLevel',
    'goalIntent',
    'lossRate',
    'pregnancy',
    'breastfeeding',
    'confirmedCanonicalValues',
  });
  final unitJson = _object(json['units'], 'units');
  final textJson = _object(json['text'], 'text');
  final quantityJson = _object(json['quantities'], 'quantities');
  final confirmationsJson = _object(
    json['confirmedCanonicalValues'],
    'confirmations',
  );
  final text = <OnboardingField, String>{};
  for (final entry in textJson.entries) {
    text[_enum(OnboardingField.values, entry.key, 'text key')] = _string(
      entry.value,
      'text value',
    );
  }
  final quantities = <OnboardingField, DraftQuantity>{};
  for (final entry in quantityJson.entries) {
    final field = _enum(OnboardingField.values, entry.key, 'quantity key');
    final q = _object(entry.value, 'quantity');
    _keys(q, const {
      'rawText',
      'canonicalValue',
      'originalUnitToken',
      'displayUnitToken',
    });
    final canonical = q['canonicalValue'];
    final raw = _string(q['rawText'], 'rawText');
    final original = _string(q['originalUnitToken'], 'originalUnitToken');
    final display = _string(q['displayUnitToken'], 'displayUnitToken');
    final parsed = double.tryParse(raw);
    final canonicalValue = canonical == null
        ? null
        : _number(canonical, 'canonicalValue');
    if (canonicalValue == null &&
        parsed != null &&
        parsed.isFinite &&
        parsed > 0) {
      throw const FormatException(
        'Valid physical text must retain canonical value',
      );
    }
    if (canonicalValue != null) {
      if (!canonicalValue.isFinite ||
          canonicalValue <= 0 ||
          parsed == null ||
          !parsed.isFinite ||
          !_quantityUnitsMatch(field, original, display) ||
          (_toCanonical(parsed, display) - canonicalValue).abs() >
              1e-12 * (canonicalValue.abs() > 1 ? canonicalValue.abs() : 1)) {
        throw FormatException('Invalid canonical quantity representation');
      }
    } else if (_unitFamily(field) == null ||
        !_validUnitToken(_unitFamily(field)!, display) ||
        !_validUnitToken(_unitFamily(field)!, original)) {
      throw FormatException('Invalid quantity unit');
    }
    quantities[field] = DraftQuantity(
      rawText: raw,
      canonicalValue: canonicalValue,
      originalUnitToken: original,
      displayUnitToken: display,
    );
  }
  final confirmations = <OutlierField, double>{};
  for (final entry in confirmationsJson.entries) {
    confirmations[_enum(OutlierField.values, entry.key, 'confirmation key')] =
        _number(entry.value, 'confirmation value');
  }
  return OnboardingDraft(
    setupId: _string(json['setupId'], 'setupId'),
    createdAtUtc: _utc(json['createdAtUtc'], 'createdAtUtc'),
    updatedAtUtc: _utc(json['updatedAtUtc'], 'updatedAtUtc'),
    revision: _integer(json['revision'], 'revision'),
    step: _enum(OnboardingStep.values, json['step'], 'step'),
    units: UnitPreferences(
      weight: _enum(WeightUnit.values, unitJson['weight'], 'weight unit'),
      length: _enum(LengthUnit.values, unitJson['length'], 'length unit'),
    ),
    text: text,
    quantities: quantities,
    equationInput: _nullableEnum(
      EquationSexInput.values,
      json['equationInput'],
      'equationInput',
    ),
    startingTime: _readObservationTime(
      _object(json['startingTime'], 'startingTime'),
    ),
    activityLevel: _nullableEnum(
      ActivityLevel.values,
      json['activityLevel'],
      'activityLevel',
    ),
    goalIntent: _nullableEnum(
      GoalIntent.values,
      json['goalIntent'],
      'goalIntent',
    ),
    lossRate: _nullableEnum(LossRate.values, json['lossRate'], 'lossRate'),
    pregnancy: _enum(
      ApplicabilityAnswer.values,
      json['pregnancy'],
      'pregnancy',
    ),
    breastfeeding: _enum(
      ApplicabilityAnswer.values,
      json['breastfeeding'],
      'breastfeeding',
    ),
    confirmedCanonicalValues: confirmations,
  );
}

CompletedBaseline _readBaseline(Map<String, dynamic> json) {
  _keys(json, const {
    'setupId',
    'completedAtUtc',
    'profile',
    'startingWeight',
    'goal',
  });
  return CompletedBaseline(
    setupId: _string(json['setupId'], 'setupId'),
    completedAtUtc: _utc(json['completedAtUtc'], 'completedAtUtc'),
    profile: _readProfile(_object(json['profile'], 'profile')),
    startingWeight: _readStartingWeight(
      _object(json['startingWeight'], 'startingWeight'),
    ),
    goal: _readGoal(_object(json['goal'], 'goal')),
  );
}

BaselineProfile _readProfile(Map<String, dynamic> json) {
  _keys(json, const {
    'metadata',
    'ageYears',
    'ageRecordedOn',
    'equationInput',
    'heightCm',
    'originalHeightUnit',
    'preferredUnits',
    'waistCm',
    'originalWaistUnit',
    'neckCm',
    'originalNeckUnit',
    'hipCm',
    'originalHipUnit',
    'reportedBodyFat',
    'activityLevel',
    'typicalDailySteps',
    'trainingDaysPerWeek',
    'trainingType',
    'restDaysPerWeek',
    'pregnancy',
    'breastfeeding',
  });
  final unitJson = _object(json['preferredUnits'], 'preferredUnits');
  final bodyFat = json['reportedBodyFat'] == null
      ? null
      : _object(json['reportedBodyFat'], 'reportedBodyFat');
  return BaselineProfile(
    metadata: _readMetadata(_object(json['metadata'], 'metadata')),
    ageYears: _integer(json['ageYears'], 'ageYears'),
    ageRecordedOn: LocalDay.parse(
      _string(json['ageRecordedOn'], 'ageRecordedOn'),
    ),
    equationInput: _enum(
      EquationSexInput.values,
      json['equationInput'],
      'equationInput',
    ),
    heightCm: _number(json['heightCm'], 'heightCm'),
    originalHeightUnit: _enum(
      LengthUnit.values,
      json['originalHeightUnit'],
      'originalHeightUnit',
    ),
    preferredUnits: UnitPreferences(
      weight: _enum(WeightUnit.values, unitJson['weight'], 'preferred weight'),
      length: _enum(LengthUnit.values, unitJson['length'], 'preferred length'),
    ),
    waistCm: _nullableNumber(json['waistCm'], 'waistCm'),
    originalWaistUnit: _nullableEnum(
      LengthUnit.values,
      json['originalWaistUnit'],
      'originalWaistUnit',
    ),
    neckCm: _nullableNumber(json['neckCm'], 'neckCm'),
    originalNeckUnit: _nullableEnum(
      LengthUnit.values,
      json['originalNeckUnit'],
      'originalNeckUnit',
    ),
    hipCm: _nullableNumber(json['hipCm'], 'hipCm'),
    originalHipUnit: _nullableEnum(
      LengthUnit.values,
      json['originalHipUnit'],
      'originalHipUnit',
    ),
    reportedBodyFat: bodyFat == null
        ? null
        : ReportedBodyFat(
            percent: _number(bodyFat['percent'], 'bodyFat.percent'),
            source: _string(bodyFat['source'], 'bodyFat.source'),
          ),
    activityLevel: _nullableEnum(
      ActivityLevel.values,
      json['activityLevel'],
      'activityLevel',
    ),
    typicalDailySteps: _nullableInteger(
      json['typicalDailySteps'],
      'typicalDailySteps',
    ),
    trainingDaysPerWeek: _nullableInteger(
      json['trainingDaysPerWeek'],
      'trainingDaysPerWeek',
    ),
    trainingType: _nullableString(json['trainingType'], 'trainingType'),
    restDaysPerWeek: _nullableInteger(
      json['restDaysPerWeek'],
      'restDaysPerWeek',
    ),
    pregnancy: _enum(
      ApplicabilityAnswer.values,
      json['pregnancy'],
      'pregnancy',
    ),
    breastfeeding: _enum(
      ApplicabilityAnswer.values,
      json['breastfeeding'],
      'breastfeeding',
    ),
  );
}

StartingWeightObservation _readStartingWeight(Map<String, dynamic> json) {
  _keys(json, const {
    'metadata',
    'weightKg',
    'originalUnit',
    'observedAt',
    'source',
  });
  return StartingWeightObservation(
    metadata: _readMetadata(_object(json['metadata'], 'metadata')),
    weightKg: _number(json['weightKg'], 'weightKg'),
    originalUnit: _enum(
      WeightUnit.values,
      json['originalUnit'],
      'originalUnit',
    ),
    observedAt: _readObservationTime(_object(json['observedAt'], 'observedAt')),
    source: _string(json['source'], 'source'),
  );
}

InitialGoal _readGoal(Map<String, dynamic> json) {
  final kind = _string(json['kind'], 'goal.kind');
  final baseKeys = {
    'metadata',
    'effectiveOn',
    'bodyFatMilestonePercent',
    'kind',
  };
  final metadata = _readMetadata(_object(json['metadata'], 'goal.metadata'));
  final effectiveOn = LocalDay.parse(
    _string(json['effectiveOn'], 'goal.effectiveOn'),
  );
  final milestone = _nullableNumber(
    json['bodyFatMilestonePercent'],
    'bodyFatMilestonePercent',
  );
  if (kind == 'maintenance') {
    _keys(json, baseKeys);
    return MaintenanceGoal(
      metadata: metadata,
      effectiveOn: effectiveOn,
      bodyFatMilestonePercent: milestone,
    );
  }
  if (kind == 'loss') {
    _keys(json, {
      ...baseKeys,
      'targetWeightKg',
      'originalTargetWeightUnit',
      'rate',
    });
    return LossGoal(
      metadata: metadata,
      effectiveOn: effectiveOn,
      bodyFatMilestonePercent: milestone,
      targetWeightKg: _number(json['targetWeightKg'], 'targetWeightKg'),
      originalTargetWeightUnit: _enum(
        WeightUnit.values,
        json['originalTargetWeightUnit'],
        'originalTargetWeightUnit',
      ),
      rate: _enum(LossRate.values, json['rate'], 'rate'),
    );
  }
  throw FormatException('Invalid goal kind');
}

RecordMetadata _readMetadata(Map<String, dynamic> json) {
  _keys(json, const {'id', 'createdAtUtc', 'updatedAtUtc', 'origin'});
  return RecordMetadata(
    id: _string(json['id'], 'id'),
    createdAtUtc: _utc(json['createdAtUtc'], 'createdAtUtc'),
    updatedAtUtc: _utc(json['updatedAtUtc'], 'updatedAtUtc'),
    origin: _enum(RecordOrigin.values, json['origin'], 'origin'),
  );
}

ObservationTime _readObservationTime(Map<String, dynamic> json) {
  _keys(json, const {
    'instantUtc',
    'selectedLocalDay',
    'originalUtcOffsetMinutes',
  });
  return ObservationTime(
    instantUtc: _utc(json['instantUtc'], 'instantUtc'),
    selectedLocalDay: LocalDay.parse(
      _string(json['selectedLocalDay'], 'selectedLocalDay'),
    ),
    originalUtcOffsetMinutes: _integer(
      json['originalUtcOffsetMinutes'],
      'originalUtcOffsetMinutes',
    ),
  );
}

Map<String, dynamic> _object(Object? value, String name) {
  if (value is! Map || value.keys.any((key) => key is! String)) {
    throw FormatException('$name must be an object');
  }
  return value.cast<String, dynamic>();
}

void _keys(Map<String, dynamic> value, Set<String> expected) {
  if (value.keys.toSet().difference(expected).isNotEmpty ||
      expected.difference(value.keys.toSet()).isNotEmpty) {
    throw const FormatException('Unexpected or missing snapshot field');
  }
}

String _string(Object? value, String name) {
  if (value is! String) throw FormatException('$name must be a string');
  return value;
}

String? _nullableString(Object? value, String name) =>
    value == null ? null : _string(value, name);

int _integer(Object? value, String name) {
  if (value is! int) throw FormatException('$name must be an integer');
  return value;
}

int? _nullableInteger(Object? value, String name) =>
    value == null ? null : _integer(value, name);

double _number(Object? value, String name) {
  if (value is! num) throw FormatException('$name must be numeric');
  final number = value.toDouble();
  if (!number.isFinite) throw FormatException('$name must be finite');
  return number;
}

double? _nullableNumber(Object? value, String name) =>
    value == null ? null : _number(value, name);

DateTime _utc(Object? value, String name) {
  final String raw = _string(value, name);
  final DateTime? parsed = DateTime.tryParse(raw);
  if (parsed == null || !parsed.isUtc || parsed.toIso8601String() != raw) {
    throw FormatException('$name must be UTC');
  }
  return parsed;
}

T _enum<T extends Enum>(List<T> values, Object? value, String name) {
  final token = _string(value, name);
  return values.firstWhere(
    (candidate) => candidate.name == token,
    orElse: () => throw FormatException('Invalid $name token'),
  );
}

T? _nullableEnum<T extends Enum>(List<T> values, Object? value, String name) =>
    value == null ? null : _enum(values, value, name);

String? _unitFamily(OnboardingField field) => switch (field) {
  OnboardingField.height ||
  OnboardingField.waist ||
  OnboardingField.neck ||
  OnboardingField.hip => 'length',
  OnboardingField.startingWeight || OnboardingField.goalWeight => 'weight',
  _ => null,
};

bool _validUnitToken(String family, String value) => family == 'weight'
    ? value == 'kg' || value == 'lb'
    : value == 'cm' || value == 'inch';

bool _quantityUnitsMatch(
  OnboardingField field,
  String original,
  String display,
) {
  final family = _unitFamily(field);
  return family != null &&
      _validUnitToken(family, original) &&
      _validUnitToken(family, display);
}

double _toCanonical(double value, String unit) => switch (unit) {
  'kg' || 'cm' => value,
  'lb' => value * 0.45359237,
  'inch' => value * 2.54,
  _ => throw FormatException('Invalid unit'),
};
