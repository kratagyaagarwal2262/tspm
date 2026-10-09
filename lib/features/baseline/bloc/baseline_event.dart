part of 'baseline_bloc.dart';

sealed class BaselineEvent extends Equatable {
  const BaselineEvent();
}

final class BaselineLoadRequested extends BaselineEvent {
  const BaselineLoadRequested();
  @override
  List<Object?> get props => [];
}

final class BaselineDraftChanged extends BaselineEvent {
  const BaselineDraftChanged({required this.update});
  final OnboardingDraft Function(OnboardingDraft) update;
  @override
  List<Object?> get props => [update];
}

final class BaselineUnitsChanged extends BaselineEvent {
  const BaselineUnitsChanged({required this.units});
  final UnitPreferences units;
  @override
  List<Object?> get props => [units];
}

final class BaselineNextPressed extends BaselineEvent {
  const BaselineNextPressed();
  @override
  List<Object?> get props => [];
}

final class BaselineBackPressed extends BaselineEvent {
  const BaselineBackPressed();
  @override
  List<Object?> get props => [];
}

final class BaselineOutlierAnswered extends BaselineEvent {
  const BaselineOutlierAnswered({
    required this.field,
    required this.canonicalValue,
    required this.accepted,
  });
  final OutlierField field;
  final double canonicalValue;
  final bool accepted;
  @override
  List<Object?> get props => [field, canonicalValue, accepted];
}

final class BaselineFlushRequested extends BaselineEvent {
  const BaselineFlushRequested({required this.completer});
  final Completer<bool> completer;
  @override
  List<Object?> get props => [];
}

final class BaselineCompletePressed extends BaselineEvent {
  const BaselineCompletePressed();
  @override
  List<Object?> get props => [];
}

final class BaselineRetryPressed extends BaselineEvent {
  const BaselineRetryPressed();
  @override
  List<Object?> get props => [];
}

final class BaselineWriteFinished extends BaselineEvent {
  const BaselineWriteFinished({
    required this.revision,
    required this.operation,
    required this.result,
  });
  final int revision;
  final BaselineOperation operation;
  final Either<BaselineFailure, BaselineSnapshot> result;
  @override
  List<Object?> get props => [revision, operation, result];
}
