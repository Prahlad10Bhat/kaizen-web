// Box Clock Page - Visualizes the passage of time in boxes.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../providers/boxclock_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/custom_context_menu.dart';
import '../../theme/app_colors.dart';

class BoxClockPage extends ConsumerStatefulWidget {
  const BoxClockPage({super.key});

  @override
  ConsumerState<BoxClockPage> createState() => _BoxClockPageState();
}

class _BoxClockPageState extends ConsumerState<BoxClockPage> {
  String? _selectedGoalId;

  ThemeData get theme => Theme.of(context);
  AppColorsExtension get appColors => theme.extension<AppColorsExtension>()!;

  double _calculateBoxSize(int totalUnits, bool isDays) {
    if (isDays) {
      if (totalUnits < 100) return 32.0;
      if (totalUnits < 400) return 20.0;
      if (totalUnits < 1000) return 12.0;
      return 8.0;
    } else {
      if (totalUnits < 55) return 36.0; 
      if (totalUnits < 150) return 24.0;
      if (totalUnits < 550) return 18.0;
      return 14.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(boxClockProvider);
    final isDays = data.unit == BoxClockUnit.days;
    
    final totalUnits = isDays 
        ? data.endDate.difference(data.startDate).inDays
        : data.endDate.difference(data.startDate).inDays ~/ 7;
        
    final now = DateTime.now();
    int elapsedUnits = 0;
    if (now.isAfter(data.startDate)) {
      elapsedUnits = isDays
          ? now.difference(data.startDate).inDays
          : now.difference(data.startDate).inDays ~/ 7;
    }
    
    elapsedUnits = elapsedUnits.clamp(0, totalUnits);
    final remainingUnits = (totalUnits - elapsedUnits).clamp(0, totalUnits);

    final boxSize = _calculateBoxSize(totalUnits, isDays);
    
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColorsExtension>()!;
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: MouseRegion(cursor: SystemMouseCursors.click, child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (_selectedGoalId != null) {
            setState(() => _selectedGoalId = null);
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(0, 40, 0, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60),
              child: _buildHeader(data, elapsedUnits, remainingUnits, totalUnits),
            ),
            const Gap(48),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: KeyedSubtree(
                  key: ValueKey<BoxClockUnit>(data.unit),
                  child: _buildStructuredGrid(data, elapsedUnits, boxSize),
                ),
              ),
            ),
            _buildGoalsSection(data),
            const Gap(48),
            _buildQuoteFooter(),
          ],
        ),
      ),
      )),
    );
  }

  Widget _buildHeader(BoxClockData data, int elapsed, int remaining, int total) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Box Clock',
                  style: GoogleFonts.sora(
                    color: theme.textTheme.bodyLarge?.color,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -1,
                  ),
                ),
                const Gap(12),
                IconButton(
                  onPressed: () => _showWindowSettingsDialog(data),
                  icon: Icon(LucideIcons.calendarRange, color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.2), size: 20),
                  tooltip: 'Define Clock Window',
                ),
                const Gap(4),
                IconButton(
                  onPressed: () => _showSettingsDialog(context),
                  icon: Icon(LucideIcons.settings, color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.2), size: 20),
                  tooltip: 'Settings & Controls',
                ),
              ],
            ),
            const Gap(16),
            SizedBox(
              width: 320,
              child: _buildStatsBar(data, elapsed, remaining, total),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Gap(20),
            _buildUnitToggle(data),
            const Gap(16),
            Text(
              '${((elapsed / total).clamp(0.0, 1.0) * 100).toStringAsFixed(1)}%',
              style: GoogleFonts.sora(
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.03),
                fontSize: 140,
                fontWeight: FontWeight.w800,
                height: 0.8,
              ),
            ),
            const Gap(20),
            _buildLegend(data),
          ],
        ),
      ],
    );
  }

  Widget _buildUnitToggle(BoxClockData data) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton(data, BoxClockUnit.days, 'Days'),
          _buildToggleButton(data, BoxClockUnit.weeks, 'Weeks'),
        ],
      ),
    );
  }

  Widget _buildToggleButton(BoxClockData data, BoxClockUnit unit, String label) {
    final isSelected = data.unit == unit;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
      onTap: () => ref.read(boxClockProvider.notifier).setUnit(unit),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? theme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: isSelected ? Colors.white : theme.textTheme.bodySmall?.color,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildStructuredGrid(BoxClockData data, int elapsed, double boxSize) {
    final isDays = data.unit == BoxClockUnit.days;
    
    List<Widget> yearRows = [];
    DateTime currentDate = data.startDate;
    int unitIndex = 0;

    if (data.endDate.isBefore(data.startDate)) return const Text('Invalid Date Range');

    while (currentDate.isBefore(data.endDate)) {
      final year = currentDate.year;
      final yearStart = currentDate;
      final nextYearStart = DateTime(year + 1, 1, 1);
      final yearEnd = nextYearStart.isBefore(data.endDate) 
          ? nextYearStart 
          : data.endDate;
      
      final unitsInThisYear = isDays 
          ? yearEnd.difference(yearStart).inDays
          : (yearEnd.difference(yearStart).inDays / 7).ceil();

      if (unitsInThisYear > 0) {
        yearRows.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      year.toString(),
                      style: GoogleFonts.sora(
                        color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Gap(16),
                    Expanded(child: Divider(color: theme.dividerColor.withValues(alpha: 0.3))),
                  ],
                ),
                const Gap(24),
                _buildUnitRow(data, yearStart, unitsInThisYear, unitIndex, elapsed, boxSize),
              ],
            ),
          ),
        );
        unitIndex += unitsInThisYear;
      }

      currentDate = yearEnd;
    }
    
    // Add continuation indicator if focused goal exceeds current window
    if (_selectedGoalId != null) {
      final selectedGoal = data.goals.firstWhere((g) => g.id == _selectedGoalId);
      if (selectedGoal.endDate.isAfter(data.endDate)) {
        yearRows.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: selectedGoal.color.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: selectedGoal.color.withValues(alpha: 0.1)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '...',
                      style: GoogleFonts.inter(
                        color: selectedGoal.color,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                      ),
                    ),
                    const Gap(16),
                    Text(
                      'GOAL CONTINUES BEYOND THIS WINDOW',
                      style: GoogleFonts.inter(
                        color: selectedGoal.color.withValues(alpha: 0.6),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    }

    return Column(children: yearRows);
  }

  Widget _buildUnitRow(BoxClockData data, DateTime rowStart, int count, int startIndex, int elapsed, double boxSize) {
    final isDays = data.unit == BoxClockUnit.days;
    final selectedGoal = _selectedGoalId != null 
        ? data.goals.firstWhere((g) => g.id == _selectedGoalId, orElse: () => data.goals.first)
        : null;

    final spacing = boxSize * 0.5;

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: List.generate(count, (i) {
        final globalIndex = startIndex + i;
        final isCurrent = globalIndex == elapsed;
        final unitDate = rowStart.add(Duration(days: isDays ? i : i * 7));
        
        bool isInsideFocusedGoal = false;
        bool isGoalEndDate = false;
        Color? goalColor;
        String? label;
        if (selectedGoal != null && _selectedGoalId != null) {
          isInsideFocusedGoal = unitDate.isAfter(selectedGoal.startDate) && 
                                 unitDate.isBefore(selectedGoal.endDate);
          final normalizedGoalEnd = DateTime(selectedGoal.endDate.year, selectedGoal.endDate.month, selectedGoal.endDate.day);
          final normalizedUnitDate = DateTime(unitDate.year, unitDate.month, unitDate.day);
          final diff = normalizedGoalEnd.difference(normalizedUnitDate).inDays;
          isGoalEndDate = isDays ? (diff == 0) : (diff >= 0 && diff < 7);
          goalColor = selectedGoal.color;
          
          if (isInsideFocusedGoal || isGoalEndDate) {
            final startDiff = unitDate.difference(selectedGoal.startDate).inDays;
            final relIdx = isDays ? startDiff : (startDiff / 7).floor();
            label = (relIdx + 1).toString();
          }
        } else {
          for (final goal in data.goals) {
            final normalizedGoalEnd = DateTime(goal.endDate.year, goal.endDate.month, goal.endDate.day);
            final normalizedUnitDate = DateTime(unitDate.year, unitDate.month, unitDate.day);
            final diff = normalizedGoalEnd.difference(normalizedUnitDate).inDays;

            if (isDays ? (diff == 0) : (diff >= 0 && diff < 7)) {
              isGoalEndDate = true;
              goalColor = goal.color;
              break;
            }
          }
        }

        final score = data.scores.firstWhere(
          (s) => s.weekIndex == globalIndex,
          orElse: () => WeekScore(weekIndex: -1, score: 0, goalIds: [], note: '', timestamp: DateTime.now()),
        );
        final hasNote = score.note.isNotEmpty;

        Color boxColor = theme.cardColor;
        if (_selectedGoalId == null) {
          if (isGoalEndDate) {
            boxColor = goalColor!;
          } else if (globalIndex < elapsed) {
            boxColor = theme.textTheme.bodyLarge!.color!.withValues(alpha: 0.05);
          } else {
            boxColor = theme.cardColor;
          }
        } else {
          if (isInsideFocusedGoal) {
            boxColor = goalColor!.withValues(alpha: 0.8);
          } else if (isGoalEndDate) {
            boxColor = goalColor!;
          } else {
            boxColor = theme.cardColor.withValues(alpha: 0.1);
          }
        }

        return _HoverableUnitBox(
          isCurrent: isCurrent,
          isGoalEndDate: isGoalEndDate,
          hasNote: hasNote,
          boxColor: isCurrent ? theme.primaryColor : boxColor,
          tooltipText: '${isDays ? "Day" : "Week"} $globalIndex • ${DateFormat('MMM d, y').format(unitDate)}' 
              + (isGoalEndDate ? ' (Goal Deadline)' : '')
              + (hasNote ? '\nNote: ${score.note}' : ''),
          size: boxSize,
          focusedGoalColor: goalColor,
          label: label,
          onTap: () => _showUnitLogDialog(data, globalIndex, unitDate),
        );
      }),
    );
  }

  void _showUnitLogDialog(BoxClockData data, int index, DateTime date) {
    final existingScore = data.scores.firstWhere(
      (s) => s.weekIndex == index,
      orElse: () => WeekScore(weekIndex: index, score: 5, goalIds: [], note: '', timestamp: DateTime.now()),
    );

    String note = existingScore.note;
    int score = existingScore.score;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: theme.dialogTheme.backgroundColor,
          shape: theme.dialogTheme.shape,
          contentPadding: const EdgeInsets.all(32),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('EEEE, MMM d, y').format(date),
                style: GoogleFonts.inter(color: theme.textTheme.bodySmall?.color, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1),
              ),
              const Gap(12),
              Text(
                'Log Achievement',
                style: GoogleFonts.sora(color: theme.textTheme.bodyLarge?.color, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Gap(32),
              Text(
                'How was your progress?',
                style: GoogleFonts.inter(color: theme.textTheme.bodySmall?.color, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const Gap(16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(10, (i) {
                  final s = i + 1;
                  final isSelected = score == s;
                  return MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                    onTap: () => setState(() => score = s),
                    child: Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? theme.primaryColor : theme.scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        s.toString(),
                        style: GoogleFonts.jetBrainsMono(
                          color: isSelected ? Colors.white : theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ),
                  );
                }),
              ),
              const Gap(32),
              TextField(
                controller: TextEditingController(text: note)..selection = TextSelection.collapsed(offset: note.length),
                onChanged: (v) => note = v,
                maxLines: 4,
                style: GoogleFonts.inter(color: theme.textTheme.bodyLarge?.color, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'What did you achieve? Write a note...',
                  hintStyle: GoogleFonts.inter(color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.3)),
                  filled: true,
                  fillColor: theme.scaffoldBackgroundColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel', style: GoogleFonts.inter(color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.4))),
                  ),
                  const Gap(12),
                  ElevatedButton(
                    onPressed: () {
                      final newScore = WeekScore(
                        weekIndex: index,
                        score: score,
                        goalIds: [], // Could be linked to selected goal if any
                        note: note,
                        timestamp: DateTime.now(),
                      );
                      ref.read(boxClockProvider.notifier).updateScore(newScore);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Save Log'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(BoxClockData data) {
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 16,
      runSpacing: 8,
      children: [
        _buildLegendItem(context, Colors.white, 'TODAY'),
        ...data.goals.take(5).map((g) => _buildLegendItem(context, g.color, g.name.toUpperCase())),
      ],
    );
  }

  Widget _buildLegendItem(BuildContext context, Color color, String label) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const Gap(8),
        Text(
          label,
          style: GoogleFonts.inter(
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.4),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsBar(BoxClockData data, int elapsed, int remaining, int total) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStatItem(
              elapsed.toString(), 
              'ELAPSED',
              LucideIcons.clock,
            ),
            _buildStatItem(
              remaining.toString(), 
              'REMAINING',
              LucideIcons.hourglass,
            ),
          ],
        ),
          const Gap(16),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: (elapsed / total).clamp(0.0, 1.0),
              backgroundColor: Colors.white.withValues(alpha: 0.03),
              color: theme.primaryColor.withValues(alpha: 0.8),
              minHeight: 2,
            ),
          ),
    ],
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.3),
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const Gap(4),
        Text(
          value,
          style: GoogleFonts.inter(
            color: theme.textTheme.bodyLarge?.color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildGoalsSection(BoxClockData data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 60),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ACTIVE GOALS',
                style: GoogleFonts.inter(
                  color: theme.textTheme.bodySmall?.color,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              IconButton(
                onPressed: () => _showAddGoalDialog(),
                icon: Icon(LucideIcons.plus, color: theme.primaryColor, size: 20),
                tooltip: 'Set New Goal',
              ),
            ],
          ),
          const Gap(20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              mainAxisExtent: 180,
            ),
            itemCount: data.goals.length,
            itemBuilder: (context, index) {
              final goal = data.goals[index];
              final isFocused = _selectedGoalId == goal.id;
              
              final totalDays = goal.endDate.difference(goal.startDate).inDays;
              final elapsedDays = DateTime.now().difference(goal.startDate).inDays;
              final progress = (elapsedDays / totalDays).clamp(0.0, 1.0);
              
              return MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                onTap: () => setState(() => _selectedGoalId = isFocused ? null : goal.id),
                onSecondaryTapDown: (details) => _showGoalContextMenu(details.globalPosition, goal.id),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isFocused ? goal.color.withValues(alpha: 0.05) : theme.cardColor.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isFocused ? goal.color.withValues(alpha: 0.5) : theme.dividerColor.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: goal.color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(goal.category.icon, color: goal.color, size: 12),
                                const Gap(6),
                                Text(
                                  goal.category.label,
                                  style: GoogleFonts.inter(color: goal.color, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${(progress * 100).toInt()}%',
                            style: GoogleFonts.inter(color: goal.color, fontSize: 12, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      const Gap(20),
                      Text(
                        goal.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(color: theme.textTheme.bodyLarge?.color, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat('MMM d, y').format(goal.startDate),
                                style: GoogleFonts.inter(color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.3), fontSize: 10, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                DateFormat('MMM d, y').format(goal.endDate),
                                style: GoogleFonts.inter(color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.3), fontSize: 10, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const Gap(12),
                          Stack(
                            children: [
                              Container(
                                height: 6,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              AnimatedContainer(
                                duration: const Duration(seconds: 1),
                                height: 6,
                                width: (MediaQuery.of(context).size.width / 3 - 120) * progress,
                                decoration: BoxDecoration(
                                  color: goal.color,
                                  borderRadius: BorderRadius.circular(3),
                                  boxShadow: [
                                    BoxShadow(color: goal.color.withValues(alpha: 0.3), blurRadius: 8, spreadRadius: 1)
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showGoalContextMenu(Offset position, String goalId) async {
    await showCustomContextMenu(
      context: context,
      position: position,
      items: [
        CustomContextMenuItem(
          icon: LucideIcons.trash2,
          label: 'Delete Goal',
          isDestructive: true,
          onTap: () => Future.microtask(() => _handleDeleteGoal(goalId)),
        ),
      ],
    );
  }

  Future<void> _handleDeleteGoal(String goalId) async {
    final settings = ref.read(settingsProvider);
    
    if (!settings.askBeforeDelete) {
      ref.read(boxClockProvider.notifier).deleteGoal(goalId);
      if (_selectedGoalId == goalId) setState(() => _selectedGoalId = null);
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
            title: Text('Delete Goal', style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Are you sure you want to delete this goal? This action cannot be undone.',
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
      ref.read(boxClockProvider.notifier).deleteGoal(goalId);
      if (_selectedGoalId == goalId) setState(() => _selectedGoalId = null);
    }
  }

  void _showSettingsDialog(BuildContext context) {
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
                        Text('Box Clock Controls', style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 20, fontWeight: FontWeight.bold)),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(LucideIcons.x, size: 20, color: theme.textTheme.bodyMedium?.color),
                        ),
                      ],
                    ),
                    const Gap(24),
                    _buildHelpItem(context, LucideIcons.mousePointerClick, 'Focus', 'Click a goal card to highlight its timeline on the clock'),
                    const Gap(16),
                    _buildHelpItem(context, LucideIcons.calendarRange, 'Window', 'Use the calendar icon next to settings to change the visible time range'),
                    const Gap(16),
                    _buildHelpItem(context, LucideIcons.penTool, 'Logging', 'Click any past or present box to log a note or score'),
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
                    Center(child: Text('Kaizen Box Clock v1.0', style: TextStyle(color: theme.textTheme.labelLarge?.color, fontSize: 11))),
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

  void _showWindowSettingsDialog(BoxClockData data) {
    DateTime startDate = data.startDate;
    DateTime endDate = data.endDate;
    String selectedPreset = 'Custom';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: theme.dialogTheme.backgroundColor,
          shape: theme.dialogTheme.shape,
          title: Text('Clock Window', style: GoogleFonts.sora(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Duration Preset', style: GoogleFonts.inter(color: theme.textTheme.bodySmall?.color, fontSize: 13)),
              const Gap(12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  '1 Month',
                  '3 Months',
                  '6 Months',
                  '1 Year',
                  'Custom',
                ].map((preset) {
                  final isSelected = selectedPreset == preset;
                  return ChoiceChip(
                    label: Text(preset, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : theme.textTheme.bodySmall?.color)),
                    selected: isSelected,
                    onSelected: (s) {
                      setState(() {
                        selectedPreset = preset;
                        if (preset != 'Custom') {
                          final now = DateTime.now();
                          startDate = DateTime(now.year, now.month, now.day);
                          if (preset == '1 Month') endDate = startDate.add(const Duration(days: 30));
                          else if (preset == '3 Months') endDate = startDate.add(const Duration(days: 90));
                          else if (preset == '6 Months') endDate = startDate.add(const Duration(days: 180));
                          else if (preset == '1 Year') endDate = startDate.add(const Duration(days: 365));
                        }
                      });
                    },
                    selectedColor: theme.primaryColor,
                    backgroundColor: theme.cardColor,
                  );
                }).toList(),
              ),
              const Gap(24),
              if (selectedPreset == 'Custom') ...[
                _buildDateTile(context, 'Clock Start', startDate, (d) => setState(() => startDate = d)),
                _buildDateTile(context, 'Clock End', endDate, (d) => setState(() => endDate = d)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.inter(color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.4))),
            ),
            ElevatedButton(
              onPressed: () {
                ref.read(boxClockProvider.notifier).updateDates(startDate, endDate);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                elevation: 0,
              ),
              child: const Text('Update Window'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddGoalDialog() {
    String name = '';
    GoalCategory category = GoalCategory.learning;
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 30));
    Color selectedColor = theme.primaryColor;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: theme.dialogTheme.backgroundColor,
          shape: theme.dialogTheme.shape,
          title: Text('Set New Goal', style: GoogleFonts.sora(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  onChanged: (v) => name = v,
                  autofocus: true,
                  style: GoogleFonts.inter(color: theme.textTheme.bodyLarge?.color),
                  decoration: InputDecoration(
                    labelText: 'Goal Name',
                    labelStyle: GoogleFonts.inter(color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5)),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.dividerColor)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.primaryColor)),
                  ),
                ),
                const Gap(24),
                Text('Category', style: GoogleFonts.inter(color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5), fontSize: 12, fontWeight: FontWeight.w600)),
                const Gap(8),
                Wrap(
                  spacing: 8,
                  children: GoalCategory.values.map((c) {
                    final isSelected = category == c;
                    return ChoiceChip(
                      label: Text(c.label),
                      selected: isSelected,
                      onSelected: (s) => setState(() => category = c),
                      backgroundColor: theme.scaffoldBackgroundColor,
                      selectedColor: theme.primaryColor.withValues(alpha: 0.2),
                      labelStyle: GoogleFonts.inter(color: isSelected ? theme.primaryColor : theme.textTheme.bodySmall?.color, fontSize: 12),
                    );
                  }).toList(),
                ),
                const Gap(24),
                _buildDateTile(context, 'Start Date', startDate, (d) => setState(() => startDate = d)),
                _buildDateTile(context, 'End Date', endDate, (d) => setState(() => endDate = d)),
                const Gap(24),
                Text('Color', style: GoogleFonts.inter(color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5), fontSize: 12, fontWeight: FontWeight.w600)),
                const Gap(8),
                Wrap(
                  spacing: 12,
                  children: [
                    const Color(0xFF6C63FF),
                    const Color(0xFFE57373),
                    const Color(0xFF81C784),
                    const Color(0xFFFFB74D),
                    const Color(0xFF4FC3F7),
                  ].map((c) {
                    final isSelected = selectedColor == c;
                    return MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                      onTap: () => setState(() => selectedColor = c),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
                        ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel', style: GoogleFonts.inter(color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.4), fontSize: 14)),
                  ),
                  const Gap(12),
                  ElevatedButton(
                    onPressed: () {
                      if (name.isNotEmpty) {
                        final goal = LifeGoal(
                          id: const Uuid().v4(),
                          name: name,
                          color: selectedColor,
                          category: category,
                          startDate: startDate,
                          endDate: endDate,
                        );
                        ref.read(boxClockProvider.notifier).addGoal(goal);
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      elevation: 0,
                    ),
                    child: Text('Create Goal', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTile(BuildContext context, String label, DateTime date, Function(DateTime) onPicked) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: GoogleFonts.inter(color: theme.textTheme.bodySmall?.color, fontSize: 13, fontWeight: FontWeight.w500)),
      subtitle: Text(DateFormat('MMM dd, yyyy').format(date), style: GoogleFonts.inter(color: theme.textTheme.bodyLarge?.color, fontSize: 15, fontWeight: FontWeight.bold)),
      trailing: Icon(LucideIcons.calendar, color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.4), size: 18),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(1900),
          lastDate: DateTime(2100),
        );
        if (picked != null) onPicked(picked);
      },
    );
  }

  Widget _buildQuoteFooter() {
    return Center(
      child: Text(
        "Stay hungry, stay foolish.",
        style: GoogleFonts.sora(color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.05), fontStyle: FontStyle.italic, fontSize: 24),
      ),
    );
  }
}

class _HoverableUnitBox extends StatefulWidget {
  final bool isCurrent;
  final bool isGoalEndDate;
  final bool hasNote;
  final Color boxColor;
  final String tooltipText;
  final double size;
  final Color? focusedGoalColor;
  final String? label;
  final VoidCallback onTap;

  const _HoverableUnitBox({
    required this.isCurrent,
    required this.isGoalEndDate,
    required this.hasNote,
    required this.boxColor,
    required this.tooltipText,
    required this.size,
    this.focusedGoalColor,
    this.label,
    required this.onTap,
  });

  @override
  State<_HoverableUnitBox> createState() => _HoverableUnitBoxState();
}

class _HoverableUnitBoxState extends State<_HoverableUnitBox> {
  bool isHovered = false;

  ThemeData get theme => Theme.of(context);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: widget.tooltipText,
      verticalOffset: 20,
      preferBelow: false,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: theme.dividerColor),
      ),
      textStyle: GoogleFonts.inter(
        color: theme.textTheme.bodyLarge?.color,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => isHovered = true),
        onExit: (_) => setState(() => isHovered = false),
        child: MouseRegion(cursor: SystemMouseCursors.click, child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            width: widget.size,
            height: widget.size,
            transform: isHovered 
              ? (Matrix4.identity()..scale(1.3)..translate(-2.0, -2.0)) 
              : Matrix4.identity(),
            decoration: BoxDecoration(
              color: widget.isCurrent ? Colors.white : widget.boxColor,
              borderRadius: BorderRadius.circular(widget.size > 14 ? 6 : (widget.size > 8 ? 3 : 2)),
              border: isHovered 
                ? Border.all(color: widget.boxColor == theme.cardColor ? theme.primaryColor : theme.textTheme.bodyLarge!.color!, width: widget.size > 14 ? 3 : 1)
                : (widget.isGoalEndDate 
                    ? Border.all(color: widget.focusedGoalColor ?? theme.textTheme.bodyLarge!.color!, width: widget.size > 14 ? 3 : 1) 
                    : (widget.isCurrent ? Border.all(color: theme.textTheme.bodyLarge!.color!, width: widget.size > 14 ? 3 : 1) : null)),
              boxShadow: isHovered || widget.isGoalEndDate || widget.hasNote || widget.isCurrent ? [
                BoxShadow(
                  color: (widget.focusedGoalColor ?? (widget.hasNote ? theme.primaryColor : theme.textTheme.bodyLarge!.color!)).withValues(alpha: 0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                )
              ] : null,
            ),
            child: widget.label != null 
              ? Center(
                  child: Text(
                    widget.label!,
                    softWrap: false,
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: widget.size * (widget.label!.length > 2 ? 0.35 : 0.45),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                )
              : (widget.hasNote ? Center(
                  child: Container(
                    width: widget.size * 0.3,
                    height: widget.size * 0.3,
                    decoration: BoxDecoration(color: theme.textTheme.bodyLarge?.color, shape: BoxShape.circle),
                  ),
                ) : null),
          ),
        )),
      ),
    );
  }
}
