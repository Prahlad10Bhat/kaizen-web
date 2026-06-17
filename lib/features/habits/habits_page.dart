import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'dart:convert';

import '../../theme/app_colors.dart';
import '../../providers/settings_provider.dart';

enum HabitStatus { none, completed, frozen }

class Habit {
  final String id;
  final String name;
  final String icon;
  final int streak;
  final Map<String, HabitStatus> history;
  final Color color;

  Habit({
    required this.id,
    required this.name,
    required this.icon,
    required this.streak,
    required this.history,
    required this.color,
  });

  Habit copyWith({
    String? id,
    String? name,
    String? icon,
    int? streak,
    Map<String, HabitStatus>? history,
    Color? color,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      streak: streak ?? this.streak,
      history: history ?? this.history,
      color: color ?? this.color,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'streak': streak,
      'history': history.map((key, value) => MapEntry(key, value.name)),
      'color': color.value,
    };
  }

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String,
      streak: json['streak'] as int? ?? 0,
      history: (json['history'] as Map<String, dynamic>? ?? {}).map(
        (key, value) => MapEntry(
          key,
          HabitStatus.values.firstWhere(
            (e) => e.name == value,
            orElse: () => HabitStatus.none,
          ),
        ),
      ),
      color: Color(json['color'] as int),
    );
  }
}

String _dateKey(DateTime date) => "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

bool _isConsecutiveFreeze(Habit habit, DateTime date) {
  final key = _dateKey(date);
  if (habit.history[key] != HabitStatus.frozen) return false;
  
  // Check day before
  final prevDate = date.subtract(const Duration(days: 1));
  final prevKey = _dateKey(prevDate);
  if (habit.history[prevKey] == HabitStatus.frozen) return true;
  
  // Check day after
  final nextDate = date.add(const Duration(days: 1));
  final nextKey = _dateKey(nextDate);
  if (habit.history[nextKey] == HabitStatus.frozen) return true;
  
  return false;
}

class HabitsNotifier extends Notifier<List<Habit>> {
  static const _storageKey = 'kaizen_habits';

  @override
  List<Habit> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final jsonStr = prefs.getString(_storageKey);
    if (jsonStr != null) {
      try {
        final List<dynamic> jsonList = jsonDecode(jsonStr);
        return jsonList.map((j) => Habit.fromJson(j)).toList();
      } catch (e) {
        return [];
      }
    }
    return [];
  }

  void _saveHabits() {
    final prefs = ref.read(sharedPreferencesProvider);
    final jsonStr = jsonEncode(state.map((h) => h.toJson()).toList());
    prefs.setString(_storageKey, jsonStr);
  }

  void addHabit(String name, String icon, Color color) {
    final newHabit = Habit(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      icon: icon,
      streak: 0,
      history: {},
      color: color,
    );
    state = [...state, newHabit];
    _saveHabits();
  }

  void deleteHabit(String id) {
    state = state.where((h) => h.id != id).toList();
    _saveHabits();
  }

  void toggleDay(String id, DateTime date) {
    if (!DateUtils.isSameDay(date, DateTime.now())) return;
    
    state = [
      for (final h in state)
        if (h.id == id)
          _updateHabit(h, date, (current) => 
            current == HabitStatus.completed ? HabitStatus.none : HabitStatus.completed
          )
        else
          h
    ];
    _saveHabits();
  }

  void freezeDay(String id, DateTime date) {
    if (DateUtils.isSameDay(date, DateTime.now())) return;
    
    state = [
      for (final h in state)
        if (h.id == id)
          _updateHabit(h, date, (current) => 
            current == HabitStatus.frozen ? HabitStatus.none : HabitStatus.frozen
          )
        else
          h
    ];
    _saveHabits();
  }

  Habit _updateHabit(Habit h, DateTime date, HabitStatus Function(HabitStatus) transform) {
    final key = _dateKey(date);
    final currentStatus = h.history[key] ?? HabitStatus.none;
    final newHistory = Map<String, HabitStatus>.from(h.history);
    
    final newStatus = transform(currentStatus);
    if (newStatus == HabitStatus.none) {
      newHistory.remove(key);
    } else {
      newHistory[key] = newStatus;
    }

    return h.copyWith(
      history: newHistory,
      streak: _calculateStreak(newHistory),
    );
  }

  int _calculateStreak(Map<String, HabitStatus> history) {
    int streak = 0;
    int consecutiveMisses = 0;
    int consecutiveFreezes = 0;
    DateTime date = DateTime.now();
    
    while (true) {
      final key = _dateKey(date);
      final status = history[key] ?? HabitStatus.none;
      
      if (status == HabitStatus.completed) {
        streak++;
        consecutiveMisses = 0;
        consecutiveFreezes = 0;
      } else if (status == HabitStatus.frozen) {
        consecutiveMisses = 0;
        consecutiveFreezes++;
        if (consecutiveFreezes >= 2) {
          // Streak breaks if 2 or more freezes one after the other!
          break;
        }
      } else {
        if (DateUtils.isSameDay(date, DateTime.now())) {
          // Skip today
        } else {
          consecutiveMisses++;
          consecutiveFreezes = 0;
          if (consecutiveMisses >= 2) break;
        }
      }
      date = date.subtract(const Duration(days: 1));
      if (DateTime.now().difference(date).inDays > 365) break;
    }
    
    return streak;
  }
}

final habitsProvider = NotifierProvider<HabitsNotifier, List<Habit>>(() {
  return HabitsNotifier();
});

final habitIdeasPool = [
  {'name': 'Read 10 Pages', 'idea': 'Sharpen your mind daily', 'icon': '📚', 'color': Colors.blue},
  {'name': 'Meditate', 'idea': 'Find your inner peace', 'icon': '🧘', 'color': Colors.purple},
  {'name': 'Exercise', 'idea': 'Keep your body active', 'icon': '🏃', 'color': Colors.orange},
  {'name': 'Drink Water', 'idea': 'Stay hydrated', 'icon': '💧', 'color': Colors.cyan},
  {'name': 'Journaling', 'idea': 'Reflect on your day', 'icon': '✍️', 'color': Colors.teal},
  {'name': 'Sleep 8 Hours', 'idea': 'Rest and recover', 'icon': '😴', 'color': Colors.indigo},
  {'name': 'Learn Language', 'idea': 'Expand your horizons', 'icon': '🌍', 'color': Colors.green},
  {'name': 'No Sugar', 'idea': 'Eat clean and healthy', 'icon': '🚫', 'color': Colors.red},
  // Adventure & Fun
  {'name': 'Explore Outdoors', 'idea': 'Discover a new trail or park', 'icon': '🏕️', 'color': Colors.brown},
  {'name': 'Try New Recipe', 'idea': 'Cook something adventurous', 'icon': '🍳', 'color': Colors.deepOrange},
  {'name': 'Take a Photo', 'idea': 'Capture a beautiful moment', 'icon': '📸', 'color': Colors.pink},
  {'name': 'Try a New Hobby', 'idea': 'Step out of your comfort zone', 'icon': '🎨', 'color': Colors.amber},
  // Self-Improvement
  {'name': 'Learn a Skill', 'idea': 'Code, play guitar, or craft', 'icon': '🧠', 'color': Colors.deepPurple},
  {'name': 'Compliment Someone', 'idea': 'Spread positivity today', 'icon': '✨', 'color': Colors.yellow},
  {'name': 'Digital Detox', 'idea': 'Unplug for an hour', 'icon': '📵', 'color': Colors.blueGrey},
  {'name': 'Read Articles', 'idea': 'Stay informed on new topics', 'icon': '📰', 'color': Colors.lightBlue},
];

class IdeasNotifier extends Notifier<List<Map<String, dynamic>>> {
  @override
  List<Map<String, dynamic>> build() {
    return _getRandomIdeas();
  }

  void refresh() {
    state = _getRandomIdeas();
  }

  List<Map<String, dynamic>> _getRandomIdeas() {
    final random = Random();
    final pool = List<Map<String, dynamic>>.from(habitIdeasPool);
    pool.shuffle(random);
    return pool.take(4).toList();
  }
}

final currentIdeasProvider = NotifierProvider<IdeasNotifier, List<Map<String, dynamic>>>(() {
  return IdeasNotifier();
});

class HabitsPage extends ConsumerWidget {
  const HabitsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(habitsProvider);
    final ideas = ref.watch(currentIdeasProvider);

    final theme = Theme.of(context);
    final appColors = theme.extension<AppColorsExtension>()!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(isMobile ? 20 : 40, isMobile ? 32 : 64, isMobile ? 20 : 40, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Habit Tracker',
                              style: TextStyle(fontSize: isMobile ? 26 : 32, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
                            ),
                            const Gap(12),
                            IconButton(
                              onPressed: () => _showSettingsDialog(context),
                              icon: Icon(LucideIcons.settings, size: 20, color: theme.textTheme.labelLarge?.color),
                              tooltip: 'Settings & Controls',
                            ),
                          ],
                        ),
                        const Gap(8),
                        Text(
                          'Consistency is the key to Kaizen.',
                          style: TextStyle(fontSize: isMobile ? 14 : 16, color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7)),
                        ),
                      ],
                    ),
                    if (habits.isNotEmpty && !isMobile)
                      ElevatedButton.icon(
                        onPressed: () => _showAddHabitDialog(context, ref),
                        icon: const Icon(LucideIcons.plus, size: 18),
                        label: const Text('New Habit'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        ),
                      ),
                  ],
                ),
                if (isMobile && habits.isNotEmpty) ...[
                  const Gap(16),
                  ElevatedButton.icon(
                    onPressed: () => _showAddHabitDialog(context, ref),
                    icon: const Icon(LucideIcons.plus, size: 16),
                    label: const Text('New Habit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ],
                const Gap(24),
                if (habits.isEmpty)
                  _buildEmptyState(context, ref)
                else ...[
                  isMobile ? _buildMobileOverview(context, habits) : _buildOverviewCards(context, habits),
                  const Gap(32),
                  Text(
                    'Your Journey',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
                  ),
                  const Gap(16),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: habits.length,
                    separatorBuilder: (context, index) => const Gap(12),
                    itemBuilder: (context, index) => _buildHabitCard(context, ref, habits[index]),
                  ),
                ],
                if (isMobile && habits.isNotEmpty) ...[
                  const Gap(32),
                  _buildWeeklySummarySection(context, habits),
                ],
                const Gap(48),
                _buildSuggestionsSection(context, ref, ideas),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildMobileOverview(BuildContext context, List<Habit> habits) {
    final theme = Theme.of(context);
    final todayKey = _dateKey(DateTime.now());
    final completedToday = habits.where((h) => h.history[todayKey] == HabitStatus.completed).length;
    final totalHabits = habits.length;
    final todayProgress = totalHabits == 0 ? 0.0 : (completedToday / totalHabits);

    String streakInsight = "Start a habit streak today by ticking off your daily routines.";
    String patternInsight = "Establish a regular rhythm to identify your optimal weekly focus patterns.";

    if (habits.isNotEmpty) {
      Habit? topStreakHabit;
      int maxStreak = -1;
      for (final h in habits) {
        if (h.streak > maxStreak) {
          maxStreak = h.streak;
          topStreakHabit = h;
        }
      }

      if (topStreakHabit != null && maxStreak > 0) {
        streakInsight = "Your strongest habit is ${topStreakHabit.name} with a $maxStreak day streak. Keep it going! 🔥";
      }

      final weekdayCompletions = <int, int>{};
      final weekdayOpportunities = <int, int>{};
      final today = DateTime.now();
      for (int i = 0; i < 30; i++) {
        final date = today.subtract(Duration(days: i));
        final dateStr = _dateKey(date);
        final wd = date.weekday;
        for (final h in habits) {
          weekdayOpportunities[wd] = (weekdayOpportunities[wd] ?? 0) + 1;
          if (h.history[dateStr] == HabitStatus.completed) {
            weekdayCompletions[wd] = (weekdayCompletions[wd] ?? 0) + 1;
          }
        }
      }

      int bestWeekday = -1;
      double bestRate = -1.0;
      for (int wd = 1; wd <= 7; wd++) {
        final opp = weekdayOpportunities[wd] ?? 0;
        final comp = weekdayCompletions[wd] ?? 0;
        if (opp > 0) {
          final rate = comp / opp;
          if (rate > bestRate) {
            bestRate = rate;
            bestWeekday = wd;
          }
        }
      }

      final weekdayNames = ["", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];
      if (bestWeekday != -1 && bestRate > 0.1) {
        final pct = (bestRate * 100).round();
        patternInsight = "You are historically most active on ${weekdayNames[bestWeekday]}s (with a $pct% completion rate).";
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.primaryColor.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withValues(alpha: 0.01),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 76,
                height: 76,
                padding: const EdgeInsets.all(4),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 68,
                      height: 68,
                      child: CircularProgressIndicator(
                        value: todayProgress,
                        strokeWidth: 8,
                        backgroundColor: theme.primaryColor.withValues(alpha: 0.08),
                        valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Text(
                      "${(todayProgress * 100).toInt()}%",
                      style: GoogleFonts.sora(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(LucideIcons.sparkles, size: 14, color: theme.primaryColor),
                        const Gap(6),
                        Text(
                          'AI OBSERVATIONS',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: theme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const Gap(8),
                    Text(
                      streakInsight,
                      style: GoogleFonts.sora(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Gap(16),
          Divider(color: theme.dividerColor.withValues(alpha: 0.3), height: 1),
          const Gap(16),
          Row(
            children: [
              Icon(LucideIcons.barChart2, size: 14, color: theme.primaryColor.withValues(alpha: 0.6)),
              const Gap(12),
              Expanded(
                child: Text(
                  patternInsight,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklySummarySection(BuildContext context, List<Habit> habits) {
    final theme = Theme.of(context);
    final weekdayCompletions = <int, int>{};
    final weekdayOpportunities = <int, int>{};
    final today = DateTime.now();

    for (int i = 0; i < 30; i++) {
      final date = today.subtract(Duration(days: i));
      final dateStr = _dateKey(date);
      final wd = date.weekday;
      for (final h in habits) {
        weekdayOpportunities[wd] = (weekdayOpportunities[wd] ?? 0) + 1;
        if (h.history[dateStr] == HabitStatus.completed) {
          weekdayCompletions[wd] = (weekdayCompletions[wd] ?? 0) + 1;
        }
      }
    }

    final weekdayLabels = ["", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Weekly Completion Trend',
          style: GoogleFonts.sora(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        const Gap(16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            color: theme.cardColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.08)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (index) {
              final wd = index + 1; // 1 = Monday, 7 = Sunday
              final opp = weekdayOpportunities[wd] ?? 0;
              final comp = weekdayCompletions[wd] ?? 0;
              final rate = opp == 0 ? 0.0 : (comp / opp);

              return Column(
                children: [
                  Text(
                    "${(rate * 100).toInt()}%",
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.8),
                    ),
                  ),
                  const Gap(8),
                  Container(
                    width: 12,
                    height: 80,
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    clipBehavior: Clip.antiAlias,
                    alignment: Alignment.bottomCenter,
                    child: FractionallySizedBox(
                      heightFactor: rate,
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                  const Gap(8),
                  Text(
                    weekdayLabels[wd],
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  Future<void> _handleDelete(BuildContext context, WidgetRef ref, Habit habit) async {
    final settings = ref.read(settingsProvider);
    final theme = Theme.of(context);
    
    if (!settings.askBeforeDelete) {
      ref.read(habitsProvider.notifier).deleteHabit(habit.id);
      return;
    }

    bool dontShowAgain = false;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: theme.dialogTheme.backgroundColor,
            shape: theme.dialogTheme.shape,
            title: Text('Delete Habit', style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Are you sure you want to delete this habit? All history will be lost.',
                  style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                ),
                const Gap(24),
                InkWell(
                  mouseCursor: SystemMouseCursors.click,
                  onTap: () => setState(() => dontShowAgain = !dontShowAgain),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Radio<bool>(
                          value: true,
                          groupValue: dontShowAgain,
                          onChanged: (val) => setState(() => dontShowAgain = val ?? false),
                          activeColor: theme.primaryColor,
                          visualDensity: VisualDensity.compact,
                          toggleable: true,
                        ),
                        const Gap(8),
                        Text(
                          "Don't show me again",
                          style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel', style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
              ),
              ElevatedButton(
                onPressed: () {
                  if (dontShowAgain) {
                    ref.read(settingsProvider.notifier).setAskBeforeDelete(false);
                  }
                  Navigator.pop(context, true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete'),
              ),
            ],
          );
        },
      ),
    );

    if (confirm == true) {
      ref.read(habitsProvider.notifier).deleteHabit(habit.id);
    }
  }

  void _showSettingsDialog(BuildContext context) {
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          final settings = ref.watch(settingsProvider);
          
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Container(
              width: 500,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.dialogTheme.backgroundColor,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 40, offset: const Offset(0, 20))
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Habit Controls', style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 20, fontWeight: FontWeight.bold)),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(LucideIcons.x, size: 20, color: theme.textTheme.bodyMedium?.color),
                        ),
                      ],
                    ),
                    const Gap(24),
                    _buildHelpItem(context, LucideIcons.mousePointerClick, 'Tracking', 'Click on grid cells to toggle habit completion for the day'),
                    const Gap(16),
                    _buildHelpItem(context, LucideIcons.snowflake, 'Freezing', 'Long press a grid cell to freeze a day so it doesn\'t affect your streak'),
                    const Gap(16),
                    _buildHelpItem(context, LucideIcons.barChart2, 'Analytics', 'Watch your streak and completion percentage grow'),
                    const Gap(32),
                    Divider(color: theme.dividerColor),
                    const Gap(24),
                    Text('Settings', style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 16, fontWeight: FontWeight.bold)),
                    const Gap(16),
                    InkWell(
                      mouseCursor: SystemMouseCursors.click,
                      onTap: () => ref.read(settingsProvider.notifier).setAskBeforeDelete(!settings.askBeforeDelete),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.02),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(LucideIcons.shieldAlert, size: 16, color: theme.textTheme.bodyMedium?.color),
                                const Gap(12),
                                Text('Ask before deleting', style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 13)),
                              ],
                            ),
                            Switch(
                              value: settings.askBeforeDelete,
                              onChanged: (val) => ref.read(settingsProvider.notifier).setAskBeforeDelete(val),
                              activeColor: theme.primaryColor,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Gap(32),
                    Center(child: Text('Kaizen Habits v1.0', style: TextStyle(color: theme.textTheme.labelLarge?.color, fontSize: 11))),
                    const Gap(8),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHelpItem(BuildContext context, IconData icon, String title, String description) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: theme.primaryColor),
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 14, fontWeight: FontWeight.bold)),
                const Gap(4),
                Text(description, style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 40),
      decoration: BoxDecoration(
        color: theme.cardColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.primaryColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: theme.primaryColor.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(LucideIcons.flame, size: 48, color: theme.primaryColor),
          ),
          const Gap(24),
          Text(
            'Start Your Journey',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
          ),
          const Gap(8),
          SizedBox(
            width: 340,
            child: Text(
              'Small daily actions lead to monumental results. Create your first habit to begin.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6)),
            ),
          ),
          const Gap(32),
          ElevatedButton(
            onPressed: () => _showAddHabitDialog(context, ref),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              elevation: 0,
            ),
            child: const Text('Create First Habit', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsSection(BuildContext context, WidgetRef ref, List<Map<String, dynamic>> ideas) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Ideas',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
            ),
            IconButton(
              onPressed: () => ref.read(currentIdeasProvider.notifier).refresh(),
              icon: Icon(LucideIcons.rotateCw, size: 18, color: theme.textTheme.bodySmall?.color),
              tooltip: 'Refresh Ideas',
            ),
          ],
        ),
        const Gap(24),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isMobile ? 1 : 4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: isMobile ? 3.2 : 2.2,
          ),
          itemCount: ideas.length,
          itemBuilder: (context, index) {
            final s = ideas[index];
            return InkWell(
              mouseCursor: SystemMouseCursors.click,
              onTap: () {
                ref.read(habitsProvider.notifier).addHabit(s['name'] as String, s['icon'] as String, s['color'] as Color);
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.cardColor.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: (s['color'] as Color).withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: (s['color'] as Color).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(child: Text(s['icon'] as String, style: const TextStyle(fontSize: 16))),
                    ),
                    const Gap(12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(s['name'] as String, style: TextStyle(fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color, fontSize: 13)),
                          const Gap(2),
                          Text(s['idea'] as String, style: TextStyle(fontSize: 11, color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6))),
                        ],
                      ),
                    ),
                    Icon(LucideIcons.plusCircle, size: 18, color: theme.primaryColor),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildOverviewCards(BuildContext context, List<Habit> habits) {
    final totalStreaks = habits.fold(0, (sum, item) => sum + item.streak);
    final todayKey = _dateKey(DateTime.now());
    final completedToday = habits.where((h) => h.history[todayKey] == HabitStatus.completed).length;

    return Row(
      children: [
        _buildStatCard(context, 'Total Streaks', totalStreaks.toString(), LucideIcons.flame, Colors.orange),
        const Gap(24),
        _buildStatCard(context, 'Completed Today', '$completedToday/${habits.length}', LucideIcons.checkCircle2, Colors.green),
        const Gap(24),
        _buildStatCard(context, 'Consistency', habits.isEmpty ? '0%' : '${(completedToday / habits.length * 100).toInt()}%', LucideIcons.trophy, Colors.amber),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: TextStyle(color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                Icon(icon, color: color.withValues(alpha: 0.7), size: 16),
              ],
            ),
            const Gap(8),
            Text(value, style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildHabitCard(BuildContext context, WidgetRef ref, Habit habit) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 800;

    if (isMobile) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: habit.color.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                MouseRegion(cursor: SystemMouseCursors.click, child: GestureDetector(
                  onTap: () => _showHabitDetailsDialog(context, ref, habit),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: habit.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(child: Text(habit.icon, style: const TextStyle(fontSize: 18))),
                  ),
                )),
                const Gap(12),
                Expanded(
                  child: MouseRegion(cursor: SystemMouseCursors.click, child: GestureDetector(
                    onTap: () => _showHabitDetailsDialog(context, ref, habit),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          habit.name,
                          style: GoogleFonts.sora(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                        const Gap(2),
                        Row(
                          children: [
                            Icon(LucideIcons.flame, size: 12, color: Colors.orange.withValues(alpha: 0.8)),
                            const Gap(4),
                            Text(
                              '${habit.streak} day streak',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )),
                ),
                _buildMoreButton(context, ref, habit),
              ],
            ),
            const Gap(16),
            Divider(color: theme.dividerColor.withValues(alpha: 0.15), height: 1),
            const Gap(16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (index) {
                final date = DateTime.now().subtract(Duration(days: 6 - index));
                final isToday = index == 6;
                final status = habit.history[_dateKey(date)] ?? HabitStatus.none;
                final isDone = status == HabitStatus.completed;
                final isFrozen = status == HabitStatus.frozen;
                final isConsecutiveFreeze = _isConsecutiveFreeze(habit, date);
                final dayLabel = DateFormat('E').format(date).substring(0, 1);

                String tooltipMsg = '';
                if (isToday) {
                  tooltipMsg = isDone ? 'Completed Today' : 'Tap to complete today';
                } else {
                  if (isFrozen) {
                    tooltipMsg = isConsecutiveFreeze ? 'Consecutive Freeze (Streak Broken!)' : 'Streak Frozen';
                  } else {
                    tooltipMsg = isDone ? 'Completed' : 'Long press to freeze this day';
                  }
                }

                return Tooltip(
                  message: tooltipMsg,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () {
                        if (isToday) {
                          ref.read(habitsProvider.notifier).toggleDay(habit.id, date);
                        }
                      },
                      onLongPress: () {
                        if (!isToday) {
                          ref.read(habitsProvider.notifier).freezeDay(habit.id, date);
                        }
                      },
                      child: Column(
                        children: [
                          Text(
                            dayLabel,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                              color: isToday ? theme.primaryColor : theme.textTheme.bodySmall?.color?.withValues(alpha: 0.4),
                            ),
                          ),
                          const Gap(6),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isDone 
                                  ? habit.color 
                                  : (isFrozen 
                                      ? (isConsecutiveFreeze ? Colors.redAccent.withValues(alpha: 0.15) : Colors.blue.withValues(alpha: 0.15)) 
                                      : theme.scaffoldBackgroundColor.withValues(alpha: 0.3)),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDone 
                                    ? Colors.transparent 
                                    : (isToday 
                                        ? theme.primaryColor.withValues(alpha: 0.4) 
                                        : (isFrozen && isConsecutiveFreeze ? Colors.redAccent.withValues(alpha: 0.3) : theme.dividerColor.withValues(alpha: 0.1))),
                                width: isToday ? 2 : 1,
                              ),
                            ),
                            child: Center(
                              child: isDone 
                                  ? const Icon(LucideIcons.check, color: Colors.white, size: 16)
                                  : (isFrozen 
                                      ? Icon(
                                          isConsecutiveFreeze ? LucideIcons.alertTriangle : LucideIcons.snowflake, 
                                          color: isConsecutiveFreeze ? Colors.redAccent : Colors.blue, 
                                          size: 14
                                        ) 
                                      : null),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      );
    }

    return InkWell(
      mouseCursor: SystemMouseCursors.click,
      onTap: () => _showHabitDetailsDialog(context, ref, habit),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: theme.cardColor.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: habit.color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: habit.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: Text(habit.icon, style: const TextStyle(fontSize: 20))),
            ),
            const Gap(16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(habit.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
                  const Gap(2),
                  Row(
                    children: [
                      Icon(LucideIcons.flame, size: 12, color: Colors.orange.withValues(alpha: 0.6)),
                      const Gap(4),
                      Text('${habit.streak} day streak', style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6))),
                    ],
                  ),
                ],
              ),
            ),
            Row(
              children: List.generate(7, (index) {
                final date = DateTime.now().subtract(Duration(days: 6 - index));
                final isToday = index == 6;
                final status = habit.history[_dateKey(date)] ?? HabitStatus.none;
                final isDone = status == HabitStatus.completed;
                final isFrozen = status == HabitStatus.frozen;
                final isConsecutiveFreeze = _isConsecutiveFreeze(habit, date);

                String tooltipMsg = '';
                if (isToday) {
                  tooltipMsg = isDone ? 'Completed Today' : 'Tap to complete today';
                } else {
                  if (isFrozen) {
                    tooltipMsg = isConsecutiveFreeze ? 'Consecutive Freeze (Streak Broken!)' : 'Streak Frozen';
                  } else {
                    tooltipMsg = isDone ? 'Completed' : 'Long press to freeze this day';
                  }
                }

                return Tooltip(
                  message: tooltipMsg,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () {
                        if (isToday) {
                          ref.read(habitsProvider.notifier).toggleDay(habit.id, date);
                        }
                      },
                      onLongPress: () {
                        if (!isToday) {
                          ref.read(habitsProvider.notifier).freezeDay(habit.id, date);
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isDone 
                              ? habit.color 
                              : (isFrozen 
                                  ? (isConsecutiveFreeze ? Colors.redAccent.withValues(alpha: 0.15) : Colors.blue.withValues(alpha: 0.15)) 
                                  : theme.scaffoldBackgroundColor.withValues(alpha: 0.3)),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isDone 
                                ? Colors.transparent 
                                : (isToday 
                                    ? theme.primaryColor.withValues(alpha: 0.4) 
                                    : (isFrozen && isConsecutiveFreeze ? Colors.redAccent.withValues(alpha: 0.3) : theme.dividerColor.withValues(alpha: 0.1))),
                          ),
                        ),
                        child: Center(
                          child: isDone 
                              ? const Icon(LucideIcons.check, color: Colors.white, size: 14)
                              : (isFrozen 
                                  ? Icon(
                                      isConsecutiveFreeze ? LucideIcons.alertTriangle : LucideIcons.snowflake, 
                                      color: isConsecutiveFreeze ? Colors.redAccent : Colors.blue, 
                                      size: 12
                                    ) 
                                  : null),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const Gap(24),
            _buildMoreButton(context, ref, habit),
          ],
        ),
      ),
    );
  }

  void _showHabitDetailsDialog(BuildContext context, WidgetRef ref, Habit habit) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.dialogTheme.backgroundColor,
        shape: theme.dialogTheme.shape,
        contentPadding: EdgeInsets.zero,
        content: Container(
          width: 500,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: habit.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(child: Text(habit.icon, style: const TextStyle(fontSize: 32))),
                  ),
                  const Gap(24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(habit.name, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
                        const Gap(4),
                        Row(
                          children: [
                            const Icon(LucideIcons.flame, size: 16, color: Colors.orange),
                            const Gap(8),
                            Text('${habit.streak} Day Streak', style: TextStyle(color: theme.textTheme.bodySmall?.color, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(LucideIcons.x, color: theme.textTheme.bodySmall?.color),
                  ),
                ],
              ),
              const Gap(40),
              _buildMonthlyGrid(context, habit),
              const Gap(40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildDetailStat(context, 'Total Days', habit.history.values.where((v) => v == HabitStatus.completed).length.toString()),
                  _buildDetailStat(context, 'Status', 'Active'),
                  _buildDetailStat(context, 'Goal', 'Daily'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailStat(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(label, style: TextStyle(color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5), fontSize: 12)),
        const Gap(8),
        Text(value, style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildMonthlyGrid(BuildContext context, Habit habit) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final startWeekday = firstDayOfMonth.weekday % 7;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          DateFormat('MMMM yyyy').format(now),
          style: TextStyle(color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.9), fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const Gap(20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((day) => 
            Expanded(
              child: Center(
                child: Text(
                  day,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),
          ).toList(),
        ),
        const Gap(10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: daysInMonth + startWeekday,
          itemBuilder: (context, index) {
            if (index < startWeekday) return const SizedBox();
            
            final day = index - startWeekday + 1;
            final date = DateTime(now.year, now.month, day);
             final key = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
             final status = habit.history[key] ?? HabitStatus.none;
             final isToday = DateUtils.isSameDay(date, now);
             final isDone = status == HabitStatus.completed;
             final isFrozen = status == HabitStatus.frozen;
             final isConsecutiveFreeze = _isConsecutiveFreeze(habit, date);

            String tooltipMsg = '';
            if (isToday) {
              tooltipMsg = isDone ? 'Completed Today' : 'Tap to complete today';
            } else {
              if (isFrozen) {
                tooltipMsg = isConsecutiveFreeze ? 'Consecutive Freeze (Streak Broken!)' : 'Streak Frozen';
              } else {
                tooltipMsg = isDone ? 'Completed' : 'Long press to freeze this day';
              }
            }

            return Tooltip(
              message: tooltipMsg,
              child: Container(
                decoration: BoxDecoration(
                  color: isDone 
                      ? habit.color 
                      : (isFrozen 
                          ? (isConsecutiveFreeze ? Colors.redAccent.withValues(alpha: 0.2) : Colors.blue.withValues(alpha: 0.2)) 
                          : Colors.transparent),
                  borderRadius: BorderRadius.circular(6),
                  border: isToday 
                      ? Border.all(color: theme.primaryColor, width: 2) 
                      : (isFrozen && isConsecutiveFreeze ? Border.all(color: Colors.redAccent.withValues(alpha: 0.4)) : Border.all(color: theme.dividerColor)),
                ),
                child: Center(
                  child: isFrozen && isConsecutiveFreeze
                      ? const Icon(LucideIcons.alertTriangle, color: Colors.redAccent, size: 10)
                      : Text(
                          day.toString(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                            color: isDone ? Colors.white : (isToday ? theme.primaryColor : theme.textTheme.bodySmall?.color),
                          ),
                        ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMoreButton(BuildContext context, WidgetRef ref, Habit habit) {
    final theme = Theme.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: PopupMenuButton<String>(
        onSelected: (value) {
        if (value == 'delete') {
          _handleDelete(context, ref, habit);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(LucideIcons.trash2, size: 16, color: Colors.redAccent),
              Gap(12),
              Text('Delete Habit', style: TextStyle(color: Colors.redAccent)),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Icon(LucideIcons.moreHorizontal, size: 18, color: theme.textTheme.bodySmall?.color),
      ),
      ),
    );
  }

  void _showAddHabitDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.dialogTheme.backgroundColor,
        shape: theme.dialogTheme.shape,
        title: Text('Create New Habit', style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              style: TextStyle(color: theme.textTheme.bodyLarge?.color),
              decoration: InputDecoration(
                hintText: 'Habit Name (e.g., Cold Shower)',
                hintStyle: TextStyle(color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5)),
                filled: true,
                fillColor: theme.scaffoldBackgroundColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const Gap(16),
            Text('Frequency: Daily', style: TextStyle(color: theme.textTheme.bodySmall?.color)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                ref.read(habitsProvider.notifier).addHabit(nameController.text, '🔥', theme.primaryColor);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: theme.primaryColor, foregroundColor: Colors.white),
            child: const Text('Start Journey'),
          ),
        ],
      ),
    );
  }
}
