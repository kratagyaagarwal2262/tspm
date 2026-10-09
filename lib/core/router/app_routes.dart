import 'exports.dart';

abstract final class AppRoutes {
  static const String home = '/';
  static const String product = '/product';
  static const String profile = '/profile';
  static const String counter = '/counter';
}

final class ProfileRouteArgs {
  const ProfileRouteArgs({required this.baseline});
  final CompletedBaseline baseline;
}
