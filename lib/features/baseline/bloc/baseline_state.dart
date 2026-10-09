part of 'baseline_bloc.dart';

sealed class BaselineState extends Equatable {
  const BaselineState();
}

final class BaselineLoading extends BaselineState {
  const BaselineLoading();
  @override
  List<Object?> get props => [];
}

final class BaselineLoadFailed extends BaselineState {
  const BaselineLoadFailed({required this.failure});
  final BaselineFailure failure;
  @override
  List<Object?> get props => [failure];
}

final class BaselineEditing extends BaselineState {
  const BaselineEditing({
    required this.draft,
    required this.validation,
    required this.persistedRevision,
    required this.saving,
    this.saveFailure,
    this.confirmationPending = false,
  });
  final OnboardingDraft draft;
  final FormProblems validation;
  final int persistedRevision;
  final bool saving;
  final BaselineFailure? saveFailure;
  final bool confirmationPending;

  @override
  List<Object?> get props => [
    draft,
    validation,
    persistedRevision,
    saving,
    saveFailure,
    confirmationPending,
  ];
}

final class BaselineCompleting extends BaselineState {
  const BaselineCompleting({
    required this.draft,
    required this.candidate,
    required this.saving,
    this.saveFailure,
  });
  final OnboardingDraft draft;
  final CompletedBaseline candidate;
  final bool saving;
  final BaselineFailure? saveFailure;

  @override
  List<Object?> get props => [draft, candidate, saving, saveFailure];
}

final class BaselineCompleted extends BaselineState {
  const BaselineCompleted({
    required this.baseline,
    required this.justCompleted,
    this.refreshFailure,
  });
  final CompletedBaseline baseline;
  final bool justCompleted;
  final BaselineFailure? refreshFailure;

  @override
  List<Object?> get props => [baseline, justCompleted, refreshFailure];
}
