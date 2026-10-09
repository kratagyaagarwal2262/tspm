import 'package:flutter_test/flutter_test.dart';
import 'package:tspm/core/router/exports.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const MethodChannel channel = MethodChannel('baseline-repository-test');
  late BaselineRepository repository;
  String? stored;
  PlatformException? readFailure;
  PlatformException? writeFailure;
  int writes = 0;

  setUp(() {
    stored = null;
    readFailure = null;
    writeFailure = null;
    writes = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
          if (call.method == 'read') {
            if (readFailure != null) throw readFailure!;
            return stored;
          }
          final Map<Object?, Object?> arguments =
              call.arguments as Map<Object?, Object?>;
          if (writeFailure != null) throw writeFailure!;
          if (arguments['expectedJson'] != stored) {
            throw PlatformException(
              code: 'conflict',
              details: <String, String>{'writeOutcome': 'notCommitted'},
            );
          }
          stored = arguments['nextJson'] as String;
          writes++;
          return null;
        });
    repository = BaselineRepository(
      store: ProtectedBaselineStore(channel: channel),
    );
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('AC 12: explicit read outcomes preserve storage', () {
    test('verified absence alone returns Right(null)', () async {
      final Either<BaselineFailure, BaselineSnapshot?> result = await repository
          .load();
      expect(result.isRight(), isTrue);
      expect(result.getOrElse(() => throw StateError('failed')), isNull);
    });
    test('corrupt JSON is a failure, not first run', () async {
      stored = '{broken';
      final Either<BaselineFailure, BaselineSnapshot?> result = await repository
          .load();
      expect(result.isLeft(), isTrue);
      expect(stored, '{broken');
      expect(writes, 0);
    });
    test('read I/O failure names load and leaves content intact', () async {
      readFailure = PlatformException(code: 'io');
      final Either<BaselineFailure, BaselineSnapshot?> result = await repository
          .load();
      expect(
        result.fold((failure) => failure.operation, (_) => null),
        BaselineOperation.load,
      );
    });
  });
  group('AC 8–9, 12: durable draft and completion writes', () {
    OnboardingDraft draft() => OnboardingDraft.initial(
      now: DateTime.utc(2026, 10, 9),
      setupId: 'test-setup',
    );
    test(
      'draft save persists its raw answers and reads them on restart',
      () async {
        final OnboardingDraft input = draft().withText(
          OnboardingField.age,
          'unfinished',
        );
        expect((await repository.saveDraft(input)).isRight(), isTrue);
        expect(writes, 1);
        final BaselineRepository reopened = BaselineRepository(
          store: ProtectedBaselineStore(channel: channel),
        );
        final BaselineSnapshot? loaded = (await reopened.load()).getOrElse(
          () => throw StateError('load failed'),
        );
        expect(
          (loaded as DraftBaselineSnapshot).draft.text[OnboardingField.age],
          'unfinished',
        );
      },
    );
    test('unsupported data blocks writes without overwriting it', () async {
      stored = '{"schemaVersion":99}';
      final Either<BaselineFailure, DraftBaselineSnapshot> result =
          await repository.saveDraft(draft());
      expect(result.isLeft(), isTrue);
      expect(stored, '{"schemaVersion":99}');
      expect(writes, 0);
    });
    test(
      'save failure retains draft and reports the operation and uncertainty',
      () async {
        writeFailure = PlatformException(
          code: 'io',
          details: <String, String>{'writeOutcome': 'unknown'},
        );
        final Either<BaselineFailure, DraftBaselineSnapshot> result =
            await repository.saveDraft(draft());
        expect(result.isLeft(), isTrue);
        expect(
          result.fold((failure) => failure.operation, (_) => null),
          BaselineOperation.saveDraft,
        );
        expect(
          result.fold((failure) => failure.writeOutcome, (_) => null),
          WriteOutcome.unknown,
        );
        expect(stored, isNull);
      },
    );
    test('stale revisions cannot replace a newer draft', () async {
      final OnboardingDraft input = draft();
      await repository.saveDraft(input.copyWith(revision: 2));
      final String? latest = stored;
      expect((await repository.saveDraft(input)).isLeft(), isTrue);
      expect(stored, latest);
    });
    test(
      'completion is one snapshot; duplicate retry rewrites same records; late draft is blocked',
      () async {
        final OnboardingDraft input = draft()
            .withText(OnboardingField.age, '30')
            .withQuantity(
              OnboardingField.height,
              DraftQuantity(
                rawText: '175',
                canonicalValue: 175,
                originalUnitToken: 'cm',
                displayUnitToken: 'cm',
              ),
            )
            .withQuantity(
              OnboardingField.startingWeight,
              DraftQuantity(
                rawText: '80',
                canonicalValue: 80,
                originalUnitToken: 'kg',
                displayUnitToken: 'kg',
              ),
            )
            .copyWith(
              equationInput: EquationSexInput.male,
              goalIntent: GoalIntent.maintenance,
            );
        final CompletedBaseline candidate =
            BaselineValidation.prepareCompletion(
              input,
              DateTime.utc(2026, 10, 9),
              LocalDay(year: 2026, month: 10, day: 9),
            ).getOrElse(() => throw StateError('invalid fixture'));
        await repository.saveDraft(input);
        expect((await repository.complete(candidate)).isRight(), isTrue);
        final String? completed = stored;
        expect((await repository.complete(candidate)).isRight(), isTrue);
        expect(stored, completed);
        expect(
          (await repository.saveDraft(input.copyWith(revision: 5))).isLeft(),
          isTrue,
        );
        expect(stored, completed);
        final BaselineSnapshot? loaded = (await repository.load()).getOrElse(
          () => throw StateError('load failed'),
        );
        expect(loaded, isA<CompletedBaselineSnapshot>());
      },
    );
  });
}
