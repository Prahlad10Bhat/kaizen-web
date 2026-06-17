import 'package:flutter/material.dart';

enum TaskPriority { high, medium, low }

enum TaskStatus { todo, inProgress, done }

class Task {
  final String id;
  final String title;
  final String? description;
  final TaskStatus status;
  final TaskPriority priority;
  final List<String> tags;
  final List<String> assignees; // using avatar URLs
  final DateTime? dueDate;
  final int commentsCount;
  final int attachmentsCount;
  final String? calendarId;
  final bool isRecurring;

  const Task({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    required this.priority,
    this.tags = const [],
    this.assignees = const [],
    this.dueDate,
    this.commentsCount = 0,
    this.attachmentsCount = 0,
    this.calendarId,
    this.isRecurring = false,
  });

  Task copyWith({
    String? id,
    String? title,
    String? description,
    TaskStatus? status,
    TaskPriority? priority,
    List<String>? tags,
    List<String>? assignees,
    DateTime? dueDate,
    int? commentsCount,
    int? attachmentsCount,
    String? calendarId,
    bool? isRecurring,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      tags: tags ?? this.tags,
      assignees: assignees ?? this.assignees,
      dueDate: dueDate ?? this.dueDate,
      commentsCount: commentsCount ?? this.commentsCount,
      attachmentsCount: attachmentsCount ?? this.attachmentsCount,
      calendarId: calendarId ?? this.calendarId,
      isRecurring: isRecurring ?? this.isRecurring,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'status': status.name,
    'priority': priority.name,
    'tags': tags,
    'assignees': assignees,
    'dueDate': dueDate?.toIso8601String(),
    'commentsCount': commentsCount,
    'attachmentsCount': attachmentsCount,
    'calendarId': calendarId,
    'isRecurring': isRecurring,
  };

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      status: TaskStatus.values.firstWhere((e) => e.name == json['status'], orElse: () => TaskStatus.todo),
      priority: TaskPriority.values.firstWhere((e) => e.name == json['priority'], orElse: () => TaskPriority.medium),
      tags: List<String>.from(json['tags'] ?? []),
      assignees: List<String>.from(json['assignees'] ?? []),
      dueDate: json['dueDate'] != null ? DateTime.tryParse(json['dueDate']) : null,
      commentsCount: json['commentsCount'] ?? 0,
      attachmentsCount: json['attachmentsCount'] ?? 0,
      calendarId: json['calendarId'],
      isRecurring: json['isRecurring'] ?? false,
    );
  }
}
