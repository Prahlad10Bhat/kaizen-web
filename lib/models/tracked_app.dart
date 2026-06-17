import 'dart:convert';
import 'package:flutter/material.dart';

class AppSession {
  final DateTime startTime;
  final DateTime endTime;

  AppSession({
    required this.startTime,
    required this.endTime,
  });

  Duration get duration => endTime.difference(startTime);

  Map<String, dynamic> toJson() {
    return {
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
    };
  }

  factory AppSession.fromJson(Map<String, dynamic> json) {
    return AppSession(
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
    );
  }
}

class TrackedApp {
  final String id;
  final String name;
  final String keyword;
  final int durationSeconds; // Legacy
  final List<AppSession> sessions;
  final bool isProductive;
  final Color color;
  final String? processPath;

  TrackedApp({
    required this.id,
    required this.name,
    required this.keyword,
    this.durationSeconds = 0,
    this.sessions = const [],
    this.isProductive = true,
    required this.color,
    this.processPath,
  });

  int get totalDurationSeconds {
    int total = durationSeconds; // Legacy counter
    for (var session in sessions) {
      total += session.duration.inSeconds;
    }
    return total;
  }

  int getTodayDurationSeconds() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    
    int total = 0;
    for (var session in sessions) {
      if (session.endTime.isBefore(startOfDay)) continue;
      
      DateTime visibleStart = session.startTime.isBefore(startOfDay) ? startOfDay : session.startTime;
      total += session.endTime.difference(visibleStart).inSeconds;
    }
    return total;
  }

  TrackedApp copyWith({
    String? id,
    String? name,
    String? keyword,
    int? durationSeconds,
    List<AppSession>? sessions,
    bool? isProductive,
    Color? color,
    String? processPath,
  }) {
    return TrackedApp(
      id: id ?? this.id,
      name: name ?? this.name,
      keyword: keyword ?? this.keyword,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      sessions: sessions ?? this.sessions,
      isProductive: isProductive ?? this.isProductive,
      color: color ?? this.color,
      processPath: processPath ?? this.processPath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'keyword': keyword,
      'durationSeconds': durationSeconds,
      'sessions': sessions.map((s) => s.toJson()).toList(),
      'isProductive': isProductive,
      'color': color.value,
      'processPath': processPath,
    };
  }

  factory TrackedApp.fromJson(Map<String, dynamic> json) {
    return TrackedApp(
      id: json['id'],
      name: json['name'],
      keyword: json['keyword'],
      durationSeconds: json['durationSeconds'] ?? 0,
      sessions: (json['sessions'] as List<dynamic>?)
              ?.map((e) => AppSession.fromJson(e))
              .toList() ??
          [],
      isProductive: json['isProductive'] ?? true,
      color: Color(json['color']),
      processPath: json['processPath'],
    );
  }
}
