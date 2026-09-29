import 'package:tspm/core/router/exports.dart';

abstract final class AppRouter {
  static Route<void> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.home:
        return MaterialPageRoute<void>(
          builder: (_) => const CounterPage(title: AppStrings.homeTitle),
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
