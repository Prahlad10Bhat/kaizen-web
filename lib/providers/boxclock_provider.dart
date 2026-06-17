import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'settings_provider.dart';

enum GoalCategory {
  health('Health', Icons.favorite),
  career('Career', Icons.work),
  learning('Learning', Icons.school),
  personal('Personal', Icons.person);

  final String label;
  final IconData icon;
  const GoalCategory(this.label, this.icon);
}

enum BoxClockViewType { date, age }
enum BoxClockUnit { days, weeks }

class LifeGoal {
  final String id;
  final String name;
  final Color color;
  final GoalCategory category;
  final DateTime? _startDate;
  final DateTime? _endDate;

  DateTime get startDate => _startDate ?? DateTime.now();
  DateTime get endDate => _endDate ?? DateTime.now().add(const Duration(days: 30));

  LifeGoal({
    required this.id,
    required this.name,
    required this.color,
    required this.category,
    DateTime? startDate,
    DateTime? endDate,
  }) : _startDate = startDate,
       _endDate = endDate;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'color': color.value,
    'category': category.name,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
  };

  factory LifeGoal.fromJson(Map<String, dynamic> json) {
    return LifeGoal(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Untitled Goal',
      color: json['color'] != null ? Color(json['color']) : const Color(0xFF6C63FF),
      category: json['category'] != null 
        ? GoalCategory.values.firstWhere((c) => c.name == json['category'], orElse: () => GoalCategory.learning)
        : GoalCategory.learning,
      startDate: json['startDate'] != null ? DateTime.tryParse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.tryParse(json['endDate']) : null,
    );
  }
}

class WeekScore {
  final int weekIndex;
  final int score;
  final List<String> goalIds;
  final String note;
  final DateTime timestamp;

  WeekScore({
    required this.weekIndex,
    required this.score,
    required this.goalIds,
    required this.note,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'weekIndex': weekIndex,
    'score': score,
    'goalIds': goalIds,
    'note': note,
    'timestamp': timestamp.toIso8601String(),
  };

  factory WeekScore.fromJson(Map<String, dynamic> json) => WeekScore(
    weekIndex: json['weekIndex'],
    score: json['score'],
    goalIds: List<String>.from(json['goalIds']),
    note: json['note'],
    timestamp: DateTime.parse(json['timestamp']),
  );
}

class BoxClockData {
  final DateTime startDate;
  final DateTime endDate;
  final List<LifeGoal> goals;
  final List<WeekScore> scores;
  final BoxClockViewType? _viewType;
  final BoxClockUnit? _unit;

  BoxClockViewType get viewType => _viewType ?? BoxClockViewType.date;
  BoxClockUnit get unit => _unit ?? BoxClockUnit.weeks;

  BoxClockData({
    required this.startDate,
    required this.endDate,
    required this.goals,
    required this.scores,
    BoxClockViewType? viewType,
    BoxClockUnit? unit,
  }) : _viewType = viewType,
       _unit = unit;

  BoxClockData copyWith({
    DateTime? startDate,
    DateTime? endDate,
    List<LifeGoal>? goals,
    List<WeekScore>? scores,
    BoxClockViewType? viewType,
    BoxClockUnit? unit,
  }) {
    return BoxClockData(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      goals: goals ?? this.goals,
      scores: scores ?? this.scores,
      viewType: viewType ?? this.viewType,
      unit: unit ?? this.unit,
    );
  }

  Map<String, dynamic> toJson() => {
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'goals': goals.map((g) => g.toJson()).toList(),
    'scores': scores.map((s) => s.toJson()).toList(),
    'viewType': viewType.name,
    'unit': unit.name,
  };

  factory BoxClockData.fromJson(Map<String, dynamic> json) {
    return BoxClockData(
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : DateTime.now(),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : DateTime.now().add(const Duration(days: 365)),
      goals: (json['goals'] as List?)?.map((g) => LifeGoal.fromJson(g)).toList() ?? [],
      scores: (json['scores'] as List?)?.map((s) => WeekScore.fromJson(s)).toList() ?? [],
      viewType: BoxClockViewType.values.firstWhere(
        (v) => v.name == json['viewType'], 
        orElse: () => BoxClockViewType.date,
      ),
      unit: BoxClockUnit.values.firstWhere(
        (v) => v.name == json['unit'],
        orElse: () => BoxClockUnit.weeks,
      ),
    );
  }
}

class BoxClockNotifier extends Notifier<BoxClockData> {
  static const _storageKey = 'boxclock_data';

  @override
  BoxClockData build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final jsonStr = prefs.getString(_storageKey);
    
    if (jsonStr != null) {
      try {
        return BoxClockData.fromJson(jsonDecode(jsonStr));
      } catch (e) {
        debugPrint('Error loading BoxClock data: $e');
      }
    }
    
    final now = DateTime.now();
    return BoxClockData(
      startDate: DateTime(now.year, 1, 1),
      endDate: DateTime(now.year, 12, 31),
      goals: [],
      scores: [],
      viewType: BoxClockViewType.date,
      unit: BoxClockUnit.weeks,
    );
  }

  void _saveData() {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      prefs.setString(_storageKey, jsonEncode(state.toJson()));
    } catch (e) {
      debugPrint('Error saving BoxClock data: $e');
    }
  }

  void addGoal(LifeGoal goal) {
    state = state.copyWith(goals: [...state.goals, goal]);
    _saveData();
  }

  void deleteGoal(String id) {
    state = state.copyWith(goals: state.goals.where((g) => g.id != id).toList());
    _saveData();
  }

  void updateScore(WeekScore score) {
    final newScores = List<WeekScore>.from(state.scores);
    final existingIndex = newScores.indexWhere((s) => s.weekIndex == score.weekIndex);
    if (existingIndex != -1) {
      newScores[existingIndex] = score;
    } else {
      newScores.add(score);
    }
    state = state.copyWith(scores: newScores);
    _saveData();
  }

  void updateDates(DateTime start, DateTime end) {
    state = state.copyWith(startDate: start, endDate: end);
    _saveData();
  }

  void setViewType(BoxClockViewType type) {
    state = state.copyWith(viewType: type);
    _saveData();
  }

  void setUnit(BoxClockUnit unit) {
    state = state.copyWith(unit: unit);
    _saveData();
  }
}

final boxClockProvider = NotifierProvider<BoxClockNotifier, BoxClockData>(() => BoxClockNotifier());
