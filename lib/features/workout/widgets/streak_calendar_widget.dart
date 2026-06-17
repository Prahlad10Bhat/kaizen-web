import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../providers/workout_provider.dart';

class StreakCalendarWidget extends ConsumerWidget {
  const StreakCalendarWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final monthYear = DateFormat('MMMM yyyy').format(now);
    final workoutState = ref.watch(workoutProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            monthYear,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Gap(12),
          Row(
            children: [
              _buildStatHeader('Your Streak', '${workoutState.currentStreak} Days'),
              const Gap(24),
              _buildStatHeader('Total Workouts', '${workoutState.logs.length}'),
            ],
          ),
          const Gap(16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 7,
                child: _buildDaysGrid(workoutState.logs),
              ),
              const Gap(8),
              Expanded(
                flex: 1,
                child: _buildStreakColumn(workoutState.currentStreak),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStatHeader(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.white70,
            fontSize: 10,
          ),
        ),
        const Gap(2),
        Text(
          value,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDaysGrid(List<WorkoutLog> logs) {
    final daysOfWeek = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Calculate the grid: 6 rows of 7 days, ending on the Sunday of the current week.
    final currentWeekday = today.weekday; // 1 = Monday, 7 = Sunday
    final endOfWeek = today.add(Duration(days: 7 - currentWeekday));
    final startOfGrid = endOfWeek.subtract(const Duration(days: 41));

    final Set<String> logDates = logs.map((l) => l.date).toSet();

    final List<_GridCell> gridItems = [];
    for (int i = 0; i < 42; i++) {
      final date = startOfGrid.add(Duration(days: i));
      final dateStr = date.toIso8601String().substring(0, 10);
      final hasLog = logDates.contains(dateStr);
      final isToday = date == today;
      final isFuture = date.isAfter(today);
      final isOutsideMonth = date.month != now.month;

      gridItems.add(_GridCell(
        date.day,
        icon: hasLog ? LucideIcons.dumbbell : null,
        isDimmed: isFuture || isOutsideMonth,
        dot: hasLog && isToday,
        outlined: isToday && !hasLog,
      ));
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: daysOfWeek
              .map((d) => SizedBox(
                    width: 24,
                    child: Center(
                      child: Text(
                        d,
                        style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const Gap(8),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 7,
          mainAxisSpacing: 10,
          crossAxisSpacing: 6,
          childAspectRatio: 1,
          children: gridItems.map((cell) => _buildDayCell(cell)).toList(),
        ),
      ],
    );
  }

  Widget _buildDayCell(_GridCell cell) {
    if (cell.icon != null) {
      return Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                cell.icon,
                size: 14,
                color: Colors.black,
              ),
            ),
          ),
          if (cell.dot)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      );
    } else {
      return Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: cell.outlined ? Border.all(color: Colors.white24, width: 1.5) : null,
        ),
        child: Center(
          child: Text(
            '${cell.day}',
            style: GoogleFonts.inter(
              color: cell.isDimmed ? Colors.white38 : Colors.white,
              fontSize: 12,
            ),
          ),
        ),
      );
    }
  }

  Widget _buildStreakColumn(int streak) {
    return Column(
      children: [
        // Empty space for the header row alignment
        const SizedBox(height: 20),
        Container(
          width: 30,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFE65100).withValues(alpha: 0.3), // Dark orange/brown track
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStreakCheck(streak >= 4),
              const Gap(10),
              _buildStreakCheck(streak >= 3),
              const Gap(10),
              _buildStreakCheck(streak >= 2),
              const Gap(10),
              _buildStreakCheck(streak >= 1),
              const Gap(10),
              Stack(
                alignment: Alignment.center,
                children: [
                  Icon(LucideIcons.flame, color: streak > 0 ? const Color(0xFFFF5722) : Colors.white24, size: 28),
                  Positioned(
                    bottom: 4,
                    child: Text(
                      '$streak',
                      style: GoogleFonts.inter(
                        color: streak > 0 ? Colors.black : Colors.white38,
                        fontWeight: FontWeight.bold,
                        fontSize: 8,
                      ),
                    ),
                  )
                ],
              ),
              const Gap(10),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 1.5),
                  color: streak > 0 ? const Color(0xFFFF5722) : Colors.transparent,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStreakCheck(bool active) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: active ? const Color(0xFFFF5722) : Colors.transparent,
        shape: BoxShape.circle,
        border: active ? null : Border.all(color: Colors.white24),
      ),
      child: Center(
        child: Icon(LucideIcons.check, size: 10, color: active ? Colors.black : Colors.white24),
      ),
    );
  }
}

class _GridCell {
  final int day;
  final IconData? icon;
  final bool isDimmed;
  final bool dot;
  final bool outlined;

  _GridCell(this.day, {this.icon, this.isDimmed = false, this.dot = false, this.outlined = false});
}
