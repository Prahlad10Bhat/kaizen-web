import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode {
  light,
  dark,
  cherryBlossom,
  coffee,
  ember,
  ivory,
  ash,
  plush,
  system;

  String get label {
    switch (this) {
      case AppThemeMode.light: return 'Light';
      case AppThemeMode.dark: return 'Dark';
      case AppThemeMode.cherryBlossom: return 'Cherry Blossom';
      case AppThemeMode.coffee: return 'Coffee';
      case AppThemeMode.ember: return 'Ember';
      case AppThemeMode.ivory: return 'Ivory';
      case AppThemeMode.ash: return 'Ash';
      case AppThemeMode.plush: return 'Plush';
      case AppThemeMode.system: return 'System Default';
    }
  }
}

class AppSettings {
  final AppThemeMode themeMode;
  final bool notificationsEnabled;
  final String language;
  final bool askBeforeDelete;
  final String? alarmAudioPath;
  final bool showTimer;

  AppSettings({
    this.themeMode = AppThemeMode.system,
    this.notificationsEnabled = true,
    this.language = 'English (US)',
    this.askBeforeDelete = true,
    this.alarmAudioPath,
    this.showTimer = true,
  });

  AppSettings copyWith({
    AppThemeMode? themeMode,
    bool? notificationsEnabled,
    String? language,
    bool? askBeforeDelete,
    String? alarmAudioPath,
    bool clearAlarmAudioPath = false,
    bool? showTimer,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      language: language ?? this.language,
      askBeforeDelete: askBeforeDelete ?? this.askBeforeDelete,
      alarmAudioPath: clearAlarmAudioPath ? null : (alarmAudioPath ?? this.alarmAudioPath),
      showTimer: showTimer ?? this.showTimer,
    );
  }
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

class SettingsNotifier extends Notifier<AppSettings> {
  static const _themeKey = 'settings_theme';
  static const _notificationsKey = 'settings_notifications';
  static const _languageKey = 'settings_language';
  static const _askBeforeDeleteKey = 'settings_ask_before_delete';
  static const _alarmAudioPathKey = 'settings_alarm_audio_path';
  static const _showTimerKey = 'settings_show_timer';

  @override
  AppSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    
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
      prefs.setBool('app_installed_flag', true);
    }

    final defaultThemeIndex = isNewInstall ? AppThemeMode.system.index : AppThemeMode.dark.index;
    final themeIndex = prefs.getInt(_themeKey) ?? defaultThemeIndex;
    final notifications = prefs.getBool(_notificationsKey) ?? true;
    final language = prefs.getString(_languageKey) ?? 'English (US)';
    final askBeforeDelete = prefs.getBool(_askBeforeDeleteKey) ?? true;
    final alarmAudioPath = prefs.getString(_alarmAudioPathKey);
    final showTimer = prefs.getBool(_showTimerKey) ?? true;

    return AppSettings(
      themeMode: AppThemeMode.values[themeIndex],
      notificationsEnabled: notifications,
      language: language,
      askBeforeDelete: askBeforeDelete,
      alarmAudioPath: alarmAudioPath,
      showTimer: showTimer,
    );
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setInt(_themeKey, mode.index);
  }

  Future<void> setNotifications(bool enabled) async {
    state = state.copyWith(notificationsEnabled: enabled);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_notificationsKey, enabled);
  }

  Future<void> setLanguage(String lang) async {
    state = state.copyWith(language: lang);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_languageKey, lang);
  }

  Future<void> setAskBeforeDelete(bool ask) async {
    state = state.copyWith(askBeforeDelete: ask);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_askBeforeDeleteKey, ask);
  }

  Future<void> setAlarmAudioPath(String? path) async {
    final prefs = ref.read(sharedPreferencesProvider);
    if (path == null) {
      state = state.copyWith(clearAlarmAudioPath: true);
      await prefs.remove(_alarmAudioPathKey);
    } else {
      state = state.copyWith(alarmAudioPath: path);
      await prefs.setString(_alarmAudioPathKey, path);
    }
  }

  Future<void> setShowTimer(bool show) async {
    state = state.copyWith(showTimer: show);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_showTimerKey, show);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(() => SettingsNotifier());
