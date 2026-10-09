import 'package:flutter_test/flutter_test.dart';
import 'package:tspm/core/router/exports.dart';

const _channel = MethodChannel('baseline-bloc-test');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late String? persistedJson;
  late List<String> writes;
  late List<Completer<void>> writeGates;
  late Completer<void>? firstWriteEntered;
  late Completer<void>? secondWriteEntered;
  late bool failNextWrite;

  setUp(() {
    persistedJson = null;
    writes = [];
    writeGates = [];
    firstWriteEntered = null;
    secondWriteEntered = null;
    failNextWrite = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
          if (call.method == 'read') return persistedJson;
          if (call.method == 'replace') {
            final nextJson = (call.arguments as Map)['nextJson'] as String;
            writes.add(nextJson);
            if (writes.length == 1) firstWriteEntered?.complete();
            if (writes.length == 2) secondWriteEntered?.complete();
            if (writeGates.isNotEmpty) await writeGates.removeAt(0).future;
            if (failNextWrite) {
              failNextWrite = false;
              throw PlatformException(
                code: 'io',
                details: {'writeOutcome': 'unknown'},
              );
            }
            persistedJson = nextJson;
            return null;
          }
          throw MissingPluginException(call.method);
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  test(
    'loads saved draft as editing and reports its acknowledged revision',
    () async {
      final draft = OnboardingDraft.initial(
        now: DateTime.utc(2026, 10, 9),
        setupId: 'resume-me',
      ).copyWith(revision: 4, step: OnboardingStep.activity);
      persistedJson = BaselineCodec.encode(DraftBaselineSnapshot(draft: draft));
      final bloc = _bloc();
      final state = bloc.stream.firstWhere((value) => value is BaselineEditing);

      bloc.add(const BaselineLoadRequested());

      final editing =
          await state.timeout(const Duration(seconds: 1)) as BaselineEditing;
      expect(editing.draft.setupId, 'resume-me');
      expect(editing.draft.revision, 4);
      expect(editing.draft.step, OnboardingStep.activity);
      expect(editing.persistedRevision, 4);
      expect(editing.saving, isFalse);
      await bloc.close();
    },
  );

  test('applies rapid field edits to the latest draft', () async {
    final draft = OnboardingDraft.initial(
      now: DateTime.utc(2026, 10, 9),
      setupId: 'rapid-edits',
    );
    persistedJson = BaselineCodec.encode(DraftBaselineSnapshot(draft: draft));
    final bloc = _bloc();
    final editing = bloc.stream.firstWhere(
      (value) =>
          value is BaselineEditing &&
          value.draft.text.containsKey(OnboardingField.age) &&
          value.draft.text.containsKey(OnboardingField.trainingType),
    );
    bloc.add(const BaselineLoadRequested());
    await bloc.stream.firstWhere((value) => value is BaselineEditing);
    bloc.add(
      BaselineDraftChanged(
        update: (latest) => latest.withText(OnboardingField.age, '31'),
      ),
    );
    bloc.add(
      BaselineDraftChanged(
        update: (latest) =>
            latest.withText(OnboardingField.trainingType, 'walk'),
      ),
    );

    final updated =
        await editing.timeout(const Duration(seconds: 1)) as BaselineEditing;
    expect(updated.draft.text[OnboardingField.age], '31');
    expect(updated.draft.text[OnboardingField.trainingType], 'walk');
    expect(updated.draft.revision, 2);
    await bloc.close();
  });

  test(
    'next keeps an underage answer on the required step with an explanation issue',
    () async {
      var draft = OnboardingDraft.initial(
        now: DateTime.utc(2026, 10, 9),
        setupId: 'adult-scope',
      ).copyWith(step: OnboardingStep.requiredBaseline);
      draft = draft.withText(OnboardingField.age, '17');
      persistedJson = BaselineCodec.encode(DraftBaselineSnapshot(draft: draft));
      final bloc = _bloc();
      bloc.add(const BaselineLoadRequested());
      await bloc.stream.firstWhere((value) => value is BaselineEditing);
      final nextState = bloc.stream.firstWhere(
        (value) =>
            value is BaselineEditing &&
            value.validation.fields[OnboardingField.age] ==
                InputIssue.adultOnly,
      );

      bloc.add(const BaselineNextPressed());

      final editing =
          await nextState.timeout(const Duration(seconds: 1))
              as BaselineEditing;
      expect(editing.draft.step, OnboardingStep.requiredBaseline);
      expect(editing.draft.text[OnboardingField.age], '17');
      await bloc.close();
    },
  );

  test(
    'stale write acknowledgment leaves the latest revision unsaved',
    () async {
      final draft = OnboardingDraft.initial(
        now: DateTime.utc(2026, 10, 9),
        setupId: 'stale-ack',
      );
      persistedJson = BaselineCodec.encode(DraftBaselineSnapshot(draft: draft));
      final firstGate = Completer<void>();
      final secondGate = Completer<void>();
      writeGates.addAll([firstGate, secondGate]);
      firstWriteEntered = Completer<void>();
      secondWriteEntered = Completer<void>();
      final bloc = _bloc();
      bloc.add(const BaselineLoadRequested());
      await bloc.stream.firstWhere((value) => value is BaselineEditing);
      bloc.add(
        BaselineDraftChanged(
          update: (latest) => latest.withText(OnboardingField.age, '30'),
        ),
      );
      bloc.add(
        BaselineDraftChanged(
          update: (latest) =>
              latest.withText(OnboardingField.trainingType, 'run'),
        ),
      );
      await firstWriteEntered!.future.timeout(const Duration(seconds: 1));
      final staleAckFuture = bloc.stream.firstWhere(
        (value) =>
            value is BaselineEditing &&
            value.persistedRevision == 1 &&
            value.draft.revision == 2,
      );
      firstGate.complete();
      await secondWriteEntered!.future.timeout(const Duration(seconds: 1));
      final staleAck =
          await staleAckFuture.timeout(const Duration(seconds: 1))
              as BaselineEditing;
      expect(staleAck.saving, isTrue);
      final savedFuture = bloc.stream.firstWhere(
        (value) =>
            value is BaselineEditing &&
            value.persistedRevision == 2 &&
            !value.saving,
      );
      secondGate.complete();
      final saved =
          await savedFuture.timeout(const Duration(seconds: 1))
              as BaselineEditing;
      expect(saved.draft.text[OnboardingField.trainingType], 'run');
      await bloc.close();
    },
  );

  test(
    'failed draft save retains input and retry saves the same revision',
    () async {
      final draft = OnboardingDraft.initial(
        now: DateTime.utc(2026, 10, 9),
        setupId: 'save-retry',
      );
      persistedJson = BaselineCodec.encode(DraftBaselineSnapshot(draft: draft));
      final bloc = _bloc();
      bloc.add(const BaselineLoadRequested());
      await bloc.stream.firstWhere((value) => value is BaselineEditing);
      failNextWrite = true;
      bloc.add(
        BaselineDraftChanged(
          update: (latest) => latest.withText(OnboardingField.age, '28'),
        ),
      );
      final failed =
          await bloc.stream
                  .firstWhere(
                    (value) =>
                        value is BaselineEditing && value.saveFailure != null,
                  )
                  .timeout(const Duration(seconds: 1))
              as BaselineEditing;
      expect(failed.draft.text[OnboardingField.age], '28');
      expect(failed.persistedRevision, 0);
      final firstCandidate = writes.single;
      bloc.add(const BaselineRetryPressed());
      final saved =
          await bloc.stream
                  .firstWhere(
                    (value) =>
                        value is BaselineEditing &&
                        value.persistedRevision == 1 &&
                        !value.saving,
                  )
                  .timeout(const Duration(seconds: 1))
              as BaselineEditing;
      expect(saved.draft.text[OnboardingField.age], '28');
      expect(writes[1], firstCandidate);
      await bloc.close();
    },
  );

  test(
    'flush resolves true only after the current revision is acknowledged',
    () async {
      final draft = OnboardingDraft.initial(
        now: DateTime.utc(2026, 10, 9),
        setupId: 'flush-current',
      );
      persistedJson = BaselineCodec.encode(DraftBaselineSnapshot(draft: draft));
      final gate = Completer<void>();
      writeGates.add(gate);
      firstWriteEntered = Completer<void>();
      final bloc = _bloc();
      bloc.add(const BaselineLoadRequested());
      await bloc.stream.firstWhere((value) => value is BaselineEditing);
      bloc.add(
        BaselineDraftChanged(
          update: (latest) => latest.withText(OnboardingField.age, '33'),
        ),
      );
      await firstWriteEntered!.future.timeout(const Duration(seconds: 1));
      final flushed = bloc.flush();
      var resolved = false;
      flushed.then((_) => resolved = true);
      await Future<void>.delayed(Duration.zero);
      expect(resolved, isFalse);
      gate.complete();
      expect(await flushed.timeout(const Duration(seconds: 1)), isTrue);
      await bloc.close();
    },
  );

  test('outlier decline preserves the value and acceptance advances', () async {
    final draft = _validDraft(step: OnboardingStep.requiredBaseline)
        .withQuantity(
          OnboardingField.height,
          DraftQuantity(
            rawText: '270',
            canonicalValue: 270,
            originalUnitToken: 'cm',
            displayUnitToken: 'cm',
          ),
        );
    persistedJson = BaselineCodec.encode(DraftBaselineSnapshot(draft: draft));
    final bloc = _bloc();
    bloc.add(const BaselineLoadRequested());
    await bloc.stream.firstWhere((value) => value is BaselineEditing);
    final prompt = bloc.stream.firstWhere(
      (value) => value is BaselineEditing && value.confirmationPending,
    );
    bloc.add(const BaselineNextPressed());
    await prompt.timeout(const Duration(seconds: 1));
    bloc.add(
      const BaselineOutlierAnswered(
        field: OutlierField.height,
        canonicalValue: 270,
        accepted: false,
      ),
    );
    final declined =
        await bloc.stream
                .firstWhere(
                  (value) =>
                      value is BaselineEditing && !value.confirmationPending,
                )
                .timeout(const Duration(seconds: 1))
            as BaselineEditing;
    expect(
      declined.draft.quantities[OnboardingField.height]!.canonicalValue,
      270,
    );
    expect(declined.draft.isOutlierConfirmed(OutlierField.height), isFalse);
    final advanced = bloc.stream.firstWhere(
      (value) =>
          value is BaselineEditing &&
          value.draft.step == OnboardingStep.measurements,
    );
    bloc.add(const BaselineNextPressed());
    await bloc.stream
        .firstWhere(
          (value) => value is BaselineEditing && value.confirmationPending,
        )
        .timeout(const Duration(seconds: 1));
    bloc.add(
      const BaselineOutlierAnswered(
        field: OutlierField.height,
        canonicalValue: 270,
        accepted: true,
      ),
    );
    final accepted =
        await advanced.timeout(const Duration(seconds: 1)) as BaselineEditing;
    expect(accepted.draft.isOutlierConfirmed(OutlierField.height), isTrue);
    await bloc.close();
  });

  test(
    'completion retry reuses candidate and duplicate taps make one write',
    () async {
      persistedJson = BaselineCodec.encode(
        DraftBaselineSnapshot(draft: _validDraft()),
      );
      final bloc = _bloc();
      bloc.add(const BaselineLoadRequested());
      await bloc.stream.firstWhere((value) => value is BaselineEditing);
      failNextWrite = true;
      bloc.add(const BaselineCompletePressed());
      bloc.add(const BaselineCompletePressed());
      final failed =
          await bloc.stream
                  .firstWhere(
                    (value) =>
                        value is BaselineCompleting &&
                        value.saveFailure != null,
                  )
                  .timeout(const Duration(seconds: 1))
              as BaselineCompleting;
      expect(writes, hasLength(1));
      final candidate = failed.candidate;
      final bytes = writes.single;
      bloc.add(
        BaselineDraftChanged(
          update: (latest) => latest.withText(OnboardingField.age, '99'),
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state, failed);
      bloc.add(const BaselineRetryPressed());
      final completed =
          await bloc.stream
                  .firstWhere(
                    (value) =>
                        value is BaselineCompleted && value.justCompleted,
                  )
                  .timeout(const Duration(seconds: 1))
              as BaselineCompleted;
      expect(completed.baseline, candidate);
      expect(writes, [bytes, bytes]);
      await bloc.close();
    },
  );

  test(
    'refresh failure retains completion; unsupported schema blocks first load',
    () async {
      final candidate = _completedBaseline();
      persistedJson = BaselineCodec.encode(
        CompletedBaselineSnapshot(baseline: candidate),
      );
      final bloc = _bloc();
      bloc.add(const BaselineLoadRequested());
      await bloc.stream.firstWhere((value) => value is BaselineCompleted);
      persistedJson =
          '{"schemaVersion":99,"kind":"draft","setupId":"x","payload":{}}';
      bloc.add(const BaselineLoadRequested());
      final retained =
          await bloc.stream
                  .firstWhere(
                    (value) =>
                        value is BaselineCompleted &&
                        value.refreshFailure != null,
                  )
                  .timeout(const Duration(seconds: 1))
              as BaselineCompleted;
      expect(retained.baseline, candidate);
      await bloc.close();

      final blocked = _bloc();
      final failed = blocked.stream.firstWhere(
        (value) => value is BaselineLoadFailed,
      );
      blocked.add(const BaselineLoadRequested());
      expect(
        await failed.timeout(const Duration(seconds: 1)),
        isA<BaselineLoadFailed>(),
      );
      await blocked.close();
    },
  );

  test(
    'known not-committed completion failure allows editing retained answers',
    () async {
      final draft = _validDraft();
      persistedJson = BaselineCodec.encode(DraftBaselineSnapshot(draft: draft));
      final bloc = _bloc();
      bloc.add(const BaselineLoadRequested());
      await bloc.stream.firstWhere((value) => value is BaselineEditing);
      persistedJson = BaselineCodec.encode(
        DraftBaselineSnapshot(
          draft: OnboardingDraft.initial(
            now: DateTime.utc(2026, 10, 9),
            setupId: 'another-setup',
          ),
        ),
      );
      bloc.add(const BaselineCompletePressed());
      final blocked =
          await bloc.stream
                  .firstWhere(
                    (value) =>
                        value is BaselineCompleting &&
                        value.saveFailure != null,
                  )
                  .timeout(const Duration(seconds: 1))
              as BaselineCompleting;
      expect(blocked.saveFailure!.writeOutcome, WriteOutcome.notCommitted);
      bloc.add(const BaselineBackPressed());
      final editable =
          await bloc.stream
                  .firstWhere((value) => value is BaselineEditing)
                  .timeout(const Duration(seconds: 1))
              as BaselineEditing;
      expect(editable.draft.setupId, draft.setupId);
      expect(editable.draft.text[OnboardingField.age], '30');
      await bloc.close();
    },
  );

  test(
    'Back after noncommitted completion does not claim a failed draft was saved',
    () async {
      final draft = _validDraft();
      persistedJson = BaselineCodec.encode(DraftBaselineSnapshot(draft: draft));
      final bloc = _bloc();
      bloc.add(const BaselineLoadRequested());
      await bloc.stream.firstWhere((value) => value is BaselineEditing);
      failNextWrite = true;
      bloc.add(
        BaselineDraftChanged(
          update: (latest) => latest.withText(OnboardingField.age, '31'),
        ),
      );
      final failedDraft =
          await bloc.stream
                  .firstWhere(
                    (value) =>
                        value is BaselineEditing && value.saveFailure != null,
                  )
                  .timeout(const Duration(seconds: 1))
              as BaselineEditing;
      expect(failedDraft.persistedRevision, draft.revision);

      persistedJson = BaselineCodec.encode(
        DraftBaselineSnapshot(
          draft: OnboardingDraft.initial(
            now: DateTime.utc(2026, 10, 9),
            setupId: 'foreign-draft',
          ),
        ),
      );
      bloc.add(const BaselineCompletePressed());
      final completionFailure =
          await bloc.stream
                  .firstWhere(
                    (value) =>
                        value is BaselineCompleting &&
                        value.saveFailure != null,
                  )
                  .timeout(const Duration(seconds: 1))
              as BaselineCompleting;
      expect(
        completionFailure.saveFailure!.writeOutcome,
        WriteOutcome.notCommitted,
      );

      persistedJson = BaselineCodec.encode(DraftBaselineSnapshot(draft: draft));
      final returnedToEdit = bloc.stream.firstWhere(
        (value) =>
            value is BaselineEditing &&
            value.draft.text[OnboardingField.age] == '31',
      );
      bloc.add(const BaselineBackPressed());
      final editing =
          await returnedToEdit.timeout(const Duration(seconds: 1))
              as BaselineEditing;
      expect(editing.persistedRevision, lessThan(editing.draft.revision));
      expect(editing.saving, isTrue);

      final saved =
          await bloc.stream
                  .firstWhere(
                    (value) =>
                        value is BaselineEditing &&
                        value.persistedRevision == value.draft.revision &&
                        !value.saving,
                  )
                  .timeout(const Duration(seconds: 1))
              as BaselineEditing;
      expect(saved.draft.text[OnboardingField.age], '31');
      await bloc.close();
    },
  );
}

BaselineBloc _bloc() => BaselineBloc(
  repository: BaselineRepository(
    store: ProtectedBaselineStore(channel: _channel),
  ),
  now: () => DateTime.utc(2026, 10, 9, 12),
);

OnboardingDraft _validDraft({
  OnboardingStep step = OnboardingStep.goalAndApplicability,
}) =>
    OnboardingDraft.initial(
          now: DateTime.utc(2026, 10, 9),
          setupId: 'valid-setup',
        )
        .copyWith(
          step: step,
          equationInput: EquationSexInput.female,
          goalIntent: GoalIntent.maintenance,
        )
        .withText(OnboardingField.age, '30')
        .withQuantity(
          OnboardingField.height,
          DraftQuantity(
            rawText: '170',
            canonicalValue: 170,
            originalUnitToken: 'cm',
            displayUnitToken: 'cm',
          ),
        )
        .withQuantity(
          OnboardingField.startingWeight,
          DraftQuantity(
            rawText: '70',
            canonicalValue: 70,
            originalUnitToken: 'kg',
            displayUnitToken: 'kg',
          ),
        );

CompletedBaseline _completedBaseline() => BaselineValidation.prepareCompletion(
  _validDraft(),
  DateTime.utc(2026, 10, 9, 12),
  LocalDay.parse('2026-10-09'),
).toOption().toNullable()!;
