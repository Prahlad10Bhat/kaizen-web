import 'package:flutter/material.dart';

class AppPalette {
  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color accent;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color border;
  final Color borderSubtle;
  final Color highPriority;
  final Color mediumPriority;
  final Color lowPriority;
  
  // Calendar Specific
  final Color calendarAccent;
  final Color calendarSurface;
  final Color calendarGrid;

  const AppPalette({
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.accent,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.border,
    required this.borderSubtle,
    required this.highPriority,
    required this.mediumPriority,
    required this.lowPriority,
    required this.calendarAccent,
    required this.calendarSurface,
    required this.calendarGrid,
  });

  static const dark = AppPalette(
    background: Color(0xFF0D0D0D),
    surface: Color(0xFF1A1A1A),
    surfaceElevated: Color(0xFF222222),
    accent: Color(0xFF6C63FF),
    textPrimary: Color(0xFFF0F0F0),
    textSecondary: Color(0xFFA0A0A0),
    textMuted: Color(0xFF6E6E6E),
    border: Color(0x1AFFFFFF),
    borderSubtle: Color(0x06FFFFFF),
    highPriority: Color(0xFFE57373),
    mediumPriority: Color(0xFFFFB74D),
    lowPriority: Color(0xFF81C784),
    calendarAccent: Color(0xFFFFFFFF),
    calendarSurface: Color(0xFF141814),
    calendarGrid: Color(0xFF1B201B),
  );

  static const light = AppPalette(
    background: Color(0xFFF8F9FA),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFE9ECEF),
    accent: Color(0xFF212529),
    textPrimary: Color(0xFF121212),
    textSecondary: Color(0xFF343A40),
    textMuted: Color(0xFF6C757D),
    border: Color(0x33000000),
    borderSubtle: Color(0x1F000000),
    highPriority: Color(0xFFD32F2F),
    mediumPriority: Color(0xFFF57C00),
    lowPriority: Color(0xFF388E3C),
    calendarAccent: Color(0xFF212529),
    calendarSurface: Color(0xFFFFFFFF),
    calendarGrid: Color(0xFFE9ECEF),
  );

  static const cherryBlossom = AppPalette(
    background: Color(0xFFFFE0E6),      // Darker light pink (was FFF0F3)
    surface: Color(0xFFFFF0F3),         // Very light pink (was FFFFFF)
    surfaceElevated: Color(0xFFFFD1DC), // Noticeably darker pink (was FFE5EC)
    accent: Color(0xFFFF4D6D),          // Darker, richer pink accent (was FF758F)
    textPrimary: Color(0xFF3B0918),     // Darker text (was 590D22)
    textSecondary: Color(0xFF590D22),   // Darker text (was 800F2F)
    textMuted: Color(0xFF800F2F),       // Darker text (was A4133C)
    border: Color(0x33FF4D6D),          // Stronger border
    borderSubtle: Color(0x1AFF4D6D),
    highPriority: Color(0xFFD32F2F),
    mediumPriority: Color(0xFFF57C00),
    lowPriority: Color(0xFF388E3C),
    calendarAccent: Color(0xFFFF4D6D),
    calendarSurface: Color(0xFFFFF0F3),
    calendarGrid: Color(0xFFFFD1DC),
  );

  static const coffee = AppPalette(
    background: Color(0xFF1B1714), // Dark espresso bean
    surface: Color(0xFF2B231F),    // Roasted coffee
    surfaceElevated: Color(0xFF382E29),
    accent: Color(0xFFB08968),     // Latte/Crema
    textPrimary: Color(0xFFEDE0D4), // Light cream
    textSecondary: Color(0xFFDDB892),
    textMuted: Color(0xFF7F5539),
    border: Color(0x1AEDE0D4),
    borderSubtle: Color(0x06EDE0D4),
    highPriority: Color(0xFFE57373),
    mediumPriority: Color(0xFFFFB74D),
    lowPriority: Color(0xFF81C784),
    calendarAccent: Color(0xFFB08968),
    calendarSurface: Color(0xFF2B231F),
    calendarGrid: Color(0xFF382E29),
  );

  static const ember = AppPalette(
    background: Color(0xFF1B1212),      // Deep Obsidian with a hint of dark ember
    surface: Color(0xFF2D1B1B),         // Burnt Sienna
    surfaceElevated: Color(0xFF3D2626),
    accent: Color(0xFFFF8C42),          // Golden Autumn Orange
    textPrimary: Color(0xFFFFF3E0),     // Soft Sunset Cream
    textSecondary: Color(0xFFE07A5F),   // Muted Terracotta
    textMuted: Color(0xFF8B4513),       // Saddle Brown
    border: Color(0x26FF8C42),
    borderSubtle: Color(0x08FF8C42),
    highPriority: Color(0xFFE57373),
    mediumPriority: Color(0xFFFFB74D),
    lowPriority: Color(0xFF81C784),
    calendarAccent: Color(0xFFFF8C42),
    calendarSurface: Color(0xFF2D1B1B),
    calendarGrid: Color(0xFF3D2626),
  );

  static const ivory = AppPalette(
    background: Color(0xFFE4E3DD),       // Warm beige/cream background
    surface: Color(0xFFFBFBFA),          // Clean white surface cards
    surfaceElevated: Color(0xFFEBEAE4),  // Elevated cream
    accent: Color(0xFF1E201F),           // Charcoal slate accent
    textPrimary: Color(0xFF1E201F),      // Dark slate primary text
    textSecondary: Color(0xFF535554),    // Muted slate secondary text
    textMuted: Color(0xFF868887),        // Subtle slate muted text
    border: Color(0x2B1E201F),           // Charcoal border
    borderSubtle: Color(0x1F1E201F),     // Subtle charcoal border line
    highPriority: Color(0xFFD2E224),     // Bright lime green/yellow
    mediumPriority: Color(0xFF1E201F),   // Dark slate
    lowPriority: Color(0xFF868887),      // Slate grey
    calendarAccent: Color(0xFF1E201F),   // Charcoal calendar highlights
    calendarSurface: Color(0xFFFBFBFA),  // White calendar surface
    calendarGrid: Color(0xFFEBEAE4),     // Cream grid lines
  );

  static const ash = AppPalette(
    background: Color(0xFFC9CCD0),       // Main grey background
    surface: Color(0xFFDCDFE3),          // Slightly lighter card/surface
    surfaceElevated: Color(0xFFE8EAEF),  // Even lighter
    accent: Color(0xFF222428),           // Dark charcoal
    textPrimary: Color(0xFF1E2024),      // Dark text
    textSecondary: Color(0xFF5A5E66),    // Gray text
    textMuted: Color(0xFF8B909A),
    border: Color(0x33222428),           // Dark border
    borderSubtle: Color(0x1F222428),
    highPriority: Color(0xFFD32F2F),
    mediumPriority: Color(0xFFF57C00),
    lowPriority: Color(0xFF388E3C),
    calendarAccent: Color(0xFF222428),
    calendarSurface: Color(0xFFDCDFE3),
    calendarGrid: Color(0xFFC9CCD0),
  );

  static const plush = AppPalette(
    background: Color(0xFFEBE5D9),       // Warm fuzzy beige
    surface: Color(0xFFF5EFE6),          // Off-white plush surface
    surfaceElevated: Color(0xFFFFFFFF),  // Pure white
    accent: Color(0xFF2E3A7B),           // Navy plush
    textPrimary: Color(0xFF1A1A1A),      // Black text
    textSecondary: Color(0xFF5A5A5A),    // Dark grey text
    textMuted: Color(0xFF8A8A8A),        // Muted grey
    border: Color(0x1A000000),           // Soft shadow-like border
    borderSubtle: Color(0x0A000000),     // Very soft shadow
    highPriority: Color(0xFFC73636),     // Plush Red
    mediumPriority: Color(0xFFDBA335),   // Plush Yellow
    lowPriority: Color(0xFF166D5E),      // Plush Teal
    calendarAccent: Color(0xFF2E3A7B),
    calendarSurface: Color(0xFFF5EFE6),
    calendarGrid: Color(0xFFEBE5D9),
  );
}

class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  final Color highPriority;
  final Color mediumPriority;
  final Color lowPriority;
  final Color calendarAccent;
  final Color calendarSurface;
  final Color calendarGrid;
  final Color borderSubtle;

  const AppColorsExtension({
    required this.highPriority,
    required this.mediumPriority,
    required this.lowPriority,
    required this.calendarAccent,
    required this.calendarSurface,
    required this.calendarGrid,
    required this.borderSubtle,
  });

  factory AppColorsExtension.fromPalette(AppPalette palette) {
    return AppColorsExtension(
      highPriority: palette.highPriority,
      mediumPriority: palette.mediumPriority,
      lowPriority: palette.lowPriority,
      calendarAccent: palette.calendarAccent,
      calendarSurface: palette.calendarSurface,
      calendarGrid: palette.calendarGrid,
      borderSubtle: palette.borderSubtle,
    );
  }

  @override
  ThemeExtension<AppColorsExtension> copyWith({
    Color? highPriority,
    Color? mediumPriority,
    Color? lowPriority,
    Color? calendarAccent,
    Color? calendarSurface,
    Color? calendarGrid,
    Color? borderSubtle,
  }) {
    return AppColorsExtension(
      highPriority: highPriority ?? this.highPriority,
      mediumPriority: mediumPriority ?? this.mediumPriority,
      lowPriority: lowPriority ?? this.lowPriority,
      calendarAccent: calendarAccent ?? this.calendarAccent,
      calendarSurface: calendarSurface ?? this.calendarSurface,
      calendarGrid: calendarGrid ?? this.calendarGrid,
      borderSubtle: borderSubtle ?? this.borderSubtle,
    );
  }

  @override
  ThemeExtension<AppColorsExtension> lerp(ThemeExtension<AppColorsExtension>? other, double t) {
    if (other is! AppColorsExtension) return this;
    return AppColorsExtension(
      highPriority: Color.lerp(highPriority, other.highPriority, t)!,
      mediumPriority: Color.lerp(mediumPriority, other.mediumPriority, t)!,
      lowPriority: Color.lerp(lowPriority, other.lowPriority, t)!,
      calendarAccent: Color.lerp(calendarAccent, other.calendarAccent, t)!,
      calendarSurface: Color.lerp(calendarSurface, other.calendarSurface, t)!,
      calendarGrid: Color.lerp(calendarGrid, other.calendarGrid, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
    );
  }
}

