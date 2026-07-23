import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:soui/theme.dart';

/// SharePerks design tokens and [ThemeData] for light and dark mode.
///
/// Maps the app theme guide: primary trust (purple), growth (amber), success (green).
abstract final class SharePerksColors {
  // Primary palette
  static const Color primary = AppColors.brand;
  static const Color primaryHover = AppColors.secondary;
  static const Color secondary = AppColors.secondary;
  static const Color accent = AppColors.accent;

  // Light neutrals
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFF8FAFC);
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color textPrimaryLight = Color(0xFF111827);
  static const Color textSecondaryLight = Color(0xFF6B7280);

  // Dark neutrals
  static const Color backgroundDark = Color(0xFF0B0F19);
  static const Color surfaceDark = Color(0xFF111827);
  static const Color borderDark = Color(0xFF1F2937);
  static const Color textPrimaryDark = Color(0xFFF9FAFB);
  static const Color textSecondaryDark = Color(0xFF9CA3AF);

  // Semantic
  static const Color success = AppColors.success;
  static const Color warning = AppColors.warning;
  static const Color error = AppColors.error;
  static const Color info = AppColors.info;

  // Inputs (light) — crisp white fields on gray/surface pages
  static const Color inputFillLight = Color(0xFFFFFFFF);
  static const Color inputBorderLight = Color.fromARGB(255, 229, 233, 239);
}

/// Spacing scale: xs → xl.
abstract final class SharePerksSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

/// Border radii from the theme guide.
abstract final class SharePerksRadii {
  static const double sm = 6;
  static const double md = 10;
  static const double lg = 16;
  static const double xl = 24;
}

abstract final class SharePerksShadows {
  static List<BoxShadow> sm = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      offset: const Offset(0, 1),
      blurRadius: 2,
    ),
  ];

  static List<BoxShadow> md = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      offset: const Offset(0, 4),
      blurRadius: 6,
    ),
  ];

  static List<BoxShadow> lg = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.15),
      offset: const Offset(0, 10),
      blurRadius: 15,
    ),
  ];
}

/// Builds Material 3 [ThemeData] for SharePerks.
abstract final class SharePerksTheme {
  static ThemeData get light => _build(
    brightness: Brightness.light,
    colorScheme: _lightColorScheme,
    scaffoldBackground: SharePerksColors.backgroundLight,
  );

  static ThemeData get dark => _build(
    brightness: Brightness.dark,
    colorScheme: _darkColorScheme,
    scaffoldBackground: SharePerksColors.backgroundDark,
  );

  static const ColorScheme _lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: SharePerksColors.primary,
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFE8E9FC),
    onPrimaryContainer: SharePerksColors.textPrimaryLight,
    secondary: SharePerksColors.secondary,
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFFEF3C7),
    onSecondaryContainer: Color(0xFF78350F),
    tertiary: SharePerksColors.accent,
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFDCFCE7),
    onTertiaryContainer: Color(0xFF14532D),
    error: SharePerksColors.error,
    onError: Color(0xFFFFFFFF),
    surface: SharePerksColors.surfaceLight,
    onSurface: SharePerksColors.textPrimaryLight,
    onSurfaceVariant: SharePerksColors.textSecondaryLight,
    outline: SharePerksColors.borderLight,
    outlineVariant: SharePerksColors.inputBorderLight,
    shadow: Color(0x1A000000),
    scrim: Color(0x66000000),
    inverseSurface: SharePerksColors.surfaceDark,
    onInverseSurface: SharePerksColors.textPrimaryDark,
    inversePrimary: Color(0xFFC7C9F8),
  );

  static const ColorScheme _darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: SharePerksColors.primary,
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFF3730A3),
    onPrimaryContainer: Color(0xFFE8E9FC),
    secondary: SharePerksColors.secondary,
    onSecondary: Color(0xFF1C1917),
    secondaryContainer: Color(0xFF92400E),
    onSecondaryContainer: Color(0xFFFEF3C7),
    tertiary: SharePerksColors.accent,
    onTertiary: Color(0xFF052E16),
    tertiaryContainer: Color(0xFF166534),
    onTertiaryContainer: Color(0xFFDCFCE7),
    error: Color(0xFFF87171),
    onError: Color(0xFF450A0A),
    surface: SharePerksColors.surfaceDark,
    onSurface: SharePerksColors.textPrimaryDark,
    onSurfaceVariant: SharePerksColors.textSecondaryDark,
    outline: SharePerksColors.borderDark,
    outlineVariant: Color(0xFF374151),
    shadow: Color(0x66000000),
    scrim: Color(0x99000000),
    inverseSurface: SharePerksColors.backgroundLight,
    onInverseSurface: SharePerksColors.textPrimaryLight,
    inversePrimary: SharePerksColors.primaryHover,
  );

  static ThemeData _build({
    required Brightness brightness,
    required ColorScheme colorScheme,
    required Color scaffoldBackground,
  }) {
    final baseTextTheme = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      fontFamily: SharePerksFonts.inter,
    ).textTheme;
    final textTheme = baseTextTheme.copyWith(
      headlineLarge: baseTextTheme.headlineLarge?.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: colorScheme.onSurface,
      ),
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(
        fontSize: 16,

        color: colorScheme.onSurface,
      ),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        fontSize: 14,
        color: colorScheme.onSurfaceVariant,
      ),
    );

    final isLight = brightness == Brightness.light;
    final inputFill = isLight
        ? SharePerksColors.inputFillLight
        : SharePerksColors.surfaceDark;
    final inputBorder = isLight
        ? SharePerksColors.inputBorderLight
        : const Color(0xFF374151);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBackground,

      textTheme: textTheme,
      actionIconTheme: ActionIconThemeData(
        drawerButtonIconBuilder: (context) {
          return Icon(
            HugeIconsStroke.menu02,
            color: colorScheme.onSurface,
            size: 26,
          );
        },
        endDrawerButtonIconBuilder: (context) {
          return Icon(
            HugeIconsStroke.cancel01,
            color: colorScheme.onSurface,
            size: 26,
          );
        },
        closeButtonIconBuilder: (context) {
          return Icon(
            HugeIconsStroke.cancel01,
            color: colorScheme.onSurface,
            size: 26,
          );
        },
        backButtonIconBuilder: (context) {
          return Icon(
            HugeIconsStroke.arrowLeft01,
            color: colorScheme.onSurface,
            size: 28,
          );
        },
      ),

      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: isLight
            ? SharePerksColors.surfaceLight
            : SharePerksColors.surfaceDark,
        textStyle: textTheme.bodyMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SharePerksRadii.lg),
        ),
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        enableFeedback: true,
        position: PopupMenuPosition.under,
        surfaceTintColor: Colors.transparent,
        iconSize: 24,
        iconColor: colorScheme.onSurface,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.brand,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
        ),
        actionsIconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: isLight
            ? SharePerksColors.backgroundLight
            : SharePerksColors.surfaceDark,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SharePerksRadii.lg),
          side: BorderSide(color: colorScheme.outline),
        ),
        margin: EdgeInsets.zero,
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: isLight
            ? SharePerksColors.backgroundLight
            : SharePerksColors.backgroundDark,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(SharePerksRadii.lg),
            bottomRight: Radius.circular(SharePerksRadii.lg),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        iconColor: inputBorder,
        prefixIconColor: inputBorder,
        suffixIconColor: inputBorder,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: SharePerksSpacing.md,
          vertical: SharePerksSpacing.sm,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SharePerksRadii.md),
          borderSide: BorderSide(color: inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SharePerksRadii.md),
          borderSide: BorderSide(color: inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SharePerksRadii.md),
          borderSide: BorderSide(color: inputBorder),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SharePerksRadii.md),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SharePerksRadii.md),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        hintStyle: textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontFamily: SharePerksFonts.inter,
          fontWeight: FontWeight.w400,
          fontSize: 10,
        ),
      ),
      searchBarTheme: SearchBarThemeData(
        elevation: const WidgetStatePropertyAll(0),

        backgroundColor: WidgetStatePropertyAll(
          isLight
              ? SharePerksColors.backgroundLight
              : SharePerksColors.surfaceDark,
        ),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        side: WidgetStatePropertyAll(BorderSide(color: inputBorder)),

        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SharePerksRadii.md),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style:
            ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: SharePerksColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: colorScheme.onSurface.withValues(
                alpha: 0.12,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: SharePerksSpacing.lg,
                vertical: SharePerksSpacing.sm + 2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(SharePerksRadii.md),
              ),
            ).copyWith(
              overlayColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.hovered) ||
                    states.contains(WidgetState.pressed)) {
                  return SharePerksColors.primaryHover.withValues(alpha: 0.9);
                }
                return null;
              }),
            ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: SharePerksColors.secondary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: SharePerksSpacing.lg,
            vertical: SharePerksSpacing.sm + 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SharePerksRadii.md),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: SharePerksColors.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: SharePerksSpacing.lg,
            vertical: SharePerksSpacing.sm + 2,
          ),
          side: const BorderSide(color: SharePerksColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SharePerksRadii.md),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: SharePerksColors.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: SharePerksSpacing.md,
            vertical: SharePerksSpacing.sm,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: SharePerksColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SharePerksRadii.lg),
        ),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isLight ? scaffoldBackground : scaffoldBackground,
        selectedItemColor: SharePerksColors.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        enableFeedback: true,
        unselectedIconTheme: IconThemeData(
          color: colorScheme.onSurfaceVariant,
          size: 24,
        ),
        selectedIconTheme: IconThemeData(
          color: SharePerksColors.primary,
          size: 24,
        ),
        selectedLabelStyle: textTheme.bodyMedium?.copyWith(
          color: SharePerksColors.primary,
          fontSize: 10,
        ),
        unselectedLabelStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontSize: 10,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outline.withValues(alpha: 0.6),
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        labelStyle: textTheme.bodyMedium!,
        padding: const EdgeInsets.symmetric(horizontal: SharePerksSpacing.sm),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SharePerksRadii.sm),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isLight
            ? SharePerksColors.textPrimaryLight
            : SharePerksColors.surfaceDark,
        contentTextStyle: textTheme.bodyLarge?.copyWith(color: Colors.white),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isLight
            ? SharePerksColors.backgroundLight
            : SharePerksColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SharePerksRadii.xl),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        borderRadius: BorderRadius.circular(SharePerksRadii.md),
        strokeCap: StrokeCap.round,
        color: colorScheme.primary,
        linearTrackColor: colorScheme.primary.withValues(alpha: 0.12),
        circularTrackColor: colorScheme.primary.withValues(alpha: 0.12),
        linearMinHeight: 4,
        strokeAlign: BorderSide.strokeAlignInside,
        trackGap: 4,
        refreshBackgroundColor: isLight
            ? SharePerksColors.surfaceLight
            : SharePerksColors.surfaceDark,
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: scaffoldBackground,
      ),
    );
  }
}
