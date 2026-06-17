import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/calendar.dart';
import 'settings_provider.dart';

class CalendarNotifier extends Notifier<List<Calendar>> {
  static const _storageKey = 'kaizen_calendars';

  @override
  List<Calendar> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final jsonStr = prefs.getString(_storageKey);
    
    if (jsonStr != null) {
      try {
        final List<dynamic> jsonList = jsonDecode(jsonStr);
        var list = jsonList.map((j) => Calendar.fromJson(j)).toList();
        
        // Dynamically migrate "Default Tasks" name to "Tasks" and ensure proper isTaskCalendar values
        bool migrated = false;
        list = list.map((c) {
          if (c.id == 'default_tasks') {
            if (c.name == 'Default Tasks' || !c.isTaskCalendar) {
              migrated = true;
              return c.copyWith(name: 'Tasks', isTaskCalendar: true);
            }
          } else if (c.id == 'work_tasks') {
            if (!c.isTaskCalendar) {
              migrated = true;
              return c.copyWith(isTaskCalendar: true);
            }
          }
          return c;
        }).toList();

        if (migrated) {
          _saveCalendars(list);
        }

        if (list.isNotEmpty) {
          return list;
        }
      } catch (e) {
        // Fall back to seeding
      }
    }
    
    // Seed default calendars matching img1
    final seeded = [
      const Calendar(
        id: 'default_tasks',
        name: 'Tasks',
        colorValue: 0xFF6C63FF, // Accent blue-purple
        isTaskCalendar: true,
        isVisible: true,
      ),
    ];
    
    // Save asynchronously to prevent synchronous state modification issues in Riverpod build
    Future.microtask(() => _saveCalendars(seeded));
    return seeded;
  }

  void _saveCalendars(List<Calendar> list) {
    final prefs = ref.read(sharedPreferencesProvider);
    final jsonStr = jsonEncode(list.map((c) => c.toJson()).toList());
    prefs.setString(_storageKey, jsonStr);
  }

  void addCalendar(Calendar calendar) {
    state = [...state, calendar];
    _saveCalendars(state);
  }

  void updateCalendar(Calendar updatedCalendar) {
    state = [
      for (final calendar in state)
        if (calendar.id == updatedCalendar.id) updatedCalendar else calendar
    ];
    _saveCalendars(state);
  }

  void toggleVisibility(String calendarId) {
    state = [
      for (final calendar in state)
        if (calendar.id == calendarId) calendar.copyWith(isVisible: !calendar.isVisible) else calendar
    ];
    _saveCalendars(state);
  }

  void deleteCalendar(String calendarId) {
    // Never allow deleting the primary default calendar
    if (calendarId == 'default_tasks') return;
    
    state = state.where((calendar) => calendar.id != calendarId).toList();
    _saveCalendars(state);
  }
}

final calendarProvider = NotifierProvider<CalendarNotifier, List<Calendar>>(() {
  return CalendarNotifier();
});

class ActiveCalendarNotifier extends Notifier<String> {
  @override
  String build() => 'default_tasks';

  set state(String value) => super.state = value;
}

final activeCalendarProvider = NotifierProvider<ActiveCalendarNotifier, String>(() {
  return ActiveCalendarNotifier();
});
