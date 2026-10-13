import 'package:flutter_test/flutter_test.dart';
import 'package:tspm/core/router/exports.dart';
import 'package:tspm/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('tspm/protected_baseline');
  String? stored;
  bool failRead = false;
  int reads = 0;
  setUp(() {
    stored = null;
    failRead = false;
    reads = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'read') {
            reads++;
            if (failRead) throw PlatformException(code: 'io');
            return stored;
          }
          stored = (call.arguments as Map)['nextJson'] as String;
          return null;
        });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  Future<void> start(WidgetTester tester, {String? route}) async {
    await tester.pumpWidget(
      route == null ? const MyApp() : MyApp(initialRoute: route),
    );
    await tester.pumpAndSettle();
    expect(find.byType(BaselinePage), findsOneWidget);
    expect(find.text(AppStrings.counterPrompt), findsNothing);
  }

  testWidgets('AC 1: default startup uses verified absence for first run', (
    tester,
  ) async {
    await start(tester);
    expect(find.text(AppStrings.stepProgress(1)), findsOneWidget);
  });
  testWidgets('AC 8: default startup resumes the saved draft step', (
    tester,
  ) async {
    stored = BaselineCodec.encode(
      DraftBaselineSnapshot(
        draft: _draft().copyWith(step: OnboardingStep.activity),
      ),
    );
    await start(tester);
    expect(find.text(AppStrings.stepProgress(4)), findsOneWidget);
    expect(reads, 1);
  });
  testWidgets('AC 10: default startup opens a completed landing', (
    tester,
  ) async {
    final completed = BaselineValidation.prepareCompletion(
      _draft(),
      DateTime.utc(2026, 10, 9),
      LocalDay.parse('2026-10-09'),
    ).getOrElse(() => throw StateError('invalid fixture'));
    stored = BaselineCodec.encode(
      CompletedBaselineSnapshot(baseline: completed),
    );
    await start(tester);
    expect(find.text(AppStrings.landingTitle), findsOneWidget);
    expect(find.text(AppStrings.setupSaved), findsNothing);
    expect(reads, 1);
  });
  testWidgets(
    'AC 12: default startup read failure has no writable replacement',
    (tester) async {
      failRead = true;
      await start(tester);
      expect(find.text(AppStrings.loadFailed), findsOneWidget);
      expect(find.byType(TextFormField), findsNothing);
      expect(find.text(AppStrings.retry), findsOneWidget);
      expect(reads, 1);
    },
  );
  testWidgets('AC 1, 8: explicit product startup creates one storage gate', (
    tester,
  ) async {
    stored = BaselineCodec.encode(DraftBaselineSnapshot(draft: _draft()));
    await start(tester, route: AppRoutes.product);
    expect(reads, 1);
  });
}

OnboardingDraft _draft() {
  var draft =
      OnboardingDraft.initial(
            now: DateTime.utc(2026, 10, 9),
            setupId: 'startup-test',
          )
          .withText(OnboardingField.age, '30')
          .copyWith(
            equationInput: EquationSexInput.male,
            goalIntent: GoalIntent.maintenance,
          );
  for (final (field, value, unit) in [
    (OnboardingField.height, 175.0, 'cm'),
    (OnboardingField.startingWeight, 80.0, 'kg'),
  ]) {
    draft = draft.withQuantity(
      field,
      DraftQuantity(
        rawText: value.toString(),
        canonicalValue: value,
        originalUnitToken: unit,
        displayUnitToken: unit,
      ),
    );
  }
  return draft;
}
