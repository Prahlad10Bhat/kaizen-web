import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import 'settings_provider.dart';

class TaskNotifier extends Notifier<List<Task>> {
  static const _storageKey = 'kaizen_tasks';

  @override
  List<Task> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final jsonStr = prefs.getString(_storageKey);
    
    if (jsonStr != null) {
      try {
        final List<dynamic> jsonList = jsonDecode(jsonStr);
        return jsonList.map((j) => Task.fromJson(j)).toList();
      } catch (e) {
        return [];
      }
    }
    return [];
  }

  void _saveTasks() {
    final prefs = ref.read(sharedPreferencesProvider);
    final jsonStr = jsonEncode(state.map((t) => t.toJson()).toList());
    prefs.setString(_storageKey, jsonStr);
  }

  void updateTaskStatus(String taskId, TaskStatus newStatus) {
    state = [
      for (final task in state)
        if (task.id == taskId) task.copyWith(status: newStatus) else task
    ];
    _saveTasks();
  }

  void addTask(Task task) {
    state = [...state, task];
    _saveTasks();
  }

  void addTasks(List<Task> tasks) {
    state = [...state, ...tasks];
    _saveTasks();
  }
  
  void removeTask(String taskId) {
    state = state.where((task) => task.id != taskId).toList();
    _saveTasks();
  }

  void removeTasksByCalendarId(String calendarId) {
    state = state.where((task) => task.calendarId != calendarId).toList();
    _saveTasks();
  }

  void updateTask(Task updatedTask) {
    state = [
      for (final task in state)
        if (task.id == updatedTask.id) updatedTask else task
    ];
    _saveTasks();
  }
}

final taskProvider = NotifierProvider<TaskNotifier, List<Task>>(() {
  return TaskNotifier();
});

// Initial data
final _initialTasks = <Task>[];
