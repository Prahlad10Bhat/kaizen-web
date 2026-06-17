import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/tracked_app.dart';

class AppTrackerState {
  final List<TrackedApp> apps;
  final bool isTrackingEnabled;
  final String? activeAppId;
  final String? lastDetectedWindowTitle;
  final DateTime? currentSessionStartTime;
  final Map<String, String?> discoveredApps;

  AppTrackerState({
    required this.apps,
    this.isTrackingEnabled = false,
    this.activeAppId,
    this.lastDetectedWindowTitle,
    this.currentSessionStartTime,
    this.discoveredApps = const {},
  });

  AppTrackerState copyWith({
    List<TrackedApp>? apps,
    bool? isTrackingEnabled,
    String? activeAppId,
    String? lastDetectedWindowTitle,
    DateTime? currentSessionStartTime,
    Map<String, String?>? discoveredApps,
    bool clearActiveApp = false,
  }) {
    return AppTrackerState(
      apps: apps ?? this.apps,
      isTrackingEnabled: isTrackingEnabled ?? this.isTrackingEnabled,
      activeAppId: clearActiveApp ? null : (activeAppId ?? this.activeAppId),
      lastDetectedWindowTitle:
          lastDetectedWindowTitle ?? this.lastDetectedWindowTitle,
      currentSessionStartTime: clearActiveApp
          ? null
          : (currentSessionStartTime ?? this.currentSessionStartTime),
      discoveredApps: discoveredApps ?? this.discoveredApps,
    );
  }
}

class AppTrackerNotifier extends Notifier<AppTrackerState> {
  static const _prefsKey = 'kaizen_tracked_apps_v2';
  static const _enabledKey = 'kaizen_app_tracking_enabled';

  @override
  AppTrackerState build() {
    _loadFromPrefs();
    return AppTrackerState(apps: []);
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_prefsKey);
    final isEnabled = prefs.getBool(_enabledKey) ?? false;

    List<TrackedApp> loadedApps = [];
    if (jsonStr != null) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        for (var e in decoded) {
          try {
            loadedApps.add(TrackedApp.fromJson(e));
          } catch (_) {
            // Ignore corrupted entries
          }
        }
      } catch (e) {
        loadedApps = [];
      }
    }
    // Initialize with the saved tracking enabled state
    state = AppTrackerState(apps: loadedApps, isTrackingEnabled: isEnabled);
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(state.apps.map((e) => e.toJson()).toList());
    await prefs.setString(_prefsKey, encoded);
    await prefs.setBool(_enabledKey, state.isTrackingEnabled);
  }

  void toggleGlobalTracking() {
    if (state.isTrackingEnabled) {
      // Stopping tracking
      _finalizeCurrentSession();
      state = state.copyWith(isTrackingEnabled: false, clearActiveApp: true);
    } else {
      // Starting tracking
      state = state.copyWith(isTrackingEnabled: true);
    }
    _saveToPrefs();
  }

  void addApp(TrackedApp app) {
    state = state.copyWith(apps: [...state.apps, app]);
    _saveToPrefs();
  }

  void updateApp(TrackedApp app) {
    state = state.copyWith(
      apps: state.apps.map((e) => e.id == app.id ? app : e).toList(),
    );
    _saveToPrefs();
  }

  void removeApp(String id) {
    if (state.activeAppId == id) {
      _finalizeCurrentSession();
      state = state.copyWith(clearActiveApp: true);
    }
    state = state.copyWith(apps: state.apps.where((e) => e.id != id).toList());
    _saveToPrefs();
  }

  void _finalizeCurrentSession() {
    if (state.activeAppId == null || state.currentSessionStartTime == null)
      return;

    final endTime = DateTime.now();
    final duration = endTime.difference(state.currentSessionStartTime!);

    if (duration.inSeconds > 0) {
      final newApps = state.apps.map((app) {
        if (app.id == state.activeAppId) {
          return app.copyWith(
            sessions: [
              ...app.sessions,
              AppSession(
                startTime: state.currentSessionStartTime!,
                endTime: endTime,
              ),
            ],
            // Update legacy counter just in case
            durationSeconds: app.durationSeconds + duration.inSeconds,
          );
        }
        return app;
      }).toList();
      state = state.copyWith(apps: newApps);
    }
  }

  void autoDetectAndSetActiveApp({
    required String processName,
    required String windowTitle,
    required String processPath,
  }) {
    if (!state.isTrackingEnabled) {
      state = state.copyWith(lastDetectedWindowTitle: windowTitle);
      return;
    }

    final now = DateTime.now();

    // Find matching app by process name keyword
    final lowerProcess = processName.toLowerCase();
    TrackedApp? matchedApp;

    for (final app in state.apps) {
      if (app.keyword.isNotEmpty && lowerProcess == app.keyword.toLowerCase()) {
        matchedApp = app;
        // Check if we need to update processPath
        if (matchedApp.processPath == null && processPath.isNotEmpty) {
          matchedApp = matchedApp.copyWith(processPath: processPath);
          updateApp(matchedApp);
        }
        break;
      }
    }

    // If no app found, add to discoveredApps!
    if (matchedApp == null && processName.isNotEmpty) {
      if (!state.discoveredApps.containsKey(processName) ||
          state.discoveredApps[processName] != processPath) {
        final newDiscovered = Map<String, String?>.from(state.discoveredApps);
        newDiscovered[processName] = processPath.isNotEmpty
            ? processPath
            : null;

        // Optional: limit the size of discoveredApps to avoid memory leak
        if (newDiscovered.length > 50) {
          final firstKey = newDiscovered.keys.first;
          newDiscovered.remove(firstKey);
        }

        state = state.copyWith(discoveredApps: newDiscovered);
      }
    }

    final appId = matchedApp?.id;

    if (appId != state.activeAppId) {
      // App changed
      _finalizeCurrentSession();

      if (appId == null) {
        state = state.copyWith(
          clearActiveApp: true,
          lastDetectedWindowTitle: windowTitle,
        );
      } else {
        state = state.copyWith(
          activeAppId: appId,
          currentSessionStartTime: now,
          lastDetectedWindowTitle: windowTitle,
        );
      }
    } else {
      // Same app still active.
      if (appId != null) {
        state = state.copyWith(lastDetectedWindowTitle: windowTitle);
      } else {
        if (state.lastDetectedWindowTitle != windowTitle) {
          state = state.copyWith(lastDetectedWindowTitle: windowTitle);
        }
      }
    }

    // Periodically save to prefs
    if (now.second % 10 == 0) {
      _saveToPrefs();
    }
  }

  void setActiveAppAndIncrement(String? appId, {String? windowTitle}) {
    // Keep this for backward compatibility or remove it if not needed anywhere else
    if (appId == null) {
      _finalizeCurrentSession();
      state = state.copyWith(
        clearActiveApp: true,
        lastDetectedWindowTitle: windowTitle,
      );
    }
  }

  void addDiscoveredAppToTracking(
    String processName,
    String? processPath, {
    required String customName,
    required bool isProductive,
  }) {
    final matchedApp = TrackedApp(
      id: const Uuid().v4(),
      name: customName,
      keyword: processName,
      isProductive: isProductive,
      color: Colors.primaries[processName.hashCode % Colors.primaries.length],
      processPath: processPath,
    );

    // Remove from discovered
    final newDiscovered = Map<String, String?>.from(state.discoveredApps);
    newDiscovered.remove(processName);

    state = state.copyWith(
      apps: [...state.apps, matchedApp],
      discoveredApps: newDiscovered,
    );
    _saveToPrefs();
  }
}

final appTrackerProvider =
    NotifierProvider<AppTrackerNotifier, AppTrackerState>(() {
      return AppTrackerNotifier();
    });
