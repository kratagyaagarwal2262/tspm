import 'package:flutter_test/flutter_test.dart';
import 'package:tspm/core/router/exports.dart';
import 'package:tspm/main.dart';

void main() {
  testWidgets('AC 14: explicit counter route preserves increment behavior', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    Navigator.of(tester.element(find.byType(Scaffold))).pushNamed('/counter');
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.counterPrompt), findsOneWidget);
    await tester.tap(find.byTooltip(AppStrings.incrementTooltip));
    await tester.pump();
    expect(find.text('1'), findsOneWidget);
  });
}
