import 'core/router/exports.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({
    this.themeMode = ThemeMode.light,
    this.initialRoute = AppRoutes.home,
    super.key,
  });

  final ThemeMode themeMode;
  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appTitle,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      builder: (BuildContext context, Widget? child) {
        final ThemeData theme = Theme.of(context);
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: AppSystemUi.overlayStyleFor(theme.brightness),
          child: ColoredBox(
            color: theme.scaffoldBackgroundColor,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      initialRoute: initialRoute,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
