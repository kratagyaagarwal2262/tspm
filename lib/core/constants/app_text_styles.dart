import 'package:tspm/core/router/exports.dart';

/// Uses Material's offline system font; platform text scaling remains intact.
abstract final class AppTextStyles {
  static TextStyle display({Color? color}) =>
      TextStyle(fontSize: 32, fontWeight: FontWeight.w500, color: color);

  static TextStyle sectionTitle({Color? color}) =>
      TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: color);

  static TextStyle body({Color? color}) =>
      TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: color);

  static TextStyle supporting({Color? color}) =>
      TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: color);

  static TextStyle caption({Color? color}) =>
      TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: color);

  static TextStyle chartAnnotation({Color? color}) => caption(color: color);
}
