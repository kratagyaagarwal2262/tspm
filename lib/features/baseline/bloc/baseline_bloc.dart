import '../../../core/router/exports.dart';

part 'baseline_event.dart';
part 'baseline_state.dart';

final class BaselineBloc extends Bloc<BaselineEvent, BaselineState> {
  BaselineBloc({
    required BaselineRepository repository,
    DateTime Function()? now,
  }) : _repository = repository,
       _now = now ?? DateTime.now,
       super(const BaselineLoading()) {
    on<BaselineLoadRequested>((event, emit) => _load(emit));
    on<BaselineDraftChanged>(_draftChanged);
    on<BaselineUnitsChanged>(_unitsChanged);
    on<BaselineNextPressed>(_nextPressed);
    on<BaselineBackPressed>(_backPressed);
    on<BaselineOutlierAnswered>(_outlierAnswered);
    on<BaselineFlushRequested>(_flushRequested);
    on<BaselineCompletePressed>(_completePressed);
    on<BaselineRetryPressed>((event, emit) => _retry(emit));
    on<BaselineWriteFinished>(_writeFinished);
  }

  final BaselineRepository _repository;
  final DateTime Function() _now;
  final Map<int, List<Completer<bool>>> _flushWaiters = {};

  Future<bool> flush() {
    final completer = Completer<bool>();
    add(BaselineFlushRequested(completer: completer));
    return completer.future;
  }

  Future<void> _load(Emitter<BaselineState> emit) async {
    final previous = state;
    if (previous is BaselineEditing || previous is BaselineCompleting) return;
    final existingCompleted = previous is BaselineCompleted ? previous : null;
    final preserveCompleted = existingCompleted != null;
    if (!preserveCompleted) emit(const BaselineLoading());
    final result = await _repository.load();
    if (isClosed) return;
    result.fold(
      (failure) {
        if (existingCompleted != null) {
          emit(
            BaselineCompleted(
              baseline: existingCompleted.baseline,
              justCompleted: false,
              refreshFailure: failure,
            ),
          );
        } else {
          emit(BaselineLoadFailed(failure: failure));
        }
      },
      (snapshot) {
        if (preserveCompleted) {
          if (snapshot is CompletedBaselineSnapshot &&
              snapshot.baseline.setupId == existingCompleted.baseline.setupId) {
            emit(
              BaselineCompleted(
                baseline: snapshot.baseline,
                justCompleted: false,
              ),
            );
          } else {
            emit(
              BaselineCompleted(
                baseline: existingCompleted.baseline,
                justCompleted: false,
                refreshFailure: _conflict(BaselineOperation.load),
              ),
            );
          }
          return;
        }
        if (snapshot is CompletedBaselineSnapshot) {
          emit(
            BaselineCompleted(
              baseline: snapshot.baseline,
              justCompleted: false,
            ),
          );
          return;
        }
        if (snapshot is DraftBaselineSnapshot) {
          emit(
            BaselineEditing(
              draft: snapshot.draft,
              validation: FormProblems(),
              persistedRevision: snapshot.draft.revision,
              saving: false,
            ),
          );
          return;
        }
        final draft = OnboardingDraft.initial(now: _now());
        final editing = BaselineEditing(
          draft: draft,
          validation: FormProblems(),
          persistedRevision: -1,
          saving: true,
        );
        emit(editing);
        _saveDraft(draft);
      },
    );
  }

  void _draftChanged(BaselineDraftChanged event, Emitter<BaselineState> emit) {
    final current = state;
    if (current is! BaselineEditing) return;
    try {
      final updated = event.update(current.draft);
      if (updated.setupId != current.draft.setupId ||
          updated.revision != current.draft.revision) {
        return;
      }
      _edit(current, updated, emit);
    } on Object {
      // A malformed UI update leaves the last valid in-memory draft intact.
    }
  }

  void _unitsChanged(BaselineUnitsChanged event, Emitter<BaselineState> emit) {
    final current = state;
    if (current is! BaselineEditing) return;
    _edit(current, current.draft.changeUnits(event.units), emit);
  }

  void _edit(
    BaselineEditing current,
    OnboardingDraft value,
    Emitter<BaselineState> emit, {
    OnboardingStep? step,
    FormProblems? validation,
    bool confirmationPending = false,
  }) {
    final draft = value.copyWith(
      revision: current.draft.revision + 1,
      updatedAtUtc: _now().toUtc(),
      step: step,
    );
    final nextValidation =
        validation ??
        (current.validation.isEmpty
            ? current.validation
            : BaselineValidation.checkStep(draft));
    emit(
      BaselineEditing(
        draft: draft,
        validation: nextValidation,
        persistedRevision: current.persistedRevision,
        saving: true,
        confirmationPending: confirmationPending,
      ),
    );
    _saveDraft(draft);
  }

  void _nextPressed(BaselineNextPressed event, Emitter<BaselineState> emit) {
    final current = state;
    if (current is! BaselineEditing ||
        current.draft.step == OnboardingStep.goalAndApplicability) {
      return;
    }
    final validation = BaselineValidation.checkStep(current.draft);
    if (!validation.isEmpty) {
      emit(
        BaselineEditing(
          draft: current.draft,
          validation: validation,
          persistedRevision: current.persistedRevision,
          saving: current.saving,
          saveFailure: current.saveFailure,
          confirmationPending:
              validation.confirmationsRequired.isNotEmpty &&
              validation.fields.isEmpty &&
              !validation.invalidStartingTime &&
              !validation.missingEquationInput &&
              !validation.missingGoalIntent &&
              !validation.missingLossRate,
        ),
      );
      return;
    }
    _edit(
      current,
      current.draft,
      emit,
      step: OnboardingStep.values[current.draft.step.index + 1],
      validation: FormProblems(),
    );
  }

  void _backPressed(BaselineBackPressed event, Emitter<BaselineState> emit) {
    final current = state;
    if (current is BaselineCompleting &&
        !current.saving &&
        current.saveFailure?.writeOutcome == WriteOutcome.notCommitted) {
      emit(
        BaselineEditing(
          draft: current.draft,
          validation: FormProblems(),
          persistedRevision: -1,
          saving: true,
        ),
      );
      unawaited(_saveDraft(current.draft));
      return;
    }
    if (current is! BaselineEditing || current.draft.step.index == 0) return;
    _edit(
      current,
      current.draft,
      emit,
      step: OnboardingStep.values[current.draft.step.index - 1],
      validation: FormProblems(),
    );
  }

  void _outlierAnswered(
    BaselineOutlierAnswered event,
    Emitter<BaselineState> emit,
  ) {
    final current = state;
    if (current is! BaselineEditing || !current.confirmationPending) return;
    final nextValidation = BaselineValidation.checkStep(current.draft);
    if (!nextValidation.confirmationsRequired.containsKey(event.field) ||
        nextValidation.confirmationsRequired[event.field] !=
            event.canonicalValue) {
      return;
    }
    if (!event.accepted) {
      emit(
        BaselineEditing(
          draft: current.draft,
          validation: current.validation,
          persistedRevision: current.persistedRevision,
          saving: current.saving,
          saveFailure: current.saveFailure,
        ),
      );
      return;
    }
    final confirmed = current.draft.confirmOutlier(
      event.field,
      event.canonicalValue,
    );
    final remaining = BaselineValidation.checkStep(confirmed);
    final advance =
        remaining.isEmpty &&
        confirmed.step != OnboardingStep.goalAndApplicability;
    final nextStep = advance
        ? OnboardingStep.values[confirmed.step.index + 1]
        : confirmed.step;
    _edit(current, confirmed, emit, step: nextStep, validation: remaining);
  }

  void _flushRequested(
    BaselineFlushRequested event,
    Emitter<BaselineState> emit,
  ) {
    final current = state;
    if (current is! BaselineEditing) {
      event.completer.complete(current is BaselineCompleted);
      return;
    }
    if (current.persistedRevision >= current.draft.revision &&
        current.saveFailure == null) {
      event.completer.complete(true);
      return;
    }
    (_flushWaiters[current.draft.revision] ??= []).add(event.completer);
    _saveDraft(current.draft);
    if (!current.saving) {
      emit(
        BaselineEditing(
          draft: current.draft,
          validation: current.validation,
          persistedRevision: current.persistedRevision,
          saving: true,
          confirmationPending: current.confirmationPending,
        ),
      );
    }
  }

  void _completePressed(
    BaselineCompletePressed event,
    Emitter<BaselineState> emit,
  ) {
    final current = state;
    if (current is! BaselineEditing ||
        current.draft.step != OnboardingStep.goalAndApplicability) {
      return;
    }
    final now = _now();
    final result = BaselineValidation.prepareCompletion(
      current.draft,
      now.toUtc(),
      LocalDay(year: now.year, month: now.month, day: now.day),
    );
    result.fold(
      (validation) => emit(
        BaselineEditing(
          draft: current.draft,
          validation: validation,
          persistedRevision: current.persistedRevision,
          saving: current.saving,
          saveFailure: current.saveFailure,
        ),
      ),
      (candidate) {
        emit(
          BaselineCompleting(
            draft: current.draft,
            candidate: candidate,
            saving: true,
          ),
        );
        _complete(candidate, current.draft.revision);
      },
    );
  }

  Future<void> _retry(Emitter<BaselineState> emit) async {
    final current = state;
    if (current is BaselineLoadFailed) {
      await _load(emit);
    } else if (current is BaselineEditing && current.saveFailure != null) {
      emit(
        BaselineEditing(
          draft: current.draft,
          validation: current.validation,
          persistedRevision: current.persistedRevision,
          saving: true,
          confirmationPending: current.confirmationPending,
        ),
      );
      await _saveDraft(current.draft);
    } else if (current is BaselineCompleting && current.saveFailure != null) {
      emit(
        BaselineCompleting(
          draft: current.draft,
          candidate: current.candidate,
          saving: true,
        ),
      );
      await _complete(current.candidate, current.draft.revision);
    } else if (current is BaselineCompleted && current.refreshFailure != null) {
      await _load(emit);
    }
  }

  Future<void> _saveDraft(OnboardingDraft draft) async {
    final result = await _repository.saveDraft(draft);
    if (isClosed) return;
    add(
      BaselineWriteFinished(
        revision: draft.revision,
        operation: BaselineOperation.saveDraft,
        result: result.fold<Either<BaselineFailure, BaselineSnapshot>>(
          (failure) => Left(failure),
          (snapshot) => Right(snapshot),
        ),
      ),
    );
  }

  Future<void> _complete(CompletedBaseline candidate, int revision) async {
    final result = await _repository.complete(candidate);
    if (isClosed) return;
    add(
      BaselineWriteFinished(
        revision: revision,
        operation: BaselineOperation.complete,
        result: result.fold<Either<BaselineFailure, BaselineSnapshot>>(
          (failure) => Left(failure),
          (snapshot) => Right(snapshot),
        ),
      ),
    );
  }

  void _writeFinished(
    BaselineWriteFinished event,
    Emitter<BaselineState> emit,
  ) {
    final current = state;
    if (event.operation == BaselineOperation.complete &&
        current is BaselineCompleting) {
      event.result.fold(
        (failure) => emit(
          BaselineCompleting(
            draft: current.draft,
            candidate: current.candidate,
            saving: false,
            saveFailure: failure,
          ),
        ),
        (snapshot) {
          if (snapshot is CompletedBaselineSnapshot &&
              snapshot.baseline.setupId == current.candidate.setupId) {
            emit(
              BaselineCompleted(
                baseline: snapshot.baseline,
                justCompleted: true,
              ),
            );
          }
        },
      );
      _finishFlushes(event);
      return;
    }
    if (event.operation != BaselineOperation.saveDraft ||
        current is! BaselineEditing) {
      _finishFlushes(event);
      return;
    }
    var persistedRevision = current.persistedRevision;
    var failure = current.saveFailure;
    event.result.fold(
      (nextFailure) {
        if (event.revision == current.draft.revision) failure = nextFailure;
      },
      (snapshot) {
        if (snapshot is DraftBaselineSnapshot &&
            snapshot.draft.setupId == current.draft.setupId &&
            snapshot.draft.revision == event.revision) {
          if (event.revision > persistedRevision) {
            persistedRevision = event.revision;
          }
          if (event.revision >= current.draft.revision) failure = null;
        }
      },
    );
    emit(
      BaselineEditing(
        draft: current.draft,
        validation: current.validation,
        persistedRevision: persistedRevision,
        saving: persistedRevision < current.draft.revision,
        saveFailure: failure,
        confirmationPending: current.confirmationPending,
      ),
    );
    _finishFlushes(event);
  }

  void _finishFlushes(BaselineWriteFinished event) {
    final revisions = _flushWaiters.keys
        .where((revision) => revision <= event.revision)
        .toList();
    for (final revision in revisions) {
      final waiters = _flushWaiters.remove(revision)!;
      final success = event.result.isRight() && event.revision >= revision;
      for (final waiter in waiters) {
        if (!waiter.isCompleted) waiter.complete(success);
      }
    }
  }

  BaselineFailure _conflict(BaselineOperation operation) => BaselineFailure(
    operation: operation,
    reason: BaselineFailureReason.conflict,
  );
}
