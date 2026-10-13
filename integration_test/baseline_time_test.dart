import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tspm/core/router/exports.dart';
import 'package:tspm/main.dart';

// Run on a disposable unfinished baseline with device zone America/New_York.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'AC 6: Android picker rejects nonexistent DST clock without losing time',
    (tester) async {
      expect(DateTime(2026, 3, 8, 2, 30).hour, isNot(2));
      final repository = BaselineRepository(store: ProtectedBaselineStore());
      final before =
          (await repository.load()).getOrElse(
                () => throw StateError('read failed'),
              )
              as DraftBaselineSnapshot;
      await tester.pumpWidget(const MyApp(initialRoute: AppRoutes.product));
      await tester.pumpAndSettle();
      for (
        int step = before.draft.step.index;
        step > OnboardingStep.requiredBaseline.index;
        step--
      ) {
        await tester.tap(find.byTooltip(AppStrings.back));
        await tester.pumpAndSettle();
      }
      await binding.convertFlutterSurfaceToImage();
      await tester.pump();

      Future<void> choose(String hour) async {
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
          '03/08/2026',
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
        await tester.enterText(fields.at(1), '30');
        if (find.text('AM').evaluate().isNotEmpty) {
          await tester.tap(find.text('AM'));
        }
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
      }

      await choose('2');
      expect(find.text(AppStrings.invalidTime), findsOneWidget);
      expect(
        find.text(baselineTimeLabel(before.draft.startingTime)),
        findsOneWidget,
      );
      final rejected =
          (await repository.load()).getOrElse(
                () => throw StateError('read failed'),
              )
              as DraftBaselineSnapshot;
      expect(rejected.draft.startingTime, before.draft.startingTime);
      await binding.takeScreenshot('android-dst-rejected');

      await choose('3');
      expect(find.text(AppStrings.invalidTime), findsNothing);
      for (
        int attempt = 0;
        attempt < 200 && find.text(AppStrings.savedDraft).evaluate().isEmpty;
        attempt++
      ) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.text(AppStrings.savedDraft), findsOneWidget);
      final accepted =
          (await repository.load()).getOrElse(
                () => throw StateError('read failed'),
              )
              as DraftBaselineSnapshot;
      expect(
        accepted.draft.startingTime,
        ObservationTime.fromSelectedLocal(DateTime(2026, 3, 8, 3, 30)),
      );
      await binding.takeScreenshot('android-dst-valid');
    },
  );
}
