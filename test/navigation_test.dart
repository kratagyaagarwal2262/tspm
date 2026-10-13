import 'package:flutter_test/flutter_test.dart';
import 'package:tspm/core/router/exports.dart';
import 'package:tspm/main.dart';

void main() {
  testWidgets('AC 14: explicit counter route preserves increment behavior', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp(initialRoute: AppRoutes.counter));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.counterPrompt), findsOneWidget);
    await tester.tap(find.byTooltip(AppStrings.incrementTooltip));
    await tester.pump();
    expect(find.text('1'), findsOneWidget);
  });

  for (final Object? args in [
    null,
    <String, String>{'baseline': 'wrong'},
  ]) {
    testWidgets(
      'AC 10: Profile rejects ${args == null ? 'missing' : 'wrong'} route arguments',
      (tester) async {
        await tester.pumpWidget(const MyApp(initialRoute: AppRoutes.counter));
        Navigator.of(
          tester.element(find.byType(Scaffold)),
        ).pushNamed(AppRoutes.profile, arguments: args);
        await tester.pumpAndSettle();
        expect(find.text(AppStrings.unknownRoute), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
