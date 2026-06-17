import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'settings_provider.dart';

class RecentCommandsNotifier extends Notifier<List<String>> {
  static const _storageKey = 'kaizen_recent_commands';

  @override
  List<String> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final jsonStr = prefs.getString(_storageKey);
    if (jsonStr != null) {
      try {
        final List<dynamic> jsonList = jsonDecode(jsonStr);
        return jsonList.cast<String>();
      } catch (e) {
        return [];
      }
    }
    return [];
  }

  void addCommand(String commandId) {
    var newState = state.where((id) => id != commandId).toList();
    newState.insert(0, commandId);
    if (newState.length > 5) newState = newState.take(5).toList();
    state = newState;
    
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.setString(_storageKey, jsonEncode(state));
  }
}

final recentCommandsProvider = NotifierProvider<RecentCommandsNotifier, List<String>>(() {
  return RecentCommandsNotifier();
});
