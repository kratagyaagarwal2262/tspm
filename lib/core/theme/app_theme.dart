import 'package:tspm/core/router/exports.dart';

abstract final class AppTheme {
  static final ThemeData light = _build(Brightness.light);
  static final ThemeData dark = _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    final Color background = isDark
        ? AppColors.darkBackground
        : AppColors.lightBackground;
    final Color surface = isDark
        ? AppColors.darkSurface
        : AppColors.lightSurface;
    final Color text = isDark ? AppColors.darkText : AppColors.lightText;
    final Color muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    final Color primary = isDark
        ? AppColors.darkPrimary
        : AppColors.lightPrimary;
    final Color onPrimary = isDark
        ? AppColors.darkOnPrimary
        : AppColors.lightOnPrimary;
    final Color border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final Color error = isDark ? AppColors.darkError : AppColors.lightError;
    final Color errorContainer = isDark
        ? AppColors.darkErrorContainer
        : AppColors.lightErrorContainer;
    final Color pressed = isDark
        ? AppColors.darkPressed
        : AppColors.lightPressed;
    final Color focused = isDark
        ? AppColors.darkFocused
        : AppColors.lightFocused;
    final Color filledPressed = isDark
        ? AppColors.darkFilledPressed
        : AppColors.lightFilledPressed;
    final Color disabledText = isDark
        ? AppColors.darkDisabledText
        : AppColors.lightDisabledText;
    final ColorScheme colors = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: surface,
      onPrimaryContainer: text,
      primaryFixed: AppColors.darkPrimary,
      primaryFixedDim: AppColors.darkMuted,
      onPrimaryFixed: AppColors.darkOnPrimary,
      onPrimaryFixedVariant: AppColors.lightPrimary,
      secondary: primary,
      onSecondary: onPrimary,
      secondaryContainer: surface,
      onSecondaryContainer: text,
      secondaryFixed: AppColors.darkPrimary,
      secondaryFixedDim: AppColors.darkMuted,
      onSecondaryFixed: AppColors.darkOnPrimary,
      onSecondaryFixedVariant: AppColors.lightPrimary,
      tertiary: muted,
      onTertiary: background,
      tertiaryContainer: surface,
      onTertiaryContainer: text,
      tertiaryFixed: AppColors.darkMuted,
      tertiaryFixedDim: AppColors.darkPrimary,
      onTertiaryFixed: AppColors.darkOnPrimary,
      onTertiaryFixedVariant: AppColors.lightPrimary,
      error: error,
      onError: background,
      errorContainer: errorContainer,
      onErrorContainer: isDark ? AppColors.darkError : AppColors.lightError,
      surface: background,
      onSurface: text,
      surfaceDim: surface,
      surfaceBright: background,
      surfaceContainerLowest: background,
      surfaceContainerLow: surface,
      surfaceContainer: surface,
      surfaceContainerHigh: surface,
      surfaceContainerHighest: surface,
      onSurfaceVariant: muted,
      outline: muted,
      outlineVariant: border,
      shadow: AppColors.transparent,
      scrim: AppColors.scrim,
      inverseSurface: text,
      onInverseSurface: background,
      inversePrimary: isDark ? AppColors.lightPrimary : AppColors.darkPrimary,
      surfaceTint: AppColors.transparent,
    );
    final RoundedRectangleBorder controlShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppDimensions.controlRadius),
    );
    final TextStyle label = AppTextStyles.supporting(
      color: text,
    ).copyWith(fontWeight: FontWeight.w500);

    WidgetStateProperty<Color?> overlay({bool filled = false}) =>
        WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
          if (states.contains(WidgetState.disabled)) {
            return AppColors.transparent;
          }
          if (states.contains(WidgetState.pressed)) {
            return filled ? filledPressed : pressed;
          }
          if (states.contains(WidgetState.focused)) {
            return filled ? filledPressed : focused;
          }
          if (states.contains(WidgetState.hovered)) return pressed;
          return AppColors.transparent;
        });

    ButtonStyle buttonStyle({bool filled = false, bool outlined = false}) =>
        ButtonStyle(
          minimumSize: const WidgetStatePropertyAll<Size>(
            Size(AppDimensions.minTapTarget, AppDimensions.minTapTarget),
          ),
          padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
            EdgeInsets.symmetric(
              horizontal: AppDimensions.medium,
              vertical: AppDimensions.small,
            ),
          ),
          shape: WidgetStatePropertyAll<OutlinedBorder>(controlShape),
          elevation: const WidgetStatePropertyAll<double>(0),
          surfaceTintColor: const WidgetStatePropertyAll<Color>(
            AppColors.transparent,
          ),
          textStyle: WidgetStatePropertyAll<TextStyle>(label),
          backgroundColor: WidgetStateProperty.resolveWith<Color?>((
            Set<WidgetState> states,
          ) {
            if (!filled) return AppColors.transparent;
            return states.contains(WidgetState.disabled) ? surface : primary;
          }),
          foregroundColor: WidgetStateProperty.resolveWith<Color?>((
            Set<WidgetState> states,
          ) {
            if (states.contains(WidgetState.disabled)) return disabledText;
            return filled ? onPrimary : primary;
          }),
          side: WidgetStateProperty.resolveWith<BorderSide?>((
            Set<WidgetState> states,
          ) {
            if (states.contains(WidgetState.focused) &&
                !states.contains(WidgetState.disabled)) {
              return BorderSide(
                color: filled ? onPrimary : primary,
                width: AppDimensions.focusBorderWidth,
              );
            }
            return outlined
                ? BorderSide(
                    color: states.contains(WidgetState.disabled)
                        ? border
                        : muted,
                    width: AppDimensions.borderWidth,
                  )
                : BorderSide.none;
          }),
          overlayColor: overlay(filled: filled),
          tapTargetSize: MaterialTapTargetSize.padded,
          visualDensity: VisualDensity.standard,
        );

    OutlineInputBorder inputBorder(Color color, {bool focused = false}) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.controlRadius),
          borderSide: BorderSide(
            color: color,
            width: focused
                ? AppDimensions.focusBorderWidth
                : AppDimensions.borderWidth,
          ),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colors,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      cardColor: surface,
      disabledColor: disabledText,
      dividerColor: border,
      focusColor: focused,
      hoverColor: pressed,
      highlightColor: pressed,
      splashColor: pressed,
      shadowColor: AppColors.transparent,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      textTheme: TextTheme(
        displayLarge: AppTextStyles.display(color: text),
        displayMedium: AppTextStyles.display(color: text),
        displaySmall: AppTextStyles.display(color: text),
        headlineLarge: AppTextStyles.sectionTitle(color: text),
        headlineMedium: AppTextStyles.sectionTitle(color: text),
        headlineSmall: AppTextStyles.sectionTitle(color: text),
        titleLarge: AppTextStyles.sectionTitle(color: text),
        titleMedium: AppTextStyles.body(
          color: text,
        ).copyWith(fontWeight: FontWeight.w500),
        titleSmall: label,
        bodyLarge: AppTextStyles.body(color: text),
        bodyMedium: AppTextStyles.body(color: text),
        bodySmall: AppTextStyles.supporting(color: muted),
        labelLarge: label,
        labelMedium: AppTextStyles.caption(
          color: text,
        ).copyWith(fontWeight: FontWeight.w500),
        labelSmall: AppTextStyles.caption(color: muted),
      ),
      appBarTheme: AppBarThemeData(
        systemOverlayStyle: AppSystemUi.overlayStyleFor(brightness),
        backgroundColor: background,
        foregroundColor: text,
        surfaceTintColor: AppColors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: AppTextStyles.sectionTitle(color: text),
        iconTheme: IconThemeData(color: text),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: buttonStyle(filled: true),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: buttonStyle(filled: true),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: buttonStyle(outlined: true),
      ),
      textButtonTheme: TextButtonThemeData(style: buttonStyle()),
      iconButtonTheme: IconButtonThemeData(
        style: buttonStyle().copyWith(
          foregroundColor: WidgetStateProperty.resolveWith<Color?>(
            (Set<WidgetState> states) =>
                states.contains(WidgetState.disabled) ? disabledText : text,
          ),
          padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
            EdgeInsets.all(AppDimensions.small),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.all(AppDimensions.medium),
        constraints: const BoxConstraints(
          minHeight: AppDimensions.minTapTarget,
        ),
        labelStyle: AppTextStyles.body(color: muted),
        floatingLabelStyle: AppTextStyles.supporting(color: primary),
        hintStyle: AppTextStyles.body(color: muted),
        helperStyle: AppTextStyles.caption(color: muted),
        errorStyle: AppTextStyles.supporting(color: error),
        border: inputBorder(muted),
        enabledBorder: inputBorder(muted),
        disabledBorder: inputBorder(border),
        focusedBorder: inputBorder(primary, focused: true),
        errorBorder: inputBorder(error),
        focusedErrorBorder: inputBorder(error, focused: true),
        prefixIconColor: muted,
        suffixIconColor: muted,
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: AppColors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.groupRadius),
          side: BorderSide(color: border, width: AppDimensions.borderWidth),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        disabledElevation: 0,
        focusColor: filledPressed,
        hoverColor: filledPressed,
        splashColor: filledPressed,
        shape: controlShape,
        smallSizeConstraints: const BoxConstraints.tightFor(
          width: AppDimensions.minTapTarget,
          height: AppDimensions.minTapTarget,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: background,
        surfaceTintColor: AppColors.transparent,
        elevation: 0,
        indicatorColor: surface,
        indicatorShape: controlShape,
        overlayColor: overlay(),
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData?>(
          (Set<WidgetState> states) => IconThemeData(
            color: states.contains(WidgetState.disabled)
                ? disabledText
                : states.contains(WidgetState.selected)
                ? primary
                : muted,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>(
          (Set<WidgetState> states) => AppTextStyles.caption(
            color: states.contains(WidgetState.disabled)
                ? disabledText
                : states.contains(WidgetState.selected)
                ? primary
                : muted,
          ),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        modalBackgroundColor: surface,
        modalBarrierColor: AppColors.scrim,
        surfaceTintColor: AppColors.transparent,
        elevation: 0,
        modalElevation: 0,
        dragHandleColor: muted,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDimensions.sheetRadius),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.inverseSurface,
        contentTextStyle: AppTextStyles.supporting(
          color: colors.onInverseSurface,
        ),
        actionTextColor: colors.inversePrimary,
        disabledActionTextColor: muted,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        shape: controlShape,
      ),
      extensions: <ThemeExtension<dynamic>>[
        AppChartTheme(
          rawObservation: text,
          observedTrend: primary,
          normalizedTrend: muted,
          uncertaintyBand: isDark
              ? AppColors.darkUncertainty
              : AppColors.lightUncertainty,
          grid: border,
        ),
      ],
    );
  }
}
