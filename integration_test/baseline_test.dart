import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tspm/core/router/exports.dart';
import 'package:tspm/main.dart';

// Run only on a disposable Android emulator. Phases intentionally retain real
// storage across host force-stop/time-zone changes; there is no reset operation.
void main() {
  final IntegrationTestWidgetsFlutterBinding binding =
      IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const String phase = String.fromEnvironment(
    'BASELINE_PHASE',
    defaultValue: 'draft',
  );

  testWidgets('AC 1–14: real protected baseline ($phase)', (
    WidgetTester tester,
  ) async {
    final BaselineRepository repository = BaselineRepository(
      store: ProtectedBaselineStore(),
    );
    final Either<BaselineFailure, BaselineSnapshot?> before = await repository
        .load();
    expect(before.isRight(), isTrue);
    if (phase == 'draft') expect(_snapshotOrNull(before), isNull);
    await tester.pumpWidget(const MyApp(initialRoute: AppRoutes.product));
    await _waitFor(
      tester,
      () => find.byType(CircularProgressIndicator).evaluate().isEmpty,
    );
    await binding.convertFlutterSurfaceToImage();
    await tester.pump();

    Future<void> shot(String name) async {
      await _waitFor(
        tester,
        () => find.text(AppStrings.savingDraft).evaluate().isEmpty,
      );
      await binding.takeScreenshot('$phase-$name');
    }

    if (phase == 'draft') {
      expect(find.text(AppStrings.baselineTitle), findsOneWidget);
      await shot('purpose');
      await _choose(tester, AppStrings.weightUnits, 'lb');
      await _choose(tester, AppStrings.lengthUnits, LengthUnit.inch.name);
      await _tap(tester, AppStrings.continueLabel);
      await _enter(tester, OnboardingField.age, '17');
      await _choose(tester, AppStrings.equationInput, AppStrings.male);
      await _enter(tester, OnboardingField.height, '99');
      await _enter(tester, OnboardingField.startingWeight, '180');
      await _tap(tester, AppStrings.continueLabel);
      expect(find.text(AppStrings.adultOnly), findsOneWidget);
      await _enter(tester, OnboardingField.age, '30');
      await _tap(tester, AppStrings.continueLabel);
      expect(find.text(AppStrings.outlierTitle), findsOneWidget);
      await _tap(tester, AppStrings.changeEntry);
      expect(_field(tester, OnboardingField.height).controller!.text, '99');
      await _enter(tester, OnboardingField.height, '70');
      await shot('baseline');
      await _tap(tester, AppStrings.continueLabel);
      expect(find.text(AppStrings.measurements), findsOneWidget);
      await shot('recoverable-draft');
      final BaselineSnapshot? saved = _snapshotOrNull(await repository.load());
      expect(saved, isA<DraftBaselineSnapshot>());
      final OnboardingDraft draft = (saved! as DraftBaselineSnapshot).draft;
      expect(draft.step, OnboardingStep.measurements);
      expect(draft.text[OnboardingField.age], '30');
      expect(draft.units.weight, WeightUnit.lb);
      expect(
        draft.quantities[OnboardingField.startingWeight]!.canonicalValue,
        closeTo(180 * 0.45359237, 1e-10),
      );
      return;
    }

    if (phase == 'complete') {
      expect(find.text(AppStrings.measurements), findsOneWidget);
      final OnboardingDraft restored =
          (_snapshotOrNull(before)! as DraftBaselineSnapshot).draft;
      expect(restored.text[OnboardingField.age], '30');
      await shot('resumed');
      await _tap(tester, AppStrings.continueLabel);
      expect(find.text(AppStrings.activity), findsOneWidget);
      await shot('activity');
      await _tap(tester, AppStrings.continueLabel);
      await _choose(tester, AppStrings.goalIntent, AppStrings.loss);
      await _enter(tester, OnboardingField.goalWeight, '160');
      await _choose(tester, AppStrings.lossRate, AppStrings.rateLabels.first);
      await _choose(tester, AppStrings.goalIntent, AppStrings.maintenance);
      expect(
        find.byKey(const ValueKey<OnboardingField>(OnboardingField.goalWeight)),
        findsNothing,
      );
      await _choose(tester, AppStrings.pregnancy, AppStrings.yes);
      expect(find.text(AppStrings.applicabilityLimited), findsOneWidget);
      await shot('goal');
      final Finder finish = find.text(AppStrings.finishSetup);
      await tester.ensureVisible(finish);
      await tester.tap(finish);
      await tester.tap(finish);
      await _waitFor(
        tester,
        () => find.text(AppStrings.setupSaved).evaluate().isNotEmpty,
      );
      await shot('landing');
      final BaselineSnapshot? saved = _snapshotOrNull(await repository.load());
      expect(saved, isA<CompletedBaselineSnapshot>());
      final CompletedBaseline baseline =
          (saved! as CompletedBaselineSnapshot).baseline;
      expect(baseline.startingWeight.observedAt, restored.startingTime);
      expect(baseline.profile.waistCm, isNull);
      expect(baseline.profile.typicalDailySteps, isNull);
      expect(baseline.profile.activityLevel, isNull);
      expect(baseline.profile.reportedBodyFat, isNull);
      expect(baseline.profile.pregnancy, ApplicabilityAnswer.yes);
      expect(baseline.profile.breastfeeding, ApplicabilityAnswer.unknown);
      expect(baseline.goal, isA<MaintenanceGoal>());
      expect(
        {
          baseline.profile.metadata.id,
          baseline.startingWeight.metadata.id,
          baseline.goal.metadata.id,
        }.length,
        3,
      );
    } else {
      expect(_snapshotOrNull(before), isA<CompletedBaselineSnapshot>());
      expect(find.text(AppStrings.landingTitle), findsOneWidget);
      expect(find.text(AppStrings.setupSaved), findsNothing);
      await shot('reopened-landing');
    }

    await _tap(tester, AppStrings.reviewProfile);
    expect(find.text(AppStrings.profileTitle), findsOneWidget);
    final CompletedBaseline baseline =
        (_snapshotOrNull(before) is CompletedBaselineSnapshot)
        ? (_snapshotOrNull(before)! as CompletedBaselineSnapshot).baseline
        : (_snapshotOrNull(await repository.load())!
                  as CompletedBaselineSnapshot)
              .baseline;
    expect(
      find.text(baselineTimeLabel(baseline.startingWeight.observedAt)),
      findsOneWidget,
    );
    await shot('profile');
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -900),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await shot('profile-goal');
    Navigator.of(
      tester.element(find.byType(Scaffold).last),
    ).pushNamed(AppRoutes.counter);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(AppStrings.incrementTooltip));
    await tester.pump();
    expect(find.text('1'), findsOneWidget);
    await shot('counter');
  });
}

Future<void> _waitFor(WidgetTester tester, bool Function() ready) async {
  for (int attempt = 0; attempt < 200; attempt++) {
    if (ready()) return;
    await tester.pump(const Duration(milliseconds: 100));
  }
  fail('The real app did not reach the expected state within 20 seconds.');
}

Future<void> _tap(WidgetTester tester, String label) async {
  final Finder finder = find.text(label).last;
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _enter(
  WidgetTester tester,
  OnboardingField field,
  String value,
) async {
  final Finder finder = find.byKey(ValueKey<OnboardingField>(field));
  await tester.ensureVisible(finder);
  await tester.enterText(finder, value);
  await tester.pumpAndSettle();
}

TextFormField _field(WidgetTester tester, OnboardingField field) =>
    tester.widget<TextFormField>(find.byKey(ValueKey<OnboardingField>(field)));

Future<void> _choose(WidgetTester tester, String label, String value) async {
  final Finder dropdown = find.byKey(ValueKey<String>(label));
  await tester.ensureVisible(dropdown);
  await tester.tap(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(find.text(value).last);
  await tester.pumpAndSettle();
}

BaselineSnapshot? _snapshotOrNull(
  Either<BaselineFailure, BaselineSnapshot?> result,
) => result.fold<BaselineSnapshot?>((_) => null, (snapshot) => snapshot);
