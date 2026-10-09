import '../../../core/router/exports.dart';

enum BaselineOperation { load, saveDraft, complete }

enum BaselineFailureReason {
  io,
  keyUnavailable,
  corrupt,
  unsupportedVersion,
  conflict,
}

enum WriteOutcome { notCommitted, unknown }

final class BaselineFailure extends Equatable {
  const BaselineFailure({
    required this.operation,
    required this.reason,
    this.unsupportedVersion,
    this.writeOutcome,
  });

  final BaselineOperation operation;
  final BaselineFailureReason reason;
  final int? unsupportedVersion;
  final WriteOutcome? writeOutcome;

  BaselineFailure forOperation(BaselineOperation operation) => BaselineFailure(
    operation: operation,
    reason: reason,
    unsupportedVersion: unsupportedVersion,
    writeOutcome: writeOutcome,
  );

  @override
  List<Object?> get props => <Object?>[
    operation,
    reason,
    unsupportedVersion,
    writeOutcome,
  ];
}

final class BaselineRepository {
  BaselineRepository({required ProtectedBaselineStore store}) : _store = store;
  final ProtectedBaselineStore _store;

  Future<void> _tail = Future<void>.value();

  Future<T> _ordered<T>(Future<T> Function() action) {
    final Future<T> next = _tail.then((_) => action());
    _tail = next.then<void>((_) {}, onError: (Object _) {});
    return next;
  }

  Future<Either<BaselineFailure, BaselineSnapshot?>> load() =>
      _ordered(() async {
        try {
          final String? raw = await _store.read();
          if (raw == null) return const Right(null);
          return BaselineCodec.decode(raw);
        } on Object catch (error) {
          return Left(_failure(error, BaselineOperation.load));
        }
      });

  Future<Either<BaselineFailure, DraftBaselineSnapshot>> saveDraft(
    OnboardingDraft draft,
  ) => _ordered(
    () => _replace(
      DraftBaselineSnapshot(draft: draft),
      BaselineOperation.saveDraft,
    ),
  );

  Future<Either<BaselineFailure, CompletedBaselineSnapshot>> complete(
    CompletedBaseline candidate,
  ) => _ordered(
    () => _replace(
      CompletedBaselineSnapshot(baseline: candidate),
      BaselineOperation.complete,
    ),
  );

  Future<Either<BaselineFailure, T>> _replace<T extends BaselineSnapshot>(
    T candidate,
    BaselineOperation operation,
  ) async {
    bool replacing = false;
    try {
      final String next = BaselineCodec.encode(candidate);
      final Either<BaselineFailure, BaselineSnapshot> checked =
          BaselineCodec.decode(next);
      if (checked.isLeft()) {
        return checked.fold(
          (failure) => Left(failure.forOperation(operation)),
          (_) => throw StateError('unreachable'),
        );
      }
      final String? raw = await _store.read();
      if (raw != null) {
        final Either<BaselineFailure, BaselineSnapshot> decoded =
            BaselineCodec.decode(raw);
        final BaselineFailure? failure = decoded.fold(
          (failure) => failure,
          (_) => null,
        );
        if (failure != null) return Left(failure.forOperation(operation));
        final BaselineSnapshot current = decoded.getOrElse(
          () => throw StateError('unreachable'),
        );
        bool conflict = current.setupId != candidate.setupId;
        if (current is CompletedBaselineSnapshot) {
          conflict =
              conflict ||
              candidate is! CompletedBaselineSnapshot ||
              BaselineCodec.encode(current) != next;
        } else if (current is DraftBaselineSnapshot &&
            candidate is DraftBaselineSnapshot) {
          conflict =
              conflict ||
              current.draft.revision > candidate.draft.revision ||
              (current.draft.revision == candidate.draft.revision &&
                  BaselineCodec.encode(current) != next);
        }
        if (conflict) {
          return Left(
            BaselineFailure(
              operation: operation,
              reason: BaselineFailureReason.conflict,
              writeOutcome: WriteOutcome.notCommitted,
            ),
          );
        }
      }
      replacing = true;
      await _store.replace(expectedJson: raw, nextJson: next);
      return Right(candidate);
    } on Object catch (error) {
      final BaselineFailure failure = _failure(error, operation);
      return Left(
        replacing
            ? failure
            : BaselineFailure(
                operation: operation,
                reason: failure.reason,
                unsupportedVersion: failure.unsupportedVersion,
                writeOutcome: WriteOutcome.notCommitted,
              ),
      );
    }
  }
}

BaselineFailure _failure(Object error, BaselineOperation operation) {
  BaselineFailureReason reason = BaselineFailureReason.io;
  WriteOutcome? outcome;
  int? version;
  if (error is PlatformException) {
    reason = switch (error.code) {
      'keyUnavailable' => BaselineFailureReason.keyUnavailable,
      'corrupt' => BaselineFailureReason.corrupt,
      'unsupportedVersion' => BaselineFailureReason.unsupportedVersion,
      'conflict' => BaselineFailureReason.conflict,
      _ => BaselineFailureReason.io,
    };
    final Object? details = error.details;
    if (details is Map) {
      outcome = details['writeOutcome'] == 'notCommitted'
          ? WriteOutcome.notCommitted
          : WriteOutcome.unknown;
      final Object? reportedVersion = details['unsupportedVersion'];
      if (reportedVersion is int) version = reportedVersion;
    }
  }
  return BaselineFailure(
    operation: operation,
    reason: reason,
    unsupportedVersion: version,
    writeOutcome: operation == BaselineOperation.load
        ? null
        : outcome ?? WriteOutcome.unknown,
  );
}
