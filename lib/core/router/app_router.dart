import 'package:tspm/core/router/exports.dart';

abstract final class AppRouter {
  static Route<void> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.home:
      case AppRoutes.counter:
        return MaterialPageRoute<void>(
          builder: (_) => const CounterPage(title: AppStrings.homeTitle),
        );
      case AppRoutes.product:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const BaselinePage(),
        );
      case AppRoutes.profile:
        final Object? args = settings.arguments;
        if (args is ProfileRouteArgs) {
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => BaselineProfilePage(baseline: args.baseline),
          );
        }
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const Scaffold(
            body: Center(child: Text(AppStrings.unknownRoute)),
          ),
        );
      default:
        return MaterialPageRoute<void>(
          builder: (_) => const Scaffold(
            body: Center(child: Text(AppStrings.unknownRoute)),
          ),
        );
    }
  }
}
