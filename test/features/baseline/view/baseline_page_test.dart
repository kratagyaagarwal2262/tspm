import 'package:flutter_test/flutter_test.dart';
import 'package:tspm/core/router/exports.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('tspm/protected_baseline');
  String? stored;
  bool failRead = false;
  bool failWrite = false;
  setUp(() {
    stored = null;
    failRead = false;
    failWrite = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (failRead) throw PlatformException(code: 'io');
          if (call.method == 'read') return stored;
          if (failWrite) {
            throw PlatformException(
              code: 'io',
              details: {'writeOutcome': 'notCommitted'},
            );
          }
          final args = call.arguments as Map;
          stored = args['nextJson'] as String;
          return null;
        });
  });
  Future<void> pump(WidgetTester tester, {double scale = 1}) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: const BaselinePage(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'first run explains local storage and advances to required baseline',
    (tester) async {
      await pump(tester);
      expect(find.text('Your baseline'), findsOneWidget);
      expect(find.textContaining('on this device'), findsWidgets);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextFormField, 'Age (years)'), findsOneWidget);
      expect(find.text('Draft saved on this device'), findsOneWidget);
    },
  );
  testWidgets('failed read offers retry without a writable form', (
    tester,
  ) async {
    failRead = true;
    await pump(tester);
    expect(find.text('Could not load your baseline'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    failRead = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Your baseline'), findsOneWidget);
  });
  testWidgets('200 percent text keeps next action reachable', (tester) async {
    await pump(tester, scale: 2);
    await tester.ensureVisible(find.text('Continue'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.widgetWithText(TextFormField, 'Age (years)'), findsOneWidget);
  });

  OnboardingDraft completeDraft() =>
      OnboardingDraft.initial(now: DateTime.now(), setupId: 'widget-flow')
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
            equationInput: EquationSexInput.female,
            goalIntent: GoalIntent.maintenance,
            step: OnboardingStep.goalAndApplicability,
          );

  testWidgets('optional skipped maintenance completes with honest landing', (
    tester,
  ) async {
    stored = BaselineCodec.encode(
      DraftBaselineSnapshot(draft: completeDraft()),
    );
    await pump(tester);
    await tester.ensureVisible(find.text(AppStrings.finishSetup));
    await tester.tap(find.text(AppStrings.finishSetup));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.setupSaved), findsOneWidget);
    expect(find.text('80 kg'), findsOneWidget);
    expect(find.text(AppStrings.reviewProfile), findsOneWidget);
    final decoded = BaselineCodec.decode(stored!);
    final saved =
        decoded.getOrElse(() => throw StateError('not completed'))
            as CompletedBaselineSnapshot;
    expect(saved.baseline.profile.waistCm, isNull);
    expect(saved.baseline.profile.activityLevel, isNull);
    expect(saved.baseline.goal, isA<MaintenanceGoal>());
  });
  testWidgets(
    'outlier decline keeps value editable and does not reopen dialog',
    (tester) async {
      final draft = completeDraft()
          .withQuantity(
            OnboardingField.height,
            DraftQuantity(
              rawText: '260',
              canonicalValue: 260,
              originalUnitToken: 'cm',
              displayUnitToken: 'cm',
            ),
          )
          .copyWith(step: OnboardingStep.requiredBaseline);
      stored = BaselineCodec.encode(DraftBaselineSnapshot(draft: draft));
      await pump(tester);
      await tester.ensureVisible(find.text(AppStrings.continueLabel));
      await tester.tap(find.text(AppStrings.continueLabel));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.outlierTitle), findsOneWidget);
      await tester.tap(find.text(AppStrings.changeEntry));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(
                const ValueKey<OnboardingField>(OnboardingField.height),
              ),
            )
            .controller!
            .text,
        '260',
      );
    },
  );
  testWidgets(
    'profile retains original clock and unknown inputs at large text',
    (tester) async {
      final baseline = BaselineValidation.prepareCompletion(
        completeDraft(),
        DateTime.now().toUtc(),
        LocalDay.parse('2026-10-09'),
      ).getOrElse(() => throw StateError('invalid'));
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: BaselineProfilePage(baseline: baseline),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find
                .text(AppStrings.applicabilityClear)
                .hitTestable()
                .evaluate()
                .isEmpty
            ? find.text(AppStrings.applicabilityLimited)
            : find.text(AppStrings.applicabilityClear),
      );
      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.unknown), findsWidgets);
    },
  );
  testWidgets('first-run semantic controls meet accessibility guidelines', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pump(tester);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });

  testWidgets(
    'loss intention with long rate label remains reachable at 200 percent',
    (tester) async {
      final draft = completeDraft()
          .copyWith(
            goalIntent: GoalIntent.loss,
            lossRate: LossRate.threeQuarterPercent,
          )
          .withQuantity(
            OnboardingField.goalWeight,
            DraftQuantity(
              rawText: '75',
              canonicalValue: 75,
              originalUnitToken: 'kg',
              displayUnitToken: 'kg',
            ),
          );
      stored = BaselineCodec.encode(DraftBaselineSnapshot(draft: draft));
      await pump(tester, scale: 2);
      await tester.ensureVisible(find.text(AppStrings.finishSetup));
      expect(tester.takeException(), isNull);
      await tester.tap(find.text(AppStrings.finishSetup));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.setupSaved), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'write failure retains entered text and offers retry without saved claim',
    (tester) async {
      stored = BaselineCodec.encode(
        DraftBaselineSnapshot(
          draft: completeDraft().copyWith(
            step: OnboardingStep.requiredBaseline,
          ),
        ),
      );
      await pump(tester);
      failWrite = true;
      await tester.enterText(
        find.byKey(const ValueKey<OnboardingField>(OnboardingField.age)),
        '31',
      );
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.unsavedDraft), findsOneWidget);
      expect(find.text(AppStrings.savedDraft), findsNothing);
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const ValueKey<OnboardingField>(OnboardingField.age)),
            )
            .controller!
            .text,
        '31',
      );
      failWrite = false;
      await tester.ensureVisible(find.text(AppStrings.retry));
      await tester.tap(find.text(AppStrings.retry));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.savedDraft), findsOneWidget);
    },
  );
}
