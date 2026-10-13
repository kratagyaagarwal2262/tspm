import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tspm/core/router/exports.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('tspm/protected_baseline');
  String? stored;
  bool failRead = false;
  bool failWrite = false;
  bool uncertainWrite = false;
  Completer<void>? delayedWrite;
  setUp(() {
    stored = null;
    failRead = false;
    failWrite = false;
    uncertainWrite = false;
    delayedWrite = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (failRead) throw PlatformException(code: 'io');
          if (call.method == 'read') return stored;
          final gate = delayedWrite;
          delayedWrite = null;
          final shouldFail = failWrite;
          if (gate != null) await gate.future;
          if (shouldFail) {
            throw PlatformException(
              code: 'io',
              details: {
                'writeOutcome': uncertainWrite ? 'uncertain' : 'notCommitted',
              },
            );
          }
          final args = call.arguments as Map;
          stored = args['nextJson'] as String;
          return null;
        });
  });
  Future<void> pump(
    WidgetTester tester, {
    double scale = 1,
    ThemeData? theme,
    Widget? home,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: home ?? const BaselinePage(),
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
      await tester.ensureVisible(find.text('Continue'));
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
  testWidgets(
    '200 percent step navigation resets scroll so heading and first field are visible',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2220);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await pump(tester, scale: 2);
      await tester.ensureVisible(find.text(AppStrings.continueLabel));
      await tester.tap(find.text(AppStrings.continueLabel));
      await tester.pumpAndSettle();
      expect(
        find.text(AppStrings.stepProgress(2)).hitTestable(),
        findsOneWidget,
      );
      final age = find.byKey(
        const ValueKey<OnboardingField>(OnboardingField.age),
      );
      expect(age.hitTestable(), findsOneWidget);
      expect(
        tester.getRect(age).top,
        greaterThanOrEqualTo(tester.getRect(find.byType(AppBar)).bottom),
      );
      await tester.ensureVisible(find.text(AppStrings.editWeightTime));
      await tester.tap(find.byTooltip(AppStrings.back));
      await tester.pumpAndSettle();
      expect(
        find.text(AppStrings.stepProgress(1)).hitTestable(),
        findsOneWidget,
      );
      expect(
        tester.getRect(find.text(AppStrings.baselinePurpose)).top,
        greaterThanOrEqualTo(tester.getRect(find.byType(AppBar)).bottom),
      );
      expect(tester.takeException(), isNull);
    },
  );

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

  for (final focusBeforeEntry in [false, true]) {
    testWidgets(
      'semantics text entry ${focusBeforeEntry ? 'focused' : 'after rejecting unfocused input'} survives queued autosave and Continue at 200 percent',
      (tester) async {
        final handle = tester.ensureSemantics();
        tester.view.physicalSize = const Size(1080, 2220);
        tester.view.devicePixelRatio = 2.75;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        stored = BaselineCodec.encode(
          DraftBaselineSnapshot(
            draft:
                OnboardingDraft.initial(
                  now: DateTime.now(),
                  setupId: 'semantics-entry',
                ).copyWith(
                  step: OnboardingStep.requiredBaseline,
                  equationInput: EquationSexInput.male,
                ),
          ),
        );
        await pump(tester, scale: 2);
        final gate = Completer<void>();
        delayedWrite = gate;
        for (final entry in {
          OnboardingField.age: '30',
          OnboardingField.height: '175',
          OnboardingField.startingWeight: '80',
        }.entries) {
          final field = find.byKey(ValueKey<OnboardingField>(entry.key));
          await tester.ensureVisible(field);
          await tester.pump();
          if (focusBeforeEntry) {
            await tester.tap(field);
            await tester.pump();
          }
          final editable = find.descendant(
            of: field,
            matching: find.byType(EditableText),
          );
          var node = tester.getSemantics(editable);
          if (!focusBeforeEntry) {
            expect(
              node.getSemanticsData().hasAction(SemanticsAction.setText),
              isFalse,
            );
            node.owner!.performAction(
              node.id,
              SemanticsAction.setText,
              entry.value,
            );
            await tester.pump();
            expect(
              tester.widget<TextFormField>(field).controller!.text,
              isEmpty,
            );
            await tester.tap(field);
            await tester.pump();
            node = tester.getSemantics(editable);
          }
          expect(
            node.getSemanticsData().hasAction(SemanticsAction.setText),
            isTrue,
            reason: entry.key.name,
          );
          node.owner!.performAction(
            node.id,
            SemanticsAction.setText,
            entry.value,
          );
          await tester.pump();
          expect(
            tester.widget<TextFormField>(field).controller!.text,
            entry.value,
          );
        }
        gate.complete();
        await tester.pumpAndSettle();
        final saved =
            BaselineCodec.decode(
                  stored!,
                ).getOrElse(() => throw StateError('invalid'))
                as DraftBaselineSnapshot;
        expect(saved.draft.text[OnboardingField.age], '30');
        expect(saved.draft.quantities[OnboardingField.height]?.rawText, '175');
        expect(
          saved.draft.quantities[OnboardingField.startingWeight]?.rawText,
          '80',
        );
        await tester.ensureVisible(find.text(AppStrings.continueLabel));
        await tester.tap(find.text(AppStrings.continueLabel));
        await tester.pumpAndSettle();
        expect(
          find.text(AppStrings.stepProgress(3)).hitTestable(),
          findsOneWidget,
        );
        expect(find.text(AppStrings.requiredInput), findsNothing);
        handle.dispose();
      },
    );
  }

  Future<void> selectClock(
    WidgetTester tester,
    String date,
    String hour,
    String minute,
  ) async {
    await tester.ensureVisible(find.text(AppStrings.editWeightTime));
    await tester.tap(find.text(AppStrings.editWeightTime));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byType(DatePickerDialog),
        matching: find.byType(TextFormField),
      ),
      date,
    );
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.keyboard_outlined));
    await tester.pumpAndSettle();
    final fields = find.descendant(
      of: find.byType(TimePickerDialog),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(fields.at(0), hour);
    await tester.enterText(fields.at(1), minute);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'valid clock edit saves selected day, clock and original offset',
    (tester) async {
      stored = BaselineCodec.encode(
        DraftBaselineSnapshot(
          draft: completeDraft()
              .copyWith(step: OnboardingStep.requiredBaseline)
              .withStartingTime(
                ObservationTime.fromSelectedLocal(DateTime(2026, 3, 7, 8)),
              ),
        ),
      );
      await pump(tester);
      await selectClock(tester, '03/07/2026', '9', '15');
      final saved =
          BaselineCodec.decode(
                stored!,
              ).getOrElse(() => throw StateError('invalid'))
              as DraftBaselineSnapshot;
      final expected = ObservationTime.fromSelectedLocal(
        DateTime(2026, 3, 7, 9, 15),
      );
      expect(saved.draft.startingTime, expected);
      expect(find.text(baselineTimeLabel(expected)), findsOneWidget);
      expect(find.text(AppStrings.invalidTime), findsNothing);
    },
  );

  testWidgets(
    'nonexistent local clock retains saved time and shows feedback until valid edit',
    (tester) async {
      final previous = ObservationTime.fromSelectedLocal(
        DateTime(2026, 3, 7, 9, 15),
      );
      stored = BaselineCodec.encode(
        DraftBaselineSnapshot(
          draft: completeDraft()
              .copyWith(step: OnboardingStep.requiredBaseline)
              .withStartingTime(previous),
        ),
      );
      await pump(tester);
      await selectClock(tester, '03/08/2026', '2', '30');
      final saved =
          BaselineCodec.decode(
                stored!,
              ).getOrElse(() => throw StateError('invalid'))
              as DraftBaselineSnapshot;
      expect(saved.draft.startingTime, previous);
      expect(find.text(AppStrings.invalidTime), findsOneWidget);
      expect(find.text(baselineTimeLabel(previous)), findsOneWidget);
      await selectClock(tester, '03/08/2026', '9', '15');
      expect(find.text(AppStrings.invalidTime), findsNothing);
    },
    // Run with TZ=America/New_York to exercise real platform normalization.
    skip: DateTime(2026, 3, 8, 2, 30).hour == 2,
  );

  for (final dark in [false, true]) {
    final theme = dark ? AppTheme.dark : AppTheme.light;
    final name = dark ? 'dark' : 'light';
    for (final step in OnboardingStep.values) {
      testWidgets(
        '$name ${step.name} at 200 percent has reachable controls and accessible labels',
        (tester) async {
          final handle = tester.ensureSemantics();
          stored = BaselineCodec.encode(
            DraftBaselineSnapshot(draft: completeDraft().copyWith(step: step)),
          );
          await pump(tester, scale: 2, theme: theme);
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          await expectLater(tester, meetsGuideline(textContrastGuideline));
          final action = find.text(
            step == OnboardingStep.goalAndApplicability
                ? AppStrings.finishSetup
                : AppStrings.continueLabel,
          );
          await tester.ensureVisible(action);
          expect(action.hitTestable(), findsOneWidget);
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          await expectLater(tester, meetsGuideline(textContrastGuideline));
          expect(tester.takeException(), isNull);
          handle.dispose();
        },
      );
    }
    testWidgets(
      '$name landing and Profile at 200 percent retain provenance and accessible review',
      (tester) async {
        final handle = tester.ensureSemantics();
        final baseline = BaselineValidation.prepareCompletion(
          completeDraft(),
          DateTime.now().toUtc(),
          LocalDay.parse('2026-10-09'),
        ).getOrElse(() => throw StateError('invalid'));
        stored = BaselineCodec.encode(
          CompletedBaselineSnapshot(baseline: baseline),
        );
        await pump(tester, scale: 2, theme: theme);
        expect(
          find.text(baselineTimeLabel(baseline.startingWeight.observedAt)),
          findsOneWidget,
        );
        await tester.ensureVisible(find.text(AppStrings.reviewProfile));
        expect(
          find.text(AppStrings.reviewProfile).hitTestable(),
          findsOneWidget,
        );
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        expect(tester.takeException(), isNull);
        await pump(
          tester,
          scale: 2,
          theme: theme,
          home: BaselineProfilePage(baseline: baseline),
        );
        expect(
          find.text(baselineTimeLabel(baseline.startingWeight.observedAt)),
          findsOneWidget,
        );
        await tester.ensureVisible(find.text(AppStrings.applicabilityLimited));
        expect(
          find.text(AppStrings.applicabilityLimited).hitTestable(),
          findsOneWidget,
        );
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        expect(tester.takeException(), isNull);
        handle.dispose();
      },
    );
  }

  testWidgets('exit waits for newest edit and warns when its save fails', (
    tester,
  ) async {
    stored = BaselineCodec.encode(
      DraftBaselineSnapshot(
        draft: completeDraft().copyWith(step: OnboardingStep.purposeAndUnits),
      ),
    );
    await pump(
      tester,
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const BaselinePage()),
            ),
            child: const Text('Open baseline'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open baseline'));
    await tester.pumpAndSettle();
    final gate = Completer<void>();
    delayedWrite = gate;
    final units = find.byKey(const ValueKey<String>(AppStrings.weightUnits));
    await tester.tap(units);
    await tester.pumpAndSettle();
    await tester.tap(find.text('lb').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(AppStrings.back));
    await tester.pump();
    failWrite = true;
    await tester.tap(units);
    await tester.pumpAndSettle();
    await tester.tap(find.text('kg').last);
    await tester.pumpAndSettle();
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.unsavedExitTitle), findsOneWidget);
    expect(find.text('Open baseline').hitTestable(), findsNothing);
    await tester.tap(find.text(AppStrings.stay));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.unsavedDraft), findsOneWidget);
  });

  testWidgets(
    'uncertain completion failure shows frozen answers and retry without editable fields',
    (tester) async {
      stored = BaselineCodec.encode(
        DraftBaselineSnapshot(draft: completeDraft()),
      );
      await pump(tester);
      failWrite = true;
      uncertainWrite = true;
      await tester.ensureVisible(find.text(AppStrings.finishSetup));
      await tester.tap(find.text(AppStrings.finishSetup));
      await tester.pumpAndSettle();
      expect(find.text('30'), findsOneWidget);
      expect(find.text('175 cm'), findsOneWidget);
      expect(find.text('80 kg'), findsOneWidget);
      expect(find.text(AppStrings.retry), findsOneWidget);
      expect(find.text(AppStrings.uncertainSave), findsOneWidget);
      expect(find.text(AppStrings.editAnswers), findsNothing);
      expect(find.text(AppStrings.readOnly), findsNothing);
      expect(find.text('Saved intention'), findsNothing);
      expect(find.text(AppStrings.setupSaved), findsNothing);
      expect(find.byType(TextFormField), findsNothing);
    },
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

  for (final dark in [false, true]) {
    testWidgets(
      '${dark ? 'dark' : 'light'} phone selected goal labels fit at 200 percent',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2220);
        tester.view.devicePixelRatio = 2.75;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        stored = BaselineCodec.encode(
          DraftBaselineSnapshot(
            draft: completeDraft().copyWith(
              goalIntent: GoalIntent.loss,
              lossRate: LossRate.threeQuarterPercent,
            ),
          ),
        );
        await pump(
          tester,
          scale: 2,
          theme: dark ? AppTheme.dark : AppTheme.light,
        );
        for (final entry in {
          AppStrings.goalIntent: AppStrings.loss,
          AppStrings.lossRate:
              AppStrings.rateLabels[LossRate.threeQuarterPercent.index],
        }.entries) {
          final field = find.byKey(ValueKey<String>(entry.key));
          await tester.ensureVisible(field);
          final text = find
              .descendant(of: field, matching: find.text(entry.value))
              .hitTestable();
          expect(text, findsOneWidget);
          final selectedBounds = tester.getRect(
            find.ancestor(of: text, matching: find.byType(IndexedStack)).first,
          );
          final textBounds = tester.getRect(text);
          final buttonBounds = tester.getRect(
            find
                .ancestor(
                  of: text,
                  matching: find.byWidgetPredicate(
                    (widget) => widget is DropdownButton,
                  ),
                )
                .first,
          );
          final paragraph = tester.renderObject<RenderParagraph>(
            find.descendant(of: text, matching: find.byType(RichText)),
          );
          expect(
            paragraph.getMaxIntrinsicHeight(textBounds.width),
            lessThanOrEqualTo(textBounds.height),
            reason: '${entry.key} must fit every selected text line',
          );
          expect(textBounds.bottom, lessThanOrEqualTo(buttonBounds.bottom));
          expect(
            textBounds.top,
            greaterThanOrEqualTo(selectedBounds.top),
            reason: '${entry.key} must show its full selected label',
          );
          expect(
            textBounds.bottom,
            lessThanOrEqualTo(selectedBounds.bottom),
            reason: '${entry.key} must show its full selected label',
          );
          expect(textBounds.left, greaterThanOrEqualTo(selectedBounds.left));
          expect(textBounds.right, lessThanOrEqualTo(selectedBounds.right));
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

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
