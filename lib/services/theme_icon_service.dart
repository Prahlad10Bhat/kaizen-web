import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:window_manager/window_manager.dart';
import '../providers/settings_provider.dart';

class ThemeIconService {
  /// Updates the taskbar, window title bar, and Alt+Tab icons to match the given theme.
  /// This requires the corresponding .ico files to be present in the assets directory.
  static Future<void> updateIconForTheme(AppThemeMode mode) async {
    // Icon switching is primarily supported on desktop platforms
    if (!(Platform.isWindows || Platform.isLinux || Platform.isMacOS)) return;

    String iconPath = 'assets/logo_dark.ico';
    switch (mode) {
      case AppThemeMode.light:
        // Light Theme -> use light icon variant
        iconPath = 'assets/logo_light.ico';
        break;
      case AppThemeMode.dark:
        // Dark Theme -> use dark icon variant
        iconPath = 'assets/logo_dark.ico';
        break;
      case AppThemeMode.cherryBlossom:
        iconPath = 'assets/logo_cherry.ico';
        break;
      case AppThemeMode.coffee:
        iconPath = 'assets/logo_coffee.ico';
        break;
      case AppThemeMode.ember:
        iconPath = 'assets/logo_ember.ico';
        break;
      case AppThemeMode.ivory:
        iconPath = 'assets/logo_ivory.ico';
        break;
      case AppThemeMode.ash:
        iconPath = 'assets/logo_ash.ico';
        break;
      case AppThemeMode.plush:
        iconPath = 'assets/logo_plush.ico';
        break;
      case AppThemeMode.system:
        iconPath = 'assets/logo_dark.ico';
        break;
    }

    try {
      // Create the absolute path to the icon file inside the flutter_assets directory
      String executableDir = p.dirname(Platform.resolvedExecutable);
      String absolutePath = p.join(executableDir, 'data', 'flutter_assets', iconPath);
      
      // Fallback to project root if running from IDE and flutter_assets doesn't have it
      if (!File(absolutePath).existsSync()) {
        absolutePath = p.join(Directory.current.path, iconPath);
      }

      await windowManager.setIcon(absolutePath);
      debugPrint('Successfully set icon to: $absolutePath');
    } catch (e) {
      debugPrint('Failed to set taskbar icon: $e');
    }
  }

  /// Restores the correct icon on app startup based on the initial theme
  static Future<void> restoreIconOnStartup(AppThemeMode mode) async {
    await updateIconForTheme(mode);
  }
}
