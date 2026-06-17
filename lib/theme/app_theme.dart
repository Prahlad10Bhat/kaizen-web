import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData createTheme(AppPalette palette, bool isDark) {
    final baseTextTheme = isDark 
      ? GoogleFonts.interTextTheme(ThemeData.dark().textTheme)
      : GoogleFonts.interTextTheme(ThemeData.light().textTheme);
    final soraTheme = GoogleFonts.soraTextTheme(baseTextTheme);

    final headingFont = GoogleFonts.sora;
    final bodyFont = GoogleFonts.inter;

    return (isDark ? ThemeData.dark() : ThemeData.light()).copyWith(
      scaffoldBackgroundColor: palette.background,
      cardColor: palette.surface,
      canvasColor: palette.background,
      dialogBackgroundColor: palette.surface,
      primaryColor: palette.accent,
      colorScheme: (isDark ? const ColorScheme.dark() : const ColorScheme.light()).copyWith(
        primary: palette.accent,
        onPrimary: isDark ? Colors.black : Colors.white,
        secondary: palette.accent,
        onSecondary: isDark ? Colors.black : Colors.white,
        surface: palette.surface,
        onSurface: palette.textPrimary,
        background: palette.background,
        onBackground: palette.textPrimary,
        error: palette.highPriority,
        onError: Colors.white,
        outline: palette.borderSubtle,
      ),
      dividerColor: palette.borderSubtle,
      appBarTheme: AppBarTheme(
        backgroundColor: palette.background,
        elevation: 0,
        titleTextStyle: headingFont(
          color: palette.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: palette.textPrimary),
      ),
      textTheme: soraTheme.copyWith(
        displayLarge: headingFont(color: palette.textPrimary, fontWeight: FontWeight.bold),
        displayMedium: headingFont(color: palette.textPrimary, fontWeight: FontWeight.bold),
        headlineLarge: headingFont(color: palette.textPrimary, fontWeight: FontWeight.bold),
        headlineMedium: headingFont(color: palette.textPrimary, fontWeight: FontWeight.bold),
        titleLarge: headingFont(color: palette.textPrimary, fontWeight: FontWeight.w600, fontSize: null),
        titleMedium: headingFont(color: palette.textPrimary, fontWeight: FontWeight.w600, fontSize: null),
        bodyLarge: bodyFont(color: palette.textPrimary, fontSize: null),
        bodyMedium: bodyFont(color: palette.textPrimary, fontSize: null),
        bodySmall: bodyFont(color: palette.textMuted, fontSize: null),
        labelLarge: bodyFont(color: palette.textSecondary, fontSize: null),
      ).apply(
        bodyColor: palette.textPrimary,
        displayColor: palette.textPrimary,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: palette.background,
        unselectedIconTheme: IconThemeData(color: palette.textSecondary),
        selectedIconTheme: IconThemeData(color: palette.accent),
        unselectedLabelTextStyle: TextStyle(color: palette.textSecondary),
        selectedLabelTextStyle: TextStyle(color: palette.accent, fontWeight: FontWeight.bold),
      ),
      cardTheme: CardThemeData(
        color: palette.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide.none,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: palette.borderSubtle,
        thickness: 1,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          animationDuration: const Duration(milliseconds: 150),
          elevation: WidgetStateProperty.resolveWith<double>((states) {
            if (states.contains(WidgetState.hovered)) return 2;
            return 0;
          }),
          backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.disabled)) return palette.borderSubtle;
            if (states.contains(WidgetState.hovered)) return palette.accent.withValues(alpha: 0.9);
            return palette.accent;
          }),
          foregroundColor: WidgetStateProperty.all(Colors.white),
          textStyle: WidgetStateProperty.all(
            GoogleFonts.inter(fontWeight: FontWeight.w600, decoration: TextDecoration.none),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide.none,
            ),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          animationDuration: const Duration(milliseconds: 150),
          backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.hovered)) return palette.accent.withValues(alpha: 0.05);
            return Colors.transparent;
          }),
          side: WidgetStateProperty.resolveWith<BorderSide>((states) {
            if (states.contains(WidgetState.hovered)) return BorderSide(color: palette.accent);
            return BorderSide(color: palette.borderSubtle);
          }),
          foregroundColor: WidgetStateProperty.all(palette.textPrimary),
          textStyle: WidgetStateProperty.all(
            GoogleFonts.inter(fontWeight: FontWeight.w500, decoration: TextDecoration.none),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          animationDuration: const Duration(milliseconds: 150),
          backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.hovered)) return isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05);
            return Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.all(palette.textPrimary),
          textStyle: WidgetStateProperty.all(
            GoogleFonts.inter(fontWeight: FontWeight.w500, decoration: TextDecoration.none),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide.none,
            ),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide.none,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        side: null,
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return palette.accent;
          }
          return null;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: const Color(0xFF252525),
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: GoogleFonts.inter(
          color: const Color(0xFFE0E0E0),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      extensions: [
        AppColorsExtension.fromPalette(palette),
      ],
    );
  }

  static ThemeData get darkTheme => createTheme(AppPalette.dark, true);
  static ThemeData get lightTheme => createTheme(AppPalette.light, false);
  static ThemeData get cherryBlossomTheme => createTheme(AppPalette.cherryBlossom, false);
  static ThemeData get coffeeTheme => createTheme(AppPalette.coffee, true);
  static ThemeData get emberTheme => createTheme(AppPalette.ember, true);
  static ThemeData get ivoryTheme => createTheme(AppPalette.ivory, false);
  static ThemeData get ashTheme => createTheme(AppPalette.ash, false);
  static ThemeData get plushTheme => createTheme(AppPalette.plush, false);
}
