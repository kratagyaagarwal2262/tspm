import 'package:tspm/core/router/exports.dart';

/// Screen backgrounds extend behind system bars; controls retain safe insets.
abstract final class AppSystemUi {
  static SystemUiOverlayStyle overlayStyleFor(Brightness brightness) {
    final Brightness iconBrightness = brightness == Brightness.light
        ? Brightness.dark
        : Brightness.light;
    return SystemUiOverlayStyle(
      statusBarColor: AppColors.transparent,
      statusBarBrightness: brightness,
      statusBarIconBrightness: iconBrightness,
      systemStatusBarContrastEnforced: false,
      systemNavigationBarColor: AppColors.transparent,
      systemNavigationBarDividerColor: AppColors.transparent,
      systemNavigationBarIconBrightness: iconBrightness,
      systemNavigationBarContrastEnforced: false,
    );
  }
}
