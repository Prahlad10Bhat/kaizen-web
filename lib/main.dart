import 'dart:io';

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:window_manager/window_manager.dart';
import 'package:local_notifier/local_notifier.dart';

import 'layout/app_layout.dart';
import 'providers/settings_provider.dart';
import 'theme/app_theme.dart';
import 'package:flutter/services.dart';
import 'layout/command_palette.dart';
import 'providers/navigation_provider.dart';
import 'services/theme_icon_service.dart';

class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://eorgurskwosstujvlxez.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVvcmd1cnNrd29zc3R1anZseGV6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg2MDIyNDksImV4cCI6MjA5NDE3ODI0OX0.Q3AnnBrB9O_cDEReQqQGJC-toxDiziMsCzudrzuCvOM',
  );

  final prefs = await SharedPreferences.getInstance();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();
    await localNotifier.setup(appName: 'Kaizen');

    const windowOptions = WindowOptions(
      size: Size(1400, 900),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.setPreventClose(true);
      await windowManager.show();
      await windowManager.focus();
      await windowManager.maximize();
      // Determine if this is a new install or existing user
      bool isNewInstall = false;
      if (!prefs.containsKey('app_installed_flag')) {
        final hasExistingData = prefs.getKeys().any((k) => 
          k.startsWith('settings_') || 
          k.startsWith('kaizen_') || 
          k == 'app_tour_completed' || 
          k == 'changelog_last_version'
        );
        isNewInstall = !hasExistingData;
      }
      final defaultThemeIndex = isNewInstall ? AppThemeMode.system.index : AppThemeMode.dark.index;
      final themeIndex = prefs.getInt('settings_theme') ?? defaultThemeIndex;
      final initialThemeMode = AppThemeMode.values[themeIndex];
      await ThemeIconService.restoreIconOnStartup(initialThemeMode);
    });
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final currentTheme = _getTheme(settings.themeMode);

    // Dynamic Taskbar Icon Update
    ref.listen(settingsProvider, (previous, next) {
      if (previous?.themeMode != next.themeMode) {
        ThemeIconService.updateIconForTheme(next.themeMode);
      }
    });

    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyF): const SearchIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          SearchIntent: CallbackAction<SearchIntent>(
            onInvoke: (SearchIntent intent) {
              final scaffoldContext = ref.read(scaffoldKeyProvider).currentContext;
              if (scaffoldContext != null) {
                CommandPalette.show(scaffoldContext);
              }
              return null;
            },
          ),
        },
        child: MaterialApp(
          title: 'KAIZEN',
          debugShowCheckedModeBanner: false,
          scrollBehavior: AppScrollBehavior(),
          theme: currentTheme,
          darkTheme: settings.themeMode == AppThemeMode.system
              ? AppTheme.darkTheme
              : currentTheme,
          themeMode: _getThemeMode(settings.themeMode),
          home: const AppLayout(),
        ),
      ),
    );
  }



  ThemeData _getTheme(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return AppTheme.lightTheme;
      case AppThemeMode.dark:
        return AppTheme.darkTheme;
      case AppThemeMode.cherryBlossom:
        return AppTheme.cherryBlossomTheme;
      case AppThemeMode.coffee:
        return AppTheme.coffeeTheme;
      case AppThemeMode.ember:
        return AppTheme.emberTheme;
      case AppThemeMode.ivory:
        return AppTheme.ivoryTheme;
      case AppThemeMode.ash:
        return AppTheme.ashTheme;
      case AppThemeMode.plush:
        return AppTheme.plushTheme;
      case AppThemeMode.system:
        return AppTheme.lightTheme;
    }
  }

  ThemeMode _getThemeMode(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.cherryBlossom:
        return ThemeMode.light;
      case AppThemeMode.coffee:
        return ThemeMode.dark;
      case AppThemeMode.ember:
        return ThemeMode.dark;
      case AppThemeMode.ivory:
        return ThemeMode.light;
      case AppThemeMode.ash:
        return ThemeMode.light;
      case AppThemeMode.plush:
        return ThemeMode.light;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }
}
