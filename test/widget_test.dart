// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:tspm/core/router/exports.dart';
import 'package:tspm/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });

  group('Theme acceptance coverage', () {
    testWidgets('light is the default even when the system is dark', (
      tester,
    ) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await tester.pumpWidget(const MyApp());

      final ThemeData theme = Theme.of(tester.element(find.byType(Scaffold)));
      expect(theme.brightness, Brightness.light);
      expect(theme.scaffoldBackgroundColor, const Color(0xFFF7F1E8));
      expect(theme.colorScheme.primary, const Color(0xFF753B50));
    });

    testWidgets('an explicit dark choice uses the coordinated dark theme', (
      tester,
    ) async {
      await tester.pumpWidget(const MyApp(themeMode: ThemeMode.dark));

      final ThemeData theme = Theme.of(tester.element(find.byType(Scaffold)));
      expect(theme.brightness, Brightness.dark);
      expect(theme.scaffoldBackgroundColor, const Color(0xFF251B20));
      await tester.tap(find.byTooltip(AppStrings.incrementTooltip));
      await tester.pump();
      expect(find.text('1'), findsOneWidget);
    });

    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      testWidgets('$mode applies transparent system bars across routes', (
        tester,
      ) async {
        await tester.pumpWidget(MyApp(themeMode: mode));

        void expectSystemBars() {
          final Iterable<AnnotatedRegion<SystemUiOverlayStyle>> regions = tester
              .widgetList<AnnotatedRegion<SystemUiOverlayStyle>>(
                find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
              );
          final Brightness icons = mode == ThemeMode.light
              ? Brightness.dark
              : Brightness.light;
          expect(
            regions.any(
              (region) =>
                  region.value.systemNavigationBarColor ==
                      AppColors.transparent &&
                  region.value.systemNavigationBarContrastEnforced == false &&
                  region.value.systemNavigationBarIconBrightness == icons,
            ),
            isTrue,
          );
        }

        expectSystemBars();
        final BuildContext context = tester.element(find.byType(Scaffold));
        Navigator.of(context).pushNamed('/unknown-test-route');
        await tester.pumpAndSettle();
        expect(find.text(AppStrings.unknownRoute), findsOneWidget);
        expectSystemBars();
      });

      testWidgets('$mode keeps the counter usable at 200% text scale', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        await tester.pumpWidget(MyApp(themeMode: mode));
        expect(tester.takeException(), isNull);
        expect(find.text(AppStrings.counterPrompt), findsOneWidget);
        await tester.tap(find.byTooltip(AppStrings.incrementTooltip));
        await tester.pump();
        expect(find.text('1'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('$mode counter meets accessibility guidelines', (
        tester,
      ) async {
        final SemanticsHandle handle = tester.ensureSemantics();
        try {
          await tester.pumpWidget(MyApp(themeMode: mode));

          await expectLater(tester, meetsGuideline(textContrastGuideline));
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        } finally {
          handle.dispose();
        }
      });
    }
  });
}
