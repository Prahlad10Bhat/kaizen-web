import 'package:flutter/material.dart';

class Calendar {
  final String id;
  final String name;
  final int colorValue; // 32-bit ARGB color value
  final bool isTaskCalendar; // true if it acts as a task list, false for pure events
  final bool isVisible; // true if events are shown in main calendar views

  const Calendar({
    required this.id,
    required this.name,
    required this.colorValue,
    this.isTaskCalendar = true,
    this.isVisible = true,
  });

  Color get color => Color(colorValue);

  String get abbreviation {
    if (name.isEmpty) return '';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      final word = parts[0];
      if (word.length <= 4) {
        return word; // Keep short words fully, e.g. "work" -> "work"
      } else {
        return word.substring(0, 1).toUpperCase(); // Long word -> first initial, e.g. "Barcelona" -> "B", "Tasks" -> "T"
      }
    } else {
      // Multiple words -> initials of each word, e.g. "Personal Calendar" -> "PC"
      return parts.map((p) => p.isNotEmpty ? p[0].toUpperCase() : '').join('');
    }
  }

  Calendar copyWith({
    String? id,
    String? name,
    int? colorValue,
    bool? isTaskCalendar,
    bool? isVisible,
  }) {
    return Calendar(
      id: id ?? this.id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      isTaskCalendar: isTaskCalendar ?? this.isTaskCalendar,
      isVisible: isVisible ?? this.isVisible,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'colorValue': colorValue,
    'isTaskCalendar': isTaskCalendar,
    'isVisible': isVisible,
  };

  factory Calendar.fromJson(Map<String, dynamic> json) {
    return Calendar(
      id: json['id'] as String,
      name: json['name'] as String,
      colorValue: json['colorValue'] as int,
      isTaskCalendar: (json['isTaskCalendar'] ?? true) as bool,
      isVisible: (json['isVisible'] ?? true) as bool,
    );
  }
}
